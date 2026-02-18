/**
 * BeadsIssueStorage - Issue storage implementation using beads CLI
 *
 * Uses the --repo flag to specify the beads repository path,
 * avoiding the need for cd commands which don't work reliably
 * in all shell environments.
 */

import * as fs from "node:fs/promises"
import * as path from "node:path"

import type {
  IssueStorage,
  Issue,
  CreateIssueOptions,
  IssueStatus,
  ListIssuesOptions,
  UpdateIssueOptions,
  IssueDelegationMetadata,
  ProjectStatus,
} from "./issue-storage.js"
import type { BunShell, Logger } from "../core/types.js"

interface ShellResult {
  exitCode: number
  stdout: string
  stderr: string
}

/**
 * BeadsIssueStorage - uses beads CLI for issue management
 */
export class BeadsIssueStorage implements IssueStorage {
  private $: BunShell | null = null
  private log: Logger
  private noDaemon: boolean

  constructor(log: Logger, options?: { noDaemon?: boolean }) {
    this.log = log
    this.noDaemon = options?.noDaemon ?? true
  }

  /**
   * Set the shell to use for commands
   */
  setShell($: BunShell): void {
    this.$ = $
  }

  /**
   * Get shell or throw if not set
   */
  private getShell(): BunShell {
    if (!this.$) {
      throw new Error("BeadsIssueStorage shell not initialized. Call setShell() first.")
    }
    return this.$
  }

  /**
   * Run a beads command with the specified repo path
   */
  private async runBd(args: string[], repoPath?: string): Promise<ShellResult> {
    const $ = this.getShell()
    const daemonFlag = this.noDaemon ? "--no-daemon" : ""
    const repoFlag = repoPath ? `--repo "${repoPath}"` : ""

    // Build the command - bd [flags] [args]
    const cmd = ["bd", daemonFlag, repoFlag, ...args].filter(Boolean).join(" ")

    try {
      // Use { raw: cmd } to tell the shell to parse the command string
      // rather than treating it as a single escaped argument
      const result = await $`${{ raw: cmd }}`.nothrow().quiet()
      return {
        exitCode: result.exitCode,
        stdout: result.stdout.toString(),
        stderr: result.stderr.toString(),
      }
    } catch (error) {
      return {
        exitCode: 1,
        stdout: "",
        stderr: String(error),
      }
    }
  }

  async isAvailable(): Promise<boolean> {
    try {
      const $ = this.getShell()
      const result = await $`which bd`.nothrow().quiet()
      return result.exitCode === 0
    } catch {
      return false
    }
  }

  async init(projectDir: string, options?: { stealth?: boolean }): Promise<boolean> {
    try {
      const args = options?.stealth ? ["init", "--stealth"] : ["init"]
      const result = await this.runBd(args, projectDir)
      return result.exitCode === 0
    } catch (error) {
      await this.log.error(`beads init failed: ${error}`)
      return false
    }
  }

  async isInitialized(projectDir: string): Promise<boolean> {
    try {
      const beadsDir = path.join(projectDir, ".beads")
      await fs.access(beadsDir)
      return true
    } catch {
      return false
    }
  }

  async createIssue(
    projectDir: string,
    title: string,
    options?: CreateIssueOptions
  ): Promise<string | null> {
    try {
      // Use --force to bypass prefix mismatch errors
      const args: string[] = ["create", "--force", `"${title.replace(/"/g, '\\"')}"`]

      if (options?.priority !== undefined) {
        args.push("-p", String(options.priority))
      }
      if (options?.parent) {
        args.push("--parent", options.parent)
      }
      if (options?.description) {
        args.push("-d", `"${options.description.replace(/"/g, '\\"')}"`)
      }
      if (options?.labels?.length) {
        for (const label of options.labels) {
          args.push("-l", label)
        }
      }

      const result = await this.runBd(args, projectDir)

      if (result.exitCode !== 0) {
        await this.log.error(`beads create failed: ${result.stderr}`)
        return null
      }

      // Parse issue ID from output
      const match = result.stdout.match(/Created issue:\s+([\w.-]+)/)
      if (match) return match[1]

      const altMatch = result.stdout.match(/✓\s+Created issue:\s+([\w.-]+)/)
      if (altMatch) return altMatch[1]

      const idMatch = result.stdout.match(/[\w]+-[a-z0-9.]+/)
      return idMatch ? idMatch[0] : null
    } catch (error) {
      await this.log.error(`beads create failed: ${error}`)
      return null
    }
  }

