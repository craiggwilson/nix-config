import type { Hook } from "../../hooks/index.js";
import type { ConfigManager } from "../config-manager.js";
import type { Logger } from "../../utils/opencode-sdk/index.js";
import { OPENCODE_PROJECTS_AGENT_CONFIG } from "../../agents/index.js";
import { OPENCODE_PROJECTS_COMMANDS } from "../../commands/index.js";
import path from "node:path";

/**
 * Registers plugin agents, commands, skill paths, and filesystem permissions into the opencode config.
 */
export function createConfigHook(
	configManager: ConfigManager,
	log: Logger,
	pluginDir: string,
): Hook<"config"> {
	return {
		name: "config",
		handler: async (opencodeConfig: Record<string, unknown>) => {
			const packageRoot = path.resolve(pluginDir, "..");
			const skillsPath = path.resolve(packageRoot, "skills");

			const pluginAgents = {
				"opencode-projects": OPENCODE_PROJECTS_AGENT_CONFIG,
			};

			const pluginSkillPaths = [skillsPath];

			if (!opencodeConfig.agent) {
				opencodeConfig.agent = {};
			}
			Object.assign(
				opencodeConfig.agent as Record<string, unknown>,
				pluginAgents,
			);

			if (!opencodeConfig.command) {
				opencodeConfig.command = {};
			}
			Object.assign(
				opencodeConfig.command as Record<string, unknown>,
				OPENCODE_PROJECTS_COMMANDS,
			);

			if (!opencodeConfig.skills) {
				opencodeConfig.skills = { paths: [] };
			}
			const skillsConfig = opencodeConfig.skills as { paths?: string[] };
			if (!skillsConfig.paths) {
				skillsConfig.paths = [];
			}
			for (const p of pluginSkillPaths) {
				if (!skillsConfig.paths.includes(p)) {
					skillsConfig.paths.push(p);
				}
			}

			const globalProjectsDir = configManager.getGlobalProjectsDir();
			const globalProjectsPattern = `${globalProjectsDir}/*`;
			if (
				!opencodeConfig.permission ||
				typeof opencodeConfig.permission === "object"
			) {
				if (!opencodeConfig.permission) {
					opencodeConfig.permission = {};
				}
				const permissionConfig = opencodeConfig.permission as Record<
					string,
					unknown
				>;
				if (
					!permissionConfig.external_directory ||
					typeof permissionConfig.external_directory === "object"
				) {
					if (!permissionConfig.external_directory) {
						permissionConfig.external_directory = {};
					}
					const externalDir = permissionConfig.external_directory as Record<
						string,
						unknown
					>;
					if (!externalDir[globalProjectsPattern]) {
						externalDir[globalProjectsPattern] = "allow";
					}
				}
			}

			await log.info(
				`Registered ${Object.keys(pluginAgents).length} agent(s), ${Object.keys(OPENCODE_PROJECTS_COMMANDS).length} command(s), and ${pluginSkillPaths.length} skill path(s)`,
			);
		},
	};
}
