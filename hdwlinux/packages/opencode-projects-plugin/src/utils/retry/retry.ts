/**
 * Retry utility with exponential backoff for transient failures.
 *
 * Designed for API calls that may fail due to network issues, timeouts,
 * or transient server errors (like "JSON Parse error: Unexpected EOF").
 */

import type { Logger } from "../opencode-sdk/index.js"
import type { Result } from "../result/index.js"
import { ok, err } from "../result/index.js"

/**
 * Configuration for retry behavior.
 */
export interface RetryConfig {
  /** Maximum number of retry attempts (default: 3) */
  maxAttempts: number
  /** Initial delay between retries in milliseconds (default: 1000) */
  initialDelayMs: number
  /** Maximum delay between retries in milliseconds (default: 10000) */
  maxDelayMs: number
  /** Multiplier for exponential backoff (default: 2) */
  backoffMultiplier: number
  /** Jitter factor to add randomness (0-1, default: 0.1) */
  jitterFactor: number
}

/**
 * Default retry configuration.
 */
export const DEFAULT_RETRY_CONFIG: RetryConfig = {
  maxAttempts: 3,
  initialDelayMs: 1000,
  maxDelayMs: 10000,
  backoffMultiplier: 2,
  jitterFactor: 0.1,
}

/**
 * Error patterns that indicate transient failures worth retrying.
 */
const RETRYABLE_ERROR_PATTERNS = [
  /unexpected\s+eof/i,
  /json\s+parse\s+error/i,
  /connection\s+reset/i,
  /connection\s+refused/i,
  /econnreset/i,
  /econnrefused/i,
  /etimedout/i,
  /socket\s+hang\s+up/i,
  /network\s+error/i,
  /fetch\s+failed/i,
  /aborted/i,
  /timeout/i,
  /503/i,
  /502/i,
  /504/i,
  /service\s+unavailable/i,
  /bad\s+gateway/i,
  /gateway\s+timeout/i,
]

/**
 * Check if an error is retryable based on its message.
 */
export function isRetryableError(error: unknown): boolean {
  const message = error instanceof Error ? error.message : String(error)
  return RETRYABLE_ERROR_PATTERNS.some((pattern) => pattern.test(message))
}

/**
 * Detailed error information for retry failures.
 */
export interface RetryError {
  /** Type discriminator */
  type: "retry_exhausted"
  /** Operation that was being retried */
  operation: string
  /** Number of attempts made */
  attempts: number
  /** Last error encountered */
  lastError: string
  /** All errors encountered during retries */
  allErrors: string[]
  /** Whether the error appeared to be retryable */
  wasRetryable: boolean
  /** Hint for the user */
  hint: string
}

/**
 * Format a RetryError for display.
 */
export function formatRetryError(error: RetryError): string {
  const lines = [
    `Operation '${error.operation}' failed after ${error.attempts} attempt(s).`,
    "",
    `**Last error:** ${error.lastError}`,
  ]

  if (error.allErrors.length > 1) {
    lines.push("")
    lines.push("**All errors:**")
    error.allErrors.forEach((e, i) => {
      lines.push(`  ${i + 1}. ${e}`)
    })
  }

  lines.push("")
  lines.push(`**Hint:** ${error.hint}`)

  return lines.join("\n")
}

/**
 * Calculate delay for the next retry attempt with exponential backoff and jitter.
 */
function calculateDelay(attempt: number, config: RetryConfig): number {
  const exponentialDelay = config.initialDelayMs * Math.pow(config.backoffMultiplier, attempt - 1)
  const cappedDelay = Math.min(exponentialDelay, config.maxDelayMs)

  // Add jitter to prevent thundering herd
  const jitter = cappedDelay * config.jitterFactor * (Math.random() * 2 - 1)
  return Math.max(0, cappedDelay + jitter)
}

/**
 * Sleep for a specified duration.
 */
function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms))
}

/**
 * Execute an async operation with retry logic.
 *
 * Retries on transient failures (network errors, JSON parse errors, etc.)
 * with exponential backoff and jitter.
 *
 * @param operation - Name of the operation (for logging and error messages)
 * @param fn - Async function to execute
 * @param log - Logger for retry attempts
 * @param config - Retry configuration (optional, uses defaults)
 * @returns Result with the operation result or a RetryError
 */
