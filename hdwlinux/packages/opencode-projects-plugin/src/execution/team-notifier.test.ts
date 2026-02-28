/**
 * Tests for TeamNotifier
 */

import { describe, test, expect } from "bun:test"
import { TeamNotifier } from "./team-notifier.js"
import { createMockLogger } from "../utils/testing/index.js"
import type { Team } from "./team-manager.js"

const mockLogger = createMockLogger()

describe("TeamNotifier", () => {
  describe("buildTeamNotification", () => {
    test("builds basic XML notification", () => {
      const notifier = new TeamNotifier(mockLogger, undefined as any)

      const team: Team = {
        id: "team-123",
        projectId: "proj-1",
        projectDir: "/tmp/test",
        issueId: "issue-1",
        members: [
          { agent: "coder", role: "primary", status: "completed", retryCount: 0 },
        ],
        status: "completed",
        discussionRounds: 0,
        currentRound: 0,
        results: {
          coder: {
            agent: "coder",
            result: "Implementation complete",
            completedAt: "2024-01-01T00:00:00Z",
          },
        },
        discussionHistory: [],
        startedAt: "2024-01-01T00:00:00Z",
        completedAt: "2024-01-01T01:00:00Z",
      }

      const notification = notifier.buildTeamNotification(team)

      expect(notification).toContain("<team-notification>")
      expect(notification).toContain("<team-id>team-123</team-id>")
      expect(notification).toContain("<issue>issue-1</issue>")
      expect(notification).toContain("<status>completed</status>")
      expect(notification).toContain('<member agent="coder" role="primary">')
      expect(notification).toContain("Implementation complete")
      expect(notification).toContain("</team-notification>")
    })

    test("includes worktree info when present", () => {
      const notifier = new TeamNotifier(mockLogger, undefined as any)

      const team: Team = {
        id: "team-123",
        projectId: "proj-1",
        projectDir: "/tmp/test",
        issueId: "issue-1",
        members: [
          { agent: "coder", role: "primary", status: "completed", retryCount: 0 },
        ],
        status: "completed",
        worktreePath: "/tmp/worktree/issue-1",
        worktreeBranch: "feature/issue-1",
        vcs: "jj",
        discussionRounds: 0,
        currentRound: 0,
        results: {},
        discussionHistory: [],
        startedAt: "2024-01-01T00:00:00Z",
        completedAt: "2024-01-01T01:00:00Z",
      }

      const notification = notifier.buildTeamNotification(team)

      expect(notification).toContain("<worktree>")
      expect(notification).toContain("<path>/tmp/worktree/issue-1</path>")
      expect(notification).toContain("<branch>feature/issue-1</branch>")
      expect(notification).toContain("<vcs>jj</vcs>")
      expect(notification).toContain("</worktree>")
    })

    test("includes discussion history when present", () => {
      const notifier = new TeamNotifier(mockLogger, undefined as any)

      const team: Team = {
        id: "team-123",
        projectId: "proj-1",
        projectDir: "/tmp/test",
        issueId: "issue-1",
        members: [
          { agent: "coder", role: "primary", status: "completed", retryCount: 0 },
          { agent: "reviewer", role: "secondary", status: "completed", retryCount: 0 },
        ],
        status: "completed",
        discussionRounds: 2,
        currentRound: 2,
        results: {},
        discussionHistory: [
          { round: 1, responses: { coder: "Round 1 coder", reviewer: "Round 1 reviewer" } },
          { round: 2, responses: { coder: "Round 2 coder", reviewer: "Round 2 reviewer" } },
        ],
        startedAt: "2024-01-01T00:00:00Z",
        completedAt: "2024-01-01T01:00:00Z",
      }

      const notification = notifier.buildTeamNotification(team)

      expect(notification).toContain('<discussion rounds="2">')
      expect(notification).toContain('<round n="1">')
      expect(notification).toContain('<round n="2">')
      expect(notification).toContain("Round 1 coder")
      expect(notification).toContain("Round 2 reviewer")
    })

    test("includes merge instructions for jj worktree", () => {
      const notifier = new TeamNotifier(mockLogger, undefined as any)

      const team: Team = {
        id: "team-123",
        projectId: "proj-1",
        projectDir: "/tmp/test",
        issueId: "issue-1",
        members: [],
        status: "completed",
        worktreePath: "/tmp/worktree",
        worktreeBranch: "feature-branch",
        vcs: "jj",
        discussionRounds: 0,
        currentRound: 0,
        results: {},
        discussionHistory: [],
        startedAt: "2024-01-01T00:00:00Z",
      }

      const notification = notifier.buildTeamNotification(team)

      expect(notification).toContain("<merge-instructions>")
      expect(notification).toContain("jj diff")
      expect(notification).toContain("jj squash")
      expect(notification).toContain("jj workspace forget")
    })

    test("includes merge instructions for git worktree", () => {
      const notifier = new TeamNotifier(mockLogger, undefined as any)

      const team: Team = {
        id: "team-123",
        projectId: "proj-1",
        projectDir: "/tmp/test",
        issueId: "issue-1",
        members: [],
        status: "completed",
        worktreePath: "/tmp/worktree",
        worktreeBranch: "feature-branch",
        vcs: "git",
        discussionRounds: 0,
        currentRound: 0,
        results: {},
        discussionHistory: [],
        startedAt: "2024-01-01T00:00:00Z",
      }

      const notification = notifier.buildTeamNotification(team)

      expect(notification).toContain("<merge-instructions>")
      expect(notification).toContain("git diff")
      expect(notification).toContain("git merge")
      expect(notification).toContain("git worktree remove")
    })
  })

  describe("XML escaping", () => {
    test("escapes special characters in team data", () => {
      const notifier = new TeamNotifier(mockLogger, undefined as any)

      const team: Team = {
        id: "team-<script>alert('xss')</script>",
        projectId: "proj-1",
        projectDir: "/tmp/test",
        issueId: "issue-with-&-ampersand",
        members: [
          { agent: "agent-with-\"quotes\"", role: "primary", status: "completed", retryCount: 0 },
        ],
        status: "completed",
        discussionRounds: 0,
        currentRound: 0,
        results: {
          "agent-with-\"quotes\"": {
            agent: "agent-with-\"quotes\"",
            result: "Result with <html> tags & special chars",
            completedAt: "2024-01-01T00:00:00Z",
          },
        },
        discussionHistory: [],
        startedAt: "2024-01-01T00:00:00Z",
      }

      const notification = notifier.buildTeamNotification(team)

      // Verify special characters are escaped
      expect(notification).toContain("&lt;script&gt;")
      expect(notification).toContain("&amp;-ampersand")
      expect(notification).toContain("&quot;quotes&quot;")
      expect(notification).toContain("&lt;html&gt;")
      // Verify raw special characters are NOT present
      expect(notification).not.toContain("<script>")
      expect(notification).not.toContain("&-ampersand")
    })

    test("escapes discussion responses", () => {
      const notifier = new TeamNotifier(mockLogger, undefined as any)

      const team: Team = {
        id: "team-123",
        projectId: "proj-1",
        projectDir: "/tmp/test",
        issueId: "issue-1",
        members: [
          { agent: "coder", role: "primary", status: "completed", retryCount: 0 },
        ],
        status: "completed",
        discussionRounds: 1,
        currentRound: 1,
        results: {},
        discussionHistory: [
          { round: 1, responses: { coder: "Response with <code> and & symbols" } },
        ],
        startedAt: "2024-01-01T00:00:00Z",
      }

      const notification = notifier.buildTeamNotification(team)

      expect(notification).toContain("&lt;code&gt;")
      expect(notification).toContain("&amp; symbols")
    })
  })

  describe("getMergeInstructions", () => {
    test("generates jj instructions", () => {
      const notifier = new TeamNotifier(mockLogger, undefined as any)

      const team: Team = {
        id: "team-123",
        projectId: "proj-1",
        projectDir: "/tmp/test",
        issueId: "issue-1",
        members: [],
        status: "completed",
        worktreePath: "/tmp/worktree",
        worktreeBranch: "my-branch",
        vcs: "jj",
        discussionRounds: 0,
        currentRound: 0,
        results: {},
        discussionHistory: [],
        startedAt: "2024-01-01T00:00:00Z",
      }

      const instructions = notifier.getMergeInstructions(team)

      expect(instructions).toContain("jj diff --from main --to my-branch")
      expect(instructions).toContain("jj squash --from my-branch")
      expect(instructions).toContain("jj workspace forget my-branch")
    })

    test("generates git instructions", () => {
      const notifier = new TeamNotifier(mockLogger, undefined as any)

      const team: Team = {
        id: "team-123",
        projectId: "proj-1",
        projectDir: "/tmp/test",
        issueId: "issue-1",
        members: [],
        status: "completed",
        worktreePath: "/tmp/worktree",
        worktreeBranch: "my-branch",
        vcs: "git",
        discussionRounds: 0,
        currentRound: 0,
        results: {},
        discussionHistory: [],
        startedAt: "2024-01-01T00:00:00Z",
      }

      const instructions = notifier.getMergeInstructions(team)

      expect(instructions).toContain("git diff main..my-branch")
      expect(instructions).toContain("git merge my-branch")
      expect(instructions).toContain("git worktree remove /tmp/worktree")
      expect(instructions).toContain("git branch -d my-branch")
    })

    test("uses issueId as branch when worktreeBranch not set", () => {
      const notifier = new TeamNotifier(mockLogger, undefined as any)

      const team: Team = {
        id: "team-123",
        projectId: "proj-1",
        projectDir: "/tmp/test",
        issueId: "issue-123",
        members: [],
        status: "completed",
        worktreePath: "/tmp/worktree",
        vcs: "jj",
        discussionRounds: 0,
        currentRound: 0,
        results: {},
        discussionHistory: [],
        startedAt: "2024-01-01T00:00:00Z",
      }

      const instructions = notifier.getMergeInstructions(team)

      expect(instructions).toContain("issue-123")
    })
  })
})
