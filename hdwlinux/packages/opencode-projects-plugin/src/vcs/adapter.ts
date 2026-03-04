/**
 * VCS Adapter - Abstraction for version control operations
 *
 * Provides a unified interface for git and jujutsu (jj) operations,
 * focusing on worktree/workspace management and merge operations.
 */

import type { Result } from "../utils/result/index.js";
import type { VCSError } from "../utils/errors/index.js";

/**
 * Supported version control systems.
 * - `"git"`: Standard Git repositories using git worktrees for isolation
 * - `"jj"`: Jujutsu repositories (may be colocated with Git) using jj workspaces
 */
export type VCSType = "git" | "jj";

/**
 * Strategy for merging worktree changes back to the target branch.
 * - `"squash"`: Combine all commits into one (cleanest history, default)
 * - `"merge"`: Create a merge commit preserving the full commit history
 * - `"rebase"`: Replay commits on top of the target branch
 */
export type MergeStrategy = "squash" | "merge" | "rebase";

/**
 * Information about a worktree/workspace
 */
export interface WorktreeInfo {
	name: string;
	path: string;
	branch?: string; // jj change id or git branch
	isMain: boolean;
}

/**
 * Result of a successful merge operation
 */
export interface MergeSuccess {
	commitId: string;
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
	readonly type: VCSType;

	/**
	 * The root directory of the repository
	 */
	readonly repoRoot: string;

	/**
	 * Create a new worktree/workspace for isolated work
	 *
	 * @param name - Name for the worktree (used in path and branch name)
	 * @param baseBranch - Branch to base the worktree on (default: current)
	 * @returns Result containing information about the created worktree
	 */
	createWorktree(
		name: string,
		baseBranch?: string,
	): Promise<Result<WorktreeInfo, VCSError>>;

	/**
	 * List all worktrees/workspaces
	 *
	 * @returns Result containing array of worktree information
	 */
	listWorktrees(): Promise<Result<WorktreeInfo[], VCSError>>;

	/**
	 * Remove a worktree/workspace
	 *
	 * @param name - Name of the worktree to remove
	 * @returns Result indicating success
	 */
	removeWorktree(name: string): Promise<Result<void, VCSError>>;

	/**
	 * Merge changes from a worktree back to a target branch
	 *
	 * @param source - Source branch/change to merge from
	 * @param target - Target branch to merge into (default: main/master)
	 * @param strategy - Merge strategy (default: squash)
	 * @returns Result containing merge information
	 */
	merge(
		source: string,
		target?: string,
		strategy?: MergeStrategy,
	): Promise<Result<MergeSuccess, VCSError>>;

	/**
	 * Get the current branch/change
	 *
	 * @returns Result containing current branch name or change id
	 */
	getCurrentBranch(): Promise<Result<string, VCSError>>;

	/**
	 * Get the default branch (main/master/trunk)
	 *
	 * @returns Result containing default branch name
	 */
	getDefaultBranch(): Promise<Result<string, VCSError>>;

	/**
	 * Check if there are uncommitted changes
	 *
	 * @returns Result containing boolean indicating uncommitted changes
	 */
	hasUncommittedChanges(): Promise<Result<boolean, VCSError>>;

	/**
	 * Get the path where worktrees are stored
	 *
	 * @returns Base path for worktrees
	 */
	getWorktreeBasePath(): string;
}
