/**
 * project-work-on-issue tool - Start work on an issue with a background agent or team
 *
 * Delegates work to a background agent or team of agents. Optionally creates an
 * isolated worktree for code changes that need to be merged back.
 */

import { tool } from "@opencode-ai/plugin"

import type { ToolDeps, ProjectToolContext, Team } from "../core/types.js"
import { formatError } from "../core/errors.js"

interface IssueWorkArgs {
  issueId: string
  isolate?: boolean
  agents?: string[]
  foreground?: boolean
}

/**
 * Create the project-work-on-issue tool
 */
export function createProjectWorkOnIssue(deps: ToolDeps) {
  const { projectManager, teamManager, log } = deps

  return tool({
    description: `Start work on an issue with a background agent or team.

This tool:
1. Claims the issue (sets status to in_progress)
2. Optionally creates an isolated git worktree or jj workspace (if isolate=true)
3. Delegates work to a background agent or team of agents
4. Returns immediately (or waits if foreground=true)

Parameters:
- isolate=false (default): Runs in repo root. Good for research, analysis, documentation.
- isolate=true: Creates isolated worktree. Required for code changes that need merging.
- agents: Array of agent names to use. Options:
  - Not specified: Small model auto-selects a team (2-4 agents)
  - ["agent-name"]: Single agent (team of 1)
  - ["agent1", "agent2"]: Explicit team (first is PRIMARY, others REVIEW)
- foreground=false (default): Fire-and-forget, notified via <team-notification> when complete.
- foreground=true: Wait for completion and return full results inline.

When using multiple agents, discussion rounds occur after initial work completes.
When isolate=true, the completion notification includes merge instructions.`,

    args: {
      issueId: tool.schema.string().describe("Issue ID to work on (e.g., 'proj-abc.1')"),
      isolate: tool.schema
        .boolean()
        .optional()
        .describe("Create isolated worktree (default: false). Use true for code changes."),
      agents: tool.schema
        .array(tool.schema.string())
        .optional()
        .describe("Agent(s) to use. If not specified, small model auto-selects a team. First agent is PRIMARY, others REVIEW."),
      foreground: tool.schema
        .boolean()
        .optional()
        .describe("Wait for completion instead of fire-and-forget (default: false)"),
    },

    async execute(args: IssueWorkArgs, ctx: ProjectToolContext): Promise<string> {
      try {
        const { issueId, isolate = false, agents, foreground = false } = args

        const projectId = projectManager.getFocusedProjectId()

        if (!projectId) {
          return "No project is currently focused.\n\nUse `project-focus(projectId)` to set context before working on issues."
        }

        // Get project directory
        const projectDir = await projectManager.findProjectDir(projectId)
        if (!projectDir) {
          return `Project '${projectId}' not found.`
        }

        // Get the issue
        const issue = await projectManager.getIssue(projectId, issueId)
        if (!issue) {
          return `Issue '${issueId}' not found in project '${projectId}'.`
        }

        // Check if already in progress
        if (issue.status === "in_progress") {
          return `Issue '${issueId}' is already in progress${issue.assignee ? ` (assigned to ${issue.assignee})` : ""}.`
        }

        await log.info(`Starting work on issue ${issueId} in project ${projectId} (isolate=${isolate}, agents=${agents || "auto-single"}, foreground=${foreground})`)

        // Build issue context for team composition selection
        const issueContext = `${issue.title}\n\n${issue.description || ""}`

        // If agents not specified or empty, undefined means auto-select
        const agentsList = agents && agents.length > 0 ? agents : undefined

        // Claim the issue
        const issueManager = projectManager.getIssueManager()
        const claimed = await issueManager.claimIssue(projectDir, issueId)
        if (!claimed) {
          return `Failed to claim issue '${issueId}'. Check issue storage configuration.`
        }

        // Create team (even single-agent work creates a team of 1)
        const createdTeam = await teamManager.create({
          projectId,
          issueId,
          issueContext,
          agents: agentsList,
          isolate,
          parentSessionId: ctx.sessionID,
          parentAgent: ctx.agent,
          foreground,
        })

        // Store team metadata on the issue
        await issueManager.setDelegationMetadata(projectDir, issueId, {
          delegationId: createdTeam.id,
          delegationStatus: foreground ? createdTeam.status : "running",
        })

        // Format response based on mode
        if (foreground) {
          // In foreground mode, team is already complete
          return formatCompletedTeamResponse(issue, createdTeam)
        } else {
          // In background mode, return immediately
          return formatStartWorkResponse(issue, createdTeam)
        }
      } catch (error) {
        return formatError(error)
      }
    },
  })
}

