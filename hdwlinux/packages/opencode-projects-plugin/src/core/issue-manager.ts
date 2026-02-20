/**
 * IssueManager - Core business logic for issue operations
 *
 * Encapsulates all issue management operations, delegating to IssueStorage
 * for persistence and coordinating with FocusManager for focus state.
 */

import type { IssueStorage, Issue, CreateIssueOptions, IssueStatus } from "../storage/index.js"
import type { FocusManager } from "./focus-manager.js"
import type { Logger } from "./types.js"

/**
 * Options for updating an issue
 */
export interface UpdateIssueOptions {
  status?: IssueStatus
  assignee?: string
  priority?: number
  description?: string
  labels?: string[]
  blockedBy?: string[]
}

/**
 * Options for adding a completion comment
 */
export interface CompletionCommentOptions {
  summary?: string
  artifacts?: string[]
  mergeCommit?: string
}

/**
 * IssueManager dependencies
 */
export interface IssueManagerDeps {
  issueStorage: IssueStorage
  focus: FocusManager
  log: Logger
}

/**
 * IssueManager - encapsulates all issue operations
 */
export class IssueManager {
  private issueStorage: IssueStorage
  private focus: FocusManager
  private log: Logger

  constructor(deps: IssueManagerDeps) {
    this.issueStorage = deps.issueStorage
    this.focus = deps.focus
    this.log = deps.log
  }

  /**
   * Create an issue in a project directory.
   */
  async createIssue(
    projectDir: string,
    title: string,
    options?: CreateIssueOptions
  ): Promise<string | null> {
    return this.issueStorage.createIssue(projectDir, title, options)
  }

  /**
   * Get an issue by ID
   */
  async getIssue(projectDir: string, issueId: string): Promise<Issue | null> {
    return this.issueStorage.getIssue(issueId, projectDir)
  }

  /**
   * List all issues in a project
   */
  async listIssues(projectDir: string): Promise<Issue[]> {
    return this.issueStorage.listIssues(projectDir)
  }

  /**
   * Get ready issues (no blockers, open status)
   */
  async getReadyIssues(projectDir: string): Promise<Issue[]> {
    return this.issueStorage.getReadyIssues(projectDir)
  }

  /**
   * Claim an issue (set to in_progress and optionally assign)
   */
  async claimIssue(projectDir: string, issueId: string, assignee?: string): Promise<boolean> {
    const claimed = await this.issueStorage.claimIssue(issueId, projectDir, assignee)

    if (claimed) {
      this.focus.setIssueFocus(issueId)
      await this.log.debug(`Claimed issue ${issueId}`)
    }

    return claimed
  }

  /**
   * Update an issue
   */
  async updateIssue(
    projectDir: string,
    issueId: string,
    options: UpdateIssueOptions
  ): Promise<boolean> {
    const updated = await this.issueStorage.updateIssue(issueId, projectDir, options)

    if (updated && options.status === "closed") {
      if (this.focus.getIssueId() === issueId) {
        this.focus.clearIssueFocus()
      }
    }

    return updated
  }

  /**
   * Add a comment to an issue
   */
  async addComment(projectDir: string, issueId: string, comment: string): Promise<boolean> {
    return this.issueStorage.addComment(issueId, projectDir, comment)
  }

  /**
   * Add a completion comment when closing an issue
   */
  async addCompletionComment(
    projectDir: string,
    issueId: string,
    options: CompletionCommentOptions
  ): Promise<boolean> {
    const lines: string[] = []

    lines.push("[COMPLETED]")

    if (options.summary) {
      lines.push("")
      lines.push(options.summary)
    }

    if (options.mergeCommit) {
      lines.push("")
      lines.push(`Merge commit: ${options.mergeCommit}`)
    }

    if (options.artifacts && options.artifacts.length > 0) {
      lines.push("")
      lines.push("Artifacts:")
      for (const artifact of options.artifacts) {
        lines.push(`- ${artifact}`)
      }
    }

    return this.addComment(projectDir, issueId, lines.join("\n"))
  }

  /**
   * Get issue tree for a project
   */
  async getTree(projectDir: string, rootId?: string): Promise<Issue[]> {
    return this.issueStorage.getTree(projectDir, rootId)
  }

  /**
   * Get children of an issue
   */
  async getChildren(projectDir: string, issueId: string): Promise<Issue[]> {
    return this.issueStorage.getChildren(issueId, projectDir)
  }

  /**
   * Add a dependency between issues
   */
  async addDependency(projectDir: string, childId: string, parentId: string): Promise<boolean> {
    return this.issueStorage.addDependency(childId, parentId, projectDir)
  }

  /**
   * Set delegation metadata on an issue
   */
  async setDelegationMetadata(
    projectDir: string,
    issueId: string,
    metadata: { delegationId: string; delegationStatus: string }
  ): Promise<boolean> {
    return this.issueStorage.setDelegationMetadata(issueId, projectDir, metadata)
  }

  /**
   * Get delegation metadata from an issue
   */
  async getDelegationMetadata(
    projectDir: string,
    issueId: string
  ): Promise<{ delegationId: string; delegationStatus: string } | null> {
    return this.issueStorage.getDelegationMetadata(issueId, projectDir)
  }

  /**
   * Clear delegation metadata from an issue
   */
  async clearDelegationMetadata(projectDir: string, issueId: string): Promise<boolean> {
    return this.issueStorage.clearDelegationMetadata(issueId, projectDir)
  }
}
