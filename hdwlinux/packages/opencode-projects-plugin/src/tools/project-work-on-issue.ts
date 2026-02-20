/**
 * project-work-on-issue tool - Start work on an issue with a background agent
 *
 * Delegates work to a background agent. Optionally creates an isolated worktree
 * for code changes that need to be merged back.
 */

import { tool } from "@opencode-ai/plugin"

import type { ToolDeps, ProjectToolContext } from "../core/types.js"
import { formatError } from "../core/errors.js"

interface IssueWorkArgs {
  issueId: string
  isolate?: boolean
  agent?: string
}

/**
 * Create the project-work-on-issue tool
 */
export function createProjectWorkOnIssue(deps: ToolDeps) {
  const { projectManager, log, delegationManager } = deps

  return tool({
    description: `Start work on an issue with a background agent.

This tool:
1. Claims the issue (sets status to in_progress)
2. Optionally creates an isolated git worktree or jj workspace (if isolate=true)
3. Delegates work to a background agent
4. Returns immediately - you'll be notified when complete

Parameters:
- isolate=false (default): Runs in repo root. Good for research, analysis, documentation.
- isolate=true: Creates isolated worktree. Required for code changes that need merging.

When isolate=true, the completion notification includes merge instructions.`,

    args: {
      issueId: tool.schema.string().describe("Issue ID to work on (e.g., 'proj-abc.1')"),
      isolate: tool.schema
        .boolean()
        .optional()
        .describe("Create isolated worktree (default: false). Use true for code changes."),
      agent: tool.schema
        .string()
        .optional()
        .describe("Agent to use for delegation (auto-selected if not specified)"),
    },

    async execute(args: IssueWorkArgs, ctx: ProjectToolContext): Promise<string> {
      try {
        const { issueId, isolate = false, agent } = args

        const projectId = projectManager.getFocusedProjectId()

        if (!projectId) {
          return "No project is currently focused.\n\nUse `project-focus(projectId)` to set context before working on issues."
        }

        // Verify delegation manager is available
        if (!delegationManager) {
          return "Delegation manager not available. Cannot start background work."
        }

        await log.info(`Starting work on issue ${issueId} in project ${projectId} (isolate=${isolate})`)

        // Delegate to ProjectManager
        const result = await projectManager.startWorkOnIssue(projectId, issueId, {
          isolate,
          agent,
          parentSessionId: ctx.sessionID,
        })

        if (!result.success) {
          return result.error || "Failed to start work on issue."
        }

        // Format response
        return formatStartWorkResponse(result)
      } catch (error) {
        return formatError(error)
      }
    },
  })
}

/**
 * Format the response for starting work on an issue
 */
function formatStartWorkResponse(result: {
  issue: { id: string; title: string; description?: string }
  delegation?: { id: string; agent?: string }
  worktreePath?: string
  worktreeBranch?: string
  vcs?: string
}): string {
  const { issue, delegation, worktreePath, worktreeBranch, vcs } = result
  const lines: string[] = []

  lines.push(`## Work Started: ${issue.id}`)
  lines.push("")
  lines.push(`**Title:** ${issue.title}`)
  lines.push(`**Status:** in_progress`)
  lines.push("")

  if (issue.description) {
    lines.push("**Description:**")
    lines.push(issue.description)
    lines.push("")
  }

  if (worktreePath) {
    lines.push("### Isolated Worktree")
    lines.push("")
    lines.push(`**Path:** ${worktreePath}`)
    lines.push(`**Branch:** ${worktreeBranch}`)
    lines.push(`**VCS:** ${vcs}`)
    lines.push("")
    lines.push("*Changes will need to be merged back when complete.*")
    lines.push("")
  } else {
    lines.push("### Execution")
    lines.push("")
    lines.push("**Mode:** Running in repo root (no isolation)")
    lines.push("")
  }

  lines.push("### Background Delegation")
  lines.push("")
  if (delegation?.agent) {
    lines.push(`**Agent:** ${delegation.agent}`)
  } else {
    lines.push(`**Agent:** (OpenCode will decide)`)
  }
  if (delegation) {
    lines.push(`**Delegation ID:** ${delegation.id}`)
  }
  lines.push(`**Status:** Running in background`)
  lines.push("")
  lines.push("---")
  lines.push("")
  lines.push("You will be notified via `<delegation-notification>` when complete.")
  lines.push("Continue with other work - do NOT poll for status.")
  lines.push("")
  lines.push("Use `project-internal-delegation-read(id)` to retrieve results after compaction.")

  return lines.join("\n")
}
