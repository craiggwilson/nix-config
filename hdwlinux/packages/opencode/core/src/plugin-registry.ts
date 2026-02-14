/**
 * Plugin Registry
 *
 * Creates shared instances of storage, config, and dispatcher, then
 * wires the cross-plugin delegate chain so that program planner can
 * delegate to project planner, and project planner can delegate to
 * work executor.
 *
 * Each plugin's index.ts should call `getRegistry()` instead of
 * creating its own IssueStorage / ConfigManager / orchestrators.
 */

import { IssueStorage } from "./beads.js";
import type { IssueStorageBackend } from "./storage-backend.js";
import { ConfigManager } from "./config.js";
import { SubagentDispatcher } from "./orchestration/subagent-dispatcher.js";
import { ProgramPlannerOrchestrator } from "../../program-planner/src/orchestrator.js";
import type { ProjectPlannerDelegate } from "../../program-planner/src/orchestrator.js";
import { ProjectPlannerOrchestrator } from "../../project-planner/src/orchestrator.js";
import type { WorkExecutorDelegate } from "../../project-planner/src/orchestrator.js";
import { WorkExecutorOrchestrator } from "../../work-executor/src/orchestrator.js";

export interface PluginRegistryOptions {
  /** Optional storage backend (e.g. beads-backed). */
  backend?: IssueStorageBackend;
  /** Optional config directory override. */
  configDir?: string;
  /** Optional pre-built SubagentDispatcher. */
  dispatcher?: SubagentDispatcher;
}

export interface PluginRegistry {
  storage: IssueStorage;
  configManager: ConfigManager;
  dispatcher: SubagentDispatcher;
  programPlanner: ProgramPlannerOrchestrator;
  projectPlanner: ProjectPlannerOrchestrator;
  workExecutor: WorkExecutorOrchestrator;
}

let _instance: PluginRegistry | null = null;

/**
 * Build a fresh PluginRegistry.
 *
 * Creates shared instances and wires the delegate chain:
 *   program-planner  →  project-planner  →  work-executor
 */
export function createRegistry(options?: PluginRegistryOptions): PluginRegistry {
  const storage = new IssueStorage(options?.backend);
  const configManager = options?.configDir
    ? new ConfigManager(options.configDir)
    : new ConfigManager();
  const dispatcher = options?.dispatcher ?? new SubagentDispatcher();

  const programPlanner = new ProgramPlannerOrchestrator(storage, configManager, { dispatcher });
  const projectPlanner = new ProjectPlannerOrchestrator(storage, configManager, { dispatcher });
  const workExecutor = new WorkExecutorOrchestrator(storage, configManager, { dispatcher });

  // Wire program-planner → project-planner delegate
  const projectPlannerDelegate: ProjectPlannerDelegate = {
    planProject: (input) => projectPlanner.planProject(input),
  };
  programPlanner.setProjectPlannerDelegate(projectPlannerDelegate);

  // Wire project-planner → work-executor delegate
  const workExecutorDelegate: WorkExecutorDelegate = {
    executeWork: (input) => workExecutor.executeWork(input),
  };
  projectPlanner.setWorkExecutorDelegate(workExecutorDelegate);

  return {
    storage,
    configManager,
    dispatcher,
    programPlanner,
    projectPlanner,
    workExecutor,
  };
}

/**
 * Get or create the singleton PluginRegistry.
 *
 * Plugins that run in the same process should share one registry so
 * they all operate on the same IssueStorage and delegate chain.
 * Call `resetRegistry()` in tests to get a clean slate.
 */
export function getRegistry(options?: PluginRegistryOptions): PluginRegistry {
  if (!_instance) {
    _instance = createRegistry(options);
  }
  return _instance;
}

/**
 * Reset the singleton so the next `getRegistry()` call creates a
 * fresh instance.  Intended for tests.
 */
export function resetRegistry(): void {
  _instance = null;
}
