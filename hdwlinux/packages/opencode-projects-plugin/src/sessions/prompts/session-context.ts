/**
 * Session context builder for prompt injection
 *
 * Builds context from session history including recent sessions,
 * open questions, pending decisions, and what's next. This context
 * provides continuity across conversations by surfacing accumulated
 * state and recent work.
 */

import type { SessionManager, SessionIndex, SessionSummary } from "../session-manager.js"

/**
 * Aggregated session context for prompt injection.
 *
 * Contains recent session summaries and accumulated state that persists
 * across sessions, enabling agents to quickly orient themselves.
 */
export interface SessionContext {
  /** Most recent sessions, ordered newest first */
  recentSessions: SessionSummary[]
  /** Accumulated open questions across all sessions */
  openQuestions: string[]
  /** Decisions awaiting resolution */
  pendingDecisions: string[]
  /** Planned next steps */
  whatsNext: string[]
}

/**
 * Options for building session context.
 */
export interface BuildSessionContextOptions {
  /** Maximum number of recent sessions to include (default: 3) */
  recentLimit?: number
}

/**
 * Builds session context for prompt injection.
 *
 * Loads the session index and extracts recent sessions along with
 * accumulated state (open questions, pending decisions, next steps).
 *
 * @param sessionManager - The session manager to load context from
 * @param options - Optional configuration for context building
 * @returns Aggregated session context
 */
export async function buildSessionContext(
  sessionManager: SessionManager,
  options?: BuildSessionContextOptions
): Promise<SessionContext> {
  const limit = options?.recentLimit ?? 3
  const index = await sessionManager.load()

  return {
    recentSessions: sessionManager.getRecentSessions(limit),
    openQuestions: index.openQuestions,
    pendingDecisions: index.pendingDecisions,
    whatsNext: index.whatsNext,
  }
}

/**
 * Formats session context as markdown for prompt injection.
 *
 * Produces a human-readable summary of recent sessions and accumulated
 * state, suitable for inclusion in system prompts.
 *
 * @param context - The session context to format
 * @returns Markdown-formatted context string
 */
export function formatSessionContext(context: SessionContext): string {
  const lines: string[] = []

  if (context.recentSessions.length > 0) {
    lines.push("## Recent Sessions")
    lines.push("")

    for (const session of context.recentSessions) {
      lines.push(`### ${session.date}`)
      lines.push(session.summary)
      lines.push("")

      if (session.keyPoints.length > 0) {
        lines.push("**Key Points:**")
        for (const point of session.keyPoints) {
          lines.push(`- ${point}`)
        }
        lines.push("")
      }
    }
  }

  if (context.openQuestions.length > 0) {
    lines.push("## Open Questions")
    for (const question of context.openQuestions) {
      lines.push(`- ${question}`)
    }
    lines.push("")
  }

  if (context.pendingDecisions.length > 0) {
    lines.push("## Pending Decisions")
    for (const decision of context.pendingDecisions) {
      lines.push(`- ${decision}`)
    }
    lines.push("")
  }

  if (context.whatsNext.length > 0) {
    lines.push("## What's Next")
    for (const next of context.whatsNext) {
      lines.push(`- ${next}`)
    }
    lines.push("")
  }

  return lines.join("\n").trim()
}

/**
 * Checks if there is any session context to inject.
 *
 * Returns true if there are recent sessions or any accumulated state,
 * allowing callers to skip context injection when empty.
 *
 * @param context - The session context to check
 * @returns True if context contains any data
 */
export function hasSessionContext(context: SessionContext): boolean {
  return (
    context.recentSessions.length > 0 ||
    context.openQuestions.length > 0 ||
    context.pendingDecisions.length > 0 ||
    context.whatsNext.length > 0
  )
}