/**
 * Format the response for a completed team (foreground mode)
 */
function formatCompletedTeamResponse(
  issue: { id: string; title: string; description?: string },
  team: Team
): string {
  const lines: string[] = []

  lines.push(`## Work Completed: ${issue.id}`)
  lines.push("")
  lines.push(`**Title:** ${issue.title}`)
  lines.push(`**Status:** ${team.status}`)
  lines.push(`**Team ID:** ${team.id}`)
  lines.push("")

  if (team.worktreePath) {
    lines.push("### Worktree")
    lines.push("")
    lines.push(`**Path:** ${team.worktreePath}`)
    lines.push(`**Branch:** ${team.worktreeBranch}`)
    lines.push(`**VCS:** ${team.vcs}`)
    lines.push("")
  }

  // Member results
  lines.push("### Team Results")
  lines.push("")

  for (const member of team.members) {
    const roleLabel = member.role === "primary" ? "(PRIMARY)" : member.role === "devilsAdvocate" ? "(DEVIL'S ADVOCATE)" : ""
    lines.push(`#### ${member.agent} ${roleLabel}`)
    lines.push("")
    lines.push(`**Status:** ${member.status}`)
    lines.push("")

    const result = team.results[member.agent]
    if (result) {
      lines.push(result.result)
      lines.push("")
    }
  }

  // Discussion history
  if (team.discussionHistory.length > 0) {
    lines.push("### Discussion")
    lines.push("")

    for (const round of team.discussionHistory) {
      lines.push(`#### Round ${round.round}`)
      lines.push("")

      for (const [agentName, response] of Object.entries(round.responses)) {
        lines.push(`**${agentName}:**`)
        lines.push(response)
        lines.push("")
      }
    }
  }

  // Merge instructions if worktree
  if (team.worktreePath && team.vcs) {
    lines.push("### Merge Instructions")
    lines.push("")

    if (team.vcs === "jj") {
      lines.push("```bash")
      lines.push(`# Review changes`)
      lines.push(`jj diff --from main --to ${team.worktreeBranch}`)
      lines.push("")
      lines.push(`# Squash into main`)
      lines.push(`jj squash --from ${team.worktreeBranch}`)
      lines.push("")
      lines.push(`# Clean up`)
      lines.push(`jj workspace forget ${team.worktreeBranch}`)
      lines.push("```")
    } else {
      lines.push("```bash")
      lines.push(`# Review changes`)
      lines.push(`git diff main..${team.worktreeBranch}`)
      lines.push("")
      lines.push(`# Merge`)
      lines.push(`git merge ${team.worktreeBranch}`)
      lines.push("")
      lines.push(`# Clean up`)
      lines.push(`git worktree remove ${team.worktreePath} && git branch -d ${team.worktreeBranch}`)
      lines.push("```")
    }
    lines.push("")
  }

  return lines.join("\n")
}

/**
 * Format the response for starting work on an issue
 */
function formatStartWorkResponse(
  issue: { id: string; title: string; description?: string },
  team: Team
): string {
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

  if (team.worktreePath) {
    lines.push("### Isolated Worktree")
    lines.push("")
    lines.push(`**Path:** ${team.worktreePath}`)
    lines.push(`**Branch:** ${team.worktreeBranch}`)
    lines.push(`**VCS:** ${team.vcs}`)
    lines.push("")
    lines.push("*Changes will need to be merged back when complete.*")
    lines.push("")
  } else {
    lines.push("### Execution")
    lines.push("")
    lines.push("**Mode:** Running in repo root (no isolation)")
    lines.push("")
  }

  lines.push("### Team")
  lines.push("")
  lines.push(`**Team ID:** ${team.id}`)
  lines.push(`**Members:** ${team.members.length}`)
  lines.push("")

  for (const member of team.members) {
    const roleLabel = member.role === "primary" ? "(PRIMARY)" : member.role === "devilsAdvocate" ? "(DEVIL'S ADVOCATE)" : ""
    lines.push(`- **${member.agent}** ${roleLabel}`)
  }
  lines.push("")

  if (team.discussionRounds > 0) {
    lines.push(`**Discussion Rounds:** ${team.discussionRounds}`)
    lines.push("")
  }

  lines.push("---")
  lines.push("")
  lines.push("You will be notified via `<team-notification>` when complete.")
  lines.push("Continue with other work - do NOT poll for status.")
  lines.push("")
  lines.push("Use `project-internal-delegation-read(id)` to retrieve results after compaction.")

  return lines.join("\n")
}
