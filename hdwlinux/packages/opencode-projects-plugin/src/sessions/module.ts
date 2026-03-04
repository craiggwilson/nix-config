import type { ContainerModule } from "../container/index.js";
import type { TypeSafeContainer } from "../container/index.js";

/**
 * Registers sessions module services into the DI container.
 *
 * SessionManager instances are created per-project by ProjectManager and are
 * not registered as singleton container services. Session compaction hooks live
 * in the projects module, which owns the project state they read and summarise.
 */
export const sessionsModule: ContainerModule = {
	register(_container: TypeSafeContainer): void {
		// No singleton services to register — SessionManager is per-project.
	},
};
