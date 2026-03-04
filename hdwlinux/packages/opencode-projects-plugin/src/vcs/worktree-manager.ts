/**
 * WorktreeManager - High-level worktree operations
 *
 * Provides a unified interface for managing worktrees/workspaces
 * across different VCS systems (git and jj).
 */

import * as fs from "node:fs/promises";
import * as path from "node:path";

import type {
	VCSAdapter,
	VCSType,
	WorktreeInfo,
	MergeSuccess,
	MergeStrategy,
} from "./adapter.js";
import { GitAdapter } from "./git/index.js";
import { JujutsuAdapter } from "./jujutsu/index.js";
import type { BunShell, Logger } from "../utils/opencode-sdk/index.js";
import type { Result } from "../utils/result/index.js";
import { ok, err, isOk } from "../utils/result/index.js";
import type { VCSError } from "../utils/errors/index.js";
import { VCSNotDetectedError, WorktreeError } from "../utils/errors/index.js";
import { createSafeWorktreeName } from "../utils/validation/index.js";

/**
 * Options for creating a worktree
 */
export interface CreateWorktreeOptions {
	projectId: string;
	issueId: string;
	baseBranch?: string;
}

/**
 * Options for merging a worktree
 */
export interface MergeWorktreeOptions {
	targetBranch?: string;
	strategy?: MergeStrategy;
	cleanup?: boolean; // Remove worktree after merge (default: true)
}

/**
 * WorktreeManager - manages worktrees across VCS systems
 */
export class WorktreeManager {
	private repoRoot: string;
	private $: BunShell;
	private log: Logger;
	private adapter: VCSAdapter | null = null;
	private vcsType: VCSType | null = null;

	constructor(repoRoot: string, shell: BunShell, log: Logger) {
		this.repoRoot = repoRoot;
		this.$ = shell;
		this.log = log;
	}

	/**
	 * Detect the VCS type and initialize the appropriate adapter
	 */
	async detectVCS(): Promise<Result<VCSAdapter, VCSError>> {
		if (this.adapter) {
			return ok(this.adapter);
		}

		try {
			await fs.access(path.join(this.repoRoot, ".jj"));
			this.vcsType = "jj";
			this.adapter = new JujutsuAdapter(this.repoRoot, this.$, this.log);
			await this.log.info("Detected Jujutsu (jj) repository");
			return ok(this.adapter);
		} catch {
			// jj not detected, try git
		}

		try {
			await fs.access(path.join(this.repoRoot, ".git"));
			this.vcsType = "git";
			this.adapter = new GitAdapter(this.repoRoot, this.$, this.log);
			await this.log.info("Detected Git repository");
			return ok(this.adapter);
		} catch {
			// git not detected
		}

		await this.log.warn("No VCS detected in repository");
		return err(new VCSNotDetectedError(this.repoRoot));
	}

	/**
	 * Get the VCS type (jj or git)
	 */
	getVCSType(): VCSType | null {
		return this.vcsType;
	}

	/**
	 * Get the VCS adapter
	 */
	getAdapter(): VCSAdapter | null {
		return this.adapter;
	}

	/**
	 * Create an isolated worktree for working on an issue
	 *
	 * The worktree name is the issue ID. Since issue IDs already contain the
	 * project ID as a prefix, prepending it again would be redundant.
	 */
	async createIsolatedWorktree(
		options: CreateWorktreeOptions,
	): Promise<Result<WorktreeInfo, VCSError>> {
		const adapterResult = await this.detectVCS();
		if (!isOk(adapterResult)) {
			return adapterResult;
		}

		const { projectId, issueId, baseBranch } = options;

		const nameResult = createSafeWorktreeName(projectId, issueId);
		if (!nameResult.ok) {
			return nameResult;
		}
		const name = nameResult.value;

		const result = await adapterResult.value.createWorktree(name, baseBranch);
		if (isOk(result)) {
			await this.log.info(
				`Created worktree for ${issueId} at ${result.value.path}`,
			);
		}
		return result;
	}

	/**
	 * List all worktrees for a project
	 *
	 * Filters by worktrees whose name starts with the project ID, since issue IDs
	 * are formatted as `{projectId}-{shortId}`.
	 */
	async listProjectWorktrees(
		projectId: string,
	): Promise<Result<WorktreeInfo[], VCSError>> {
		const adapterResult = await this.detectVCS();
		if (!isOk(adapterResult)) {
			return adapterResult;
		}

		const worktreesResult = await adapterResult.value.listWorktrees();
		if (!isOk(worktreesResult)) {
			return worktreesResult;
		}

		const filtered = worktreesResult.value.filter((wt) =>
			wt.name.startsWith(`${projectId}-`),
		);
		return ok(filtered);
	}

