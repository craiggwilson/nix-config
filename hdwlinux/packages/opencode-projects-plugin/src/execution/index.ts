/**
 * Execution module - Delegation and team management
 *
 * Core components:
 * - DelegationManager: Manages individual agent delegations
 * - TeamManager: Orchestrates multi-agent team execution
 *
 * Supporting components (extracted for SRP):
 * - TeamComposer: Agent selection and team composition
 * - DiscussionCoordinator: Multi-round discussion logic
 * - TeamNotifier: Parent notification and XML generation
 */

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

export { DiscussionCoordinator } from "./discussion-coordinator.js"
export type { DiscussionCoordinatorConfig } from "./discussion-coordinator.js"

export { TeamNotifier } from "./team-notifier.js"
