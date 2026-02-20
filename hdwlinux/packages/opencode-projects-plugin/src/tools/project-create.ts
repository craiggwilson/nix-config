/**
 * project_create tool - Create a new project and initiate planning
 */

import { tool } from "@opencode-ai/plugin"

import type { ToolDeps, ProjectToolContext } from "../core/types.js"
import { formatError } from "../core/errors.js"

interface ProjectCreateArgs {
  name: string
  type?: "roadmap" | "project"
  workspace?: string
  storage?: "local" | "global"
  description?: string
}

/**
 * Creates the project_create tool for initializing new projects.
 *
 * @param deps - Tool dependencies including ProjectManager and logger
 * @returns OpenCode tool definition
 */
export function createProjectCreate(deps: ToolDeps) {
  const { projectManager, log } = deps

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

    async execute(args: ProjectCreateArgs, _ctx: ProjectToolContext): Promise<string> {
      const { name, type, workspace, storage, description } = args

      await log.info(`Creating project: ${name}`)

      try {
        const result = await projectManager.createProject({
          name,
          type,
          workspace,
          storage,
          description,
        })

  
        const lines: string[] = [
          `## Project Created: ${result.metadata.name}`,
          "",
          `**ID:** ${result.projectId}`,
          `**Location:** ${result.projectDir}`,
          `**Storage:** ${result.metadata.storage}`,
          `**Type:** ${result.metadata.type}`,
        ]

        if (result.rootIssueId) {
          lines.push(`**Root Issue:** ${result.rootIssueId}`)
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
      } catch (error) {
        return formatError(error)
      }
    },
  })
}
