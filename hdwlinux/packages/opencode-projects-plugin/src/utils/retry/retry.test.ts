/**
 * Tests for retry utility
 */

import { describe, it, expect, beforeEach } from "bun:test"
import {
  withRetry,
  withRetryResult,
  isRetryableError,
  formatRetryError,
  DEFAULT_RETRY_CONFIG,
  type RetryError,
} from "./retry.js"
import type { Logger } from "../opencode-sdk/index.js"
import { ok, err } from "../result/index.js"

function createMockLogger(): Logger {
  return {
    debug: async () => {},
    info: async () => {},
    warn: async () => {},
    error: async () => {},
  }
}

describe("isRetryableError", () => {
  it("should identify the specific JSON Parse error from the issue as retryable", () => {
    // This is the exact error message from the issue
    expect(isRetryableError(new Error("JSON Parse error: Unexpected EOF"))).toBe(true)
  })

  it("should identify JSON parse errors as retryable", () => {
    expect(isRetryableError(new Error("JSON Parse error: Unexpected EOF"))).toBe(true)
    expect(isRetryableError(new Error("json parse error"))).toBe(true)
  })

  it("should identify connection errors as retryable", () => {
    expect(isRetryableError(new Error("Connection reset by peer"))).toBe(true)
    expect(isRetryableError(new Error("ECONNRESET"))).toBe(true)
    expect(isRetryableError(new Error("ECONNREFUSED"))).toBe(true)
    expect(isRetryableError(new Error("ETIMEDOUT"))).toBe(true)
  })

  it("should identify network errors as retryable", () => {
    expect(isRetryableError(new Error("Network error"))).toBe(true)
    expect(isRetryableError(new Error("fetch failed"))).toBe(true)
    expect(isRetryableError(new Error("socket hang up"))).toBe(true)
  })

  it("should identify HTTP 5xx errors as retryable", () => {
    expect(isRetryableError(new Error("502 Bad Gateway"))).toBe(true)
    expect(isRetryableError(new Error("503 Service Unavailable"))).toBe(true)
    expect(isRetryableError(new Error("504 Gateway Timeout"))).toBe(true)
  })

  it("should not identify non-retryable errors", () => {
    expect(isRetryableError(new Error("Invalid argument"))).toBe(false)
    expect(isRetryableError(new Error("Not found"))).toBe(false)
    expect(isRetryableError(new Error("Permission denied"))).toBe(false)
    expect(isRetryableError(new Error("400 Bad Request"))).toBe(false)
  })

  it("should handle string errors", () => {
    expect(isRetryableError("Unexpected EOF")).toBe(true)
    expect(isRetryableError("Invalid input")).toBe(false)
  })
})

describe("withRetry", () => {
  let log: Logger

  beforeEach(() => {
    log = createMockLogger()
  })

  it("should succeed on first attempt", async () => {
    let attempts = 0
    const result = await withRetry(
      "test-op",
      async () => {
        attempts++
        return "success"
      },
      log,
      { maxAttempts: 3, initialDelayMs: 10 }
    )

    expect(result.ok).toBe(true)
    if (result.ok) {
      expect(result.value).toBe("success")
    }
    expect(attempts).toBe(1)
  })

  it("should retry on retryable errors", async () => {
    let attempts = 0
    const result = await withRetry(
      "test-op",
      async () => {
        attempts++
        if (attempts < 3) {
          throw new Error("JSON Parse error: Unexpected EOF")
        }
        return "success"
      },
      log,
      { maxAttempts: 3, initialDelayMs: 10 }
    )

    expect(result.ok).toBe(true)
    if (result.ok) {
      expect(result.value).toBe("success")
    }
    expect(attempts).toBe(3)
  })

  it("should fail immediately on non-retryable errors", async () => {
    let attempts = 0
    const result = await withRetry(
      "test-op",
      async () => {
        attempts++
        throw new Error("Invalid argument")
      },
      log,
      { maxAttempts: 3, initialDelayMs: 10 }
    )

    expect(result.ok).toBe(false)
    if (!result.ok) {
      expect(result.error.type).toBe("retry_exhausted")
      expect(result.error.attempts).toBe(1)
      expect(result.error.wasRetryable).toBe(false)
    }
    expect(attempts).toBe(1)
  })

  it("should exhaust retries on persistent retryable errors", async () => {
    let attempts = 0
    const result = await withRetry(
      "test-op",
      async () => {
        attempts++
        throw new Error("Connection reset")
      },
      log,
      { maxAttempts: 3, initialDelayMs: 10 }
    )

    expect(result.ok).toBe(false)
    if (!result.ok) {
      expect(result.error.type).toBe("retry_exhausted")
      expect(result.error.attempts).toBe(3)
      expect(result.error.wasRetryable).toBe(true)
      expect(result.error.allErrors).toHaveLength(3)
    }
    expect(attempts).toBe(3)
  })

  it("should include operation name in error", async () => {
    const result = await withRetry(
      "session.create",
      async () => {
        throw new Error("Unexpected EOF")
      },
      log,
      { maxAttempts: 2, initialDelayMs: 10 }
    )

    expect(result.ok).toBe(false)
    if (!result.ok) {
      expect(result.error.operation).toBe("session.create")
    }
  })
})

