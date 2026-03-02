/**
 * project-close tool - Close a project
 */

import { tool } from "@opencode-ai/plugin"

import type { ProjectToolContext, Tool } from "./tools.js"
import type { Logger } from "../utils/opencode-sdk/index.js"
import type { ProjectManager } from "../projects/index.js"
import { formatError } from "../utils/errors/index.js"
import {
  ProjectCloseArgsSchema,
  validateToolArgs,
  formatValidationError,
  type ProjectCloseArgs,
} from "../utils/validation/index.js"

/**
 * Create the project-close tool
 */
export function createProjectClose(
  projectManager: ProjectManager,
  log: Logger,
): Tool {

  return tool({
    description: `Close a project (mark as completed, cancelled, or archived).

This updates the project status and optionally adds a final summary.`,

    args: {
      projectId: tool.schema.string().describe("Project ID to close"),
      reason: tool.schema
        .enum(["completed", "cancelled", "archived"])
        .optional()
        .describe("Reason for closing (default: completed)"),
      summary: tool.schema
        .string()
        .optional()
        .describe("Final summary or notes"),
    },

    async execute(args: unknown, _ctx: ProjectToolContext): Promise<string> {
      const validationResult = validateToolArgs(ProjectCloseArgsSchema, args)
      if (!validationResult.ok) {
        return formatValidationError(validationResult.error)
      }

      try {
        const { projectId, reason = "completed", summary } = validationResult.value

        await log.info(`Closing project: ${projectId}, reason: ${reason}`)

        const closed = await projectManager.closeProject(projectId, { reason, summary })

        if (!closed) {
          return `Project '${projectId}' not found.\n\nUse \`project-list\` to see available projects.`
        }

        const lines: string[] = []

        lines.push(`## Project Closed: ${projectId}`)
        lines.push("")
        lines.push(`**Status:** ${reason}`)
        lines.push(`**Closed At:** ${new Date().toISOString()}`)

        if (summary) {
          lines.push("")
          lines.push("**Summary:**")
          lines.push(summary)
        }

        lines.push("")
        lines.push("---")
        lines.push("")
        lines.push("The project has been marked as closed. Use `project-list` to see other projects.")

        return lines.join("\n")
      } catch (error) {
        return formatError(error)
      }
    },
  })
}
