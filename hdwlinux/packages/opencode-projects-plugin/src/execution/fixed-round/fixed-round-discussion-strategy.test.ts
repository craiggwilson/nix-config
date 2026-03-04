/**
 * Tests for FixedRoundDiscussionStrategy
 */

import { describe, test, expect, mock } from "bun:test"
import {
  FixedRoundDiscussionStrategy,
  type FixedRoundStrategyConfig,
} from "./fixed-round-discussion-strategy.js"
import { buildDiscussionContext } from "../discussion-context.js"
import { createMockLogger } from "../../utils/testing/index.js"
import type { Team, DiscussionRound } from "../team-manager.js"
import type { Clock } from "../../utils/clock/index.js"

const mockLogger = createMockLogger()

const defaultConfig: FixedRoundStrategyConfig = {
  rounds: 2,
  roundTimeoutMs: 5 * 60 * 1000,
}

/**
 * Create a mock clock that advances time predictably.
 */
function createMockClock(startTime = 0): Clock {
  let time = startTime
  return {
    now: () => time,
    toISOString: () => new Date(time).toISOString(),
    sleep: async (ms: number) => { time += ms },
  }
}

/**
 * Create a mock client that returns a canned response after one poll.
 */
function createMockClientWithResponse(responseText: string) {
  let promptCalled = false
  return {
    session: {
      prompt: async () => {
        promptCalled = true
        return {}
      },
      messages: async () => {
        if (!promptCalled) return { data: [] }
        return {
          data: [
            {
              info: { role: "assistant" },
              parts: [{ type: "text", text: responseText }],
            },
          ],
        }
      },
    },
  }
}

