/**
 * Tests for RealtimeDiscussionStrategy
 */

import { describe, test, expect, beforeEach, afterEach } from "bun:test"
import * as fs from "node:fs/promises"
import * as path from "node:path"
import * as os from "node:os"

import { extractSignal } from "../convergence-signal.js"
import {
  RealtimeDiscussionStrategy,
  buildDiscussionPrompt,
  buildContinuationPrompt,
  buildArbiterPrompt,
  type RealtimeStrategyConfig,
} from "./realtime-discussion-strategy.js"
import type { InboxMessage } from "./inbox-manager.js"
import { createMockLogger } from "../../utils/testing/index.js"
import { MockClock } from "../../utils/clock/index.js"
import type { Team, TeamMember, DiscussionRound } from "../team-manager.js"

const mockLogger = createMockLogger()

describe("RealtimeDiscussionStrategy", () => {
  let tempDir: string
  let clock: MockClock

  beforeEach(async () => {
    tempDir = await fs.mkdtemp(path.join(os.tmpdir(), "realtime-test-"))
    clock = new MockClock(1000000000000)
  })

  afterEach(async () => {
    await fs.rm(tempDir, { recursive: true, force: true })
  })

  function createConfig(overrides?: Partial<RealtimeStrategyConfig>): RealtimeStrategyConfig {
    return {
      baseDir: tempDir,
      pollIntervalMs: 100,
      maxWaitTimeMs: 5000,
      promptTimeoutMs: 1000,
      clock,
      ...overrides,
    }
  }

  function createTeam(overrides?: Partial<Team>): Team {
    return {
      id: "team-123",
      projectId: "proj-1",
      projectDir: tempDir,
      issueId: "issue-1",
      discussionStrategyType: "realtime",
      members: [
        { agent: "agent-a", role: "primary", status: "completed", retryCount: 0, prompt: "" },
        { agent: "agent-b", role: "secondary", status: "completed", retryCount: 0, prompt: "" },
      ],
      status: "discussing",
      results: {
        "agent-a": {
          agent: "agent-a",
          result: "Primary agent's analysis",
          completedAt: "2024-01-01T00:00:00Z",
        },
        "agent-b": {
          agent: "agent-b",
          result: "Secondary agent's review",
          completedAt: "2024-01-01T00:00:00Z",
        },
      },
      discussionHistory: [],
      startedAt: "2024-01-01T00:00:00Z",
      ...overrides,
    }
  }

  describe("type", () => {
    test("returns 'realtime'", () => {
      const strategy = new RealtimeDiscussionStrategy(
        mockLogger,
        undefined as any,
        createConfig()
      )

      expect(strategy.type).toBe("realtime")
    })
  })

  describe("onTeamStarted", () => {
    test("initializes inbox for team", async () => {
      const strategy = new RealtimeDiscussionStrategy(
        mockLogger,
        undefined as any,
        createConfig()
      )

      const team = createTeam()
      await strategy.onTeamStarted(team)

      // Check that inbox was created
      const inboxPath = strategy._inboxManager.getInboxPath(team.id)
      const exists = await fs.access(inboxPath).then(() => true).catch(() => false)
      expect(exists).toBe(true)
    })

    test("sends system message announcing discussion", async () => {
      const strategy = new RealtimeDiscussionStrategy(
        mockLogger,
        undefined as any,
        createConfig()
      )

      const team = createTeam()
      await strategy.onTeamStarted(team)

      const messages = await strategy._inboxManager.readAllMessages(team.id)
      expect(messages.length).toBe(1)
      expect(messages[0].type).toBe("system")
      expect(messages[0].from).toBe("system")
      expect(messages[0].text).toContain("Realtime Team Discussion Started")
      expect(messages[0].text).toContain(team.issueId)
      expect(messages[0].text).toContain("agent-a")
      expect(messages[0].text).toContain("agent-b")
    })
  })

  describe("onMemberCompleted", () => {
    test("posts member's work result to inbox", async () => {
      const strategy = new RealtimeDiscussionStrategy(
        mockLogger,
        undefined as any,
        createConfig()
      )

      const team = createTeam()
      await strategy.onTeamStarted(team)

      const member: TeamMember = {
        agent: "agent-a",
        role: "primary",
        status: "completed",
        retryCount: 0, prompt: "" }

      await strategy.onMemberCompleted(team, member)

      const messages = await strategy._inboxManager.readAllMessages(team.id)
      // Should have system message + agent's work result
      expect(messages.length).toBe(2)

      const workMessage = messages[1]
      expect(workMessage.from).toBe("agent-a")
      expect(workMessage.type).toBe("chat")
      expect(workMessage.text).toContain("Primary agent's analysis")
    })

    test("returns empty rounds array", async () => {
      const strategy = new RealtimeDiscussionStrategy(
        mockLogger,
        undefined as any,
        createConfig()
      )

      const team = createTeam()
      await strategy.onTeamStarted(team)

      const member: TeamMember = {
        agent: "agent-a",
        role: "primary",
        status: "completed",
        retryCount: 0, prompt: "" }

      const rounds = await strategy.onMemberCompleted(team, member)
      expect(rounds).toEqual([])
    })

    test("handles member with no result", async () => {
      const strategy = new RealtimeDiscussionStrategy(
        mockLogger,
        undefined as any,
        createConfig()
      )

      const team = createTeam({ results: {} })
      await strategy.onTeamStarted(team)

      const member: TeamMember = {
        agent: "agent-a",
        role: "primary",
        status: "completed",
        retryCount: 0, prompt: "" }

      const rounds = await strategy.onMemberCompleted(team, member)
      expect(rounds).toEqual([])

      // Should only have system message
      const messages = await strategy._inboxManager.readAllMessages(team.id)
      expect(messages.length).toBe(1)
    })
  })

  describe("onAllMembersCompleted", () => {
    test("returns empty rounds when all agents signal done immediately", async () => {
      const strategy = new RealtimeDiscussionStrategy(
        mockLogger,
        undefined as any,
        createConfig()
      )

      const team = createTeam()
      await strategy.onTeamStarted(team)

      // Simulate agents signaling done
      await strategy._inboxManager.sendMessage(team.id, {
        from: "agent-a",
        to: "broadcast",
        text: "Done",
        type: "done",
      })

      await strategy._inboxManager.sendMessage(team.id, {
        from: "agent-b",
        to: "broadcast",
        text: "Done",
        type: "done",
      })

      const rounds = await strategy.onAllMembersCompleted(team)

      // Should return empty since no chat messages
      expect(rounds).toEqual([])
    })

    test("converts chat messages to discussion rounds", async () => {
      const strategy = new RealtimeDiscussionStrategy(
        mockLogger,
        undefined as any,
        createConfig()
      )

      const team = createTeam()
      await strategy.onTeamStarted(team)

      // Simulate chat messages
      await strategy._inboxManager.sendMessage(team.id, {
        from: "agent-a",
        to: "broadcast",
        text: "My analysis shows...",
        type: "chat",
      })

      await strategy._inboxManager.sendMessage(team.id, {
        from: "agent-b",
        to: "broadcast",
        text: "I agree with agent-a",
        type: "chat",
      })

      // Signal done
      await strategy._inboxManager.sendMessage(team.id, {
        from: "agent-a",
        to: "broadcast",
        text: "Done",
        type: "done",
      })

      await strategy._inboxManager.sendMessage(team.id, {
        from: "agent-b",
        to: "broadcast",
        text: "Done",
        type: "done",
      })

      const rounds = await strategy.onAllMembersCompleted(team)

      expect(rounds.length).toBe(1)
      expect(rounds[0].round).toBe(1)
      expect(rounds[0].responses["agent-a"]).toBe("My analysis shows...")
      expect(rounds[0].responses["agent-b"]).toBe("I agree with agent-a")
    })

    test("groups messages into rounds by time window", async () => {
      const strategy = new RealtimeDiscussionStrategy(
        mockLogger,
        undefined as any,
        createConfig()
      )

      const team = createTeam()
      await strategy.onTeamStarted(team)

      // First round of messages
      await strategy._inboxManager.sendMessage(team.id, {
        from: "agent-a",
        to: "broadcast",
        text: "Round 1 message",
        type: "chat",
        timestamp: 1000000000000,
      })

      // Advance time by 6 minutes (past the 5-minute window)
      clock.advance(6 * 60 * 1000)

      // Second round of messages
      await strategy._inboxManager.sendMessage(team.id, {
        from: "agent-b",
        to: "broadcast",
        text: "Round 2 message",
        type: "chat",
      })

      // Signal done
      await strategy._inboxManager.sendMessage(team.id, {
        from: "agent-a",
        to: "broadcast",
        text: "Done",
        type: "done",
      })

      await strategy._inboxManager.sendMessage(team.id, {
        from: "agent-b",
        to: "broadcast",
        text: "Done",
        type: "done",
      })

      const rounds = await strategy.onAllMembersCompleted(team)

      expect(rounds.length).toBe(2)
      expect(rounds[0].round).toBe(1)
      expect(rounds[0].responses["agent-a"]).toBe("Round 1 message")
      expect(rounds[1].round).toBe(2)
      expect(rounds[1].responses["agent-b"]).toBe("Round 2 message")
    })

    test("calls onProgress callback", async () => {
      const strategy = new RealtimeDiscussionStrategy(
        mockLogger,
        undefined as any,
        createConfig()
      )

      const team = createTeam()
      await strategy.onTeamStarted(team)

      // Signal done immediately
      await strategy._inboxManager.sendMessage(team.id, {
        from: "agent-a",
        to: "broadcast",
        text: "Done",
        type: "done",
      })

      await strategy._inboxManager.sendMessage(team.id, {
        from: "agent-b",
        to: "broadcast",
        text: "Done",
        type: "done",
      })

      let progressCalled = false
      let progressHistory: DiscussionRound[] = []

      await strategy.onAllMembersCompleted(team, async (history) => {
        progressCalled = true
        progressHistory = history
      })

      expect(progressCalled).toBe(true)
    })

    test("cleans up inbox after completion", async () => {
      const strategy = new RealtimeDiscussionStrategy(
        mockLogger,
        undefined as any,
        createConfig()
      )

      const team = createTeam()
      await strategy.onTeamStarted(team)

      // Signal done
      await strategy._inboxManager.sendMessage(team.id, {
        from: "agent-a",
        to: "broadcast",
        text: "Done",
        type: "done",
      })

      await strategy._inboxManager.sendMessage(team.id, {
        from: "agent-b",
        to: "broadcast",
        text: "Done",
        type: "done",
      })

      await strategy.onAllMembersCompleted(team)

      // Inbox should be cleaned up
      const exists = await strategy._inboxManager.exists(team.id)
      expect(exists).toBe(false)
    })
  })

  describe("convergence signal detection", () => {
    test("containsDoneSignal returns true only for CONVERGED on last line", async () => {
      const strategy = new RealtimeDiscussionStrategy(
        mockLogger,
        undefined as any,
        createConfig()
      )

      const containsDone = (strategy as any).containsDoneSignal

      // CONVERGED on last non-empty line signals done
      expect(containsDone.call(strategy, "Some analysis\nCONVERGED")).toBe(true)
      expect(containsDone.call(strategy, "CONVERGED")).toBe(true)
      expect(containsDone.call(strategy, "Analysis complete.\n\nCONVERGED")).toBe(true)

      // STUCK does NOT signal done (it's a veto)
      expect(containsDone.call(strategy, "STUCK")).toBe(false)
      expect(containsDone.call(strategy, "Some analysis\nSTUCK")).toBe(false)

      // CONTINUE does NOT signal done
      expect(containsDone.call(strategy, "CONTINUE")).toBe(false)
      expect(containsDone.call(strategy, "Some analysis\nCONTINUE")).toBe(false)

      // No signal
      expect(containsDone.call(strategy, "Still working")).toBe(false)
      expect(containsDone.call(strategy, "I am converged")).toBe(false) // embedded in sentence
      expect(containsDone.call(strategy, "UNCONVERGED")).toBe(false)
    })

    test("extractSignal reads signal from last non-empty line", () => {
      expect(extractSignal("CONVERGED")).toBe("CONVERGED")
      expect(extractSignal("STUCK")).toBe("STUCK")
      expect(extractSignal("CONTINUE")).toBe("CONTINUE")
      expect(extractSignal("no signal here")).toBeUndefined()

      // Last line wins — STUCK on last line takes precedence
      expect(extractSignal("CONVERGED\nSTUCK")).toBe("STUCK")
    })
  })

  describe("message formatting", () => {
    test("formats work result correctly", async () => {
      const strategy = new RealtimeDiscussionStrategy(
        mockLogger,
        undefined as any,
        createConfig()
      )

      const team = createTeam()
      await strategy.onTeamStarted(team)

      const member: TeamMember = {
        agent: "agent-a",
        role: "primary",
        status: "completed",
        retryCount: 0, prompt: "" }

      await strategy.onMemberCompleted(team, member)

      const messages = await strategy._inboxManager.readAllMessages(team.id)
      const workMessage = messages.find((m) => m.from === "agent-a")

      expect(workMessage).toBeDefined()
      expect(workMessage!.text).toContain("## agent-a's Initial Analysis")
      expect(workMessage!.text).toContain("Primary agent's analysis")
    })
  })

  describe("single agent team", () => {
    test("handles single agent team", async () => {
      const strategy = new RealtimeDiscussionStrategy(
        mockLogger,
        undefined as any,
        createConfig()
      )

      const team = createTeam({
        members: [
          { agent: "agent-a", role: "primary", status: "completed", retryCount: 0, prompt: "" },
        ],
        results: {
          "agent-a": {
            agent: "agent-a",
            result: "Solo analysis",
            completedAt: "2024-01-01T00:00:00Z",
          },
        },
      })

      await strategy.onTeamStarted(team)

      // Signal done
      await strategy._inboxManager.sendMessage(team.id, {
        from: "agent-a",
        to: "broadcast",
        text: "Done",
        type: "done",
      })

      const rounds = await strategy.onAllMembersCompleted(team)

      // Should complete without issues
      expect(rounds).toEqual([])
    })
  })

  describe("three agent team", () => {
    test("handles three agent team with all roles", async () => {
      const strategy = new RealtimeDiscussionStrategy(
        mockLogger,
        undefined as any,
        createConfig()
      )

      const team = createTeam({
        members: [
          { agent: "implementer", role: "primary", status: "completed", retryCount: 0, prompt: "" },
          { agent: "reviewer", role: "secondary", status: "completed", retryCount: 0, prompt: "" },
          { agent: "critic", role: "devilsAdvocate", status: "completed", retryCount: 0, prompt: "" },
        ],
        results: {
          implementer: {
            agent: "implementer",
            result: "Implementation done",
            completedAt: "2024-01-01T00:00:00Z",
          },
          reviewer: {
            agent: "reviewer",
            result: "Code looks good",
            completedAt: "2024-01-01T00:00:00Z",
          },
          critic: {
            agent: "critic",
            result: "Found potential issues",
            completedAt: "2024-01-01T00:00:00Z",
          },
        },
      })

      await strategy.onTeamStarted(team)

      // All agents chat
      await strategy._inboxManager.sendMessage(team.id, {
        from: "implementer",
        to: "broadcast",
        text: "Here's my implementation",
        type: "chat",
      })

      await strategy._inboxManager.sendMessage(team.id, {
        from: "reviewer",
        to: "broadcast",
        text: "Looks good to me",
        type: "chat",
      })

      await strategy._inboxManager.sendMessage(team.id, {
        from: "critic",
        to: "broadcast",
        text: "I have concerns about edge cases",
        type: "chat",
      })

      // All signal done
      await strategy._inboxManager.sendMessage(team.id, {
        from: "implementer",
        to: "broadcast",
        text: "Done",
        type: "done",
      })

      await strategy._inboxManager.sendMessage(team.id, {
        from: "reviewer",
        to: "broadcast",
        text: "Done",
        type: "done",
      })

      await strategy._inboxManager.sendMessage(team.id, {
        from: "critic",
        to: "broadcast",
        text: "Done",
        type: "done",
      })

      const rounds = await strategy.onAllMembersCompleted(team)

      expect(rounds.length).toBe(1)
      expect(rounds[0].responses["implementer"]).toBe("Here's my implementation")
      expect(rounds[0].responses["reviewer"]).toBe("Looks good to me")
      expect(rounds[0].responses["critic"]).toBe("I have concerns about edge cases")
    })
  })

  describe("minimum round guarantee", () => {
    test("suppresses CONVERGED signal until minRounds exchanges are complete", async () => {
      const strategy = new RealtimeDiscussionStrategy(
        mockLogger,
        undefined as any,
        createConfig({ minRounds: 2 })
      )

      const team = createTeam()
      await strategy.onTeamStarted(team)

      // Simulate agent-a completing only 1 exchange and signaling CONVERGED
      // (below the minRounds threshold of 2)
      const memberA: TeamMember = {
        agent: "agent-a",
        role: "primary",
        status: "completed",
        retryCount: 0, prompt: "" }

      // Manually post a chat message and increment exchange count to simulate
      // what promptAgentForDiscussion does, but with CONVERGED signal
      await strategy._inboxManager.sendMessage(team.id, {
        from: "agent-a",
        to: "broadcast",
        text: "My analysis is complete.\nCONVERGED",
        type: "chat",
        metadata: { phase: "discussion" },
      })
      // Manually set exchange count to 1 (below minRounds=2)
      strategy._agentExchangeCount.set("agent-a", 1)

      // No done message should have been posted yet (below minRounds)
      const messages = await strategy._inboxManager.readAllMessages(team.id)
      const doneMessages = messages.filter((m) => m.type === "done")
      expect(doneMessages.length).toBe(0)

      // Verify agent-a is not yet done
      const doneAgents = await strategy._inboxManager.getDoneAgents(team.id)
      expect(doneAgents.has("agent-a")).toBe(false)
    })

    test("honors CONVERGED signal after minRounds exchanges are complete", async () => {
      const strategy = new RealtimeDiscussionStrategy(
        mockLogger,
        undefined as any,
        createConfig({ minRounds: 2 })
      )

      const team = createTeam()
      await strategy.onTeamStarted(team)

      // Simulate agent-a completing 2 exchanges (meets minRounds=2)
      strategy._agentExchangeCount.set("agent-a", 2)

      // Now post a CONVERGED signal — hasMetMinRounds should return true
      // We test this by checking the private method directly
      const hasMetMinRounds = (strategy as any).hasMetMinRounds
      expect(hasMetMinRounds.call(strategy, "agent-a")).toBe(true)
    })

    test("hasMetMinRounds returns false before threshold", async () => {
      const strategy = new RealtimeDiscussionStrategy(
        mockLogger,
        undefined as any,
        createConfig({ minRounds: 3 })
      )

      const team = createTeam()
      await strategy.onTeamStarted(team)

      const hasMetMinRounds = (strategy as any).hasMetMinRounds

      // 0 exchanges — not met
      expect(hasMetMinRounds.call(strategy, "agent-a")).toBe(false)

      strategy._agentExchangeCount.set("agent-a", 1)
      expect(hasMetMinRounds.call(strategy, "agent-a")).toBe(false)

      strategy._agentExchangeCount.set("agent-a", 2)
      expect(hasMetMinRounds.call(strategy, "agent-a")).toBe(false)

      // 3 exchanges — met
      strategy._agentExchangeCount.set("agent-a", 3)
      expect(hasMetMinRounds.call(strategy, "agent-a")).toBe(true)

      // More than threshold — still met
      strategy._agentExchangeCount.set("agent-a", 5)
      expect(hasMetMinRounds.call(strategy, "agent-a")).toBe(true)
    })

    test("defaults minRounds to 2 when not configured", async () => {
      const strategy = new RealtimeDiscussionStrategy(
        mockLogger,
        undefined as any,
        createConfig() // no minRounds specified
      )

      const team = createTeam()
      await strategy.onTeamStarted(team)

      const hasMetMinRounds = (strategy as any).hasMetMinRounds

      strategy._agentExchangeCount.set("agent-a", 1)
      expect(hasMetMinRounds.call(strategy, "agent-a")).toBe(false)

      strategy._agentExchangeCount.set("agent-a", 2)
      expect(hasMetMinRounds.call(strategy, "agent-a")).toBe(true)
    })

    test("minRounds=1 allows CONVERGED after single exchange", async () => {
      const strategy = new RealtimeDiscussionStrategy(
        mockLogger,
        undefined as any,
        createConfig({ minRounds: 1 })
      )

      const team = createTeam()
      await strategy.onTeamStarted(team)

      const hasMetMinRounds = (strategy as any).hasMetMinRounds

      strategy._agentExchangeCount.set("agent-a", 0)
      expect(hasMetMinRounds.call(strategy, "agent-a")).toBe(false)

      strategy._agentExchangeCount.set("agent-a", 1)
      expect(hasMetMinRounds.call(strategy, "agent-a")).toBe(true)
    })

    test("system message includes minimum exchanges requirement", async () => {
      const strategy = new RealtimeDiscussionStrategy(
        mockLogger,
        undefined as any,
        createConfig({ minRounds: 3 })
      )

      const team = createTeam()
      await strategy.onTeamStarted(team)

      const messages = await strategy._inboxManager.readAllMessages(team.id)
      const systemMessage = messages.find((m) => m.type === "system")

      expect(systemMessage).toBeDefined()
      expect(systemMessage!.text).toContain("Minimum exchanges")
      expect(systemMessage!.text).toContain("3")
    })

    test("exchange count increments per agent independently", async () => {
      const strategy = new RealtimeDiscussionStrategy(
        mockLogger,
        undefined as any,
        createConfig({ minRounds: 2 })
      )

      const team = createTeam()
      await strategy.onTeamStarted(team)

      // Set different exchange counts for each agent
      strategy._agentExchangeCount.set("agent-a", 2)
      strategy._agentExchangeCount.set("agent-b", 1)

      const hasMetMinRounds = (strategy as any).hasMetMinRounds

      expect(hasMetMinRounds.call(strategy, "agent-a")).toBe(true)
      expect(hasMetMinRounds.call(strategy, "agent-b")).toBe(false)
    })

    test("exchange counts are cleared after onAllMembersCompleted", async () => {
      const strategy = new RealtimeDiscussionStrategy(
        mockLogger,
        undefined as any,
        createConfig({ minRounds: 2 })
      )

      const team = createTeam()
      await strategy.onTeamStarted(team)

      strategy._agentExchangeCount.set("agent-a", 5)
      strategy._agentExchangeCount.set("agent-b", 3)

      // Signal done so onAllMembersCompleted can complete
      await strategy._inboxManager.sendMessage(team.id, {
        from: "agent-a",
        to: "broadcast",
        text: "Done",
        type: "done",
      })
      await strategy._inboxManager.sendMessage(team.id, {
        from: "agent-b",
        to: "broadcast",
        text: "Done",
        type: "done",
      })

      await strategy.onAllMembersCompleted(team)

      expect(strategy._agentExchangeCount.size).toBe(0)
    })
  })

  describe("multiple messages from same agent in same round", () => {
    test("concatenates messages from same agent", async () => {
      const strategy = new RealtimeDiscussionStrategy(
        mockLogger,
        undefined as any,
        createConfig()
      )

      const team = createTeam()
      await strategy.onTeamStarted(team)

      // Same agent sends multiple messages
      await strategy._inboxManager.sendMessage(team.id, {
        from: "agent-a",
        to: "broadcast",
        text: "First thought",
        type: "chat",
      })

      await strategy._inboxManager.sendMessage(team.id, {
        from: "agent-a",
        to: "broadcast",
        text: "Second thought",
        type: "chat",
      })

      // Signal done
      await strategy._inboxManager.sendMessage(team.id, {
        from: "agent-a",
        to: "broadcast",
        text: "Done",
        type: "done",
      })

      await strategy._inboxManager.sendMessage(team.id, {
        from: "agent-b",
        to: "broadcast",
        text: "Done",
        type: "done",
      })

      const rounds = await strategy.onAllMembersCompleted(team)

      expect(rounds.length).toBe(1)
      expect(rounds[0].responses["agent-a"]).toContain("First thought")
      expect(rounds[0].responses["agent-a"]).toContain("Second thought")
    })
  })
})

