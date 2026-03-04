/**
 * PlanningManager - Manages project planning state and workflow
 *
 * Planning follows a structured four-phase workflow designed to ensure thorough
 * understanding before implementation begins. This prevents premature coding and
 * ensures alignment between stakeholders and technical decisions.
 *
 * The phases are:
 * 1. **Discovery** - Gather requirements, understand the problem space, identify stakeholders
 * 2. **Synthesis** - Consolidate findings, make architectural decisions, document risks
 * 3. **Breakdown** - Create actionable issues with proper hierarchy and dependencies
 * 4. **Complete** - Planning finished, ready for execution
 *
 * State is persisted to `planning.json` within the project directory, allowing
 * planning sessions to be resumed across multiple conversations. The accumulated
 * understanding is injected into system prompts to maintain context.
 *
 * ## Error Handling
 *
 * This module uses Result types for explicit error handling. Methods return
 * `Result<T, PlanningError>` to communicate success or failure without exceptions.
 *
 * @module planning
 */

import * as fs from "node:fs/promises";
import * as path from "node:path";

import type { PlanningError } from "../utils/errors/index.js";
import { formatPlanningError } from "../utils/errors/index.js";
import type { Logger } from "../utils/opencode-sdk/index.js";
import type { Result } from "../utils/result/index.js";
import { err, ok } from "../utils/result/index.js";

/**
 * Represents the current phase of a planning session.
 *
 * Phases must be traversed in order (discovery → synthesis → breakdown → complete),
 * though users can jump back to earlier phases if needed. This ordering ensures
 * that understanding is built incrementally before work is broken down.
 *
 * - `discovery`: Initial exploration phase for gathering requirements
 * - `synthesis`: Decision-making phase for consolidating findings
 * - `breakdown`: Issue creation phase for defining actionable work
 * - `complete`: Terminal state indicating planning is finished
 */
export type PlanningPhase =
	| "discovery"
	| "synthesis"
	| "breakdown"
	| "complete";

/**
 * Captures a key decision made during planning along with its rationale.
 *
 * Decisions are tracked separately from general understanding because they
 * represent explicit choices that may need to be revisited or explained later.
 * The rationale field ensures decisions are documented with their reasoning,
 * which is valuable for onboarding and future reference.
 */
export interface PlanningDecision {
	/** The decision that was made (e.g., "Use PostgreSQL for persistence") */
	decision: string;
	/** Why this decision was made (e.g., "Team expertise and ACID requirements") */
	rationale: string;
}

/**
 * Accumulated knowledge gathered during the planning process.
 *
 * This structure captures the evolving understanding of the project across
 * multiple dimensions. Fields are optional because understanding builds
 * incrementally - not all information is known at the start.
 *
 * The structure is designed to prompt comprehensive planning by covering:
 * - Problem definition (what and why)
 * - Stakeholder analysis (who cares and what they need)
 * - Constraints and timeline (boundaries and deadlines)
 * - Technical context (existing systems, integration points)
 * - Risk identification (what could go wrong)
 * - Key decisions (choices made and their rationale)
 */
export interface PlanningUnderstanding {
	/** Core problem statement - what are we solving and why does it matter? */
	problem?: string;
	/** Desired outcomes - what does success look like? */
	goals?: string[];
	/** People or systems affected - who cares about this project? */
	stakeholders?: string[];
	/** Time constraints - when does this need to be done? */
	timeline?: string;
	/** Limitations and boundaries - what can't we change? */
	constraints?: string[];
	/** Existing systems and integration points - what do we need to work with? */
	technicalContext?: string;
	/** Potential issues and mitigations - what could go wrong? */
	risks?: string[];
	/** Key choices made during planning with their rationale */
	decisions?: PlanningDecision[];
}

/**
 * Complete planning session state persisted to disk.
 *
 * This state is saved to `planning.json` within the project directory and
 * loaded on each interaction. The timestamps enable tracking of planning
 * velocity and identifying stale sessions.
 *
 * The `completedPhases` array tracks which phases have been explicitly
 * completed (vs just visited), enabling progress visualization and
 * preventing accidental regression.
 */
export interface PlanningState {
	/** Current active phase */
	phase: PlanningPhase;
	/** ISO timestamp when planning began */
	startedAt: string;
	/** ISO timestamp of last modification */
	lastUpdatedAt: string;
	/** Accumulated project understanding */
	understanding: PlanningUnderstanding;
	/** Unresolved questions requiring answers */
	openQuestions: string[];
	/** Phases that have been explicitly completed */
	completedPhases: PlanningPhase[];
}

