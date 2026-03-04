import type { TypeSafeContainer } from "./container.js";

/**
 * A unit of DI registration for a single domain module.
 *
 * Each domain module (config, vcs, projects, execution, sessions) implements
 * this interface and registers its services into the container. The plugin
 * entry point calls each module's `register()` in dependency order before
 * calling `container.build()`.
 */
export interface ContainerModule {
	/**
	 * Registers this module's services into the container.
	 *
	 * Called during the registration phase, before `container.build()`.
	 * Implementations must not call `container.resolve()` here — resolution
	 * happens only after `build()`.
	 */
	register(container: TypeSafeContainer): void | Promise<void>;
}
