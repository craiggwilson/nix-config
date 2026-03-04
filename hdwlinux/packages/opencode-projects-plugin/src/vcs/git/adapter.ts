/**
 * Git Adapter - VCS adapter implementation for Git
 */

import * as fs from "node:fs/promises";
import * as path from "node:path";

import type {
	VCSAdapter,
	VCSType,
	WorktreeInfo,
	MergeSuccess,
	MergeStrategy,
} from "../adapter.js";
import type { BunShell, Logger } from "../../utils/opencode-sdk/index.js";
import type { Result } from "../../utils/result/index.js";
import { ok, err } from "../../utils/result/index.js";
import type { ShellResult } from "../../utils/shell/index.js";
import { runShell, buildCommand } from "../../utils/shell/index.js";
import type { VCSError } from "../../utils/errors/index.js";
import {
	VCSCommandError,
	WorktreeError,
	WorktreeExistsError,
	MergeConflictError,
} from "../../utils/errors/index.js";
import { validatePathBoundary } from "../../utils/validation/index.js";

/**
 * Git implementation of VCSAdapter
 */
export class GitAdapter implements VCSAdapter {
	readonly type: VCSType = "git";
	readonly repoRoot: string;

	private $: BunShell;
	private log: Logger;
	private worktreeBase: string;

	constructor(repoRoot: string, shell: BunShell, log: Logger) {
		this.repoRoot = repoRoot;
		this.$ = shell;
		this.log = log;

		const repoName = path.basename(repoRoot);
		this.worktreeBase = path.join(
			path.dirname(repoRoot),
			`${repoName}-worktrees`,
		);
	}

	/**
	 * Run a shell command
	 */
	private async runCommand(cmd: string): Promise<ShellResult> {
		return runShell(this.$, cmd);
	}

