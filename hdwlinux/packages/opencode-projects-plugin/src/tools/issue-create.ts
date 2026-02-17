/**
 * issue_create tool - Create a beads issue within a project
 */

import { tool } from "@opencode-ai/plugin"
import * as fs from "node:fs/promises"
import * as path from "node:path"

import type { ToolDeps, ProjectToolContext } from "../lib/types.js"

interface IssueCreateArgs {
  title: string
  projectId?: string
  description?: string
  priority?: number
  parent?: string
  blockedBy?: string[]
  labels?: string[]
}

/**
 * Create the issue_create tool
 */
export function createIssueCreate(deps: ToolDeps) {
  const { config, beads, focus, repoRoot, log } = deps

  return tool({
    description: `Create a beads issue within a project.

Issues are tracked in beads and support:
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

    async execute(args: IssueCreateArgs, _ctx: ProjectToolContext): Promise<string> {
      const { title, description, priority, parent, blockedBy, labels } = args

      // Resolve project ID
      const projectId = args.projectId || focus.getProjectId()

      if (!projectId) {
        return "No project specified and no project is currently focused.\n\nUse `project_focus(projectId)` to set context, or provide projectId explicitly."
      }

      await log.info(`Creating issue in project ${projectId}: ${title}`)

      // Find project directory
      const projectDir = await findProjectDir(projectId, config, repoRoot)

      if (!projectDir) {
        return `Project '${projectId}' not found.\n\nUse \`project_list\` to see available projects.`
      }

      // Check if beads is initialized
      const beadsInitialized = await beads.isInitialized(projectDir)

      if (!beadsInitialized) {
        return `Beads is not initialized in project '${projectId}'.\n\nRun \`bd init\` in ${projectDir} to initialize issue tracking.`
      }

      // Create the issue
      const issueId = await beads.createIssue(projectDir, title, {
        priority,
        parent,
        description,
        labels,
      })

      if (!issueId) {
        return `Failed to create issue. Check that beads is properly configured.`
      }

      // Add dependencies if specified
      if (blockedBy && blockedBy.length > 0) {
        for (const blockerId of blockedBy) {
          const success = await beads.addDependency(issueId, blockerId, projectDir)
          if (!success) {
            await log.warn(`Failed to add dependency: ${issueId} blocked by ${blockerId}`)
          }
        }
      }

      // Build response
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
      lines.push(`- \`issue_claim('${issueId}')\` - Start work on this issue`)
      lines.push(`- \`issue_create(parent='${issueId}')\` - Add subtasks`)
      lines.push(`- \`project_status\` - See all issues`)

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
