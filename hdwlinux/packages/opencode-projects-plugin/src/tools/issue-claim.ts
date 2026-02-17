/**
 * issue_claim tool - Claim an issue and optionally start isolated work
 */

import { tool } from "@opencode-ai/plugin"
import * as fs from "node:fs/promises"
import * as path from "node:path"

import type { ToolDepsV2, ProjectToolContext, VCSType, BunShell } from "../lib/types.js"

interface IssueClaimArgs {
  issueId: string
  isolate?: boolean
  delegate?: boolean
  agent?: string
}

/**
 * Create the issue_claim tool
 */
export function createIssueClaim(deps: ToolDepsV2) {
  const { projectManager, log, $ } = deps

  return tool({
    description: `Claim an issue and optionally start work in an isolated worktree.

Options:
- isolate: Create a git worktree or jj workspace for isolated work
- delegate: Delegate to a background agent (requires isolate=true)

This atomically claims the issue (sets assignee and status to in_progress).`,

    args: {
      issueId: tool.schema.string().describe("Issue ID to claim (e.g., 'bd-a3f8')"),
      isolate: tool.schema
        .boolean()
        .optional()
        .describe("Create worktree/workspace for isolated work"),
      delegate: tool.schema
        .boolean()
        .optional()
        .describe("Delegate to background agent (requires isolate)"),
      agent: tool.schema
        .string()
        .optional()
        .describe("Agent for delegation (default: 'coder')"),
    },

    async execute(args: IssueClaimArgs, _ctx: ProjectToolContext): Promise<string> {
      const { issueId, isolate = false, delegate = false, agent = "coder" } = args

      // Resolve project ID from focus
      const projectId = projectManager.getFocusedProjectId()

      if (!projectId) {
        return "No project is currently focused.\n\nUse `project_focus(projectId)` to set context before claiming issues."
      }

      await log.info(`Claiming issue ${issueId} in project ${projectId}`)

      // Get issue details first
      const issue = await projectManager.getIssue(projectId, issueId)

      if (!issue) {
        return `Issue '${issueId}' not found in project '${projectId}'.\n\nUse \`project_status\` to see available issues.`
      }

      // Check if already claimed
      if (issue.status === "in_progress") {
        return `Issue '${issueId}' is already in progress${issue.assignee ? ` (assigned to ${issue.assignee})` : ""}.\n\nUse \`project_status\` to see other available issues.`
      }

      // Claim the issue
      const claimed = await projectManager.claimIssue(projectId, issueId)

      if (!claimed) {
        return `Failed to claim issue '${issueId}'. Check issue storage configuration.`
      }

      // Build response
      const lines: string[] = []

      lines.push(`## Issue Claimed: ${issueId}`)
      lines.push("")
      lines.push(`**Title:** ${issue.title}`)
      lines.push(`**Status:** in_progress`)

      if (issue.description) {
        lines.push("")
        lines.push("**Description:**")
        lines.push(issue.description)
      }

      // Handle isolation
      if (isolate) {
        const projectDir = await projectManager.getProjectDir(projectId)
        if (!projectDir) {
          lines.push("")
          lines.push("**Warning:** Could not find project directory for worktree creation.")
        } else {
          // Get the repo root (parent of .projects directory)
          const repoRoot = path.dirname(path.dirname(projectDir))
          const vcs = await detectVCS(repoRoot)

          if (!vcs) {
            lines.push("")
            lines.push("**Warning:** No VCS detected. Cannot create isolated worktree.")
          } else {
            const worktreeResult = await createWorktree(vcs, repoRoot, projectId, issueId, log, $)

            if (worktreeResult.success) {
              lines.push("")
              lines.push("### Isolated Worktree Created")
              lines.push("")
              lines.push(`**Path:** ${worktreeResult.path}`)
              lines.push(`**Branch:** ${worktreeResult.branch}`)
              lines.push(`**VCS:** ${vcs}`)

              // Handle delegation
              if (delegate) {
                lines.push("")
                lines.push("### Background Delegation")
                lines.push("")
                lines.push(`**Agent:** ${agent}`)
                lines.push(`**Status:** Delegation not yet implemented`)
                lines.push("")
                lines.push("TODO: Integrate with background delegation system")
              }
            } else {
              lines.push("")
              lines.push(`**Warning:** Failed to create worktree: ${worktreeResult.error}`)
            }
          }
        }
      }

      lines.push("")
      lines.push("---")
      lines.push("")
      lines.push("**Next Steps:**")

      if (isolate && !delegate) {
        lines.push("- Work in the isolated worktree")
        lines.push("- Commit changes when ready")
        lines.push("- Merge back to main branch")
      } else if (!isolate) {
        lines.push("- Start working on the issue")
        lines.push("- Use `bd update <id> --status closed` when complete")
      }

      lines.push("- `project_status` - Check project progress")

      return lines.join("\n")
    },
  })
}

/**
 * Detect VCS type
 */
async function detectVCS(directory: string): Promise<VCSType | null> {
  // Check for jj first (preferred)
  try {
    await fs.access(path.join(directory, ".jj"))
    return "jj"
  } catch {
    // Not jj
  }

  // Check for git
  try {
    await fs.access(path.join(directory, ".git"))
    return "git"
  } catch {
    // Not git
  }

  return null
}

/**
 * Create a worktree/workspace for isolated work
 */
async function createWorktree(
  vcs: VCSType,
  repoRoot: string,
  projectId: string,
  issueId: string,
  log: ToolDepsV2["log"],
  $: BunShell
): Promise<{ success: boolean; path?: string; branch?: string; error?: string }> {
  // Determine worktree base path
  const repoName = path.basename(repoRoot)
  const basePath = path.join(path.dirname(repoRoot), `${repoName}-worktrees`)

  // Create worktree path
  const worktreePath = path.join(basePath, issueId)
  const branchName = `${projectId}/${issueId}`

  try {
    // Ensure base directory exists
    await fs.mkdir(basePath, { recursive: true })

    if (vcs === "jj") {
      // Create jj workspace
      const cmd = `cd ${JSON.stringify(repoRoot)} && jj workspace add --name ${issueId} ${JSON.stringify(worktreePath)}`
      const result = await $`${cmd}`

      if (result.exitCode !== 0) {
        return { success: false, error: result.stderr.toString() }
      }

      await log.info(`Created jj workspace at ${worktreePath}`)
      return { success: true, path: worktreePath, branch: issueId }
    } else {
      // Create git worktree
      const cmd = `cd ${JSON.stringify(repoRoot)} && git worktree add -b ${branchName} ${JSON.stringify(worktreePath)}`
      const result = await $`${cmd}`

      if (result.exitCode !== 0) {
        return { success: false, error: result.stderr.toString() }
      }

      await log.info(`Created git worktree at ${worktreePath}`)
      return { success: true, path: worktreePath, branch: branchName }
    }
  } catch (error) {
    return { success: false, error: String(error) }
  }
}
