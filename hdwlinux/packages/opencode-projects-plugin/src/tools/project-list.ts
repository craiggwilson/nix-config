/**
 * project_list tool - List all projects
 */

import { tool } from "@opencode-ai/plugin"

import type { ToolDeps, ProjectToolContext } from "../core/types.js"
import type { ProjectMetadata } from "../core/project-manager.js"
import { formatError } from "../core/errors.js"

interface ProjectListArgs {
  scope?: "local" | "global" | "all"
  status?: "active" | "completed" | "all"
}

/**
 * Create the project_list tool
 */
export function createProjectList(deps: ToolDeps) {
  const { projectManager, log } = deps

  return tool({
    description: `List all projects (local and/or global).

Shows project name, status, and issue counts.`,

    args: {
      scope: tool.schema
        .enum(["local", "global", "all"])
        .optional()
        .describe("Filter by storage location (default: all)"),
      status: tool.schema
        .enum(["active", "completed", "all"])
        .optional()
        .describe("Filter by project status (default: all)"),
    },

    async execute(args: ProjectListArgs, _ctx: ProjectToolContext): Promise<string> {
      try {
        const { scope = "all", status = "all" } = args

        await log.info(`Listing projects: scope=${scope}, status=${status}`)

        const projects = await projectManager.listProjects({ scope, status })

        if (projects.length === 0) {
          const scopeText = scope === "all" ? "" : ` in ${scope} storage`
          const statusText = status === "all" ? "" : ` with status '${status}'`
          return `No projects found${scopeText}${statusText}.\n\nUse \`project_create\` to create a new project.`
        }

        const lines: string[] = ["## Projects", ""]

        const localProjects = projects.filter((p) => p.storage === "local")
        const globalProjects = projects.filter((p) => p.storage === "global")

        if (localProjects.length > 0 && (scope === "local" || scope === "all")) {
          lines.push("### Local (Repository)")
          lines.push("")
          for (const project of localProjects) {
            lines.push(formatProject(project))
          }
          lines.push("")
        }

        if (globalProjects.length > 0 && (scope === "global" || scope === "all")) {
          lines.push("### Global")
          lines.push("")
          for (const project of globalProjects) {
            lines.push(formatProject(project))
          }
          lines.push("")
        }

        lines.push("---")
        lines.push("")
        lines.push("Use `project_focus(projectId)` to set context for a project.")
        lines.push("Use `project_status(projectId)` to see detailed progress.")

        return lines.join("\n")
      } catch (error) {
        return formatError(error)
      }
    },
  })
}

/**
 * Format a project for display
 */
function formatProject(project: ProjectMetadata): string {
  const statusIcon =
    project.status === "active"
      ? "🟢"
      : project.status === "completed"
        ? "✅"
        : "📦"

  const typeLabel = project.type === "roadmap" ? "[Roadmap]" : "[Project]"

  let line = `- ${statusIcon} **${project.name}** (${project.id}) ${typeLabel}`

  if (project.description) {
    const shortDesc =
      project.description.length > 60
        ? project.description.slice(0, 57) + "..."
        : project.description
    line += `\n  ${shortDesc}`
  }

  return line
}