/**
 * Defines the valid phase progression order.
 *
 * Phases must generally be traversed in this order to ensure proper
 * understanding before breakdown. The `advancePhase` method uses this
 * array to determine the next phase.
 */
const PHASE_ORDER: PlanningPhase[] = [
	"discovery",
	"synthesis",
	"breakdown",
	"complete",
];

/**
 * Result returned from planning action handlers.
 *
 * Used by tool implementations to communicate success/failure along with
 * user-facing messages and optional state for further processing.
 */
export interface PlanningActionResult {
	/** Whether the action completed successfully */
	success: boolean;
	/** Human-readable message describing the outcome */
	message: string;
	/** Updated state if the action modified it */
	state?: PlanningState;
}

/**
 * Manages planning session state and workflow for a single project.
 *
 * PlanningManager encapsulates all planning operations including state persistence,
 * phase transitions, and context generation. Each project has its own PlanningManager
 * instance tied to its project directory.
 *
 * The manager is designed to support conversational planning where the AI guides
 * users through structured discovery. State is persisted after each operation,
 * allowing sessions to span multiple conversations.
 *
 * @example
 * ```typescript
 * const manager = new PlanningManager("/path/to/project", logger)
 *
 * // Start or resume planning
 * const state = await manager.startOrContinue()
 *
 * // Update understanding as information is gathered
 * await manager.updateUnderstanding({
 *   problem: "Users can't find relevant documentation",
 *   goals: ["Improve search accuracy", "Reduce time to find answers"]
 * })
 *
 * // Advance when ready for next phase
 * await manager.advancePhase()
 * ```
 */
export class PlanningManager {
	/** Path to the project directory containing planning.json */
	private projectDir: string;
	/** Logger for tracking planning operations */
	private log: Logger;

	/**
	 * Creates a new PlanningManager for a specific project.
	 *
	 * @param projectDir - Absolute path to the project directory (e.g., `.projects/my-project-abc123`)
	 * @param log - Logger instance for operation tracking
	 */
	constructor(projectDir: string, log: Logger) {
		this.projectDir = projectDir;
		this.log = log;
	}

	/**
	 * Resolves the path to the planning state file.
	 *
	 * State is stored as `planning.json` in the project directory alongside
	 * other project metadata. This co-location simplifies backup and cleanup.
	 */
	private getStatePath(): string {
		return path.join(this.projectDir, "planning.json");
	}

	/**
	 * Creates the initial state for a new planning session.
	 *
	 * New sessions always start in the discovery phase with empty understanding.
	 * This ensures users go through the full planning workflow rather than
	 * jumping directly to implementation.
	 */
	private createInitialState(): PlanningState {
		const now = new Date().toISOString();
		return {
			phase: "discovery",
			startedAt: now,
			lastUpdatedAt: now,
			understanding: {},
			openQuestions: [],
			completedPhases: [],
		};
	}

	/**
	 * Retrieves the current planning state from disk.
	 *
	 * Returns null if no planning session exists (file not found), allowing
	 * callers to distinguish between "no session" and "session with empty state".
	 * Other file system errors are propagated.
	 *
	 * @returns The current planning state, or null if no session exists
	 * @throws If the file exists but cannot be read or parsed
	 */
	async getState(): Promise<PlanningState | null> {
		const statePath = this.getStatePath();

		try {
			const content = await fs.readFile(statePath, "utf-8");
			return JSON.parse(content) as PlanningState;
		} catch (error) {
			if ((error as NodeJS.ErrnoException).code === "ENOENT") {
				return null;
			}
			throw error;
		}
	}

	/**
	 * Persists the planning state to disk.
	 *
	 * Automatically updates the `lastUpdatedAt` timestamp before saving.
	 * The state is written atomically (via Node's writeFile) to prevent
	 * corruption from interrupted writes.
	 *
	 * @param state - The state to persist
	 */
	async saveState(state: PlanningState): Promise<void> {
		state.lastUpdatedAt = new Date().toISOString();
		const statePath = this.getStatePath();
		await fs.writeFile(statePath, JSON.stringify(state, null, 2));
	}

