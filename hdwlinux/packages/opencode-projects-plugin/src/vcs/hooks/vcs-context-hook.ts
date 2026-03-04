import type { Hook } from "../../hooks/index.js";
import type { WorktreeManager } from "../worktree-manager.js";

/**
 * Injects VCS context (current branch, worktree info) into the system prompt.
 */
export function createVcsContextHook(
	worktreeManager: WorktreeManager,
): Hook<"experimental.chat.system.transform"> {
	return {
		name: "experimental.chat.system.transform",
		priority: 10,
		handler: (_input, output) => {
			const vcsContext = worktreeManager.getVCSContext();
			if (vcsContext) {
				output.system.push(vcsContext);
			}
		},
	};
}
