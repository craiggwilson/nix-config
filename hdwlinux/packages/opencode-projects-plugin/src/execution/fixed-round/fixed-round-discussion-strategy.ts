/**
 * FixedRoundDiscussionStrategy - Manages multi-round team discussions
 *
 * Responsible for:
 * - Running discussion rounds between team members
 * - Building discussion context from previous rounds
 * - Sending prompts and collecting responses
 */

import type { Logger, OpencodeClient } from "../../utils/opencode-sdk/index.js"
import type { Team, TeamMember, DiscussionRound } from "../team-manager.js"
import type { Clock } from "../../utils/clock/index.js"
import type { TeamDiscussionStrategy } from "../discussion-strategy.js"
import { systemClock } from "../../utils/clock/index.js"
import { PermissionManager } from "../permission-manager.js"
import { buildDiscussionContext } from "../discussion-context.js"
import { waitForResponse } from "../response-poller.js"

/**
 * Configuration for FixedRoundDiscussionStrategy.
 */
export interface FixedRoundStrategyConfig {
  /** Number of discussion rounds to run */
  rounds: number
  /** Maximum time to wait for each agent's response per round (milliseconds) */
  roundTimeoutMs: number
  /** Clock for timing operations (optional, uses system clock) */
  clock?: Clock
}

/**
 * Orchestrates multi-round team discussions with a fixed round count.
 *
 * After all team members complete their initial work, the discussion phase
 * allows agents to review each other's findings and refine their analysis.
 * Each round:
 * 1. Builds context from initial work and previous rounds
 * 2. Sends discussion prompts to each member
 * 3. Collects and records responses
 *
 * This enables agents to reach consensus, identify overlooked issues,
 * and provide more comprehensive analysis.
 */
export class FixedRoundDiscussionStrategy implements TeamDiscussionStrategy {
  readonly type = "fixedRound" as const
  readonly memberLaunchOrdering = "sequential" as const

  private log: Logger
  private client: OpencodeClient
  private config: FixedRoundStrategyConfig
  private clock: Clock

  /**
   * @param log - Logger for diagnostic output
   * @param client - OpenCode client for session management
   * @param config - Configuration options
   */
  constructor(
    log: Logger,
    client: OpencodeClient,
    config: FixedRoundStrategyConfig,
  ) {
    this.log = log
    this.client = client
    this.config = config
    this.clock = config.clock ?? systemClock
  }

  /**
   * Run all discussion rounds once all members have completed their initial work.
   *
   * Iterates through configured number of rounds, collecting responses
   * from each team member. Calls onProgress after each round to allow
   * state persistence.
   *
   * @param team - The team to run discussion for
   * @param onProgress - Optional callback after each round completes
   * @returns Complete discussion history including all rounds
   */
  async onAllMembersCompleted(
    team: Team,
    onProgress?: (history: DiscussionRound[]) => Promise<void>
  ): Promise<DiscussionRound[]> {
    if (this.config.rounds === 0) {
      return []
    }

    await this.log.info(
      `Team ${team.id}: starting ${this.config.rounds} discussion round(s)`
    )

    const discussionHistory: DiscussionRound[] = [...team.discussionHistory]
    const discussionStartTime = this.clock.now()
    let totalSuccesses = 0
    let totalFailures = 0

    for (let round = 1; round <= this.config.rounds; round++) {
      const roundStartTime = this.clock.now()
      await this.log.info(
        `Team ${team.id}: discussion round ${round}/${this.config.rounds} starting`
      )

      const roundResponses: Record<string, string> = {}
      const context = buildDiscussionContext(team, round, discussionHistory)
      let roundSuccesses = 0
      let roundFailures = 0

      for (const member of team.members) {
        if (!member.sessionId) {
          await this.log.warn(
            `Team ${team.id}: ${member.agent} has no session for discussion`
          )
          roundResponses[member.agent] = "(no session)"
          roundFailures++
          continue
        }

        try {
          const response = await this.sendDiscussionPrompt(
            team,
            member,
            round,
            context
          )
          roundResponses[member.agent] = response
          roundSuccesses++
          await this.log.debug(
            `Team ${team.id}: ${member.agent} responded to round ${round}`
          )
        } catch (error) {
          const errorMsg = error instanceof Error ? error.message : String(error)
          await this.log.warn(
            `Team ${team.id}: ${member.agent} discussion failed: ${errorMsg}`
          )
          roundResponses[member.agent] = `(error: ${errorMsg})`
          roundFailures++
        }
      }

      totalSuccesses += roundSuccesses
      totalFailures += roundFailures
      const roundDurationMs = this.clock.now() - roundStartTime

      await this.log.info(
        `Team ${team.id}: round ${round}/${this.config.rounds} complete successes=${roundSuccesses} failures=${roundFailures} durationMs=${roundDurationMs}`
      )

      discussionHistory.push({ round, responses: roundResponses })

      if (onProgress) {
        await onProgress(discussionHistory)
      }
    }

    const totalDurationMs = this.clock.now() - discussionStartTime
    const totalResponses = totalSuccesses + totalFailures
    const successRate = totalResponses > 0 ? (totalSuccesses / totalResponses).toFixed(2) : "N/A"

    await this.log.info(
      `Team ${team.id}: discussion complete rounds=${this.config.rounds} successes=${totalSuccesses} failures=${totalFailures} successRate=${successRate} totalDurationMs=${totalDurationMs}`
    )

    return discussionHistory
  }

  /**
   * Send a discussion prompt to a member and wait for response.
   *
   * Sends the prompt to the member's existing session and polls for
   * the response with timeout.
   */
  private async sendDiscussionPrompt(
    team: Team,
    member: TeamMember,
    round: number,
    context: string
  ): Promise<string> {
    const prompt = `# Discussion Round ${round}/${this.config.rounds}

## Issue: ${team.issueId}

${context}

## Your Task

As ${member.agent}, provide your updated analysis considering:
1. New insights from other agents
2. Remaining concerns
3. Points of agreement or disagreement
4. Final recommendations

Keep response focused and actionable.`

    // Discussion participants use role-based permissions
    const toolPermissions = PermissionManager.resolvePermissions(member.role)

    await this.client.session.prompt({
      path: { id: member.sessionId! },
      body: {
        agent: member.agent,
        parts: [{ type: "text", text: prompt }],
        noReply: false,
        tools: toolPermissions,
      },
    })

    return await waitForResponse(this.client, member.sessionId!, this.config.roundTimeoutMs, this.clock, this.log)
  }
}
