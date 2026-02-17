/**
 * InMemoryIssueStorage - Transient IssueStorage implementation for testing
 *
 * Stores all issues in memory with no persistence. Perfect for fast unit tests.
 */

import * as crypto from "node:crypto"

import type {
  IssueStorage,
  Issue,
  IssueStatus,
  CreateIssueOptions,
  ListIssuesOptions,
  ProjectStatus,
} from "./issue-storage.js"

/**
 * Generate a short random ID
 */
function generateId(prefix: string): string {
  const hash = crypto.randomBytes(3).toString("hex")
  return `${prefix}-${hash}`
}

/**
 * InMemoryIssueStorage - stores issues in memory
 */
export class InMemoryIssueStorage implements IssueStorage {
  // Map of projectDir -> Map of issueId -> Issue
  private projects: Map<string, Map<string, Issue>> = new Map()
  private initialized: Set<string> = new Set()
  private prefix: string

  constructor(options?: { prefix?: string }) {
    this.prefix = options?.prefix || "mem"
  }

  /**
   * Get or create the issue map for a project
   */
  private getProjectIssues(projectDir: string): Map<string, Issue> {
    let issues = this.projects.get(projectDir)
    if (!issues) {
      issues = new Map()
      this.projects.set(projectDir, issues)
    }
    return issues
  }

  /**
   * Generate a hierarchical ID based on parent
   */
  private generateIssueId(projectDir: string, parent?: string): string {
    if (parent) {
      // Find existing children to determine next index
      const issues = this.getProjectIssues(projectDir)
      let maxIndex = 0
      for (const [id] of issues) {
        if (id.startsWith(`${parent}.`)) {
          const suffix = id.slice(parent.length + 1)
          const index = parseInt(suffix.split(".")[0], 10)
          if (!isNaN(index) && index > maxIndex) {
            maxIndex = index
          }
        }
      }
      return `${parent}.${maxIndex + 1}`
    }
    return generateId(this.prefix)
  }

  async isAvailable(): Promise<boolean> {
    return true // Always available
  }

  async init(projectDir: string, _options?: { stealth?: boolean }): Promise<boolean> {
    this.initialized.add(projectDir)
    this.getProjectIssues(projectDir) // Ensure map exists
    return true
  }

  async isInitialized(projectDir: string): Promise<boolean> {
    return this.initialized.has(projectDir)
  }

  async createIssue(
    projectDir: string,
    title: string,
    options?: CreateIssueOptions
  ): Promise<string | null> {
    const issues = this.getProjectIssues(projectDir)
    const id = this.generateIssueId(projectDir, options?.parent)

    const issue: Issue = {
      id,
      title,
      description: options?.description,
      status: "open",
      priority: options?.priority,
      parent: options?.parent,
      blockedBy: options?.blockedBy,
      labels: options?.labels,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    }

    issues.set(id, issue)
    return id
  }

  async getIssue(issueId: string, projectDir: string): Promise<Issue | null> {
    const issues = this.getProjectIssues(projectDir)
    return issues.get(issueId) || null
  }

  async listIssues(projectDir: string, options?: ListIssuesOptions): Promise<Issue[]> {
    const issues = this.getProjectIssues(projectDir)
    let result = Array.from(issues.values())

    if (options?.status) {
      result = result.filter((i) => i.status === options.status)
    }
    if (options?.parent) {
      result = result.filter((i) => i.parent === options.parent)
    }
    if (options?.labels?.length) {
      result = result.filter((i) =>
        options.labels!.some((label) => i.labels?.includes(label))
      )
    }

    return result
  }

  async getReadyIssues(projectDir: string): Promise<Issue[]> {
    const issues = this.getProjectIssues(projectDir)
    const allIssues = Array.from(issues.values())

    // An issue is ready if:
    // 1. It's open (not closed or in_progress)
    // 2. It has no blockers, OR all blockers are closed
    return allIssues.filter((issue) => {
      if (issue.status !== "open") return false
      if (!issue.blockedBy || issue.blockedBy.length === 0) return true

      // Check if all blockers are closed
      return issue.blockedBy.every((blockerId) => {
        const blocker = issues.get(blockerId)
        return blocker?.status === "closed"
      })
    })
  }

