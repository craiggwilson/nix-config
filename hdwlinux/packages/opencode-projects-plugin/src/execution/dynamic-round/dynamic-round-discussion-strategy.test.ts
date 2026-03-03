/**
 * Tests for DynamicRoundDiscussionStrategy
 */

import { describe, test, expect } from "bun:test"
import {
  DynamicRoundDiscussionStrategy,
  buildDiscussionContext,
  buildConvergencePrompt,
  buildArbiterPrompt,
} from "./dynamic-round-discussion-strategy.js"
import { createMockLogger } from "../../utils/testing/index.js"
import { MockClock } from "../../utils/clock/index.js"
import type { Team, DiscussionRound } from "../team-manager.js"
import type { OpencodeClient } from "../../utils/opencode-sdk/index.js"
import type { DynamicRoundStrategyConfig } from "./dynamic-round-discussion-strategy.js"

const mockLogger = createMockLogger()

/**
 * A mock clock that resolves sleeps immediately by advancing time.
 * This avoids real delays in tests while still exercising the polling loop.
 */
class ImmediateMockClock extends MockClock {
  override sleep(_delayMs: number): Promise<void> {
    // Advance time enough to satisfy the polling loop
    this.advance(10000)
    return Promise.resolve()
  }
}

const defaultConfig: DynamicRoundStrategyConfig = {
  maxRounds: 5,
  roundTimeoutMs: 60 * 1000,
  smallModelTimeoutMs: 5000,
  clock: new ImmediateMockClock(0),
}

function makeTeam(overrides: Partial<Team> = {}): Team {
  return {
    id: "team-123",
    projectId: "proj-1",
    projectDir: "/tmp/test",
    issueId: "issue-1",
    discussionStrategyType: "dynamicRound",
    members: [
      { agent: "coder", role: "primary", status: "completed", retryCount: 0, sessionId: "session-coder" },
      { agent: "reviewer", role: "secondary", status: "completed", retryCount: 0, sessionId: "session-reviewer" },
    ],
    status: "discussing",
    results: {
      coder: { agent: "coder", result: "Primary implementation", completedAt: "2024-01-01T00:00:00Z" },
      reviewer: { agent: "reviewer", result: "Review findings", completedAt: "2024-01-01T00:00:00Z" },
    },
    discussionHistory: [],
    startedAt: "2024-01-01T00:00:00Z",
    ...overrides,
  }
}

/**
 * Create a mock client that returns a fixed convergence assessment and
 * simulates agent responses via session messages.
 */
function makeClient(options: {
  assessmentState?: "converged" | "stuck" | "continue"
  agentResponse?: string
  noSmallModel?: boolean
} = {}): { client: OpencodeClient; promptCalls: Array<{ sessionId: string; text: string }> } {
  const promptCalls: Array<{ sessionId: string; text: string }> = []
  const { assessmentState = "converged", agentResponse = "Agent response **CONVERGED**", noSmallModel = false } = options

  const agentSignal = assessmentState === "converged" ? "CONVERGED" : assessmentState === "stuck" ? "STUCK" : "CONTINUE"
  const assessmentJson = JSON.stringify({
    agentSignals: { coder: agentSignal, reviewer: agentSignal },
    state: assessmentState,
    summary: `Team is ${assessmentState}`,
  })

  let sessionCounter = 0

  const client: OpencodeClient = {
    config: {
      get: async () => ({
        data: noSmallModel ? {} : { small_model: "test-model" },
      }),
    },
    session: {
      create: async () => ({ data: { id: `small-model-session-${++sessionCounter}` } }),
      prompt: async (opts: { path?: { id?: string }; body?: { parts?: Array<{ type: string; text?: string }> } } = {}) => {
        const sessionId = opts?.path?.id || "unknown"
        const firstPart = opts?.body?.parts?.[0]
        const text = firstPart?.type === "text" && firstPart.text ? firstPart.text : ""
        promptCalls.push({ sessionId, text })

        // Small model sessions return assessment JSON; agent sessions return agent response
        const isSmallModelSession = sessionId.startsWith("small-model-session")
        const responseText = isSmallModelSession ? assessmentJson : agentResponse

        return {
          data: { parts: [{ type: "text", text: responseText }] },
        }
      },
      messages: async (opts: { path?: { id?: string } } = {}) => {
        const sessionId = opts?.path?.id || "unknown"
        // Return a completed assistant message for agent sessions
        if (!sessionId.startsWith("small-model-session")) {
          return {
            data: [
              {
                info: { id: "msg-1", role: "assistant" as const, sessionID: sessionId },
                parts: [{ type: "text" as const, text: agentResponse }],
              },
            ],
          }
        }
        return { data: [] }
      },
      delete: async () => ({}),
      get: async () => ({ data: { id: "session-123" } }),
    },
    app: {
      log: async () => ({}),
      agents: async () => ({ data: [] }),
    },
  } as unknown as OpencodeClient

  return { client, promptCalls }
}

