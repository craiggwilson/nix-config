/**
 * Projects module - Project and focus management
 */

export { ProjectManager } from "./project-manager.js";
export type {
	ProjectMetadata,
	CreateProjectOptions,
	ListProjectsOptions,
	CloseProjectOptions,
	CreateProjectResult,
} from "./project-manager.js";

export { FocusManager } from "./focus-manager.js";
export type { FocusState } from "./focus-manager.js";

// Prompts
export {
	PROJECT_RULES,
	buildFocusContext,
	buildCompactionContext,
	buildDelegationCompactionContext,
	buildTeamCompactionContext,
} from "./prompts/index.js";

export { projectsModule } from "./module.js";

export { ProjectManagerToken, FocusManagerToken } from "./token.js";
