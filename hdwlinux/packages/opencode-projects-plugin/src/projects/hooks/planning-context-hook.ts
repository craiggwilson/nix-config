import type { Hook } from "../../hooks/index.js";
import type { ProjectManager } from "../project-manager.js";

/**
 * Injects the active planning session context into the system prompt when a project is focused.
 */
export function createPlanningContextHook(
	projectManager: ProjectManager,
): Hook<"experimental.chat.system.transform"> {
	return {
		name: "experimental.chat.system.transform",
		priority: 30,
		handler: async (_input, output) => {
			const projectId = projectManager.getFocusedProjectId();
			if (projectId) {
				const planningManager =
					await projectManager.getPlanningManager(projectId);
				if (planningManager) {
					const planningContext = await planningManager.buildContext();
					if (planningContext) {
						output.system.push(planningContext);
					}
				}
			}
		},
	};
}
