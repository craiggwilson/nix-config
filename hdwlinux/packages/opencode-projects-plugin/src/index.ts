/**
 * opencode-projects
 *
 * Project planning, tracking, and execution plugin for OpenCode.
 * Integrates with beads for issue tracking and supports parallel
 * agent work with VCS worktree isolation.
 *
 * @packageDocumentation
 */

import type { Plugin } from "@opencode-ai/plugin"
import type { Event } from "@opencode-ai/sdk"

import {
  createProjectCreate,
  createProjectList,
  createProjectStatus,
  createProjectFocus,
  createProjectPlan,
  createProjectClose,
  createProjectCreateIssue,
  createProjectWorkOnIssue,
  createProjectUpdateIssue,
  createProjectInternalDelegationRead,
} from "./tools/index.js"

import {
  ConfigManager,
  FocusManager,
  ProjectManager,
  createLogger,
  type OpencodeClient,
} from "./core/index.js"

import { BeadsIssueStorage } from "./storage/index.js"

import { PROJECT_RULES } from "./agents/index.js"
import { WorktreeManager, DelegationManager, type Delegation } from "./execution/index.js"

// Re-exports removed to avoid plugin loader issues.
// The plugin loader may try to call each export as a plugin function.
// Import directly from submodules if needed for external use.

/**
 * Main plugin export
 */
export const ProjectsPlugin: Plugin = async (ctx) => {
  const { client, directory, worktree, $ } = ctx
  const typedClient = client as OpencodeClient

  const log = createLogger(typedClient)
  await log.info("opencode-projects plugin initializing")

  const config = await ConfigManager.load()
  const issueStorage = new BeadsIssueStorage(log)
  const focus = new FocusManager()
  issueStorage.setShell($)

  const repoRoot = worktree || directory

  // Create delegation manager first (uses repoRoot as default project dir)
  const delegationManager = new DelegationManager(
    repoRoot,
    log,
    typedClient,
    {
      timeoutMs: config.getDelegationTimeoutMs(),
      smallModelTimeoutMs: config.getSmallModelTimeoutMs(),
    }
  )

  // Create project manager with all dependencies including shell and delegation manager
  const projectManager = new ProjectManager({
    config,
    issueStorage,
    focus,
    log,
    repoRoot,
    client: typedClient,
    $,
    delegationManager,
  })

  const beadsAvailable = await issueStorage.isAvailable()
  if (!beadsAvailable) {
    await log.warn("beads (bd) not found in PATH - some features will be unavailable")
  }

  await log.info(`opencode-projects initialized in ${repoRoot}`)

  const toolDeps = { client: typedClient, projectManager, issueStorage, log, $, delegationManager }

  return {
    tool: {
      "project-create": createProjectCreate(toolDeps),
      "project-list": createProjectList(toolDeps),
      "project-status": createProjectStatus(toolDeps),
      "project-focus": createProjectFocus(toolDeps),
      "project-plan": createProjectPlan(toolDeps),
      "project-close": createProjectClose(toolDeps),
      "project-create-issue": createProjectCreateIssue(toolDeps),
      "project-work-on-issue": createProjectWorkOnIssue(toolDeps),
      "project-update-issue": createProjectUpdateIssue(toolDeps),
      "project-internal-delegation-read": createProjectInternalDelegationRead(toolDeps),
    },

    "experimental.chat.system.transform": async (_input, output) => {
      output.system.push(PROJECT_RULES)

      const worktreeManager = new WorktreeManager(repoRoot, $, log)
      await worktreeManager.detectVCS()
      const vcsContext = worktreeManager.getVCSContext()
      if (vcsContext) {
        output.system.push(vcsContext)
      }

      const projectId = projectManager.getFocusedProjectId()
      if (projectId) {
        const contextBlock = await buildFocusContext(projectManager)
        if (contextBlock) {
          output.system.push(contextBlock)
        }

        // Add planning context if planning is active
        const planningContext = await buildPlanningContext(projectManager, projectId)
        if (planningContext) {
          output.system.push(planningContext)
        }
      }
    },

    "experimental.session.compacting": async (input, output) => {
      const projectId = projectManager.getFocusedProjectId()
      if (!projectId) return

      const contextBlock = await buildCompactionContext(projectManager)
      if (contextBlock) {
        output.context.push(contextBlock)
      }

      // Issue #8: Get session ID for filtering delegations
      const sessionId = (input as { sessionID?: string }).sessionID

      // Issue #7 & #8: Add running and completed delegations, filtered by session
      const allRunning = await delegationManager.getRunningDelegations()
      const allCompleted = await delegationManager.getRecentCompletedDelegations(10)

      // Filter to delegations for this session (Issue #8)
      const runningDelegations = sessionId
        ? allRunning.filter((d) => d.parentSessionId === sessionId)
        : allRunning
      const completedDelegations = sessionId
        ? allCompleted.filter((d) => d.parentSessionId === sessionId)
        : allCompleted

      if (runningDelegations.length > 0 || completedDelegations.length > 0) {
        const delegationContext = buildDelegationCompactionContext(
          runningDelegations,
          completedDelegations
        )
        output.context.push(delegationContext)
      }
    },

    "shell.env": async (_input, output) => {
      const projectId = projectManager.getFocusedProjectId()
      const issueId = projectManager.getFocusedIssueId()

      if (projectId) {
        output.env.OPENCODE_PROJECT_ID = projectId
      }
      if (issueId) {
        output.env.OPENCODE_ISSUE_ID = issueId
      }
    },

    event: async ({ event }: { event: Event }) => {
      if (event.type === "session.idle") {
        // Check if this is a delegation session
        const sessionId = (event.properties as { sessionID?: string })?.sessionID
        if (sessionId) {
          const delegationId = delegationManager.findBySession(sessionId)
          if (delegationId) {
            await delegationManager.handleSessionIdle(sessionId)
          }
        }
      }
    },
  }
}

