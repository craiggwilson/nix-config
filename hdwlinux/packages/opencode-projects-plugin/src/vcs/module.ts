import type { ContainerModule } from "../container/index.js";
import type { TypeSafeContainer } from "../container/index.js";
import { Tokens } from "../container/index.js";
import { WorktreeManager } from "./worktree-manager.js";
import { WorktreeManagerToken } from "./token.js";
import { HookRegistryToken } from "../hooks/index.js";
import { createVcsContextHook } from "./hooks/index.js";

/**
 * Registers VCS module services and hooks into the DI container.
 */
export const vcsModule: ContainerModule = {
	async register(container: TypeSafeContainer): Promise<void> {
		container.register(
			WorktreeManagerToken,
			[Tokens.RepoRoot, Tokens.Shell, Tokens.Logger],
			async (repoRoot, shell, log) => {
				const manager = new WorktreeManager(repoRoot, shell, log);
				await manager.detectVCS();
				return manager;
			},
		);

		container.onBuild((c) => {
			const hookRegistry = c.resolve(HookRegistryToken);
			const worktreeManager = c.resolve(WorktreeManagerToken);

			hookRegistry.register(createVcsContextHook(worktreeManager));
		});
	},
};
