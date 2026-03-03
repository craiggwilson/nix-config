import type { Team, TeamMember, DiscussionRound } from "./team-manager.js"

/**
 * Supported discussion strategy types.
 *
 * Persisted on the Team record for observability.
 */
export type DiscussionStrategyType = "fixedRound" | "dynamicRound" | "realtime"

/**
 * Event-based lifecycle hooks for coordinating team discussion.
 *
 * All hooks are optional so strategies only implement what they need:
 * - fixedRound/dynamicRound: implement `onAllMembersCompleted` for batched post-work discussion
 * - realtime: implement `onMemberCompleted` to react as each member finishes
 * - any strategy: implement `onTeamStarted` for setup after all delegations are launched
 */
export interface TeamDiscussionStrategy {
  /** The strategy type — persisted to the Team record when discussion runs */
  readonly type: DiscussionStrategyType

  /**
   * Called once after all member delegations have been started.
   *
   * Useful for strategies that need to set up subscriptions or state
   * before any member completes.
   */
  onTeamStarted?(team: Team): Promise<void>

  /**
   * Called each time a single member completes (successfully or with failure).
   *
   * May return new `DiscussionRound` entries to accumulate into the team's
   * discussion history. Used by realtime strategies that react incrementally
   * as members finish.
   */
  onMemberCompleted?(team: Team, member: TeamMember): Promise<DiscussionRound[]>

  /**
   * Called when ALL members have finished their initial work.
   *
   * Primary hook for round-based strategies (fixedRound, dynamicRound).
   * The `onProgress` callback should be invoked after each round to allow
   * intermediate state to be persisted.
   *
   * @returns Complete discussion history including all rounds produced
   */
  onAllMembersCompleted?(
    team: Team,
    onProgress?: (history: DiscussionRound[]) => Promise<void>
  ): Promise<DiscussionRound[]>
}
