/**
 * DynamicRoundDiscussionStrategy - Adaptive discussion that stops when agents agree
 *
 * Runs discussion rounds until the team converges, gets stuck (triggering arbiter),
 * or hits the hard cap on rounds.
 */

import type { Logger, OpencodeClient } from "../../utils/opencode-sdk/index.js"
import type { Team, TeamMember, DiscussionRound } from "../team-manager.js"
import type { Clock } from "../../utils/clock/index.js"
import type { TeamDiscussionStrategy } from "../discussion-strategy.js"
import { systemClock } from "../../utils/clock/index.js"
import { PermissionManager } from "../permission-manager.js"
import { ConvergenceAssessor } from "./convergence-assessor.js"
import { extractSignal, parseAgentSignals, countSignals, ensureSignal } from "../convergence-signal.js"
import { buildDiscussionContext } from "../discussion-context.js"
import { waitForResponse } from "../response-poller.js"

/**
 * Configuration for DynamicRoundDiscussionStrategy.
 */
export interface DynamicRoundStrategyConfig {
  /** Hard cap on discussion rounds regardless of convergence state */
  maxRounds: number
  /** Minimum rounds before convergence assessment fires, even if all agents signal CONVERGED */
  minRounds?: number
  /** Maximum time to wait for each agent's response per round (milliseconds) */
  roundTimeoutMs: number
  /** Timeout for small model convergence assessment queries (milliseconds) */
  smallModelTimeoutMs: number
  /** Maximum response size in characters before truncation (0 or omitted = no limit) */
  maxResponseChars?: number
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
  readonly memberLaunchOrdering = "sequential" as const

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

    const minRounds = this.config.minRounds ?? 2
    const startTime = this.clock.now()

    await this.log.info(
      `Team ${team.id}: starting convergence discussion (min ${minRounds}, max ${this.config.maxRounds} rounds)`
    )

    const discussionHistory: DiscussionRound[] = [...team.discussionHistory]
    let round = 1
    let convergenceAssessmentCount = 0
    let arbiterInvocations = 0
    let mediatorInvocations = 0

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
          const normalized = await this.normalizeAgentResponse(response, member.agent, team.id)
          const truncated = await this.truncateResponseIfNeeded(normalized, member.agent, team.id)
          roundResponses[member.agent] = truncated
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

      await this.logRoundMetrics(round, roundResponses, team.id)

      const completedRound: DiscussionRound = { round, responses: roundResponses }
      discussionHistory.push(completedRound)

      if (onProgress) {
        await onProgress(discussionHistory)
      }

      // Skip convergence assessment until minRounds have completed to ensure
      // agents have had a meaningful exchange before early termination is possible.
      if (round < minRounds) {
        await this.log.info(
          `Team ${team.id}: round ${round} complete (minRounds=${minRounds}, skipping convergence assessment)`
        )
        round++
        continue
      }

