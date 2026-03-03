/**
 * Tests for RealtimeDiscussionStrategy
 */

import { describe, test, expect, beforeEach, afterEach } from "bun:test"
import * as fs from "node:fs/promises"
import * as path from "node:path"
import * as os from "node:os"

import {
  RealtimeDiscussionStrategy,
  type RealtimeStrategyConfig,
} from "./realtime-discussion-strategy.js"
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
        { agent: "agent-a", role: "primary", status: "completed", retryCount: 0 },
        { agent: "agent-b", role: "secondary", status: "completed", retryCount: 0 },
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
        retryCount: 0,
      }

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
        retryCount: 0,
      }

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
        retryCount: 0,
      }

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

  describe("done signal detection", () => {
    test("detects DONE on its own line", async () => {
      const strategy = new RealtimeDiscussionStrategy(
        mockLogger,
        undefined as any,
        createConfig()
      )

      // Access private method via any cast for testing
      const containsDone = (strategy as any).containsDoneSignal

      // Positive cases - "DONE" on its own line
      expect(containsDone.call(strategy, "Some analysis\nDONE")).toBe(true)
      expect(containsDone.call(strategy, "DONE")).toBe(true)
      expect(containsDone.call(strategy, "done")).toBe(true)
      expect(containsDone.call(strategy, "Analysis complete.\n\nDONE")).toBe(true)
      expect(containsDone.call(strategy, "  DONE  ")).toBe(true) // whitespace trimmed

      // Negative cases - "DONE" not on its own line
      expect(containsDone.call(strategy, "Still working")).toBe(false)
      expect(containsDone.call(strategy, "I am done")).toBe(false) // "done" embedded in sentence
      expect(containsDone.call(strategy, "I AM NOT DONE")).toBe(false)
      expect(containsDone.call(strategy, "ABANDONED")).toBe(false)
      expect(containsDone.call(strategy, "This is my second round")).toBe(false)
      expect(containsDone.call(strategy, "UNDONE")).toBe(false)
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
        retryCount: 0,
      }

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
          { agent: "agent-a", role: "primary", status: "completed", retryCount: 0 },
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
          { agent: "implementer", role: "primary", status: "completed", retryCount: 0 },
          { agent: "reviewer", role: "secondary", status: "completed", retryCount: 0 },
          { agent: "critic", role: "devilsAdvocate", status: "completed", retryCount: 0 },
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
