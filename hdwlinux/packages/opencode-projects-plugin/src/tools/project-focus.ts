/**
 * project-focus tool - Set or get current project context
 */

import { tool } from "@opencode-ai/plugin"

import type { ProjectToolContext, Tool } from "./tools.js"
import type { Logger } from "../utils/opencode-sdk/index.js"
import type { ProjectManager } from "../projects/index.js"
import { formatError } from "../utils/errors/index.js"
import {
  ProjectFocusArgsSchema,
  validateToolArgs,
} from "../utils/validation/index.js"

/**
 * Create the project-focus tool
 */
export function createProjectFocus(
  projectManager: ProjectManager,
  log: Logger,
): Tool {

  return tool({
    description: `Set or get the current project context.

When focused on a project:
- Project context is injected into prompts
- Issue queries are scoped to the project
- Environment variables are set for shell commands

Call without arguments to see current focus.`,

    args: {
      projectId: tool.schema
        .string()
        .optional()
        .describe("Project ID to focus on"),
      clear: tool.schema
        .boolean()
        .optional()
        .describe("Clear current focus"),
    },

    async execute(args: unknown, _ctx: ProjectToolContext): Promise<string> {
      const validationResult = validateToolArgs(ProjectFocusArgsSchema, args)
      if (!validationResult.ok) {
        const lines: string[] = ["## Validation Error", ""]
        lines.push(`**Error:** ${validationResult.error.message}`)
        if (validationResult.error.suggestion) {
          lines.push(`**Suggestion:** ${validationResult.error.suggestion}`)
        }
        return lines.join("\n")
      }

      try {
        const { projectId, clear } = validationResult.value

        if (clear) {
          projectManager.clearFocus()
          await log.info("Focus cleared")
          return "Focus cleared. No project is currently active."
        }

        if (!projectId) {
          const currentProjectId = projectManager.getFocusedProjectId()

          if (!currentProjectId) {
            return "No project is currently focused.\n\nUse `project-focus(projectId)` to set focus, or `project-list` to see available projects."
          }

          const lines: string[] = ["## Current Focus", ""]
          lines.push(`**Project:** ${currentProjectId}`)

          lines.push("")
          lines.push("---")
          lines.push("")
          lines.push("**Actions:**")
          lines.push("- `project-focus(clear=true)` - Clear focus")
          lines.push("- `project-status` - See project progress")
          lines.push("- `project-work-on-issue(issueId)` - Start work on an issue")

          return lines.join("\n")
        }

        const project = await projectManager.getProject(projectId)
        if (!project) {
          return `Project '${projectId}' not found.\n\nUse \`project-list\` to see available projects.`
        }

        projectManager.setFocus(projectId)
        await log.info(`Focus set to project: ${projectId}`)

        const lines: string[] = ["## Focus Set", ""]
        lines.push(`**Project:** ${projectId}`)

        lines.push("")
        lines.push("Context will be injected into subsequent prompts.")

        return lines.join("\n")
      } catch (error) {
        return formatError(error)
      }
    },
  })
}