/**
 * Build context block for focused project/issue
 */
async function buildFocusContext(projectManager: ProjectManager): Promise<string | null> {
  const projectId = projectManager.getFocusedProjectId()
  if (!projectId) return null

  const sections: string[] = ["<project-context>"]

  sections.push(`## Focused Project: ${projectId}`)

  try {
    const status = await projectManager.getProjectStatus(projectId)
    if (status?.issueStatus) {
      sections.push("")
      sections.push(
        `**Progress:** ${status.issueStatus.completed}/${status.issueStatus.total} issues complete`
      )
      if (status.issueStatus.blockers.length > 0) {
        sections.push(`**Blockers:** ${status.issueStatus.blockers.length}`)
      }
    }
  } catch {
    // Project may not exist
  }

  const issueId = projectManager.getFocusedIssueId()
  if (issueId) {
    sections.push("")
    sections.push(`### Focused Issue: ${issueId}`)

    try {
      const issue = await projectManager.getIssue(projectId, issueId)
      if (issue) {
        sections.push(`**Title:** ${issue.title}`)
        sections.push(`**Status:** ${issue.status}`)
        if (issue.description) {
          sections.push(`**Description:** ${issue.description}`)
        }
      }
    } catch {
      // Issue may not exist
    }
  }

  sections.push("</project-context>")

  return sections.length > 2 ? sections.join("\n") : null
}

/**
 * Build context for session compaction.
 * This context survives compaction and helps the agent resume work.
 */