describe("FixedRoundDiscussionStrategy", () => {
  describe("buildDiscussionContext", () => {
    test("includes primary agent implementation", () => {
      const coordinator = new FixedRoundDiscussionStrategy(
        mockLogger,
        undefined as any,
        defaultConfig
      )

      const team: Team = {
        id: "team-123",
        projectId: "proj-1",
        projectDir: "/tmp/test",
        issueId: "issue-1",
          discussionStrategyType: "fixedRound",
        members: [
          { agent: "coder", role: "primary", status: "completed", retryCount: 0, prompt: "" },
          { agent: "reviewer", role: "secondary", status: "completed", retryCount: 0, prompt: "" },
        ],
        status: "discussing",
        results: {
          coder: {
            agent: "coder",
            result: "Primary implementation details",
            completedAt: "2024-01-01T00:00:00Z",
          },
          reviewer: {
            agent: "reviewer",
            result: "Review findings",
            completedAt: "2024-01-01T00:00:00Z",
          },
        },
        discussionHistory: [],
        startedAt: "2024-01-01T00:00:00Z",
      }

      const context = buildDiscussionContext(team, 1, [])

      expect(context).toContain("## Primary Agent's Implementation")
      expect(context).toContain("Primary implementation details")
      expect(context).toContain("## Team Findings")
      expect(context).toContain("### reviewer")
      expect(context).toContain("Review findings")
    })

    test("includes previous discussion rounds", () => {
      const coordinator = new FixedRoundDiscussionStrategy(
        mockLogger,
        undefined as any,
        defaultConfig
      )

      const team: Team = {
        id: "team-123",
        projectId: "proj-1",
        projectDir: "/tmp/test",
        issueId: "issue-1",
          discussionStrategyType: "fixedRound",
        members: [
          { agent: "coder", role: "primary", status: "completed", retryCount: 0, prompt: "" },
          { agent: "reviewer", role: "secondary", status: "completed", retryCount: 0, prompt: "" },
        ],
        status: "discussing",
        results: {
          coder: { agent: "coder", result: "Initial work", completedAt: "2024-01-01T00:00:00Z" },
          reviewer: { agent: "reviewer", result: "Initial review", completedAt: "2024-01-01T00:00:00Z" },
        },
        discussionHistory: [
          { round: 1, responses: { coder: "Round 1 coder response", reviewer: "Round 1 reviewer response" } },
        ],
        startedAt: "2024-01-01T00:00:00Z",
      }

      const discussionHistory: DiscussionRound[] = [
        { round: 1, responses: { coder: "Round 1 coder response", reviewer: "Round 1 reviewer response" } },
      ]

      const context = buildDiscussionContext(team, 2, discussionHistory)

      expect(context).toContain("## Previous Discussion")
      expect(context).toContain("### Round 1")
      expect(context).toContain("**coder:**")
      expect(context).toContain("Round 1 coder response")
      expect(context).toContain("**reviewer:**")
      expect(context).toContain("Round 1 reviewer response")
    })

    test("excludes previous discussion for round 1", () => {
      const coordinator = new FixedRoundDiscussionStrategy(
        mockLogger,
        undefined as any,
        defaultConfig
      )

      const team: Team = {
        id: "team-123",
        projectId: "proj-1",
        projectDir: "/tmp/test",
        issueId: "issue-1",
          discussionStrategyType: "fixedRound",
        members: [
          { agent: "coder", role: "primary", status: "completed", retryCount: 0, prompt: "" },
        ],
        status: "discussing",
        results: {
          coder: { agent: "coder", result: "Work done", completedAt: "2024-01-01T00:00:00Z" },
        },
        discussionHistory: [],
        startedAt: "2024-01-01T00:00:00Z",
      }

      const context = buildDiscussionContext(team, 1, [])

      expect(context).not.toContain("## Previous Discussion")
    })

    test("excludes primary from team findings section", () => {
      const coordinator = new FixedRoundDiscussionStrategy(
        mockLogger,
        undefined as any,
        defaultConfig
      )

      const team: Team = {
        id: "team-123",
        projectId: "proj-1",
        projectDir: "/tmp/test",
        issueId: "issue-1",
          discussionStrategyType: "fixedRound",
        members: [
          { agent: "primary-agent", role: "primary", status: "completed", retryCount: 0, prompt: "" },
          { agent: "secondary-agent", role: "secondary", status: "completed", retryCount: 0, prompt: "" },
        ],
        status: "discussing",
        results: {
          "primary-agent": { agent: "primary-agent", result: "Primary work", completedAt: "2024-01-01T00:00:00Z" },
          "secondary-agent": { agent: "secondary-agent", result: "Secondary work", completedAt: "2024-01-01T00:00:00Z" },
        },
        discussionHistory: [],
        startedAt: "2024-01-01T00:00:00Z",
      }

      const context = buildDiscussionContext(team, 1, [])

      // Primary should be in its own section, not in Team Findings
      expect(context).toContain("## Primary Agent's Implementation")
      expect(context).toContain("Primary work")
      expect(context).toContain("## Team Findings")
      expect(context).toContain("### secondary-agent")
      expect(context).toContain("Secondary work")
      // Primary should not appear under Team Findings
      expect(context).not.toContain("### primary-agent")
    })

    test("includes devil's advocate in team findings", () => {
      const coordinator = new FixedRoundDiscussionStrategy(
        mockLogger,
        undefined as any,
        defaultConfig
      )

      const team: Team = {
        id: "team-123",
        projectId: "proj-1",
        projectDir: "/tmp/test",
        issueId: "issue-1",
          discussionStrategyType: "fixedRound",
        members: [
          { agent: "implementer", role: "primary", status: "completed", retryCount: 0, prompt: "" },
          { agent: "reviewer", role: "secondary", status: "completed", retryCount: 0, prompt: "" },
          { agent: "critic", role: "devilsAdvocate", status: "completed", retryCount: 0, prompt: "" },
        ],
        status: "discussing",
        results: {
          implementer: { agent: "implementer", result: "Implementation done", completedAt: "2024-01-01T00:00:00Z" },
          reviewer: { agent: "reviewer", result: "Code looks good", completedAt: "2024-01-01T00:00:00Z" },
          critic: { agent: "critic", result: "Found potential issues", completedAt: "2024-01-01T00:00:00Z" },
        },
        discussionHistory: [],
        startedAt: "2024-01-01T00:00:00Z",
      }

      const context = buildDiscussionContext(team, 1, [])

      // Devil's advocate should be in Team Findings
      expect(context).toContain("### critic")
      expect(context).toContain("Found potential issues")
      // Both secondary and devil's advocate should be in Team Findings
      expect(context).toContain("### reviewer")
      expect(context).toContain("Code looks good")
    })

    test("builds context for 3-agent team with all roles", () => {
      const coordinator = new FixedRoundDiscussionStrategy(
        mockLogger,
        undefined as any,
        defaultConfig
      )

      const team: Team = {
        id: "team-3-agent",
        projectId: "proj-1",
        projectDir: "/tmp/test",
        issueId: "issue-1",
          discussionStrategyType: "fixedRound",
        members: [
          { agent: "typescript-expert", role: "primary", status: "completed", retryCount: 0, prompt: "" },
          { agent: "code-reviewer", role: "secondary", status: "completed", retryCount: 0, prompt: "" },
          { agent: "security-expert", role: "devilsAdvocate", status: "completed", retryCount: 0, prompt: "" },
        ],
        status: "discussing",
        results: {
          "typescript-expert": { agent: "typescript-expert", result: "Implemented auth flow", completedAt: "2024-01-01T00:00:00Z" },
          "code-reviewer": { agent: "code-reviewer", result: "Code structure is clean", completedAt: "2024-01-01T00:00:00Z" },
          "security-expert": { agent: "security-expert", result: "Security concerns identified", completedAt: "2024-01-01T00:00:00Z" },
        },
        discussionHistory: [],
        startedAt: "2024-01-01T00:00:00Z",
      }

      const context = buildDiscussionContext(team, 1, [])

      // Verify primary agent section
      expect(context).toContain("## Primary Agent's Implementation")
      expect(context).toContain("Implemented auth flow")
      
      // Verify team findings section has both reviewers
      expect(context).toContain("## Team Findings")
      expect(context).toContain("### code-reviewer")
      expect(context).toContain("Code structure is clean")
      expect(context).toContain("### security-expert")
      expect(context).toContain("Security concerns identified")
    })

    test("multiple discussion rounds accumulate history", () => {
      const coordinator = new FixedRoundDiscussionStrategy(
        mockLogger,
        undefined as any,
        defaultConfig
      )

      const team: Team = {
        id: "team-multi-round",
        projectId: "proj-1",
        projectDir: "/tmp/test",
        issueId: "issue-1",
          discussionStrategyType: "fixedRound",
        members: [
          { agent: "agent-a", role: "primary", status: "completed", retryCount: 0, prompt: "" },
          { agent: "agent-b", role: "secondary", status: "completed", retryCount: 0, prompt: "" },
        ],
        status: "discussing",
        results: {
          "agent-a": { agent: "agent-a", result: "Initial work", completedAt: "2024-01-01T00:00:00Z" },
          "agent-b": { agent: "agent-b", result: "Initial review", completedAt: "2024-01-01T00:00:00Z" },
        },
        discussionHistory: [
          { round: 1, responses: { "agent-a": "Round 1 A", "agent-b": "Round 1 B" } },
          { round: 2, responses: { "agent-a": "Round 2 A", "agent-b": "Round 2 B" } },
        ],
        startedAt: "2024-01-01T00:00:00Z",
      }

      const discussionHistory: DiscussionRound[] = [
        { round: 1, responses: { "agent-a": "Round 1 A", "agent-b": "Round 1 B" } },
        { round: 2, responses: { "agent-a": "Round 2 A", "agent-b": "Round 2 B" } },
      ]

      const context = buildDiscussionContext(team, 3, discussionHistory)

      // Verify all previous rounds are included
      expect(context).toContain("## Previous Discussion")
      expect(context).toContain("### Round 1")
      expect(context).toContain("Round 1 A")
      expect(context).toContain("Round 1 B")
      expect(context).toContain("### Round 2")
      expect(context).toContain("Round 2 A")
      expect(context).toContain("Round 2 B")
    })
  })

})
