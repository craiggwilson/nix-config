/**
 * project-status tool - Show project progress and blockers
 */

import { tool } from "@opencode-ai/plugin"

import type { ToolDepsV2, ProjectToolContext } from "../core/types.js"
import { renderIssueTree } from "../core/tree-renderer.js"

interface ProjectStatusArgs {
  projectId?: string
  format?: "summary" | "detailed" | "tree"
}

/**
 * Create the project-status tool
 */
export function createProjectStatus(deps: ToolDepsV2) {
  const { projectManager, log } = deps

  return tool({
    description: `Show detailed project status including progress and blockers.

If no projectId is provided, uses the currently focused project.`,

    args: {
      projectId: tool.schema
        .string()
        .optional()
        .describe("Project ID (default: focused project)"),
      format: tool.schema
        .enum(["summary", "detailed", "tree"])
        .optional()
        .describe("Output format: summary, detailed, or tree view"),
    },

    async execute(args: ProjectStatusArgs, _ctx: ProjectToolContext): Promise<string> {
      const { format = "summary" } = args


      const projectId = args.projectId || projectManager.getFocusedProjectId()

      if (!projectId) {
        return "No project specified and no project is currently focused.\n\nUse `project-list` to see available projects, then `project-focus(projectId)` to set context."
      }

      await log.info(`Getting status for project: ${projectId}`)

      // Get project status
      const status = await projectManager.getProjectStatus(projectId)

      if (!status) {
        return `Project '${projectId}' not found.\n\nUse \`project-list\` to see available projects.`
      }

      const { metadata, issueStatus } = status

      // Get issues for detailed/tree view
      const issues = format !== "summary" ? await projectManager.listIssues(projectId) : []
      const readyIssues = await projectManager.getReadyIssues(projectId)


      const lines: string[] = []

      // Header
      lines.push(`## ${metadata.name}`)
      lines.push("")
      lines.push(`**ID:** ${projectId}`)
      lines.push(`**Type:** ${metadata.type}`)
      lines.push(`**Status:** ${metadata.status}`)

      if (metadata.description) {
        lines.push(`**Description:** ${metadata.description}`)
      }

      lines.push("")

      // Progress
      if (issueStatus) {
        const percentage =
          issueStatus.total > 0
            ? Math.round((issueStatus.completed / issueStatus.total) * 100)
            : 0

        lines.push("### Progress")
        lines.push("")
        lines.push(`${renderProgressBar(percentage)} ${percentage}%`)
        lines.push("")
        lines.push(`| Status | Count |`)
        lines.push(`|--------|-------|`)
        lines.push(`| Total | ${issueStatus.total} |`)
        lines.push(`| Completed | ${issueStatus.completed} |`)
        lines.push(`| In Progress | ${issueStatus.inProgress} |`)
        lines.push(`| Blocked | ${issueStatus.blocked} |`)
        lines.push("")
      }

      // Ready issues
      if (readyIssues.length > 0) {
        lines.push("### Ready to Work (No Blockers)")
        lines.push("")
        for (const issue of readyIssues.slice(0, 5)) {
          const priority = issue.priority !== undefined ? `P${issue.priority}` : ""
          lines.push(`- **${issue.id}**: ${issue.title} ${priority}`)
        }
        if (readyIssues.length > 5) {
          lines.push(`- ... and ${readyIssues.length - 5} more`)
        }
        lines.push("")
      }

      // Blockers
      if (issueStatus && issueStatus.blockers.length > 0) {
        lines.push("### Blockers")
        lines.push("")
        for (const blocker of issueStatus.blockers.slice(0, 5)) {
          lines.push(`- **${blocker.issueId}**: ${blocker.title}`)
          lines.push(`  Blocked by: ${blocker.blockedBy.join(", ")}`)
        }
        if (issueStatus.blockers.length > 5) {
          lines.push(`- ... and ${issueStatus.blockers.length - 5} more`)
        }
        lines.push("")
      }

      // Tree view
      if (format === "tree" && issues.length > 0) {
        lines.push("### Issue Hierarchy")
        lines.push("")
        lines.push("```")
        lines.push(renderIssueTree(issues))
        lines.push("```")
        lines.push("")
      }

      // Detailed view
      if (format === "detailed" && issues.length > 0) {
        lines.push("### All Issues")
        lines.push("")
        for (const issue of issues) {
          const statusIcon =
            issue.status === "closed"
              ? "✅"
              : issue.status === "in_progress"
                ? "🔄"
                : "⬜"
          const priority = issue.priority !== undefined ? `P${issue.priority}` : ""
          lines.push(`${statusIcon} **${issue.id}**: ${issue.title} ${priority}`)
          if (issue.assignee) {
            lines.push(`   Assignee: ${issue.assignee}`)
          }
          if (issue.blockedBy && issue.blockedBy.length > 0) {
            lines.push(`   Blocked by: ${issue.blockedBy.join(", ")}`)
          }
        }
        lines.push("")
      }

      // Actions
      lines.push("---")
      lines.push("")
      lines.push("**Actions:**")
      lines.push("- `project-work-on-issue(issueId)` - Start work on an issue")
      lines.push("- `project-create-issue(title)` - Add a new issue")
      lines.push("- `project-plan` - Continue planning")

      return lines.join("\n")
    },
  })
}

/**
 * Render ASCII progress bar
 */
function renderProgressBar(percentage: number): string {
  const width = 20
  const filled = Math.round((percentage / 100) * width)
  const empty = width - filled
  return `[${"█".repeat(filled)}${"░".repeat(empty)}]`
}
