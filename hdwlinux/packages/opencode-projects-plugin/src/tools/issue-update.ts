/**
 * issue_update tool - Update issue fields including status
 */

import { tool } from "@opencode-ai/plugin"

import * as path from "node:path"

import type { ToolDepsV2, ProjectToolContext } from "../core/types.js"
import { WorktreeManager } from "../execution/index.js"

interface IssueUpdateArgs {
  issueId: string
  projectId?: string
  status?: "open" | "in_progress" | "closed"
  assignee?: string
  priority?: number
  description?: string
  labels?: string[]
  blockedBy?: string[]
  mergeWorktree?: boolean
  mergeStrategy?: "squash" | "merge" | "rebase"
  comment?: string
  artifacts?: string[]
}

/**
 * Create the issue_update tool
 */
export function createIssueUpdate(deps: ToolDepsV2) {
  const { projectManager, log, $ } = deps

  return tool({
    description: `Update an issue's fields including status, assignee, priority, and more.

Use this to:
- Close an issue when work is complete
- Change priority or assignee
- Update description or labels
- Add/remove blockers

When closing an issue with mergeWorktree=true, the associated worktree will be merged back to the main branch and cleaned up.`,

    args: {
      issueId: tool.schema.string().describe("Issue ID to update"),
      projectId: tool.schema
        .string()
        .optional()
        .describe("Project ID (default: focused project)"),
      status: tool.schema
        .enum(["open", "in_progress", "closed"])
        .optional()
        .describe("New status for the issue"),
      assignee: tool.schema
        .string()
        .optional()
        .describe("New assignee (use empty string to unassign)"),
      priority: tool.schema
        .number()
        .optional()
        .describe("New priority (0=highest, 3=lowest)"),
      description: tool.schema
        .string()
        .optional()
        .describe("New description"),
      labels: tool.schema
        .array(tool.schema.string())
        .optional()
        .describe("New labels (replaces existing)"),
      blockedBy: tool.schema
        .array(tool.schema.string())
        .optional()
        .describe("Issue IDs that block this issue"),
      mergeWorktree: tool.schema
        .boolean()
        .optional()
        .describe("Merge and cleanup worktree when closing (default: false)"),
      mergeStrategy: tool.schema
        .enum(["squash", "merge", "rebase"])
        .optional()
        .describe("Merge strategy when merging worktree (default: squash)"),
      comment: tool.schema
        .string()
        .optional()
        .describe("Comment to add (e.g., completion summary when closing)"),
      artifacts: tool.schema
        .array(tool.schema.string())
        .optional()
        .describe("Artifacts generated (referenced in completion comment)"),
    },

    async execute(args: IssueUpdateArgs, _ctx: ProjectToolContext): Promise<string> {
      const {
        issueId,
        status,
        assignee,
        priority,
        description,
        labels,
        blockedBy,
        mergeWorktree,
        mergeStrategy = "squash",
        comment,
        artifacts,
      } = args

      // Resolve project ID
      const projectId = args.projectId || projectManager.getFocusedProjectId()

      if (!projectId) {
        return "No project specified and no project is currently focused.\n\nUse `project_focus(projectId)` to set context, or provide projectId explicitly."
      }

      await log.info(`Updating issue ${issueId} in project ${projectId}`)

      // Get current issue state
      const issue = await projectManager.getIssue(projectId, issueId)

      if (!issue) {
        return `Issue '${issueId}' not found in project '${projectId}'.\n\nUse \`project_status\` to see available issues.`
      }

      // Build update options
      const updateOptions: {
        status?: "open" | "in_progress" | "closed"
        assignee?: string
        priority?: number
        description?: string
        labels?: string[]
        blockedBy?: string[]
      } = {}

      if (status !== undefined) updateOptions.status = status
      if (assignee !== undefined) updateOptions.assignee = assignee
      if (priority !== undefined) updateOptions.priority = priority
      if (description !== undefined) updateOptions.description = description
      if (labels !== undefined) updateOptions.labels = labels
      if (blockedBy !== undefined) updateOptions.blockedBy = blockedBy

      // Check if there's anything to update
      if (Object.keys(updateOptions).length === 0) {
        return `No updates specified for issue '${issueId}'.\n\nProvide at least one field to update (status, assignee, priority, description, labels, or blockedBy).`
      }

      // Perform the update
      const updated = await projectManager.updateIssue(projectId, issueId, updateOptions)

      if (!updated) {
        return `Failed to update issue '${issueId}'. Check issue storage configuration.`
      }

      // Build response
      const lines: string[] = []

      lines.push(`## Issue Updated: ${issueId}`)
      lines.push("")
      lines.push(`**Title:** ${issue.title}`)

      // Show what changed
      lines.push("")
      lines.push("### Changes")
      lines.push("")

      if (status !== undefined) {
        const statusIcon =
          status === "closed" ? "✅" : status === "in_progress" ? "🔄" : "⬜"
        lines.push(`- **Status:** ${issue.status} → ${statusIcon} ${status}`)
      }
      if (assignee !== undefined) {
        lines.push(`- **Assignee:** ${issue.assignee || "(none)"} → ${assignee || "(none)"}`)
      }
      if (priority !== undefined) {
        lines.push(`- **Priority:** P${issue.priority ?? "?"} → P${priority}`)
      }
      if (description !== undefined) {
        lines.push(`- **Description:** Updated`)
      }
      if (labels !== undefined) {
        lines.push(`- **Labels:** ${labels.join(", ") || "(none)"}`)
      }
      if (blockedBy !== undefined) {
        lines.push(`- **Blocked By:** ${blockedBy.join(", ") || "(none)"}`)
      }

      // Track merge commit for completion comment
      let mergeCommitId: string | undefined

      // Handle worktree merge if closing and requested
      if (status === "closed" && mergeWorktree) {
        const projectDir = await projectManager.getProjectDir(projectId)
        if (projectDir) {
          // Get repo root (parent of .projects directory)
          const repoRoot = path.dirname(path.dirname(projectDir))
          const worktreeManager = new WorktreeManager(repoRoot, $, log)

          // Check if there's a worktree for this issue
          const worktree = await worktreeManager.getWorktree(projectId, issueId)

          if (worktree) {
            lines.push("")
            lines.push("### Worktree Merge")
            lines.push("")

            const mergeResult = await worktreeManager.mergeAndCleanup(worktree.name, {
              strategy: mergeStrategy,
              cleanup: true,
            })

            if (mergeResult.success) {
              lines.push(`✅ Merged worktree with strategy: ${mergeStrategy}`)
              if (mergeResult.commitId) {
                mergeCommitId = mergeResult.commitId
                lines.push(`**Commit:** ${mergeResult.commitId.slice(0, 8)}`)
              }
              lines.push(`**Worktree cleaned up:** ${worktree.path}`)
            } else {
              lines.push(`⚠️ Merge failed: ${mergeResult.error}`)
              if (mergeResult.conflictFiles?.length) {
                lines.push("")
                lines.push("**Conflict files:**")
                for (const file of mergeResult.conflictFiles) {
                  lines.push(`- ${file}`)
                }
              }
              lines.push("")
              lines.push("Resolve conflicts manually and try again.")
            }
          } else {
            lines.push("")
            lines.push("*No worktree found for this issue.*")
          }
        }
      }

      // Add completion comment when closing
      if (status === "closed") {
        await projectManager.addCompletionComment(projectId, issueId, {
          summary: comment,
          artifacts,
          mergeCommit: mergeCommitId,
        })

        lines.push("")
        lines.push("---")
        lines.push("")
        lines.push("**Issue closed.** Use `project_status` to see remaining work.")
      } else if (comment) {
        // Add regular comment if provided but not closing
        await projectManager.addIssueComment(projectId, issueId, comment)
      }

      if (status === "in_progress") {
        lines.push("")
        lines.push("---")
        lines.push("")
        lines.push("**Issue in progress.** Use `issue_update(status='closed')` when complete.")
      }

      return lines.join("\n")
    },
  })
}
