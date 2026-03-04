import type { ContainerModule } from "../container/index.js";
import type { TypeSafeContainer } from "../container/index.js";
import { Tokens } from "../container/index.js";
import { FocusManager } from "./focus-manager.js";
import { ProjectManager } from "./project-manager.js";
import { ProjectManagerToken, FocusManagerToken } from "./token.js";
import { HookRegistryToken } from "../hooks/index.js";
import { ConfigManagerToken } from "../config/index.js";
import { IssueStorageToken } from "../issues/index.js";
import { DelegationManagerToken } from "../delegation/index.js";
import { TeamManagerToken } from "../teams/index.js";
import {
	createDelegationCompactionHook,
	createPlanningContextHook,
	createProjectCompactionHook,
	createProjectRulesHook,
	createSessionCaptureHook,
	createShellEnvHook,
	createTeamCompactionHook,
} from "./hooks/index.js";

/**
 * Registers projects module services and hooks into the DI container.
 */
export const projectsModule: ContainerModule = {
	register(container: TypeSafeContainer): void {
		container.register(FocusManagerToken, [], () => new FocusManager());

		container.register(
			ProjectManagerToken,
			[
				ConfigManagerToken,
				IssueStorageToken,
				FocusManagerToken,
				Tokens.Logger,
				Tokens.RepoRoot,
			],
			(config, issueStorage, focus, log, repoRoot) =>
				new ProjectManager(config, issueStorage, focus, log, repoRoot),
		);

		container.onBuild((c) => {
			const hookRegistry = c.resolve(HookRegistryToken);
			const projectManager = c.resolve(ProjectManagerToken);
			const delegationManager = c.resolve(DelegationManagerToken);
			const teamManager = c.resolve(TeamManagerToken);
			const typedClient = c.resolve(Tokens.Client);
			const config = c.resolve(ConfigManagerToken);
			const log = c.resolve(Tokens.Logger);

			hookRegistry.register(createProjectRulesHook(projectManager));
			hookRegistry.register(createPlanningContextHook(projectManager));
			hookRegistry.register(createShellEnvHook(projectManager));
			hookRegistry.register(createProjectCompactionHook(projectManager));
			hookRegistry.register(
				createDelegationCompactionHook(projectManager, delegationManager),
			);
			hookRegistry.register(
				createTeamCompactionHook(projectManager, teamManager),
			);
			hookRegistry.register(
				createSessionCaptureHook(projectManager, typedClient, log, config),
			);
		});
	},
};
