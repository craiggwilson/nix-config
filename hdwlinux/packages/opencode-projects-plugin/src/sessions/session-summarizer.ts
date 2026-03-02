/**
 * Session Summarizer
 *
 * Uses the small model to generate structured summaries from
 * conversation content. Extracts key points, open questions,
 * decisions, and next steps.
 */

import { z } from "zod"

import { promptSmallModel } from "../agents/index.js"
import type { Logger, OpencodeClient } from "../utils/opencode-sdk/index.js"
import { buildSessionSummaryPrompt } from "../utils/prompts/index.js"
import type { Result } from "../utils/result/index.js"

/**
 * Structured session summary from small model.
 */
export interface SessionSummaryResult {
  /** 2-3 sentence summary of the session */
  summary: string
  /** 3-5 key accomplishments or topics */
  keyPoints: string[]
  /** Questions raised but not resolved */
  openQuestionsAdded: string[]
  /** Explicit decisions made during the session */
  decisionsMade: string[]
  /** Concrete next steps identified */
  whatsNext: string[]
}

/**
 * Options for summarizing a session.
 */
export interface SummarizeSessionOptions {
  /** The conversation content to summarize */
  conversationContent: string
  /** Project name for context */
  projectName?: string
  /** Current planning phase if applicable */
  planningPhase?: string
  /** Timeout in milliseconds (default: 30000) */
  timeoutMs?: number
}

/**
 * Zod schema for validating small model response.
 */
const SessionSummarySchema = z.object({
  summary: z.string().max(500),
  keyPoints: z.array(z.string().max(200)).min(1).max(10),
  openQuestionsAdded: z.array(z.string().max(300)).max(10),
  decisionsMade: z.array(z.string().max(300)).max(10),
  whatsNext: z.array(z.string().max(200)).max(5),
})

/**
 * Summarize a session using the small model.
 *
 * Takes conversation content and generates a structured summary
 * including key points, open questions, decisions, and next steps.
 *
 * Falls back to a basic summary if the small model is unavailable.
 *
 * @param client - OpenCode client for small model queries
 * @param log - Logger for debugging
 * @param options - Summarization options
 * @returns Result with structured summary or error
 */
export async function summarizeSession(
  client: OpencodeClient,
  log: Logger,
  options: SummarizeSessionOptions
): Promise<Result<SessionSummaryResult>> {
  const { conversationContent, projectName, planningPhase, timeoutMs = 30000 } = options

  // Truncate content if too long (keep last ~10k chars for recency)
  const maxContentLength = 10000
  const truncatedContent =
    conversationContent.length > maxContentLength
      ? "...[truncated]...\n" + conversationContent.slice(-maxContentLength)
      : conversationContent

  const prompt = buildSessionSummaryPrompt({
    conversationContent: truncatedContent,
    projectName,
    planningPhase,
  })

  await log.debug("Summarizing session with small model")

  const result = await promptSmallModel(client, log, {
    prompt,
    timeoutMs,
    sessionTitle: "Session Summary",
    schema: SessionSummarySchema,
  })

  if (!result.ok) {
    await log.warn(`Small model summarization failed: ${result.error}`)
    return {
      ok: true,
      value: generateFallbackSummary(conversationContent),
    }
  }

  return { ok: true, value: result.value }
}

/**
 * Generate a basic fallback summary when small model is unavailable.
 *
 * Extracts basic information from the conversation content using
 * simple heuristics.
 */
function generateFallbackSummary(content: string): SessionSummaryResult {
  // Count approximate message exchanges
  const messageCount = (content.match(/^(Human|Assistant|User):/gm) || []).length

  // Extract any lines that look like questions
  const questionLines = content
    .split("\n")
    .filter((line) => line.trim().endsWith("?"))
    .slice(0, 3)
    .map((line) => line.trim().slice(0, 200))

  const summary =
    `Session with approximately ${Math.ceil(messageCount / 2)} exchanges. ` +
    `Content length: ${content.length} characters.`

  return {
    summary,
    keyPoints: ["Session content captured", "Manual review recommended"],
    openQuestionsAdded: questionLines,
    decisionsMade: [],
    whatsNext: ["Review session content for key decisions"],
  }
}