function makeConfig(overrides: Partial<DynamicRoundStrategyConfig> = {}): DynamicRoundStrategyConfig {
  return {
    maxRounds: 5,
    roundTimeoutMs: 60 * 1000,
    smallModelTimeoutMs: 5000,
    clock: new ImmediateMockClock(0),
    ...overrides,
  }
}

describe("DynamicRoundDiscussionStrategy", () => {
  describe("onAllMembersCompleted", () => {
    test("returns empty history for single-member team", async () => {
      const { client } = makeClient()
      const strategy = new DynamicRoundDiscussionStrategy(mockLogger, client, makeConfig())

      const team = makeTeam({
        members: [
          { agent: "coder", role: "primary", status: "completed", retryCount: 0, sessionId: "session-coder" },
        ],
      })

      const history = await strategy.onAllMembersCompleted(team)
      expect(history).toEqual([])
    })

    test("stops after one round when team converges", async () => {
      const { client } = makeClient({ assessmentState: "converged" })
      const strategy = new DynamicRoundDiscussionStrategy(mockLogger, client, makeConfig({ maxRounds: 5 }))

      const team = makeTeam()
      const history = await strategy.onAllMembersCompleted(team)

      // Should stop after 1 round due to convergence
      expect(history.length).toBe(1)
      expect(history[0].round).toBe(1)
    })

    test("continues until maxRounds when team never converges", async () => {
      const { client } = makeClient({ assessmentState: "continue", noSmallModel: true })
      const strategy = new DynamicRoundDiscussionStrategy(mockLogger, client, makeConfig({ maxRounds: 3 }))

      const team = makeTeam()
      const history = await strategy.onAllMembersCompleted(team)

      expect(history.length).toBe(3)
    })

    test("calls onProgress after each round", async () => {
      const { client } = makeClient({ assessmentState: "continue", noSmallModel: true })
      const strategy = new DynamicRoundDiscussionStrategy(mockLogger, client, makeConfig({ maxRounds: 2 }))

      const team = makeTeam()
      const progressCalls: number[] = []

      await strategy.onAllMembersCompleted(team, async (history) => {
        progressCalls.push(history.length)
      })

      expect(progressCalls).toEqual([1, 2])
    })

    test("handles member with no session gracefully", async () => {
      const { client } = makeClient({ assessmentState: "converged" })
      const strategy = new DynamicRoundDiscussionStrategy(mockLogger, client, makeConfig())

      const team = makeTeam({
        members: [
          { agent: "coder", role: "primary", status: "completed", retryCount: 0, sessionId: "session-coder" },
          { agent: "reviewer", role: "secondary", status: "completed", retryCount: 0 }, // no sessionId
        ],
      })

      const history = await strategy.onAllMembersCompleted(team)

      expect(history.length).toBeGreaterThan(0)
      expect(history[0].responses["reviewer"]).toBe("(no session)")
    })

    test("invokes arbiter and stops when team is stuck", async () => {
      const { client, promptCalls } = makeClient({ assessmentState: "stuck" })
      const strategy = new DynamicRoundDiscussionStrategy(mockLogger, client, makeConfig())

      const team = makeTeam()
      const history = await strategy.onAllMembersCompleted(team)

      // Should have 1 discussion round + 1 arbiter round
      expect(history.length).toBe(2)

      // Arbiter round should be labeled with "(arbiter)"
      const arbiterRound = history[history.length - 1]
      const arbiterKey = Object.keys(arbiterRound.responses).find((k) => k.includes("arbiter"))
      expect(arbiterKey).toBeDefined()
    })

    test("includes existing discussion history in context", async () => {
      const { client, promptCalls } = makeClient({ assessmentState: "converged" })
      const strategy = new DynamicRoundDiscussionStrategy(mockLogger, client, makeConfig())

      const existingHistory: DiscussionRound[] = [
        { round: 1, responses: { coder: "Previous round response" } },
      ]

      const team = makeTeam({ discussionHistory: existingHistory })
      await strategy.onAllMembersCompleted(team)

      // The prompt sent to agents should include previous discussion context
      const agentPrompts = promptCalls.filter((c) => c.sessionId.startsWith("session-"))
      expect(agentPrompts.length).toBeGreaterThan(0)
      // Round 2 prompt should include previous discussion
      const roundTwoPrompt = agentPrompts.find((p) => p.text.includes("Round 2"))
      if (roundTwoPrompt) {
        expect(roundTwoPrompt.text).toContain("Previous Discussion")
      }
    })
  })

  describe("buildDiscussionContext", () => {
    test("includes primary agent implementation", () => {
      const team = makeTeam()
      const context = buildDiscussionContext(team, 1, [])

      expect(context).toContain("## Primary Agent's Implementation")
      expect(context).toContain("Primary implementation")
      expect(context).toContain("## Team Findings")
      expect(context).toContain("### reviewer")
      expect(context).toContain("Review findings")
    })

    test("includes previous discussion rounds for round > 1", () => {
      const team = makeTeam()
      const history: DiscussionRound[] = [
        { round: 1, responses: { coder: "Round 1 coder", reviewer: "Round 1 reviewer" } },
      ]

      const context = buildDiscussionContext(team, 2, history)

      expect(context).toContain("## Previous Discussion")
      expect(context).toContain("### Round 1")
      expect(context).toContain("Round 1 coder")
      expect(context).toContain("Round 1 reviewer")
    })

    test("excludes previous discussion for round 1", () => {
      const team = makeTeam()
      const context = buildDiscussionContext(team, 1, [])

      expect(context).not.toContain("## Previous Discussion")
    })

    test("excludes primary from team findings section", () => {
      const team = makeTeam()
      const context = buildDiscussionContext(team, 1, [])

      expect(context).toContain("## Primary Agent's Implementation")
      expect(context).not.toContain("### coder")
      expect(context).toContain("### reviewer")
    })
  })

  describe("buildConvergencePrompt", () => {
    test("includes convergence signal instructions", () => {
      const prompt = buildConvergencePrompt("issue-1", "coder", 1, 5, "context here")

      expect(prompt).toContain("CONVERGED")
      expect(prompt).toContain("STUCK")
      expect(prompt).toContain("CONTINUE")
    })

    test("includes round number and max rounds", () => {
      const prompt = buildConvergencePrompt("issue-1", "coder", 3, 10, "context")

      expect(prompt).toContain("Round 3/10")
    })

    test("includes issue ID", () => {
      const prompt = buildConvergencePrompt("proj-abc.42", "coder", 1, 5, "context")

      expect(prompt).toContain("proj-abc.42")
    })

    test("includes agent name", () => {
      const prompt = buildConvergencePrompt("issue-1", "security-expert", 1, 5, "context")

      expect(prompt).toContain("security-expert")
    })

    test("includes provided context", () => {
      const prompt = buildConvergencePrompt("issue-1", "coder", 1, 5, "## My Context\nSome details here")

      expect(prompt).toContain("## My Context")
      expect(prompt).toContain("Some details here")
    })
  })

  describe("buildArbiterPrompt", () => {
    test("includes issue ID", () => {
      const prompt = buildArbiterPrompt("proj-abc.42", 3, [])

      expect(prompt).toContain("proj-abc.42")
    })

    test("includes stuck round number", () => {
      const prompt = buildArbiterPrompt("issue-1", 4, [])

      expect(prompt).toContain("4 discussion round")
    })

    test("includes full discussion history", () => {
      const history: DiscussionRound[] = [
        { round: 1, responses: { "agent-a": "First response", "agent-b": "Second response" } },
        { round: 2, responses: { "agent-a": "Third response" } },
      ]

      const prompt = buildArbiterPrompt("issue-1", 2, history)

      expect(prompt).toContain("Round 1")
      expect(prompt).toContain("First response")
      expect(prompt).toContain("Second response")
      expect(prompt).toContain("Round 2")
      expect(prompt).toContain("Third response")
    })

    test("instructs arbiter to make final binding decision", () => {
      const prompt = buildArbiterPrompt("issue-1", 1, [])

      expect(prompt).toContain("final")
      expect(prompt).toContain("decision")
    })
  })
})
