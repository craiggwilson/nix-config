/**
 * issue_create tool - Create an issue within a project
 */

import { tool } from "@opencode-ai/plugin"

import type { ProjectToolContext, Tool } from "./tools.js"
import type { Logger } from "../utils/opencode-sdk/index.js"
import type { ProjectManager } from "../projects/index.js"
import { formatError } from "../utils/errors/index.js"
import {
  ProjectCreateIssueArgsSchema,
  validateToolArgs,
  formatValidationError,
  type ProjectCreateIssueArgs,
} from "../utils/validation/index.js"

/**
 * Create the issue_create tool
 */
export function createProjectCreateIssue(
  projectManager: ProjectManager,
  log: Logger,
): Tool {

  return tool({
    description: `Create an issue within a project.

Issues support:
- Hierarchical IDs (epic → task → subtask)
- Priority levels (P0-P3)
- Dependency relationships
- Labels for categorization`,

    args: {
      title: tool.schema.string().describe("Issue title"),
      projectId: tool.schema
        .string()
        .optional()
        .describe("Project ID (default: focused project)"),
      description: tool.schema.string().optional().describe("Issue description"),
      priority: tool.schema
        .number()
        .optional()
        .describe("Priority level: 0 (highest) to 3 (lowest)"),
      parent: tool.schema
        .string()
        .optional()
        .describe("Parent issue ID for hierarchical structure"),
      blockedBy: tool.schema
        .array(tool.schema.string())
        .optional()
        .describe("Issue IDs that block this issue"),
      labels: tool.schema
        .array(tool.schema.string())
        .optional()
        .describe("Labels to apply"),
    },

    async execute(args: unknown, _ctx: ProjectToolContext): Promise<string> {
      const validationResult = validateToolArgs(ProjectCreateIssueArgsSchema, args)
      if (!validationResult.ok) {
        return formatValidationError(validationResult.error)
      }

      try {
        const { title, description, priority, parent, blockedBy, labels } = validationResult.value

        const projectId = validationResult.value.projectId || projectManager.getFocusedProjectId()

        if (!projectId) {
          return "No project specified and no project is currently focused.\n\nUse `project_focus(projectId)` to set context, or provide projectId explicitly."
        }

        await log.info(`Creating issue in project ${projectId}: ${title}`)

        const project = await projectManager.getProject(projectId)
        if (!project) {
          return `Project '${projectId}' not found.\n\nUse \`project_list\` to see available projects.`
        }

        const result = await projectManager.createIssue(projectId, title, {
          priority,
          parent,
          description,
          labels,
          blockedBy,
        })

        if (!result.ok) {
          const error = result.error
          const lines: string[] = []
          
          lines.push(`## Failed to Create Issue`)
          lines.push("")
          lines.push(`**Error:** ${error.message}`)
          
          if (error.suggestion) {
            lines.push("")
            lines.push(`**Suggestion:** ${error.suggestion}`)
          }
          
          lines.push("")
          lines.push(`**Error Type:** ${error.name}`)
          lines.push(`**Error Code:** ${error.code}`)
          lines.push(`**Recoverable:** ${error.recoverable ? "Yes" : "No"}`)
          
          return lines.join("\n")
        }

        const issueId = result.value
        const lines: string[] = []

        lines.push(`## Issue Created: ${issueId}`)
        lines.push("")
        lines.push(`**Title:** ${title}`)
        lines.push(`**Project:** ${projectId}`)

        if (priority !== undefined) {
          lines.push(`**Priority:** P${priority}`)
        }

        if (parent) {
          lines.push(`**Parent:** ${parent}`)
        }

        if (blockedBy && blockedBy.length > 0) {
          lines.push(`**Blocked By:** ${blockedBy.join(", ")}`)
        }

        if (labels && labels.length > 0) {
          lines.push(`**Labels:** ${labels.join(", ")}`)
        }

        if (description) {
          lines.push("")
          lines.push("**Description:**")
          lines.push(description)
        }

        lines.push("")
        lines.push("---")
        lines.push("")
        lines.push("**Next Steps:**")
        lines.push(`- \`project-work-on-issue(issueId='${issueId}')\` - Start work on this issue`)
        lines.push(`- \`project-create-issue(parent='${issueId}')\` - Add subtasks`)
        lines.push(`- \`project-status\` - View all issues`)

        return lines.join("\n")
      } catch (error) {
        return formatError(error)
      }
    },
  })
}