describe("withRetryResult", () => {
  let log: Logger

  beforeEach(() => {
    log = createMockLogger()
  })

  it("should succeed on first attempt", async () => {
    let attempts = 0
    const result = await withRetryResult(
      "test-op",
      async () => {
        attempts++
        return ok("success")
      },
      () => true,
      log,
      { maxAttempts: 3, initialDelayMs: 10 }
    )

    expect(result.ok).toBe(true)
    if (result.ok) {
      expect(result.value).toBe("success")
    }
    expect(attempts).toBe(1)
  })

  it("should retry on retryable Result errors", async () => {
    let attempts = 0
    const result = await withRetryResult(
      "test-op",
      async () => {
        attempts++
        if (attempts < 3) {
          return err({ type: "transient" as const, message: "try again" })
        }
        return ok("success")
      },
      (e) => e.type === "transient",
      log,
      { maxAttempts: 3, initialDelayMs: 10 }
    )

    expect(result.ok).toBe(true)
    if (result.ok) {
      expect(result.value).toBe("success")
    }
    expect(attempts).toBe(3)
  })

  it("should return original error on non-retryable Result errors", async () => {
    type TestError = { type: "permanent" | "transient"; message: string }
    let attempts = 0
    const result = await withRetryResult<string, TestError>(
      "test-op",
      async () => {
        attempts++
        return err({ type: "permanent", message: "not found" })
      },
      (e) => e.type === "transient",
      log,
      { maxAttempts: 3, initialDelayMs: 10 }
    )

    expect(result.ok).toBe(false)
    if (!result.ok) {
      // Should return the original error, not a RetryError
      const errorType = (result.error as { type: string }).type
      expect(errorType).toBe("permanent")
    }
    expect(attempts).toBe(1)
  })
})

describe("formatRetryError", () => {
  it("should format error with all details", () => {
    const error: RetryError = {
      type: "retry_exhausted",
      operation: "session.create",
      attempts: 3,
      lastError: "Connection reset",
      allErrors: [
        "Attempt 1: Connection reset",
        "Attempt 2: Connection reset",
        "Attempt 3: Connection reset",
      ],
      wasRetryable: true,
      hint: "Try again later",
    }

    const formatted = formatRetryError(error)

    expect(formatted).toContain("session.create")
    expect(formatted).toContain("3 attempt(s)")
    expect(formatted).toContain("Connection reset")
    expect(formatted).toContain("All errors:")
    expect(formatted).toContain("Try again later")
  })

  it("should not show all errors for single attempt", () => {
    const error: RetryError = {
      type: "retry_exhausted",
      operation: "test",
      attempts: 1,
      lastError: "Error",
      allErrors: ["Attempt 1: Error"],
      wasRetryable: false,
      hint: "Check logs",
    }

    const formatted = formatRetryError(error)

    expect(formatted).not.toContain("All errors:")
  })
})

describe("DEFAULT_RETRY_CONFIG", () => {
  it("should have sensible defaults", () => {
    expect(DEFAULT_RETRY_CONFIG.maxAttempts).toBe(3)
    expect(DEFAULT_RETRY_CONFIG.initialDelayMs).toBe(1000)
    expect(DEFAULT_RETRY_CONFIG.maxDelayMs).toBe(10000)
    expect(DEFAULT_RETRY_CONFIG.backoffMultiplier).toBe(2)
    expect(DEFAULT_RETRY_CONFIG.jitterFactor).toBeGreaterThan(0)
    expect(DEFAULT_RETRY_CONFIG.jitterFactor).toBeLessThanOrEqual(1)
  })
})