async function buildCompactionContext(projectManager: ProjectManager): Promise<string | null> {
  const projectId = projectManager.getFocusedProjectId()
  if (!projectId) return null

  const sections: string[] = ["<project-compaction-context>"]

  sections.push(`## Active Project: ${projectId}`)

  const issueId = projectManager.getFocusedIssueId()
  if (issueId) {
    sections.push(`## Current Issue: ${issueId}`)

    try {
      const issue = await projectManager.getIssue(projectId, issueId)
      if (issue) {
        sections.push(`**Title:** ${issue.title}`)
        sections.push(`**Status:** ${issue.status}`)
        if (issue.description) {
          sections.push(`**Description:** ${issue.description}`)
        }
        if (issue.blockedBy && issue.blockedBy.length > 0) {
          sections.push(`**Blocked by:** ${issue.blockedBy.join(", ")}`)
        }
      }
    } catch {
      // Issue may not exist
    }
  }

  try {
    const status = await projectManager.getProjectStatus(projectId)
    if (status?.issueStatus) {
      sections.push("")
      sections.push("## Project Progress")
      sections.push(`- **Completed:** ${status.issueStatus.completed}/${status.issueStatus.total}`)
      sections.push(`- **In Progress:** ${status.issueStatus.inProgress}`)
      sections.push(`- **Blocked:** ${status.issueStatus.blocked}`)
    }
  } catch {
    // Project may not exist
  }

  try {
    const ready = await projectManager.getReadyIssues(projectId)
    if (ready.length > 0) {
      sections.push("")
      sections.push("## Ready Issues (unblocked)")
      for (const issue of ready.slice(0, 5)) {
        const priority = issue.priority !== undefined ? `P${issue.priority}` : ""
        sections.push(`- ${issue.id}: ${issue.title} ${priority}`.trim())
      }
      if (ready.length > 5) {
        sections.push(`- ... and ${ready.length - 5} more`)
      }
    }
  } catch {
    // Project may not exist
  }

  sections.push("")
  sections.push("## Quick Reference")
  sections.push("- `project-status` - Full project state")
  sections.push("- `project-focus` - Change focus")
  sections.push("- `project-work-on-issue` - Start work on an issue")
  sections.push("- `project-update-issue` - Update/close an issue")
  sections.push("- `project-internal-delegation-read` - Read delegation results")
  sections.push("</project-compaction-context>")

  return sections.join("\n")
}

/**
 * Build context for delegations during compaction.
 * Issue #7: Include both running and recent completed delegations.
 */
function buildDelegationCompactionContext(
  running: Delegation[],
  completed: Delegation[]
): string {
  const lines = ["<delegation-context>"]

  if (running.length > 0) {
    lines.push("## Running Delegations")
    lines.push("")

    for (const d of running) {
      lines.push(`### ${d.id}`)
      lines.push(`- **Issue:** ${d.issueId}`)
      lines.push(`- **Agent:** ${d.agent || "(auto)"}`)
      lines.push(`- **Started:** ${d.startedAt}`)
      if (d.worktreePath) {
        lines.push(`- **Worktree:** ${d.worktreePath}`)
      }
      lines.push("")
    }

    lines.push("> You will be notified via `<delegation-notification>` when delegations complete.")
    lines.push("> Do NOT poll for status - continue productive work.")
    lines.push("")
  }

  if (completed.length > 0) {
    lines.push("## Recent Completed Delegations")
    lines.push("")

    for (const d of completed) {
      const statusIcon =
        d.status === "completed" ? "✅" : d.status === "failed" ? "❌" : "⏱️"
      lines.push(`### ${statusIcon} ${d.id}`)
      lines.push(`- **Title:** ${d.title || "(no title)"}`)
      lines.push(`- **Issue:** ${d.issueId}`)
      lines.push(`- **Status:** ${d.status}`)
      if (d.completedAt) {
        lines.push(`- **Completed:** ${d.completedAt}`)
      }
      lines.push("")
    }

    lines.push("> Use `project-internal-delegation-read(id)` to retrieve full results.")
    lines.push("")
  }

  lines.push("</delegation-context>")

  return lines.join("\n")
}

/**
 * Build context for active planning sessions.
 * This provides rich guidance for the planning conversation.
 */
async function buildPlanningContext(
  projectManager: ProjectManager,
  projectId: string
): Promise<string | null> {
  const planningManager = await projectManager.getPlanningManager(projectId)
  if (!planningManager) return null

  return planningManager.buildContext()
}

export default ProjectsPlugin
