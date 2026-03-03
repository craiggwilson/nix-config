export { DelegationManager } from "./delegation-manager.js"
export type {
  Delegation,
  DelegationStatus,
  CreateDelegationOptions,
} from "./delegation-manager.js"

export { TeamManager } from "./team-manager.js"
export type {
  TeamMemberRole,
  TeamStatus,
  TeamMemberStatus,
  TeamMember,
  TeamMemberResult,
  DiscussionRound,
  Team,
  CreateTeamOptions,
  TeamConfig,
} from "./team-manager.js"

export { TeamComposer } from "./team-composer.js"
export type { TeamComposerConfig } from "./team-composer.js"

export type {
  TeamDiscussionStrategy,
  DiscussionStrategyType,
} from "./discussion-strategy.js"

export { TeamNotifier } from "./team-notifier.js"

export { PermissionManager } from "./permission-manager.js"
export type { ToolPermissions } from "./permission-manager.js"

export { FixedRoundDiscussionStrategy } from "./fixed-round/index.js"
export type { FixedRoundStrategyConfig } from "./fixed-round/index.js"

export { DynamicRoundDiscussionStrategy, ConvergenceAssessor } from "./dynamic-round/index.js"
export type {
  DynamicRoundStrategyConfig,
  ConvergenceAssessorConfig,
  ConvergenceAssessment,
  AgentConvergenceSignal,
  TeamConvergenceState,
} from "./dynamic-round/index.js"

export { RealtimeDiscussionStrategy, InboxManager } from "./realtime/index.js"
export type {
  RealtimeStrategyConfig,
  InboxManagerConfig,
  InboxMessage,
  MessageType,
  ReadResult,
} from "./realtime/index.js"
