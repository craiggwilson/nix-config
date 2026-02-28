/**
 * Planning module - Structured project planning workflow
 *
 * This module provides a four-phase planning workflow that guides users through
 * comprehensive project discovery before implementation begins. The workflow
 * ensures that requirements are understood, decisions are documented, and work
 * is properly broken down before coding starts.
 *
 * ## Phases
 *
 * 1. **Discovery** - Gather requirements, understand stakeholders, identify constraints
 * 2. **Synthesis** - Make decisions, document risks, create architecture artifacts
 * 3. **Breakdown** - Create actionable issues with hierarchy and dependencies
 * 4. **Complete** - Planning finished, ready for execution
 *
 * ## Usage
 *
 * ```typescript
 * import { PlanningManager } from "./planning/index.js"
 *
 * const manager = new PlanningManager(projectDir, logger)
 * const state = await manager.startOrContinue()
 *
 * // Build context for system prompt injection
 * const context = await manager.buildContext()
 * ```
 *
 * @module planning
 */

export { PlanningManager } from "./planning-manager.js"
export type {
  PlanningPhase,
  PlanningDecision,
  PlanningUnderstanding,
  PlanningState,
} from "./planning-manager.js"
