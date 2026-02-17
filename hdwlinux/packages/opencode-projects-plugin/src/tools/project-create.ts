/**
 * project_create tool - Create a new project and initiate planning
 */

import { tool } from "@opencode-ai/plugin"
import * as fs from "node:fs/promises"
import * as path from "node:path"
import * as crypto from "node:crypto"

import type { ToolDeps, ProjectToolContext } from "../lib/types.js"

interface ProjectCreateArgs {
  name: string
  type?: "roadmap" | "project"
  workspace?: string
  storage?: "local" | "global"
  description?: string
}

/**
 * Generate a project ID from name
 */
function generateProjectId(name: string): string {
  const slug = name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "")
    .slice(0, 30)

  const hash = crypto.randomBytes(3).toString("hex")
  return `${slug}-${hash}`
}

/**
 * Create the project_create tool
 */
export function createProjectCreate(deps: ToolDeps) {
  const { config, beads, focus, repoRoot, log } = deps

  return tool({
    description: `Create a new project and initiate the planning process.

This will:
1. Create the project directory structure
2. Initialize beads for issue tracking
3. Start a conversational planning interview

Use this when starting a new initiative, feature, or long-term effort.`,

    args: {
      name: tool.schema.string().describe("Project name (will be used to generate ID)"),
      type: tool.schema
        .enum(["roadmap", "project"])
        .optional()
        .describe("Planning type: 'roadmap' for 6+ months, 'project' for 0-3 months"),
      workspace: tool.schema
        .string()
        .optional()
        .describe("Repository path (default: current directory)"),
      storage: tool.schema
        .enum(["local", "global"])
        .optional()
        .describe("Storage location: 'local' in repo, 'global' in ~/.local/share"),
      description: tool.schema.string().optional().describe("Initial project description"),
    },

    async execute(args: ProjectCreateArgs, ctx: ProjectToolContext): Promise<string> {
      const { name, type, workspace, storage, description } = args

      await log.info(`Creating project: ${name}`)

      // Generate project ID
      const projectId = generateProjectId(name)

      // Determine workspace root
      const effectiveWorkspace = workspace || repoRoot

      // Determine storage location
      const effectiveStorage = storage || config.getDefaultStorage()

      // Get project directory
      const projectDir = config.resolveProjectDir(projectId, effectiveWorkspace, effectiveStorage)

      // Check if project already exists
      try {
        await fs.access(projectDir)
        return `Project directory already exists at ${projectDir}. Use a different name or remove the existing directory.`
      } catch {
        // Directory doesn't exist, good to proceed
      }

      // Create directory structure
      await fs.mkdir(projectDir, { recursive: true })
      await fs.mkdir(path.join(projectDir, "research"), { recursive: true })
      await fs.mkdir(path.join(projectDir, "interviews"), { recursive: true })
      await fs.mkdir(path.join(projectDir, "plans"), { recursive: true })

      // Initialize beads
      const beadsInitialized = await beads.init(projectDir, {
        stealth: effectiveStorage === "global",
      })

      if (!beadsInitialized) {
        await log.warn("Failed to initialize beads - issue tracking will be limited")
      }

      // Create root epic in beads
      let rootIssueId: string | null = null
      if (beadsInitialized) {
        rootIssueId = await beads.createIssue(projectDir, name, {
          priority: 0,
          description: description || `Root epic for ${name}`,
          labels: ["epic", type || "project"],
        })
      }

      // Create project metadata file
      const metadata = {
        id: projectId,
        name,
        type: type || "project",
        description: description || "",
        storage: effectiveStorage,
        workspace: effectiveWorkspace,
        rootIssue: rootIssueId,
        createdAt: new Date().toISOString(),
        status: "active",
      }

      await fs.writeFile(
        path.join(projectDir, "project.json"),
        JSON.stringify(metadata, null, 2),
        "utf8"
      )

      // Save project overrides to config
      config.setProjectOverrides(projectId, {
        storage: effectiveStorage,
        workspaces: [effectiveWorkspace],
      })
      await config.save()

      // Set focus to new project
      focus.setFocus(projectId)

      // Build response
      const lines: string[] = [
        `## Project Created: ${name}`,
        "",
        `**ID:** ${projectId}`,
        `**Location:** ${projectDir}`,
        `**Storage:** ${effectiveStorage}`,
        `**Type:** ${type || "project"}`,
      ]

      if (rootIssueId) {
        lines.push(`**Root Issue:** ${rootIssueId}`)
      }

      if (!beadsInitialized) {
        lines.push("")
        lines.push("**Warning:** Beads initialization failed. Install beads (`bd`) for full issue tracking.")
      }

      lines.push("")
      lines.push("---")
      lines.push("")
      lines.push("## Next Steps")
      lines.push("")
      lines.push("I'll now guide you through a planning interview to understand the project scope.")
      lines.push("")
      lines.push("**Let's start with the basics:**")
      lines.push("")

      if (type === "roadmap") {
        lines.push("1. What is the high-level vision for this initiative?")
        lines.push("2. What are the key outcomes you want to achieve in the next 6-12 months?")
        lines.push("3. Who are the primary stakeholders?")
      } else {
        lines.push("1. What problem are you trying to solve?")
        lines.push("2. What does success look like for this project?")
        lines.push("3. Are there any hard constraints (timeline, technology, resources)?")
      }

      return lines.join("\n")
    },
  })
}
