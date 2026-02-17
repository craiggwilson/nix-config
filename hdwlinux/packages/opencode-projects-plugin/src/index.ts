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
import { BeadsClient } from "./lib/beads.js"
import { FocusManager } from "./lib/focus.js"
import { createLogger } from "./lib/logger.js"

import { PROJECT_RULES } from "./agents/rules.js"

import type { OpencodeClient } from "./lib/types.js"

/**
 * Main plugin export
 */
export const ProjectsPlugin: Plugin = async (ctx) => {
  const { client, directory, worktree } = ctx
  const typedClient = client as OpencodeClient

  const log = createLogger(typedClient)
  await log.info("opencode-projects plugin initializing")

  // Initialize managers
  const config = await ConfigManager.load()
  const beads = new BeadsClient(log)
  const focus = new FocusManager()

  // Detect if we're in a repository
  const repoRoot = worktree || directory

  // Check beads availability
  const beadsAvailable = await beads.isAvailable()
  if (!beadsAvailable) {
    await log.warn("beads (bd) not found in PATH - some features will be unavailable")
  }

  await log.info(`opencode-projects initialized in ${repoRoot}`)

  return {
    // Project management tools
    tool: {
      project_create: createProjectCreate({ client: typedClient, config, beads, focus, repoRoot, log }),
      project_list: createProjectList({ client: typedClient, config, beads, focus, repoRoot, log }),
      project_status: createProjectStatus({ client: typedClient, config, beads, focus, repoRoot, log }),
      project_focus: createProjectFocus({ client: typedClient, config, beads, focus, repoRoot, log }),
      project_plan: createProjectPlan({ client: typedClient, config, beads, focus, repoRoot, log }),
      project_close: createProjectClose({ client: typedClient, config, beads, focus, repoRoot, log }),
      issue_create: createIssueCreate({ client: typedClient, config, beads, focus, repoRoot, log }),
      issue_claim: createIssueClaim({ client: typedClient, config, beads, focus, repoRoot, log }),
    },

    // Inject project management rules into system prompt
    "experimental.chat.system.transform": async (_input, output) => {
      output.system.push(PROJECT_RULES)

      // Inject focused project context if any
      const focused = focus.getCurrent()
      if (focused) {
        const contextBlock = await buildFocusContext(focused, beads, repoRoot)
        if (contextBlock) {
          output.system.push(contextBlock)
        }
      }
    },

    // Preserve project context during compaction
    "experimental.session.compacting": async (input, output) => {
      const focused = focus.getCurrent()
      if (!focused) return

      const contextBlock = await buildCompactionContext(focused, beads, repoRoot)
      if (contextBlock) {
        output.context.push(contextBlock)
      }
    },

    // Inject environment variables for shell commands
    "shell.env": async (_input, output) => {
      const focused = focus.getCurrent()
      if (focused?.projectId) {
        output.env.OPENCODE_PROJECT_ID = focused.projectId
      }
      if (focused?.issueId) {
        output.env.OPENCODE_ISSUE_ID = focused.issueId
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
async function buildFocusContext(
  focused: { projectId: string; issueId?: string },
  beads: BeadsClient,
  repoRoot: string
): Promise<string | null> {
  const sections: string[] = ["<project-context>"]

  sections.push(`## Focused Project: ${focused.projectId}`)

  // Get project status from beads
  try {
    const status = await beads.getProjectStatus(focused.projectId, repoRoot)
    if (status) {
      sections.push("")
      sections.push(`**Progress:** ${status.completed}/${status.total} issues complete`)
      if (status.blockers.length > 0) {
        sections.push(`**Blockers:** ${status.blockers.length}`)
      }
    }
  } catch {
    // Beads may not be initialized
  }

  if (focused.issueId) {
    sections.push("")
    sections.push(`### Focused Issue: ${focused.issueId}`)

    try {
      const issue = await beads.getIssue(focused.issueId, repoRoot)
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
async function buildCompactionContext(
  focused: { projectId: string; issueId?: string },
  beads: BeadsClient,
  repoRoot: string
): Promise<string | null> {
  const sections: string[] = ["<project-compaction-context>"]

  sections.push(`## Active Project: ${focused.projectId}`)

  if (focused.issueId) {
    sections.push(`## Working On: ${focused.issueId}`)
  }

  // Get ready issues
  try {
    const ready = await beads.getReadyIssues(focused.projectId, repoRoot)
    if (ready.length > 0) {
      sections.push("")
      sections.push("## Ready Issues (no blockers)")
      for (const issue of ready.slice(0, 5)) {
        sections.push(`- ${issue.id}: ${issue.title}`)
      }
    }
  } catch {
    // Beads may not be available
  }

  sections.push("")
  sections.push("Use `project_status` to get full project state.")
  sections.push("Use `project_focus` to change focus.")
  sections.push("</project-compaction-context>")

  return sections.join("\n")
}

export default ProjectsPlugin
