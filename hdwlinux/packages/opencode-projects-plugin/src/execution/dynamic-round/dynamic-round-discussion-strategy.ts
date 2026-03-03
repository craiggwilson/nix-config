/**
 * DynamicRoundDiscussionStrategy - Adaptive discussion that stops when agents agree
 *
 * Runs discussion rounds until the team converges, gets stuck (triggering arbiter),
 * or hits the hard cap on rounds.
 */

import type { Logger, OpencodeClient, MessageItem, Part } from "../../utils/opencode-sdk/index.js"
import type { Team, TeamMember, DiscussionRound } from "../team-manager.js"
import type { Clock } from "../../utils/clock/index.js"
import type { TeamDiscussionStrategy } from "../discussion-strategy.js"
import { systemClock } from "../../utils/clock/index.js"
import { PermissionManager } from "../permission-manager.js"
import { ConvergenceAssessor } from "./convergence-assessor.js"

/**
 * Configuration for DynamicRoundDiscussionStrategy.
 */
export interface DynamicRoundStrategyConfig {
  /** Hard cap on discussion rounds regardless of convergence state */
  maxRounds: number
  /** Maximum time to wait for each agent's response per round (milliseconds) */
  roundTimeoutMs: number
  /** Timeout for small model convergence assessment queries (milliseconds) */
  smallModelTimeoutMs: number
  /** Clock for timing operations (optional, uses system clock) */
  clock?: Clock
}

/**
 * Orchestrates adaptive team discussions that terminate on convergence.
 *
 * Unlike FixedRoundDiscussionStrategy, this strategy:
 * 1. Assesses convergence after each round using a small model judge
 * 2. Stops early when all agents signal agreement
 * 3. Invokes an arbiter agent when the team is stuck
 * 4. Always terminates at maxRounds regardless of state
 *
 * The convergence prompt instructs agents to include explicit signals
 * (CONVERGED / STUCK / CONTINUE) in their responses so the assessor
 * can parse team state without ambiguity.
 */
export class DynamicRoundDiscussionStrategy implements TeamDiscussionStrategy {
  readonly type = "dynamicRound" as const

  private log: Logger
  private client: OpencodeClient
  private config: DynamicRoundStrategyConfig
  private clock: Clock
  private assessor: ConvergenceAssessor

  /**
   * @param log - Logger for diagnostic output
   * @param client - OpenCode client for session management
   * @param config - Configuration options
   */
  constructor(
    log: Logger,
    client: OpencodeClient,
    config: DynamicRoundStrategyConfig
  ) {
    this.log = log
    this.client = client
    this.config = config
    this.clock = config.clock ?? systemClock
    this.assessor = new ConvergenceAssessor(log, client, {
      smallModelTimeoutMs: config.smallModelTimeoutMs,
    })
  }