  async claimIssue(issueId: string, projectDir: string, assignee?: string): Promise<boolean> {
    const issues = this.getProjectIssues(projectDir)
    const issue = issues.get(issueId)

    if (!issue) return false

    issue.status = "in_progress"
    if (assignee) {
      issue.assignee = assignee
    }
    issue.updatedAt = new Date().toISOString()

    return true
  }

  async updateStatus(issueId: string, status: IssueStatus, projectDir: string): Promise<boolean> {
    const issues = this.getProjectIssues(projectDir)
    const issue = issues.get(issueId)

    if (!issue) return false

    issue.status = status
    issue.updatedAt = new Date().toISOString()

    return true
  }

  async updateIssue(
    issueId: string,
    projectDir: string,
    options: import("./issue-storage.js").UpdateIssueOptions
  ): Promise<boolean> {
    const issues = this.getProjectIssues(projectDir)
    const issue = issues.get(issueId)

    if (!issue) return false

    if (options.status !== undefined) {
      issue.status = options.status
    }
    if (options.assignee !== undefined) {
      issue.assignee = options.assignee
    }
    if (options.priority !== undefined) {
      issue.priority = options.priority
    }
    if (options.description !== undefined) {
      issue.description = options.description
    }
    if (options.labels !== undefined) {
      issue.labels = options.labels
    }
    if (options.blockedBy !== undefined) {
      issue.blockedBy = options.blockedBy
    }

    issue.updatedAt = new Date().toISOString()

    return true
  }

  async addDependency(childId: string, parentId: string, projectDir: string): Promise<boolean> {
    const issues = this.getProjectIssues(projectDir)
    const child = issues.get(childId)
    const parent = issues.get(parentId)

    if (!child || !parent) return false

    if (!child.blockedBy) {
      child.blockedBy = []
    }

    if (!child.blockedBy.includes(parentId)) {
      child.blockedBy.push(parentId)
    }

    child.updatedAt = new Date().toISOString()
    return true
  }

  // Store delegation metadata in memory
  private delegationMetadata: Map<string, import("./issue-storage.js").IssueDelegationMetadata> =
    new Map()

  private getDelegationKey(issueId: string, projectDir: string): string {
    return `${projectDir}:${issueId}`
  }

  async setDelegationMetadata(
    issueId: string,
    projectDir: string,
    metadata: import("./issue-storage.js").IssueDelegationMetadata
  ): Promise<boolean> {
    const key = this.getDelegationKey(issueId, projectDir)
    this.delegationMetadata.set(key, metadata)
    return true
  }

  async getDelegationMetadata(
    issueId: string,
    projectDir: string
  ): Promise<import("./issue-storage.js").IssueDelegationMetadata | null> {
    const key = this.getDelegationKey(issueId, projectDir)
    return this.delegationMetadata.get(key) || null
  }

  async clearDelegationMetadata(issueId: string, projectDir: string): Promise<boolean> {
    const key = this.getDelegationKey(issueId, projectDir)
    this.delegationMetadata.delete(key)
    return true
  }

  // Store comments in memory
  private comments: Map<string, string[]> = new Map()

  async addComment(issueId: string, projectDir: string, comment: string): Promise<boolean> {
    const key = this.getDelegationKey(issueId, projectDir)
    const existing = this.comments.get(key) || []
    existing.push(comment)
    this.comments.set(key, existing)
    return true
  }

  async getProjectStatus(projectDir: string): Promise<ProjectStatus | null> {
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

    // Count issues that have open blockers
    const issueMap = new Map(issues.map((i) => [i.id, i]))
    const blockedIssues = issues.filter((i) => {
      if (!i.blockedBy || i.blockedBy.length === 0) return false
      return i.blockedBy.some((blockerId) => {
        const blocker = issueMap.get(blockerId)
        return blocker && blocker.status !== "closed"
      })
    })

    const blockers = blockedIssues.map((i) => ({
      issueId: i.id,
      title: i.title,
      blockedBy: i.blockedBy || [],
    }))

    return {
      total: issues.length,
      completed,
      inProgress,
      blocked: blockedIssues.length,
      blockers,
    }
  }

  /**
   * Clear all data (useful for test cleanup)
   */
  clear(): void {
    this.projects.clear()
    this.initialized.clear()
  }

  /**
   * Clear data for a specific project
   */
  clearProject(projectDir: string): void {
    this.projects.delete(projectDir)
    this.initialized.delete(projectDir)
  }
}
