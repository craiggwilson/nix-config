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
  IssueStorageError,
  UpdateIssueOptions,
  IssueDelegationMetadata,
} from "../issue-storage.js"
import { StorageOperationError } from "../issue-storage.js"
import type { Result } from "../../utils/result/index.js"

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

  async isAvailable(): Promise<Result<boolean, IssueStorageError>> {
    return { ok: true, value: true }
  }

  async init(projectDir: string, _options?: { stealth?: boolean }): Promise<Result<void, IssueStorageError>> {
    this.initialized.add(projectDir)
    this.getProjectIssues(projectDir)
    return { ok: true, value: undefined }
  }

  async isInitialized(projectDir: string): Promise<Result<boolean, IssueStorageError>> {
    return { ok: true, value: this.initialized.has(projectDir) }
  }

  async createIssue(
    projectDir: string,
    title: string,
    options?: CreateIssueOptions
  ): Promise<Result<string, IssueStorageError>> {
    const issues = this.getProjectIssues(projectDir)

    // Validate parent exists if specified
    if (options?.parent) {
      const parentIssue = issues.get(options.parent)
      if (!parentIssue) {
        return {
          ok: false,
          error: new StorageOperationError(
            `Parent issue '${options.parent}' not found`,
            "Check that the parent issue ID is correct"
          ),
        }
      }
    }

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
    return { ok: true, value: id }
  }

  async getIssue(issueId: string, projectDir: string): Promise<Result<Issue, IssueStorageError>> {
    const issues = this.getProjectIssues(projectDir)
    const issue = issues.get(issueId)
    if (!issue) {
      return { ok: false, error: new StorageOperationError(`Issue ${issueId} not found`, "Check that the issue ID is correct") }
    }
    return { ok: true, value: issue }
  }

  async listIssues(projectDir: string, options?: ListIssuesOptions): Promise<Result<Issue[], IssueStorageError>> {
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

    return { ok: true, value: result }
  }

  async getReadyIssues(projectDir: string): Promise<Result<Issue[], IssueStorageError>> {
    const issues = this.getProjectIssues(projectDir)
    const allIssues = Array.from(issues.values())

    // An issue is ready if:
    // 1. It's open (not closed or in_progress)
    // 2. It has no blockers, OR all blockers are closed
    const readyIssues = allIssues.filter((issue) => {
      if (issue.status !== "open") return false
      if (!issue.blockedBy || issue.blockedBy.length === 0) return true

      return issue.blockedBy.every((blockerId) => {
        const blocker = issues.get(blockerId)
        return blocker?.status === "closed"
      })
    })
    return { ok: true, value: readyIssues }
  }

  async claimIssue(issueId: string, projectDir: string, assignee?: string): Promise<Result<void, IssueStorageError>> {
    const issues = this.getProjectIssues(projectDir)
    const issue = issues.get(issueId)

    if (!issue) {
      return { ok: false, error: new StorageOperationError(`Issue ${issueId} not found`, "Check that the issue ID is correct") }
    }

    issue.status = "in_progress"
    if (assignee) {
      issue.assignee = assignee
    }
    issue.updatedAt = new Date().toISOString()

    return { ok: true, value: undefined }
  }

  async updateStatus(issueId: string, status: IssueStatus, projectDir: string): Promise<Result<void, IssueStorageError>> {
    const issues = this.getProjectIssues(projectDir)
    const issue = issues.get(issueId)

    if (!issue) {
      return { ok: false, error: new StorageOperationError(`Issue ${issueId} not found`, "Check that the issue ID is correct") }
    }

    issue.status = status
    issue.updatedAt = new Date().toISOString()

    return { ok: true, value: undefined }
  }

  async updateIssue(
    issueId: string,
    projectDir: string,
    options: UpdateIssueOptions
  ): Promise<Result<void, IssueStorageError>> {
    const issues = this.getProjectIssues(projectDir)
    const issue = issues.get(issueId)

    if (!issue) {
      return { ok: false, error: new StorageOperationError(`Issue ${issueId} not found`, "Check that the issue ID is correct") }
    }

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

    return { ok: true, value: undefined }
  }

  async addDependency(childId: string, parentId: string, projectDir: string): Promise<Result<void, IssueStorageError>> {
    const issues = this.getProjectIssues(projectDir)
    const child = issues.get(childId)
    const parent = issues.get(parentId)

    if (!child || !parent) {
      return { ok: false, error: new StorageOperationError("Issue not found", "Check that both issue IDs are correct") }
    }

    if (!child.blockedBy) {
      child.blockedBy = []
    }

    if (!child.blockedBy.includes(parentId)) {
      child.blockedBy.push(parentId)
    }

    child.updatedAt = new Date().toISOString()
    return { ok: true, value: undefined }
  }


  private delegationMetadata: Map<string, IssueDelegationMetadata> = new Map()

  private getDelegationKey(issueId: string, projectDir: string): string {
    return `${projectDir}:${issueId}`
  }

  async setDelegationMetadata(
    issueId: string,
    projectDir: string,
    metadata: IssueDelegationMetadata
  ): Promise<Result<void, IssueStorageError>> {
    const key = this.getDelegationKey(issueId, projectDir)
    this.delegationMetadata.set(key, metadata)
    return { ok: true, value: undefined }
  }

  async getDelegationMetadata(
    issueId: string,
    projectDir: string
  ): Promise<Result<IssueDelegationMetadata | null, IssueStorageError>> {
    const key = this.getDelegationKey(issueId, projectDir)
    return { ok: true, value: this.delegationMetadata.get(key) || null }
  }

  async clearDelegationMetadata(issueId: string, projectDir: string): Promise<Result<void, IssueStorageError>> {
    const key = this.getDelegationKey(issueId, projectDir)
    this.delegationMetadata.delete(key)
    return { ok: true, value: undefined }
  }


  private comments: Map<string, string[]> = new Map()

  async addComment(issueId: string, projectDir: string, comment: string): Promise<Result<void, IssueStorageError>> {
    const key = this.getDelegationKey(issueId, projectDir)
    const existing = this.comments.get(key) || []
    existing.push(comment)
    this.comments.set(key, existing)
    return { ok: true, value: undefined }
  }

  async getProjectStatus(projectDir: string): Promise<Result<ProjectStatus, IssueStorageError>> {
    const issuesResult = await this.listIssues(projectDir)
    if (!issuesResult.ok) return issuesResult
    const issues = issuesResult.value

    if (issues.length === 0) {
      return { ok: true, value: {
        total: 0,
        completed: 0,
        inProgress: 0,
        blocked: 0,
        blockers: [],
      }}
    }

    const completed = issues.filter((i) => i.status === "closed").length
    const inProgress = issues.filter((i) => i.status === "in_progress").length

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

    return { ok: true, value: {
      total: issues.length,
      completed,
      inProgress,
      blocked: blockedIssues.length,
      blockers,
    }}
  }

  async getChildren(issueId: string, projectDir: string): Promise<Result<Issue[], IssueStorageError>> {
    const issues = this.getProjectIssues(projectDir)
    return { ok: true, value: Array.from(issues.values()).filter((i) => i.parent === issueId) }
  }

  async getTree(projectDir: string, rootId?: string): Promise<Result<Issue[], IssueStorageError>> {
    const issues = this.getProjectIssues(projectDir)
    const allIssues = Array.from(issues.values())

    if (!rootId) {
      return { ok: true, value: allIssues }
    }

    // Return the root and all descendants
    const result: Issue[] = []
    const collectDescendants = (parentId: string) => {
      const children = allIssues.filter((i) => i.parent === parentId)
      for (const child of children) {
        result.push(child)
        collectDescendants(child.id)
      }
    }

    const root = issues.get(rootId)
    if (root) {
      result.push(root)
      collectDescendants(rootId)
    }

    return { ok: true, value: result }
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
