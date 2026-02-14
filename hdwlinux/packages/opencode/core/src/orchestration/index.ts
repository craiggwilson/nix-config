/**
 * Orchestration Module
 *
 * Exports subagent orchestration utilities for planning and execution plugins.
 */

export { SubagentDispatcher } from "./subagent-dispatcher.js";
export type { SubagentTask, SubagentResult } from "./subagent-dispatcher.js";

export { createSdkExecutionHandler, buildPrompt, extractInsights } from "./sdk-dispatch.js";
export type { OpenCodeClient, SdkDispatchOptions } from "./sdk-dispatch.js";