  /**
   * Run convergence-aware discussion rounds until the team agrees or hits the cap.
   *
   * Each round:
   * 1. Sends convergence-aware prompts to all members
   * 2. Assesses team state via small model judge
   * 3. Stops if converged, invokes arbiter if stuck, continues otherwise
   *
   * @param team - The team to run discussion for
   * @param onProgress - Optional callback after each round completes
   * @returns Complete discussion history including all rounds
   */
  async onAllMembersCompleted(
    team: Team,
    onProgress?: (history: DiscussionRound[]) => Promise<void>
  ): Promise<DiscussionRound[]> {
    if (team.members.length <= 1) {
      return []
    }

    await this.log.info(
      `Team ${team.id}: starting convergence discussion (max ${this.config.maxRounds} rounds)`
    )

    const discussionHistory: DiscussionRound[] = [...team.discussionHistory]
    let round = 1

    while (round <= this.config.maxRounds) {
      await this.log.info(
        `Team ${team.id}: convergence round ${round}/${this.config.maxRounds}`
      )

      const context = buildDiscussionContext(team, round, discussionHistory)
      const roundResponses: Record<string, string> = {}

      for (const member of team.members) {
        if (!member.sessionId) {
          await this.log.warn(
            `Team ${team.id}: ${member.agent} has no session for discussion`
          )
          roundResponses[member.agent] = "(no session)"
          continue
        }

        try {
          const response = await this.sendConvergencePrompt(
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

      const completedRound: DiscussionRound = { round, responses: roundResponses }
      discussionHistory.push(completedRound)

      if (onProgress) {
        await onProgress(discussionHistory)
      }

      // Assess convergence after collecting all responses
      const assessment = await this.assessor.assess(
        completedRound,
        round,
        this.config.maxRounds
      )

      await this.log.info(
        `Team ${team.id}: round ${round} assessment: ${assessment.state} - ${assessment.summary}`
      )

      if (assessment.state === "converged") {
        await this.log.info(`Team ${team.id}: team converged after ${round} round(s)`)
        break
      }

      if (assessment.state === "stuck") {
        await this.log.info(
          `Team ${team.id}: team stuck after ${round} round(s), invoking arbiter`
        )
        const arbiterRound = await this.invokeArbiter(team, round, discussionHistory)
        if (arbiterRound) {
          discussionHistory.push(arbiterRound)
          if (onProgress) {
            await onProgress(discussionHistory)
          }
        }
        break
      }

      round++
    }

    if (round > this.config.maxRounds) {
      await this.log.info(
        `Team ${team.id}: reached max rounds (${this.config.maxRounds}), stopping`
      )
    }

    await this.log.info(`Team ${team.id}: convergence discussion complete`)
    return discussionHistory
  }

  /**
   * Send a convergence-aware discussion prompt to a member.
   *
   * The prompt instructs the agent to include an explicit convergence signal
   * (CONVERGED / STUCK / CONTINUE) so the assessor can parse team state.
   */
  private async sendConvergencePrompt(
    team: Team,
    member: TeamMember,
    round: number,
    context: string
  ): Promise<string> {
    const prompt = buildConvergencePrompt(team.issueId, member.agent, round, this.config.maxRounds, context)
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

    return await this.waitForResponse(member.sessionId!, this.config.roundTimeoutMs)
  }

  /**
   * Invoke the primary agent as arbiter to break a deadlock.
   *
   * The arbiter receives the full discussion history and is asked to make
   * a final binding decision to unblock the team.
   */
  private async invokeArbiter(
    team: Team,
    stuckAtRound: number,
    discussionHistory: DiscussionRound[]
  ): Promise<DiscussionRound | null> {
    const primary = team.members.find((m) => m.role === "primary")
    if (!primary?.sessionId) {
      await this.log.warn(`Team ${team.id}: no primary agent available for arbiter`)
      return null
    }

    const prompt = buildArbiterPrompt(team.issueId, stuckAtRound, discussionHistory)
    const toolPermissions = PermissionManager.resolvePermissions(primary.role)

    try {
      await this.client.session.prompt({
        path: { id: primary.sessionId },
        body: {
          agent: primary.agent,
          parts: [{ type: "text", text: prompt }],
          noReply: false,
          tools: toolPermissions,
        },
      })

      const response = await this.waitForResponse(primary.sessionId, this.config.roundTimeoutMs)
      return {
        round: stuckAtRound + 1,
        responses: { [`${primary.agent} (arbiter)`]: response },
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error)
      await this.log.warn(`Team ${team.id}: arbiter invocation failed: ${errorMsg}`)
      return null
    }
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

/**
 * Build context for a convergence discussion round.
 *
 * Assembles context from primary agent's work, other agents' findings,
 * and all previous discussion rounds.
 */
export function buildDiscussionContext(
  team: Team,
  round: number,
  discussionHistory: DiscussionRound[]
): string {
  const lines: string[] = []

  const primary = team.members.find((m) => m.role === "primary")
  if (primary && team.results[primary.agent]) {
    lines.push("## Primary Agent's Implementation")
    lines.push("")
    lines.push(team.results[primary.agent].result)
    lines.push("")
  }

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
 * Build the convergence-aware discussion prompt for an agent.
 *
 * Instructs the agent to include an explicit convergence signal so the
 * assessor can determine team state without ambiguity.
 */
export function buildConvergencePrompt(
  issueId: string,
  agentName: string,
  round: number,
  maxRounds: number,
  context: string
): string {
  return `# Discussion Round ${round}/${maxRounds}

## Issue: ${issueId}

${context}

## Your Task

As ${agentName}, provide your updated analysis considering:
1. New insights from other agents
2. Remaining concerns or disagreements
3. Points of agreement
4. Final recommendations

## Convergence Signal

End your response with exactly one of these signals on its own line:

**CONVERGED** - You agree with the current direction and have no blocking concerns
**STUCK** - You have unresolved concerns that are not being addressed by others
**CONTINUE** - You have remaining points but are making progress

Keep response focused and actionable.`
}

/**
 * Build the arbiter prompt for the primary agent to break a deadlock.
 *
 * The arbiter is given full discussion history and asked to make a final
 * binding decision that all agents must accept.
 */
export function buildArbiterPrompt(
  issueId: string,
  stuckAtRound: number,
  discussionHistory: DiscussionRound[]
): string {
  const historyText = discussionHistory
    .map((r) => {
      const responses = Object.entries(r.responses)
        .map(([agent, response]) => `**${agent}:**\n${response}`)
        .join("\n\n")
      return `### Round ${r.round}\n\n${responses}`
    })
    .join("\n\n")

  return `# Arbiter Decision Required

## Issue: ${issueId}

The team has reached a deadlock after ${stuckAtRound} discussion round(s) and cannot converge on their own.

## Full Discussion History

${historyText}

## Your Role as Arbiter

You are the primary agent and final decision-maker. Review the full discussion and:

1. Identify the core points of disagreement
2. Evaluate the merits of each position
3. Make a final binding decision that resolves the deadlock
4. Explain your reasoning clearly

Your decision is final. All team members will accept it. Be decisive and specific.`
}