	/**
	 * Starts a new planning session or continues an existing one.
	 *
	 * This is the primary entry point for planning operations. It handles
	 * both first-time initialization and session resumption transparently,
	 * allowing the same code path regardless of whether planning has started.
	 *
	 * @returns Result containing the current (possibly newly created) planning state
	 */
	async startOrContinue(): Promise<Result<PlanningState, PlanningError>> {
		try {
			let state = await this.getState();

			if (!state) {
				state = this.createInitialState();
				await this.saveState(state);
				await this.log.info(`Started new planning session`);
			} else {
				await this.log.info(
					`Continuing planning session (phase: ${state.phase})`,
				);
			}

			return ok(state);
		} catch (error) {
			return err({ type: "persistence_failed", message: String(error) });
		}
	}

	/**
	 * Checks whether planning is currently in progress.
	 *
	 * A session is considered active if it exists and hasn't reached the
	 * "complete" phase. This is used to determine whether to inject planning
	 * context into system prompts.
	 *
	 * @returns True if an active planning session exists
	 */
	async isActive(): Promise<boolean> {
		const state = await this.getState();
		return state !== null && state.phase !== "complete";
	}

	/**
	 * Advances to the next planning phase in sequence.
	 *
	 * Phases progress in order: discovery → synthesis → breakdown → complete.
	 * The current phase is marked as completed before advancing, enabling
	 * progress tracking. Cannot advance from the "complete" phase.
	 *
	 * @returns Result containing the updated state with the new phase, or an error
	 */
	async advancePhase(): Promise<Result<PlanningState, PlanningError>> {
		try {
			const state = await this.getState();
			if (!state) {
				return err({ type: "no_session" });
			}

			const currentIndex = PHASE_ORDER.indexOf(state.phase);

			if (currentIndex === -1 || currentIndex >= PHASE_ORDER.length - 1) {
				return err({ type: "cannot_advance", currentPhase: state.phase });
			}

			// Mark current phase as completed
			if (!state.completedPhases.includes(state.phase)) {
				state.completedPhases.push(state.phase);
			}

			// Move to next phase
			state.phase = PHASE_ORDER[currentIndex + 1];
			await this.saveState(state);

			await this.log.info(`Advanced planning to phase: ${state.phase}`);
			return ok(state);
		} catch (error) {
			return err({ type: "persistence_failed", message: String(error) });
		}
	}

	/**
	 * Jumps directly to a specific planning phase.
	 *
	 * Unlike `advancePhase`, this allows non-sequential transitions, enabling
	 * users to revisit earlier phases if new information requires rethinking.
	 * Does not modify the `completedPhases` array.
	 *
	 * @param phase - The phase to jump to
	 * @returns Result containing the updated state, or an error
	 */
	async setPhase(
		phase: PlanningPhase,
	): Promise<Result<PlanningState, PlanningError>> {
		try {
			const state = await this.getState();
			if (!state) {
				return err({ type: "no_session" });
			}

			state.phase = phase;
			await this.saveState(state);

			await this.log.info(`Set planning phase to: ${phase}`);
			return ok(state);
		} catch (error) {
			return err({ type: "persistence_failed", message: String(error) });
		}
	}

	/**
	 * Merges new information into the accumulated understanding.
	 *
	 * Updates are merged with existing understanding rather than replacing it,
	 * allowing incremental knowledge building. Array fields (goals, stakeholders,
	 * constraints, risks) are deduplicated to prevent redundancy. Decisions are
	 * appended while avoiding duplicates based on the decision text.
	 *
	 * @param updates - Partial understanding to merge
	 * @returns Result containing the updated state, or an error
	 */
	async updateUnderstanding(
		updates: Partial<PlanningUnderstanding>,
	): Promise<Result<PlanningState, PlanningError>> {
		try {
			const state = await this.getState();
			if (!state) {
				return err({ type: "no_session" });
			}

			// Merge updates into existing understanding
			state.understanding = {
				...state.understanding,
				...updates,
			};

			// Deduplicate arrays
			if (updates.goals) {
				state.understanding.goals = [...new Set(state.understanding.goals)];
			}
			if (updates.stakeholders) {
				state.understanding.stakeholders = [
					...new Set(state.understanding.stakeholders),
				];
			}
			if (updates.constraints) {
				state.understanding.constraints = [
					...new Set(state.understanding.constraints),
				];
			}
			if (updates.risks) {
				state.understanding.risks = [...new Set(state.understanding.risks)];
			}
			if (updates.decisions && state.understanding.decisions) {
				// Append new decisions, avoiding duplicates
				const existingDecisions = state.understanding.decisions.map(
					(d) => d.decision,
				);
				const newDecisions = updates.decisions.filter(
					(d) => !existingDecisions.includes(d.decision),
				);
				state.understanding.decisions = [
					...state.understanding.decisions,
					...newDecisions,
				];
			}

			await this.saveState(state);
			return ok(state);
		} catch (error) {
			return err({ type: "persistence_failed", message: String(error) });
		}
	}