export async function withRetry<T>(
  operation: string,
  fn: () => Promise<T>,
  log: Logger,
  config: Partial<RetryConfig> = {}
): Promise<Result<T, RetryError>> {
  const fullConfig: RetryConfig = { ...DEFAULT_RETRY_CONFIG, ...config }
  const errors: string[] = []
  let lastError: string = ""
  let wasRetryable = false

  for (let attempt = 1; attempt <= fullConfig.maxAttempts; attempt++) {
    try {
      const result = await fn()
      if (attempt > 1) {
        await log.info(`${operation}: succeeded on attempt ${attempt}`)
      }
      return ok(result)
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error)
      lastError = errorMessage
      errors.push(`Attempt ${attempt}: ${errorMessage}`)

      const retryable = isRetryableError(error)
      wasRetryable = wasRetryable || retryable

      if (attempt < fullConfig.maxAttempts && retryable) {
        const delay = calculateDelay(attempt, fullConfig)
        await log.warn(
          `${operation}: attempt ${attempt}/${fullConfig.maxAttempts} failed (${errorMessage}), retrying in ${Math.round(delay)}ms...`
        )
        await sleep(delay)
      } else if (!retryable) {
        // Non-retryable error, fail immediately
        await log.error(`${operation}: non-retryable error on attempt ${attempt}: ${errorMessage}`)
        break
      } else {
        await log.error(`${operation}: all ${fullConfig.maxAttempts} attempts exhausted`)
      }
    }
  }

  const hint = wasRetryable
    ? "This appears to be a transient error. Try again in a few moments, or check network connectivity."
    : "This error may require investigation. Check the OpenCode logs for more details."

  return err({
    type: "retry_exhausted",
    operation,
    attempts: errors.length,
    lastError,
    allErrors: errors,
    wasRetryable,
    hint,
  })
}

/**
 * Execute an async operation that returns a Result with retry logic.
 *
 * Similar to withRetry, but for functions that already return Result types.
 * Retries when the Result is an error and the error appears retryable.
 *
 * @param operation - Name of the operation (for logging and error messages)
 * @param fn - Async function that returns a Result
 * @param isRetryable - Function to check if a Result error is retryable
 * @param log - Logger for retry attempts
 * @param config - Retry configuration (optional, uses defaults)
 * @returns Result with the operation result or a RetryError
 */
export async function withRetryResult<T, E>(
  operation: string,
  fn: () => Promise<Result<T, E>>,
  isRetryable: (error: E) => boolean,
  log: Logger,
  config: Partial<RetryConfig> = {}
): Promise<Result<T, RetryError | E>> {
  const fullConfig: RetryConfig = { ...DEFAULT_RETRY_CONFIG, ...config }
  const errors: string[] = []
  let lastResult: Result<T, E> | undefined
  let wasRetryable = false

  for (let attempt = 1; attempt <= fullConfig.maxAttempts; attempt++) {
    const result = await fn()

    if (result.ok) {
      if (attempt > 1) {
        await log.info(`${operation}: succeeded on attempt ${attempt}`)
      }
      return result
    }

    lastResult = result
    const errorStr = typeof result.error === "object" && result.error !== null && "message" in result.error
      ? String((result.error as { message: unknown }).message)
      : String(result.error)
    errors.push(`Attempt ${attempt}: ${errorStr}`)

    const retryable = isRetryable(result.error)
    wasRetryable = wasRetryable || retryable

    if (attempt < fullConfig.maxAttempts && retryable) {
      const delay = calculateDelay(attempt, fullConfig)
      await log.warn(
        `${operation}: attempt ${attempt}/${fullConfig.maxAttempts} failed (${errorStr}), retrying in ${Math.round(delay)}ms...`
      )
      await sleep(delay)
    } else if (!retryable) {
      // Non-retryable error, return the original error
      await log.error(`${operation}: non-retryable error on attempt ${attempt}: ${errorStr}`)
      return result
    } else {
      await log.error(`${operation}: all ${fullConfig.maxAttempts} attempts exhausted`)
    }
  }

  // If we have a last result and it wasn't retryable, return the original error
  if (lastResult && !wasRetryable) {
    return lastResult
  }

  const hint = wasRetryable
    ? "This appears to be a transient error. Try again in a few moments, or check network connectivity."
    : "This error may require investigation. Check the OpenCode logs for more details."

  return err({
    type: "retry_exhausted",
    operation,
    attempts: errors.length,
    lastError: errors[errors.length - 1] || "Unknown error",
    allErrors: errors,
    wasRetryable,
    hint,
  })
}
