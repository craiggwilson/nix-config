/**
 * project-work-on-issue tool - Start work on an issue with a background agent or team
 *
 * Delegates work to a background agent or team of agents. Optionally creates an
 * isolated worktree for code changes that need to be merged back.
 */

import { tool } from "@opencode-ai/plugin"

import type { ProjectToolContext, Tool } from "./tools.js"
import type { Logger, OpencodeClient } from "../utils/opencode-sdk/index.js"
import type { ProjectManager } from "../projects/index.js"
import type { Team, TeamManager } from "../execution/index.js"
import type { DiscussionStrategyType, TeamDiscussionStrategy } from "../execution/index.js"
import { FixedRoundDiscussionStrategy, DynamicRoundDiscussionStrategy, RealtimeDiscussionStrategy } from "../execution/index.js"
import type { ConfigManager, TeamDiscussionSettings } from "../config/index.js"
import { formatError } from "../utils/errors/index.js"
import {
  ProjectWorkOnIssueArgsSchema,
  validateToolArgs,
  formatValidationError,
  type ProjectWorkOnIssueArgs,
} from "../utils/validation/index.js"

function createStrategy(
  settings: TeamDiscussionSettings,
  log: Logger,
  client: OpencodeClient,
  smallModelTimeoutMs: number,
  projectDir: string,
): TeamDiscussionStrategy {
  switch (settings.type) {
    case "fixedRound":
      return new FixedRoundDiscussionStrategy(log, client, { rounds: settings.rounds, roundTimeoutMs: settings.roundTimeoutMs })
    case "dynamicRound":
      return new DynamicRoundDiscussionStrategy(log, client, {
        maxRounds: settings.maxRounds,
        minRounds: settings.minRounds,
        roundTimeoutMs: settings.roundTimeoutMs,
        smallModelTimeoutMs,
      })
    case "realtime":
      return new RealtimeDiscussionStrategy(log, client, {
        baseDir: projectDir,
        pollIntervalMs: settings.pollIntervalMs,
        maxWaitTimeMs: settings.maxWaitTimeMs,
        promptTimeoutMs: settings.promptTimeoutMs,
      })
    default: {
      const _exhaustive: never = settings
      throw new Error(`Unknown discussion strategy type: ${(settings as TeamDiscussionSettings).type}`)
    }
  }
}

/**
 * Create the project-work-on-issue tool
 */
export function createProjectWorkOnIssue(
  projectManager: ProjectManager,
  teamManager: TeamManager,
  log: Logger,
  client: OpencodeClient,
  config: ConfigManager,
): Tool {

  return tool({
    description: `Start work on an issue with a background agent or team.

This tool:
1. Claims the issue (sets status to in_progress)
2. Optionally creates an isolated jj workspace or git worktree (if isolate=true)
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
      discussionStrategy: tool.schema
        .enum(["fixedRound", "dynamicRound", "realtime"])
        .optional()
        .describe("Discussion strategy to use (default: plugin config default)"),
    },

    async execute(args: unknown, ctx: ProjectToolContext): Promise<string> {
      const validationResult = validateToolArgs(ProjectWorkOnIssueArgsSchema, args)
      if (!validationResult.ok) {
        return formatValidationError(validationResult.error)
      }

      try {
        const { issueId, isolate = false, agents, foreground = false, discussionStrategy: discussionStrategyArg } = validationResult.value

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
        const claimed = await projectManager.claimIssueByDir(projectDir, issueId)
        if (!claimed) {
          return `Failed to claim issue '${issueId}'. Check issue storage configuration.`
        }

        // Create team (even single-agent work creates a team of 1)
        const strategyType = discussionStrategyArg ?? config.getDefaultDiscussionStrategy()
        const discussionStrategy = createStrategy(config.getTeamDiscussionSettings(strategyType), log, client, config.getSmallModelTimeoutMs(), projectDir)
        const teamResult = await teamManager.create({
          projectId,
          projectDir,
          issueId,
          issueContext,
          agents: agentsList,
          isolate,
          parentSessionId: ctx.sessionID,
          parentAgent: ctx.agent,
          foreground,
          discussionStrategy,
        })

        if (!teamResult.ok) {
          const error = teamResult.error
          if (error.type === "no_agents_available") {
            return `No agents available for this issue.\n\nIssue context: ${error.issueContext.slice(0, 200)}...`
          }
          return `Failed to create team: ${error.type}`
        }

        const createdTeam = teamResult.value

        // Store team metadata on the issue
        await projectManager.setDelegationMetadataByDir(projectDir, issueId, {
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

  lines.push(`**Discussion Strategy:** ${team.discussionStrategyType}`)
  lines.push("")

  lines.push("---")
  lines.push("")
  lines.push("You will be notified via `<team-notification>` when complete.")
  lines.push("Continue with other work - do NOT poll for status.")
  lines.push("")
  lines.push("Use `project-internal-delegation-read(id)` to retrieve results after compaction.")

  return lines.join("\n")
}
