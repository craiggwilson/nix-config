/**
 * project_focus tool - Set or get current project context
 */

import { tool } from "@opencode-ai/plugin"

import type { ToolDepsV2, ProjectToolContext } from "../core/types.js"

interface ProjectFocusArgs {
  projectId?: string
  issueId?: string
  clear?: boolean
}

/**
 * Create the project_focus tool
 */
export function createProjectFocus(deps: ToolDepsV2) {
  const { projectManager, log } = deps

  return tool({
    description: `Set or get the current project context.

When focused on a project:
- Project context is injected into prompts
- Beads queries are scoped to the project
- Environment variables are set for shell commands

Call without arguments to see current focus.`,

    args: {
      projectId: tool.schema
        .string()
        .optional()
        .describe("Project ID to focus on"),
      issueId: tool.schema
        .string()
        .optional()
        .describe("Issue ID to focus on (within the project)"),
      clear: tool.schema
        .boolean()
        .optional()
        .describe("Clear current focus"),
    },

    async execute(args: ProjectFocusArgs, _ctx: ProjectToolContext): Promise<string> {
      const { projectId, issueId, clear } = args


      if (clear) {
        projectManager.clearFocus()
        await log.info("Focus cleared")
        return "Focus cleared. No project or issue is currently active."
      }


      if (!projectId && !issueId) {
        const currentProjectId = projectManager.getFocusedProjectId()
        const currentIssueId = projectManager.getFocusedIssueId()

        if (!currentProjectId) {
          return "No project is currently focused.\n\nUse `project_focus(projectId)` to set focus, or `project_list` to see available projects."
        }

        const lines: string[] = ["## Current Focus", ""]
        lines.push(`**Project:** ${currentProjectId}`)

        if (currentIssueId) {
          lines.push(`**Issue:** ${currentIssueId}`)


          try {
            const issue = await projectManager.getIssue(currentProjectId, currentIssueId)
            if (issue) {
              lines.push(`**Title:** ${issue.title}`)
              lines.push(`**Status:** ${issue.status}`)
            }
          } catch {

          }
        }

        lines.push("")
        lines.push("---")
        lines.push("")
        lines.push("**Actions:**")
        lines.push("- `project_focus(clear=true)` - Clear focus")
        lines.push("- `project_focus(issueId='...')` - Focus on a specific issue")
        lines.push("- `project_status` - See project progress")

        return lines.join("\n")
      }


      if (projectId) {
  
        const project = await projectManager.getProject(projectId)
        if (!project) {
          return `Project '${projectId}' not found.\n\nUse \`project_list\` to see available projects.`
        }

        projectManager.setFocus(projectId, issueId)
        await log.info(`Focus set to project: ${projectId}${issueId ? `, issue: ${issueId}` : ""}`)

        const lines: string[] = ["## Focus Set", ""]
        lines.push(`**Project:** ${projectId}`)

        if (issueId) {
          lines.push(`**Issue:** ${issueId}`)


          try {
            const issue = await projectManager.getIssue(projectId, issueId)
            if (issue) {
              lines.push(`**Title:** ${issue.title}`)
              lines.push(`**Status:** ${issue.status}`)
              if (issue.description) {
                lines.push("")
                lines.push("**Description:**")
                lines.push(issue.description)
              }
            }
          } catch {

          }
        }

        lines.push("")
        lines.push("Context will be injected into subsequent prompts.")

        return lines.join("\n")
      }


      if (issueId) {
        const currentProjectId = projectManager.getFocusedProjectId()

        if (!currentProjectId) {
          return "Cannot focus on an issue without a project.\n\nUse `project_focus(projectId, issueId)` to set both."
        }

        projectManager.setFocus(currentProjectId, issueId)
        await log.info(`Focus set to issue: ${issueId} in project: ${currentProjectId}`)

        const lines: string[] = ["## Issue Focus Set", ""]
        lines.push(`**Project:** ${currentProjectId}`)
        lines.push(`**Issue:** ${issueId}`)

        // Get issue details
        try {
          const issue = await projectManager.getIssue(currentProjectId, issueId)
          if (issue) {
            lines.push(`**Title:** ${issue.title}`)
            lines.push(`**Status:** ${issue.status}`)
            if (issue.description) {
              lines.push("")
              lines.push("**Description:**")
              lines.push(issue.description)
            }
          }
        } catch {
          // Issue details not available
        }

        return lines.join("\n")
      }

      return "Invalid arguments. Provide projectId, issueId, or clear=true."
    },
  })
}
