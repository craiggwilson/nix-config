/**
 * PlanningManager - Manages project planning state and workflow
 *
 * Handles:
 * - Planning state persistence
 * - Phase transitions
 * - Understanding accumulation
 * - Context generation for prompts
 */

import * as fs from "node:fs/promises"
import * as path from "node:path"

import type {
  PlanningState,
  PlanningPhase,
  PlanningUnderstanding,
  Logger,
} from "../core/types.js"

/**
 * Phase order for transitions
 */
const PHASE_ORDER: PlanningPhase[] = ["discovery", "synthesis", "breakdown", "complete"]

/**
 * Result of a planning action
 */
export interface PlanningActionResult {
  success: boolean
  message: string
  state?: PlanningState
}

/**
 * PlanningManager - encapsulates all planning operations
 */
export class PlanningManager {
  private projectDir: string
  private log: Logger

  constructor(projectDir: string, log: Logger) {
    this.projectDir = projectDir
    this.log = log
  }

  /**
   * Get the path to the planning state file
   */
  private getStatePath(): string {
    return path.join(this.projectDir, "planning.json")
  }

  /**
   * Create initial planning state
   */
  private createInitialState(): PlanningState {
    const now = new Date().toISOString()
    return {
      phase: "discovery",
      startedAt: now,
      lastUpdatedAt: now,
      understanding: {},
      openQuestions: [],
      completedPhases: [],
    }
  }

