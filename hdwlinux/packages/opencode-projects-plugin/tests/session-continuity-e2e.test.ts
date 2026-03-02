/**
 * E2E tests for session continuity across multiple sessions
 *
 * Tests the complete session lifecycle including:
 * - Session capture on compaction
 * - Multi-session accumulation
 * - Focus context injection after multiple sessions
 * - Open question accumulation and resolution
 * - Session index ordering
 *
 * Verifies actual file contents on disk, not just in-memory state.
 */

import { describe, test, expect, beforeEach, afterEach, afterAll } from "bun:test"
import * as fs from "node:fs/promises"
import * as path from "node:path"

import {
  createIntegrationFixture,
  cleanupTestDirectories,
  type IntegrationTestFixture,
} from "./integration-test-utils.js"
import { SessionManager } from "../src/sessions/index.js"
import {
  buildSessionContext,
  formatSessionContext,
  hasSessionContext,
} from "../src/sessions/prompts/session-context.js"
import { buildFocusContext } from "../src/projects/prompts/focus-context.js"
import { createMockLogger } from "../src/utils/testing/index.js"

describe("Session Continuity E2E", () => {
  let fixture: IntegrationTestFixture
  let sessionManager: SessionManager
  let projectDir: string
  let projectId: string

  beforeEach(async () => {
    fixture = await createIntegrationFixture()

    // Create a project with local storage
    const project = await fixture.projectManager.createProject({
      name: "Session Continuity E2E Test",
      storage: "local",
      description: "Testing session continuity across multiple sessions",
    })
    projectDir = project.projectDir
    projectId = project.projectId

    // Initialize session manager
    const log = createMockLogger()
    sessionManager = new SessionManager(projectDir, log)
    await sessionManager.load()
  })

  afterEach(async () => {
    await fixture.cleanup()
  })

  afterAll(async () => {
    await cleanupTestDirectories("opencode-integration-test-")
  })

  describe("Scenario 1: Session capture on compaction", () => {
    test("session file is written to projectDir/sessions/", async () => {
      const result = await sessionManager.captureSession({
        sessionId: "ses_compaction_test_1",
        summary: "Completed initial project setup and research.",
        keyPoints: [
          "Analyzed authentication patterns",
          "Created initial design document",
          "Identified key stakeholders",
        ],
        openQuestionsAdded: ["How to handle token refresh?"],
        decisionsMade: ["Use OAuth2 with PKCE"],
        artifactsCreated: ["research-auth-patterns-abc123"],
      })

      expect(result.ok).toBe(true)
      if (!result.ok) return

      // Verify session file exists on disk
      const sessionsDir = path.join(projectDir, "sessions")
      const files = await fs.readdir(sessionsDir)
      const sessionFile = files.find((f) => f.includes("ses_compaction_test_1"))
      expect(sessionFile).toBeDefined()
      expect(sessionFile).toMatch(/^001-ses_compaction_test_1-\d{4}-\d{2}-\d{2}\.md$/)

      // Verify session file content
      const sessionContent = await fs.readFile(
        path.join(sessionsDir, sessionFile!),
        "utf-8"
      )
      expect(sessionContent).toContain("# Session:")
      expect(sessionContent).toContain("**Session ID:** ses_compaction_test_1")
      expect(sessionContent).toContain("## Summary")
      expect(sessionContent).toContain("Completed initial project setup and research.")
      expect(sessionContent).toContain("## Key Points")
      expect(sessionContent).toContain("- Analyzed authentication patterns")
      expect(sessionContent).toContain("- Created initial design document")
      expect(sessionContent).toContain("- Identified key stakeholders")
      expect(sessionContent).toContain("## Open Questions Added")
      expect(sessionContent).toContain("- How to handle token refresh?")
      expect(sessionContent).toContain("## Decisions Made")
      expect(sessionContent).toContain("- Use OAuth2 with PKCE")
      expect(sessionContent).toContain("## Artifacts Created")
      expect(sessionContent).toContain("- research-auth-patterns-abc123")
    })

    test("session index (sessions/index.md) is created/updated", async () => {
      await sessionManager.captureSession({
        sessionId: "ses_index_test_1",
        summary: "First session for index test.",
        keyPoints: ["Point 1", "Point 2"],
        openQuestionsAdded: ["Question 1?"],
      })

      // Verify index file exists
      const indexPath = path.join(projectDir, "sessions", "index.md")
      const indexExists = await fs
        .access(indexPath)
        .then(() => true)
        .catch(() => false)
      expect(indexExists).toBe(true)

      // Verify index content
      const indexContent = await fs.readFile(indexPath, "utf-8")
      expect(indexContent).toContain("# Session History")
      expect(indexContent).toContain("## Open Questions")
      expect(indexContent).toContain("- Question 1?")
      expect(indexContent).toContain("## Sessions")
      expect(indexContent).toContain("ses_index_test_1")
      expect(indexContent).toContain("First session for index test.")
    })

    test("session file contains all required fields", async () => {
      const result = await sessionManager.captureSession({
        sessionId: "ses_fields_test",
        summary: "Testing all session fields are captured.",
        keyPoints: ["Key point 1", "Key point 2", "Key point 3"],
        openQuestionsAdded: ["Open question 1?", "Open question 2?"],
        decisionsMade: ["Decision 1", "Decision 2"],
        artifactsCreated: ["artifact-1", "artifact-2"],
      })

      expect(result.ok).toBe(true)
      if (!result.ok) return

      const sessionsDir = path.join(projectDir, "sessions")
      const files = await fs.readdir(sessionsDir)
      const sessionFile = files.find((f) => f.includes("ses_fields_test"))

      const content = await fs.readFile(path.join(sessionsDir, sessionFile!), "utf-8")

      // Verify all sections are present
      expect(content).toContain("## Summary")
      expect(content).toContain("## Key Points")
      expect(content).toContain("## Open Questions Added")
      expect(content).toContain("## Decisions Made")
      expect(content).toContain("## Artifacts Created")

      // Verify timestamp is present
      expect(content).toContain("**Timestamp:**")
    })
  })

  describe("Scenario 2: Multi-session accumulation", () => {
    test("new session is prepended to index (most-recent-first)", async () => {
      // Capture first session
      await sessionManager.captureSession({
        sessionId: "ses_multi_1",
        summary: "First session in multi-session test.",
        keyPoints: ["First session point"],
      })

      // Capture second session
      await sessionManager.captureSession({
        sessionId: "ses_multi_2",
        summary: "Second session in multi-session test.",
        keyPoints: ["Second session point"],
      })

      // Verify order in index
      const indexPath = path.join(projectDir, "sessions", "index.md")
      const indexContent = await fs.readFile(indexPath, "utf-8")

      // Second session should appear before first in the file
      const session2Pos = indexContent.indexOf("ses_multi_2")
      const session1Pos = indexContent.indexOf("ses_multi_1")
      expect(session2Pos).toBeLessThan(session1Pos)

      // Verify in-memory order
      const sessions = sessionManager.getRecentSessions(10)
      expect(sessions[0].id).toBe("ses_multi_2")
      expect(sessions[1].id).toBe("ses_multi_1")
    })

    test("open questions from session 1 are still present in index after session 2", async () => {
      // Session 1 adds questions
      await sessionManager.captureSession({
        sessionId: "ses_q_accum_1",
        summary: "Session 1 with questions.",
        keyPoints: ["Point 1"],
        openQuestionsAdded: ["Question from session 1?", "Another question from session 1?"],
      })

      // Session 2 adds more questions
      await sessionManager.captureSession({
        sessionId: "ses_q_accum_2",
        summary: "Session 2 with more questions.",
        keyPoints: ["Point 2"],
        openQuestionsAdded: ["Question from session 2?"],
      })

      // Verify all questions are in the index
      const indexPath = path.join(projectDir, "sessions", "index.md")
      const indexContent = await fs.readFile(indexPath, "utf-8")

      expect(indexContent).toContain("Question from session 1?")
      expect(indexContent).toContain("Another question from session 1?")
      expect(indexContent).toContain("Question from session 2?")

      // Verify in-memory state
      const log = createMockLogger()
      const freshManager = new SessionManager(projectDir, log)
      const index = await freshManager.load()

      expect(index.openQuestions).toContain("Question from session 1?")
      expect(index.openQuestions).toContain("Another question from session 1?")
      expect(index.openQuestions).toContain("Question from session 2?")
      expect(index.openQuestions.length).toBe(3)
    })

    test("what's next reflects the most recent session", async () => {
      // Session 1 sets what's next
      await sessionManager.captureSession({
        sessionId: "ses_next_1",
        summary: "Session 1.",
        keyPoints: ["Point 1"],
      })
      await sessionManager.updateIndex({
        whatsNext: ["Next step from session 1", "Another step from session 1"],
      })

      // Session 2 updates what's next
      await sessionManager.captureSession({
        sessionId: "ses_next_2",
        summary: "Session 2.",
        keyPoints: ["Point 2"],
      })
      await sessionManager.updateIndex({
        whatsNext: ["Next step from session 2"],
      })

      // Verify what's next reflects session 2
      const indexPath = path.join(projectDir, "sessions", "index.md")
      const indexContent = await fs.readFile(indexPath, "utf-8")

      expect(indexContent).toContain("Next step from session 2")
      expect(indexContent).not.toContain("Next step from session 1")
    })

    test("session count increments correctly (001-, 002-, 003- prefixes)", async () => {
      // Capture 3 sessions
      await sessionManager.captureSession({
        sessionId: "ses_seq_1",
        summary: "First session.",
        keyPoints: ["Point 1"],
      })

      await sessionManager.captureSession({
        sessionId: "ses_seq_2",
        summary: "Second session.",
        keyPoints: ["Point 2"],
      })

      await sessionManager.captureSession({
        sessionId: "ses_seq_3",
        summary: "Third session.",
        keyPoints: ["Point 3"],
      })

      // Verify sequence numbers in filenames
      const sessionsDir = path.join(projectDir, "sessions")
      const files = await fs.readdir(sessionsDir)

      const session1File = files.find((f) => f.includes("ses_seq_1"))
      const session2File = files.find((f) => f.includes("ses_seq_2"))
      const session3File = files.find((f) => f.includes("ses_seq_3"))

      expect(session1File).toMatch(/^001-/)
      expect(session2File).toMatch(/^002-/)
      expect(session3File).toMatch(/^003-/)

      // Verify sequence numbers in memory
      const sessions = sessionManager.getRecentSessions(10)
      expect(sessions[0].sequence).toBe(3)
      expect(sessions[1].sequence).toBe(2)
      expect(sessions[2].sequence).toBe(1)
    })
  })

  describe("Scenario 3: Focus context injection after multiple sessions", () => {
    test("injected context includes last 2-3 session summaries (not all sessions)", async () => {
      // Create 5 sessions
      for (let i = 1; i <= 5; i++) {
        await sessionManager.captureSession({
          sessionId: `ses_focus_${i}`,
          summary: `Session ${i} summary for focus test.`,
          keyPoints: [`Point from session ${i}`],
        })
      }

      // Build session context with default limit (3)
      const context = await buildSessionContext(sessionManager, { recentLimit: 3 })

      // Should only include last 3 sessions
      expect(context.recentSessions.length).toBe(3)
      expect(context.recentSessions[0].id).toBe("ses_focus_5")
      expect(context.recentSessions[1].id).toBe("ses_focus_4")
      expect(context.recentSessions[2].id).toBe("ses_focus_3")

      // Format and verify older sessions are NOT included
      const formatted = formatSessionContext(context)
      expect(formatted).toContain("Session 5 summary")
      expect(formatted).toContain("Session 4 summary")
      expect(formatted).toContain("Session 3 summary")
      expect(formatted).not.toContain("Session 2 summary")
      expect(formatted).not.toContain("Session 1 summary")
    })

    test("injected context includes accumulated open questions from all sessions", async () => {
      // Create sessions with different open questions
      await sessionManager.captureSession({
        sessionId: "ses_oq_1",
        summary: "Session 1.",
        keyPoints: ["Point 1"],
        openQuestionsAdded: ["Question from session 1?"],
      })

      await sessionManager.captureSession({
        sessionId: "ses_oq_2",
        summary: "Session 2.",
        keyPoints: ["Point 2"],
        openQuestionsAdded: ["Question from session 2?"],
      })

      await sessionManager.captureSession({
        sessionId: "ses_oq_3",
        summary: "Session 3.",
        keyPoints: ["Point 3"],
        openQuestionsAdded: ["Question from session 3?"],
      })

      // Build context
      const context = await buildSessionContext(sessionManager)

      // All open questions should be accumulated
      expect(context.openQuestions).toContain("Question from session 1?")
      expect(context.openQuestions).toContain("Question from session 2?")
      expect(context.openQuestions).toContain("Question from session 3?")

      // Verify in formatted output
      const formatted = formatSessionContext(context)
      expect(formatted).toContain("## Open Questions")
      expect(formatted).toContain("Question from session 1?")
      expect(formatted).toContain("Question from session 2?")
      expect(formatted).toContain("Question from session 3?")
    })

    test("injected context includes pending decisions", async () => {
      await sessionManager.captureSession({
        sessionId: "ses_pd_1",
        summary: "Session with pending decisions.",
        keyPoints: ["Point 1"],
      })

      await sessionManager.updateIndex({
        pendingDecisions: ["Choose between Auth0 and Okta", "Select database provider"],
      })

      const context = await buildSessionContext(sessionManager)

      expect(context.pendingDecisions).toContain("Choose between Auth0 and Okta")
      expect(context.pendingDecisions).toContain("Select database provider")

      const formatted = formatSessionContext(context)
      expect(formatted).toContain("## Pending Decisions")
      expect(formatted).toContain("Choose between Auth0 and Okta")
    })

    test("injected context includes what's next from most recent session", async () => {
      await sessionManager.captureSession({
        sessionId: "ses_wn_1",
        summary: "Session 1.",
        keyPoints: ["Point 1"],
      })

      await sessionManager.updateIndex({
        whatsNext: ["Implement authentication", "Write tests", "Deploy to staging"],
      })

      const context = await buildSessionContext(sessionManager)

      expect(context.whatsNext).toContain("Implement authentication")
      expect(context.whatsNext).toContain("Write tests")
      expect(context.whatsNext).toContain("Deploy to staging")

      const formatted = formatSessionContext(context)
      expect(formatted).toContain("## What's Next")
      expect(formatted).toContain("Implement authentication")
    })

    test("older sessions are NOT included in injected context (truncation works)", async () => {
      // Create 10 sessions
      for (let i = 1; i <= 10; i++) {
        await sessionManager.captureSession({
          sessionId: `ses_trunc_${i}`,
          summary: `Session ${i} summary.`,
          keyPoints: [`Point from session ${i}`],
        })
      }

      // Build context with limit of 2
      const context = await buildSessionContext(sessionManager, { recentLimit: 2 })

      expect(context.recentSessions.length).toBe(2)
      expect(context.recentSessions[0].id).toBe("ses_trunc_10")
      expect(context.recentSessions[1].id).toBe("ses_trunc_9")

      // Verify sessions 1-8 are not in the context
      const formatted = formatSessionContext(context)
      expect(formatted).toContain("Session 10 summary")
      expect(formatted).toContain("Session 9 summary")
      expect(formatted).not.toContain("Session 8 summary")
      expect(formatted).not.toContain("Session 1 summary")
    })

    test("focus context via buildFocusContext includes session data", async () => {
      // Capture sessions
      await sessionManager.captureSession({
        sessionId: "ses_focus_ctx_1",
        summary: "First session for focus context test.",
        keyPoints: ["Analyzed requirements"],
        openQuestionsAdded: ["How to handle edge cases?"],
      })

      await sessionManager.captureSession({
        sessionId: "ses_focus_ctx_2",
        summary: "Second session for focus context test.",
        keyPoints: ["Implemented core logic"],
      })

      await sessionManager.updateIndex({
        pendingDecisions: ["Choose testing framework"],
        whatsNext: ["Write unit tests"],
      })

      // Build focus context through ProjectManager
      fixture.projectManager.setFocus(projectId)
      const focusContext = await buildFocusContext(fixture.projectManager)

      // Verify session context is included
      expect(focusContext).toContain("Recent Sessions")
      expect(focusContext).toContain("Second session for focus context test")
      expect(focusContext).toContain("Open Questions")
      expect(focusContext).toContain("How to handle edge cases?")
      expect(focusContext).toContain("Pending Decisions")
      expect(focusContext).toContain("Choose testing framework")
      expect(focusContext).toContain("What's Next")
      expect(focusContext).toContain("Write unit tests")
    })
  })

  describe("Scenario 4: Open question accumulation across sessions", () => {
    test("add open questions in session 1", async () => {
      await sessionManager.captureSession({
        sessionId: "ses_oq_add_1",
        summary: "Session adding questions.",
        keyPoints: ["Identified questions"],
        openQuestionsAdded: ["Question A?", "Question B?", "Question C?"],
      })

      const index = await sessionManager.load()
      expect(index.openQuestions).toContain("Question A?")
      expect(index.openQuestions).toContain("Question B?")
      expect(index.openQuestions).toContain("Question C?")
      expect(index.openQuestions.length).toBe(3)
    })

    test("resolve some questions in session 2, add new ones", async () => {
      // Session 1: Add questions
      await sessionManager.captureSession({
        sessionId: "ses_resolve_1",
        summary: "Session 1 with questions.",
        keyPoints: ["Point 1"],
        openQuestionsAdded: ["Question A?", "Question B?", "Question C?"],
      })

      // Session 2: Resolve Question B, add Question D
      await sessionManager.captureSession({
        sessionId: "ses_resolve_2",
        summary: "Session 2 resolving and adding questions.",
        keyPoints: ["Resolved Question B"],
        openQuestionsAdded: ["Question D?"],
      })

      // Resolve Question B by updating the index with filtered list
      const currentIndex = await sessionManager.load()
      const resolvedQuestions = currentIndex.openQuestions.filter(
        (q) => q !== "Question B?"
      )
      await sessionManager.updateIndex({ openQuestions: resolvedQuestions })

      // Verify resolved question is removed
      const updatedIndex = await sessionManager.load()
      expect(updatedIndex.openQuestions).toContain("Question A?")
      expect(updatedIndex.openQuestions).not.toContain("Question B?")
      expect(updatedIndex.openQuestions).toContain("Question C?")
      expect(updatedIndex.openQuestions).toContain("Question D?")
      expect(updatedIndex.openQuestions.length).toBe(3)

      // Verify on disk
      const indexPath = path.join(projectDir, "sessions", "index.md")
      const indexContent = await fs.readFile(indexPath, "utf-8")
      expect(indexContent).toContain("Question A?")
      expect(indexContent).not.toContain("Question B?")
      expect(indexContent).toContain("Question C?")
      expect(indexContent).toContain("Question D?")
    })

    test("duplicate questions are not added", async () => {
      // Session 1: Add questions
      await sessionManager.captureSession({
        sessionId: "ses_dup_1",
        summary: "Session 1.",
        keyPoints: ["Point 1"],
        openQuestionsAdded: ["Unique question?", "Duplicate question?"],
      })

      // Session 2: Try to add duplicate
      await sessionManager.captureSession({
        sessionId: "ses_dup_2",
        summary: "Session 2.",
        keyPoints: ["Point 2"],
        openQuestionsAdded: ["Duplicate question?", "New question?"],
      })

      const index = await sessionManager.load()
      const duplicateCount = index.openQuestions.filter(
        (q) => q === "Duplicate question?"
      ).length
      expect(duplicateCount).toBe(1)
      expect(index.openQuestions.length).toBe(3)
    })
  })

  describe("Scenario 5: Session index ordering", () => {
    test("create 3+ sessions and verify index lists them most-recent-first", async () => {
      // Create sessions with small delays to ensure different timestamps
      await sessionManager.captureSession({
        sessionId: "ses_order_1",
        summary: "First session.",
        keyPoints: ["Point 1"],
      })

      await sessionManager.captureSession({
        sessionId: "ses_order_2",
        summary: "Second session.",
        keyPoints: ["Point 2"],
      })

      await sessionManager.captureSession({
        sessionId: "ses_order_3",
        summary: "Third session.",
        keyPoints: ["Point 3"],
      })

      await sessionManager.captureSession({
        sessionId: "ses_order_4",
        summary: "Fourth session.",
        keyPoints: ["Point 4"],
      })

      // Verify in-memory order
      const sessions = sessionManager.getRecentSessions(10)
      expect(sessions.length).toBe(4)
      expect(sessions[0].id).toBe("ses_order_4")
      expect(sessions[1].id).toBe("ses_order_3")
      expect(sessions[2].id).toBe("ses_order_2")
      expect(sessions[3].id).toBe("ses_order_1")

      // Verify order in index file
      const indexPath = path.join(projectDir, "sessions", "index.md")
      const indexContent = await fs.readFile(indexPath, "utf-8")

      const pos4 = indexContent.indexOf("ses_order_4")
      const pos3 = indexContent.indexOf("ses_order_3")
      const pos2 = indexContent.indexOf("ses_order_2")
      const pos1 = indexContent.indexOf("ses_order_1")

      expect(pos4).toBeLessThan(pos3)
      expect(pos3).toBeLessThan(pos2)
      expect(pos2).toBeLessThan(pos1)
    })

    test("sequence numbers are correct after multiple sessions", async () => {
      for (let i = 1; i <= 5; i++) {
        await sessionManager.captureSession({
          sessionId: `ses_seq_check_${i}`,
          summary: `Session ${i}.`,
          keyPoints: [`Point ${i}`],
        })
      }

      const sessions = sessionManager.getRecentSessions(10)

      // Verify sequence numbers (most recent has highest sequence)
      expect(sessions[0].sequence).toBe(5)
      expect(sessions[1].sequence).toBe(4)
      expect(sessions[2].sequence).toBe(3)
      expect(sessions[3].sequence).toBe(2)
      expect(sessions[4].sequence).toBe(1)

      // Verify filenames have correct prefixes
      expect(sessions[0].filename).toMatch(/^005-/)
      expect(sessions[1].filename).toMatch(/^004-/)
      expect(sessions[2].filename).toMatch(/^003-/)
      expect(sessions[3].filename).toMatch(/^002-/)
      expect(sessions[4].filename).toMatch(/^001-/)
    })

    test("session index persists and reloads correctly", async () => {
      // Create sessions
      await sessionManager.captureSession({
        sessionId: "ses_persist_1",
        summary: "Session 1 for persistence test.",
        keyPoints: ["Point 1"],
        openQuestionsAdded: ["Persistent question 1?"],
      })

      await sessionManager.captureSession({
        sessionId: "ses_persist_2",
        summary: "Session 2 for persistence test.",
        keyPoints: ["Point 2"],
        openQuestionsAdded: ["Persistent question 2?"],
      })

      await sessionManager.updateIndex({
        pendingDecisions: ["Persistent decision"],
        whatsNext: ["Persistent next step"],
      })

      // Create a fresh session manager and reload
      const log = createMockLogger()
      const freshManager = new SessionManager(projectDir, log)
      const reloadedIndex = await freshManager.load()

      // Verify all data persisted
      expect(reloadedIndex.sessions.length).toBe(2)
      expect(reloadedIndex.sessions[0].id).toBe("ses_persist_2")
      expect(reloadedIndex.sessions[1].id).toBe("ses_persist_1")
      expect(reloadedIndex.openQuestions).toContain("Persistent question 1?")
      expect(reloadedIndex.openQuestions).toContain("Persistent question 2?")
      expect(reloadedIndex.pendingDecisions).toContain("Persistent decision")
      expect(reloadedIndex.whatsNext).toContain("Persistent next step")
    })
  })

  describe("Edge Cases", () => {
    test("hasSessionContext returns false for empty context", async () => {
      const context = await buildSessionContext(sessionManager)
      expect(hasSessionContext(context)).toBe(false)
    })

    test("hasSessionContext returns true when sessions exist", async () => {
      await sessionManager.captureSession({
        sessionId: "ses_has_ctx",
        summary: "Session for context check.",
        keyPoints: ["Point 1"],
      })

      const context = await buildSessionContext(sessionManager)
      expect(hasSessionContext(context)).toBe(true)
    })

    test("hasSessionContext returns true when only open questions exist", async () => {
      await sessionManager.updateIndex({
        openQuestions: ["Standalone question?"],
      })

      const context = await buildSessionContext(sessionManager)
      expect(hasSessionContext(context)).toBe(true)
    })

    test("duplicate session ID is rejected", async () => {
      await sessionManager.captureSession({
        sessionId: "ses_dup_id",
        summary: "First capture.",
        keyPoints: ["Point 1"],
      })

      const duplicate = await sessionManager.captureSession({
        sessionId: "ses_dup_id",
        summary: "Duplicate capture.",
        keyPoints: ["Point 2"],
      })

      expect(duplicate.ok).toBe(false)
      if (!duplicate.ok) {
        expect(duplicate.error.type).toBe("already_exists")
        if (duplicate.error.type === "already_exists") {
          expect(duplicate.error.sessionId).toBe("ses_dup_id")
        }
      }
    })

    test("empty key points are handled", async () => {
      const result = await sessionManager.captureSession({
        sessionId: "ses_empty_kp",
        summary: "Session with no key points.",
        keyPoints: [],
      })

      expect(result.ok).toBe(true)

      const sessionsDir = path.join(projectDir, "sessions")
      const files = await fs.readdir(sessionsDir)
      const sessionFile = files.find((f) => f.includes("ses_empty_kp"))
      const content = await fs.readFile(path.join(sessionsDir, sessionFile!), "utf-8")

      expect(content).toContain("## Key Points")
    })

    test("session with no optional fields", async () => {
      const result = await sessionManager.captureSession({
        sessionId: "ses_minimal",
        summary: "Minimal session.",
        keyPoints: ["Single point"],
      })

      expect(result.ok).toBe(true)
      if (!result.ok) return

      expect(result.value.openQuestionsAdded).toEqual([])
      expect(result.value.decisionsMade).toEqual([])
      expect(result.value.artifactsCreated).toEqual([])

      // Verify file doesn't have empty sections
      const sessionsDir = path.join(projectDir, "sessions")
      const files = await fs.readdir(sessionsDir)
      const sessionFile = files.find((f) => f.includes("ses_minimal"))
      const content = await fs.readFile(path.join(sessionsDir, sessionFile!), "utf-8")

      expect(content).not.toContain("## Open Questions Added")
      expect(content).not.toContain("## Decisions Made")
      expect(content).not.toContain("## Artifacts Created")
    })
  })
})
