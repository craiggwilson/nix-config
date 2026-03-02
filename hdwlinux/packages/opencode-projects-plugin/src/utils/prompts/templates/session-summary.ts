/**
 * Session Summary Prompt Template
 *
 * Template for generating session summaries using the small model.
 * Extracts key information from conversation content.
 */

/**
 * Input data for session summary generation.
 */
export interface SessionSummaryInput {
  /** The conversation content to summarize */
  conversationContent: string
  /** Project name for context */
  projectName?: string
  /** Current planning phase if applicable */
  planningPhase?: string
}

/**
 * Build a prompt for session summarization.
 *
 * Used by the small model to create structured summaries of sessions
 * including key points, open questions, and decisions.
 */
export function buildSessionSummaryPrompt(input: SessionSummaryInput): string {
  const contextLines: string[] = []

  if (input.projectName) {
    contextLines.push(`Project: ${input.projectName}`)
  }
  if (input.planningPhase) {
    contextLines.push(`Planning Phase: ${input.planningPhase}`)
  }

  const contextSection =
    contextLines.length > 0 ? `## Context\n${contextLines.join("\n")}\n\n` : ""

  return `You are summarizing a development session conversation.

${contextSection}## Conversation Content
${input.conversationContent}

## Task
Analyze the conversation and extract:
1. A 2-3 sentence summary of what was discussed/accomplished
2. 3-5 key points (bullet points)
3. Any open questions that were raised but not resolved
4. Any decisions that were made
5. What should happen next

Respond with ONLY a JSON object in this exact format:
{
  "summary": "2-3 sentence summary of the session",
  "keyPoints": ["point 1", "point 2", "point 3"],
  "openQuestionsAdded": ["question 1", "question 2"],
  "decisionsMade": ["decision 1"],
  "whatsNext": ["next step 1", "next step 2"]
}

Rules:
- summary: 2-3 sentences, max 300 characters
- keyPoints: 3-5 items, each max 100 characters
- openQuestionsAdded: Only questions explicitly raised but not answered (can be empty array)
- decisionsMade: Only explicit decisions made (can be empty array)
- whatsNext: 1-3 concrete next steps (can be empty array)

Respond with ONLY the JSON object, no other text.`
}
