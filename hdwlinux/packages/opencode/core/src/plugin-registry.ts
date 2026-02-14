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
import { createSdkExecutionHandler } from "./orchestration/sdk-dispatch.js";
import type { OpenCodeClient } from "./orchestration/sdk-dispatch.js";
import { createBeadsCliBackend } from "./backends/beads-backend.js";
import type { ShellExecutor } from "./backends/beads-backend.js";
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
  /**
   * Shell executor for the beads CLI backend.
   * When provided (and no explicit backend), creates a BeadsCliBackend
   * that delegates to the `bd` CLI.
   */
  shellExecutor?: ShellExecutor;
  /**
   * OpenCode SDK client for real subagent dispatch.
   * When provided (and no explicit dispatcher), creates a dispatcher
   * with an SDK-backed executionHandler.
   */
  client?: OpenCodeClient;
  /** Parent session ID for subagent child sessions. */
  parentSessionId?: string;
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
  // Storage: explicit backend > shell executor > in-memory
  let backend = options?.backend;
  if (!backend && options?.shellExecutor) {
    backend = createBeadsCliBackend(options.shellExecutor);
  }

  const storage = new IssueStorage(backend);
  const configManager = options?.configDir
    ? new ConfigManager(options.configDir)
    : new ConfigManager();

  // Dispatcher: explicit > SDK-backed > default mock
  let dispatcher = options?.dispatcher;
  if (!dispatcher && options?.client) {
    dispatcher = new SubagentDispatcher({
      executionHandler: createSdkExecutionHandler({
        client: options.client,
        parentSessionId: options.parentSessionId,
      }),
    });
  }
  if (!dispatcher) {
    dispatcher = new SubagentDispatcher();
  }

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
