/**
 * Jujutsu Adapter - VCS adapter implementation for Jujutsu (jj)
 */

import * as path from "node:path"

import type { VCSAdapter, VCSType, WorktreeInfo, MergeResult, MergeStrategy } from "./vcs-adapter.js"
import type { BunShell, Logger } from "../core/types.js"

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

  async createWorktree(name: string, _baseBranch?: string): Promise<WorktreeInfo> {
    const workspacePath = path.join(this.worktreeBase, name)

    await this.log.info(`Creating jj workspace: ${name} at ${workspacePath}`)

    // Ensure the parent directory exists
    const mkdirCmd = `mkdir -p ${JSON.stringify(this.worktreeBase)}`
    await this.$`${mkdirCmd}`

    // Create the workspace
    // Note: jj workspace add creates a new workspace at the specified path
    const cmd = `jj -R ${JSON.stringify(this.repoRoot)} workspace add --name ${name} ${JSON.stringify(workspacePath)}`
    const result = await this.$`${cmd}`

    if (result.exitCode !== 0) {
      const error = result.stderr.toString()
      await this.log.error(`Failed to create workspace: ${error}`)
      throw new Error(`Failed to create jj workspace: ${error}`)
    }

    // Get the change ID for the new workspace
    const changeCmd = `jj -R ${JSON.stringify(workspacePath)} log -r @ --no-graph -T 'change_id'`
    const changeResult = await this.$`${changeCmd}`
    const changeId = changeResult.stdout.toString().trim()

    return {
      name,
      path: workspacePath,
      branch: changeId,
      isMain: false,
    }
  }

  async listWorktrees(): Promise<WorktreeInfo[]> {
    const cmd = `jj -R ${JSON.stringify(this.repoRoot)} workspace list`
    const result = await this.$`${cmd}`

    if (result.exitCode !== 0) {
      return []
    }

    const output = result.stdout.toString()
    const workspaces: WorktreeInfo[] = []

    for (const line of output.split("\n")) {
      if (!line.trim()) continue

      // Parse workspace list output
      // Format: "name: path (change_id)"
      const match = line.match(/^(\S+):\s+(.+?)(?:\s+\(([^)]+)\))?$/)
      if (match) {
        const [, name, wsPath, changeId] = match
        workspaces.push({
          name,
          path: wsPath,
          branch: changeId,
          isMain: name === "default",
        })
      }
    }

    return workspaces
  }

  async removeWorktree(name: string): Promise<boolean> {
    await this.log.info(`Removing jj workspace: ${name}`)

    // Forget the workspace
    const forgetCmd = `jj -R ${JSON.stringify(this.repoRoot)} workspace forget ${name}`
    const forgetResult = await this.$`${forgetCmd}`

    if (forgetResult.exitCode !== 0) {
      await this.log.warn(`Failed to forget workspace: ${forgetResult.stderr.toString()}`)
      return false
    }

    // Remove the directory
    const workspacePath = path.join(this.worktreeBase, name)
    const rmCmd = `rm -rf ${JSON.stringify(workspacePath)}`
    await this.$`${rmCmd}`

    return true
  }

  async merge(
    source: string,
    target?: string,
    strategy: MergeStrategy = "squash"
  ): Promise<MergeResult> {
    // In jj, we typically squash changes into a target
    // The "source" is a change ID or revision
    // The "target" is where we want to squash into (default: main bookmark)

    const targetRev = target || (await this.getDefaultBranch())

    await this.log.info(`Merging ${source} into ${targetRev} with strategy: ${strategy}`)

    let mergeCmd: string

    switch (strategy) {
      case "squash":
        // Squash the source into the target
        mergeCmd = `jj -R ${JSON.stringify(this.repoRoot)} squash --from ${source} --into ${targetRev}`
        break
      case "rebase":
        // Rebase source onto target
        mergeCmd = `jj -R ${JSON.stringify(this.repoRoot)} rebase -s ${source} -d ${targetRev}`
        break
      case "merge":
      default:
        // Create a merge commit
        mergeCmd = `jj -R ${JSON.stringify(this.repoRoot)} new ${source} ${targetRev} -m "Merge ${source}"`
        break
    }

    const mergeResult = await this.$`${mergeCmd}`

    if (mergeResult.exitCode !== 0) {
      const error = mergeResult.stderr.toString()

      // Check for conflicts
      if (error.includes("conflict") || error.includes("Conflict")) {
        return {
          success: false,
          error: "Merge conflicts detected",
          conflictFiles: [], // jj handles conflicts differently
        }
      }

      return {
        success: false,
        error: `Merge failed: ${error}`,
      }
    }

    // Get the resulting change ID
    const headCmd = `jj -R ${JSON.stringify(this.repoRoot)} log -r @ --no-graph -T 'commit_id'`
    const headResult = await this.$`${headCmd}`
    const commitId = headResult.stdout.toString().trim()

    return {
      success: true,
      commitId,
    }
  }

  async getCurrentBranch(): Promise<string> {
    // In jj, we return the current change ID
    const cmd = `jj -R ${JSON.stringify(this.repoRoot)} log -r @ --no-graph -T 'change_id'`
    const result = await this.$`${cmd}`

    if (result.exitCode !== 0) {
      return "@"
    }

    return result.stdout.toString().trim()
  }

  async getDefaultBranch(): Promise<string> {
    // In jj, look for main/master bookmark or trunk
    const cmd = `jj -R ${JSON.stringify(this.repoRoot)} bookmark list`
    const result = await this.$`${cmd}`

    if (result.exitCode === 0) {
      const output = result.stdout.toString()
      for (const name of ["main", "master", "trunk"]) {
        if (output.includes(name)) {
          return name
        }
      }
    }

    // Fall back to root()
    return "root()"
  }

  async hasUncommittedChanges(): Promise<boolean> {
    // In jj, check if the working copy has modifications
    const cmd = `jj -R ${JSON.stringify(this.repoRoot)} status`
    const result = await this.$`${cmd}`

    const output = result.stdout.toString()
    // If there are working copy changes, status will show them
    return output.includes("Working copy changes:")
  }

  getWorktreeBasePath(): string {
    return this.worktreeBase
  }
}
