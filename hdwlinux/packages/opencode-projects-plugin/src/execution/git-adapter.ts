/**
 * Git Adapter - VCS adapter implementation for Git
 */

import * as path from "node:path"

import type { VCSAdapter, VCSType, WorktreeInfo, MergeResult, MergeStrategy } from "./vcs-adapter.js"
import type { BunShell, Logger } from "../core/types.js"

interface ShellResult {
  exitCode: number
  stdout: string
  stderr: string
}

/**
 * Git implementation of VCSAdapter
 */
export class GitAdapter implements VCSAdapter {
  readonly type: VCSType = "git"
  readonly repoRoot: string

  private $: BunShell
  private log: Logger
  private worktreeBase: string

  constructor(repoRoot: string, shell: BunShell, log: Logger) {
    this.repoRoot = repoRoot
    this.$ = shell
    this.log = log

    // Worktrees go in a sibling directory
    const repoName = path.basename(repoRoot)
    this.worktreeBase = path.join(path.dirname(repoRoot), `${repoName}-worktrees`)
  }

  /**
   * Run a shell command
   */
  private async runShell(cmd: string): Promise<ShellResult> {
    try {
      // Use { raw: cmd } to tell the shell to parse the command string
      // rather than treating it as a single escaped argument
      const result = await this.$`${{ raw: cmd }}`.nothrow().quiet()
      return {
        exitCode: result.exitCode,
        stdout: result.stdout.toString(),
        stderr: result.stderr.toString(),
      }
    } catch (error) {
      return {
        exitCode: 1,
        stdout: "",
        stderr: String(error),
      }
    }
  }