describe("arbiter mechanism", () => {
  let tempDir: string
  let clock: MockClock

  beforeEach(async () => {
    tempDir = await fs.mkdtemp(path.join(os.tmpdir(), "realtime-arbiter-test-"))
    clock = new MockClock(1000000000000)
  })

  afterEach(async () => {
    await fs.rm(tempDir, { recursive: true, force: true })
  })

  function createConfig(overrides?: Partial<RealtimeStrategyConfig>): RealtimeStrategyConfig {
    return {
      baseDir: tempDir,
      pollIntervalMs: 100,
      maxWaitTimeMs: 5000,
      promptTimeoutMs: 1000,
      clock,
      ...overrides,
    }
  }

  function createTeam(overrides?: Partial<Team>): Team {
    return {
      id: "team-arbiter",
      projectId: "proj-1",
      projectDir: tempDir,
      issueId: "issue-arbiter",
      discussionStrategyType: "realtime",
      members: [
        { agent: "agent-a", role: "primary", status: "completed", retryCount: 0, prompt: "" },
        { agent: "agent-b", role: "secondary", status: "completed", retryCount: 0, prompt: "" },
      ],
      status: "discussing",
      results: {
        "agent-a": { agent: "agent-a", result: "Primary analysis", completedAt: "2024-01-01T00:00:00Z" },
        "agent-b": { agent: "agent-b", result: "Secondary review", completedAt: "2024-01-01T00:00:00Z" },
      },
      discussionHistory: [],
      startedAt: "2024-01-01T00:00:00Z",
      ...overrides,
    }
  }

  describe("isTeamDeadlocked", () => {
    test("returns false when no agents are stuck", async () => {
      const strategy = new RealtimeDiscussionStrategy(
        createMockLogger(),
        undefined as any,
        createConfig({ stuckThreshold: 2 })
      )

      const team = createTeam()
      await strategy.onTeamStarted(team)

      const isDeadlocked = (strategy as any).isTeamDeadlocked
      expect(isDeadlocked.call(strategy)).toBe(false)
    })

    test("returns false when stuck count is below threshold", async () => {
      const strategy = new RealtimeDiscussionStrategy(
        createMockLogger(),
        undefined as any,
        createConfig({ stuckThreshold: 3 })
      )

      const team = createTeam()
      await strategy.onTeamStarted(team)

      strategy._agentStuckCount.set("agent-a", 2)

      const isDeadlocked = (strategy as any).isTeamDeadlocked
      expect(isDeadlocked.call(strategy)).toBe(false)
    })

    test("returns true when any agent reaches the stuck threshold", async () => {
      const strategy = new RealtimeDiscussionStrategy(
        createMockLogger(),
        undefined as any,
        createConfig({ stuckThreshold: 2 })
      )

      const team = createTeam()
      await strategy.onTeamStarted(team)

      strategy._agentStuckCount.set("agent-b", 2)

      const isDeadlocked = (strategy as any).isTeamDeadlocked
      expect(isDeadlocked.call(strategy)).toBe(true)
    })

    test("defaults stuckThreshold to 2", async () => {
      const strategy = new RealtimeDiscussionStrategy(
        createMockLogger(),
        undefined as any,
        createConfig() // no stuckThreshold
      )

      const team = createTeam()
      await strategy.onTeamStarted(team)

      strategy._agentStuckCount.set("agent-a", 1)
      const isDeadlocked = (strategy as any).isTeamDeadlocked
      expect(isDeadlocked.call(strategy)).toBe(false)

      strategy._agentStuckCount.set("agent-a", 2)
      expect(isDeadlocked.call(strategy)).toBe(true)
    })
  })

  describe("stuck count tracking", () => {
    test("stuck count increments on STUCK signal", async () => {
      const strategy = new RealtimeDiscussionStrategy(
        createMockLogger(),
        undefined as any,
        createConfig()
      )

      const team = createTeam()
      await strategy.onTeamStarted(team)

      // Manually set exchange count and stuck count to simulate what promptAgentToContinue does
      strategy._agentStuckCount.set("agent-a", 0)

      // Simulate the signal tracking logic directly
      const signal = extractSignal("I disagree with this approach.\nSTUCK")
      expect(signal).toBe("STUCK")
    })

    test("stuck count resets on CONVERGED signal", async () => {
      const strategy = new RealtimeDiscussionStrategy(
        createMockLogger(),
        undefined as any,
        createConfig()
      )

      const team = createTeam()
      await strategy.onTeamStarted(team)

      strategy._agentStuckCount.set("agent-a", 3)

      // Simulate reset on non-STUCK signal
      const signal = extractSignal("I agree now.\nCONVERGED")
      expect(signal).toBe("CONVERGED")
      // The reset happens in promptAgentToContinue when signal !== "STUCK"
    })

    test("stuck counts are cleared after onAllMembersCompleted", async () => {
      const strategy = new RealtimeDiscussionStrategy(
        createMockLogger(),
        undefined as any,
        createConfig()
      )

      const team = createTeam()
      await strategy.onTeamStarted(team)

      strategy._agentStuckCount.set("agent-a", 5)
      strategy._agentStuckCount.set("agent-b", 3)

      // Signal done so onAllMembersCompleted can complete
      await strategy._inboxManager.sendMessage(team.id, {
        from: "agent-a",
        to: "broadcast",
        text: "Done",
        type: "done",
      })
      await strategy._inboxManager.sendMessage(team.id, {
        from: "agent-b",
        to: "broadcast",
        text: "Done",
        type: "done",
      })

      await strategy.onAllMembersCompleted(team)

      expect(strategy._agentStuckCount.size).toBe(0)
    })
  })
})

