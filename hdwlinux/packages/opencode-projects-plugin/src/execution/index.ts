/**
 * Execution module - Worktree and delegation management
 */

export type {
  VCSType,
  MergeStrategy,
  WorktreeInfo,
  MergeResult,
  VCSAdapter,
} from "./vcs-adapter.js"

export { GitAdapter } from "./git-adapter.js"
export { JujutsuAdapter } from "./jujutsu-adapter.js"

export { WorktreeManager } from "./worktree-manager.js"
export type {
  CreateWorktreeOptions,
  MergeWorktreeOptions,
} from "./worktree-manager.js"