	/**
	 * Replaces the list of open questions.
	 *
	 * Open questions track unresolved items that need answers before planning
	 * can progress. Unlike understanding updates, questions are replaced rather
	 * than merged, as the list represents the current state of unknowns.
	 *
	 * @param questions - The new list of open questions
	 * @returns Result containing the updated state, or an error
	 */
	async updateOpenQuestions(
		questions: string[],
	): Promise<Result<PlanningState, PlanningError>> {
		try {
			const state = await this.getState();
			if (!state) {
				return err({ type: "no_session" });
			}

			state.openQuestions = questions;
			await this.saveState(state);
			return ok(state);
		} catch (error) {
			return err({ type: "persistence_failed", message: String(error) });
		}
	}

	// ============================================================================
	// Formatting Methods
	// ============================================================================

	/**
	 * Formats the accumulated understanding as markdown for display.
	 *
	 * Produces a human-readable summary of all known information, with each
	 * field on its own line. Empty/undefined fields are omitted to keep
	 * output concise. Decisions are formatted as a nested list with rationale.
	 *
	 * @param understanding - The understanding to format
	 * @returns Markdown-formatted string
	 */
	formatUnderstanding(understanding: PlanningUnderstanding): string {
		const lines: string[] = [];

		if (understanding.problem) {
			lines.push(`**Problem:** ${understanding.problem}`);
		}
		if (understanding.goals?.length) {
			lines.push(`**Goals:** ${understanding.goals.join(", ")}`);
		}
		if (understanding.stakeholders?.length) {
			lines.push(`**Stakeholders:** ${understanding.stakeholders.join(", ")}`);
		}
		if (understanding.timeline) {
			lines.push(`**Timeline:** ${understanding.timeline}`);
		}
		if (understanding.constraints?.length) {
			lines.push(`**Constraints:** ${understanding.constraints.join(", ")}`);
		}
		if (understanding.technicalContext) {
			lines.push(`**Technical Context:** ${understanding.technicalContext}`);
		}
		if (understanding.risks?.length) {
			lines.push(`**Risks:** ${understanding.risks.join(", ")}`);
		}
		if (understanding.decisions?.length) {
			lines.push("**Decisions:**");
			for (const d of understanding.decisions) {
				lines.push(`  - ${d.decision} (${d.rationale})`);
			}
		}

		return lines.join("\n");
	}

	/**
	 * Formats the complete planning status as markdown.
	 *
	 * Includes phase information, timestamps, completed phases, understanding
	 * summary, and open questions. Used by the status action handler to provide
	 * a comprehensive view of planning progress.
	 *
	 * @param state - The planning state to format
	 * @returns Markdown-formatted status string
	 */
	formatStatus(state: PlanningState): string {
		const lines: string[] = [];

		lines.push(`**Phase:** ${state.phase}`);
		lines.push(`**Started:** ${state.startedAt}`);
		lines.push(`**Last Updated:** ${state.lastUpdatedAt}`);

		if (state.completedPhases.length > 0) {
			lines.push(`**Completed Phases:** ${state.completedPhases.join(", ")}`);
		}

		lines.push("");

		if (Object.keys(state.understanding).length > 0) {
			lines.push("### Understanding");
			lines.push(this.formatUnderstanding(state.understanding));
			lines.push("");
		}

		if (state.openQuestions.length > 0) {
			lines.push(`### Open Questions: ${state.openQuestions.length}`);
			for (const q of state.openQuestions) {
				lines.push(`- ${q}`);
			}
			lines.push("");
		}

		return lines.join("\n");
	}

