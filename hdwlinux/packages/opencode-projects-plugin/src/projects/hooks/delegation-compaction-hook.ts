import type { Hook } from "../../hooks/index.js";
import type { ProjectManager } from "../project-manager.js";
import type { DelegationManager, Delegation } from "../../delegation/index.js";
import { buildDelegationCompactionContext } from "../prompts/index.js";

/**
 * Injects running and recently completed delegation context into the compaction prompt.
 */
export function createDelegationCompactionHook(
	projectManager: ProjectManager,
	delegationManager: DelegationManager,
): Hook<"experimental.session.compacting"> {
	return {
		name: "experimental.session.compacting",
		priority: 20,
		handler: async (input, output) => {
			const projectId = projectManager.getFocusedProjectId();
			if (!projectId) return;

			const sessionId = (input as { sessionID?: string }).sessionID;

			const allRunning = await delegationManager.list({ status: "running" });
			const allCompleted =
				await delegationManager.getRecentCompletedDelegations(10);

			const runningDelegations = sessionId
				? allRunning.filter((d: Delegation) => d.parentSessionId === sessionId)
				: allRunning;
			const completedDelegations = sessionId
				? allCompleted.filter(
						(d: Delegation) => d.parentSessionId === sessionId,
					)
				: allCompleted;

			if (runningDelegations.length > 0 || completedDelegations.length > 0) {
				const delegationContext = buildDelegationCompactionContext(
					runningDelegations,
					completedDelegations,
				);
				output.context.push(delegationContext);
			}
		},
	};
}
