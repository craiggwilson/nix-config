/**
 * VCS Adapter - Abstraction for version control operations
 *
 * Provides a unified interface for git and jujutsu (jj) operations,
 * focusing on worktree/workspace management and merge operations.
 */

/**
 * Supported VCS types
 */
export type VCSType = "git" | "jj"

/**
 * Merge strategy options
 */
export type MergeStrategy = "squash" | "merge" | "rebase"

/**
 * Information about a worktree/workspace
 */
export interface WorktreeInfo {
  name: string
  path: string
  branch?: string // git branch or jj change id
  isMain: boolean
}

/**
 * Result of a merge operation
 */
export interface MergeResult {
  success: boolean
  commitId?: string
  error?: string
  conflictFiles?: string[]
}

/**
 * VCS Adapter interface
 *
 * Implementations should handle the differences between git and jj
 * while providing a consistent API for worktree operations.
 */
export interface VCSAdapter {
  /**
   * The type of VCS this adapter handles
   */
  readonly type: VCSType

  /**
   * The root directory of the repository
   */
  readonly repoRoot: string

  /**
   * Create a new worktree/workspace for isolated work
   *
   * @param name - Name for the worktree (used in path and branch name)
   * @param baseBranch - Branch to base the worktree on (default: current)
   * @returns Information about the created worktree
   */
  createWorktree(name: string, baseBranch?: string): Promise<WorktreeInfo>

  /**
   * List all worktrees/workspaces
   *
   * @returns Array of worktree information
   */
  listWorktrees(): Promise<WorktreeInfo[]>

  /**
   * Remove a worktree/workspace
   *
   * @param name - Name of the worktree to remove
   * @returns True if successful
   */
  removeWorktree(name: string): Promise<boolean>

  /**
   * Merge changes from a worktree back to a target branch
   *
   * @param source - Source branch/change to merge from
   * @param target - Target branch to merge into (default: main/master)
   * @param strategy - Merge strategy (default: squash)
   * @returns Result of the merge operation
   */
  merge(source: string, target?: string, strategy?: MergeStrategy): Promise<MergeResult>

  /**
   * Get the current branch/change
   *
   * @returns Current branch name or change id
   */
  getCurrentBranch(): Promise<string>

  /**
   * Get the default branch (main/master/trunk)
   *
   * @returns Default branch name
   */
  getDefaultBranch(): Promise<string>

  /**
   * Check if there are uncommitted changes
   *
   * @returns True if there are uncommitted changes
   */
  hasUncommittedChanges(): Promise<boolean>

  /**
   * Get the path where worktrees are stored
   *
   * @returns Base path for worktrees
   */
  getWorktreeBasePath(): string
}
