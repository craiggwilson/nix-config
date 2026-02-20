/**
 * Jujutsu Adapter - VCS adapter implementation for Jujutsu (jj)
 */

import * as fs from "node:fs/promises"
import * as path from "node:path"

import type { VCSAdapter, VCSType, WorktreeInfo, MergeResult, MergeStrategy } from "./vcs-adapter.js"
import type { BunShell, Logger } from "../core/types.js"
import { runShell, type ShellResult } from "../core/shell-utils.js"

/**
 * Jujutsu implementation of VCSAdapter
 */
export class JujutsuAdapter implements VCSAdapter {
  readonly type: VCSType = "jj"
  readonly repoRoot: string

  private $: BunShell
  private log: Logger
  private worktreeBase: string

  constructor(repoRoot: string, shell: BunShell, log: Logger) {
    this.repoRoot = repoRoot
    this.$ = shell
    this.log = log

    // Workspaces go in a sibling directory
    const repoName = path.basename(repoRoot)
    this.worktreeBase = path.join(path.dirname(repoRoot), `${repoName}-workspaces`)
  }

  /**
   * Run a shell command
   */
  private async runCommand(cmd: string): Promise<ShellResult> {
    return runShell(this.$, cmd)
  }

  async createWorktree(name: string, _baseBranch?: string): Promise<WorktreeInfo> {
    const workspacePath = path.join(this.worktreeBase, name)

    await this.log.info(`Creating jj workspace: ${name} at ${workspacePath}`)

    // Ensure parent directory exists (jj workspace add requires it)
    // Use path.dirname to handle nested paths like "project/issue"
    await fs.mkdir(path.dirname(workspacePath), { recursive: true })

    const cmd = `jj -R ${JSON.stringify(this.repoRoot)} workspace add --name ${name} ${JSON.stringify(workspacePath)}`
    const result = await this.runCommand(cmd)

    if (result.exitCode !== 0) {
      await this.log.error(`Failed to create workspace: ${result.stderr}`)
      throw new Error(`Failed to create jj workspace: ${result.stderr}`)
    }

    const changeCmd = `jj -R ${JSON.stringify(workspacePath)} log -r @ --no-graph -T 'change_id'`
    const changeResult = await this.runCommand(changeCmd)
    const changeId = changeResult.stdout.trim()

    return {
      name,
      path: workspacePath,
      branch: changeId,
      isMain: false,
    }
  }

  async listWorktrees(): Promise<WorktreeInfo[]> {
    const cmd = `jj -R ${JSON.stringify(this.repoRoot)} workspace list`
    const result = await this.runCommand(cmd)

    if (result.exitCode !== 0) {
      return []
    }

    const workspaces: WorktreeInfo[] = []

    for (const line of result.stdout.split("\n")) {
      if (!line.trim()) continue

      // Format: "name: path (change_id)"
      const match = line.match(/^(\S+):\s+(.+?)(?:\s+\(([^)]+)\))?$/)
      if (match) {
        const [, wsName, wsPath, changeId] = match
        workspaces.push({
          name: wsName,
          path: wsPath,
          branch: changeId,
          isMain: wsName === "default",
        })
      }
    }

    return workspaces
  }

  async removeWorktree(name: string): Promise<boolean> {
    await this.log.info(`Removing jj workspace: ${name}`)

    const forgetCmd = `jj -R ${JSON.stringify(this.repoRoot)} workspace forget ${name}`
    const forgetResult = await this.runCommand(forgetCmd)

    if (forgetResult.exitCode !== 0) {
      await this.log.warn(`Failed to forget workspace: ${forgetResult.stderr}`)
      return false
    }

    const workspacePath = path.join(this.worktreeBase, name)
    await this.runCommand(`rm -rf ${JSON.stringify(workspacePath)}`)

    return true
  }

  async merge(
    source: string,
    target?: string,
    strategy: MergeStrategy = "squash"
  ): Promise<MergeResult> {
    const targetRev = target || (await this.getDefaultBranch())

    await this.log.info(`Merging ${source} into ${targetRev} with strategy: ${strategy}`)

    let mergeCmd: string

    switch (strategy) {
      case "squash":
        mergeCmd = `jj -R ${JSON.stringify(this.repoRoot)} squash --from ${source} --into ${targetRev}`
        break
      case "rebase":
        mergeCmd = `jj -R ${JSON.stringify(this.repoRoot)} rebase -s ${source} -d ${targetRev}`
        break
      case "merge":
      default:
        mergeCmd = `jj -R ${JSON.stringify(this.repoRoot)} new ${source} ${targetRev} -m "Merge ${source}"`
        break
    }

    const mergeResult = await this.runCommand(mergeCmd)

    if (mergeResult.exitCode !== 0) {
      if (mergeResult.stderr.includes("conflict") || mergeResult.stderr.includes("Conflict")) {
        return {
          success: false,
          error: "Merge conflicts detected",
          conflictFiles: [],
        }
      }

      return {
        success: false,
        error: `Merge failed: ${mergeResult.stderr}`,
      }
    }

    const headCmd = `jj -R ${JSON.stringify(this.repoRoot)} log -r @ --no-graph -T 'commit_id'`
    const headResult = await this.runCommand(headCmd)
    const commitId = headResult.stdout.trim()

    return {
      success: true,
      commitId,
    }
  }

  async getCurrentBranch(): Promise<string> {
    const cmd = `jj -R ${JSON.stringify(this.repoRoot)} log -r @ --no-graph -T 'change_id'`
    const result = await this.runCommand(cmd)

    if (result.exitCode !== 0) {
      return "@"
    }

    return result.stdout.trim()
  }

  async getDefaultBranch(): Promise<string> {
    const cmd = `jj -R ${JSON.stringify(this.repoRoot)} bookmark list`
    const result = await this.runCommand(cmd)

    if (result.exitCode === 0) {
      for (const name of ["main", "master", "trunk"]) {
        if (result.stdout.includes(name)) {
          return name
        }
      }
    }

    return "root()"
  }

  async hasUncommittedChanges(): Promise<boolean> {
    const cmd = `jj -R ${JSON.stringify(this.repoRoot)} status`
    const result = await this.runCommand(cmd)

    // In jj, working copy changes are always "uncommitted" in a sense
    // Check if there are actual file modifications
    return result.stdout.includes("Working copy changes:")
  }

  getWorktreeBasePath(): string {
    return this.worktreeBase
  }
}
