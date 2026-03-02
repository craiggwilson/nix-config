/**
 * Focus context builder
 *
 * Builds context blocks for the currently focused project.
 * This context is injected into the system prompt to provide
 * awareness of the current working context including:
 * - Project progress
 * - Recent sessions
 * - Open questions and pending decisions
 * - Available artifacts
 */

import { xmlWrap, lines } from "../../utils/prompts/index.js"
import type { ProjectManager } from "../project-manager.js"
import {
  buildSessionContext,
  formatSessionContext,
  hasSessionContext,
} from "../../sessions/index.js"
import {
  buildArtifactContext,
  formatArtifactSummary,
  hasArtifactContext,
} from "../../artifacts/index.js"
import {
  buildDecisionContext,
  formatDecisionContext,
  hasDecisionContext,
} from "../../decisions/index.js"

/**
 * Build context block for focused project.
 *
 * Returns an XML-wrapped context block that includes:
 * - Focused project ID and progress
 * - Recent session summaries
 * - Open questions and pending decisions
 * - Available artifacts summary
 */
export async function buildFocusContext(projectManager: ProjectManager): Promise<string> {
  const sections: string[] = []

  const projectId = projectManager.getFocusedProjectId()

  if (!projectId) {
    sections.push("## Focused Project: None")
    return xmlWrap("project-context", sections)
  }

  sections.push(`## Focused Project: ${projectId}`)

  try {
    // Project progress
    const status = await projectManager.getProjectStatus(projectId)
    if (status?.issueStatus) {
      sections.push("")
      sections.push(
        `**Progress:** ${status.issueStatus.completed}/${status.issueStatus.total} issues complete`
      )
      if (status.issueStatus.inProgress > 0) {
        sections.push(`**In Progress:** ${status.issueStatus.inProgress}`)
      }
      if (status.issueStatus.blockers.length > 0) {
        sections.push(`**Blocked:** ${status.issueStatus.blockers.length}`)
      }
    }

    // Session context (recent sessions, open questions, what's next)
    const sessionManager = await projectManager.getSessionManager(projectId)
    if (sessionManager) {
      const sessionContext = await buildSessionContext(sessionManager, { recentLimit: 3 })
      if (hasSessionContext(sessionContext)) {
        sections.push("")
        sections.push(formatSessionContext(sessionContext))
      }
    }

    // Decision context (pending decisions, recent decisions)
    const decisionManager = await projectManager.getDecisionManager(projectId)
    if (decisionManager) {
      const decisionContext = await buildDecisionContext(decisionManager, { recentLimit: 3 })
      if (hasDecisionContext(decisionContext)) {
        sections.push("")
        sections.push(formatDecisionContext(decisionContext))
      }
    }

    // Artifact summary (compact list of available artifacts)
    const artifactRegistry = await projectManager.getArtifactRegistry(projectId)
    if (artifactRegistry) {
      const artifactContext = buildArtifactContext(artifactRegistry)
      if (hasArtifactContext(artifactContext)) {
        sections.push("")
        sections.push("## Available Artifacts")
        sections.push(formatArtifactSummary(artifactContext))
      }
    }
  } catch {
    // Project may not exist or have issues loading
  }

  return xmlWrap("project-context", lines(...sections))
}