	/**
	 * List all worktrees
	 */
	async listAllWorktrees(): Promise<Result<WorktreeInfo[], VCSError>> {
		const adapterResult = await this.detectVCS();
		if (!isOk(adapterResult)) {
			return adapterResult;
		}

		return adapterResult.value.listWorktrees();
	}

	/**
	 * Get a specific worktree by issue ID
	 */
	async getWorktree(
		projectId: string,
		issueId: string,
	): Promise<Result<WorktreeInfo | null, VCSError>> {
		const nameResult = createSafeWorktreeName(projectId, issueId);
		if (!nameResult.ok) {
			return nameResult;
		}
		const name = nameResult.value;

		const adapterResult = await this.detectVCS();
		if (!isOk(adapterResult)) {
			return adapterResult;
		}

		const worktreesResult = await adapterResult.value.listWorktrees();
		if (!isOk(worktreesResult)) {
			return worktreesResult;
		}

		const worktree =
			worktreesResult.value.find((wt) => wt.name === name) || null;
		return ok(worktree);
	}

	/**
	 * Merge a worktree back to the target branch and optionally clean up
	 */
	async mergeAndCleanup(
		worktreeName: string,
		options: MergeWorktreeOptions = {},
	): Promise<Result<MergeSuccess, VCSError>> {
		const adapterResult = await this.detectVCS();
		if (!isOk(adapterResult)) {
			return adapterResult;
		}
		const adapter = adapterResult.value;

		const { targetBranch, strategy = "squash", cleanup = true } = options;

		const worktreesResult = await adapter.listWorktrees();
		if (!isOk(worktreesResult)) {
			return worktreesResult;
		}

		const worktree = worktreesResult.value.find(
			(wt) => wt.name === worktreeName,
		);
		if (!worktree) {
			return err(
				new WorktreeError("merge", `Worktree '${worktreeName}' not found`),
			);
		}

		const source = worktree.branch || worktreeName;

		const result = await adapter.merge(source, targetBranch, strategy);

		if (!isOk(result)) {
			return result;
		}

		if (cleanup) {
			const removeResult = await adapter.removeWorktree(worktreeName);
			if (!isOk(removeResult)) {
				await this.log.warn(
					`Failed to remove worktree after merge: ${worktreeName}`,
				);
			}
		}

		return result;
	}

	/**
	 * Remove a worktree without merging
	 */
	async removeWorktree(worktreeName: string): Promise<Result<void, VCSError>> {
		const adapterResult = await this.detectVCS();
		if (!isOk(adapterResult)) {
			return adapterResult;
		}

		return adapterResult.value.removeWorktree(worktreeName);
	}

	/**
	 * Check if there are uncommitted changes in the main repo
	 */
	async hasUncommittedChanges(): Promise<Result<boolean, VCSError>> {
		const adapterResult = await this.detectVCS();
		if (!isOk(adapterResult)) {
			return adapterResult;
		}

		return adapterResult.value.hasUncommittedChanges();
	}

	/**
	 * Get the current branch/change
	 */
	async getCurrentBranch(): Promise<Result<string, VCSError>> {
		const adapterResult = await this.detectVCS();
		if (!isOk(adapterResult)) {
			return adapterResult;
		}

		return adapterResult.value.getCurrentBranch();
	}

	/**
	 * Get the default branch
	 */
	async getDefaultBranch(): Promise<Result<string, VCSError>> {
		const adapterResult = await this.detectVCS();
		if (!isOk(adapterResult)) {
			return adapterResult;
		}

		return adapterResult.value.getDefaultBranch();
	}

	/**
	 * Get the base path where worktrees are stored
	 */
	getWorktreeBasePath(): string | null {
		return this.adapter?.getWorktreeBasePath() || null;
	}

	/**
	 * Get VCS context for prompt injection
	 *
	 * Returns a string describing the VCS type for inclusion in prompts
	 */
	getVCSContext(): string | null {
		if (!this.vcsType) {
			return null;
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
</vcs-context>`;
		}

		return `<vcs-context>
This repository uses **Git** for version control.
Use \`git\` commands for all VCS operations:
- \`git status\` - Show working tree status
- \`git diff\` - Show changes
- \`git add . && git commit -m "message"\` - Stage and commit
- \`git checkout -b <branch>\` - Create a new branch
- \`git merge <branch>\` - Merge a branch
</vcs-context>`;
	}
}