  async getIssue(issueId: string, projectDir: string): Promise<Issue | null> {
    try {
      const result = await this.runBd(["show", issueId, "--json"], projectDir)

      if (result.exitCode !== 0) {
        return null
      }

      const issues = JSON.parse(result.stdout)
      if (!Array.isArray(issues) || issues.length === 0) {
        return null
      }

      return this.parseIssue(issues[0])
    } catch {
      return null
    }
  }

  async listIssues(projectDir: string, options?: ListIssuesOptions): Promise<Issue[]> {
    try {
      const args = ["list", "--json"]

      if (options?.status) {
        args.push("--status", options.status)
      }

      const result = await this.runBd(args, projectDir)

      if (result.exitCode !== 0) {
        return []
      }

      const issues = JSON.parse(result.stdout)
      if (!Array.isArray(issues)) {
        return []
      }

      return issues.map((i) => this.parseIssue(i))
    } catch {
      return []
    }
  }

  async updateIssue(
    issueId: string,
    projectDir: string,
    options: UpdateIssueOptions
  ): Promise<boolean> {
    try {
      const args = ["update", issueId]

      if (options.status) {
        args.push("--status", this.statusToBeads(options.status))
      }
      if (options.priority !== undefined) {
        args.push("-p", String(options.priority))
      }
      if (options.description) {
        args.push("-d", `"${options.description.replace(/"/g, '\\"')}"`)
      }
      if (options.assignee) {
        args.push("--assignee", options.assignee)
      }

      const result = await this.runBd(args, projectDir)
      return result.exitCode === 0
    } catch (error) {
      await this.log.error(`beads update failed: ${error}`)
      return false
    }
  }

  async getReadyIssues(projectDir: string): Promise<Issue[]> {
    try {
      // Get issues that are open and have no open blockers
      const result = await this.runBd(["list", "--ready", "--json"], projectDir)

      if (result.exitCode !== 0) {
        // Fallback: get all open issues and filter
        const allIssues = await this.listIssues(projectDir, { status: "open" })
        return allIssues.filter((i) => !i.blockedBy || i.blockedBy.length === 0)
      }

      const issues = JSON.parse(result.stdout)
      if (!Array.isArray(issues)) {
        return []
      }

      return issues.map((i) => this.parseIssue(i))
    } catch {
      return []
    }
  }

  async claimIssue(issueId: string, projectDir: string, assignee?: string): Promise<boolean> {
    try {
      const args = ["update", issueId, "--status", "in_progress"]
      if (assignee) {
        args.push("--assignee", assignee)
      }

      const result = await this.runBd(args, projectDir)
      return result.exitCode === 0
    } catch (error) {
      await this.log.error(`beads claim failed: ${error}`)
      return false
    }
  }

  async updateStatus(issueId: string, status: IssueStatus, projectDir: string): Promise<boolean> {
    try {
      const beadsStatus = this.statusToBeads(status)
      const result = await this.runBd(["update", issueId, "--status", beadsStatus], projectDir)
      return result.exitCode === 0
    } catch (error) {
      await this.log.error(`beads status update failed: ${error}`)
      return false
    }
  }

  async setDelegationMetadata(
    issueId: string,
    projectDir: string,
    metadata: IssueDelegationMetadata
  ): Promise<boolean> {
    try {
      // Store delegation metadata as a label
      const label = `delegation:${metadata.delegationId}:${metadata.delegationStatus}`
      const result = await this.runBd(["update", issueId, "-l", label], projectDir)
      return result.exitCode === 0
    } catch (error) {
      await this.log.error(`beads set delegation metadata failed: ${error}`)
      return false
    }
  }

  async getDelegationMetadata(
    issueId: string,
    projectDir: string
  ): Promise<IssueDelegationMetadata | null> {
    try {
      const issue = await this.getIssue(issueId, projectDir)
      if (!issue?.labels) return null

      const delegationLabel = issue.labels.find((l) => l.startsWith("delegation:"))
      if (!delegationLabel) return null

      const parts = delegationLabel.split(":")
      if (parts.length < 3) return null

      return {
        delegationId: parts[1],
        delegationStatus: parts[2],
      }
    } catch {
      return null
    }
  }

