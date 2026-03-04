import type { ContainerModule } from "../container/index.js";
import type { TypeSafeContainer } from "../container/index.js";
import { Tokens } from "../container/index.js";
import { DelegationManager } from "./delegation-manager.js";
import { DelegationManagerToken } from "./token.js";
import { ConfigManagerToken } from "../config/index.js";
import { registerDelegationHooks } from "./hooks/index.js";

/**
 * Registers the DelegationManager service and delegation lifecycle hooks into the DI container.
 */
export const delegationModule: ContainerModule = {
	register(container: TypeSafeContainer): void {
		container.register(
			DelegationManagerToken,
			[Tokens.Logger, Tokens.Client, ConfigManagerToken],
			(log, client, config) =>
				new DelegationManager(log, client, {
					timeoutMs: config.getDelegationTimeoutMs(),
					smallModelTimeoutMs: config.getSmallModelTimeoutMs(),
				}),
		);

		registerDelegationHooks(container);
	},
};
