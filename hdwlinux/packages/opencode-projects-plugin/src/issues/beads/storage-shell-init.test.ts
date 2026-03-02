/**
 * Tests for BeadsIssueStorage shell initialization
 */

import { describe, test, expect, beforeEach } from "bun:test"
import { BeadsIssueStorage } from "./storage.js"
import type { Logger } from "../../utils/opencode-sdk/index.js"

describe("BeadsIssueStorage shell initialization", () => {
  let storage: BeadsIssueStorage
  let mockLogger: Logger

  beforeEach(() => {
    mockLogger = {
      debug: async () => {},
      info: async () => {},
      warn: async () => {},
      error: async () => {},
    } as Logger

    storage = new BeadsIssueStorage(mockLogger)
  })

  test("createIssue returns error when shell not initialized", async () => {
    const result = await storage.createIssue("/tmp/test", "Test Issue")

    expect(result.ok).toBe(false)
    if (!result.ok) {
      expect(result.error.name).toBe("StorageNotAvailableError")
      expect(result.error.message).toContain("BeadsClient shell not initialized")
    }
  })

  test("init returns error when shell not initialized", async () => {
    const result = await storage.init("/tmp/test")

    expect(result.ok).toBe(false)
    if (!result.ok) {
      expect(result.error.name).toBe("StorageNotAvailableError")
      expect(result.error.message).toContain("BeadsClient shell not initialized")
    }
  })

  test("isAvailable returns error when shell not initialized", async () => {
    const result = await storage.isAvailable()

    expect(result.ok).toBe(false)
    if (!result.ok) {
      expect(result.error.name).toBe("StorageNotAvailableError")
    }
  })
})
