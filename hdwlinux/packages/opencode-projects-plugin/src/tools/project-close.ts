/**
 * project_close tool - Close a project
 */

import { tool } from "@opencode-ai/plugin"
import * as fs from "node:fs/promises"
import * as path from "node:path"

import type { ToolDeps, ProjectToolContext } from "../lib/types.js"

interface ProjectCloseArgs {
  projectId: string
  reason?: "completed" | "cancelled" | "archived"
  summary?: string
}

/**
 * Create the project_close tool
 */
export function createProjectClose(deps: ToolDeps) {
  const { config, focus, repoRoot, log } = deps

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
      const { projectId, reason = "completed", summary } = args

      await log.info(`Closing project: ${projectId}, reason: ${reason}`)

      // Find project directory
      const projectDir = await findProjectDir(projectId, config, repoRoot)

      if (!projectDir) {
        return `Project '${projectId}' not found.\n\nUse \`project_list\` to see available projects.`
      }

      // Load and update metadata
      const metadataPath = path.join(projectDir, "project.json")

      try {
        const content = await fs.readFile(metadataPath, "utf8")
        const metadata = JSON.parse(content) as Record<string, unknown>

        // Update status
        metadata.status = reason === "cancelled" ? "archived" : reason
        metadata.closedAt = new Date().toISOString()
        metadata.closeReason = reason

        if (summary) {
          metadata.closeSummary = summary
        }

        await fs.writeFile(metadataPath, JSON.stringify(metadata, null, 2), "utf8")
      } catch (error) {
        return `Failed to update project metadata: ${error}`
      }

      // Clear focus if this project was focused
      if (focus.isFocusedOn(projectId)) {
        focus.clear()
      }

      // Build response
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
    },
  })
}

/**
 * Find project directory by ID
 */
async function findProjectDir(
  projectId: string,
  config: ToolDeps["config"],
  repoRoot: string
): Promise<string | null> {
  // Check local first
  const localDir = path.join(config.getLocalProjectsDir(repoRoot), projectId)
  try {
    await fs.access(localDir)
    return localDir
  } catch {
    // Not in local
  }

  // Check global
  const globalDir = path.join(config.getGlobalProjectsDir(), projectId)
  try {
    await fs.access(globalDir)
    return globalDir
  } catch {
    // Not in global
  }

  return null
}
