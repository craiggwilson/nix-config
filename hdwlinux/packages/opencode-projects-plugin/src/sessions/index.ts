/**
 * Session Manager module for tracking session history
 *
 * Provides session capture and indexing for project continuity across
 * multiple conversations. Maintains accumulated open questions, pending
 * decisions, and next steps.
 */

export type {
	CaptureSessionOptions,
	SessionError,
	SessionIndex,
	SessionSummary,
	WriteSnapshotOptions,
} from "./session-manager.js";

export { SessionManager } from "./session-manager.js";

export type {
	BuildSessionContextOptions,
	SessionContext,
} from "./prompts/session-context.js";

export {
	buildSessionContext,
	formatSessionContext,
	hasSessionContext,
} from "./prompts/session-context.js";

export {
	summarizeSession,
	type SessionSummaryResult,
	type SummarizeSessionOptions,
} from "./session-summarizer.js";

export { sessionsModule } from "./module.js";
