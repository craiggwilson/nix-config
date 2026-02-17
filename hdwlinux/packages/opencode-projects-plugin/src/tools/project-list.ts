/**
 * project_list tool - List all projects
 */

import { tool } from "@opencode-ai/plugin"
import * as fs from "node:fs/promises"
import * as path from "node:path"

import type { ToolDeps, ProjectToolContext, Project } from "../lib/types.js"

interface ProjectListArgs {
  scope?: "local" | "global" | "all"
  status?: "active" | "completed" | "all"
}

interface ProjectMetadata {
  id: string
  name: string
  type?: string
  description?: string
  storage: "local" | "global"
  workspace?: string
  createdAt: string
  status: "active" | "completed" | "archived"
}

/**
 * Create the project_list tool
 */
export function createProjectList(deps: ToolDeps) {
  const { config, beads, repoRoot, log } = deps

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
      const { scope = "all", status = "all" } = args

      await log.info(`Listing projects: scope=${scope}, status=${status}`)

      const projects: ProjectMetadata[] = []

      // Scan local projects
      if (scope === "local" || scope === "all") {
        const localDir = config.getLocalProjectsDir(repoRoot)
        const localProjects = await scanProjectsDir(localDir, "local")
        projects.push(...localProjects)
      }

      // Scan global projects
      if (scope === "global" || scope === "all") {
        const globalDir = config.getGlobalProjectsDir()
        const globalProjects = await scanProjectsDir(globalDir, "global")
        projects.push(...globalProjects)
      }

      // Filter by status
      const filtered =
        status === "all"
          ? projects
          : projects.filter((p) => p.status === status)

      if (filtered.length === 0) {
        const scopeText = scope === "all" ? "" : ` in ${scope} storage`
        const statusText = status === "all" ? "" : ` with status '${status}'`
        return `No projects found${scopeText}${statusText}.\n\nUse \`project_create\` to create a new project.`
      }

      // Build output
      const lines: string[] = ["## Projects", ""]

      // Group by storage
      const localProjects = filtered.filter((p) => p.storage === "local")
      const globalProjects = filtered.filter((p) => p.storage === "global")

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
    },
  })
}

/**
 * Scan a directory for projects
 */
async function scanProjectsDir(
  dir: string,
  storage: "local" | "global"
): Promise<ProjectMetadata[]> {
  const projects: ProjectMetadata[] = []

  try {
    const entries = await fs.readdir(dir, { withFileTypes: true })

    for (const entry of entries) {
      if (!entry.isDirectory()) continue

      const projectDir = path.join(dir, entry.name)
      const metadataPath = path.join(projectDir, "project.json")

      try {
        const content = await fs.readFile(metadataPath, "utf8")
        const metadata = JSON.parse(content) as ProjectMetadata
        metadata.storage = storage // Ensure storage is set correctly
        projects.push(metadata)
      } catch {
        // No valid project.json, skip
      }
    }
  } catch {
    // Directory doesn't exist
  }

  return projects
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
