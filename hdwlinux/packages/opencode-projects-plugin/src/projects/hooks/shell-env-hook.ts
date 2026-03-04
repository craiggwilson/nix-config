import type { Hook } from "../../hooks/index.js";
import type { ProjectManager } from "../project-manager.js";

/**
 * Exports the focused project ID as OPENCODE_PROJECT_ID in the shell environment.
 */
export function createShellEnvHook(
	projectManager: ProjectManager,
): Hook<"shell.env"> {
	return {
		name: "shell.env",
		handler: async (_input, output) => {
			const projectId = projectManager.getFocusedProjectId();
			if (projectId) {
				output.env.OPENCODE_PROJECT_ID = projectId;
			}
		},
	};
}
