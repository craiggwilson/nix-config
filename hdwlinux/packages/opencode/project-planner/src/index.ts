/**
 * OpenCode Project Planner Plugin
 *
 * Repo/service-level backlog management, sprint planning, and execution coordination.
 */

import type { Plugin } from "@opencode-ai/plugin";
import { getRegistry } from "../../core/src/plugin-registry.js";

export const ProjectPlannerPlugin: Plugin = async (ctx) => {
  const { projectPlanner: orchestrator } = getRegistry();

  await orchestrator.initialize();

  return {
    "tui.command.execute": async (input, output) => {
      const command = input.command;
      const args = input.args || [];

      try {
        switch (command) {
          case "project-init":
            await orchestrator.handleProjectInit(args);
            output.handled = true;
            break;

          case "project-plan":
            await orchestrator.handleProjectPlan(args);
            output.handled = true;
            break;

          case "project-sprint":
            await orchestrator.handleProjectSprint(args);
            output.handled = true;
            break;

          case "project-status":
            await orchestrator.handleProjectStatus(args);
            output.handled = true;
            break;

          case "project-focus":
            await orchestrator.handleProjectFocus(args);
            output.handled = true;
            break;

          case "project-list":
            await orchestrator.handleProjectList(args);
            output.handled = true;
            break;
        }
      } catch (error) {
        await ctx.client.app.log({
          body: {
            service: "project-planner",
            level: "error",
            message: `Error executing command ${command}: ${error}`,
          },
        });
        throw error;
      }
    },
  };
};

export { ProjectPlannerOrchestrator } from "./orchestrator.js";
export * from "./types.js";