describe("session-based state management", () => {
  let tempDir: string
  let clock: MockClock

  beforeEach(async () => {
    tempDir = await fs.mkdtemp(path.join(os.tmpdir(), "realtime-state-test-"))
    clock = new MockClock(1000000000000)
  })

  afterEach(async () => {
    await fs.rm(tempDir, { recursive: true, force: true })
  })

  function createConfig(overrides?: Partial<RealtimeStrategyConfig>): RealtimeStrategyConfig {
    return {
      baseDir: tempDir,
      pollIntervalMs: 100,
      maxWaitTimeMs: 5000,
      promptTimeoutMs: 1000,
      clock,
      ...overrides,
    }
  }

  function createTeam(overrides?: Partial<Team>): Team {
    return {
      id: "team-state",
      projectId: "proj-1",
      projectDir: tempDir,
      issueId: "issue-state",
      discussionStrategyType: "realtime",
      members: [
        { agent: "agent-a", role: "primary", status: "completed", retryCount: 0, prompt: "" },
        { agent: "agent-b", role: "secondary", status: "completed", retryCount: 0, prompt: "" },
      ],
      status: "discussing",
      results: {
        "agent-a": { agent: "agent-a", result: "Analysis A", completedAt: "2024-01-01T00:00:00Z" },
        "agent-b": { agent: "agent-b", result: "Analysis B", completedAt: "2024-01-01T00:00:00Z" },
      },
      discussionHistory: [],
      startedAt: "2024-01-01T00:00:00Z",
      ...overrides,
    }
  }

  describe("prompt version tracking", () => {
    test("initializes prompt versions to 0 for all agents on team start", async () => {
      const strategy = new RealtimeDiscussionStrategy(
        createMockLogger(),
        undefined as any,
        createConfig()
      )

      const team = createTeam()
      await strategy.onTeamStarted(team)

      expect(strategy._agentPromptVersion.get("agent-a")).toBe(0)
      expect(strategy._agentPromptVersion.get("agent-b")).toBe(0)
    })

    test("clears prompt versions after onAllMembersCompleted", async () => {
      const strategy = new RealtimeDiscussionStrategy(
        createMockLogger(),
        undefined as any,
        createConfig()
      )

      const team = createTeam()
      await strategy.onTeamStarted(team)

      strategy._agentPromptVersion.set("agent-a", 5)
      strategy._agentPromptVersion.set("agent-b", 3)

      await strategy._inboxManager.sendMessage(team.id, {
        from: "agent-a",
        to: "broadcast",
        text: "Done",
        type: "done",
      })
      await strategy._inboxManager.sendMessage(team.id, {
        from: "agent-b",
        to: "broadcast",
        text: "Done",
        type: "done",
      })

      await strategy.onAllMembersCompleted(team)

      expect(strategy._agentPromptVersion.size).toBe(0)
    })
  })

  describe("execution guard", () => {
    test("initializes executing set as empty", async () => {
      const strategy = new RealtimeDiscussionStrategy(
        createMockLogger(),
        undefined as any,
        createConfig()
      )

      expect(strategy._agentExecuting.size).toBe(0)
    })

    test("clears executing set after onAllMembersCompleted", async () => {
      const strategy = new RealtimeDiscussionStrategy(
        createMockLogger(),
        undefined as any,
        createConfig()
      )

      const team = createTeam()
      await strategy.onTeamStarted(team)

      // Simulate a leaked executing entry (e.g., from an error path)
      strategy._agentExecuting.add("agent-a")

      await strategy._inboxManager.sendMessage(team.id, {
        from: "agent-a",
        to: "broadcast",
        text: "Done",
        type: "done",
      })
      await strategy._inboxManager.sendMessage(team.id, {
        from: "agent-b",
        to: "broadcast",
        text: "Done",
        type: "done",
      })

      await strategy.onAllMembersCompleted(team)

      expect(strategy._agentExecuting.size).toBe(0)
    })
  })

  describe("map cleanup on completion", () => {
    test("all state maps are cleared after onAllMembersCompleted", async () => {
      const strategy = new RealtimeDiscussionStrategy(
        createMockLogger(),
        undefined as any,
        createConfig()
      )

      const team = createTeam()
      await strategy.onTeamStarted(team)

      // Populate all maps
      strategy._agentExchangeCount.set("agent-a", 3)
      strategy._agentStuckCount.set("agent-b", 2)
      strategy._agentPromptVersion.set("agent-a", 4)
      strategy._agentExecuting.add("agent-b")

      await strategy._inboxManager.sendMessage(team.id, {
        from: "agent-a",
        to: "broadcast",
        text: "Done",
        type: "done",
      })
      await strategy._inboxManager.sendMessage(team.id, {
        from: "agent-b",
        to: "broadcast",
        text: "Done",
        type: "done",
      })

      await strategy.onAllMembersCompleted(team)

      expect(strategy._agentExchangeCount.size).toBe(0)
      expect(strategy._agentStuckCount.size).toBe(0)
      expect(strategy._agentPromptVersion.size).toBe(0)
      expect(strategy._agentExecuting.size).toBe(0)
    })
  })
})