  async clearDelegationMetadata(issueId: string, projectDir: string): Promise<boolean> {
    try {
      const issue = await this.getIssue(issueId, projectDir)
      if (!issue?.labels) return true

      const delegationLabel = issue.labels.find((l) => l.startsWith("delegation:"))
      if (!delegationLabel) return true

      // Remove the delegation label
      const result = await this.runBd(
        ["update", issueId, "--remove-label", delegationLabel],
        projectDir
      )
      return result.exitCode === 0
    } catch (error) {
      await this.log.error(`beads clear delegation metadata failed: ${error}`)
      return false
    }
  }

  async addComment(issueId: string, projectDir: string, comment: string): Promise<boolean> {
    try {
      const result = await this.runBd(
        ["comment", issueId, `"${comment.replace(/"/g, '\\"')}"`],
        projectDir
      )
      return result.exitCode === 0
    } catch (error) {
      await this.log.error(`beads add comment failed: ${error}`)
      return false
    }
  }

  async addDependency(childId: string, parentId: string, projectDir: string): Promise<boolean> {
    try {
      const result = await this.runBd(["update", childId, "--blocked-by", parentId], projectDir)
      return result.exitCode === 0
    } catch (error) {
      await this.log.error(`beads add dependency failed: ${error}`)
      return false
    }
  }

  async getProjectStatus(projectDir: string): Promise<ProjectStatus | null> {
    try {
      const issues = await this.listIssues(projectDir)

      const total = issues.length
      const completed = issues.filter((i) => i.status === "closed").length
      const inProgress = issues.filter((i) => i.status === "in_progress").length
      const blocked = issues.filter((i) => i.blockedBy && i.blockedBy.length > 0).length

      const blockers = issues
        .filter((i) => i.blockedBy && i.blockedBy.length > 0)
        .map((i) => ({
          issueId: i.id,
          title: i.title,
          blockedBy: i.blockedBy || [],
        }))

      return {
        total,
        completed,
        inProgress,
        blocked,
        blockers,
      }
    } catch {
      return null
    }
  }

  async getChildren(issueId: string, projectDir: string): Promise<Issue[]> {
    try {
      const result = await this.runBd(["list", "--parent", issueId, "--json"], projectDir)

      if (result.exitCode !== 0) {
        return []
      }

      const issues = JSON.parse(result.stdout)
      if (!Array.isArray(issues)) {
        return []
      }

      return issues.map((i) => this.parseIssue(i))
    } catch {
      return []
    }
  }

  async getTree(projectDir: string, rootId?: string): Promise<Issue[]> {
    try {
      const args = ["tree", "--json"]
      if (rootId) {
        args.push(rootId)
      }

      const result = await this.runBd(args, projectDir)

      if (result.exitCode !== 0) {
        return []
      }

      const issues = JSON.parse(result.stdout)
      if (!Array.isArray(issues)) {
        return []
      }

      return issues.map((i) => this.parseIssue(i))
    } catch {
      return []
    }
  }

  /**
   * Parse a beads issue JSON object into our Issue type
   */
  private parseIssue(data: Record<string, unknown>): Issue {
    return {
      id: String(data.id || ""),
      title: String(data.title || ""),
      description: data.description ? String(data.description) : undefined,
      status: this.parseStatus(data.status),
      priority: typeof data.priority === "number" ? data.priority : 2,
      parent: data.parent ? String(data.parent) : undefined,
      blockedBy: Array.isArray(data.blocked_by) ? data.blocked_by.map(String) : [],
      labels: Array.isArray(data.labels) ? data.labels.map(String) : [],
      createdAt: data.created_at ? String(data.created_at) : new Date().toISOString(),
      updatedAt: data.updated_at ? String(data.updated_at) : new Date().toISOString(),
    }
  }

  /**
   * Parse status string to IssueStatus
   */
  private parseStatus(status: unknown): IssueStatus {
    const s = String(status).toLowerCase()
    if (s === "todo" || s === "open") return "open"
    if (s === "in_progress" || s === "in-progress" || s === "active") return "in_progress"
    if (s === "done" || s === "closed" || s === "completed") return "closed"
    return "open"
  }

  /**
   * Convert IssueStatus to beads status string
   */
  private statusToBeads(status: IssueStatus): string {
    switch (status) {
      case "open":
        return "todo"
      case "in_progress":
        return "in_progress"
      case "closed":
        return "done"
      default:
        return "todo"
    }
  }
}
