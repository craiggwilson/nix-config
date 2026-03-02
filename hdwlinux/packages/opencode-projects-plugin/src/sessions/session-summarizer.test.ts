/**
 * Tests for session-summarizer
 */

import { describe, it, expect } from "bun:test"

import { summarizeSession } from "./session-summarizer.js"
import type { Logger, OpencodeClient } from "../utils/opencode-sdk/index.js"

function createMockLogger(): Logger {
  return {
    debug: async () => {},
    info: async () => {},
    warn: async () => {},
    error: async () => {},
  }
}

function createMockClient(response?: unknown): OpencodeClient {
  return {
    app: {
      log: async () => ({}),
      agents: async () => ({ data: [] }),
    },
    session: {
      create: async () => ({ data: { id: "test-session" } }),
      get: async () => ({ data: { id: "test-session" } }),
      prompt: async () => ({
        data: {
          id: "test-msg",
          role: "assistant" as const,
          sessionID: "test-session",
          parts: response
            ? [{ type: "text", text: JSON.stringify(response) }]
            : [],
        },
      }),
      messages: async () => ({ data: [] }),
      delete: async () => ({}),
    },
    config: {
      get: async () => ({ data: {} }),
    },
  }
}

describe("summarizeSession", () => {
  it("returns fallback summary when small model fails", async () => {
    const client = createMockClient()
    const log = createMockLogger()

    const result = await summarizeSession(client, log, {
      conversationContent: "Human: Hello\nAssistant: Hi there!",
    })

    expect(result.ok).toBe(true)
    if (result.ok) {
      expect(result.value.summary).toContain("Session with approximately")
      expect(result.value.keyPoints).toContain("Session content captured")
      expect(result.value.keyPoints).toContain("Manual review recommended")
    }
  })

  it("extracts questions from content in fallback mode", async () => {
    const client = createMockClient()
    const log = createMockLogger()

    const result = await summarizeSession(client, log, {
      conversationContent: `Human: What is the best approach?
Assistant: Let me think about that.
Human: Should we use TypeScript?
Assistant: Yes, definitely.`,
    })

    expect(result.ok).toBe(true)
    if (result.ok) {
      expect(result.value.openQuestionsAdded.length).toBeGreaterThan(0)
      expect(result.value.openQuestionsAdded.some((q) => q.includes("?"))).toBe(true)
    }
  })

  it("truncates long content", async () => {
    const client = createMockClient()
    const log = createMockLogger()

    const longContent = "Human: Test\n".repeat(5000)

    const result = await summarizeSession(client, log, {
      conversationContent: longContent,
    })

    expect(result.ok).toBe(true)
  })

  it("includes project context when provided", async () => {
    const client = createMockClient()
    const log = createMockLogger()

    const result = await summarizeSession(client, log, {
      conversationContent: "Human: Hello\nAssistant: Hi!",
      projectName: "test-project",
      planningPhase: "discovery",
    })

    expect(result.ok).toBe(true)
  })

  it("uses custom timeout when provided", async () => {
    const client = createMockClient()
    const log = createMockLogger()

    const result = await summarizeSession(client, log, {
      conversationContent: "Human: Hello\nAssistant: Hi!",
      timeoutMs: 5000,
    })

    expect(result.ok).toBe(true)
  })

  it("handles empty conversation content", async () => {
    const client = createMockClient()
    const log = createMockLogger()

    const result = await summarizeSession(client, log, {
      conversationContent: "",
    })

    expect(result.ok).toBe(true)
    if (result.ok) {
      expect(result.value.summary).toBeDefined()
    }
  })

  it("limits extracted questions to 3", async () => {
    const client = createMockClient()
    const log = createMockLogger()

    const result = await summarizeSession(client, log, {
      conversationContent: `Question 1?
Question 2?
Question 3?
Question 4?
Question 5?`,
    })

    expect(result.ok).toBe(true)
    if (result.ok) {
      expect(result.value.openQuestionsAdded.length).toBeLessThanOrEqual(3)
    }
  })
})
