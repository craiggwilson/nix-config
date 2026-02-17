/**
 * Beads CLI client for opencode-projects plugin
 *
 * Wraps the `bd` command-line tool for issue tracking operations.
 */

import { $ } from "bun"
import * as path from "node:path"

import type { BeadsIssue, ProjectStatus, Logger } from "./types.js"

/**
 * Beads CLI client
 */
export class BeadsClient {
  private log: Logger

  constructor(log: Logger) {
    this.log = log
  }

  /**
   * Check if beads CLI is available
   */
  async isAvailable(): Promise<boolean> {
    try {
      const result = await $`which bd`.quiet()
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
      const args = options?.stealth ? ["init", "--stealth"] : ["init"]
      const result = await $`bd ${args}`.cwd(projectDir).quiet()
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
      const result = await $`test -d ${beadsDir}`.quiet()
      return result.exitCode === 0
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
      const args: string[] = ["create", title]

      if (options?.priority !== undefined) {
        args.push("-p", String(options.priority))
      }
      if (options?.parent) {
        args.push("--parent", options.parent)
      }
      if (options?.labels?.length) {
        for (const label of options.labels) {
          args.push("-l", label)
        }
      }

      const result = await $`bd ${args}`.cwd(projectDir).quiet()

      if (result.exitCode !== 0) {
        await this.log.error(`beads create failed: ${result.stderr}`)
        return null
      }

      // Parse issue ID from output (e.g., "Created bd-a3f8")
      const match = result.stdout.toString().match(/Created\s+(bd-[\w.]+)/)
      return match ? match[1] : null
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
      const result = await $`bd show ${issueId} --json`.cwd(projectDir).quiet()

      if (result.exitCode !== 0) {
        return null
      }

      const data = JSON.parse(result.stdout.toString())
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
      const result = await $`bd ready --json`.cwd(projectDir).quiet()

      if (result.exitCode !== 0) {
        return []
      }

      const data = JSON.parse(result.stdout.toString())
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
      const args: string[] = ["list", "--json"]

      if (options?.status) {
        args.push("--status", options.status)
      }

      const result = await $`bd ${args}`.cwd(projectDir).quiet()

      if (result.exitCode !== 0) {
        return []
      }

      const data = JSON.parse(result.stdout.toString())
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
      const result = await $`bd update ${issueId} --claim`.cwd(projectDir).quiet()
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
      const result = await $`bd update ${issueId} --status ${statusArg}`.cwd(projectDir).quiet()
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
      const result = await $`bd dep add ${childId} ${parentId}`.cwd(projectDir).quiet()
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