	/**
	 * Generates phase-specific guidance text for the AI.
	 *
	 * Each phase has distinct goals and recommended actions. This guidance
	 * is included in tool responses and system prompts to help the AI
	 * understand what to do in each phase. The guidance includes:
	 * - Phase objectives
	 * - Key questions or tasks
	 * - Available actions and tools
	 * - Criteria for advancing to the next phase
	 *
	 * @param phase - The phase to generate guidance for
	 * @returns Markdown-formatted guidance text
	 */
	getPhaseGuidance(phase: PlanningPhase): string {
		const lines: string[] = [];

		switch (phase) {
			case "discovery":
				lines.push("### Discovery Phase");
				lines.push("");
				lines.push(
					"**Your goal:** Deeply understand the project before making any decisions.",
				);
				lines.push("");
				lines.push("**Questions to explore:**");
				lines.push(
					"- What problem are we solving? Why now? Why is this important?",
				);
				lines.push(
					"- Who are the stakeholders? What do they need? What are their priorities?",
				);
				lines.push("- What's the timeline? What are the hard deadlines?");
				lines.push(
					"- What constraints exist? (technical, organizational, budget, etc.)",
				);
				lines.push("- What has been tried before? What worked/didn't work?");
				lines.push("");
				lines.push("**When you need research:**");
				lines.push(
					'1. Create an issue: `project-create-issue(title="Research: <topic>")`',
				);
				lines.push("2. Start work: `project-work-on-issue(issueId)`");
				lines.push("3. Continue planning - you'll be notified when complete");
				lines.push(
					"4. When notified, use `project-plan(action='save')` to incorporate findings",
				);
				lines.push("");
				lines.push(
					"**When ready:** Use `project-plan(action='advance')` to move to synthesis.",
				);
				break;

			case "synthesis":
				lines.push("### Synthesis Phase");
				lines.push("");
				lines.push(
					"**Your goal:** Consolidate findings, make decisions, identify risks.",
				);
				lines.push("");
				lines.push("**Tasks:**");
				lines.push("- Review all research findings");
				lines.push("- Make key technical and architectural decisions");
				lines.push("- Identify and document risks with mitigations");
				lines.push("- Define success criteria");
				lines.push(
					"- Create any necessary artifacts (architecture docs, etc.)",
				);
				lines.push("");
				lines.push("**Artifacts:** Write directly to `plans/` as needed:");
				lines.push("- `plans/architecture.md` - Technical architecture");
				lines.push("- `plans/risks.md` - Risk register");
				lines.push("- `plans/roadmap.md` - High-level roadmap");
				lines.push("");
				lines.push(
					"**When ready:** Use `project-plan(action='advance')` to move to breakdown.",
				);
				break;

			case "breakdown":
				lines.push("### Breakdown Phase");
				lines.push("");
				lines.push("**Your goal:** Create actionable issues.");
				lines.push("");
				lines.push("**Tasks:**");
				lines.push("- Break work into epics, tasks, and subtasks");
				lines.push("- Set priorities (P0-P3)");
				lines.push("- Define dependencies between issues");
				lines.push("- Ensure each issue is actionable and well-defined");
				lines.push("");
				lines.push("**Creating issues:**");
				lines.push(
					"- `project-create-issue(title, description, priority, parentId, blockedBy)`",
				);
				lines.push("");
				lines.push(
					"**When ready:** Use `project-plan(action='advance')` to complete planning.",
				);
				break;

			case "complete":
				lines.push("### Planning Complete");
				lines.push("");
				lines.push("Planning is finished. You can now:");
				lines.push("- Start working on issues with `project-work-on-issue`");
				lines.push("- View project status with `project-status`");
				lines.push(
					"- Return to planning with `project-plan(action='phase', phase='discovery')`",
				);
				break;
		}

		return lines.join("\n");
	}

	// ============================================================================
	// Action Handlers (called by tool)
	// ============================================================================

	/**
	 * Handles the 'status' action from the project-plan tool.
	 *
	 * Returns a formatted view of the current planning state, or a message
	 * indicating no session exists. This is the read-only inspection action.
	 *
	 * @param projectId - The project ID for display purposes
	 * @returns Formatted status message
	 */
	async handleStatus(projectId: string): Promise<string> {
		const state = await this.getState();

		if (!state) {
			return `No planning session found for project '${projectId}'.\n\nUse \`project-plan(action='start')\` to begin planning.`;
		}

		return `## Planning Status: ${projectId}\n\n${this.formatStatus(state)}`;
	}

