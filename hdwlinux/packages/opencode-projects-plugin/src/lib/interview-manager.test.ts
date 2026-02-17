/**
 * Tests for InterviewManager
 */

import { describe, test, expect, beforeEach, afterAll } from "bun:test"
import * as fs from "node:fs/promises"
import * as path from "node:path"
import * as os from "node:os"

import { InterviewManager } from "./interview-manager.js"

describe("InterviewManager", () => {
  let testDir: string
  let manager: InterviewManager

  beforeEach(async () => {
    // Create a fresh temporary directory for each test
    testDir = await fs.mkdtemp(path.join(os.tmpdir(), "interview-test-"))
    manager = new InterviewManager(testDir)
  })

  afterAll(async () => {
    // Cleanup all test directories
    try {
      const tmpDir = os.tmpdir()
      const entries = await fs.readdir(tmpDir)
      for (const entry of entries) {
        if (entry.startsWith("interview-test-")) {
          await fs.rm(path.join(tmpDir, entry), { recursive: true, force: true })
        }
      }
    } catch {
      // Ignore cleanup errors
    }
  })

  describe("startSession", () => {
    test("creates a new session", async () => {
      const session = await manager.startSession("test-project", "discovery", "requirements")

      expect(session.id).toMatch(/^\d{8}-[a-f0-9]+$/)
      expect(session.projectId).toBe("test-project")
      expect(session.phase).toBe("discovery")
      expect(session.topic).toBe("requirements")
      expect(session.status).toBe("active")
      expect(session.exchanges).toEqual([])
    })

    test("persists session to disk", async () => {
      const session = await manager.startSession("test-project", "discovery")

      const filePath = path.join(testDir, "interviews", `${session.id}.json`)
      const content = await fs.readFile(filePath, "utf8")
      const saved = JSON.parse(content)

      expect(saved.id).toBe(session.id)
      expect(saved.projectId).toBe("test-project")
    })

    test("sets current session", async () => {
      await manager.startSession("test-project", "discovery")

      const current = manager.getCurrentSession()
      expect(current).not.toBeNull()
      expect(current?.projectId).toBe("test-project")
    })
  })

  describe("addExchange", () => {
    test("adds exchange to current session", async () => {
      await manager.startSession("test-project", "discovery")

      await manager.addExchange("assistant", "What problem are you solving?")
      await manager.addExchange("user", "We need better project tracking.")

      const session = manager.getCurrentSession()
      expect(session?.exchanges.length).toBe(2)
      expect(session?.exchanges[0].role).toBe("assistant")
      expect(session?.exchanges[1].role).toBe("user")
    })

    test("persists exchanges to disk", async () => {
      const session = await manager.startSession("test-project", "discovery")

      await manager.addExchange("assistant", "Hello!")

      const filePath = path.join(testDir, "interviews", `${session.id}.json`)
      const content = await fs.readFile(filePath, "utf8")
      const saved = JSON.parse(content)

      expect(saved.exchanges.length).toBe(1)
      expect(saved.exchanges[0].content).toBe("Hello!")
    })

    test("throws if no active session", async () => {
      expect(manager.addExchange("assistant", "Hello!")).rejects.toThrow(
        "No active interview session"
      )
    })
  })

  describe("completeSession", () => {
    test("marks session as completed", async () => {
      const session = await manager.startSession("test-project", "discovery")

      await manager.completeSession()

      // Load from disk to verify
      const filePath = path.join(testDir, "interviews", `${session.id}.json`)
      const content = await fs.readFile(filePath, "utf8")
      const saved = JSON.parse(content)

      expect(saved.status).toBe("completed")
    })

    test("clears current session", async () => {
      await manager.startSession("test-project", "discovery")

      await manager.completeSession()

      expect(manager.getCurrentSession()).toBeNull()
    })
  })

  describe("resumeSession", () => {
    test("resumes an active session", async () => {
      const original = await manager.startSession("test-project", "discovery")
      await manager.addExchange("assistant", "Question 1")

      // Create new manager to simulate restart
      const manager2 = new InterviewManager(testDir)
      const resumed = await manager2.resumeSession(original.id)

      expect(resumed).not.toBeNull()
      expect(resumed?.id).toBe(original.id)
      expect(resumed?.exchanges.length).toBe(1)
    })

    test("returns null for completed session", async () => {
      const original = await manager.startSession("test-project", "discovery")
      await manager.completeSession()

      const manager2 = new InterviewManager(testDir)
      const resumed = await manager2.resumeSession(original.id)

      expect(resumed).toBeNull()
    })

    test("returns null for non-existent session", async () => {
      const resumed = await manager.resumeSession("non-existent")

      expect(resumed).toBeNull()
    })
  })

  describe("listSessions", () => {
    test("lists all sessions", async () => {
      await manager.startSession("test-project", "discovery")
      await manager.completeSession()

      await manager.startSession("test-project", "refinement")
      await manager.completeSession()

      await manager.startSession("test-project", "breakdown")

      const sessions = await manager.listSessions()

      expect(sessions.length).toBe(3)
    })

    test("sorts by last updated", async () => {
      const s1 = await manager.startSession("test-project", "discovery")
      await manager.completeSession()

      // Small delay to ensure different timestamps
      await new Promise((r) => setTimeout(r, 10))

      const s2 = await manager.startSession("test-project", "refinement")

      const sessions = await manager.listSessions()

      expect(sessions[0].id).toBe(s2.id) // Most recent first
      expect(sessions[1].id).toBe(s1.id)
    })
  })

  describe("getMostRecentActiveSession", () => {
    test("returns most recent active session", async () => {
      await manager.startSession("test-project", "discovery")
      await manager.completeSession()

      const active = await manager.startSession("test-project", "refinement")

      const manager2 = new InterviewManager(testDir)
      const found = await manager2.getMostRecentActiveSession()

      expect(found?.id).toBe(active.id)
    })

    test("returns null if no active sessions", async () => {
      await manager.startSession("test-project", "discovery")
      await manager.completeSession()

      const manager2 = new InterviewManager(testDir)
      const found = await manager2.getMostRecentActiveSession()

      expect(found).toBeNull()
    })
  })

  describe("exportToMarkdown", () => {
    test("exports session as markdown", async () => {
      const session = await manager.startSession("test-project", "discovery", "requirements")
      await manager.addExchange("assistant", "What problem are you solving?")
      await manager.addExchange("user", "We need better tracking.")

      const markdown = await manager.exportToMarkdown(session.id)

      expect(markdown).toContain("# Interview: discovery")
      expect(markdown).toContain("## Topic: requirements")
      expect(markdown).toContain("**Assistant:**")
      expect(markdown).toContain("What problem are you solving?")
      expect(markdown).toContain("**User:**")
      expect(markdown).toContain("We need better tracking.")
    })
  })

  describe("getInterviewContext", () => {
    test("returns context for active session", async () => {
      await manager.startSession("test-project", "discovery", "requirements")
      await manager.addExchange("assistant", "Question 1")
      await manager.addExchange("user", "Answer 1")

      const context = manager.getInterviewContext()

      expect(context).toContain("<interview-context>")
      expect(context).toContain("discovery")
      expect(context).toContain("requirements")
      expect(context).toContain("Question 1")
      expect(context).toContain("Answer 1")
    })

    test("returns null if no active session", () => {
      const context = manager.getInterviewContext()

      expect(context).toBeNull()
    })
  })
})
