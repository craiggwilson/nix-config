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

import { createProjectCreate } from "./tools/project-create.js"
import { createProjectList } from "./tools/project-list.js"
import { createProjectStatus } from "./tools/project-status.js"
import { createProjectFocus } from "./tools/project-focus.js"
import { createProjectPlan } from "./tools/project-plan.js"
import { createProjectClose } from "./tools/project-close.js"
import { createIssueCreate } from "./tools/issue-create.js"
import { createIssueClaim } from "./tools/issue-claim.js"

import { ConfigManager } from "./lib/config.js"
import { BeadsIssueStorage } from "./lib/beads-issue-storage.js"
import { FocusManager } from "./lib/focus.js"
import { ProjectManager } from "./lib/project-manager.js"
import { createLogger } from "./lib/logger.js"

import { PROJECT_RULES } from "./agents/rules.js"

import type { OpencodeClient } from "./lib/types.js"

// Re-export SDK classes for external consumers
export { ProjectManager } from "./lib/project-manager.js"
export { ConfigManager } from "./lib/config.js"
export { FocusManager } from "./lib/focus.js"
export { BeadsIssueStorage } from "./lib/beads-issue-storage.js"
export { InMemoryIssueStorage } from "./lib/inmemory-issue-storage.js"
export { InterviewManager } from "./lib/interview-manager.js"
export { ArtifactManager } from "./lib/artifact-manager.js"
export { PlanningDelegator } from "./lib/planning-delegator.js"
export type { IssueStorage, Issue, ProjectStatus } from "./lib/issue-storage.js"
export type { ProjectMetadata, CreateProjectOptions } from "./lib/project-manager.js"
export type { InterviewSession, InterviewSummary, InterviewExchange } from "./lib/interview-manager.js"
export type {
  ArtifactType,
  ArtifactMetadata,
  RoadmapContent,
  ArchitectureContent,
  RisksContent,
  SuccessCriteriaContent,
  Milestone,
  Risk,
  SuccessCriterion,
} from "./lib/artifact-manager.js"
export type {
  PlanningPhase,
  AgentInfo,
  DelegationRequest,
  DelegationResult,
} from "./lib/planning-delegator.js"

/**
 * Main plugin export
 */
export const ProjectsPlugin: Plugin = async (ctx) => {
  const { client, directory, worktree, $ } = ctx
  const typedClient = client as OpencodeClient

  const log = createLogger(typedClient)
  await log.info("opencode-projects plugin initializing")

  // Initialize managers
  const config = await ConfigManager.load()
  const issueStorage = new BeadsIssueStorage(log)
  const focus = new FocusManager()

  // Set the shell for beads client
  issueStorage.setShell($)

  // Detect if we're in a repository
  const repoRoot = worktree || directory

  // Create ProjectManager with client for delegation
  const projectManager = new ProjectManager({
    config,
    issueStorage,
    focus,
    log,
    repoRoot,
    client: typedClient,
  })

  // Check beads availability
  const beadsAvailable = await issueStorage.isAvailable()
  if (!beadsAvailable) {
    await log.warn("beads (bd) not found in PATH - some features will be unavailable")
  }

  await log.info(`opencode-projects initialized in ${repoRoot}`)

  // Create tool dependencies (v2 style)
  const toolDeps = { client: typedClient, projectManager, log, $ }

  return {
    // Project management tools
    tool: {
      project_create: createProjectCreate(toolDeps),
      project_list: createProjectList(toolDeps),
      project_status: createProjectStatus(toolDeps),
      project_focus: createProjectFocus(toolDeps),
      project_plan: createProjectPlan(toolDeps),
      project_close: createProjectClose(toolDeps),
      issue_create: createIssueCreate(toolDeps),
      issue_claim: createIssueClaim(toolDeps),
    },

    // Inject project management rules into system prompt
    "experimental.chat.system.transform": async (_input, output) => {
      output.system.push(PROJECT_RULES)

      // Inject focused project context if any
      const projectId = projectManager.getFocusedProjectId()
      if (projectId) {
        const contextBlock = await buildFocusContext(projectManager)
        if (contextBlock) {
          output.system.push(contextBlock)
        }
      }
    },

    // Preserve project context during compaction
    "experimental.session.compacting": async (_input, output) => {
      const projectId = projectManager.getFocusedProjectId()
      if (!projectId) return

      const contextBlock = await buildCompactionContext(projectManager)
      if (contextBlock) {
        output.context.push(contextBlock)
      }
    },

    // Inject environment variables for shell commands
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

    // Handle events
    event: async ({ event }: { event: Event }) => {
      // Handle session idle for delegation completion
      if (event.type === "session.idle") {
        // TODO: Check for completed project delegations
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

  // Get project status
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
 * Build context for session compaction
 */
async function buildCompactionContext(projectManager: ProjectManager): Promise<string | null> {
  const projectId = projectManager.getFocusedProjectId()
  if (!projectId) return null

  const sections: string[] = ["<project-compaction-context>"]

  sections.push(`## Active Project: ${projectId}`)

  const issueId = projectManager.getFocusedIssueId()
  if (issueId) {
    sections.push(`## Working On: ${issueId}`)
  }

  // Get ready issues
  try {
    const ready = await projectManager.getReadyIssues(projectId)
    if (ready.length > 0) {
      sections.push("")
      sections.push("## Ready Issues (no blockers)")
      for (const issue of ready.slice(0, 5)) {
        sections.push(`- ${issue.id}: ${issue.title}`)
      }
    }
  } catch {
    // Project may not exist
  }

  sections.push("")
  sections.push("Use `project_status` to get full project state.")
  sections.push("Use `project_focus` to change focus.")
  sections.push("</project-compaction-context>")

  return sections.join("\n")
}

export default ProjectsPlugin
