/**
 * IssueStorage interface and implementations
 *
 * Provides an abstraction over issue tracking backends, modeled after beads semantics.
 */

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
  isAvailable(): Promise<boolean>

  /**
   * Initialize storage in a directory
   */
  init(projectDir: string, options?: { stealth?: boolean }): Promise<boolean>

  /**
   * Check if storage is initialized in a directory
   */
  isInitialized(projectDir: string): Promise<boolean>

  /**
   * Create a new issue
   * @returns The created issue ID, or null on failure
   */
  createIssue(
    projectDir: string,
    title: string,
    options?: CreateIssueOptions
  ): Promise<string | null>

  /**
   * Get issue details by ID
   */
  getIssue(issueId: string, projectDir: string): Promise<Issue | null>

  /**
   * List issues with optional filters
   */
  listIssues(projectDir: string, options?: ListIssuesOptions): Promise<Issue[]>

  /**
   * Get issues that are ready to work on (no open blockers)
   */
  getReadyIssues(projectDir: string): Promise<Issue[]>

  /**
   * Claim an issue (set status to in_progress and optionally assign)
   */
  claimIssue(issueId: string, projectDir: string, assignee?: string): Promise<boolean>

  /**
   * Update issue status
   */
  updateStatus(issueId: string, status: IssueStatus, projectDir: string): Promise<boolean>

  /**
   * Update issue fields
   */
  updateIssue(issueId: string, projectDir: string, options: UpdateIssueOptions): Promise<boolean>

  /**
   * Set delegation metadata on an issue
   */
  setDelegationMetadata(
    issueId: string,
    projectDir: string,
    metadata: IssueDelegationMetadata
  ): Promise<boolean>

  /**
   * Get delegation metadata from an issue
   */
  getDelegationMetadata(
    issueId: string,
    projectDir: string
  ): Promise<IssueDelegationMetadata | null>

  /**
   * Clear delegation metadata from an issue
   */
  clearDelegationMetadata(issueId: string, projectDir: string): Promise<boolean>

  /**
   * Add a comment to an issue
   */
  addComment(issueId: string, projectDir: string, comment: string): Promise<boolean>

  /**
   * Add a dependency between issues
   * @param childId The issue that is blocked
   * @param parentId The issue that blocks
   */
  addDependency(childId: string, parentId: string, projectDir: string): Promise<boolean>

  /**
   * Get project status summary
   */
  getProjectStatus(projectDir: string): Promise<ProjectStatus | null>

  /**
   * Get children of an issue
   */
  getChildren(issueId: string, projectDir: string): Promise<Issue[]>

  /**
   * Get issue tree for a project
   */
  getTree(projectDir: string, rootId?: string): Promise<Issue[]>
}
