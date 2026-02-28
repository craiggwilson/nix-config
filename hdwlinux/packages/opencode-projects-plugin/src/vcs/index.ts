/**
 * VCS module - Version control system abstraction
 */

export type { VCSAdapter, VCSType, WorktreeInfo, MergeSuccess, MergeStrategy } from "./adapter.js"

export { WorktreeManager } from "./worktree-manager.js"
export type { CreateWorktreeOptions, MergeWorktreeOptions } from "./worktree-manager.js"
