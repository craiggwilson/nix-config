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
import { fileURLToPath } from "url"
import path from "path"

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
  createProjectRecordDecision,
  createProjectSaveArtifact,
} from "./tools/index.js"

import { ConfigManager } from "./config/index.js"
import { FocusManager, ProjectManager } from "./projects/index.js"
import { createLogger } from "./utils/logging/index.js"
import { validateClientOrThrow } from "./utils/validation/index.js"
import type { OpencodeClient } from "./utils/opencode-sdk/index.js"

import { BeadsIssueStorage } from "./issues/beads/index.js"
import { extractConversationContent } from "./utils/conversation/index.js"

import {
  PROJECT_RULES,
  buildFocusContext,
  buildCompactionContext,
  buildDelegationCompactionContext,
  buildTeamCompactionContext,
} from "./projects/index.js"
import { summarizeSession } from "./sessions/index.js"
import { DelegationManager, TeamManager, type Delegation, type Team } from "./execution/index.js"
import { WorktreeManager } from "./vcs/index.js"
import { OPENCODE_PROJECTS_AGENT_CONFIG } from "./agents/index.js"

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
      "project-record-decision": createProjectRecordDecision(projectManager, log),
      "project-save-artifact": createProjectSaveArtifact(projectManager, log),
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

      // Capture session summary if we have a session ID
      if (sessionId) {
        try {
          const sessionManager = await projectManager.getSessionManager(projectId)
          if (sessionManager) {
            const conversationContent = extractConversationContent(input)

            if (conversationContent) {
              const metadata = await projectManager.getProjectMetadata(projectId)
              const planningManager = await projectManager.getPlanningManager(projectId)
              const planningState = await planningManager?.getState()
              const planningPhase = planningState?.phase

              const summaryResult = await summarizeSession(typedClient, log, {
                conversationContent,
                projectName: metadata?.name,
                planningPhase,
                timeoutMs: config.getSmallModelTimeoutMs(),
              })

              if (summaryResult.ok) {
                await sessionManager.captureSession({
                  sessionId,
                  summary: summaryResult.value.summary,
                  keyPoints: summaryResult.value.keyPoints,
                  openQuestionsAdded: summaryResult.value.openQuestionsAdded,
                  decisionsMade: summaryResult.value.decisionsMade,
                })

                if (summaryResult.value.whatsNext.length > 0) {
                  await sessionManager.updateIndex({
                    whatsNext: summaryResult.value.whatsNext,
                  })
                }

                await log.debug(`Session ${sessionId} captured for project ${projectId}`)
              }
            }
          }
        } catch (error) {
          await log.warn(`Failed to capture session: ${error}`)
        }
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

    config: async (opencodeConfig: Record<string, unknown>) => {
      const pluginDir = path.dirname(fileURLToPath(import.meta.url))
      const packageRoot = path.resolve(pluginDir, "..")
      const skillsPath = path.resolve(packageRoot, "skills")

      const pluginAgents = {
        "opencode-projects": OPENCODE_PROJECTS_AGENT_CONFIG,
      }

      const pluginSkillPaths = [skillsPath]

      if (!opencodeConfig.agent) {
        opencodeConfig.agent = {}
      }
      Object.assign(opencodeConfig.agent as Record<string, unknown>, pluginAgents)

      if (!opencodeConfig.skills) {
        opencodeConfig.skills = { paths: [] }
      }
      const skillsConfig = opencodeConfig.skills as { paths?: string[] }
      if (!skillsConfig.paths) {
        skillsConfig.paths = []
      }
      for (const p of pluginSkillPaths) {
        if (!skillsConfig.paths.includes(p)) {
          skillsConfig.paths.push(p)
        }
      }

      const globalProjectsDir = config.getGlobalProjectsDir()
      const globalProjectsPattern = `${globalProjectsDir}/*`
      if (!opencodeConfig.permission || typeof opencodeConfig.permission === "object") {
        if (!opencodeConfig.permission) {
          opencodeConfig.permission = {}
        }
        const permissionConfig = opencodeConfig.permission as Record<string, unknown>
        if (!permissionConfig.external_directory || typeof permissionConfig.external_directory === "object") {
          if (!permissionConfig.external_directory) {
            permissionConfig.external_directory = {}
          }
          const externalDir = permissionConfig.external_directory as Record<string, unknown>
          if (!externalDir[globalProjectsPattern]) {
            externalDir[globalProjectsPattern] = "allow"
          }
        }
      }

      await log.info(`Registered ${Object.keys(pluginAgents).length} agent(s) and ${pluginSkillPaths.length} skill path(s)`)
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