  async createWorktree(name: string, baseBranch?: string): Promise<WorktreeInfo> {
    const worktreePath = path.join(this.worktreeBase, name)
    const branchName = name.replace(/\//g, "-") // Sanitize for branch name

    await this.log.info(`Creating git worktree: ${name} at ${worktreePath}`)

    const base = baseBranch || (await this.getDefaultBranch())

    const cmd = `git -C ${JSON.stringify(this.repoRoot)} worktree add -b ${branchName} ${JSON.stringify(worktreePath)} ${base}`
    const result = await this.runShell(cmd)

    if (result.exitCode !== 0) {
      await this.log.error(`Failed to create worktree: ${result.stderr}`)
      throw new Error(`Failed to create git worktree: ${result.stderr}`)
    }

    return {
      name,
      path: worktreePath,
      branch: branchName,
      isMain: false,
    }
  }

  async listWorktrees(): Promise<WorktreeInfo[]> {
    const cmd = `git -C ${JSON.stringify(this.repoRoot)} worktree list --porcelain`
    const result = await this.runShell(cmd)

    if (result.exitCode !== 0) {
      return []
    }

    const worktrees: WorktreeInfo[] = []
    let current: Partial<WorktreeInfo> = {}

    for (const line of result.stdout.split("\n")) {
      if (line.startsWith("worktree ")) {
        if (current.path) {
          worktrees.push(current as WorktreeInfo)
        }
        current = {
          path: line.slice(9),
          isMain: false,
        }
      } else if (line.startsWith("branch ")) {
        current.branch = line.slice(7).replace("refs/heads/", "")
      } else if (line === "bare") {
        current.isMain = true
      }
    }

    if (current.path) {
      worktrees.push(current as WorktreeInfo)
    }

    // Add names based on path relative to worktree base
    return worktrees.map((wt) => {
      let name: string
      if (wt.path.startsWith(this.worktreeBase)) {
        name = path.relative(this.worktreeBase, wt.path)
      } else {
        name = path.basename(wt.path)
      }
      return {
        ...wt,
        name,
        isMain: wt.path === this.repoRoot,
      }
    })
  }

  async removeWorktree(name: string): Promise<boolean> {
    const worktreePath = path.join(this.worktreeBase, name)

    await this.log.info(`Removing git worktree: ${name}`)

    const removeCmd = `git -C ${JSON.stringify(this.repoRoot)} worktree remove ${JSON.stringify(worktreePath)} --force`
    const removeResult = await this.runShell(removeCmd)

    if (removeResult.exitCode !== 0) {
      await this.log.warn(`Failed to remove worktree: ${removeResult.stderr}`)
      return false
    }

    const branchName = name.replace(/\//g, "-")
    const branchCmd = `git -C ${JSON.stringify(this.repoRoot)} branch -D ${branchName}`
    await this.runShell(branchCmd) // Ignore errors - branch may not exist

    return true
  }

  async merge(
    source: string,
    target?: string,
    strategy: MergeStrategy = "squash"
  ): Promise<MergeResult> {
    const targetBranch = target || (await this.getDefaultBranch())

    await this.log.info(`Merging ${source} into ${targetBranch} with strategy: ${strategy}`)

    const checkoutCmd = `git -C ${JSON.stringify(this.repoRoot)} checkout ${targetBranch}`
    const checkoutResult = await this.runShell(checkoutCmd)

    if (checkoutResult.exitCode !== 0) {
      return {
        success: false,
        error: `Failed to checkout ${targetBranch}: ${checkoutResult.stderr}`,
      }
    }

    let mergeCmd: string
    switch (strategy) {
      case "squash":
        mergeCmd = `git -C ${JSON.stringify(this.repoRoot)} merge --squash ${source}`
        break
      case "rebase":
        mergeCmd = `git -C ${JSON.stringify(this.repoRoot)} rebase ${source}`
        break
      case "merge":
      default:
        mergeCmd = `git -C ${JSON.stringify(this.repoRoot)} merge ${source}`
        break
    }

    const mergeResult = await this.runShell(mergeCmd)

    if (mergeResult.exitCode !== 0) {
      if (mergeResult.stderr.includes("CONFLICT") || mergeResult.stderr.includes("conflict")) {
        const conflictCmd = `git -C ${JSON.stringify(this.repoRoot)} diff --name-only --diff-filter=U`
        const conflictResult = await this.runShell(conflictCmd)
        const conflictFiles = conflictResult.stdout.trim().split("\n").filter(Boolean)

        return {
          success: false,
          error: "Merge conflicts detected",
          conflictFiles,
        }
      }

      return {
        success: false,
        error: `Merge failed: ${mergeResult.stderr}`,
      }
    }

    // For squash, we need to commit
    if (strategy === "squash") {
      const commitCmd = `git -C ${JSON.stringify(this.repoRoot)} commit -m "Merge ${source} (squashed)"`
      const commitResult = await this.runShell(commitCmd)

      if (commitResult.exitCode !== 0) {
        if (!commitResult.stdout.includes("nothing to commit")) {
          return {
            success: false,
            error: `Commit failed: ${commitResult.stderr}`,
          }
        }
      }
    }

    const headCmd = `git -C ${JSON.stringify(this.repoRoot)} rev-parse HEAD`
    const headResult = await this.runShell(headCmd)
    const commitId = headResult.stdout.trim()

    return {
      success: true,
      commitId,
    }
  }

  async getCurrentBranch(): Promise<string> {
    const cmd = `git -C ${JSON.stringify(this.repoRoot)} rev-parse --abbrev-ref HEAD`
    const result = await this.runShell(cmd)

    if (result.exitCode !== 0) {
      return "HEAD"
    }

    return result.stdout.trim()
  }

  async getDefaultBranch(): Promise<string> {
    const remoteCmd = `git -C ${JSON.stringify(this.repoRoot)} symbolic-ref refs/remotes/origin/HEAD 2>/dev/null`
    const remoteResult = await this.runShell(remoteCmd)

    if (remoteResult.exitCode === 0) {
      const ref = remoteResult.stdout.trim()
      return ref.replace("refs/remotes/origin/", "")
    }

    for (const branch of ["main", "master", "trunk"]) {
      const checkCmd = `git -C ${JSON.stringify(this.repoRoot)} rev-parse --verify ${branch} 2>/dev/null`
      const checkResult = await this.runShell(checkCmd)
      if (checkResult.exitCode === 0) {
        return branch
      }
    }

    return "main"
  }

  async hasUncommittedChanges(): Promise<boolean> {
    const cmd = `git -C ${JSON.stringify(this.repoRoot)} status --porcelain`
    const result = await this.runShell(cmd)

    return result.stdout.trim().length > 0
  }

  getWorktreeBasePath(): string {
    return this.worktreeBase
  }
}
