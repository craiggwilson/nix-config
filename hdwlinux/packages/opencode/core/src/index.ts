/**
 * OpenCode Planner Core
 *
 * Shared utilities and helpers for planning plugins
 */

export { ConfigManager } from "./config.js";
export type { ConfigSchema } from "./config.js";

export { IssueStorage } from "./beads.js";
export type { IssueQuery, DependencyNode, IssueRecord } from "./beads.js";
export type { IssueStorageBackend } from "./storage-backend.js";

export {
  BeadsIssueStorageBackend,
  createBeadsBackend,
  createBeadsCliBackend,
} from "./backends/index.js";
export type { ShellExecutor } from "./backends/index.js";

export { PlanningPlugin, createOpenCodePlugin } from "./plugin.js";
export type { PluginContext, CommandDefinition, ToolDefinition } from "./plugin.js";

export {
  AGENTS,
  getAgent,
  getAgentsByCategory,
  getAgentsByCapability,
  getAllAgentNames,
  agentExists,
} from "./agents.js";
export type { Agent } from "./agents.js";

export {
  SKILLS,
  getSkill,
  getSkillsByCategory,
  getSkillsByOperation,
  getAllSkillNames,
  skillExists,
  getRequiredSkillsForAgent,
} from "./skills.js";
export type { Skill } from "./skills.js";

export { SubagentDispatcher } from "./orchestration/index.js";
export type { SubagentTask, SubagentResult } from "./orchestration/index.js";

export { createSdkExecutionHandler } from "./orchestration/index.js";
export type { OpenCodeClient, SdkDispatchOptions } from "./orchestration/index.js";

export { createRegistry, getRegistry, resetRegistry } from "./plugin-registry.js";
export type { PluginRegistry, PluginRegistryOptions } from "./plugin-registry.js";
