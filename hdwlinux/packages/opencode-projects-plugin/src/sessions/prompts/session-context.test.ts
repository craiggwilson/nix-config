/**
 * Tests for session context builder
 */

import { describe, test, expect, beforeEach, afterEach } from "bun:test"
import * as fs from "node:fs/promises"
import * as path from "node:path"
import * as os from "node:os"

import { SessionManager } from "../session-manager.js"
import { createMockLogger } from "../../utils/testing/index.js"
import {
  buildSessionContext,
  formatSessionContext,
  hasSessionContext,
  type SessionContext,
} from "./session-context.js"

describe("session-context", () => {
  let testDir: string
  let sessionManager: SessionManager

  beforeEach(async () => {
    testDir = await fs.mkdtemp(path.join(os.tmpdir(), "session-context-test-"))
    sessionManager = new SessionManager(testDir, createMockLogger())
    await sessionManager.load()
  })

  afterEach(async () => {
    await fs.rm(testDir, { recursive: true, force: true })
  })

  describe("buildSessionContext", () => {
    test("extracts recent sessions", async () => {
      await sessionManager.captureSession({
        sessionId: "ses_1",
        summary: "First session",
        keyPoints: ["Point 1"],
      })
      await sessionManager.captureSession({
        sessionId: "ses_2",
        summary: "Second session",
        keyPoints: ["Point 2"],
      })
      await sessionManager.captureSession({
        sessionId: "ses_3",
        summary: "Third session",
        keyPoints: ["Point 3"],
      })

      const context = await buildSessionContext(sessionManager, { recentLimit: 2 })

      expect(context.recentSessions).toHaveLength(2)
      expect(context.recentSessions[0].id).toBe("ses_3")
      expect(context.recentSessions[1].id).toBe("ses_2")
    })

    test("extracts open questions", async () => {
      await sessionManager.captureSession({
        sessionId: "ses_1",
        summary: "Session with questions",
        keyPoints: ["Point 1"],
        openQuestionsAdded: ["How to handle auth?", "What about caching?"],
      })

      const context = await buildSessionContext(sessionManager)

      expect(context.openQuestions).toContain("How to handle auth?")
      expect(context.openQuestions).toContain("What about caching?")
    })

    test("extracts pending decisions from index", async () => {
      await sessionManager.captureSession({
        sessionId: "ses_1",
        summary: "Session",
        keyPoints: ["Point 1"],
      })
      await sessionManager.updateIndex({
        pendingDecisions: ["Choose database", "Select framework"],
      })

      const context = await buildSessionContext(sessionManager)

      expect(context.pendingDecisions).toContain("Choose database")
      expect(context.pendingDecisions).toContain("Select framework")
    })

    test("extracts whats next from index", async () => {
      await sessionManager.captureSession({
        sessionId: "ses_1",
        summary: "Session",
        keyPoints: ["Point 1"],
      })
      await sessionManager.updateIndex({
        whatsNext: ["Implement feature X", "Write tests"],
      })

      const context = await buildSessionContext(sessionManager)

      expect(context.whatsNext).toContain("Implement feature X")
      expect(context.whatsNext).toContain("Write tests")
    })

    test("uses default limit of 3 recent sessions", async () => {
      for (let i = 1; i <= 5; i++) {
        await sessionManager.captureSession({
          sessionId: `ses_${i}`,
          summary: `Session ${i}`,
          keyPoints: [`Point ${i}`],
        })
      }

      const context = await buildSessionContext(sessionManager)

      expect(context.recentSessions).toHaveLength(3)
      expect(context.recentSessions[0].id).toBe("ses_5")
      expect(context.recentSessions[1].id).toBe("ses_4")
      expect(context.recentSessions[2].id).toBe("ses_3")
    })

    test("returns empty context when no sessions exist", async () => {
      const context = await buildSessionContext(sessionManager)

      expect(context.recentSessions).toEqual([])
      expect(context.openQuestions).toEqual([])
      expect(context.pendingDecisions).toEqual([])
      expect(context.whatsNext).toEqual([])
    })
  })

  describe("formatSessionContext", () => {
    test("produces valid markdown with recent sessions", () => {
      const context: SessionContext = {
        recentSessions: [
          {
            id: "ses_1",
            sequence: 1,
            filename: "001-ses_1-2026-03-02.md",
            date: "2026-03-02",
            timestamp: "2026-03-02T10:00:00.000Z",
            summary: "Completed authentication research.",
            keyPoints: ["Analyzed OAuth2", "Created diagram"],
            openQuestionsAdded: [],
            decisionsMade: [],
            artifactsCreated: [],
          },
        ],
        openQuestions: ["How to handle refresh tokens?"],
        pendingDecisions: ["Choose auth provider"],
        whatsNext: ["Implement login flow"],
      }

      const markdown = formatSessionContext(context)

      expect(markdown).toContain("## Recent Sessions")
      expect(markdown).toContain("### 2026-03-02")
      expect(markdown).toContain("Completed authentication research.")
      expect(markdown).toContain("**Key Points:**")
      expect(markdown).toContain("- Analyzed OAuth2")
      expect(markdown).toContain("- Created diagram")
      expect(markdown).toContain("## Open Questions")
      expect(markdown).toContain("- How to handle refresh tokens?")
      expect(markdown).toContain("## Pending Decisions")
      expect(markdown).toContain("- Choose auth provider")
      expect(markdown).toContain("## What's Next")
      expect(markdown).toContain("- Implement login flow")
    })

    test("omits sections when empty", () => {
      const context: SessionContext = {
        recentSessions: [
          {
            id: "ses_1",
            sequence: 1,
            filename: "001-ses_1-2026-03-02.md",
            date: "2026-03-02",
            timestamp: "2026-03-02T10:00:00.000Z",
            summary: "Simple session.",
            keyPoints: [],
            openQuestionsAdded: [],
            decisionsMade: [],
            artifactsCreated: [],
          },
        ],
        openQuestions: [],
        pendingDecisions: [],
        whatsNext: [],
      }

      const markdown = formatSessionContext(context)

      expect(markdown).toContain("## Recent Sessions")
      expect(markdown).not.toContain("## Open Questions")
      expect(markdown).not.toContain("## Pending Decisions")
      expect(markdown).not.toContain("## What's Next")
    })

    test("returns empty string when no context", () => {
      const context: SessionContext = {
        recentSessions: [],
        openQuestions: [],
        pendingDecisions: [],
        whatsNext: [],
      }

      const markdown = formatSessionContext(context)

      expect(markdown).toBe("")
    })

    test("formats multiple sessions correctly", () => {
      const context: SessionContext = {
        recentSessions: [
          {
            id: "ses_2",
            sequence: 2,
            filename: "002-ses_2-2026-03-02.md",
            date: "2026-03-02",
            timestamp: "2026-03-02T11:00:00.000Z",
            summary: "Second session.",
            keyPoints: ["Point A"],
            openQuestionsAdded: [],
            decisionsMade: [],
            artifactsCreated: [],
          },
          {
            id: "ses_1",
            sequence: 1,
            filename: "001-ses_1-2026-03-01.md",
            date: "2026-03-01",
            timestamp: "2026-03-01T10:00:00.000Z",
            summary: "First session.",
            keyPoints: ["Point B"],
            openQuestionsAdded: [],
            decisionsMade: [],
            artifactsCreated: [],
          },
        ],
        openQuestions: [],
        pendingDecisions: [],
        whatsNext: [],
      }

      const markdown = formatSessionContext(context)

      expect(markdown).toContain("### 2026-03-02")
      expect(markdown).toContain("### 2026-03-01")
      const pos2 = markdown.indexOf("2026-03-02")
      const pos1 = markdown.indexOf("2026-03-01")
      expect(pos2).toBeLessThan(pos1)
    })
  })

  describe("hasSessionContext", () => {
    test("returns true when recent sessions exist", () => {
      const context: SessionContext = {
        recentSessions: [
          {
            id: "ses_1",
            sequence: 1,
            filename: "001-ses_1-2026-03-02.md",
            date: "2026-03-02",
            timestamp: "2026-03-02T10:00:00.000Z",
            summary: "Session.",
            keyPoints: [],
            openQuestionsAdded: [],
            decisionsMade: [],
            artifactsCreated: [],
          },
        ],
        openQuestions: [],
        pendingDecisions: [],
        whatsNext: [],
      }

      expect(hasSessionContext(context)).toBe(true)
    })

    test("returns true when open questions exist", () => {
      const context: SessionContext = {
        recentSessions: [],
        openQuestions: ["Question?"],
        pendingDecisions: [],
        whatsNext: [],
      }

      expect(hasSessionContext(context)).toBe(true)
    })

    test("returns true when pending decisions exist", () => {
      const context: SessionContext = {
        recentSessions: [],
        openQuestions: [],
        pendingDecisions: ["Decision"],
        whatsNext: [],
      }

      expect(hasSessionContext(context)).toBe(true)
    })

    test("returns true when whats next exists", () => {
      const context: SessionContext = {
        recentSessions: [],
        openQuestions: [],
        pendingDecisions: [],
        whatsNext: ["Next step"],
      }

      expect(hasSessionContext(context)).toBe(true)
    })

    test("returns false when empty", () => {
      const context: SessionContext = {
        recentSessions: [],
        openQuestions: [],
        pendingDecisions: [],
        whatsNext: [],
      }

      expect(hasSessionContext(context)).toBe(false)
    })
  })
})
