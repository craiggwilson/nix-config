import type { Team, TeamMember, DiscussionRound } from "../teams/index.js";

/**
 * Supported discussion strategy types.
 *
 * Persisted on the Team record for observability.
 */
export type DiscussionStrategyType = "fixedRound" | "dynamicRound" | "realtime";

/**
 * Controls when secondary member delegations are launched relative to the primary.
 *
 * - sequential: secondary delegations are created only after the primary completes,
 *   so reviewers can inspect finished work immediately
 * - concurrent: all delegations are launched at the same time; reviewers must
 *   poll the worktree and wait for the primary to produce changes
 */
export type TeamMemberLaunchOrdering = "sequential" | "concurrent";

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
	readonly type: DiscussionStrategyType;

	/**
	 * Controls when secondary member delegations are launched relative to the primary.
	 *
	 * Strategies declare this declaratively so team-manager.ts can apply the correct
	 * sequencing without conditional checks on strategy type.
	 */
	readonly memberLaunchOrdering: TeamMemberLaunchOrdering;

	/**
	 * Called once after all member delegations have been started.
	 *
	 * Useful for strategies that need to set up subscriptions or state
	 * before any member completes.
	 */
	onTeamStarted?(team: Team): Promise<void>;

	/**
	 * Called each time a single member completes (successfully or with failure).
	 *
	 * May return new `DiscussionRound` entries to accumulate into the team's
	 * discussion history. Used by realtime strategies that react incrementally
	 * as members finish.
	 */
	onMemberCompleted?(
		team: Team,
		member: TeamMember,
	): Promise<DiscussionRound[]>;

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
		onProgress?: (history: DiscussionRound[]) => Promise<void>,
	): Promise<DiscussionRound[]>;
}
