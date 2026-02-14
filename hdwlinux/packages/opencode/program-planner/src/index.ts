/**
 * OpenCode Program Planner Plugin
 *
 * Long-term program planning, themes, and cross-project roadmaps.
 */

import type { Plugin } from "@opencode-ai/plugin";
import { ProgramPlannerOrchestrator } from "./orchestrator.js";
import { ConfigManager, IssueStorage } from "opencode-planner-core";

export const ProgramPlannerPlugin: Plugin = async (ctx) => {
  const storage = new IssueStorage();
  const configManager = new ConfigManager();
  const orchestrator = new ProgramPlannerOrchestrator(storage, configManager);

  await orchestrator.initialize();

  return {
    "tui.command.execute": async (input, output) => {
      const command = input.command;
      const args = input.args || [];

      try {
        switch (command) {
          case "program-new":
            await orchestrator.handleProgramNew(args);
            output.handled = true;
            break;

          case "program-plan":
            await orchestrator.handleProgramPlan(args);
            output.handled = true;
            break;

          case "program-status":
            await orchestrator.handleProgramStatus(args);
            output.handled = true;
            break;

          case "program-rebalance":
            await orchestrator.handleProgramRebalance(args);
            output.handled = true;
            break;

          case "program-list":
            await orchestrator.handleProgramList(args);
            output.handled = true;
            break;
        }
      } catch (error) {
        await ctx.client.app.log({
          body: {
            service: "program-planner",
            level: "error",
            message: `Error executing command ${command}: ${error}`,
          },
        });
        throw error;
      }
    },
  };
};

export { ProgramPlannerOrchestrator };
export * from "./types.js";
