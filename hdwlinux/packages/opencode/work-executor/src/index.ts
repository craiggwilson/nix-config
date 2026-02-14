/**
 * OpenCode Work Executor Plugin
 *
 * Actual implementation of work with specialist subagents for research, POCs, and code review.
 */

import type { Plugin } from "@opencode-ai/plugin";
import { getRegistry } from "../../core/src/plugin-registry.js";

export const WorkExecutorPlugin: Plugin = async (ctx) => {
  const { workExecutor: orchestrator } = getRegistry();

  await orchestrator.initialize();

  return {
    "tui.command.execute": async (input, output) => {
      const command = input.command;
      const args = input.args || [];

      try {
        switch (command) {
          case "work-claim":
            await orchestrator.handleWorkClaim(args);
            output.handled = true;
            break;

          case "work-execute":
            await orchestrator.handleWorkExecute(args);
            output.handled = true;
            break;

          case "work-poc":
            await orchestrator.handleWorkPOC(args);
            output.handled = true;
            break;

          case "work-research":
            await orchestrator.handleWorkResearch(args);
            output.handled = true;
            break;

          case "work-review":
            await orchestrator.handleWorkReview(args);
            output.handled = true;
            break;

          case "work-status":
            await orchestrator.handleWorkStatus(args);
            output.handled = true;
            break;
        }
      } catch (error) {
        await ctx.client.app.log({
          body: {
            service: "work-executor",
            level: "error",
            message: `Error executing command ${command}: ${error}`,
          },
        });
        throw error;
      }
    },
  };
};

export { WorkExecutorOrchestrator } from "./orchestrator.js";
export * from "./types.js";