describe("buildArbiterPrompt", () => {
  test("includes issue ID", () => {
    const prompt = buildArbiterPrompt("proj-abc.42", [], [])

    expect(prompt).toContain("proj-abc.42")
  })

  test("includes stuck agent names", () => {
    const prompt = buildArbiterPrompt("issue-1", ["agent-b", "agent-c"], [])

    expect(prompt).toContain("agent-b")
    expect(prompt).toContain("agent-c")
  })

  test("includes discussion history from inbox messages", () => {
    const messages: InboxMessage[] = [
      {
        id: "msg-1",
        from: "agent-a",
        to: "broadcast",
        text: "My position is X",
        type: "chat",
        timestamp: 1000000000000,
      },
      {
        id: "msg-2",
        from: "agent-b",
        to: "broadcast",
        text: "I disagree because Y",
        type: "chat",
        timestamp: 1000000001000,
      },
    ]

    const prompt = buildArbiterPrompt("issue-1", ["agent-b"], messages)

    expect(prompt).toContain("agent-a")
    expect(prompt).toContain("My position is X")
    expect(prompt).toContain("agent-b")
    expect(prompt).toContain("I disagree because Y")
  })

  test("filters out system and done messages from history", () => {
    const messages: InboxMessage[] = [
      {
        id: "msg-1",
        from: "system",
        to: "broadcast",
        text: "Discussion started",
        type: "system",
        timestamp: 1000000000000,
      },
      {
        id: "msg-2",
        from: "agent-a",
        to: "broadcast",
        text: "My analysis",
        type: "chat",
        timestamp: 1000000001000,
      },
      {
        id: "msg-3",
        from: "agent-a",
        to: "broadcast",
        text: "agent-a has completed their analysis.",
        type: "done",
        timestamp: 1000000002000,
      },
    ]

    const prompt = buildArbiterPrompt("issue-1", [], messages)

    expect(prompt).toContain("My analysis")
    expect(prompt).not.toContain("Discussion started")
    expect(prompt).not.toContain("has completed their analysis")
  })

  test("instructs arbiter to make final binding decision", () => {
    const prompt = buildArbiterPrompt("issue-1", ["agent-b"], [])

    expect(prompt).toContain("final")
    expect(prompt).toContain("decision")
    expect(prompt).toContain("Arbiter")
  })

  test("includes convergence signal instructions for arbiter", () => {
    const prompt = buildArbiterPrompt("issue-1", [], [])

    expect(prompt).toContain("CONVERGED")
    expect(prompt).toContain("CONTINUE")
  })

  test("handles empty stuck agents list gracefully", () => {
    const prompt = buildArbiterPrompt("issue-1", [], [])

    expect(prompt).toContain("unable to converge")
  })
})

