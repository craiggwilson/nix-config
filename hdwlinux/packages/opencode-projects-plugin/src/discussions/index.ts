export type {
	TeamDiscussionStrategy,
	DiscussionStrategyType,
} from "./discussion-strategy.js";

export { buildDiscussionContext } from "./discussion-context.js";

export {
	extractSignal,
	hasValidSignal,
	ensureSignal,
	parseAgentSignals,
	countSignals,
} from "./convergence-signal.js";
export type { ConvergenceSignal } from "./convergence-signal.js";

export { waitForResponse } from "./response-poller.js";

export { FixedRoundDiscussionStrategy } from "./fixed-round/fixed-round-discussion-strategy.js";
export type { FixedRoundStrategyConfig } from "./fixed-round/fixed-round-discussion-strategy.js";

export { DynamicRoundDiscussionStrategy } from "./dynamic-round/dynamic-round-discussion-strategy.js";
export type { DynamicRoundStrategyConfig } from "./dynamic-round/dynamic-round-discussion-strategy.js";

export { ConvergenceAssessor } from "./dynamic-round/convergence-assessor.js";
export type {
	ConvergenceAssessorConfig,
	ConvergenceAssessment,
	AgentConvergenceSignal,
	TeamConvergenceState,
} from "./dynamic-round/convergence-assessor.js";

export { RealtimeDiscussionStrategy } from "./realtime/realtime-discussion-strategy.js";
export type { RealtimeStrategyConfig } from "./realtime/realtime-discussion-strategy.js";

export { InboxManager } from "./realtime/inbox-manager.js";
export type {
	InboxManagerConfig,
	InboxMessage,
	MessageType,
	ReadResult,
} from "./realtime/inbox-manager.js";
