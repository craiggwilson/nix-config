/**
 * FixedRoundDiscussionStrategy - Manages multi-round team discussions
 *
 * Responsible for:
 * - Running discussion rounds between team members
 * - Building discussion context from previous rounds
 * - Sending prompts and collecting responses
 */

import type { Logger, OpencodeClient, MessageItem, Part } from "../../utils/opencode-sdk/index.js"
import type { Team, TeamMember, DiscussionRound } from "../team-manager.js"
import type { Clock } from "../../utils/clock/index.js"
import type { TeamDiscussionStrategy } from "../discussion-strategy.js"
import { systemClock } from "../../utils/clock/index.js"
import { PermissionManager } from "../permission-manager.js"

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
    config: FixedRoundStrategyConfig
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

    for (let round = 1; round <= this.config.rounds; round++) {
      await this.log.info(
        `Team ${team.id}: discussion round ${round}/${this.config.rounds}`
      )

      const roundResponses: Record<string, string> = {}
      const context = this.buildDiscussionContext(team, round, discussionHistory)

      for (const member of team.members) {
        if (!member.sessionId) {
          await this.log.warn(
            `Team ${team.id}: ${member.agent} has no session for discussion`
          )
          roundResponses[member.agent] = "(no session)"
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
          await this.log.debug(
            `Team ${team.id}: ${member.agent} responded to round ${round}`
          )
        } catch (error) {
          const errorMsg = error instanceof Error ? error.message : String(error)
          await this.log.warn(
            `Team ${team.id}: ${member.agent} discussion failed: ${errorMsg}`
          )
          roundResponses[member.agent] = `(error: ${errorMsg})`
        }
      }

      discussionHistory.push({ round, responses: roundResponses })

      if (onProgress) {
        await onProgress(discussionHistory)
      }
    }

    await this.log.info(`Team ${team.id}: discussion complete`)
    return discussionHistory
  }

  /**
   * Build context for a discussion round.
   *
   * Assembles context from:
   * - Primary agent's implementation
   * - Other agents' initial findings
   * - Previous discussion rounds (if any)
   *
   * @param team - The team with results
   * @param round - Current round number (1-based)
   * @param discussionHistory - Previous rounds' responses
   * @returns Formatted context string for the discussion prompt
   */
  buildDiscussionContext(
    team: Team,
    round: number,
    discussionHistory: DiscussionRound[]
  ): string {
    const lines: string[] = []

    // Primary agent's work
    const primary = team.members.find((m) => m.role === "primary")
    if (primary && team.results[primary.agent]) {
      lines.push("## Primary Agent's Implementation")
      lines.push("")
      lines.push(team.results[primary.agent].result)
      lines.push("")
    }

    // Other agents' initial findings
    lines.push("## Team Findings")
    lines.push("")
    for (const member of team.members) {
      if (member.role !== "primary" && team.results[member.agent]) {
        lines.push(`### ${member.agent}`)
        lines.push("")
        lines.push(team.results[member.agent].result)
        lines.push("")
      }
    }

    // Previous discussion rounds
    if (round > 1 && discussionHistory.length > 0) {
      lines.push("## Previous Discussion")
      lines.push("")
      for (const prevRound of discussionHistory) {
        lines.push(`### Round ${prevRound.round}`)
        lines.push("")
        for (const [agent, response] of Object.entries(prevRound.responses)) {
          lines.push(`**${agent}:**`)
          lines.push(response)
          lines.push("")
        }
      }
    }

    return lines.join("\n")
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

    return await this.waitForResponse(
      member.sessionId!,
      this.config.roundTimeoutMs
    )
  }

  /**
   * Wait for a response from a session with timeout.
   *
   * Polls the session for new assistant messages until a response is found
   * or timeout is reached.
   *
   * @param sessionId - The session to poll
   * @param timeoutMs - Maximum time to wait
   * @returns The response text
   * @throws Error if timeout is reached
   */
  private async waitForResponse(
    sessionId: string,
    timeoutMs: number
  ): Promise<string> {
    const startTime = this.clock.now()
    const pollInterval = 2000

    while (this.clock.now() - startTime < timeoutMs) {
      await this.clock.sleep(pollInterval)

      try {
        const messages = await this.client.session.messages({
          path: { id: sessionId },
        })

        const messageData: MessageItem[] | undefined = messages.data
        if (!messageData || messageData.length === 0) {
          continue
        }

        const assistantMessages = messageData.filter(
          (m) => m.info?.role === "assistant"
        )
        if (assistantMessages.length === 0) {
          continue
        }

        const lastMessage = assistantMessages[assistantMessages.length - 1]

        const parts: Part[] = lastMessage.parts || []
        const textParts = parts.filter((p) => p.type === "text")
        const text = textParts.map((p) => p.text || "").join("\n")

        if (text && text.length > 0) {
          return text
        }
      } catch (error) {
        await this.log.debug(`Error polling session ${sessionId}: ${error}`)
      }
    }

    throw new Error(`Timeout waiting for response after ${timeoutMs / 1000}s`)
  }
}
