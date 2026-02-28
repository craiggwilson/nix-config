/**
 * Tests for small model utility with runtime validation
 */

import { describe, test, expect, beforeEach } from "bun:test"
import { z } from "zod"
import { promptSmallModel } from "./small-model.js"
import type { OpencodeClient, Logger } from "../utils/opencode-sdk/index.js"

describe("promptSmallModel", () => {
  let mockClient: OpencodeClient
  let mockLog: Logger

  beforeEach(() => {
    mockLog = {
      debug: async () => {},
      info: async () => {},
      warn: async () => {},
      error: async () => {},
    }
  })

  test("validates response with parts format", async () => {
    const schema = z.object({
      agent: z.string(),
      reason: z.string(),
    })

    mockClient = {
      config: {
        get: async () => ({ data: { small_model: "test-model" } }),
      },
      session: {
        create: async () => ({ data: { id: "session-123" } }),
        prompt: async () => ({
          data: {
            parts: [
              { type: "text", text: '{"agent": "typescript-expert", "reason": "Best for TS"}' },
            ],
          },
        }),
        delete: async () => ({}),
      },
      app: { log: async () => ({}), agents: async () => ({ data: [] }) },
    } as unknown as OpencodeClient

    const result = await promptSmallModel(mockClient, mockLog, {
      prompt: "Select an agent",
      timeoutMs: 5000,
      schema,
    })

    expect(result.ok).toBe(true)
    if (result.ok) {
      expect(result.value.agent).toBe("typescript-expert")
      expect(result.value.reason).toBe("Best for TS")
    }
  })

  test("validates response with content format", async () => {
    const schema = z.object({
      title: z.string(),
      description: z.string(),
    })

    mockClient = {
      config: {
        get: async () => ({ data: { small_model: "test-model" } }),
      },
      session: {
        create: async () => ({ data: { id: "session-123" } }),
        prompt: async () => ({
          data: {
            content: '{"title": "Test Title", "description": "Test description"}',
          },
        }),
        delete: async () => ({}),
      },
      app: { log: async () => ({}), agents: async () => ({ data: [] }) },
    } as unknown as OpencodeClient

    const result = await promptSmallModel(mockClient, mockLog, {
      prompt: "Generate metadata",
      timeoutMs: 5000,
      schema,
    })

    expect(result.ok).toBe(true)
    if (result.ok) {
      expect(result.value.title).toBe("Test Title")
      expect(result.value.description).toBe("Test description")
    }
  })

  test("validates response with string format", async () => {
    const schema = z.object({
      agents: z.array(z.string()),
    })

    mockClient = {
      config: {
        get: async () => ({ data: { small_model: "test-model" } }),
      },
      session: {
        create: async () => ({ data: { id: "session-123" } }),
        prompt: async () => ({
          data: '{"agents": ["agent1", "agent2"]}',
        }),
        delete: async () => ({}),
      },
      app: { log: async () => ({}), agents: async () => ({ data: [] }) },
    } as unknown as OpencodeClient

    const result = await promptSmallModel(mockClient, mockLog, {
      prompt: "Select team",
      timeoutMs: 5000,
      schema,
    })

    expect(result.ok).toBe(true)
    if (result.ok) {
      expect(result.value.agents).toEqual(["agent1", "agent2"])
    }
  })

  test("returns error when validation fails", async () => {
    const schema = z.object({
      agent: z.string(),
      reason: z.string(),
    })

    mockClient = {
      config: {
        get: async () => ({ data: { small_model: "test-model" } }),
      },
      session: {
        create: async () => ({ data: { id: "session-123" } }),
        prompt: async () => ({
          data: {
            parts: [{ type: "text", text: '{"agent": "test", "invalid": "field"}' }],
          },
        }),
        delete: async () => ({}),
      },
      app: { log: async () => ({}), agents: async () => ({ data: [] }) },
    } as unknown as OpencodeClient

    const result = await promptSmallModel(mockClient, mockLog, {
      prompt: "Select an agent",
      timeoutMs: 5000,
      schema,
    })

    expect(result.ok).toBe(false)
    if (!result.ok) {
      expect(result.error).toContain("validation failed")
      expect(result.error).toContain("reason")
    }
  })

  test("returns error when no JSON found", async () => {
    const schema = z.object({
      agent: z.string(),
    })

    mockClient = {
      config: {
        get: async () => ({ data: { small_model: "test-model" } }),
      },
      session: {
        create: async () => ({ data: { id: "session-123" } }),
        prompt: async () => ({
          data: {
            parts: [{ type: "text", text: "No JSON here" }],
          },
        }),
        delete: async () => ({}),
      },
      app: { log: async () => ({}), agents: async () => ({ data: [] }) },
    } as unknown as OpencodeClient

    const result = await promptSmallModel(mockClient, mockLog, {
      prompt: "Select an agent",
      timeoutMs: 5000,
      schema,
    })

    expect(result.ok).toBe(false)
    if (!result.ok) {
      expect(result.error).toBe("No JSON found in response")
    }
  })

  test("returns error when no text response", async () => {
    const schema = z.object({
      agent: z.string(),
    })

    mockClient = {
      config: {
        get: async () => ({ data: { small_model: "test-model" } }),
      },
      session: {
        create: async () => ({ data: { id: "session-123" } }),
        prompt: async () => ({
          data: {
            parts: [{ type: "image" }],
          },
        }),
        delete: async () => ({}),
      },
      app: { log: async () => ({}), agents: async () => ({ data: [] }) },
    } as unknown as OpencodeClient

    const result = await promptSmallModel(mockClient, mockLog, {
      prompt: "Select an agent",
      timeoutMs: 5000,
      schema,
    })

    expect(result.ok).toBe(false)
    if (!result.ok) {
      expect(result.error).toBe("No text part found in parts response")
    }
  })

  test("returns error when small_model not configured", async () => {
    const schema = z.object({
      agent: z.string(),
    })

    mockClient = {
      config: {
        get: async () => ({ data: {} }),
      },
      session: {
        create: async () => ({ data: { id: "session-123" } }),
        prompt: async () => ({ data: {} }),
        delete: async () => ({}),
      },
      app: { log: async () => ({}), agents: async () => ({ data: [] }) },
    } as unknown as OpencodeClient

    const result = await promptSmallModel(mockClient, mockLog, {
      prompt: "Select an agent",
      timeoutMs: 5000,
      schema,
    })

    expect(result.ok).toBe(false)
    if (!result.ok) {
      expect(result.error).toBe("No small_model configured")
    }
  })

  test("handles timeout", async () => {
    const schema = z.object({
      agent: z.string(),
    })

    mockClient = {
      config: {
        get: async () => ({ data: { small_model: "test-model" } }),
      },
      session: {
        create: async () => ({ data: { id: "session-123" } }),
        prompt: async () => {
          await new Promise((resolve) => setTimeout(resolve, 100))
          return { data: {} }
        },
        delete: async () => ({}),
      },
      app: { log: async () => ({}), agents: async () => ({ data: [] }) },
    } as unknown as OpencodeClient

    const result = await promptSmallModel(mockClient, mockLog, {
      prompt: "Select an agent",
      timeoutMs: 10,
      schema,
    })

    expect(result.ok).toBe(false)
    if (!result.ok) {
      expect(result.error).toBe("Timeout")
    }
  })

  test("validates complex nested schema", async () => {
    const schema = z.object({
      agents: z.array(z.string()),
      metadata: z.object({
        count: z.number(),
        primary: z.string(),
      }),
    })

    mockClient = {
      config: {
        get: async () => ({ data: { small_model: "test-model" } }),
      },
      session: {
        create: async () => ({ data: { id: "session-123" } }),
        prompt: async () => ({
          data: {
            parts: [
              {
                type: "text",
                text: '{"agents": ["a1", "a2"], "metadata": {"count": 2, "primary": "a1"}}',
              },
            ],
          },
        }),
        delete: async () => ({}),
      },
      app: { log: async () => ({}), agents: async () => ({ data: [] }) },
    } as unknown as OpencodeClient

    const result = await promptSmallModel(mockClient, mockLog, {
      prompt: "Select team",
      timeoutMs: 5000,
      schema,
    })

    expect(result.ok).toBe(true)
    if (result.ok) {
      expect(result.value.agents).toEqual(["a1", "a2"])
      expect(result.value.metadata.count).toBe(2)
      expect(result.value.metadata.primary).toBe("a1")
    }
  })
})
