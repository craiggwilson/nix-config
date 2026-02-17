/**
 * project_plan tool - Continue or refine project planning
 */

import { tool } from "@opencode-ai/plugin"
import * as fs from "node:fs/promises"
import * as path from "node:path"

import type { ToolDeps, ProjectToolContext } from "../lib/types.js"

interface ProjectPlanArgs {
  projectId?: string
  phase?: "discovery" | "refinement" | "breakdown"
  focus?: string
}

/**
 * Create the project_plan tool
 */
export function createProjectPlan(deps: ToolDeps) {
  const { config, beads, focus, repoRoot, log } = deps

  return tool({
    description: `Continue or refine project planning.

Phases:
- discovery: Initial exploration and requirements gathering
- refinement: Refine scope, risks, and architecture
- breakdown: Break down into actionable issues

This tool loads existing planning artifacts and continues the conversation.`,

    args: {
      projectId: tool.schema
        .string()
        .optional()
        .describe("Project ID (default: focused project)"),
      phase: tool.schema
        .enum(["discovery", "refinement", "breakdown"])
        .optional()
        .describe("Planning phase to focus on"),
      focus: tool.schema
        .string()
        .optional()
        .describe("Specific area to focus on (e.g., 'security', 'performance')"),
    },

    async execute(args: ProjectPlanArgs, _ctx: ProjectToolContext): Promise<string> {
      const { phase, focus: focusArea } = args

      // Resolve project ID
      const projectId = args.projectId || focus.getProjectId()

      if (!projectId) {
        return "No project specified and no project is currently focused.\n\nUse `project_create` to start a new project, or `project_focus(projectId)` to set context."
      }

      await log.info(`Continuing planning for project: ${projectId}, phase: ${phase || "auto"}`)

      // Find project directory
      const projectDir = await findProjectDir(projectId, config, repoRoot)

      if (!projectDir) {
        return `Project '${projectId}' not found.\n\nUse \`project_list\` to see available projects.`
      }

      // Load existing planning artifacts
      const artifacts = await loadPlanningArtifacts(projectDir)

      // Load interview history
      const interviews = await loadInterviews(projectDir)

      // Determine current phase based on artifacts
      const currentPhase = determinePhase(artifacts, interviews)
      const targetPhase = phase || currentPhase

      // Build context for planning continuation
      const lines: string[] = []

      lines.push(`## Planning: ${projectId}`)
      lines.push("")
      lines.push(`**Current Phase:** ${currentPhase}`)
      lines.push(`**Target Phase:** ${targetPhase}`)

      if (focusArea) {
        lines.push(`**Focus Area:** ${focusArea}`)
      }

      lines.push("")

      // Show existing artifacts
      if (Object.keys(artifacts).length > 0) {
        lines.push("### Existing Artifacts")
        lines.push("")
        for (const [name, exists] of Object.entries(artifacts)) {
          lines.push(`- ${exists ? "✅" : "⬜"} ${name}`)
        }
        lines.push("")
      }

      // Show interview summary
      if (interviews.length > 0) {
        lines.push("### Interview History")
        lines.push("")
        lines.push(`${interviews.length} interview session(s) recorded.`)
        lines.push("")
      }

      // Phase-specific guidance
      lines.push("---")
      lines.push("")

      switch (targetPhase) {
        case "discovery":
          lines.push("### Discovery Phase")
          lines.push("")
          lines.push("Let's continue exploring the project scope and requirements.")
          lines.push("")
          if (!artifacts.roadmap) {
            lines.push("**Questions to explore:**")
            lines.push("1. What are the key milestones and deliverables?")
            lines.push("2. Who are the stakeholders and what are their priorities?")
            lines.push("3. What are the known constraints and dependencies?")
          } else {
            lines.push("We have a roadmap. Let's validate and refine it.")
            lines.push("")
            lines.push("**Questions:**")
            lines.push("1. Are there any changes to the timeline or priorities?")
            lines.push("2. Have new risks or dependencies emerged?")
          }
          break

        case "refinement":
          lines.push("### Refinement Phase")
          lines.push("")
          lines.push("Let's refine the technical approach and identify risks.")
          lines.push("")
          lines.push("**Areas to address:**")
          if (!artifacts.architecture) {
            lines.push("1. What is the high-level architecture?")
          }
          if (!artifacts.risks) {
            lines.push("2. What are the key risks and mitigations?")
          }
          if (!artifacts["success-criteria"]) {
            lines.push("3. How will we measure success?")
          }
          break

        case "breakdown":
          lines.push("### Breakdown Phase")
          lines.push("")
          lines.push("Let's break down the work into actionable issues.")
          lines.push("")
          lines.push("I'll help you create beads issues with:")
          lines.push("- Clear titles and descriptions")
          lines.push("- Priority assignments (P0-P3)")
          lines.push("- Dependency relationships")
          lines.push("- Hierarchical structure (epics → tasks → subtasks)")
          lines.push("")
          lines.push("**What area should we break down first?**")
          break
      }

      return lines.join("\n")
    },
  })
}

/**
 * Find project directory by ID
 */
async function findProjectDir(
  projectId: string,
  config: ToolDeps["config"],
  repoRoot: string
): Promise<string | null> {
  // Check local first
  const localDir = path.join(config.getLocalProjectsDir(repoRoot), projectId)
  try {
    await fs.access(localDir)
    return localDir
  } catch {
    // Not in local
  }

  // Check global
  const globalDir = path.join(config.getGlobalProjectsDir(), projectId)
  try {
    await fs.access(globalDir)
    return globalDir
  } catch {
    // Not in global
  }

  return null
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
 * Load interview history
 */
async function loadInterviews(projectDir: string): Promise<string[]> {
  const interviewsDir = path.join(projectDir, "interviews")
  const interviews: string[] = []

  try {
    const files = await fs.readdir(interviewsDir)
    for (const file of files) {
      if (file.endsWith(".md")) {
        interviews.push(file)
      }
    }
  } catch {
    // Interviews directory doesn't exist
  }

  return interviews.sort()
}

/**
 * Determine current planning phase
 */
function determinePhase(
  artifacts: Record<string, boolean>,
  interviews: string[]
): "discovery" | "refinement" | "breakdown" {
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
