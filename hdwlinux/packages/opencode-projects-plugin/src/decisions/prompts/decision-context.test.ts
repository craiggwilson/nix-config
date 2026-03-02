/**
 * Tests for decision context builder
 */

import { describe, test, expect, beforeEach, afterEach } from "bun:test"
import * as fs from "node:fs/promises"
import * as path from "node:path"
import * as os from "node:os"

import { ArtifactRegistry } from "../../artifacts/index.js"
import { DecisionManager } from "../decision-manager.js"
import { createMockLogger } from "../../utils/testing/index.js"
import {
  buildDecisionContext,
  formatDecisionContext,
  formatDecisionSummary,
  hasDecisionContext,
  type DecisionContext,
} from "./decision-context.js"

describe("decision-context", () => {
  let testDir: string
  let decisionManager: DecisionManager
  let artifactRegistry: ArtifactRegistry

  beforeEach(async () => {
    testDir = await fs.mkdtemp(path.join(os.tmpdir(), "decision-context-test-"))
    artifactRegistry = new ArtifactRegistry(testDir, createMockLogger())
    await artifactRegistry.load()
    decisionManager = new DecisionManager(testDir, artifactRegistry, createMockLogger())
    await decisionManager.load()
  })

  afterEach(async () => {
    await fs.rm(testDir, { recursive: true, force: true })
  })

  describe("buildDecisionContext", () => {
    test("extracts pending decisions", async () => {
      await decisionManager.addPendingDecision({
        question: "Which database to use?",
        context: "Need to support high write throughput",
        blocking: ["issue-1", "issue-2"],
      })
      await decisionManager.addPendingDecision({
        question: "Which auth provider?",
        relatedResearch: ["research-auth-abc123"],
      })

      const context = await buildDecisionContext(decisionManager)

      expect(context.pending).toHaveLength(2)
      expect(context.pending[0].question).toBe("Which database to use?")
      expect(context.pending[1].question).toBe("Which auth provider?")
    })

    test("extracts recent decisions sorted by date newest first", async () => {
      await decisionManager.recordDecision({
        title: "Use PostgreSQL",
        decision: "PostgreSQL for primary database",
        rationale: "Best for our use case",
      })

      await decisionManager.recordDecision({
        title: "Use OAuth2",
        decision: "OAuth2 with PKCE",
        rationale: "Better mobile support",
      })

      const context = await buildDecisionContext(decisionManager)

      expect(context.recentDecisions).toHaveLength(2)
      // Verify sorting is applied (newest first based on createdAt)
      const timestamps = context.recentDecisions.map((d) => new Date(d.createdAt).getTime())
      expect(timestamps[0]).toBeGreaterThanOrEqual(timestamps[1])
    })

    test("respects recent limit option", async () => {
      for (let i = 1; i <= 10; i++) {
        await decisionManager.recordDecision({
          title: `Decision ${i}`,
          decision: `Decision ${i} content`,
          rationale: `Rationale ${i}`,
        })
      }

      const context = await buildDecisionContext(decisionManager, { recentLimit: 3 })

      expect(context.recentDecisions).toHaveLength(3)
      expect(context.totalDecided).toBe(10)
    })

    test("uses default limit of 5", async () => {
      for (let i = 1; i <= 10; i++) {
        await decisionManager.recordDecision({
          title: `Decision ${i}`,
          decision: `Decision ${i} content`,
          rationale: `Rationale ${i}`,
        })
      }

      const context = await buildDecisionContext(decisionManager)

      expect(context.recentDecisions).toHaveLength(5)
      expect(context.totalDecided).toBe(10)
    })

    test("returns total counts", async () => {
      await decisionManager.recordDecision({
        title: "Decision 1",
        decision: "Content 1",
        rationale: "Rationale 1",
      })
      await decisionManager.recordDecision({
        title: "Decision 2",
        decision: "Content 2",
        rationale: "Rationale 2",
      })

      const context = await buildDecisionContext(decisionManager)

      expect(context.totalDecided).toBe(2)
      expect(context.totalSuperseded).toBe(0)
    })

    test("returns empty context when no decisions", async () => {
      const context = await buildDecisionContext(decisionManager)

      expect(context.pending).toEqual([])
      expect(context.recentDecisions).toEqual([])
      expect(context.totalDecided).toBe(0)
      expect(context.totalSuperseded).toBe(0)
    })
  })

  describe("formatDecisionContext", () => {
    test("produces valid markdown with pending decisions", () => {
      const context: DecisionContext = {
        pending: [
          {
            question: "Which database to use?",
            context: "Need high write throughput",
            blocking: ["issue-1"],
            relatedResearch: ["research-db-abc123"],
          },
        ],
        recentDecisions: [],
        totalDecided: 0,
        totalSuperseded: 0,
      }

      const markdown = formatDecisionContext(context)

      expect(markdown).toContain("## Pending Decisions")
      expect(markdown).toContain("### Which database to use?")
      expect(markdown).toContain("Need high write throughput")
      expect(markdown).toContain("**Blocking:** issue-1")
      expect(markdown).toContain("**Related Research:** research-db-abc123")
    })

    test("produces valid markdown with recent decisions", () => {
      const context: DecisionContext = {
        pending: [],
        recentDecisions: [
          {
            id: "decision-oauth-abc123",
            slug: "use-oauth2",
            filename: "2026-03-02-use-oauth2.md",
            title: "Use OAuth2",
            status: "decided",
            decision: "OAuth2 with PKCE for authentication",
            rationale: "Better mobile support",
            createdAt: "2026-03-02T10:00:00.000Z",
            updatedAt: "2026-03-02T10:00:00.000Z",
          },
        ],
        totalDecided: 1,
        totalSuperseded: 0,
      }

      const markdown = formatDecisionContext(context)

      expect(markdown).toContain("## Recent Decisions")
      expect(markdown).toContain("**Use OAuth2**")
      expect(markdown).toContain("(2026-03-02)")
      expect(markdown).toContain("OAuth2 with PKCE for authentication")
    })

    test("shows count of additional decisions", () => {
      const context: DecisionContext = {
        pending: [],
        recentDecisions: [
          {
            id: "decision-1",
            slug: "decision-1",
            filename: "2026-03-02-decision-1.md",
            title: "Decision 1",
            status: "decided",
            decision: "Content",
            rationale: "Rationale",
            createdAt: "2026-03-02T10:00:00.000Z",
            updatedAt: "2026-03-02T10:00:00.000Z",
          },
        ],
        totalDecided: 5,
        totalSuperseded: 0,
      }

      const markdown = formatDecisionContext(context)

      expect(markdown).toContain("*4 more decisions in log*")
    })

    test("returns empty string when no context", () => {
      const context: DecisionContext = {
        pending: [],
        recentDecisions: [],
        totalDecided: 0,
        totalSuperseded: 0,
      }

      const markdown = formatDecisionContext(context)

      expect(markdown).toBe("")
    })

    test("truncates long decision text", () => {
      const longDecision = "A".repeat(150)
      const context: DecisionContext = {
        pending: [],
        recentDecisions: [
          {
            id: "decision-long",
            slug: "long-decision",
            filename: "2026-03-02-long-decision.md",
            title: "Long Decision",
            status: "decided",
            decision: longDecision,
            rationale: "Rationale",
            createdAt: "2026-03-02T10:00:00.000Z",
            updatedAt: "2026-03-02T10:00:00.000Z",
          },
        ],
        totalDecided: 1,
        totalSuperseded: 0,
      }

      const markdown = formatDecisionContext(context)

      expect(markdown).toContain("...")
      expect(markdown.length).toBeLessThan(longDecision.length + 200)
    })
  })

  describe("formatDecisionSummary", () => {
    test("produces compact summary with pending", () => {
      const context: DecisionContext = {
        pending: [
          { question: "Which database?" },
          { question: "Which auth provider?" },
        ],
        recentDecisions: [],
        totalDecided: 3,
        totalSuperseded: 0,
      }

      const summary = formatDecisionSummary(context)

      expect(summary).toContain("**Pending:** Which database?; Which auth provider?")
      expect(summary).toContain("**Decided:** 3 decisions recorded")
    })

    test("shows only pending when no decided", () => {
      const context: DecisionContext = {
        pending: [{ question: "Which database?" }],
        recentDecisions: [],
        totalDecided: 0,
        totalSuperseded: 0,
      }

      const summary = formatDecisionSummary(context)

      expect(summary).toContain("**Pending:** Which database?")
      expect(summary).not.toContain("**Decided:**")
    })

    test("shows only decided when no pending", () => {
      const context: DecisionContext = {
        pending: [],
        recentDecisions: [],
        totalDecided: 5,
        totalSuperseded: 0,
      }

      const summary = formatDecisionSummary(context)

      expect(summary).not.toContain("**Pending:**")
      expect(summary).toContain("**Decided:** 5 decisions recorded")
    })

    test("returns message when no decisions", () => {
      const context: DecisionContext = {
        pending: [],
        recentDecisions: [],
        totalDecided: 0,
        totalSuperseded: 0,
      }

      const summary = formatDecisionSummary(context)

      expect(summary).toBe("No decisions recorded.")
    })
  })

  describe("hasDecisionContext", () => {
    test("returns true when pending decisions exist", () => {
      const context: DecisionContext = {
        pending: [{ question: "Which database?" }],
        recentDecisions: [],
        totalDecided: 0,
        totalSuperseded: 0,
      }

      expect(hasDecisionContext(context)).toBe(true)
    })

    test("returns true when recent decisions exist", () => {
      const context: DecisionContext = {
        pending: [],
        recentDecisions: [
          {
            id: "decision-1",
            slug: "decision-1",
            filename: "2026-03-02-decision-1.md",
            title: "Decision 1",
            status: "decided",
            decision: "Content",
            rationale: "Rationale",
            createdAt: "2026-03-02T10:00:00.000Z",
            updatedAt: "2026-03-02T10:00:00.000Z",
          },
        ],
        totalDecided: 1,
        totalSuperseded: 0,
      }

      expect(hasDecisionContext(context)).toBe(true)
    })

    test("returns false when empty", () => {
      const context: DecisionContext = {
        pending: [],
        recentDecisions: [],
        totalDecided: 0,
        totalSuperseded: 0,
      }

      expect(hasDecisionContext(context)).toBe(false)
    })
  })
})
