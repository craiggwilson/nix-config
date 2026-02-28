/**
 * DiscussionCoordinator - Manages multi-round team discussions
 *
 * Responsible for:
 * - Running discussion rounds between team members
 * - Building discussion context from previous rounds
 * - Sending prompts and collecting responses
 */

import type { Logger, OpencodeClient, MessageItem, Part } from "../utils/opencode-sdk/index.js"
import type { Team, TeamMember, TeamMemberResult, DiscussionRound } from "./team-manager.js"

/**
 * Configuration options for DiscussionCoordinator.
 */
export interface DiscussionCoordinatorConfig {
  /** Maximum time to wait for each agent's response per round (milliseconds) */
  discussionRoundTimeoutMs: number
}

/**
 * Tools to disable in discussion sessions
 */
const DISABLED_TOOLS: Record<string, boolean> = {
  task: false,
  delegate: false,
  todowrite: false,
  plan_save: false,
  "project-create": false,
  "project-close": false,
  "project-create-issue": false,
  "project-update-issue": false,
  "project-work-on-issue": false,
}

/**
 * Orchestrates multi-round team discussions.
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
export class DiscussionCoordinator {
  private log: Logger
  private client: OpencodeClient
  private config: DiscussionCoordinatorConfig

  /**
   * @param log - Logger for diagnostic output
   * @param client - OpenCode client for session management
   * @param config - Configuration options
   */
  constructor(
    log: Logger,
    client: OpencodeClient,
    config: DiscussionCoordinatorConfig
  ) {
    this.log = log
    this.client = client
    this.config = config
  }

  /**
   * Run all discussion rounds for a team.
   *
   * Iterates through configured number of rounds, collecting responses
   * from each team member. Calls onRoundComplete callback after each round
   * to allow state persistence.
   *
   * @param team - The team to run discussion for
   * @param onRoundComplete - Optional callback after each round completes
   * @returns Complete discussion history including all rounds
   */
  async runDiscussion(
    team: Team,
    onRoundComplete?: (round: number, responses: Record<string, string>) => Promise<void>
  ): Promise<DiscussionRound[]> {
    await this.log.info(
      `Team ${team.id}: starting ${team.discussionRounds} discussion round(s)`
    )

    const discussionHistory: DiscussionRound[] = [...team.discussionHistory]

    for (let round = 1; round <= team.discussionRounds; round++) {
      await this.log.info(
        `Team ${team.id}: discussion round ${round}/${team.discussionRounds}`
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

      if (onRoundComplete) {
        await onRoundComplete(round, roundResponses)
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
    const prompt = `# Discussion Round ${round}/${team.discussionRounds}

## Issue: ${team.issueId}

${context}

## Your Task

As ${member.agent}, provide your updated analysis considering:
1. New insights from other agents
2. Remaining concerns
3. Points of agreement or disagreement
4. Final recommendations

Keep response focused and actionable.`

    await this.client.session.prompt({
      path: { id: member.sessionId! },
      body: {
        agent: member.agent,
        parts: [{ type: "text", text: prompt }],
        noReply: false,
        tools: DISABLED_TOOLS,
      },
    })

    return await this.waitForResponse(
      member.sessionId!,
      this.config.discussionRoundTimeoutMs
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
    const startTime = Date.now()
    const pollInterval = 2000

    while (Date.now() - startTime < timeoutMs) {
      await this.sleep(pollInterval)

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

  /**
   * Sleep utility
   */
  private sleep(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms))
  }
}
