/**
 * WorktreeManager - High-level worktree operations
 *
 * Provides a unified interface for managing worktrees/workspaces
 * across different VCS systems (git and jj).
 */

import * as fs from "node:fs/promises"
import * as path from "node:path"

import type {
  VCSAdapter,
  VCSType,
  WorktreeInfo,
  MergeResult,
  MergeStrategy,
} from "./vcs-adapter.js"
import { GitAdapter } from "./git-adapter.js"
import { JujutsuAdapter } from "./jujutsu-adapter.js"
import type { BunShell, Logger } from "../core/types.js"

/**
 * Options for creating a worktree
 */
export interface CreateWorktreeOptions {
  projectId: string
  issueId: string
  baseBranch?: string
}

/**
 * Options for merging a worktree
 */
export interface MergeWorktreeOptions {
  targetBranch?: string
  strategy?: MergeStrategy
  cleanup?: boolean // Remove worktree after merge (default: true)
}

/**
 * WorktreeManager - manages worktrees across VCS systems
 */
export class WorktreeManager {
  private repoRoot: string
  private $: BunShell
  private log: Logger
  private adapter: VCSAdapter | null = null
  private vcsType: VCSType | null = null

  constructor(repoRoot: string, shell: BunShell, log: Logger) {
    this.repoRoot = repoRoot
    this.$ = shell
    this.log = log
  }

  /**
   * Detect the VCS type and initialize the appropriate adapter
   */
  async detectVCS(): Promise<VCSAdapter | null> {
    if (this.adapter) {
      return this.adapter
    }

    // Check for jj first (preferred)
    try {
      await fs.access(path.join(this.repoRoot, ".jj"))
      this.vcsType = "jj"
      this.adapter = new JujutsuAdapter(this.repoRoot, this.$, this.log)
      await this.log.info("Detected Jujutsu (jj) repository")
      return this.adapter
    } catch {
      // Not jj
    }

    // Check for git
    try {
      await fs.access(path.join(this.repoRoot, ".git"))
      this.vcsType = "git"
      this.adapter = new GitAdapter(this.repoRoot, this.$, this.log)
      await this.log.info("Detected Git repository")
      return this.adapter
    } catch {
      // Not git
    }

    await this.log.warn("No VCS detected in repository")
    return null
  }

  /**
   * Get the VCS type (git or jj)
   */
  getVCSType(): VCSType | null {
    return this.vcsType
  }

  /**
   * Get the VCS adapter
   */
  getAdapter(): VCSAdapter | null {
    return this.adapter
  }

  /**
   * Create an isolated worktree for working on an issue
   *
   * The worktree name is derived from projectId and issueId
   */
  async createIsolatedWorktree(options: CreateWorktreeOptions): Promise<WorktreeInfo | null> {
    const adapter = await this.detectVCS()
    if (!adapter) {
      return null
    }

    const { projectId, issueId, baseBranch } = options

    // Create a name that's safe for branch names
    const name = `${projectId}/${issueId}`.replace(/[^a-zA-Z0-9/-]/g, "-")

    try {
      const info = await adapter.createWorktree(name, baseBranch)
      await this.log.info(`Created worktree for ${issueId} at ${info.path}`)
      return info
    } catch (error) {
      await this.log.error(`Failed to create worktree: ${error}`)
      return null
    }
  }

  /**
   * List all worktrees for a project
   */
  async listProjectWorktrees(projectId: string): Promise<WorktreeInfo[]> {
    const adapter = await this.detectVCS()
    if (!adapter) {
      return []
    }

    const allWorktrees = await adapter.listWorktrees()

    // Filter to worktrees that belong to this project
    return allWorktrees.filter((wt) => wt.name.startsWith(`${projectId}/`))
  }

  /**
   * List all worktrees
   */
  async listAllWorktrees(): Promise<WorktreeInfo[]> {
    const adapter = await this.detectVCS()
    if (!adapter) {
      return []
    }

    return adapter.listWorktrees()
  }

  /**
   * Get a specific worktree by issue ID
   */
  async getWorktree(projectId: string, issueId: string): Promise<WorktreeInfo | null> {
    const worktrees = await this.listProjectWorktrees(projectId)
    const name = `${projectId}/${issueId}`.replace(/[^a-zA-Z0-9/-]/g, "-")

    return worktrees.find((wt) => wt.name === name) || null
  }

  /**
   * Merge a worktree back to the target branch and optionally clean up
   */
  async mergeAndCleanup(
    worktreeName: string,
    options: MergeWorktreeOptions = {}
  ): Promise<MergeResult> {
    const adapter = await this.detectVCS()
    if (!adapter) {
      return {
        success: false,
        error: "No VCS detected",
      }
    }

    const { targetBranch, strategy = "squash", cleanup = true } = options

    // Get the branch/change associated with the worktree
    const worktrees = await adapter.listWorktrees()
    const worktree = worktrees.find((wt) => wt.name === worktreeName)

    if (!worktree) {
      return {
        success: false,
        error: `Worktree '${worktreeName}' not found`,
      }
    }

    const source = worktree.branch || worktreeName

    // Perform the merge
    const result = await adapter.merge(source, targetBranch, strategy)

    if (!result.success) {
      return result
    }

    // Clean up the worktree if requested
    if (cleanup) {
      const removed = await adapter.removeWorktree(worktreeName)
      if (!removed) {
        await this.log.warn(`Failed to remove worktree after merge: ${worktreeName}`)
      }
    }

    return result
  }

  /**
   * Remove a worktree without merging
   */
  async removeWorktree(worktreeName: string): Promise<boolean> {
    const adapter = await this.detectVCS()
    if (!adapter) {
      return false
    }

    return adapter.removeWorktree(worktreeName)
  }

  /**
   * Check if there are uncommitted changes in the main repo
   */
  async hasUncommittedChanges(): Promise<boolean> {
    const adapter = await this.detectVCS()
    if (!adapter) {
      return false
    }

    return adapter.hasUncommittedChanges()
  }

  /**
   * Get the current branch/change
   */
  async getCurrentBranch(): Promise<string | null> {
    const adapter = await this.detectVCS()
    if (!adapter) {
      return null
    }

    return adapter.getCurrentBranch()
  }

  /**
   * Get the default branch
   */
  async getDefaultBranch(): Promise<string | null> {
    const adapter = await this.detectVCS()
    if (!adapter) {
      return null
    }

    return adapter.getDefaultBranch()
  }

  /**
   * Get the base path where worktrees are stored
   */
  getWorktreeBasePath(): string | null {
    return this.adapter?.getWorktreeBasePath() || null
  }

  /**
   * Get VCS context for prompt injection
   *
   * Returns a string describing the VCS type for inclusion in prompts
   */
  getVCSContext(): string | null {
    if (!this.vcsType) {
      return null
    }

    if (this.vcsType === "jj") {
      return `<vcs-context>
This repository uses **Jujutsu (jj)** for version control.
Use \`jj\` commands for all VCS operations:
- \`jj status\` - Show working copy status
- \`jj diff\` - Show changes
- \`jj commit -m "message"\` - Create a commit
- \`jj new\` - Start a new change
- \`jj squash\` - Squash changes
- \`jj bookmark set <name>\` - Create/update a bookmark
</vcs-context>`
    }

    return `<vcs-context>
This repository uses **Git** for version control.
Use \`git\` commands for all VCS operations:
- \`git status\` - Show working tree status
- \`git diff\` - Show changes
- \`git add . && git commit -m "message"\` - Stage and commit
- \`git checkout -b <branch>\` - Create a new branch
- \`git merge <branch>\` - Merge a branch
</vcs-context>`
  }
}
