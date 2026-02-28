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

import { ConfigManager } from "./config/index.js"
import { FocusManager, ProjectManager } from "./projects/index.js"
import { createLogger } from "./utils/logging/index.js"
import { validateClientOrThrow } from "./utils/validation/index.js"
import type { OpencodeClient } from "./utils/opencode-sdk/index.js"

import { BeadsIssueStorage } from "./issues/beads/index.js"

import {
  PROJECT_RULES,
  buildFocusContext,
  buildCompactionContext,
  buildDelegationCompactionContext,
  buildTeamCompactionContext,
} from "./projects/index.js"
import { DelegationManager, TeamManager, type Delegation, type Team } from "./execution/index.js"
import { WorktreeManager } from "./vcs/index.js"

// Re-exports removed to avoid plugin loader issues.
// The plugin loader may try to call each export as a plugin function.
// Import directly from submodules if needed for external use.

/**
 * Main plugin export
 */
export const ProjectsPlugin: Plugin = async (ctx) => {
  const { client, directory, worktree, $ } = ctx
  
  // Validate client before use to catch SDK version mismatches early
  const typedClient = validateClientOrThrow(client)

  const log = createLogger(typedClient)
  await log.info("opencode-projects plugin initializing")

  const config = await ConfigManager.loadOrThrow()
  const issueStorage = new BeadsIssueStorage(log)
  const focus = new FocusManager()
  issueStorage.setShell($)

  const repoRoot = worktree || directory

  // Create worktree manager
  const worktreeManager = new WorktreeManager(repoRoot, $, log)
  await worktreeManager.detectVCS()

  // Create team config
  const teamConfig = {
    discussionRounds: config.getTeamDiscussionRounds(),
    discussionRoundTimeoutMs: config.getTeamDiscussionRoundTimeoutMs(),
    maxTeamSize: config.getTeamMaxSize(),
    retryFailedMembers: config.getTeamRetryFailedMembers(),
    smallModelTimeoutMs: config.getSmallModelTimeoutMs(),
    delegationTimeoutMs: config.getDelegationTimeoutMs(),
  }

  // Create delegation manager
  const delegationManager = new DelegationManager(
    log,
    typedClient,
    {
      timeoutMs: config.getDelegationTimeoutMs(),
      smallModelTimeoutMs: config.getSmallModelTimeoutMs(),
    }
  )

  // Create team manager (depends on delegationManager - no circular dependency)
  const teamManager = new TeamManager(
    log,
    typedClient,
    delegationManager,
    worktreeManager,
    teamConfig
  )

  // Create project manager with all dependencies
  const projectManager = new ProjectManager(
    config,
    issueStorage,
    focus,
    log,
    repoRoot,
    typedClient,
    $,
    teamManager,
  )

  const beadsAvailable = await issueStorage.isAvailable()
  if (!beadsAvailable.ok || !beadsAvailable.value) {
    await log.warn("beads (bd) not found in PATH - some features will be unavailable")
  }

  await log.info(`opencode-projects initialized in ${repoRoot}`)

  return {
    tool: {
      "project-create": createProjectCreate(projectManager, log),
      "project-list": createProjectList(projectManager, log),
      "project-status": createProjectStatus(projectManager, log),
      "project-focus": createProjectFocus(projectManager, log),
      "project-plan": createProjectPlan(projectManager, log),
      "project-close": createProjectClose(projectManager, log),
      "project-create-issue": createProjectCreateIssue(projectManager, log),
      "project-work-on-issue": createProjectWorkOnIssue(projectManager, teamManager, log),
      "project-update-issue": createProjectUpdateIssue(projectManager, log, $),
      "project-internal-delegation-read": createProjectInternalDelegationRead(projectManager, log),
    },

    "experimental.chat.system.transform": async (_input, output) => {
      output.system.push(PROJECT_RULES)

      const vcsContext = worktreeManager.getVCSContext()
      if (vcsContext) {
        output.system.push(vcsContext)
      }

      const contextBlock = await buildFocusContext(projectManager)
      output.system.push(contextBlock)

      const projectId = projectManager.getFocusedProjectId()
      if (projectId) {
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

      // Get session ID for filtering delegations
      const sessionId = (input as { sessionID?: string }).sessionID

      // Add running and completed delegations, filtered by session
      const allRunning = await delegationManager.list({ status: "running" })
      const allCompleted = await delegationManager.getRecentCompletedDelegations(10)

      // Filter to delegations for this session
      const runningDelegations = sessionId
        ? allRunning.filter((d: Delegation) => d.parentSessionId === sessionId)
        : allRunning
      const completedDelegations = sessionId
        ? allCompleted.filter((d: Delegation) => d.parentSessionId === sessionId)
        : allCompleted

      if (runningDelegations.length > 0 || completedDelegations.length > 0) {
        const delegationContext = buildDelegationCompactionContext(
          runningDelegations,
          completedDelegations
        )
        output.context.push(delegationContext)
      }

      // Add running teams context
      const runningTeams = await teamManager.getRunningTeams()
      const sessionTeams = sessionId
        ? runningTeams.filter((t) => t.parentSessionId === sessionId)
        : runningTeams

      if (sessionTeams.length > 0) {
        const teamContext = buildTeamCompactionContext(sessionTeams)
        output.context.push(teamContext)
      }
    },

    "shell.env": async (_input, output) => {
      const projectId = projectManager.getFocusedProjectId()

      if (projectId) {
        output.env.OPENCODE_PROJECT_ID = projectId
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
