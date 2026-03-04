import type { ContainerModule } from "../container/index.js";
import type { TypeSafeContainer } from "../container/index.js";
import { Tokens } from "../container/index.js";
import { TeamManager } from "./team-manager.js";
import { TeamManagerToken } from "./token.js";
import { DelegationManagerToken } from "../delegation/index.js";
import { WorktreeManagerToken } from "../vcs/index.js";
import { ConfigManagerToken } from "../config/index.js";

/**
 * Registers the TeamManager service into the DI container.
 */
export const teamsModule: ContainerModule = {
	register(container: TypeSafeContainer): void {
		container.register(
			TeamManagerToken,
			[
				Tokens.Logger,
				Tokens.Client,
				DelegationManagerToken,
				WorktreeManagerToken,
				ConfigManagerToken,
			],
			(log, client, delegationManager, worktreeManager, config) =>
				new TeamManager(log, client, delegationManager, worktreeManager, {
					maxTeamSize: config.getTeamMaxSize(),
					retryFailedMembers: config.getTeamRetryFailedMembers(),
					smallModelTimeoutMs: config.getSmallModelTimeoutMs(),
					delegationTimeoutMs: config.getDelegationTimeoutMs(),
				}),
		);
	},
};
