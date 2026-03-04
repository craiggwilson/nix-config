import type { ContainerModule } from "../container/index.js";
import type { TypeSafeContainer } from "../container/index.js";
import { Tokens } from "../container/index.js";
import { ConfigManagerToken } from "./token.js";
import { ConfigManager } from "./config-manager.js";
import { HookRegistryToken } from "../hooks/index.js";
import { createConfigHook } from "./hooks/index.js";

/**
 * Registers config module services and hooks into the DI container.
 */
export const configModule: ContainerModule = {
	register(container: TypeSafeContainer): void {
		container.register(ConfigManagerToken, [], () =>
			ConfigManager.loadOrThrow(),
		);

		container.onBuild((c) => {
			const hookRegistry = c.resolve(HookRegistryToken);
			const configManager = c.resolve(ConfigManagerToken);
			const log = c.resolve(Tokens.Logger);
			const pluginDir = c.resolve(Tokens.PluginDir);

			hookRegistry.register(createConfigHook(configManager, log, pluginDir));
		});
	},
};
