/**
 * Beads CLI client for opencode-projects plugin
 *
 * Wraps the `bd` command-line tool for issue tracking operations.
 */

import * as path from "node:path"
import * as fs from "node:fs/promises"

import type { BeadsIssue, ProjectStatus, Logger, BunShell } from "../core/types.js"

/**
 * Result from running a shell command
 */
interface ShellResult {
  exitCode: number
  stdout: string
  stderr: string
}

/**
 * Run a shell command with the provided shell function
 */
async function runCommand(
  $: BunShell,
  cmd: string,
  cwd?: string
): Promise<ShellResult> {
  // The BunShell from OpenCode handles cwd via environment
  // We need to construct the command with cd prefix if cwd is provided
  const fullCmd = cwd ? `cd ${JSON.stringify(cwd)} && ${cmd}` : cmd

  try {
    const result = await $`${fullCmd}`
    return {
      exitCode: result.exitCode,
      stdout: result.stdout.toString(),
      stderr: result.stderr.toString(),
    }
  } catch (error) {
    // Shell errors are thrown as exceptions
    return {
      exitCode: 1,
      stdout: "",
      stderr: String(error),
    }
  }
}

/**
 * Beads CLI client
 */
export class BeadsClient {
  private log: Logger
  private $: BunShell | null = null
  private noDaemon: boolean = true // Use --no-daemon by default for faster execution

  constructor(log: Logger, options?: { noDaemon?: boolean }) {
    this.log = log
    this.noDaemon = options?.noDaemon ?? true
  }

  /**
   * Get the base bd command with common flags
   */
  private bdCmd(subcommand: string): string {
    const flags = this.noDaemon ? "--no-daemon" : ""
    return `bd ${flags} ${subcommand}`.trim()
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
      throw new Error("BeadsClient shell not initialized. Call setShell() first.")
    }
    return this.$
  }

  /**
   * Check if beads CLI is available
   */
  async isAvailable(): Promise<boolean> {
    try {
      const result = await runCommand(this.getShell(), "which bd")
      return result.exitCode === 0
    } catch {
      return false
    }
  }

  /**
   * Initialize beads in a directory
   */
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

  /**
   * Check if beads is initialized in a directory
   */
  async isInitialized(projectDir: string): Promise<boolean> {
    try {
      const beadsDir = path.join(projectDir, ".beads")
      await fs.access(beadsDir)
      return true
    } catch {
      return false
    }
  }

  /**
   * Create an issue
   */
  async createIssue(
    projectDir: string,
    title: string,
    options?: {
      priority?: number
      parent?: string
      description?: string
      labels?: string[]
    }
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

      // Parse issue ID from output (e.g., "Created issue: prefix-abc")
      const match = result.stdout.match(/Created issue:\s+([\w-]+)/)
      if (match) return match[1]

      // Alternative format: "✓ Created issue: prefix-abc"
      const altMatch = result.stdout.match(/✓\s+Created issue:\s+([\w-]+)/)
      if (altMatch) return altMatch[1]

      // Try to find any issue ID pattern
      const idMatch = result.stdout.match(/[\w]+-[a-z0-9]+/)
      return idMatch ? idMatch[0] : null
    } catch (error) {
      await this.log.error(`beads create failed: ${error}`)
      return null
    }
  }

  /**
   * Get issue details
   */
  async getIssue(issueId: string, projectDir: string): Promise<BeadsIssue | null> {
    try {
      const result = await runCommand(this.getShell(), this.bdCmd(`show ${issueId} --json`), projectDir)

      if (result.exitCode !== 0) {
        return null
      }

      const data = JSON.parse(result.stdout)
      return this.parseIssue(data)
    } catch {
      return null
    }
  }

  /**
   * Get ready issues (no open blockers)
   */
  async getReadyIssues(projectId: string, projectDir: string): Promise<BeadsIssue[]> {
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

  /**
   * List all issues
   */
  async listIssues(projectDir: string, options?: { status?: string }): Promise<BeadsIssue[]> {
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
      return Array.isArray(data) ? data.map((d: unknown) => this.parseIssue(d)) : []
    } catch {
      return []
    }
  }

  /**
   * Claim an issue
   */
  async claimIssue(issueId: string, projectDir: string): Promise<boolean> {
    try {
      const result = await runCommand(this.getShell(), this.bdCmd(`update ${issueId} --claim`), projectDir)
      return result.exitCode === 0
    } catch {
      return false
    }
  }

  /**
   * Update issue status
   */
  async updateStatus(
    issueId: string,
    status: "open" | "in_progress" | "closed",
    projectDir: string
  ): Promise<boolean> {
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

  /**
   * Add dependency between issues
   */
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

  /**
   * Get project status summary
   */
  async getProjectStatus(projectId: string, projectDir: string): Promise<ProjectStatus | null> {
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
   * Parse raw beads output into BeadsIssue
   */
  private parseIssue(data: unknown): BeadsIssue {
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
  private parseStatus(status: unknown): "open" | "in_progress" | "closed" {
    const s = String(status).toLowerCase()
    if (s === "closed" || s === "done" || s === "complete") return "closed"
    if (s === "in_progress" || s === "in-progress" || s === "active") return "in_progress"
    return "open"
  }
}
