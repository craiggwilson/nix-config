/**
 * Small Model Utility
 *
 * Provides a reusable interface for prompting the small model
 * with structured JSON responses. Used for intelligent decisions
 * like agent selection.
 */

import type { Logger, OpencodeClient } from "./types.js"

/**
 * Options for prompting the small model
 */
export interface SmallModelOptions {
  /** The prompt to send (should request JSON response) */
  prompt: string
  /** Timeout in milliseconds */
  timeoutMs: number
  /** Session title for debugging */
  sessionTitle?: string
}

/**
 * Result from small model prompt
 */
export interface SmallModelResult<T> {
  success: boolean
  data?: T
  error?: string
}

/**
 * Prompt the small model for a structured JSON response.
 *
 * This utility handles:
 * - Checking if small_model is configured
 * - Creating a temporary session
 * - Sending the prompt with timeout
 * - Parsing JSON from the response
 * - Cleaning up the session
 *
 * @param client - OpenCode client
 * @param log - Logger for debugging
 * @param options - Prompt options
 * @returns Parsed JSON response or error
 */
export async function promptSmallModel<T>(
  client: OpencodeClient,
  log: Logger,
  options: SmallModelOptions
): Promise<SmallModelResult<T>> {
  const { prompt, timeoutMs, sessionTitle = "Small Model Query" } = options

  let sessionId: string | undefined

  try {
    // Check if small_model is configured
    const config = await client.config.get()
    const configData = config.data as { small_model?: string } | undefined

    if (!configData?.small_model) {
      return { success: false, error: "No small_model configured" }
    }

    // Create a temporary session
    const sessionResult = await client.session.create({
      body: { title: sessionTitle },
    })

    sessionId = sessionResult.data?.id
    if (!sessionId) {
      return { success: false, error: "Failed to create session" }
    }

    // Send prompt with timeout
    const promptPromise = client.session.prompt({
      path: { id: sessionId },
      body: { parts: [{ type: "text", text: prompt }] },
    })

    const timeoutPromise = new Promise<never>((_, reject) => {
      setTimeout(() => reject(new Error("Timeout")), timeoutMs)
    })

    const result = await Promise.race([promptPromise, timeoutPromise])

    // Extract text from response - handle different response formats
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const data = result.data as any
    let responseText: string | undefined

    // Try different response formats
    if (data?.parts) {
      const textPart = data.parts.find((p: { type: string; text?: string }) => p.type === "text")
      responseText = textPart?.text
    } else if (data?.content) {
      responseText = data.content
    } else if (typeof data === "string") {
      responseText = data
    }

    if (!responseText) {
      return { success: false, error: "No text response from small model" }
    }

    // Parse JSON from response
    const jsonMatch = responseText.match(/\{[\s\S]*\}/)
    if (!jsonMatch) {
      return { success: false, error: "No JSON found in response" }
    }

    const parsed = JSON.parse(jsonMatch[0]) as T
    return { success: true, data: parsed }
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error)
    return { success: false, error: message }
  } finally {
    // Clean up the session
    if (sessionId) {
      try {
        await client.session.delete({ path: { id: sessionId } })
      } catch {
        // Ignore cleanup errors
      }
    }
  }
}
