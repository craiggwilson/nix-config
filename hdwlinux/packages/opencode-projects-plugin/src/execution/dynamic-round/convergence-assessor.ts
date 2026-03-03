/**
 * ConvergenceAssessor - Small model judge for team convergence state
 *
 * Parses agent responses for convergence signals and determines
 * whether the team has reached consensus, is stuck, or should continue.
 */

import { z } from "zod"
import type { Logger, OpencodeClient } from "../../utils/opencode-sdk/index.js"
import type { DiscussionRound } from "../team-manager.js"
import type { Result } from "../../utils/result/index.js"
import { promptSmallModel } from "../../agents/small-model.js"

/**
 * Signal emitted by an individual agent indicating their convergence state.
 *
 * - CONVERGED: Agent agrees with the current direction and has no blocking concerns
 * - STUCK: Agent has unresolved concerns that are not being addressed
 * - CONTINUE: Agent has remaining points to discuss but is making progress
 */
export type AgentConvergenceSignal = "CONVERGED" | "STUCK" | "CONTINUE"

/**
 * Overall team convergence state derived from individual agent signals.
 *
 * - converged: All agents have signaled CONVERGED; discussion can stop
 * - stuck: At least one agent is STUCK and no progress is being made; arbiter needed
 * - continue: Discussion is progressing; run another round
 */
export type TeamConvergenceState = "converged" | "stuck" | "continue"

/**
 * Assessment result from the convergence assessor.
 */
export interface ConvergenceAssessment {
  /** Overall team state */
  state: TeamConvergenceState
  /** Per-agent signals parsed from the round */
  agentSignals: Record<string, AgentConvergenceSignal>
  /** Human-readable summary of the assessment */
  summary: string
}

/**
 * Configuration for ConvergenceAssessor.
 */
export interface ConvergenceAssessorConfig {
  /** Timeout for small model queries (milliseconds) */
  smallModelTimeoutMs: number
}

const AssessmentResponseSchema = z.object({
  agentSignals: z.record(z.string(), z.enum(["CONVERGED", "STUCK", "CONTINUE"])),
  state: z.enum(["converged", "stuck", "continue"]),
  summary: z.string(),
})

/**
 * Uses the small model to assess team convergence from discussion round responses.
 *
 * Falls back to a heuristic assessment when the small model is unavailable,
 * treating all agents as CONTINUE to avoid premature termination.
 */
export class ConvergenceAssessor {
  private log: Logger
  private client: OpencodeClient
  private config: ConvergenceAssessorConfig

  /**
   * @param log - Logger for diagnostic output
   * @param client - OpenCode client for small model access
   * @param config - Configuration options
   */
  constructor(
    log: Logger,
    client: OpencodeClient,
    config: ConvergenceAssessorConfig
  ) {
    this.log = log
    this.client = client
    this.config = config
  }

  /**
   * Assess team convergence from the latest discussion round.
   *
   * Sends agent responses to the small model for structured analysis.
   * Falls back to heuristic (all CONTINUE) if small model is unavailable.
   *
   * @param round - The completed discussion round to assess
   * @param roundNumber - Current round number for context
   * @param maxRounds - Hard cap for context
   * @returns Convergence assessment with team state and per-agent signals
   */
  async assess(
    round: DiscussionRound,
    roundNumber: number,
    maxRounds: number
  ): Promise<ConvergenceAssessment> {
    const prompt = buildAssessmentPrompt(round, roundNumber, maxRounds)

    const result = await promptSmallModel(this.client, this.log, {
      prompt,
      timeoutMs: this.config.smallModelTimeoutMs,
      sessionTitle: "Convergence Assessment",
      schema: AssessmentResponseSchema,
    })

    if (result.ok) {
      await this.log.debug(
        `Convergence assessment: ${result.value.state} - ${result.value.summary}`
      )
      return result.value
    }

    await this.log.warn(
      `Convergence assessment failed (${result.error}), defaulting to continue`
    )
    return buildFallbackAssessment(round)
  }
}

/**
 * Build the prompt for the small model convergence assessment.
 */
function buildAssessmentPrompt(
  round: DiscussionRound,
  roundNumber: number,
  maxRounds: number
): string {
  const agentResponsesText = Object.entries(round.responses)
    .map(([agent, response]) => `### ${agent}\n${response}`)
    .join("\n\n")

  return `You are assessing whether a team of AI agents has reached convergence in their discussion.

## Discussion Round ${roundNumber}/${maxRounds}

## Agent Responses

${agentResponsesText}

## Task

Analyze each agent's response and determine their convergence signal:
- CONVERGED: The agent explicitly agrees, has no remaining concerns, or indicates they are satisfied with the direction
- STUCK: The agent has unresolved concerns that are being ignored or not addressed by others
- CONTINUE: The agent has remaining points but is making progress toward resolution

Then determine the overall team state:
- "converged": ALL agents are CONVERGED
- "stuck": At least one agent is STUCK and the discussion is not making progress
- "continue": Discussion is progressing; run another round

Respond with JSON only:
{
  "agentSignals": {
    "<agent-name>": "CONVERGED" | "STUCK" | "CONTINUE"
  },
  "state": "converged" | "stuck" | "continue",
  "summary": "<brief explanation of the assessment>"
}`
}

/**
 * Build a fallback assessment when the small model is unavailable.
 *
 * Defaults all agents to CONTINUE to avoid premature termination or
 * incorrect stuck detection.
 */
function buildFallbackAssessment(round: DiscussionRound): ConvergenceAssessment {
  const agentSignals: Record<string, AgentConvergenceSignal> = {}
  for (const agent of Object.keys(round.responses)) {
    agentSignals[agent] = "CONTINUE"
  }
  return {
    state: "continue",
    agentSignals,
    summary: "Small model unavailable; defaulting to continue",
  }
}
