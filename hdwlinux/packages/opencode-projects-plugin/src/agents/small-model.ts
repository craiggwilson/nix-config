/**
 * Small Model Utility
 *
 * Provides a reusable interface for prompting the small model
 * with structured JSON responses. Used for intelligent decisions
 * like agent selection.
 */

import { z } from "zod"
import type { Logger, OpencodeClient } from "../utils/opencode-sdk/index.js"
import type { Result } from "../utils/result/index.js"

/**
 * Options for prompting the small model
 */
export interface SmallModelOptions<T> {
  /** The prompt to send (should request JSON response) */
  prompt: string
  /** Timeout in milliseconds */
  timeoutMs: number
  /** Session title for debugging */
  sessionTitle?: string
  /** Zod schema for validating the expected JSON response */
  schema: z.ZodType<T>
}

/**
 * Zod schemas for different API response formats
 */
const PartSchema = z.object({
  type: z.string(),
  text: z.string().optional(),
})

const PartsResponseSchema = z.object({
  parts: z.array(PartSchema),
})

const ContentResponseSchema = z.object({
  content: z.string(),
})

const StringResponseSchema = z.string()

/**
 * Type guards for API response formats
 */
function isPartsResponse(data: unknown): data is z.infer<typeof PartsResponseSchema> {
  return PartsResponseSchema.safeParse(data).success
}

function isContentResponse(data: unknown): data is z.infer<typeof ContentResponseSchema> {
  return ContentResponseSchema.safeParse(data).success
}

function isStringResponse(data: unknown): data is string {
  return StringResponseSchema.safeParse(data).success
}

/**
 * Extract text from API response using type guards
 */
function extractTextFromResponse(data: unknown): Result<string, string> {
  if (isStringResponse(data)) {
    return { ok: true, value: data }
  }

  if (isPartsResponse(data)) {
    const textPart = data.parts.find((p) => p.type === "text" && p.text)
    if (textPart?.text) {
      return { ok: true, value: textPart.text }
    }
    return { ok: false, error: "No text part found in parts response" }
  }

  if (isContentResponse(data)) {
    return { ok: true, value: data.content }
  }

  return { ok: false, error: "Unknown response format" }
}

/**
 * Extract and validate JSON from text response
 */
function extractAndValidateJson<T>(
  responseText: string,
  schema: z.ZodType<T>
): Result<T, string> {
  const jsonMatch = responseText.match(/\{[\s\S]*\}/)
  if (!jsonMatch) {
    return { ok: false, error: "No JSON found in response" }
  }

  try {
    const parsed = JSON.parse(jsonMatch[0])
    const validated = schema.safeParse(parsed)

    if (!validated.success) {
      const errors = validated.error.issues
        .map((issue) => `${issue.path.join(".")}: ${issue.message}`)
        .join(", ")
      return { ok: false, error: `JSON validation failed: ${errors}` }
    }

    return { ok: true, value: validated.data }
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error)
    return { ok: false, error: `JSON parse error: ${message}` }
  }
}

/**
 * Prompt the small model for a structured JSON response with validation.
 *
 * This utility handles:
 * - Checking if small_model is configured
 * - Creating a temporary session
 * - Sending the prompt with timeout
 * - Validating API response format
 * - Parsing and validating JSON from the response
 * - Cleaning up the session
 *
 * @param client - OpenCode client
 * @param log - Logger for debugging
 * @param options - Prompt options including Zod schema for validation
 * @returns Result with validated data or error
 */
export async function promptSmallModel<T>(
  client: OpencodeClient,
  log: Logger,
  options: SmallModelOptions<T>
): Promise<Result<T, string>> {
  const { prompt, timeoutMs, sessionTitle = "Small Model Query", schema } = options

  let sessionId: string | undefined

  try {
    // Check if small_model is configured
    const config = await client.config.get()
    const configData = config.data as { small_model?: string } | undefined

    if (!configData?.small_model) {
      return { ok: false, error: "No small_model configured" }
    }

    // Create a temporary session
    const sessionResult = await client.session.create({
      body: { title: sessionTitle },
    })

    sessionId = sessionResult.data?.id
    if (!sessionId) {
      return { ok: false, error: "Failed to create session" }
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

    // Extract text from response using type guards
    const textResult = extractTextFromResponse(result.data)
    if (!textResult.ok) {
      return textResult
    }

    // Extract and validate JSON from text
    return extractAndValidateJson(textResult.value, schema)
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error)
    return { ok: false, error: message }
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
