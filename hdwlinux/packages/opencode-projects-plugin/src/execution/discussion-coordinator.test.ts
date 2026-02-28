/**
 * Tests for DiscussionCoordinator
 */

import { describe, test, expect } from "bun:test"
import {
  DiscussionCoordinator,
  type DiscussionCoordinatorConfig,
} from "./discussion-coordinator.js"
import { createMockLogger } from "../utils/testing/index.js"
import type { Team, DiscussionRound } from "./team-manager.js"

const mockLogger = createMockLogger()

const defaultConfig: DiscussionCoordinatorConfig = {
  discussionRoundTimeoutMs: 5 * 60 * 1000,
}

describe("DiscussionCoordinator", () => {
  describe("buildDiscussionContext", () => {
    test("includes primary agent implementation", () => {
      const coordinator = new DiscussionCoordinator(
        mockLogger,
        undefined as any,
        defaultConfig
      )

      const team: Team = {
        id: "team-123",
        projectId: "proj-1",
        projectDir: "/tmp/test",
        issueId: "issue-1",
        members: [
          { agent: "coder", role: "primary", status: "completed", retryCount: 0 },
          { agent: "reviewer", role: "secondary", status: "completed", retryCount: 0 },
        ],
        status: "discussing",
        discussionRounds: 2,
        currentRound: 1,
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

      const context = coordinator.buildDiscussionContext(team, 1, [])

      expect(context).toContain("## Primary Agent's Implementation")
      expect(context).toContain("Primary implementation details")
      expect(context).toContain("## Team Findings")
      expect(context).toContain("### reviewer")
      expect(context).toContain("Review findings")
    })

    test("includes previous discussion rounds", () => {
      const coordinator = new DiscussionCoordinator(
        mockLogger,
        undefined as any,
        defaultConfig
      )

      const team: Team = {
        id: "team-123",
        projectId: "proj-1",
        projectDir: "/tmp/test",
        issueId: "issue-1",
        members: [
          { agent: "coder", role: "primary", status: "completed", retryCount: 0 },
          { agent: "reviewer", role: "secondary", status: "completed", retryCount: 0 },
        ],
        status: "discussing",
        discussionRounds: 2,
        currentRound: 2,
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

      const context = coordinator.buildDiscussionContext(team, 2, discussionHistory)

      expect(context).toContain("## Previous Discussion")
      expect(context).toContain("### Round 1")
      expect(context).toContain("**coder:**")
      expect(context).toContain("Round 1 coder response")
      expect(context).toContain("**reviewer:**")
      expect(context).toContain("Round 1 reviewer response")
    })

    test("excludes previous discussion for round 1", () => {
      const coordinator = new DiscussionCoordinator(
        mockLogger,
        undefined as any,
        defaultConfig
      )

      const team: Team = {
        id: "team-123",
        projectId: "proj-1",
        projectDir: "/tmp/test",
        issueId: "issue-1",
        members: [
          { agent: "coder", role: "primary", status: "completed", retryCount: 0 },
        ],
        status: "discussing",
        discussionRounds: 2,
        currentRound: 1,
        results: {
          coder: { agent: "coder", result: "Work done", completedAt: "2024-01-01T00:00:00Z" },
        },
        discussionHistory: [],
        startedAt: "2024-01-01T00:00:00Z",
      }

      const context = coordinator.buildDiscussionContext(team, 1, [])

      expect(context).not.toContain("## Previous Discussion")
    })

    test("excludes primary from team findings section", () => {
      const coordinator = new DiscussionCoordinator(
        mockLogger,
        undefined as any,
        defaultConfig
      )

      const team: Team = {
        id: "team-123",
        projectId: "proj-1",
        projectDir: "/tmp/test",
        issueId: "issue-1",
        members: [
          { agent: "primary-agent", role: "primary", status: "completed", retryCount: 0 },
          { agent: "secondary-agent", role: "secondary", status: "completed", retryCount: 0 },
        ],
        status: "discussing",
        discussionRounds: 1,
        currentRound: 1,
        results: {
          "primary-agent": { agent: "primary-agent", result: "Primary work", completedAt: "2024-01-01T00:00:00Z" },
          "secondary-agent": { agent: "secondary-agent", result: "Secondary work", completedAt: "2024-01-01T00:00:00Z" },
        },
        discussionHistory: [],
        startedAt: "2024-01-01T00:00:00Z",
      }

      const context = coordinator.buildDiscussionContext(team, 1, [])

      // Primary should be in its own section, not in Team Findings
      expect(context).toContain("## Primary Agent's Implementation")
      expect(context).toContain("Primary work")
      expect(context).toContain("## Team Findings")
      expect(context).toContain("### secondary-agent")
      expect(context).toContain("Secondary work")
      // Primary should not appear under Team Findings
      expect(context).not.toContain("### primary-agent")
    })
  })
})
