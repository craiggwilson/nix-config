/**
 * IssueStorage interface and implementations
 *
 * Provides an abstraction over issue tracking backends, modeled after beads semantics.
 */

import type { Result, BaseError } from "../utils/result/index.js"

/**
 * Storage-agnostic error types for issue operations
 */
export type IssueStorageError =
  | StorageNotAvailableError
  | StorageNotInitializedError
  | StorageOperationError
  | StorageParseError
  | StorageTimeoutError

/**
 * Error when the storage backend is not available
 */
export class StorageNotAvailableError implements BaseError {
  readonly name = "StorageNotAvailableError"
  readonly code = "STORAGE_NOT_AVAILABLE"
  readonly recoverable = false

  constructor(
    public readonly message: string,
    public readonly suggestion?: string,
    public readonly cause?: unknown
  ) {}
}

/**
 * Error when storage is not initialized in a directory
 */
export class StorageNotInitializedError implements BaseError {
  readonly name = "StorageNotInitializedError"
  readonly code = "STORAGE_NOT_INITIALIZED"
  readonly recoverable = true
  readonly suggestion = "Initialize storage in the project directory first"

  constructor(
    public readonly message: string,
    public readonly cause?: unknown
  ) {}
}

/**
 * Error when a storage operation fails
 */
export class StorageOperationError implements BaseError {
  readonly name = "StorageOperationError"
  readonly code = "STORAGE_OPERATION_FAILED"
  readonly recoverable = true

  constructor(
    public readonly message: string,
    public readonly suggestion?: string,
    public readonly cause?: unknown
  ) {}
}

/**
 * Error when parsing storage output fails
 */
export class StorageParseError implements BaseError {
  readonly name = "StorageParseError"
  readonly code = "STORAGE_PARSE_ERROR"
  readonly recoverable = false
  readonly suggestion = "This may indicate a version mismatch or corrupted data"

  constructor(
    public readonly message: string,
    public readonly cause?: unknown
  ) {}
}

/**
 * Error when a storage operation times out
 */
export class StorageTimeoutError implements BaseError {
  readonly name = "StorageTimeoutError"
  readonly code = "STORAGE_TIMEOUT"
  readonly recoverable = true
  readonly suggestion = "Try again or increase the timeout value"

  constructor(
    public readonly message: string,
    public readonly timeoutMs: number,
    public readonly cause?: unknown
  ) {}
}

/**
 * Issue data structure
 */
export interface Issue {
  id: string
  title: string
  description?: string
  status: IssueStatus
  priority?: number // 0 (highest) to 3 (lowest)
  assignee?: string
  parent?: string // Parent issue ID for hierarchy
  blockedBy?: string[] // Issue IDs that block this issue
  labels?: string[]
  createdAt?: string
  updatedAt?: string
}

export type IssueStatus = "open" | "in_progress" | "closed"

/**
 * Options for creating an issue
 */
export interface CreateIssueOptions {
  priority?: number
  parent?: string
  description?: string
  labels?: string[]
  blockedBy?: string[]
}

/**
 * Options for listing issues
 */
export interface ListIssuesOptions {
  status?: IssueStatus
  parent?: string
  labels?: string[]
  /** Include all issues regardless of status (open, in_progress, and closed) */
  all?: boolean
}

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
 * Delegation metadata stored on an issue
 */
export interface IssueDelegationMetadata {
  delegationId: string
  delegationStatus: string
  worktreePath?: string
  worktreeBranch?: string
  vcs?: "git" | "jj"
  sessionId?: string
}

/**
 * Project status summary
 */
export interface ProjectStatus {
  total: number
  completed: number
  inProgress: number
  blocked: number
  blockers: Array<{
    issueId: string
    title: string
    blockedBy: string[]
  }>
}

/**
 * IssueStorage interface
 *
 * Abstracts issue tracking operations with beads-like semantics:
 * - Hierarchical issue IDs (parent.child.grandchild)
 * - Dependency relationships (blockedBy)
 * - Ready queue (issues with no open blockers)
 */
export interface IssueStorage {
  /**
   * Check if the storage backend is available
   */
  isAvailable(): Promise<Result<boolean, IssueStorageError>>

  /**
   * Initialize storage in a directory
   */
  init(projectDir: string, options?: { stealth?: boolean }): Promise<Result<void, IssueStorageError>>

  /**
   * Check if storage is initialized in a directory
   */
  isInitialized(projectDir: string): Promise<Result<boolean, IssueStorageError>>

  /**
   * Create a new issue
   */
  createIssue(
    projectDir: string,
    title: string,
    options?: CreateIssueOptions
  ): Promise<Result<string, IssueStorageError>>

  /**
   * Get issue details by ID
   */
  getIssue(issueId: string, projectDir: string): Promise<Result<Issue, IssueStorageError>>

  /**
   * List issues with optional filters
   */
  listIssues(projectDir: string, options?: ListIssuesOptions): Promise<Result<Issue[], IssueStorageError>>

  /**
   * Get issues that are ready to work on (no open blockers)
   */
  getReadyIssues(projectDir: string): Promise<Result<Issue[], IssueStorageError>>

  /**
   * Claim an issue (set status to in_progress and optionally assign)
   */
  claimIssue(issueId: string, projectDir: string, assignee?: string): Promise<Result<void, IssueStorageError>>

  /**
   * Update issue status
   */
  updateStatus(issueId: string, status: IssueStatus, projectDir: string): Promise<Result<void, IssueStorageError>>

  /**
   * Update issue fields
   */
  updateIssue(issueId: string, projectDir: string, options: UpdateIssueOptions): Promise<Result<void, IssueStorageError>>

  /**
   * Set delegation metadata on an issue
   */
  setDelegationMetadata(
    issueId: string,
    projectDir: string,
    metadata: IssueDelegationMetadata
  ): Promise<Result<void, IssueStorageError>>

  /**
   * Get delegation metadata from an issue
   */
  getDelegationMetadata(
    issueId: string,
    projectDir: string
  ): Promise<Result<IssueDelegationMetadata | null, IssueStorageError>>

  /**
   * Clear delegation metadata from an issue
   */
  clearDelegationMetadata(issueId: string, projectDir: string): Promise<Result<void, IssueStorageError>>

  /**
   * Add a comment to an issue
   */
  addComment(issueId: string, projectDir: string, comment: string): Promise<Result<void, IssueStorageError>>

  /**
   * Add a dependency between issues
   * @param childId The issue that is blocked
   * @param parentId The issue that blocks
   */
  addDependency(childId: string, parentId: string, projectDir: string): Promise<Result<void, IssueStorageError>>

  /**
   * Get project status summary
   */
  getProjectStatus(projectDir: string): Promise<Result<ProjectStatus, IssueStorageError>>

  /**
   * Get children of an issue
   */
  getChildren(issueId: string, projectDir: string): Promise<Result<Issue[], IssueStorageError>>

  /**
   * Get issue tree for a project
   */
  getTree(projectDir: string, rootId?: string): Promise<Result<Issue[], IssueStorageError>>
}