	/**
	 * Handles the 'start' and 'continue' actions from the project-plan tool.
	 *
	 * Creates a new session if none exists, or resumes the existing one.
	 * Returns a comprehensive view including current understanding, open
	 * questions, and phase-specific guidance to orient the AI.
	 *
	 * @param projectId - The project ID for display purposes
	 * @returns Formatted session overview with guidance
	 */
	async handleStartOrContinue(projectId: string): Promise<string> {
		const result = await this.startOrContinue();
		if (!result.ok) {
			return formatPlanningError(result.error);
		}
		const state = result.value;

		const lines: string[] = [];

		lines.push(`## Planning Session: ${projectId}`);
		lines.push("");
		lines.push(`**Phase:** ${state.phase}`);
		lines.push(`**Started:** ${state.startedAt}`);
		lines.push(`**Last Updated:** ${state.lastUpdatedAt}`);
		lines.push("");

		// Show current understanding
		if (Object.keys(state.understanding).length > 0) {
			lines.push("### Current Understanding");
			lines.push("");
			lines.push(this.formatUnderstanding(state.understanding));
			lines.push("");
		}

		// Show open questions
		if (state.openQuestions.length > 0) {
			lines.push("### Open Questions");
			lines.push("");
			for (const q of state.openQuestions) {
				lines.push(`- ${q}`);
			}
			lines.push("");
		}

		lines.push("---");
		lines.push("");

		// Add phase-specific guidance
		lines.push(this.getPhaseGuidance(state.phase));

		return lines.join("\n");
	}

	/**
	 * Handles the 'save' action from the project-plan tool.
	 *
	 * Persists updates to understanding and/or open questions. The understanding
	 * parameter is expected as a JSON string (parsed here) to allow flexible
	 * updates from the AI. Open questions are comma-separated for simplicity.
	 *
	 * @param projectId - The project ID for display purposes
	 * @param understandingJson - Optional JSON string of understanding updates
	 * @param openQuestionsStr - Optional comma-separated list of questions
	 * @returns Confirmation message with updated status
	 */
	async handleSave(
		projectId: string,
		understandingJson?: string,
		openQuestionsStr?: string,
	): Promise<string> {
		const state = await this.getState();

		if (!state) {
			return `No planning session found for project '${projectId}'.`;
		}

		// Update understanding if provided
		if (understandingJson) {
			try {
				const updates = JSON.parse(understandingJson);
				const result = await this.updateUnderstanding(updates);
				if (!result.ok) {
					return formatPlanningError(result.error);
				}
			} catch (e) {
				return `Error parsing understanding JSON: ${e}`;
			}
		}

		// Update open questions if provided
		if (openQuestionsStr) {
			const questions = openQuestionsStr
				.split(",")
				.map((q) => q.trim())
				.filter(Boolean);
			const result = await this.updateOpenQuestions(questions);
			if (!result.ok) {
				return formatPlanningError(result.error);
			}
		}

		const updatedState = await this.getState();
		if (!updatedState) {
			return "## Planning Progress Saved\n\n(state unavailable)";
		}

		return `## Planning Progress Saved\n\n${this.formatStatus(updatedState)}`;
	}

	/**
	 * Handles the 'advance' action from the project-plan tool.
	 *
	 * Moves to the next phase in sequence. Returns guidance for the new phase,
	 * or a completion message if planning is finished.
	 *
	 * @returns Formatted message with new phase guidance or error
	 */
	async handleAdvance(): Promise<string> {
		const result = await this.advancePhase();
		if (!result.ok) {
			return formatPlanningError(result.error);
		}
		const state = result.value;

		const lines: string[] = [];
		lines.push(`## Advanced to Phase: ${state.phase}`);
		lines.push("");

		if (state.phase === "complete") {
			lines.push("🎉 Planning is complete!");
			lines.push("");
			lines.push("You can now:");
			lines.push("- Review the issues created");
			lines.push("- Start working on issues with `project-work-on-issue`");
			lines.push("- Close the project when done with `project-close`");
		} else {
			lines.push(this.getPhaseGuidance(state.phase));
		}

		return lines.join("\n");
	}

