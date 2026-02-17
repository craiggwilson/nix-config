/**
 * project_plan tool - Continue or refine project planning
 */

import { tool } from "@opencode-ai/plugin"
import * as fs from "node:fs/promises"
import * as path from "node:path"

import type { ToolDepsV2, ProjectToolContext } from "../lib/types.js"

interface ProjectPlanArgs {
  projectId?: string
  phase?: "discovery" | "refinement" | "breakdown"
  topic?: string
  action?: "start" | "continue" | "complete" | "list"
}

/**
 * Create the project_plan tool
 */
export function createProjectPlan(deps: ToolDepsV2) {
  const { projectManager, log } = deps

  return tool({
    description: `Continue or refine project planning through conversational interviews.

Actions:
- start: Begin a new planning interview
- continue: Resume the current interview (default)
- complete: Mark the current interview as complete
- list: Show all interview sessions

Phases:
- discovery: Initial exploration and requirements gathering
- refinement: Refine scope, risks, and architecture
- breakdown: Break down into actionable issues

This tool manages interview sessions and loads existing planning artifacts.`,

    args: {
      projectId: tool.schema
        .string()
        .optional()
        .describe("Project ID (default: focused project)"),
      phase: tool.schema
        .enum(["discovery", "refinement", "breakdown"])
        .optional()
        .describe("Planning phase to focus on"),
      topic: tool.schema
        .string()
        .optional()
        .describe("Specific topic to focus on (e.g., 'security', 'performance')"),
      action: tool.schema
        .enum(["start", "continue", "complete", "list"])
        .optional()
        .describe("Action to perform (default: continue)"),
    },

    async execute(args: ProjectPlanArgs, _ctx: ProjectToolContext): Promise<string> {
      const { phase, topic, action = "continue" } = args

      // Resolve project ID
      const projectId = args.projectId || projectManager.getFocusedProjectId()

      if (!projectId) {
        return "No project specified and no project is currently focused.\n\nUse `project_create` to start a new project, or `project_focus(projectId)` to set context."
      }

      await log.info(`Planning for project: ${projectId}, action: ${action}`)

      // Get project directory
      const projectDir = await projectManager.getProjectDir(projectId)

      if (!projectDir) {
        return `Project '${projectId}' not found.\n\nUse \`project_list\` to see available projects.`
      }

      // Handle different actions
      switch (action) {
        case "list":
          return await handleListInterviews(projectManager, projectId)

        case "complete":
          return await handleCompleteInterview(projectManager, projectId)

        case "start":
          return await handleStartInterview(projectManager, projectId, phase, topic, projectDir)

        case "continue":
        default:
          return await handleContinueInterview(projectManager, projectId, phase, topic, projectDir)
      }
    },
  })
}

/**
 * List all interview sessions
 */
async function handleListInterviews(
  projectManager: ToolDepsV2["projectManager"],
  projectId: string
): Promise<string> {
  const interviews = await projectManager.listInterviews(projectId)

  if (interviews.length === 0) {
    return `No interview sessions found for project '${projectId}'.\n\nUse \`project_plan(action='start')\` to begin a planning interview.`
  }

  const lines: string[] = ["## Interview Sessions", ""]

  for (const interview of interviews) {
    const statusIcon =
      interview.status === "active"
        ? "🟢"
        : interview.status === "completed"
          ? "✅"
          : "⚪"

    lines.push(
      `- ${statusIcon} **${interview.id}** - ${interview.phase}${interview.topic ? ` (${interview.topic})` : ""}`
    )
    lines.push(`  ${interview.exchangeCount} exchanges, last updated ${interview.lastUpdatedAt}`)
  }

  lines.push("")
  lines.push("---")
  lines.push("")
  lines.push("Use `project_plan(action='continue')` to resume the most recent active session.")

  return lines.join("\n")
}

/**
 * Complete the current interview
 */
async function handleCompleteInterview(
  projectManager: ToolDepsV2["projectManager"],
  projectId: string
): Promise<string> {
  const completed = await projectManager.completeInterview(projectId)

  if (!completed) {
    return "No active interview session to complete."
  }

  return "## Interview Completed\n\nThe current interview session has been marked as complete.\n\nUse `project_plan(action='start')` to begin a new session."
}

/**
 * Start a new interview session
 */
async function handleStartInterview(
  projectManager: ToolDepsV2["projectManager"],
  projectId: string,
  phase: "discovery" | "refinement" | "breakdown" | undefined,
  topic: string | undefined,
  projectDir: string
): Promise<string> {
  // Determine phase from artifacts if not specified
  const effectivePhase = phase || (await determinePhase(projectDir))

  const session = await projectManager.startInterview(projectId, effectivePhase, topic)

  if (!session) {
    return "Failed to start interview session."
  }

  const lines: string[] = []

  lines.push(`## Interview Started: ${effectivePhase}`)
  lines.push("")
  lines.push(`**Session ID:** ${session.id}`)

  if (topic) {
    lines.push(`**Topic:** ${topic}`)
  }

  lines.push("")
  lines.push("---")
  lines.push("")

  // Add phase-specific opening questions
  lines.push(getPhaseQuestions(effectivePhase, topic))

  return lines.join("\n")
}

/**
 * Continue an existing interview or start a new one
 */
