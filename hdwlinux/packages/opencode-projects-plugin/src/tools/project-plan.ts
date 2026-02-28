/**
 * project-plan tool - Manage project planning sessions
 *
 * Thin wrapper around PlanningManager.
 */

import { tool } from "@opencode-ai/plugin"

import type { ProjectToolContext, Tool } from "./tools.js"
import type { Logger } from "../utils/opencode-sdk/index.js"
import type { ProjectManager } from "../projects/index.js"
import { formatError } from "../utils/errors/index.js"
import { PlanningManager } from "../planning/index.js"
import {
  ProjectPlanArgsSchema,
  validateToolArgs,
  formatValidationError,
  type ProjectPlanArgs,
} from "../utils/validation/index.js"

/**
 * Create the project-plan tool
 */
export function createProjectPlan(
  projectManager: ProjectManager,
  log: Logger,
): Tool {

  return tool({
    description: `Manage project planning sessions.

Actions:
- start: Begin a new planning session (or continue existing)
- continue: Continue the current planning session (default)
- save: Save progress and summarize current understanding
- advance: Move to the next planning phase
- phase: Jump to a specific phase (requires phase parameter)
- status: Show current planning status

Phases:
- discovery: Understand the problem, stakeholders, timeline, constraints
- synthesis: Consolidate research, make decisions, identify risks
- breakdown: Create issues with proper hierarchy
- complete: Planning is finished

During planning, you can:
- Create research issues with project-create-issue(title="Research: <topic>")
- Start research with project-work-on-issue(issueId)
- When notified of completion, use project-plan(action='save') to incorporate findings`,

    args: {
      projectId: tool.schema
        .string()
        .optional()
        .describe("Project ID (default: focused project)"),
      action: tool.schema
        .enum(["start", "continue", "save", "advance", "phase", "status"])
        .optional()
        .describe("Action to perform (default: continue)"),
      phase: tool.schema
        .enum(["discovery", "synthesis", "breakdown", "complete"])
        .optional()
        .describe("Phase to jump to (only for action='phase')"),
      understanding: tool.schema
        .string()
        .optional()
        .describe("JSON string of understanding updates (for action='save')"),
      openQuestions: tool.schema
        .string()
        .optional()
        .describe("Comma-separated list of open questions (for action='save')"),
    },

    async execute(args: unknown, _ctx: ProjectToolContext): Promise<string> {
      const validationResult = validateToolArgs(ProjectPlanArgsSchema, args)
      if (!validationResult.ok) {
        return formatValidationError(validationResult.error)
      }

      try {
        const { action = "continue", phase, understanding, openQuestions } = validationResult.value

        const projectId = validationResult.value.projectId || projectManager.getFocusedProjectId()

        if (!projectId) {
          return "No project specified and no project is currently focused.\n\nUse `project-create` to start a new project, or `project-focus(projectId)` to set context."
        }

        const projectDir = await projectManager.getProjectDir(projectId)
        if (!projectDir) {
          return `Project '${projectId}' not found.\n\nUse \`project-list\` to see available projects.`
        }

        const planningManager = new PlanningManager(projectDir, log)

        await log.info(`Planning for project: ${projectId}, action: ${action}`)

        switch (action) {
          case "status":
            return planningManager.handleStatus(projectId)

          case "start":
          case "continue":
            return planningManager.handleStartOrContinue(projectId)

          case "save":
            return planningManager.handleSave(projectId, understanding, openQuestions)

          case "advance":
            return planningManager.handleAdvance()

          case "phase":
            if (!phase) {
              return "Error: phase parameter is required for action='phase'"
            }
            return planningManager.handleSetPhase(phase)

          default:
            return `Unknown action: ${action}`
        }
      } catch (error) {
        return formatError(error)
      }
    },
  })
}
