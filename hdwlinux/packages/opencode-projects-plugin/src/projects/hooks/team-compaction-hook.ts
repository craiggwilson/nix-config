import type { Hook } from "../../hooks/index.js";
import type { ProjectManager } from "../project-manager.js";
import type { TeamManager } from "../../teams/index.js";
import { buildTeamCompactionContext } from "../prompts/index.js";

/**
 * Injects running team context into the compaction prompt.
 */
export function createTeamCompactionHook(
	projectManager: ProjectManager,
	teamManager: TeamManager,
): Hook<"experimental.session.compacting"> {
	return {
		name: "experimental.session.compacting",
		priority: 30,
		handler: async (input, output) => {
			const projectId = projectManager.getFocusedProjectId();
			if (!projectId) return;

			const sessionId = (input as { sessionID?: string }).sessionID;

			const runningTeams = await teamManager.getRunningTeams();
			const sessionTeams = sessionId
				? runningTeams.filter((t) => t.parentSessionId === sessionId)
				: runningTeams;

			if (sessionTeams.length > 0) {
				const teamContext = buildTeamCompactionContext(sessionTeams);
				output.context.push(teamContext);
			}
		},
	};
}
