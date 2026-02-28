/**
 * Focus context builder
 *
 * Builds context blocks for the currently focused project.
 * This context is injected into the system prompt to provide
 * awareness of the current working context.
 */

import { xmlWrap, lines } from "../../utils/prompts/index.js"
import type { ProjectManager } from "../project-manager.js"

/**
 * Build context block for focused project.
 *
 * Returns an XML-wrapped context block that includes:
 * - Focused project ID and progress
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

  return xmlWrap("project-context", lines(...sections))
}
