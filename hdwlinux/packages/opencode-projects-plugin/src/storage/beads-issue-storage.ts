/**
 * BeadsIssueStorage - IssueStorage implementation backed by beads CLI
 */

import * as path from "node:path"
import * as fs from "node:fs/promises"

import type {
  IssueStorage,
  Issue,
  IssueStatus,
  CreateIssueOptions,
  ListIssuesOptions,
  ProjectStatus,
} from "./issue-storage.js"
import type { Logger, BunShell } from "../core/types.js"

/**
 * Result from running a shell command
 */
interface ShellResult {
  exitCode: number
  stdout: string
  stderr: string
}

/**
 * Run a shell command
 */
async function runCommand(
  $: BunShell,
  cmd: string,
  cwd?: string
): Promise<ShellResult> {
  const fullCmd = cwd ? `cd ${JSON.stringify(cwd)} && ${cmd}` : cmd

  try {
    const result = await $`${fullCmd}`
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

/**
 * BeadsIssueStorage - wraps beads CLI for issue tracking
 */
export class BeadsIssueStorage implements IssueStorage {
  private log: Logger
  private $: BunShell | null = null
  private noDaemon: boolean = true

  constructor(log: Logger, options?: { noDaemon?: boolean }) {
    this.log = log
    this.noDaemon = options?.noDaemon ?? true
  }

  /**
   * Set the shell function to use for commands
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
   * Get the base bd command with common flags
   */
  private bdCmd(subcommand: string): string {
    const flags = this.noDaemon ? "--no-daemon" : ""
    return `bd ${flags} ${subcommand}`.trim()
  }

  async isAvailable(): Promise<boolean> {
    try {
      const result = await runCommand(this.getShell(), "which bd")
      return result.exitCode === 0
    } catch {
      return false
    }
  }

  async init(projectDir: string, options?: { stealth?: boolean }): Promise<boolean> {
    try {
      const args = options?.stealth ? "init --stealth" : "init"
      const result = await runCommand(this.getShell(), this.bdCmd(args), projectDir)
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
      const args: string[] = ["create", JSON.stringify(title)]

      if (options?.priority !== undefined) {
        args.push("-p", String(options.priority))
      }
      if (options?.parent) {
        args.push("--parent", options.parent)
      }
      if (options?.description) {
        args.push("-d", JSON.stringify(options.description))
      }
      if (options?.labels?.length) {
        for (const label of options.labels) {
          args.push("-l", label)
        }
      }

      const result = await runCommand(this.getShell(), this.bdCmd(args.join(" ")), projectDir)

      if (result.exitCode !== 0) {
        await this.log.error(`beads create failed: ${result.stderr}`)
        return null
      }


      const match = result.stdout.match(/Created issue:\s+([\w-]+)/)
      if (match) return match[1]

      const altMatch = result.stdout.match(/✓\s+Created issue:\s+([\w-]+)/)
      if (altMatch) return altMatch[1]

      const idMatch = result.stdout.match(/[\w]+-[a-z0-9]+/)
      return idMatch ? idMatch[0] : null
    } catch (error) {
      await this.log.error(`beads create failed: ${error}`)
      return null
    }
  }

  async getIssue(issueId: string, projectDir: string): Promise<Issue | null> {
    try {
      const result = await runCommand(
        this.getShell(),
        this.bdCmd(`show ${issueId} --json`),
        projectDir
      )

      if (result.exitCode !== 0) {
        return null
      }

      const data = JSON.parse(result.stdout)
      return this.parseIssue(data)
    } catch {
      return null
    }
  }

  async listIssues(projectDir: string, options?: ListIssuesOptions): Promise<Issue[]> {
    try {
      let args = "list --json"

      if (options?.status) {
        args += ` --status ${options.status}`
      }

      const result = await runCommand(this.getShell(), this.bdCmd(args), projectDir)

      if (result.exitCode !== 0) {
        return []
      }

      const data = JSON.parse(result.stdout)
      let issues = Array.isArray(data) ? data.map((d: unknown) => this.parseIssue(d)) : []


      if (options?.parent) {
        issues = issues.filter((i) => i.parent === options.parent)
      }
      if (options?.labels?.length) {
        issues = issues.filter((i) =>
          options.labels!.some((label) => i.labels?.includes(label))
        )
      }

      return issues
    } catch {
      return []
    }
  }

  async getReadyIssues(projectDir: string): Promise<Issue[]> {
    try {
      const result = await runCommand(this.getShell(), this.bdCmd("ready --json"), projectDir)

      if (result.exitCode !== 0) {
        return []
      }

      const data = JSON.parse(result.stdout)
      return Array.isArray(data) ? data.map((d: unknown) => this.parseIssue(d)) : []
    } catch {
      return []
    }
  }

  async claimIssue(issueId: string, projectDir: string, assignee?: string): Promise<boolean> {
    try {
      let cmd = `update ${issueId} --claim`
      if (assignee) {
        cmd += ` --assignee ${assignee}`
      }
      const result = await runCommand(this.getShell(), this.bdCmd(cmd), projectDir)
      return result.exitCode === 0
    } catch {
      return false
    }
  }

  async updateStatus(issueId: string, status: IssueStatus, projectDir: string): Promise<boolean> {
    try {
      const statusArg = status === "in_progress" ? "in-progress" : status
      const result = await runCommand(
        this.getShell(),
        this.bdCmd(`update ${issueId} --status ${statusArg}`),
        projectDir
      )
      return result.exitCode === 0
    } catch {
      return false
    }
  }

  async updateIssue(
    issueId: string,
    projectDir: string,
    options: import("./issue-storage.js").UpdateIssueOptions
  ): Promise<boolean> {
    try {
      const args: string[] = ["update", issueId]

      if (options.status) {
        const statusArg = options.status === "in_progress" ? "in-progress" : options.status
        args.push("--status", statusArg)
      }
      if (options.assignee !== undefined) {
        args.push("--assignee", options.assignee)
      }
      if (options.priority !== undefined) {
        args.push("-p", String(options.priority))
      }
      if (options.description !== undefined) {
        args.push("-d", JSON.stringify(options.description))
      }
      if (options.labels?.length) {
        for (const label of options.labels) {
          args.push("-l", label)
        }
      }

      const result = await runCommand(this.getShell(), this.bdCmd(args.join(" ")), projectDir)
      return result.exitCode === 0
    } catch {
      return false
    }
  }

  async addDependency(childId: string, parentId: string, projectDir: string): Promise<boolean> {
    try {
      const result = await runCommand(
        this.getShell(),
        this.bdCmd(`dep add ${childId} ${parentId}`),
        projectDir
      )
      return result.exitCode === 0
    } catch {
      return false
    }
  }

  async setDelegationMetadata(
    issueId: string,
    projectDir: string,
    metadata: import("./issue-storage.js").IssueDelegationMetadata
  ): Promise<boolean> {
    try {

      const comment = this.formatDelegationComment(metadata)


      const commentResult = await runCommand(
        this.getShell(),
        this.bdCmd(`comments add ${issueId} ${JSON.stringify(comment)}`),
        projectDir
      )

      if (commentResult.exitCode !== 0) {
        return false
      }


      const notesJson = JSON.stringify(metadata)
      const notesResult = await runCommand(
        this.getShell(),
        this.bdCmd(`update ${issueId} --notes ${JSON.stringify(notesJson)}`),
        projectDir
      )

      return notesResult.exitCode === 0
    } catch {
      return false
    }
  }

  async getDelegationMetadata(
    issueId: string,
    projectDir: string
  ): Promise<import("./issue-storage.js").IssueDelegationMetadata | null> {
    try {

      const result = await runCommand(
        this.getShell(),
        this.bdCmd(`show ${issueId} --json`),
        projectDir
      )

      if (result.exitCode !== 0) {
        return null
      }

      const issues = JSON.parse(result.stdout.toString())
      const issue = Array.isArray(issues) ? issues[0] : issues

      if (!issue?.notes) {
        return null
      }


      return JSON.parse(issue.notes)
    } catch {
      return null
    }
  }

  async clearDelegationMetadata(issueId: string, projectDir: string): Promise<boolean> {
    try {

      const comment = "[DELEGATION] Cleared"
      await runCommand(
        this.getShell(),
        this.bdCmd(`comments add ${issueId} ${JSON.stringify(comment)}`),
        projectDir
      )


      const result = await runCommand(
        this.getShell(),
        this.bdCmd(`update ${issueId} --notes ""`),
        projectDir
      )

      return result.exitCode === 0
    } catch {
      return false
    }
  }

  /**
   * Format delegation metadata as a human-readable comment
   */
  private formatDelegationComment(
    metadata: import("./issue-storage.js").IssueDelegationMetadata
  ): string {
    const lines: string[] = []

    lines.push(`[DELEGATION] ${metadata.delegationStatus.toUpperCase()}`)
    lines.push(`- ID: ${metadata.delegationId}`)

    if (metadata.worktreePath) {
      lines.push(`- Worktree: ${metadata.worktreePath}`)
    }

    if (metadata.sessionId) {
      lines.push(`- Session: ${metadata.sessionId}`)
    }

    return lines.join("\n")
  }

  async addComment(issueId: string, projectDir: string, comment: string): Promise<boolean> {
    try {
      const result = await runCommand(
        this.getShell(),
        this.bdCmd(`comments add ${issueId} ${JSON.stringify(comment)}`),
        projectDir
      )
      return result.exitCode === 0
    } catch {
      return false
    }
  }

  async getProjectStatus(projectDir: string): Promise<ProjectStatus | null> {
    try {
      const issues = await this.listIssues(projectDir)

      if (issues.length === 0) {
        return {
          total: 0,
          completed: 0,
          inProgress: 0,
          blocked: 0,
          blockers: [],
        }
      }

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
        total: issues.length,
        completed,
        inProgress,
        blocked,
        blockers,
      }
    } catch {
      return null
    }
  }

  /**
   * Parse raw beads output into Issue
   */
  private parseIssue(data: unknown): Issue {
    const d = data as Record<string, unknown>
    return {
      id: String(d.id || ""),
      title: String(d.title || d.summary || ""),
      description: d.description ? String(d.description) : undefined,
      status: this.parseStatus(d.status),
      priority: typeof d.priority === "number" ? d.priority : undefined,
      assignee: d.assignee ? String(d.assignee) : undefined,
      parent: d.parent ? String(d.parent) : undefined,
      blockedBy: Array.isArray(d.blocked_by) ? d.blocked_by.map(String) : undefined,
      labels: Array.isArray(d.labels) ? d.labels.map(String) : undefined,
      createdAt: d.created_at ? String(d.created_at) : undefined,
      updatedAt: d.updated_at ? String(d.updated_at) : undefined,
    }
  }

  /**
   * Parse status string
   */
  private parseStatus(status: unknown): IssueStatus {
    const s = String(status).toLowerCase()
    if (s === "closed" || s === "done" || s === "complete") return "closed"
    if (s === "in_progress" || s === "in-progress" || s === "active") return "in_progress"
    return "open"
  }
}