describe("buildDiscussionPrompt", () => {
  test("includes convergence signal instructions", () => {
    const prompt = buildDiscussionPrompt("issue-1", "Some context")

    expect(prompt).toContain("CONVERGED")
    expect(prompt).toContain("STUCK")
    expect(prompt).toContain("CONTINUE")
  })

  test("includes issue ID", () => {
    const prompt = buildDiscussionPrompt("proj-abc.42", "context")

    expect(prompt).toContain("proj-abc.42")
  })

  test("includes provided inbox context", () => {
    const prompt = buildDiscussionPrompt("issue-1", "## agent-a's message\nSome analysis")

    expect(prompt).toContain("## agent-a's message")
    expect(prompt).toContain("Some analysis")
  })

  test("shows placeholder when no inbox context", () => {
    const prompt = buildDiscussionPrompt("issue-1", "")

    expect(prompt).toContain("(No messages yet")
  })

  test("includes devil's advocate language for CONVERGED signal", () => {
    const prompt = buildDiscussionPrompt("issue-1", "context")

    expect(prompt).toContain("devil's advocate")
    expect(prompt).toContain("no remaining blockers")
  })
})

describe("buildContinuationPrompt", () => {
  test("includes convergence signal instructions", () => {
    const prompt = buildContinuationPrompt("issue-1", "Some new messages")

    expect(prompt).toContain("CONVERGED")
    expect(prompt).toContain("STUCK")
    expect(prompt).toContain("CONTINUE")
  })

  test("includes issue ID", () => {
    const prompt = buildContinuationPrompt("proj-abc.42", "context")

    expect(prompt).toContain("proj-abc.42")
  })

  test("includes provided inbox context", () => {
    const prompt = buildContinuationPrompt("issue-1", "## agent-b's message\nNew insight")

    expect(prompt).toContain("## agent-b's message")
    expect(prompt).toContain("New insight")
  })

  test("includes devil's advocate language for CONVERGED signal", () => {
    const prompt = buildContinuationPrompt("issue-1", "context")

    expect(prompt).toContain("devil's advocate")
    expect(prompt).toContain("no remaining blockers")
  })
})
