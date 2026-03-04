/**
 * Tests for DynamicRoundDiscussionStrategy
 */

import { describe, test, expect } from "bun:test"
import {
  DynamicRoundDiscussionStrategy,
  buildConvergencePrompt,
  buildArbiterPrompt,
  buildMediatorPrompt,
} from "./dynamic-round-discussion-strategy.js"
import { buildDiscussionContext } from "../discussion-context.js"
import { createMockLogger } from "../../utils/testing/index.js"
import { MockClock } from "../../utils/clock/index.js"
import type { Team, DiscussionRound } from "../team-manager.js"
import type { OpencodeClient, Logger } from "../../utils/opencode-sdk/index.js"
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
      { agent: "coder", role: "primary", status: "completed", retryCount: 0, sessionId: "session-coder", prompt: "" },
      { agent: "reviewer", role: "secondary", status: "completed", retryCount: 0, sessionId: "session-reviewer", prompt: "" },
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
  /** When true, the arbiter invocation fails (no primary session), triggering mediator */
  arbiterFails?: boolean
  mediatorResponse?: string
} = {}): { client: OpencodeClient; promptCalls: Array<{ sessionId: string; text: string }>; createdSessions: string[] } {
  const promptCalls: Array<{ sessionId: string; text: string }> = []
  const createdSessions: string[] = []
  const {
    assessmentState = "converged",
    agentResponse = "Agent response **CONVERGED**",
    noSmallModel = false,
    mediatorResponse = "Mediator proposal: take approach A",
  } = options

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
      create: async (args: { body?: { title?: string } } = {}) => {
        const id = `created-session-${++sessionCounter}`
        createdSessions.push(args?.body?.title ?? id)
        return { data: { id } }
      },
      prompt: async (opts: { path?: { id?: string }; body?: { parts?: Array<{ type: string; text?: string }> } } = {}) => {
        const sessionId = opts?.path?.id || "unknown"
        const firstPart = opts?.body?.parts?.[0]
        const text = firstPart?.type === "text" && firstPart.text ? firstPart.text : ""
        promptCalls.push({ sessionId, text })

        // Convergence assessor sessions return assessment JSON; agent sessions return agent response
        const isAssessorSession = sessionId.startsWith("created-session") && !sessionId.startsWith("session-")
        const responseText = isAssessorSession ? assessmentJson : agentResponse

        return {
          data: { parts: [{ type: "text", text: responseText }] },
        }
      },
      messages: async (opts: { path?: { id?: string } } = {}) => {
        const sessionId = opts?.path?.id || "unknown"
        // Mediator sessions (created dynamically) return mediator response
        if (sessionId.startsWith("created-session") && createdSessions.some((t) => t.startsWith("Mediator:"))) {
          return {
            data: [
              {
                info: { id: "msg-mediator", role: "assistant" as const, sessionID: sessionId },
                parts: [{ type: "text" as const, text: mediatorResponse }],
              },
            ],
          }
        }
        // Pre-existing agent sessions (session-coder, session-reviewer) return agent response
        if (sessionId.startsWith("session-")) {
          return {
            data: [
              {
                info: { id: "msg-1", role: "assistant" as const, sessionID: sessionId },
                parts: [{ type: "text" as const, text: agentResponse }],
              },
            ],
          }
        }
        // Convergence assessor sessions return no messages (response comes via prompt return)
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

  return { client, promptCalls, createdSessions }
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
          { agent: "coder", role: "primary", status: "completed", retryCount: 0, sessionId: "session-coder", prompt: "" },
        ],
      })

      const history = await strategy.onAllMembersCompleted(team)
      expect(history).toEqual([])
    })

    test("stops after minRounds when team converges", async () => {
      const { client } = makeClient({ assessmentState: "converged" })
      const strategy = new DynamicRoundDiscussionStrategy(mockLogger, client, makeConfig({ maxRounds: 5, minRounds: 2 }))

      const team = makeTeam()
      const history = await strategy.onAllMembersCompleted(team)

      // Should stop after minRounds (2) due to convergence — not after round 1
      expect(history.length).toBe(2)
      expect(history[0].round).toBe(1)
      expect(history[1].round).toBe(2)
    })

    test("stops after round 1 when minRounds is 1 and team converges", async () => {
      const { client } = makeClient({ assessmentState: "converged" })
      const strategy = new DynamicRoundDiscussionStrategy(mockLogger, client, makeConfig({ maxRounds: 5, minRounds: 1 }))

      const team = makeTeam()
      const history = await strategy.onAllMembersCompleted(team)

      // With minRounds=1, convergence assessment fires after round 1
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
          { agent: "coder", role: "primary", status: "completed", retryCount: 0, sessionId: "session-coder", prompt: "" },
          { agent: "reviewer", role: "secondary", status: "completed", retryCount: 0, prompt: "" }, // no sessionId
        ],
      })

      const history = await strategy.onAllMembersCompleted(team)

      expect(history.length).toBeGreaterThan(0)
      expect(history[0].responses["reviewer"]).toBe("(no session)")
    })

    test("invokes arbiter and stops when team is stuck", async () => {
      const { client, promptCalls } = makeClient({ assessmentState: "stuck" })
      // Use minRounds=1 so stuck assessment fires after round 1
      const strategy = new DynamicRoundDiscussionStrategy(mockLogger, client, makeConfig({ minRounds: 1 }))

      const team = makeTeam()
      const history = await strategy.onAllMembersCompleted(team)

      // Should have 1 discussion round + 1 arbiter round
      expect(history.length).toBe(2)

      // Arbiter round should be labeled with "(arbiter)"
      const arbiterRound = history[history.length - 1]
      const arbiterKey = Object.keys(arbiterRound.responses).find((k) => k.includes("arbiter"))
      expect(arbiterKey).toBeDefined()
    })

    test("invokes mediator when arbiter fails due to missing primary session", async () => {
      const { client, createdSessions } = makeClient({ assessmentState: "stuck", mediatorResponse: "Mediator: try approach X" })
      const strategy = new DynamicRoundDiscussionStrategy(mockLogger, client, makeConfig({ minRounds: 1 }))

      // Team where primary has no sessionId — arbiter will fail
      const team = makeTeam({
        members: [
          { agent: "coder", role: "primary", status: "completed", retryCount: 0, prompt: "" }, // no sessionId
          { agent: "reviewer", role: "secondary", status: "completed", retryCount: 0, sessionId: "session-reviewer", prompt: "" },
        ],
      })

      const history = await strategy.onAllMembersCompleted(team)

      // Should have 1 discussion round + 1 mediator round
      expect(history.length).toBe(2)

      // Mediator round should be labeled "mediator"
      const mediatorRound = history[history.length - 1]
      expect(mediatorRound.responses["mediator"]).toBeDefined()
      expect(mediatorRound.responses["mediator"]).toContain("Mediator: try approach X")

      // A new session should have been created for the mediator
      expect(createdSessions.some((t) => t.startsWith("Mediator:"))).toBe(true)
    })

    test("mediator round is included in onProgress callback", async () => {
      const { client } = makeClient({ assessmentState: "stuck", mediatorResponse: "Mediator proposal" })
      const strategy = new DynamicRoundDiscussionStrategy(mockLogger, client, makeConfig({ minRounds: 1 }))

      const team = makeTeam({
        members: [
          { agent: "coder", role: "primary", status: "completed", retryCount: 0, prompt: "" }, // no sessionId → arbiter fails
          { agent: "reviewer", role: "secondary", status: "completed", retryCount: 0, sessionId: "session-reviewer", prompt: "" },
        ],
      })

      const progressSnapshots: number[] = []
      await strategy.onAllMembersCompleted(team, async (history) => {
        progressSnapshots.push(history.length)
      })

      // Progress should be called for discussion round and mediator round
      expect(progressSnapshots).toContain(2)
    })

    test("does not invoke arbiter before minRounds even if stuck", async () => {
      const { client } = makeClient({ assessmentState: "stuck" })
      // minRounds=2 (default), so stuck assessment is skipped for round 1
      const strategy = new DynamicRoundDiscussionStrategy(mockLogger, client, makeConfig({ maxRounds: 3, minRounds: 2 }))

      const team = makeTeam()
      const history = await strategy.onAllMembersCompleted(team)

      // Round 1 skips assessment, round 2 detects stuck → 2 discussion rounds + 1 arbiter
      expect(history.length).toBe(3)
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

  describe("buildMediatorPrompt", () => {
    test("includes issue ID", () => {
      const prompt = buildMediatorPrompt("proj-abc.42", 3, [])

      expect(prompt).toContain("proj-abc.42")
    })

    test("includes stuck round number", () => {
      const prompt = buildMediatorPrompt("issue-1", 4, [])

      expect(prompt).toContain("4 discussion round")
    })

    test("includes full discussion history", () => {
      const history: DiscussionRound[] = [
        { round: 1, responses: { "agent-a": "First response", "agent-b": "Second response" } },
        { round: 2, responses: { "agent-a": "Third response" } },
      ]

      const prompt = buildMediatorPrompt("issue-1", 2, history)

      expect(prompt).toContain("Round 1")
      expect(prompt).toContain("First response")
      expect(prompt).toContain("Second response")
      expect(prompt).toContain("Round 2")
      expect(prompt).toContain("Third response")
    })

    test("frames mediator as neutral third party", () => {
      const prompt = buildMediatorPrompt("issue-1", 1, [])

      expect(prompt).toContain("neutral")
    })

    test("asks for concrete path forward, not a binding decision", () => {
      const prompt = buildMediatorPrompt("issue-1", 1, [])

      expect(prompt).toContain("path forward")
      expect(prompt).not.toContain("binding decision")
    })

    test("mentions arbiter failure context", () => {
      const prompt = buildMediatorPrompt("issue-1", 2, [])

      expect(prompt).toContain("arbiter")
    })
  })

  describe("response normalization", () => {
    function makeSpyLogger(): { logger: Logger; warnings: string[] } {
      const warnings: string[] = []
      const logger: Logger = {
        debug: async () => {},
        info: async () => {},
        warn: async (msg: string) => { warnings.push(msg) },
        error: async () => {},
      }
      return { logger, warnings }
    }

    test("normalizes response missing convergence signal to CONTINUE", async () => {
      const { client } = makeClient({ assessmentState: "converged", agentResponse: "My analysis without signal" })
      const { logger, warnings } = makeSpyLogger()
      const strategy = new DynamicRoundDiscussionStrategy(logger, client, makeConfig({ minRounds: 1 }))

      const team = makeTeam()
      const history = await strategy.onAllMembersCompleted(team)

      // Should have warned about missing signal
      expect(warnings.some((w) => w.includes("missing convergence signal"))).toBe(true)
      // Discussion should still complete
      expect(history.length).toBeGreaterThan(0)
    })

    test("normalizes response with embedded signal (not on own line) to CONTINUE", async () => {
      const { client } = makeClient({ assessmentState: "converged", agentResponse: "I think CONVERGED is the right call here" })
      const { logger, warnings } = makeSpyLogger()
      const strategy = new DynamicRoundDiscussionStrategy(logger, client, makeConfig({ minRounds: 1 }))

      const team = makeTeam()
      const history = await strategy.onAllMembersCompleted(team)

      // Should have warned about signal not on own line
      expect(warnings.some((w) => w.includes("not on own line"))).toBe(true)
      // Discussion should still complete
      expect(history.length).toBeGreaterThan(0)
    })

    test("does not warn when signal is correctly placed on own line", async () => {
      const { client } = makeClient({ assessmentState: "converged", agentResponse: "My analysis\nCONVERGED" })
      const { logger, warnings } = makeSpyLogger()
      const strategy = new DynamicRoundDiscussionStrategy(logger, client, makeConfig({ minRounds: 1 }))

      const team = makeTeam()
      await strategy.onAllMembersCompleted(team)

      expect(warnings.filter((w) => w.includes("convergence signal"))).toHaveLength(0)
    })
  })

  describe("response truncation", () => {
    test("truncates response exceeding maxResponseChars", async () => {
      const longResponse = "A".repeat(200) + "\nCONVERGED"
      const { client } = makeClient({ assessmentState: "converged", agentResponse: longResponse })
      const strategy = new DynamicRoundDiscussionStrategy(
        mockLogger,
        client,
        makeConfig({ minRounds: 1, maxResponseChars: 100 })
      )

      const team = makeTeam()
      const history = await strategy.onAllMembersCompleted(team)

      // Responses should be truncated
      const firstRound = history[0]
      for (const response of Object.values(firstRound.responses)) {
        if (!response.startsWith("(")) {
          expect(response.length).toBeLessThan(longResponse.length)
          expect(response).toContain("[... truncated ...]")
        }
      }
    })

    test("does not truncate response within maxResponseChars", async () => {
      const shortResponse = "Short response\nCONVERGED"
      const { client } = makeClient({ assessmentState: "converged", agentResponse: shortResponse })
      const strategy = new DynamicRoundDiscussionStrategy(
        mockLogger,
        client,
        makeConfig({ minRounds: 1, maxResponseChars: 5000 })
      )

      const team = makeTeam()
      const history = await strategy.onAllMembersCompleted(team)

      const firstRound = history[0]
      for (const response of Object.values(firstRound.responses)) {
        if (!response.startsWith("(")) {
          expect(response).not.toContain("[... truncated ...]")
        }
      }
    })

    test("does not truncate when maxResponseChars is not configured", async () => {
      const longResponse = "A".repeat(10000) + "\nCONVERGED"
      const { client } = makeClient({ assessmentState: "converged", agentResponse: longResponse })
      const strategy = new DynamicRoundDiscussionStrategy(
        mockLogger,
        client,
        makeConfig({ minRounds: 1 }) // no maxResponseChars
      )

      const team = makeTeam()
      const history = await strategy.onAllMembersCompleted(team)

      const firstRound = history[0]
      for (const response of Object.values(firstRound.responses)) {
        if (!response.startsWith("(")) {
          expect(response).not.toContain("[... truncated ...]")
        }
      }
    })
  })

  describe("timeout handling", () => {
    test("degrades gracefully on timeout, returning CONTINUE", async () => {
      // Client that never returns messages (simulates timeout)
      const timeoutClient: OpencodeClient = {
        config: {
          get: async () => ({ data: { small_model: "test-model" } }),
        },
        session: {
          create: async () => ({ data: { id: "created-session-1" } }),
          prompt: async () => ({ data: {} }),
          messages: async (opts: { path?: { id?: string } } = {}) => {
            const sessionId = opts?.path?.id || ""
            // Assessor sessions return converged; agent sessions return no messages (timeout)
            if (sessionId.startsWith("created-session")) {
              return {
                data: [
                  {
                    info: { id: "msg-1", role: "assistant" as const, sessionID: sessionId },
                    parts: [{ type: "text" as const, text: JSON.stringify({
                      agentSignals: { coder: "CONVERGED", reviewer: "CONVERGED" },
                      state: "converged",
                      summary: "All converged",
                    }) }],
                  },
                ],
              }
            }
            return { data: [] } // No messages → timeout
          },
          delete: async () => ({}),
          get: async () => ({ data: { id: "session-123" } }),
        },
        app: {
          log: async () => ({}),
          agents: async () => ({ data: [] }),
        },
      } as unknown as OpencodeClient

      const { logger, warnings } = (() => {
        const warnings: string[] = []
        const logger: Logger = {
          debug: async () => {},
          info: async () => {},
          warn: async (msg: string) => { warnings.push(msg) },
          error: async () => {},
        }
        return { logger, warnings }
      })()

      const strategy = new DynamicRoundDiscussionStrategy(
        logger,
        timeoutClient,
        makeConfig({ minRounds: 1, roundTimeoutMs: 1 }) // Very short timeout
      )

      const team = makeTeam()
      const history = await strategy.onAllMembersCompleted(team)

      // Should complete without throwing
      expect(history.length).toBeGreaterThan(0)
      // Should have warned about timeout
      expect(warnings.some((w) => w.includes("timed out"))).toBe(true)
    })
  })

  describe("round metrics logging", () => {
    test("logs metrics after each round", async () => {
      const infos: string[] = []
      const logger: Logger = {
        debug: async () => {},
        info: async (msg: string) => { infos.push(msg) },
        warn: async () => {},
        error: async () => {},
      }

      const { client } = makeClient({ assessmentState: "converged", agentResponse: "Analysis\nCONVERGED" })
      const strategy = new DynamicRoundDiscussionStrategy(logger, client, makeConfig({ minRounds: 1 }))

      const team = makeTeam()
      await strategy.onAllMembersCompleted(team)

      // Should have logged round metrics
      expect(infos.some((msg) => msg.includes("round 1 metrics"))).toBe(true)
      expect(infos.some((msg) => msg.includes("converged="))).toBe(true)
    })

    test("logs completion summary with metrics", async () => {
      const infos: string[] = []
      const logger: Logger = {
        debug: async () => {},
        info: async (msg: string) => { infos.push(msg) },
        warn: async () => {},
        error: async () => {},
      }

      const { client } = makeClient({ assessmentState: "converged", agentResponse: "Analysis\nCONVERGED" })
      const strategy = new DynamicRoundDiscussionStrategy(logger, client, makeConfig({ minRounds: 1 }))

      const team = makeTeam()
      await strategy.onAllMembersCompleted(team)

      // Should have logged completion summary with metrics
      const completionLog = infos.find((msg) => msg.includes("convergence discussion complete"))
      expect(completionLog).toBeDefined()
      expect(completionLog).toContain("totalRounds=")
      expect(completionLog).toContain("convergenceAssessments=")
      expect(completionLog).toContain("durationMs=")
    })
  })
})
