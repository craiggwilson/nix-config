/**
 * opencode-projects
 *
 * Project planning, tracking, and execution plugin for OpenCode.
 * Integrates with beads for issue tracking and supports parallel
 * agent work with VCS worktree isolation.
 *
 * @packageDocumentation
 */

import type { Plugin } from "@opencode-ai/plugin";
import { fileURLToPath } from "node:url";
import path from "node:path";

import {
	createProjectCreate,
	createProjectList,
	createProjectStatus,
	createProjectFocus,
	createProjectPlan,
	createProjectClose,
	createProjectCreateIssue,
	createProjectWorkOnIssue,
	createProjectUpdateIssue,
	createProjectInternalDelegationRead,
	createProjectRecordDecision,
	createProjectSaveArtifact,
} from "./tools/index.js";

import { createLogger } from "./utils/logging/index.js";
import { validateClientOrThrow } from "./utils/validation/index.js";

import { BeadsIssueStorage } from "./issues/beads/index.js";

import { TypeSafeContainer, Tokens } from "./container/index.js";
import { HookRegistry, HookRegistryToken } from "./hooks/index.js";
import { configModule, ConfigManagerToken } from "./config/index.js";
import { vcsModule } from "./vcs/index.js";
import { delegationModule } from "./delegation/index.js";
import { teamsModule, TeamManagerToken } from "./teams/index.js";
import { projectsModule, ProjectManagerToken } from "./projects/index.js";
import { sessionsModule } from "./sessions/index.js";
import { IssueStorageToken } from "./issues/index.js";

// Re-exports removed to avoid plugin loader issues.
// The plugin loader may try to call each export as a plugin function.
// Import directly from submodules if needed for external use.

/**
 * Main plugin export
 */
export const ProjectsPlugin: Plugin = async (ctx) => {
	const { client, directory, worktree, $ } = ctx;

	// Validate client before use to catch SDK version mismatches early
	const typedClient = validateClientOrThrow(client);

	const log = createLogger(typedClient);
	await log.info("opencode-projects plugin initializing");

	const repoRoot = worktree || directory;
	const pluginDir = path.dirname(fileURLToPath(import.meta.url));

	// Build the DI container
	const container = new TypeSafeContainer();

	// Register infrastructure instances
	container.registerInstance(Tokens.Client, typedClient);
	container.registerInstance(Tokens.Shell, $);
	container.registerInstance(Tokens.RepoRoot, repoRoot);
	container.registerInstance(Tokens.PluginDir, pluginDir);
	container.registerInstance(Tokens.Logger, log);
	container.registerInstance(HookRegistryToken, new HookRegistry());
	container.register(
		IssueStorageToken,
		[Tokens.Logger, Tokens.Shell],
		(logger, shell) => {
			const storage = new BeadsIssueStorage(logger);
			storage.setShell(shell);
			return storage;
		},
	);

	// Register domain modules in dependency order
	const modules = [
		configModule,
		vcsModule,
		delegationModule,
		teamsModule,
		projectsModule,
		sessionsModule,
	];
	for (const mod of modules) {
		await mod.register(container);
	}

	await container.build();

	const config = container.resolve(ConfigManagerToken);
	const projectManager = container.resolve(ProjectManagerToken);
	const teamManager = container.resolve(TeamManagerToken);
	const issueStorage = container.resolve(IssueStorageToken);

	const beadsAvailable = await issueStorage.isAvailable();
	if (!beadsAvailable.ok || !beadsAvailable.value) {
		await log.warn(
			"beads (bd) not found in PATH - some features will be unavailable",
		);
	}

	await log.info(`opencode-projects initialized in ${repoRoot}`);

	const hookRegistry = container.resolve(HookRegistryToken);

	return {
		tool: {
			"project-create": createProjectCreate(projectManager, log),
			"project-list": createProjectList(projectManager, log),
			"project-status": createProjectStatus(projectManager, log),
			"project-focus": createProjectFocus(projectManager, log),
			"project-plan": createProjectPlan(projectManager, log),
			"project-close": createProjectClose(projectManager, log),
			"project-create-issue": createProjectCreateIssue(projectManager, log),
			"project-work-on-issue": createProjectWorkOnIssue(
				projectManager,
				teamManager,
				log,
				typedClient,
				config,
			),
			"project-update-issue": createProjectUpdateIssue(projectManager, log, $),
			"project-internal-delegation-read": createProjectInternalDelegationRead(
				projectManager,
				log,
			),
			"project-record-decision": createProjectRecordDecision(
				projectManager,
				log,
			),
			"project-save-artifact": createProjectSaveArtifact(projectManager, log),
		},

		...hookRegistry.buildHooks(log),
	};
};

export default ProjectsPlugin;