async function handleContinueInterview(
  projectManager: ToolDepsV2["projectManager"],
  projectId: string,
  phase: "discovery" | "refinement" | "breakdown" | undefined,
  topic: string | undefined,
  projectDir: string
): Promise<string> {
  // Check for active interview
  const activeInterview = await projectManager.getActiveInterview(projectId)

  if (activeInterview) {
    // Resume existing interview
    const context = await projectManager.getInterviewContext(projectId)

    const lines: string[] = []

    lines.push(`## Continuing Interview: ${activeInterview.phase}`)
    lines.push("")
    lines.push(`**Session ID:** ${activeInterview.id}`)
    lines.push(`**Exchanges:** ${activeInterview.exchanges.length}`)

    if (activeInterview.topic) {
      lines.push(`**Topic:** ${activeInterview.topic}`)
    }

    lines.push("")

    if (context) {
      lines.push(context)
      lines.push("")
    }

    lines.push("---")
    lines.push("")
    lines.push("Continue the conversation, or use `project_plan(action='complete')` to finish.")

    return lines.join("\n")
  }

  // No active interview - show planning status and offer to start
  const artifacts = await loadPlanningArtifacts(projectDir)
  const interviews = await projectManager.listInterviews(projectId)
  const currentPhase = await determinePhase(projectDir)
  const targetPhase = phase || currentPhase

  const lines: string[] = []

  lines.push(`## Planning: ${projectId}`)
  lines.push("")
  lines.push(`**Current Phase:** ${currentPhase}`)

  if (topic) {
    lines.push(`**Focus Area:** ${topic}`)
  }

  lines.push("")

  // Show existing artifacts
  if (Object.keys(artifacts).length > 0) {
    lines.push("### Planning Artifacts")
    lines.push("")
    for (const [name, exists] of Object.entries(artifacts)) {
      lines.push(`- ${exists ? "✅" : "⬜"} ${name}`)
    }
    lines.push("")
  }

  // Show interview summary
  if (interviews.length > 0) {
    const completed = interviews.filter((i) => i.status === "completed").length
    lines.push(`### Interview History: ${completed} completed sessions`)
    lines.push("")
  }

  lines.push("---")
  lines.push("")
  lines.push("No active interview session.")
  lines.push("")
  lines.push(`Use \`project_plan(action='start', phase='${targetPhase}')\` to begin a new interview.`)
  lines.push("")
  lines.push(getPhaseQuestions(targetPhase, topic))

  return lines.join("\n")
}

/**
 * Get phase-specific opening questions
 */
function getPhaseQuestions(
  phase: "discovery" | "refinement" | "breakdown",
  topic?: string
): string {
  const lines: string[] = []

  switch (phase) {
    case "discovery":
      lines.push("### Discovery Phase")
      lines.push("")
      lines.push("Let's explore the project scope and requirements.")
      lines.push("")
      lines.push("**Questions to discuss:**")
      if (topic) {
        lines.push(`1. What are the key requirements for ${topic}?`)
        lines.push(`2. What constraints or dependencies affect ${topic}?`)
        lines.push(`3. How does ${topic} fit into the overall project goals?`)
      } else {
        lines.push("1. What problem are you trying to solve?")
        lines.push("2. Who are the primary stakeholders?")
        lines.push("3. What does success look like for this project?")
        lines.push("4. What are the known constraints (timeline, resources, technology)?")
      }
      break

    case "refinement":
      lines.push("### Refinement Phase")
      lines.push("")
      lines.push("Let's refine the technical approach and identify risks.")
      lines.push("")
      lines.push("**Areas to address:**")
      if (topic) {
        lines.push(`1. What is the technical approach for ${topic}?`)
        lines.push(`2. What are the risks specific to ${topic}?`)
        lines.push(`3. How will we validate ${topic} works correctly?`)
      } else {
        lines.push("1. What is the high-level architecture?")
        lines.push("2. What are the key technical decisions?")
        lines.push("3. What are the main risks and how will we mitigate them?")
        lines.push("4. How will we measure success?")
      }
      break

    case "breakdown":
      lines.push("### Breakdown Phase")
      lines.push("")
      lines.push("Let's break down the work into actionable issues.")
      lines.push("")
      lines.push("I'll help you create issues with:")
      lines.push("- Clear titles and descriptions")
      lines.push("- Priority assignments (P0-P3)")
      lines.push("- Dependency relationships")
      lines.push("- Hierarchical structure (epics → tasks → subtasks)")
      lines.push("")
      if (topic) {
        lines.push(`**What specific work items are needed for ${topic}?**`)
      } else {
        lines.push("**What area should we break down first?**")
      }
      break
  }

  return lines.join("\n")
}

/**
 * Load planning artifacts
 */
async function loadPlanningArtifacts(
  projectDir: string
): Promise<Record<string, boolean>> {
  const plansDir = path.join(projectDir, "plans")
  const artifacts: Record<string, boolean> = {
    roadmap: false,
    architecture: false,
    risks: false,
    "success-criteria": false,
    resources: false,
  }

  try {
    const files = await fs.readdir(plansDir)
    for (const file of files) {
      const name = file.replace(".md", "")
      if (name in artifacts) {
        artifacts[name] = true
      }
    }
  } catch {
    // Plans directory doesn't exist
  }

  return artifacts
}

/**
 * Determine current planning phase based on artifacts
 */
async function determinePhase(
  projectDir: string
): Promise<"discovery" | "refinement" | "breakdown"> {
  const artifacts = await loadPlanningArtifacts(projectDir)

  // If we have architecture and risks, we're in breakdown
  if (artifacts.architecture && artifacts.risks) {
    return "breakdown"
  }

  // If we have a roadmap, we're in refinement
  if (artifacts.roadmap) {
    return "refinement"
  }

  // Otherwise, we're in discovery
  return "discovery"
}
