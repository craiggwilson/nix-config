/**
 * Jujutsu Adapter - VCS adapter implementation for Jujutsu (jj)
 */

import * as fs from "node:fs/promises"
import * as path from "node:path"

import type { VCSAdapter, VCSType, WorktreeInfo, MergeSuccess, MergeStrategy } from "../adapter.js"
import type { BunShell, Logger } from "../../utils/opencode-sdk/index.js"
import type { Result } from "../../utils/result/index.js"
import { ok, err } from "../../utils/result/index.js"
import type { ShellResult } from "../../utils/shell/index.js"
import { runShell, buildCommand } from "../../utils/shell/index.js"
import type { VCSError } from "../../utils/errors/index.js"
import {
  VCSCommandError,
  WorktreeError,
  WorktreeExistsError,
  MergeConflictError,
} from "../../utils/errors/index.js"
import { validatePathBoundary } from "../../utils/validation/index.js"

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

    const repoName = path.basename(repoRoot)
    this.worktreeBase = path.join(path.dirname(repoRoot), `${repoName}-workspaces`)
  }

  /**
   * Run a shell command
   */
  private async runCommand(cmd: string): Promise<ShellResult> {
    return runShell(this.$, cmd)
  }

  async createWorktree(name: string, _baseBranch?: string): Promise<Result<WorktreeInfo, VCSError>> {
    const workspacePath = path.join(this.worktreeBase, name)

    const boundaryCheck = validatePathBoundary(this.worktreeBase, workspacePath)
    if (!boundaryCheck.ok) {
      return err(
        new WorktreeError("create", `Path traversal detected: ${boundaryCheck.error.message}`)
      )
    }

    await this.log.info(`Creating jj workspace: ${name} at ${workspacePath}`)

    try {
      await fs.mkdir(path.dirname(workspacePath), { recursive: true })
    } catch (error) {
      return err(
        new WorktreeError("create", `Failed to create directory: ${error}`, error)
      )
    }

    const cmd = buildCommand(this.$, "jj", ["-R", this.repoRoot, "workspace", "add", "--name", name, workspacePath])
    const result = await this.runCommand(cmd)

    if (result.exitCode !== 0) {
      await this.log.error(`Failed to create workspace: ${result.stderr}`)
      
      if (result.stderr.includes("already exists")) {
        return err(new WorktreeExistsError(name, workspacePath))
      }
      
      return err(
        new VCSCommandError("jj workspace add", result.exitCode, result.stderr)
      )
    }

    const changeCmd = buildCommand(this.$, "jj", ["-R", workspacePath, "log", "-r", "@", "--no-graph", "-T", "change_id"])
    const changeResult = await this.runCommand(changeCmd)
    const changeId = changeResult.stdout.trim()

    return ok({
      name,
      path: workspacePath,
      branch: changeId,
      isMain: false,
    })
  }

  async listWorktrees(): Promise<Result<WorktreeInfo[], VCSError>> {
    const cmd = buildCommand(this.$, "jj", ["-R", this.repoRoot, "workspace", "list"])
    const result = await this.runCommand(cmd)

    if (result.exitCode !== 0) {
      return err(
        new VCSCommandError("jj workspace list", result.exitCode, result.stderr)
      )
    }

    const workspaces: WorktreeInfo[] = []

    for (const line of result.stdout.split("\n")) {
      if (!line.trim()) continue

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

    return ok(workspaces)
  }

  async removeWorktree(name: string): Promise<Result<void, VCSError>> {
    await this.log.info(`Removing jj workspace: ${name}`)

    const forgetCmd = buildCommand(this.$, "jj", ["-R", this.repoRoot, "workspace", "forget", name])
    const forgetResult = await this.runCommand(forgetCmd)

    if (forgetResult.exitCode !== 0) {
      await this.log.warn(`Failed to forget workspace: ${forgetResult.stderr}`)
      return err(
        new VCSCommandError("jj workspace forget", forgetResult.exitCode, forgetResult.stderr)
      )
    }

    const workspacePath = path.join(this.worktreeBase, name)
    await this.runCommand(buildCommand(this.$, "rm", ["-rf", workspacePath]))

    return ok(undefined)
  }

  async merge(
    source: string,
    target?: string,
    strategy: MergeStrategy = "squash"
  ): Promise<Result<MergeSuccess, VCSError>> {
    const targetResult = target ? ok(target) : await this.getDefaultBranch()
    if (!targetResult.ok) {
      return targetResult
    }
    const targetRev = targetResult.value

    await this.log.info(`Merging ${source} into ${targetRev} with strategy: ${strategy}`)

    let mergeCmd: string

    switch (strategy) {
      case "squash":
        mergeCmd = buildCommand(this.$, "jj", ["-R", this.repoRoot, "squash", "--from", source, "--into", targetRev])
        break
      case "rebase":
        mergeCmd = buildCommand(this.$, "jj", ["-R", this.repoRoot, "rebase", "-s", source, "-d", targetRev])
        break
      case "merge":
      default:
        mergeCmd = buildCommand(this.$, "jj", ["-R", this.repoRoot, "new", source, targetRev, "-m", `Merge ${source}`])
        break
    }

    const mergeResult = await this.runCommand(mergeCmd)

    if (mergeResult.exitCode !== 0) {
      if (mergeResult.stderr.includes("conflict") || mergeResult.stderr.includes("Conflict")) {
        return err(new MergeConflictError([]))
      }

      return err(
        new VCSCommandError("jj merge", mergeResult.exitCode, mergeResult.stderr)
      )
    }

    const headCmd = buildCommand(this.$, "jj", ["-R", this.repoRoot, "log", "-r", "@", "--no-graph", "-T", "commit_id"])
    const headResult = await this.runCommand(headCmd)
    const commitId = headResult.stdout.trim()

    return ok({ commitId })
  }

  async getCurrentBranch(): Promise<Result<string, VCSError>> {
    const cmd = buildCommand(this.$, "jj", ["-R", this.repoRoot, "log", "-r", "@", "--no-graph", "-T", "change_id"])
    const result = await this.runCommand(cmd)

    if (result.exitCode !== 0) {
      return err(
        new VCSCommandError("jj log", result.exitCode, result.stderr)
      )
    }

    return ok(result.stdout.trim())
  }

  async getDefaultBranch(): Promise<Result<string, VCSError>> {
    const cmd = buildCommand(this.$, "jj", ["-R", this.repoRoot, "bookmark", "list"])
    const result = await this.runCommand(cmd)

    if (result.exitCode === 0) {
      for (const name of ["main", "master", "trunk"]) {
        if (result.stdout.includes(name)) {
          return ok(name)
        }
      }
    }

    return ok("root()")
  }

  async hasUncommittedChanges(): Promise<Result<boolean, VCSError>> {
    const cmd = buildCommand(this.$, "jj", ["-R", this.repoRoot, "status"])
    const result = await this.runCommand(cmd)

    if (result.exitCode !== 0) {
      return err(
        new VCSCommandError("jj status", result.exitCode, result.stderr)
      )
    }

    return ok(result.stdout.includes("Working copy changes:"))
  }

  getWorktreeBasePath(): string {
    return this.worktreeBase
  }
}
