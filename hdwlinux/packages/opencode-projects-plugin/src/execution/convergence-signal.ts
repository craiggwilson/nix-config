/**
 * Convergence signal utilities for parsing and validating agent responses.
 *
 * Centralizes signal extraction logic used by both the strategy and assessor
 * to avoid duplication and ensure consistent parsing behavior.
 */

/**
 * Explicit convergence signal emitted by an agent at the end of their response.
 *
 * Agents are instructed to place exactly one of these on its own line as the
 * final non-empty line of their response.
 */
export type ConvergenceSignal = "CONVERGED" | "STUCK" | "CONTINUE"

const VALID_SIGNALS: readonly ConvergenceSignal[] = ["CONVERGED", "STUCK", "CONTINUE"]

/**
 * Extract the convergence signal from an agent response.
 *
 * Looks for a valid signal on the last non-empty line of the response.
 * Returns undefined if no valid signal is found.
 *
 * @param response - The agent response text
 * @returns The signal if found on the last non-empty line, undefined otherwise
 */
export function extractSignal(response: string): ConvergenceSignal | undefined {
  const lines = response.split("\n").filter((line) => line.trim())
  if (lines.length === 0) return undefined

  const lastLine = lines[lines.length - 1].trim()
  return VALID_SIGNALS.find((signal) => signal === lastLine)
}

/**
 * Check if a response contains a valid convergence signal on its own line.
 *
 * @param response - The agent response text
 * @returns True if a valid signal is present on the last non-empty line
 */
export function hasValidSignal(response: string): boolean {
  return extractSignal(response) !== undefined
}

/**
 * Ensure a response ends with a valid convergence signal on its own line.
 *
 * If the signal is already present and correctly placed, returns the response
 * unchanged. If missing, appends the provided default signal.
 *
 * @param response - The agent response text
 * @param defaultSignal - Signal to append if missing (default: CONTINUE)
 * @returns Response with valid signal on its own line
 */
export function ensureSignal(
  response: string,
  defaultSignal: ConvergenceSignal = "CONTINUE"
): string {
  if (hasValidSignal(response)) {
    return response
  }
  return `${response.trim()}\n${defaultSignal}`
}

/**
 * Parse convergence signals from multiple agent responses.
 *
 * @param responses - Agent responses keyed by agent name
 * @returns Map of agent name to signal (undefined if no valid signal found)
 */
export function parseAgentSignals(
  responses: Record<string, string>
): Record<string, ConvergenceSignal | undefined> {
  const signals: Record<string, ConvergenceSignal | undefined> = {}
  for (const [agentName, response] of Object.entries(responses)) {
    signals[agentName] = extractSignal(response)
  }
  return signals
}

/**
 * Count convergence signals by type across all agents.
 *
 * @param signals - Map of agent name to signal
 * @returns Count of each signal type, including UNKNOWN for missing signals
 */
export function countSignals(
  signals: Record<string, ConvergenceSignal | undefined>
): Record<ConvergenceSignal | "UNKNOWN", number> {
  const counts: Record<ConvergenceSignal | "UNKNOWN", number> = {
    CONVERGED: 0,
    STUCK: 0,
    CONTINUE: 0,
    UNKNOWN: 0,
  }
  for (const signal of Object.values(signals)) {
    if (signal !== undefined) {
      counts[signal]++
    } else {
      counts.UNKNOWN++
    }
  }
  return counts
}
