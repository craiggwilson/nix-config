/**
 * Tests for SessionManager
 */

import { describe, test, expect, beforeEach, afterEach } from "bun:test"
import * as fs from "node:fs/promises"
import * as path from "node:path"
import * as os from "node:os"

import { SessionManager, type SessionIndex, type SessionSummary } from "./session-manager.js"
import { createMockLogger } from "../utils/testing/index.js"

describe("SessionManager", () => {
  let testDir: string
  let manager: SessionManager

  beforeEach(async () => {
    testDir = await fs.mkdtemp(path.join(os.tmpdir(), "session-manager-test-"))
    manager = new SessionManager(testDir, createMockLogger())
  })

  afterEach(async () => {
    await fs.rm(testDir, { recursive: true, force: true })
  })

  describe("load", () => {
    test("creates empty index if directory doesn't exist", async () => {
      const index = await manager.load()

      expect(index.sessions).toEqual([])
      expect(index.openQuestions).toEqual([])
      expect(index.pendingDecisions).toEqual([])
      expect(index.whatsNext).toEqual([])
    })

    test("loads existing index from file", async () => {
      const sessionsDir = path.join(testDir, "sessions")
      await fs.mkdir(sessionsDir, { recursive: true })

      const existingIndex = `# Session History

## Open Questions
- How to handle token refresh?
- What about offline mode?

## Pending Decisions
- Choose between OAuth2 and SAML

## What's Next
- Implement authentication flow

---

## Sessions

### 001-ses_abc123-2026-03-01
**Summary:** Completed initial research on authentication patterns.

**Key Points:**
- Analyzed OAuth2 vs SAML
- Created architecture diagram

**Link:** [Full session](./001-ses_abc123-2026-03-01.md)

---

`
      await fs.writeFile(path.join(sessionsDir, "index.md"), existingIndex)

      const index = await manager.load()

      expect(index.openQuestions).toEqual([
        "How to handle token refresh?",
        "What about offline mode?",
      ])
      expect(index.pendingDecisions).toEqual(["Choose between OAuth2 and SAML"])
      expect(index.whatsNext).toEqual(["Implement authentication flow"])
      expect(index.sessions).toHaveLength(1)
      expect(index.sessions[0].id).toBe("ses_abc123")
      expect(index.sessions[0].sequence).toBe(1)
      expect(index.sessions[0].date).toBe("2026-03-01")
    })

    test("creates sessions directory on first use", async () => {
      await manager.load()

      await manager.captureSession({
        sessionId: "ses_test123",
        summary: "Test session",
        keyPoints: ["Point 1"],
      })

      const sessionsDir = path.join(testDir, "sessions")
      const stat = await fs.stat(sessionsDir)
      expect(stat.isDirectory()).toBe(true)
    })
  })

  describe("captureSession", () => {
    beforeEach(async () => {
      await manager.load()
    })

    test("captures session with all fields", async () => {
      const result = await manager.captureSession({
        sessionId: "ses_full123",
        summary: "Completed authentication research and made key decisions.",
        keyPoints: [
          "Analyzed OAuth2 vs SAML for enterprise SSO",
          "Decided on OAuth2 with PKCE for mobile support",
          "Created architecture diagram",
        ],
        openQuestionsAdded: ["How to handle token refresh in offline mode?"],
        decisionsMade: ["[OAuth2 with PKCE](../decisions/auth-protocol.md)"],
        artifactsCreated: ["research-auth-patterns-abc123"],
      })

      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(result.value.id).toBe("ses_full123")
        expect(result.value.summary).toBe(
          "Completed authentication research and made key decisions."
        )
        expect(result.value.keyPoints).toHaveLength(3)
        expect(result.value.openQuestionsAdded).toEqual([
          "How to handle token refresh in offline mode?",
        ])
        expect(result.value.decisionsMade).toEqual([
          "[OAuth2 with PKCE](../decisions/auth-protocol.md)",
        ])
        expect(result.value.artifactsCreated).toEqual(["research-auth-patterns-abc123"])
      }
    })

    test("generates correct filename format {seq}-{sessionId}-{date}.md", async () => {
      const result = await manager.captureSession({
        sessionId: "ses_abc123",
        summary: "Test session",
        keyPoints: ["Point 1"],
      })

      expect(result.ok).toBe(true)
      if (result.ok) {
        const today = new Date().toISOString().split("T")[0]
        expect(result.value.filename).toBe(`001-ses_abc123-${today}.md`)
      }
    })

    test("increments sequence number correctly", async () => {
      const result1 = await manager.captureSession({
        sessionId: "ses_first",
        summary: "First session",
        keyPoints: ["Point 1"],
      })

      const result2 = await manager.captureSession({
        sessionId: "ses_second",
        summary: "Second session",
        keyPoints: ["Point 2"],
      })

      const result3 = await manager.captureSession({
        sessionId: "ses_third",
        summary: "Third session",
        keyPoints: ["Point 3"],
      })

      expect(result1.ok).toBe(true)
      expect(result2.ok).toBe(true)
      expect(result3.ok).toBe(true)

      if (result1.ok && result2.ok && result3.ok) {
        expect(result1.value.sequence).toBe(1)
        expect(result2.value.sequence).toBe(2)
        expect(result3.value.sequence).toBe(3)
        expect(result1.value.filename).toMatch(/^001-/)
        expect(result2.value.filename).toMatch(/^002-/)
        expect(result3.value.filename).toMatch(/^003-/)
      }
    })

    test("writes session file with correct format", async () => {
      const result = await manager.captureSession({
        sessionId: "ses_format123",
        summary: "Test session for format verification.",
        keyPoints: ["First key point", "Second key point"],
        openQuestionsAdded: ["Question 1?"],
        decisionsMade: ["Decision 1"],
        artifactsCreated: ["artifact-1"],
      })

      expect(result.ok).toBe(true)
      if (!result.ok) return

      const sessionPath = path.join(testDir, "sessions", result.value.filename)
      const content = await fs.readFile(sessionPath, "utf-8")

      expect(content).toContain("# Session:")
      expect(content).toContain("**Session ID:** ses_format123")
      expect(content).toContain("**Timestamp:**")
      expect(content).toContain("## Summary")
      expect(content).toContain("Test session for format verification.")
      expect(content).toContain("## Key Points")
      expect(content).toContain("- First key point")
      expect(content).toContain("- Second key point")
      expect(content).toContain("## Open Questions Added")
      expect(content).toContain("- Question 1?")
      expect(content).toContain("## Decisions Made")
      expect(content).toContain("- Decision 1")
      expect(content).toContain("## Artifacts Created")
      expect(content).toContain("- artifact-1")
    })

    test("prepends to index (most recent first)", async () => {
      await manager.captureSession({
        sessionId: "ses_first",
        summary: "First session",
        keyPoints: ["Point 1"],
      })

      await manager.captureSession({
        sessionId: "ses_second",
        summary: "Second session",
        keyPoints: ["Point 2"],
      })

      await manager.captureSession({
        sessionId: "ses_third",
        summary: "Third session",
        keyPoints: ["Point 3"],
      })

      const sessions = manager.getRecentSessions(10)

      expect(sessions).toHaveLength(3)
      expect(sessions[0].id).toBe("ses_third")
      expect(sessions[1].id).toBe("ses_second")
      expect(sessions[2].id).toBe("ses_first")
    })

    test("returns error for duplicate session ID", async () => {
      await manager.captureSession({
        sessionId: "ses_duplicate",
        summary: "First capture",
        keyPoints: ["Point 1"],
      })

      const result = await manager.captureSession({
        sessionId: "ses_duplicate",
        summary: "Second capture",
        keyPoints: ["Point 2"],
      })

      expect(result.ok).toBe(false)
      if (!result.ok && result.error.type === "already_exists") {
        expect(result.error.sessionId).toBe("ses_duplicate")
      }
    })

    test("accumulates open questions from sessions", async () => {
      await manager.captureSession({
        sessionId: "ses_q1",
        summary: "Session 1",
        keyPoints: ["Point 1"],
        openQuestionsAdded: ["Question 1?", "Question 2?"],
      })

      await manager.captureSession({
        sessionId: "ses_q2",
        summary: "Session 2",
        keyPoints: ["Point 2"],
        openQuestionsAdded: ["Question 3?"],
      })

      const newManager = new SessionManager(testDir, createMockLogger())
      const index = await newManager.load()

      expect(index.openQuestions).toContain("Question 1?")
      expect(index.openQuestions).toContain("Question 2?")
      expect(index.openQuestions).toContain("Question 3?")
    })

    test("does not duplicate existing open questions", async () => {
      await manager.captureSession({
        sessionId: "ses_dup1",
        summary: "Session 1",
        keyPoints: ["Point 1"],
        openQuestionsAdded: ["Same question?"],
      })

      await manager.captureSession({
        sessionId: "ses_dup2",
        summary: "Session 2",
        keyPoints: ["Point 2"],
        openQuestionsAdded: ["Same question?"],
      })

      const newManager = new SessionManager(testDir, createMockLogger())
      const index = await newManager.load()

      const count = index.openQuestions.filter((q) => q === "Same question?").length
      expect(count).toBe(1)
    })

    test("handles optional fields gracefully", async () => {
      const result = await manager.captureSession({
        sessionId: "ses_minimal",
        summary: "Minimal session",
        keyPoints: ["Only key point"],
      })

      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(result.value.openQuestionsAdded).toEqual([])
        expect(result.value.decisionsMade).toEqual([])
        expect(result.value.artifactsCreated).toEqual([])
      }
    })
  })

  describe("updateIndex", () => {
    beforeEach(async () => {
      await manager.load()
      await manager.captureSession({
        sessionId: "ses_existing",
        summary: "Existing session",
        keyPoints: ["Point 1"],
        openQuestionsAdded: ["Original question?"],
      })
    })

    test("updates open questions", async () => {
      await manager.updateIndex({
        openQuestions: ["New question 1?", "New question 2?"],
      })

      const newManager = new SessionManager(testDir, createMockLogger())
      const index = await newManager.load()

      expect(index.openQuestions).toEqual(["New question 1?", "New question 2?"])
    })

    test("updates pending decisions", async () => {
      await manager.updateIndex({
        pendingDecisions: ["Decision A", "Decision B"],
      })

      const newManager = new SessionManager(testDir, createMockLogger())
      const index = await newManager.load()

      expect(index.pendingDecisions).toEqual(["Decision A", "Decision B"])
    })

    test("updates what's next", async () => {
      await manager.updateIndex({
        whatsNext: ["Next step 1", "Next step 2"],
      })

      const newManager = new SessionManager(testDir, createMockLogger())
      const index = await newManager.load()

      expect(index.whatsNext).toEqual(["Next step 1", "Next step 2"])
    })

    test("preserves existing sessions when updating index", async () => {
      await manager.updateIndex({
        openQuestions: ["Updated question?"],
        pendingDecisions: ["Updated decision"],
        whatsNext: ["Updated next step"],
      })

      const newManager = new SessionManager(testDir, createMockLogger())
      const index = await newManager.load()

      expect(index.sessions).toHaveLength(1)
      expect(index.sessions[0].id).toBe("ses_existing")
    })

    test("allows partial updates", async () => {
      await manager.updateIndex({
        pendingDecisions: ["Only updating decisions"],
      })

      const newManager = new SessionManager(testDir, createMockLogger())
      const index = await newManager.load()

      expect(index.pendingDecisions).toEqual(["Only updating decisions"])
      expect(index.openQuestions).toContain("Original question?")
    })
  })

  describe("getRecentSessions", () => {
    beforeEach(async () => {
      await manager.load()
    })

    test("returns n most recent sessions", async () => {
      for (let i = 1; i <= 5; i++) {
        await manager.captureSession({
          sessionId: `ses_${i}`,
          summary: `Session ${i}`,
          keyPoints: [`Point ${i}`],
        })
      }

      const recent = manager.getRecentSessions(3)

      expect(recent).toHaveLength(3)
      expect(recent[0].id).toBe("ses_5")
      expect(recent[1].id).toBe("ses_4")
      expect(recent[2].id).toBe("ses_3")
    })

    test("respects limit when fewer sessions exist", async () => {
      await manager.captureSession({
        sessionId: "ses_only",
        summary: "Only session",
        keyPoints: ["Point 1"],
      })

      const recent = manager.getRecentSessions(10)

      expect(recent).toHaveLength(1)
      expect(recent[0].id).toBe("ses_only")
    })

    test("returns empty array when no sessions", () => {
      const recent = manager.getRecentSessions(5)

      expect(recent).toEqual([])
    })

    test("returns all sessions when limit exceeds count", async () => {
      await manager.captureSession({
        sessionId: "ses_1",
        summary: "Session 1",
        keyPoints: ["Point 1"],
      })
      await manager.captureSession({
        sessionId: "ses_2",
        summary: "Session 2",
        keyPoints: ["Point 2"],
      })

      const recent = manager.getRecentSessions(100)

      expect(recent).toHaveLength(2)
    })
  })

  describe("formatSessionFile", () => {
    beforeEach(async () => {
      await manager.load()
    })

    test("produces valid markdown with all sections", () => {
      const summary: SessionSummary = {
        id: "ses_format",
        sequence: 1,
        filename: "001-ses_format-2026-03-02.md",
        date: "2026-03-02",
        timestamp: "2026-03-02T10:30:00.000Z",
        summary: "Test session summary.",
        keyPoints: ["Key point 1", "Key point 2"],
        openQuestionsAdded: ["Question 1?"],
        decisionsMade: ["Decision 1"],
        artifactsCreated: ["artifact-1"],
      }

      const content = manager.formatSessionFile(summary)

      expect(content).toContain("# Session: 2026-03-02")
      expect(content).toContain("**Session ID:** ses_format")
      expect(content).toContain("**Timestamp:** 2026-03-02T10:30:00.000Z")
      expect(content).toContain("## Summary")
      expect(content).toContain("Test session summary.")
      expect(content).toContain("## Key Points")
      expect(content).toContain("- Key point 1")
      expect(content).toContain("- Key point 2")
      expect(content).toContain("## Open Questions Added")
      expect(content).toContain("- Question 1?")
      expect(content).toContain("## Decisions Made")
      expect(content).toContain("- Decision 1")
      expect(content).toContain("## Artifacts Created")
      expect(content).toContain("- artifact-1")
    })

    test("omits empty optional sections", () => {
      const summary: SessionSummary = {
        id: "ses_minimal",
        sequence: 1,
        filename: "001-ses_minimal-2026-03-02.md",
        date: "2026-03-02",
        timestamp: "2026-03-02T10:30:00.000Z",
        summary: "Minimal session.",
        keyPoints: ["Only key point"],
        openQuestionsAdded: [],
        decisionsMade: [],
        artifactsCreated: [],
      }

      const content = manager.formatSessionFile(summary)

      expect(content).toContain("## Summary")
      expect(content).toContain("## Key Points")
      expect(content).not.toContain("## Open Questions Added")
      expect(content).not.toContain("## Decisions Made")
      expect(content).not.toContain("## Artifacts Created")
    })
  })

  describe("formatIndexFile", () => {
    beforeEach(async () => {
      await manager.load()
    })

    test("produces valid markdown with all sections", () => {
      const index: SessionIndex = {
        openQuestions: ["Question 1?", "Question 2?"],
        pendingDecisions: ["Decision A"],
        whatsNext: ["Next step 1"],
        sessions: [
          {
            id: "ses_1",
            sequence: 1,
            filename: "001-ses_1-2026-03-02.md",
            date: "2026-03-02",
            timestamp: "2026-03-02T10:00:00.000Z",
            summary: "First session summary.",
            keyPoints: ["Point 1", "Point 2"],
            openQuestionsAdded: [],
            decisionsMade: [],
            artifactsCreated: [],
          },
        ],
      }

      const content = manager.formatIndexFile(index)

      expect(content).toContain("# Session History")
      expect(content).toContain("## Open Questions")
      expect(content).toContain("- Question 1?")
      expect(content).toContain("- Question 2?")
      expect(content).toContain("## Pending Decisions")
      expect(content).toContain("- Decision A")
      expect(content).toContain("## What's Next")
      expect(content).toContain("- Next step 1")
      expect(content).toContain("## Sessions")
      expect(content).toContain("### 001-ses_1-2026-03-02")
      expect(content).toContain("**Summary:** First session summary.")
      expect(content).toContain("**Key Points:**")
      expect(content).toContain("- Point 1")
      expect(content).toContain("- Point 2")
      expect(content).toContain("**Link:** [Full session](./001-ses_1-2026-03-02.md)")
    })

    test("shows placeholder text for empty sections", () => {
      const index: SessionIndex = {
        openQuestions: [],
        pendingDecisions: [],
        whatsNext: [],
        sessions: [],
      }

      const content = manager.formatIndexFile(index)

      expect(content).toContain("*No open questions*")
      expect(content).toContain("*No pending decisions*")
      expect(content).toContain("*No next steps defined*")
    })

    test("formats multiple sessions correctly", () => {
      const index: SessionIndex = {
        openQuestions: [],
        pendingDecisions: [],
        whatsNext: [],
        sessions: [
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
      }

      const content = manager.formatIndexFile(index)

      expect(content).toContain("### 002-ses_2-2026-03-02")
      expect(content).toContain("### 001-ses_1-2026-03-01")
      // Most recent should appear first
      const pos2 = content.indexOf("002-ses_2")
      const pos1 = content.indexOf("001-ses_1")
      expect(pos2).toBeLessThan(pos1)
    })
  })

  describe("persistence across instances", () => {
    test("new manager instance loads previously saved sessions", async () => {
      await manager.load()
      await manager.captureSession({
        sessionId: "ses_persist",
        summary: "Persistent session",
        keyPoints: ["Point 1"],
        openQuestionsAdded: ["Persistent question?"],
      })

      const newManager = new SessionManager(testDir, createMockLogger())
      const index = await newManager.load()

      expect(index.sessions).toHaveLength(1)
      expect(index.sessions[0].id).toBe("ses_persist")
      expect(index.openQuestions).toContain("Persistent question?")
    })

    test("sequence numbers continue correctly after reload", async () => {
      await manager.load()
      await manager.captureSession({
        sessionId: "ses_1",
        summary: "Session 1",
        keyPoints: ["Point 1"],
      })
      await manager.captureSession({
        sessionId: "ses_2",
        summary: "Session 2",
        keyPoints: ["Point 2"],
      })

      const newManager = new SessionManager(testDir, createMockLogger())
      await newManager.load()
      const result = await newManager.captureSession({
        sessionId: "ses_3",
        summary: "Session 3",
        keyPoints: ["Point 3"],
      })

      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(result.value.sequence).toBe(3)
        expect(result.value.filename).toMatch(/^003-/)
      }
    })
  })

  describe("getNextSequence", () => {
    test("returns 1 for empty index", async () => {
      await manager.load()

      const seq = await manager.getNextSequence()

      expect(seq).toBe(1)
    })

    test("returns max sequence + 1", async () => {
      await manager.load()
      await manager.captureSession({
        sessionId: "ses_1",
        summary: "Session 1",
        keyPoints: ["Point 1"],
      })
      await manager.captureSession({
        sessionId: "ses_2",
        summary: "Session 2",
        keyPoints: ["Point 2"],
      })

      const seq = await manager.getNextSequence()

      expect(seq).toBe(3)
    })
  })
})
