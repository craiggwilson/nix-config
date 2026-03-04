/**
 * Decision management module
 *
 * Exports types and the DecisionManager class for managing decision records
 * with status tracking, pending decisions, and historical records.
 *
 * @module decisions
 */

export type {
	Alternative,
	DecisionError,
	DecisionIndex,
	DecisionRecord,
	DecisionStatus,
	PendingDecision,
	RecordDecisionOptions,
} from "./decision-manager.js";

export { DecisionManager } from "./decision-manager.js";

export {
	buildDecisionContext,
	formatDecisionContext,
	formatDecisionSummary,
	hasDecisionContext,
	type BuildDecisionContextOptions,
	type DecisionContext,
} from "./prompts/decision-context.js";