  /**
   * Get the current planning state
   */
  async getState(): Promise<PlanningState | null> {
    const statePath = this.getStatePath()

    try {
      const content = await fs.readFile(statePath, "utf-8")
      return JSON.parse(content) as PlanningState
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code === "ENOENT") {
        return null
      }
      throw error
    }
  }

  /**
   * Save the planning state
   */
  async saveState(state: PlanningState): Promise<void> {
    state.lastUpdatedAt = new Date().toISOString()
    const statePath = this.getStatePath()
    await fs.writeFile(statePath, JSON.stringify(state, null, 2))
  }

  /**
   * Start or continue a planning session
   */
  async startOrContinue(): Promise<PlanningState> {
    let state = await this.getState()

    if (!state) {
      state = this.createInitialState()
      await this.saveState(state)
      await this.log.info(`Started new planning session`)
    } else {
      await this.log.info(`Continuing planning session (phase: ${state.phase})`)
    }

    return state
  }

  /**
   * Check if planning is active
   */
  async isActive(): Promise<boolean> {
    const state = await this.getState()
    return state !== null && state.phase !== "complete"
  }

  /**
   * Advance to the next planning phase
   */
  async advancePhase(): Promise<PlanningState> {
    const state = await this.getState()
    if (!state) {
      throw new Error("No planning session found")
    }

    const currentIndex = PHASE_ORDER.indexOf(state.phase)

    if (currentIndex === -1 || currentIndex >= PHASE_ORDER.length - 1) {
      throw new Error(`Cannot advance from phase: ${state.phase}`)
    }

    // Mark current phase as completed
    if (!state.completedPhases.includes(state.phase)) {
      state.completedPhases.push(state.phase)
    }

    // Move to next phase
    state.phase = PHASE_ORDER[currentIndex + 1]
    await this.saveState(state)

    await this.log.info(`Advanced planning to phase: ${state.phase}`)
    return state
  }

  /**
   * Set a specific planning phase
   */
  async setPhase(phase: PlanningPhase): Promise<PlanningState> {
    const state = await this.getState()
    if (!state) {
      throw new Error("No planning session found")
    }

    state.phase = phase
    await this.saveState(state)

    await this.log.info(`Set planning phase to: ${phase}`)
    return state
  }

  /**
   * Update the planning understanding
   */
  async updateUnderstanding(updates: Partial<PlanningUnderstanding>): Promise<PlanningState> {
    const state = await this.getState()
    if (!state) {
      throw new Error("No planning session found")
    }

    // Merge updates into existing understanding
    state.understanding = {
      ...state.understanding,
      ...updates,
    }

    // Deduplicate arrays
    if (updates.goals) {
      state.understanding.goals = [...new Set(state.understanding.goals)]
    }
    if (updates.stakeholders) {
      state.understanding.stakeholders = [...new Set(state.understanding.stakeholders)]
    }
    if (updates.constraints) {
      state.understanding.constraints = [...new Set(state.understanding.constraints)]
    }
    if (updates.risks) {
      state.understanding.risks = [...new Set(state.understanding.risks)]
    }
    if (updates.decisions && state.understanding.decisions) {
      // Append new decisions, avoiding duplicates
      const existingDecisions = state.understanding.decisions.map((d) => d.decision)
      const newDecisions = updates.decisions.filter((d) => !existingDecisions.includes(d.decision))
      state.understanding.decisions = [...state.understanding.decisions, ...newDecisions]
    }

    await this.saveState(state)
    return state
  }

  /**
   * Update open questions
   */
  async updateOpenQuestions(questions: string[]): Promise<PlanningState> {
    const state = await this.getState()
    if (!state) {
      throw new Error("No planning session found")
    }

    state.openQuestions = questions
    await this.saveState(state)
    return state
  }

  // ============================================================================
  // Formatting Methods
  // ============================================================================

  /**
   * Format understanding for display
   */
  formatUnderstanding(understanding: PlanningUnderstanding): string {
    const lines: string[] = []

    if (understanding.problem) {
      lines.push(`**Problem:** ${understanding.problem}`)
    }
    if (understanding.goals?.length) {
      lines.push(`**Goals:** ${understanding.goals.join(", ")}`)
    }
    if (understanding.stakeholders?.length) {
      lines.push(`**Stakeholders:** ${understanding.stakeholders.join(", ")}`)
    }
    if (understanding.timeline) {
      lines.push(`**Timeline:** ${understanding.timeline}`)
    }
    if (understanding.constraints?.length) {
      lines.push(`**Constraints:** ${understanding.constraints.join(", ")}`)
    }
    if (understanding.technicalContext) {
      lines.push(`**Technical Context:** ${understanding.technicalContext}`)
    }
    if (understanding.risks?.length) {
      lines.push(`**Risks:** ${understanding.risks.join(", ")}`)
    }
    if (understanding.decisions?.length) {
      lines.push("**Decisions:**")
      for (const d of understanding.decisions) {
        lines.push(`  - ${d.decision} (${d.rationale})`)
      }
    }

    return lines.join("\n")
  }

  /**
   * Format planning status for display
   */
  formatStatus(state: PlanningState): string {
    const lines: string[] = []

    lines.push(`**Phase:** ${state.phase}`)
    lines.push(`**Started:** ${state.startedAt}`)
    lines.push(`**Last Updated:** ${state.lastUpdatedAt}`)

    if (state.completedPhases.length > 0) {
      lines.push(`**Completed Phases:** ${state.completedPhases.join(", ")}`)
    }

    lines.push("")

    if (Object.keys(state.understanding).length > 0) {
      lines.push("### Understanding")
      lines.push(this.formatUnderstanding(state.understanding))
      lines.push("")
    }

    if (state.openQuestions.length > 0) {
      lines.push(`### Open Questions: ${state.openQuestions.length}`)
      for (const q of state.openQuestions) {
        lines.push(`- ${q}`)
      }
      lines.push("")
    }

    return lines.join("\n")
  }

  /**
   * Get phase-specific guidance
   */
  getPhaseGuidance(phase: PlanningPhase): string {
    const lines: string[] = []

    switch (phase) {
      case "discovery":
        lines.push("### Discovery Phase")
        lines.push("")
        lines.push("**Your goal:** Deeply understand the project before making any decisions.")
        lines.push("")
        lines.push("**Questions to explore:**")
        lines.push("- What problem are we solving? Why now? Why is this important?")
        lines.push("- Who are the stakeholders? What do they need? What are their priorities?")
        lines.push("- What's the timeline? What are the hard deadlines?")
        lines.push("- What constraints exist? (technical, organizational, budget, etc.)")
        lines.push("- What has been tried before? What worked/didn't work?")
        lines.push("")
        lines.push("**When you need research:**")
        lines.push("1. Create an issue: `project-create-issue(title=\"Research: <topic>\")`")
        lines.push("2. Start work: `project-work-on-issue(issueId)`")
        lines.push("3. Continue planning - you'll be notified when complete")
        lines.push("4. When notified, use `project-plan(action='save')` to incorporate findings")
        lines.push("")
        lines.push("**When ready:** Use `project-plan(action='advance')` to move to synthesis.")
        break

      case "synthesis":
        lines.push("### Synthesis Phase")
        lines.push("")
        lines.push("**Your goal:** Consolidate findings, make decisions, identify risks.")
        lines.push("")
        lines.push("**Tasks:**")
        lines.push("- Review all research findings")
        lines.push("- Make key technical and architectural decisions")
        lines.push("- Identify and document risks with mitigations")
        lines.push("- Define success criteria")
        lines.push("- Create any necessary artifacts (architecture docs, etc.)")
        lines.push("")
        lines.push("**Artifacts:** Write directly to `.projects/<id>/plans/` as needed:")
        lines.push("- `plans/architecture.md` - Technical architecture")
        lines.push("- `plans/risks.md` - Risk register")
        lines.push("- `plans/roadmap.md` - High-level roadmap")
        lines.push("")
        lines.push("**When ready:** Use `project-plan(action='advance')` to move to breakdown.")
        break

      case "breakdown":
        lines.push("### Breakdown Phase")
        lines.push("")
        lines.push("**Your goal:** Create actionable issues in beads.")
        lines.push("")
        lines.push("**Tasks:**")
        lines.push("- Break work into epics, tasks, and subtasks")
        lines.push("- Set priorities (P0-P3)")
        lines.push("- Define dependencies between issues")
        lines.push("- Ensure each issue is actionable and well-defined")
        lines.push("")
        lines.push("**Creating issues:**")
        lines.push("- `project-create-issue(title, description, priority, parentId, blockedBy)`")
        lines.push("")
        lines.push("**When ready:** Use `project-plan(action='advance')` to complete planning.")
        break

      case "complete":
        lines.push("### Planning Complete")
        lines.push("")
        lines.push("Planning is finished. You can now:")
        lines.push("- Start working on issues with `project-work-on-issue`")
        lines.push("- View project status with `project-status`")
        lines.push("- Return to planning with `project-plan(action='phase', phase='discovery')`")
        break
    }

    return lines.join("\n")
  }

  // ============================================================================
  // Action Handlers (called by tool)
  // ============================================================================

  /**
   * Handle status action
   */
  async handleStatus(projectId: string): Promise<string> {
    const state = await this.getState()

    if (!state) {
      return `No planning session found for project '${projectId}'.\n\nUse \`project-plan(action='start')\` to begin planning.`
    }

    return `## Planning Status: ${projectId}\n\n${this.formatStatus(state)}`
  }

  /**
   * Handle start or continue action
   */
  async handleStartOrContinue(projectId: string): Promise<string> {
    const state = await this.startOrContinue()

    const lines: string[] = []

    lines.push(`## Planning Session: ${projectId}`)
    lines.push("")
    lines.push(`**Phase:** ${state.phase}`)
    lines.push(`**Started:** ${state.startedAt}`)
    lines.push(`**Last Updated:** ${state.lastUpdatedAt}`)
    lines.push("")

    // Show current understanding
    if (Object.keys(state.understanding).length > 0) {
      lines.push("### Current Understanding")
      lines.push("")
      lines.push(this.formatUnderstanding(state.understanding))
      lines.push("")
    }

    // Show open questions
    if (state.openQuestions.length > 0) {
      lines.push("### Open Questions")
      lines.push("")
      for (const q of state.openQuestions) {
        lines.push(`- ${q}`)
      }
      lines.push("")
    }

    lines.push("---")
    lines.push("")

    // Add phase-specific guidance
    lines.push(this.getPhaseGuidance(state.phase))

    return lines.join("\n")
  }

  /**
   * Handle save action
   */
  async handleSave(
    projectId: string,
    understandingJson?: string,
    openQuestionsStr?: string
  ): Promise<string> {
    const state = await this.getState()

    if (!state) {
      return `No planning session found for project '${projectId}'.`
    }

    // Update understanding if provided
    if (understandingJson) {
      try {
        const updates = JSON.parse(understandingJson)
        await this.updateUnderstanding(updates)
      } catch (e) {
        return `Error parsing understanding JSON: ${e}`
      }
    }

    // Update open questions if provided
    if (openQuestionsStr) {
      const questions = openQuestionsStr.split(",").map((q) => q.trim()).filter(Boolean)
      await this.updateOpenQuestions(questions)
    }

    const updatedState = await this.getState()

    return `## Planning Progress Saved\n\n${this.formatStatus(updatedState!)}`
  }

  /**
   * Handle advance action
   */
  async handleAdvance(): Promise<string> {
    try {
      const state = await this.advancePhase()

      const lines: string[] = []
      lines.push(`## Advanced to Phase: ${state.phase}`)
      lines.push("")

      if (state.phase === "complete") {
        lines.push("🎉 Planning is complete!")
        lines.push("")
        lines.push("You can now:")
        lines.push("- Review the issues created in beads")
        lines.push("- Start working on issues with `project-work-on-issue`")
        lines.push("- Close the project when done with `project-close`")
      } else {
        lines.push(this.getPhaseGuidance(state.phase))
      }

      return lines.join("\n")
    } catch (e) {
      return `Error advancing phase: ${e}`
    }
  }

  /**
   * Handle set phase action
   */
  async handleSetPhase(phase: PlanningPhase): Promise<string> {
    try {
      const state = await this.setPhase(phase)

      const lines: string[] = []
      lines.push(`## Phase Set: ${state.phase}`)
      lines.push("")
      lines.push(this.getPhaseGuidance(state.phase))

      return lines.join("\n")
    } catch (e) {
      return `Error setting phase: ${e}`
    }
  }

  // ============================================================================
  // Context Building (for system prompt injection)
  // ============================================================================

  /**
   * Build context for system prompt injection
   */
  async buildContext(): Promise<string | null> {
    const state = await this.getState()
    if (!state || state.phase === "complete") return null

    const lines: string[] = ["<planning-session>"]
    lines.push(`## Active Planning`)
    lines.push(`**Phase:** ${state.phase}`)
    lines.push(`**Last Updated:** ${state.lastUpdatedAt}`)
    lines.push("")

    // Current understanding
    if (Object.keys(state.understanding).length > 0) {
      lines.push("### What We Know")
      const u = state.understanding
      if (u.problem) lines.push(`- **Problem:** ${u.problem}`)
      if (u.goals?.length) lines.push(`- **Goals:** ${u.goals.join(", ")}`)
      if (u.stakeholders?.length) lines.push(`- **Stakeholders:** ${u.stakeholders.join(", ")}`)
      if (u.timeline) lines.push(`- **Timeline:** ${u.timeline}`)
      if (u.constraints?.length) lines.push(`- **Constraints:** ${u.constraints.join(", ")}`)
      if (u.technicalContext) lines.push(`- **Technical Context:** ${u.technicalContext}`)
      if (u.risks?.length) lines.push(`- **Risks:** ${u.risks.join(", ")}`)
      if (u.decisions?.length) {
        lines.push("- **Decisions:**")
        for (const d of u.decisions) {
          lines.push(`  - ${d.decision}`)
        }
      }
      lines.push("")
    }

    // Open questions
    if (state.openQuestions.length > 0) {
      lines.push("### Open Questions")
      for (const q of state.openQuestions) {
        lines.push(`- ${q}`)
      }
      lines.push("")
    }

    // Phase-specific guidance
    lines.push("### Your Role")
    switch (state.phase) {
      case "discovery":
        lines.push("You are conducting a planning interview. Ask probing questions to understand:")
        lines.push("- What problem are we solving? Why now?")
        lines.push("- Who are the stakeholders? What do they need?")
        lines.push("- What's the timeline? What are the constraints?")
        lines.push("- What technical decisions need to be made?")
        lines.push("")
        lines.push("When you need research:")
        lines.push("1. Create an issue: `project-create-issue(title=\"Research: <topic>\")`")
        lines.push("2. Start work: `project-work-on-issue(issueId)`")
        lines.push("3. Continue planning - you'll be notified when complete")
        lines.push("4. When notified, use `project-plan(action='save')` to incorporate findings")
        break

      case "synthesis":
        lines.push("Consolidate findings and make decisions:")
        lines.push("- Review all research findings")
        lines.push("- Make key technical and architectural decisions")
        lines.push("- Identify and document risks")
        lines.push("- Write artifacts to `.projects/<id>/plans/` as needed")
        break

      case "breakdown":
        lines.push("Create actionable issues:")
        lines.push("- Break work into epics, tasks, subtasks")
        lines.push("- Set priorities and dependencies")
        lines.push("- Use `project-create-issue` to create issues in beads")
        break
    }

    lines.push("")
    lines.push("### Actions")
    lines.push("- `project-plan(action='save', understanding='{...}')` - Save progress")
    lines.push("- `project-plan(action='advance')` - Move to next phase")
    lines.push("- `project-plan(action='status')` - View full planning status")
    lines.push("</planning-session>")

    return lines.join("\n")
  }
}