	async createWorktree(
		name: string,
		baseBranch?: string,
	): Promise<Result<WorktreeInfo, VCSError>> {
		const worktreePath = path.join(this.worktreeBase, name);
		const branchName = name.replace(/\//g, "-");

		const boundaryCheck = validatePathBoundary(this.worktreeBase, worktreePath);
		if (!boundaryCheck.ok) {
			return err(
				new WorktreeError(
					"create",
					`Path traversal detected: ${boundaryCheck.error.message}`,
				),
			);
		}

		await this.log.info(`Creating git worktree: ${name} at ${worktreePath}`);

		try {
			await fs.mkdir(path.dirname(worktreePath), { recursive: true });
		} catch (error) {
			return err(
				new WorktreeError(
					"create",
					`Failed to create directory: ${error}`,
					error,
				),
			);
		}

		const baseResult = baseBranch
			? ok(baseBranch)
			: await this.getDefaultBranch();
		if (!baseResult.ok) {
			return baseResult;
		}
		const base = baseResult.value;

		const cmd = buildCommand(this.$, "git", [
			"-C",
			this.repoRoot,
			"worktree",
			"add",
			"-b",
			branchName,
			worktreePath,
			base,
		]);
		const result = await this.runCommand(cmd);

		if (result.exitCode !== 0) {
			await this.log.error(`Failed to create worktree: ${result.stderr}`);

			if (result.stderr.includes("already exists")) {
				return err(new WorktreeExistsError(name, worktreePath));
			}

			return err(
				new VCSCommandError("git worktree add", result.exitCode, result.stderr),
			);
		}

		return ok({
			name,
			path: worktreePath,
			branch: branchName,
			isMain: false,
		});
	}

	async listWorktrees(): Promise<Result<WorktreeInfo[], VCSError>> {
		const cmd = buildCommand(this.$, "git", [
			"-C",
			this.repoRoot,
			"worktree",
			"list",
			"--porcelain",
		]);
		const result = await this.runCommand(cmd);

		if (result.exitCode !== 0) {
			return err(
				new VCSCommandError(
					"git worktree list",
					result.exitCode,
					result.stderr,
				),
			);
		}

		const worktrees: WorktreeInfo[] = [];
		let current: Partial<WorktreeInfo> = {};

		for (const line of result.stdout.split("\n")) {
			if (line.startsWith("worktree ")) {
				if (current.path) {
					worktrees.push(current as WorktreeInfo);
				}
				current = {
					path: line.slice(9),
					isMain: false,
				};
			} else if (line.startsWith("branch ")) {
				current.branch = line.slice(7).replace("refs/heads/", "");
			} else if (line === "bare") {
				current.isMain = true;
			}
		}

		if (current.path) {
			worktrees.push(current as WorktreeInfo);
		}

		const namedWorktrees = worktrees.map((wt) => {
			let name: string;
			if (wt.path.startsWith(this.worktreeBase)) {
				name = path.relative(this.worktreeBase, wt.path);
			} else {
				name = path.basename(wt.path);
			}
			return {
				...wt,
				name,
				isMain: wt.path === this.repoRoot,
			};
		});

		return ok(namedWorktrees);
	}

	async removeWorktree(name: string): Promise<Result<void, VCSError>> {
		const worktreePath = path.join(this.worktreeBase, name);

		await this.log.info(`Removing git worktree: ${name}`);

		const removeCmd = buildCommand(this.$, "git", [
			"-C",
			this.repoRoot,
			"worktree",
			"remove",
			worktreePath,
			"--force",
		]);
		const removeResult = await this.runCommand(removeCmd);

		if (removeResult.exitCode !== 0) {
			await this.log.warn(`Failed to remove worktree: ${removeResult.stderr}`);
			return err(
				new VCSCommandError(
					"git worktree remove",
					removeResult.exitCode,
					removeResult.stderr,
				),
			);
		}

		const branchName = name.replace(/\//g, "-");
		const branchCmd = buildCommand(this.$, "git", [
			"-C",
			this.repoRoot,
			"branch",
			"-D",
			branchName,
		]);
		await this.runCommand(branchCmd);

		return ok(undefined);
	}

	async merge(
		source: string,
		target?: string,
		strategy: MergeStrategy = "squash",
	): Promise<Result<MergeSuccess, VCSError>> {
		const targetResult = target ? ok(target) : await this.getDefaultBranch();
		if (!targetResult.ok) {
			return targetResult;
		}
		const targetBranch = targetResult.value;

		await this.log.info(
			`Merging ${source} into ${targetBranch} with strategy: ${strategy}`,
		);

		const checkoutCmd = buildCommand(this.$, "git", [
			"-C",
			this.repoRoot,
			"checkout",
			targetBranch,
		]);
		const checkoutResult = await this.runCommand(checkoutCmd);

		if (checkoutResult.exitCode !== 0) {
			return err(
				new VCSCommandError(
					"git checkout",
					checkoutResult.exitCode,
					checkoutResult.stderr,
				),
			);
		}

		let mergeCmd: string;
		switch (strategy) {
			case "squash":
				mergeCmd = buildCommand(this.$, "git", [
					"-C",
					this.repoRoot,
					"merge",
					"--squash",
					source,
				]);
				break;
			case "rebase":
				mergeCmd = buildCommand(this.$, "git", [
					"-C",
					this.repoRoot,
					"rebase",
					source,
				]);
				break;
			default:
				mergeCmd = buildCommand(this.$, "git", [
					"-C",
					this.repoRoot,
					"merge",
					source,
				]);
				break;
		}

		const mergeResult = await this.runCommand(mergeCmd);

		if (mergeResult.exitCode !== 0) {
			if (
				mergeResult.stderr.includes("CONFLICT") ||
				mergeResult.stderr.includes("conflict")
			) {
				const conflictCmd = buildCommand(this.$, "git", [
					"-C",
					this.repoRoot,
					"diff",
					"--name-only",
					"--diff-filter=U",
				]);
				const conflictResult = await this.runCommand(conflictCmd);
				const conflictFiles = conflictResult.stdout
					.trim()
					.split("\n")
					.filter(Boolean);

				return err(new MergeConflictError(conflictFiles));
			}

			return err(
				new VCSCommandError(
					"git merge",
					mergeResult.exitCode,
					mergeResult.stderr,
				),
			);
		}

		if (strategy === "squash") {
			const commitCmd = buildCommand(this.$, "git", [
				"-C",
				this.repoRoot,
				"commit",
				"-m",
				`Merge ${source} (squashed)`,
			]);
			const commitResult = await this.runCommand(commitCmd);

			if (commitResult.exitCode !== 0) {
				if (!commitResult.stdout.includes("nothing to commit")) {
					return err(
						new VCSCommandError(
							"git commit",
							commitResult.exitCode,
							commitResult.stderr,
						),
					);
				}
			}
		}

		const headCmd = buildCommand(this.$, "git", [
			"-C",
			this.repoRoot,
			"rev-parse",
			"HEAD",
		]);
		const headResult = await this.runCommand(headCmd);
		const commitId = headResult.stdout.trim();

		return ok({ commitId });
	}

	async getCurrentBranch(): Promise<Result<string, VCSError>> {
		const cmd = buildCommand(this.$, "git", [
			"-C",
			this.repoRoot,
			"rev-parse",
			"--abbrev-ref",
			"HEAD",
		]);
		const result = await this.runCommand(cmd);

		if (result.exitCode !== 0) {
			return err(
				new VCSCommandError("git rev-parse", result.exitCode, result.stderr),
			);
		}

		return ok(result.stdout.trim());
	}

	async getDefaultBranch(): Promise<Result<string, VCSError>> {
		const remoteCmd = `${buildCommand(this.$, "git", ["-C", this.repoRoot, "symbolic-ref", "refs/remotes/origin/HEAD"])} 2>/dev/null`;
		const remoteResult = await this.runCommand(remoteCmd);

		if (remoteResult.exitCode === 0) {
			const ref = remoteResult.stdout.trim();
			return ok(ref.replace("refs/remotes/origin/", ""));
		}

		for (const branch of ["main", "master", "trunk"]) {
			const checkCmd = `${buildCommand(this.$, "git", ["-C", this.repoRoot, "rev-parse", "--verify", branch])} 2>/dev/null`;
			const checkResult = await this.runCommand(checkCmd);
			if (checkResult.exitCode === 0) {
				return ok(branch);
			}
		}

		return ok("main");
	}

	async hasUncommittedChanges(): Promise<Result<boolean, VCSError>> {
		const cmd = buildCommand(this.$, "git", [
			"-C",
			this.repoRoot,
			"status",
			"--porcelain",
		]);
		const result = await this.runCommand(cmd);

		if (result.exitCode !== 0) {
			return err(
				new VCSCommandError("git status", result.exitCode, result.stderr),
			);
		}

		return ok(result.stdout.trim().length > 0);
	}

	getWorktreeBasePath(): string {
		return this.worktreeBase;
	}
}
