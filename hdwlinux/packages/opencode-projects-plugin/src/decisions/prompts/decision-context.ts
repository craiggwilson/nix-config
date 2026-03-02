/**
 * Decision context builder for prompt injection
 *
 * Builds context from the decision manager including pending decisions
 * and recent decided items for reference. This enables agents to understand
 * what decisions are blocking progress and what has already been decided.
 */

import type { DecisionManager, DecisionRecord, PendingDecision } from "../decision-manager.js"

/**
 * Aggregated decision context for prompt injection.
 *
 * Contains pending decisions that need resolution and recent decided
 * items for reference, enabling agents to make informed choices.
 */
export interface DecisionContext {
  /** Decisions awaiting resolution */
  pending: PendingDecision[]
  /** Most recent decisions, ordered newest first */
  recentDecisions: DecisionRecord[]
  /** Total number of decided records */
  totalDecided: number
  /** Total number of superseded records */
  totalSuperseded: number
}

/**
 * Options for building decision context.
 */
export interface BuildDecisionContextOptions {
  /** Maximum number of recent decisions to include (default: 5) */
  recentLimit?: number
}

/**
 * Builds decision context for prompt injection.
 *
 * Loads the decision index and extracts pending decisions along with
 * recent decided items, sorted by creation date (newest first).
 *
 * @param decisionManager - The decision manager to load context from
 * @param options - Optional configuration for context building
 * @returns Aggregated decision context
 */
export async function buildDecisionContext(
  decisionManager: DecisionManager,
  options?: BuildDecisionContextOptions
): Promise<DecisionContext> {
  const limit = options?.recentLimit ?? 5
  const index = await decisionManager.load()

  // Sort decisions by date (newest first)
  const sortedDecisions = [...index.decided].sort(
    (a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
  )

  return {
    pending: index.pending,
    recentDecisions: sortedDecisions.slice(0, limit),
    totalDecided: index.decided.length,
    totalSuperseded: index.superseded.length,
  }
}

/**
 * Formats decision context as markdown for prompt injection.
 *
 * Produces a structured listing of pending decisions and recent decided
 * items, suitable for inclusion in system prompts.
 *
 * @param context - The decision context to format
 * @returns Markdown-formatted context string
 */
export function formatDecisionContext(context: DecisionContext): string {
  const lines: string[] = []

  // Pending decisions (most important for agent to know)
  if (context.pending.length > 0) {
    lines.push("## Pending Decisions")
    lines.push("")

    for (const pending of context.pending) {
      lines.push(`### ${pending.question}`)

      if (pending.context) {
        lines.push(pending.context)
      }

      if (pending.blocking && pending.blocking.length > 0) {
        lines.push(`**Blocking:** ${pending.blocking.join(", ")}`)
      }

      if (pending.relatedResearch && pending.relatedResearch.length > 0) {
        lines.push(`**Related Research:** ${pending.relatedResearch.join(", ")}`)
      }

      lines.push("")
    }
  }

  // Recent decisions for reference
  if (context.recentDecisions.length > 0) {
    lines.push("## Recent Decisions")
    lines.push("")

    for (const decision of context.recentDecisions) {
      const date = decision.createdAt.split("T")[0]
      lines.push(`- **${decision.title}** (${date}): ${truncate(decision.decision, 100)}`)
    }

    lines.push("")

    if (context.totalDecided > context.recentDecisions.length) {
      lines.push(`*${context.totalDecided - context.recentDecisions.length} more decisions in log*`)
      lines.push("")
    }
  }

  return lines.join("\n").trim()
}

/**
 * Formats a compact decision summary for limited context.
 *
 * Produces a brief summary listing pending questions and decision count,
 * useful when full context would be too verbose.
 *
 * @param context - The decision context to summarize
 * @returns Compact summary string
 */
export function formatDecisionSummary(context: DecisionContext): string {
  const parts: string[] = []

  if (context.pending.length > 0) {
    const questions = context.pending.map((p) => p.question).join("; ")
    parts.push(`**Pending:** ${questions}`)
  }

  if (context.totalDecided > 0) {
    parts.push(`**Decided:** ${context.totalDecided} decisions recorded`)
  }

  if (parts.length === 0) {
    return "No decisions recorded."
  }

  return parts.join("\n")
}

/**
 * Checks if there is any decision context to inject.
 *
 * Returns true if there are pending decisions or recent decided items,
 * allowing callers to skip context injection when empty.
 *
 * @param context - The decision context to check
 * @returns True if context contains any data
 */
export function hasDecisionContext(context: DecisionContext): boolean {
  return context.pending.length > 0 || context.recentDecisions.length > 0
}

/**
 * Truncates a string to a maximum length, adding ellipsis if needed.
 *
 * @param str - The string to truncate
 * @param maxLength - Maximum length before truncation
 * @returns Truncated string with ellipsis if needed
 */
function truncate(str: string, maxLength: number): string {
  if (str.length <= maxLength) return str
  return str.slice(0, maxLength - 3) + "..."
}
