import type { Hook } from "../../hooks/index.js";
import type { ProjectManager } from "../project-manager.js";
import { PROJECT_RULES, buildFocusContext } from "../prompts/index.js";

/**
 * Injects project rules and current focus context into the system prompt.
 */
export function createProjectRulesHook(
	projectManager: ProjectManager,
): Hook<"experimental.chat.system.transform"> {
	return {
		name: "experimental.chat.system.transform",
		priority: 20,
		handler: async (_input, output) => {
			output.system.push(PROJECT_RULES);

			const contextBlock = await buildFocusContext(projectManager);
			output.system.push(contextBlock);
		},
	};
}
