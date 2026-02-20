/**
 * project_close tool - Close a project
 */

import { tool } from "@opencode-ai/plugin"

import type { ToolDeps, ProjectToolContext } from "../core/types.js"
import { formatError } from "../core/errors.js"

interface ProjectCloseArgs {
  projectId: string
  reason?: "completed" | "cancelled" | "archived"
  summary?: string
}

/**
 * Create the project_close tool
 */
export function createProjectClose(deps: ToolDeps) {
  const { projectManager, log } = deps

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

    async execute(args: ProjectCloseArgs, _ctx: ProjectToolContext): Promise<string> {
      try {
        const { projectId, reason = "completed", summary } = args

        await log.info(`Closing project: ${projectId}, reason: ${reason}`)

        const closed = await projectManager.closeProject(projectId, { reason, summary })

        if (!closed) {
          return `Project '${projectId}' not found.\n\nUse \`project_list\` to see available projects.`
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
        lines.push("The project has been marked as closed. Use `project_list` to see other projects.")

        return lines.join("\n")
      } catch (error) {
        return formatError(error)
      }
    },
  })
}
