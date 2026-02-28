/**
 * Tests for beads schema validation
 */

import { describe, test, expect } from "bun:test"
import {
  parseBeadsIssue,
  parseBeadsIssueArray,
  parseJSON,
  BeadsParseError,
} from "./schemas.js"

describe("parseJSON", () => {
  test("parses valid JSON", () => {
    const result = parseJSON('{"key": "value"}')
    expect(result.ok).toBe(true)
    if (result.ok) {
      expect(result.value).toEqual({ key: "value" })
    }
  })

  test("handles invalid JSON", () => {
    const result = parseJSON("{invalid json}")
    expect(result.ok).toBe(false)
    if (!result.ok) {
      expect(result.error).toBeInstanceOf(BeadsParseError)
    }
  })

  test("handles empty string", () => {
    const result = parseJSON("")
    expect(result.ok).toBe(false)
  })
})

describe("parseBeadsIssue", () => {
  test("parses valid beads issue", () => {
    const raw = {
      id: "test-123",
      title: "Test Issue",
      description: "Test description",
      status: "open",
      priority: 1,
      blocked_by: ["test-456"],
      labels: ["bug", "urgent"],
      created_at: "2024-01-01T00:00:00Z",
      updated_at: "2024-01-02T00:00:00Z",
    }

    const result = parseBeadsIssue(raw)
    expect(result.ok).toBe(true)
    if (result.ok) {
      expect(result.value.id).toBe("test-123")
      expect(result.value.title).toBe("Test Issue")
      expect(result.value.description).toBe("Test description")
      expect(result.value.status).toBe("open")
      expect(result.value.priority).toBe(1)
      expect(result.value.blockedBy).toEqual(["test-456"])
      expect(result.value.labels).toEqual(["bug", "urgent"])
    }
  })

  test("normalizes status values", () => {
    const testCases: Array<{ input: string; expected: "open" | "in_progress" | "closed" }> = [
      { input: "todo", expected: "open" },
      { input: "open", expected: "open" },
      { input: "in_progress", expected: "in_progress" },
      { input: "in-progress", expected: "in_progress" },
      { input: "active", expected: "in_progress" },
      { input: "done", expected: "closed" },
      { input: "closed", expected: "closed" },
      { input: "completed", expected: "closed" },
    ]

    for (const { input, expected } of testCases) {
      const result = parseBeadsIssue({
        id: "test-1",
        title: "Test",
        status: input,
      })
      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(result.value.status).toBe(expected)
      }
    }
  })

  test("applies default values", () => {
    const minimal = {
      id: "test-1",
      title: "Minimal Issue",
      status: "open",
    }

    const result = parseBeadsIssue(minimal)
    expect(result.ok).toBe(true)
    if (result.ok) {
      expect(result.value.priority).toBe(2)
      expect(result.value.blockedBy).toEqual([])
      expect(result.value.labels).toEqual([])
      expect(result.value.createdAt).toBeDefined()
      expect(result.value.updatedAt).toBeDefined()
    }
  })

  test("rejects missing required fields", () => {
    const invalid = {
      title: "Missing ID",
      status: "open",
    }

    const result = parseBeadsIssue(invalid)
    expect(result.ok).toBe(false)
    if (!result.ok) {
      expect(result.error).toBeInstanceOf(BeadsParseError)
      expect(result.error.message).toContain("Invalid beads issue data")
    }
  })

  test("rejects empty id", () => {
    const invalid = {
      id: "",
      title: "Test",
      status: "open",
    }

    const result = parseBeadsIssue(invalid)
    expect(result.ok).toBe(false)
  })

  test("rejects empty title", () => {
    const invalid = {
      id: "test-1",
      title: "",
      status: "open",
    }

    const result = parseBeadsIssue(invalid)
    expect(result.ok).toBe(false)
  })

  test("rejects invalid priority", () => {
    const invalid = {
      id: "test-1",
      title: "Test",
      status: "open",
      priority: 5,
    }

    const result = parseBeadsIssue(invalid)
    expect(result.ok).toBe(false)
  })

  test("rejects non-integer priority", () => {
    const invalid = {
      id: "test-1",
      title: "Test",
      status: "open",
      priority: 1.5,
    }

    const result = parseBeadsIssue(invalid)
    expect(result.ok).toBe(false)
  })

  test("handles optional fields", () => {
    const withOptionals = {
      id: "test-1",
      title: "Test",
      status: "open",
      description: "Description",
      assignee: "user@example.com",
      parent: "test-0",
    }

    const result = parseBeadsIssue(withOptionals)
    expect(result.ok).toBe(true)
    if (result.ok) {
      expect(result.value.description).toBe("Description")
      expect(result.value.assignee).toBe("user@example.com")
      expect(result.value.parent).toBe("test-0")
    }
  })
})

describe("parseBeadsIssueArray", () => {
  test("parses array of valid issues", () => {
    const raw = [
      {
        id: "test-1",
        title: "Issue 1",
        status: "open",
      },
      {
        id: "test-2",
        title: "Issue 2",
        status: "in_progress",
      },
    ]

    const result = parseBeadsIssueArray(raw)
    expect(result.ok).toBe(true)
    if (result.ok) {
      expect(result.value).toHaveLength(2)
      expect(result.value[0].id).toBe("test-1")
      expect(result.value[1].id).toBe("test-2")
    }
  })

  test("parses empty array", () => {
    const result = parseBeadsIssueArray([])
    expect(result.ok).toBe(true)
    if (result.ok) {
      expect(result.value).toEqual([])
    }
  })

  test("rejects non-array input", () => {
    const result = parseBeadsIssueArray({ not: "an array" })
    expect(result.ok).toBe(false)
    if (!result.ok) {
      expect(result.error).toBeInstanceOf(BeadsParseError)
    }
  })

  test("rejects array with invalid issue", () => {
    const raw = [
      {
        id: "test-1",
        title: "Valid Issue",
        status: "open",
      },
      {
        id: "test-2",
        // Missing title
        status: "open",
      },
    ]

    const result = parseBeadsIssueArray(raw)
    expect(result.ok).toBe(false)
  })

  test("preserves all issues when all valid", () => {
    const raw = Array.from({ length: 10 }, (_, i) => ({
      id: `test-${i}`,
      title: `Issue ${i}`,
      status: "open",
      priority: i % 4,
    }))

    const result = parseBeadsIssueArray(raw)
    expect(result.ok).toBe(true)
    if (result.ok) {
      expect(result.value).toHaveLength(10)
      result.value.forEach((issue, i) => {
        expect(issue.id).toBe(`test-${i}`)
        expect(issue.priority).toBe(i % 4)
      })
    }
  })
})

describe("BeadsParseError", () => {
  test("includes zod error details", () => {
    const result = parseBeadsIssue({ invalid: "data" })
    expect(result.ok).toBe(false)
    if (!result.ok) {
      expect(result.error).toBeInstanceOf(BeadsParseError)
      expect(result.error.zodError).toBeDefined()
      expect(result.error.zodError?.issues).toBeDefined()
    }
  })
})