	/**
	 * Handles the 'phase' action from the project-plan tool.
	 *
	 * Allows jumping directly to a specific phase, useful for revisiting
	 * earlier phases when new information emerges. Returns guidance for
	 * the selected phase.
	 *
	 * @param phase - The phase to jump to
	 * @returns Formatted message with phase guidance or error
	 */
	async handleSetPhase(phase: PlanningPhase): Promise<string> {
		const result = await this.setPhase(phase);
		if (!result.ok) {
			return formatPlanningError(result.error);
		}
		const state = result.value;

		const lines: string[] = [];
		lines.push(`## Phase Set: ${state.phase}`);
		lines.push("");
		lines.push(this.getPhaseGuidance(state.phase));

		return lines.join("\n");
	}

	// ============================================================================
	// Context Building (for system prompt injection)
	// ============================================================================

	/**
	 * Builds planning context for injection into system prompts.
	 *
	 * When planning is active, this context is injected into every AI interaction
	 * to maintain awareness of the planning state. The context includes:
	 * - Current phase and timestamps
	 * - Accumulated understanding
	 * - Open questions
	 * - Phase-specific role guidance
	 * - Available actions
	 *
	 * Returns null if no active planning session exists (either no session
	 * or session is complete), indicating no context should be injected.
	 *
	 * @returns XML-wrapped planning context, or null if not applicable
	 */
	async buildContext(): Promise<string | null> {
		const state = await this.getState();
		if (!state || state.phase === "complete") return null;

		const lines: string[] = ["<planning-session>"];
		lines.push(`## Active Planning`);
		lines.push(`**Phase:** ${state.phase}`);
		lines.push(`**Last Updated:** ${state.lastUpdatedAt}`);
		lines.push("");

		// Current understanding
		if (Object.keys(state.understanding).length > 0) {
			lines.push("### What We Know");
			const u = state.understanding;
			if (u.problem) lines.push(`- **Problem:** ${u.problem}`);
			if (u.goals?.length) lines.push(`- **Goals:** ${u.goals.join(", ")}`);
			if (u.stakeholders?.length)
				lines.push(`- **Stakeholders:** ${u.stakeholders.join(", ")}`);
			if (u.timeline) lines.push(`- **Timeline:** ${u.timeline}`);
			if (u.constraints?.length)
				lines.push(`- **Constraints:** ${u.constraints.join(", ")}`);
			if (u.technicalContext)
				lines.push(`- **Technical Context:** ${u.technicalContext}`);
			if (u.risks?.length) lines.push(`- **Risks:** ${u.risks.join(", ")}`);
			if (u.decisions?.length) {
				lines.push("- **Decisions:**");
				for (const d of u.decisions) {
					lines.push(`  - ${d.decision}`);
				}
			}
			lines.push("");
		}

		// Open questions
		if (state.openQuestions.length > 0) {
			lines.push("### Open Questions");
			for (const q of state.openQuestions) {
				lines.push(`- ${q}`);
			}
			lines.push("");
		}

		// Phase-specific guidance
		lines.push("### Your Role");
		switch (state.phase) {
			case "discovery":
				lines.push(
					"You are conducting a planning interview. Ask probing questions to understand:",
				);
				lines.push("- What problem are we solving? Why now?");
				lines.push("- Who are the stakeholders? What do they need?");
				lines.push("- What's the timeline? What are the constraints?");
				lines.push("- What technical decisions need to be made?");
				lines.push("");
				lines.push("When you need research:");
				lines.push(
					'1. Create an issue: `project-create-issue(title="Research: <topic>")`',
				);
				lines.push("2. Start work: `project-work-on-issue(issueId)`");
				lines.push("3. Continue planning - you'll be notified when complete");
				lines.push(
					"4. When notified, use `project-plan(action='save')` to incorporate findings",
				);
				break;

			case "synthesis":
				lines.push("Consolidate findings and make decisions:");
				lines.push("- Review all research findings");
				lines.push("- Make key technical and architectural decisions");
				lines.push("- Identify and document risks");
				lines.push("- Write artifacts to `plans/` as needed");
				break;

			case "breakdown":
				lines.push("Create actionable issues:");
				lines.push("- Break work into epics, tasks, subtasks");
				lines.push("- Set priorities and dependencies");
				lines.push("- Use `project-create-issue` to create issues");
				break;
		}

		lines.push("");
		lines.push("### Actions");
		lines.push(
			"- `project-plan(action='save', understanding='{...}')` - Save progress",
		);
		lines.push("- `project-plan(action='advance')` - Move to next phase");
		lines.push("- `project-plan(action='status')` - View full planning status");
		lines.push("</planning-session>");

		return lines.join("\n");
	}
}