      // Assess convergence after collecting all responses
      convergenceAssessmentCount++
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
        arbiterInvocations++
        const arbiterRound = await this.invokeArbiter(team, round, discussionHistory)
        if (arbiterRound) {
          discussionHistory.push(arbiterRound)
          if (onProgress) {
            await onProgress(discussionHistory)
          }
        } else {
          await this.log.info(
            `Team ${team.id}: arbiter failed, invoking mediator as last resort`
          )
          mediatorInvocations++
          const mediatorRound = await this.invokeMediator(team, round, discussionHistory)
          if (mediatorRound) {
            discussionHistory.push(mediatorRound)
            if (onProgress) {
              await onProgress(discussionHistory)
            }
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

    const durationMs = this.clock.now() - startTime
    await this.log.info(
      `Team ${team.id}: convergence discussion complete totalRounds=${round <= this.config.maxRounds ? round : this.config.maxRounds} convergenceAssessments=${convergenceAssessmentCount} arbiterInvocations=${arbiterInvocations} mediatorInvocations=${mediatorInvocations} durationMs=${durationMs}`
    )
    return discussionHistory
  }

  /**
   * Send a convergence-aware discussion prompt to a member.
   *
   * The prompt instructs the agent to include an explicit convergence signal
   * (CONVERGED / STUCK / CONTINUE) so the assessor can parse team state.
   * On timeout, returns a default CONTINUE response rather than throwing.
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

    try {
      return await waitForResponse(this.client, member.sessionId!, this.config.roundTimeoutMs, this.clock, this.log)
    } catch (error) {
      // Only degrade gracefully on timeout — other errors (network, auth) should propagate
      if (error instanceof Error && error.message.startsWith("Timeout waiting for response")) {
        await this.log.warn(
          `Team ${team.id}: ${member.agent} timed out in round ${round}, defaulting to CONTINUE`
        )
        return "CONTINUE"
      }
      throw error
    }
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

      const response = await waitForResponse(this.client, primary.sessionId, this.config.roundTimeoutMs, this.clock, this.log)
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
   * Invoke a neutral mediator in a fresh session to break a deadlock after the arbiter fails.
   *
   * Unlike the arbiter (which re-uses the primary's session), the mediator is a fresh
   * session with no prior context bias. It reviews the full discussion history and
   * proposes a concrete path forward without making binding decisions.
   */
  private async invokeMediator(
    team: Team,
    stuckAtRound: number,
    discussionHistory: DiscussionRound[]
  ): Promise<DiscussionRound | null> {
    const primary = team.members.find((m) => m.role === "primary")
    const mediatorAgent = primary?.agent

    try {
      const sessionResult = await this.client.session.create({
        body: { title: `Mediator: ${team.issueId}` },
      })
      const sessionId = sessionResult.data?.id
      if (!sessionId) {
        await this.log.warn(`Team ${team.id}: mediator session creation returned no ID`)
        return null
      }

      const prompt = buildMediatorPrompt(team.issueId, stuckAtRound, discussionHistory)
      const toolPermissions = PermissionManager.resolvePermissions("mediator")

      await this.client.session.prompt({
        path: { id: sessionId },
        body: {
          agent: mediatorAgent,
          parts: [{ type: "text", text: prompt }],
          noReply: false,
          tools: toolPermissions,
        },
      })

      const response = await waitForResponse(this.client, sessionId, this.config.roundTimeoutMs, this.clock, this.log)

      // Clean up the temporary mediator session
      await this.client.session.delete({ path: { id: sessionId } }).catch(() => {
        // Non-fatal: session cleanup failure should not block result
      })

      return {
        round: stuckAtRound + 1,
        responses: { "mediator": response },
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error)
      await this.log.warn(`Team ${team.id}: mediator invocation failed: ${errorMsg}`)
      return null
    }
  }

  /**
   * Validate and normalize an agent's response to ensure it contains
   * a valid convergence signal on its own line.
   *
   * If the signal is missing, appends CONTINUE and logs a warning.
   * If the signal appears mid-response (not on its own line), normalizes
   * to CONTINUE since the intent is ambiguous.
   *
   * @param response - The raw agent response
   * @param agentName - Agent name for logging context
   * @param teamId - Team ID for logging context
   * @returns Normalized response with valid signal on its own line
   */
  private async normalizeAgentResponse(
    response: string,
    agentName: string,
    teamId: string
  ): Promise<string> {
    if (extractSignal(response) !== undefined) {
      return response
    }

    // Signal appears somewhere in the response but not on its own line
    const VALID_SIGNALS = ["CONVERGED", "STUCK", "CONTINUE"]
    const hasEmbeddedSignal = VALID_SIGNALS.some((s) => response.includes(s))
    if (hasEmbeddedSignal) {
      await this.log.warn(
        `Team ${teamId}: ${agentName} convergence signal not on own line, normalizing to CONTINUE`
      )
    } else {
      await this.log.warn(
        `Team ${teamId}: ${agentName} missing convergence signal, defaulting to CONTINUE`
      )
    }

    return ensureSignal(response, "CONTINUE")
  }

  /**
   * Truncate an agent response if it exceeds the configured size threshold,
   * while preserving the convergence signal on the last line.
   *
   * No-op when maxResponseChars is not configured or response is within limit.
   *
   * @param response - The agent response (should already be normalized)
   * @param agentName - Agent name for logging context
   * @param teamId - Team ID for logging context
   * @returns Truncated response with signal preserved, or original if within limit
   */
  private async truncateResponseIfNeeded(
    response: string,
    agentName: string,
    teamId: string
  ): Promise<string> {
    const maxChars = this.config.maxResponseChars
    if (!maxChars || maxChars <= 0 || response.length <= maxChars) {
      return response
    }

    const lines = response.split("\n")
    const lastLine = lines[lines.length - 1].trim()
    const VALID_SIGNALS = ["CONVERGED", "STUCK", "CONTINUE"]
    const hasSignalOnLastLine = VALID_SIGNALS.includes(lastLine)

    const body = hasSignalOnLastLine ? lines.slice(0, -1).join("\n") : response
    const signal = hasSignalOnLastLine ? lastLine : "CONTINUE"
    // Reserve space for the truncation marker and signal
    const truncatedBody = body.substring(0, maxChars - 50)

    await this.log.info(
      `Team ${teamId}: ${agentName} response truncated from ${response.length} to ${truncatedBody.length} chars`
    )

    return `${truncatedBody}\n[... truncated ...]\n${signal}`
  }

  /**
   * Log convergence signal metrics for a completed discussion round.
   *
   * Parses signals from all agent responses and logs a summary with
   * per-agent breakdown for observability.
   *
   * @param round - Round number
   * @param responses - Agent responses keyed by agent name
   * @param teamId - Team ID for logging context
   */
  private async logRoundMetrics(
    round: number,
    responses: Record<string, string>,
    teamId: string
  ): Promise<void> {
    const signals = parseAgentSignals(responses)
    const counts = countSignals(signals)
    const total = Object.keys(responses).length
    const convergenceRate = total > 0 ? ((counts.CONVERGED / total) * 100).toFixed(1) : "0.0"

    await this.log.info(
      `Team ${teamId}: round ${round} metrics converged=${counts.CONVERGED}/${total} (${convergenceRate}%) stuck=${counts.STUCK} continue=${counts.CONTINUE} unknown=${counts.UNKNOWN}`
    )

    const agentSignalStr = Object.entries(signals)
      .map(([agent, signal]) => `${agent}=${signal ?? "UNKNOWN"}`)
      .join(" ")
    await this.log.debug(
      `Team ${teamId}: round ${round} agent signals ${agentSignalStr}`
    )
  }

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

**CONVERGED** - You have no remaining blockers. For the primary, this means you are satisfied with the outcome and believe the work is sound. For the devil's advocate, this means you have exhausted your objections and cannot find further reason to prevent convergence — not that you agree, but that you have no remaining blockers.
**STUCK** - There is a blocker the primary has not addressed. Use this to veto convergence until the issue is resolved.
**CONTINUE** - You have remaining points but are making progress

Note: The discussion ends only when BOTH the primary AND the devil's advocate signal CONVERGED. Do not signal CONVERGED out of politeness or to end the discussion — only signal it when you have genuinely run out of objections or concerns.

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
  const historyText = buildHistoryText(discussionHistory)

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

/**
 * Build the mediator prompt for a neutral agent to propose a path forward.
 *
 * The mediator is a last resort invoked in a fresh session when the arbiter
 * fails to break a deadlock. Unlike the arbiter, the mediator does not make
 * binding decisions — it identifies the root of the disagreement and proposes
 * a concrete path forward that the team can act on.
 */
export function buildMediatorPrompt(
  issueId: string,
  stuckAtRound: number,
  discussionHistory: DiscussionRound[]
): string {
  const historyText = buildHistoryText(discussionHistory)

  return `# Mediation Required

## Issue: ${issueId}

A team of agents has been unable to resolve a disagreement after ${stuckAtRound} discussion round(s). The primary agent's arbiter attempt also failed to break the deadlock. You are being brought in as a neutral mediator.

## Full Discussion History

${historyText}

## Your Role as Mediator

You are a neutral third party with no prior involvement in this discussion. Your job is not to pick a winner, but to unblock the team. Review the full history and:

1. Identify the root cause of the disagreement (what is the team actually stuck on?)
2. Separate factual disputes from preference disputes
3. Propose a concrete, actionable path forward that addresses the core concern
4. Explain why your proposed path is reasonable given the constraints

Be specific and practical. The team needs a clear next step, not a summary of the problem.`
}

/**
 * Format discussion history rounds into a readable text block.
 */
function buildHistoryText(discussionHistory: DiscussionRound[]): string {
  return discussionHistory
    .map((r) => {
      const responses = Object.entries(r.responses)
        .map(([agent, response]) => `**${agent}:**\n${response}`)
        .join("\n\n")
      return `### Round ${r.round}\n\n${responses}`
    })
    .join("\n\n")
}
