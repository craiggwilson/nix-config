import type { Hook } from "../../hooks/index.js";
import type { ProjectManager } from "../project-manager.js";
import { buildCompactionContext } from "../prompts/index.js";

/**
 * Injects project state context (issues, decisions, artifacts) into the compaction prompt.
 */
export function createProjectCompactionHook(
	projectManager: ProjectManager,
): Hook<"experimental.session.compacting"> {
	return {
		name: "experimental.session.compacting",
		priority: 10,
		handler: async (_input, output) => {
			const projectId = projectManager.getFocusedProjectId();
			if (!projectId) return;

			const contextBlock = await buildCompactionContext(projectManager);
			if (contextBlock) {
				output.context.push(contextBlock);
			}
		},
	};
}
