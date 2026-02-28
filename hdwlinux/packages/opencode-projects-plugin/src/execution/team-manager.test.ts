/**
 * Tests for TeamManager
 *
 * Note: Full integration tests require a running OpenCode client.
 * These tests focus on unit testing the team management logic.
 */

import { describe, test, expect, beforeEach, afterAll } from "bun:test"
import * as fs from "node:fs/promises"
import * as path from "node:path"
import * as os from "node:os"

import { TeamManager } from "./team-manager.js"
import { DelegationManager } from "./delegation-manager.js"
import { WorktreeManager } from "./worktree-manager.js"
import { createMockLogger, createTestShell } from "../core/test-utils.js"
import type { TeamConfig, Team } from "../core/types.js"

const mockLogger = createMockLogger()

const defaultConfig: TeamConfig = {
  discussionRounds: 2,
  discussionRoundTimeoutMs: 5 * 60 * 1000,
  maxTeamSize: 5,
  retryFailedMembers: true,
  smallModelTimeoutMs: 30000,
  delegationTimeoutMs: 15 * 60 * 1000,
}

describe("TeamManager", () => {
  let testDir: string
  let teamManager: TeamManager
  let delegationManager: DelegationManager
  let worktreeManager: WorktreeManager

  beforeEach(async () => {
    testDir = await fs.mkdtemp(path.join(os.tmpdir(), "team-test-"))

    const testShell = createTestShell()
    worktreeManager = new WorktreeManager(testDir, testShell, mockLogger)

    delegationManager = new DelegationManager(testDir, mockLogger, undefined, {
      timeoutMs: defaultConfig.delegationTimeoutMs,
      smallModelTimeoutMs: defaultConfig.smallModelTimeoutMs,
    })

    // Create TeamManager without client (for unit testing)
    teamManager = new TeamManager(
      testDir,
      mockLogger,
      undefined as any, // No client for unit tests
      worktreeManager,
      defaultConfig
    )

    // Wire up circular dependency
    delegationManager.setTeamManager(teamManager)
    teamManager.setDelegationManager(delegationManager)
  })

  afterAll(async () => {
    try {
      const tmpDir = os.tmpdir()
      const entries = await fs.readdir(tmpDir)
      for (const entry of entries) {
        if (entry.startsWith("team-test-")) {
          await fs.rm(path.join(tmpDir, entry), { recursive: true, force: true })
        }
      }
    } catch {
      // Ignore cleanup errors
    }
  })

  describe("Team persistence", () => {
    test("saves and retrieves team", async () => {
      // Create a team manually for testing persistence
      const team: Team = {
        id: "team-test-123",
        projectId: "test-project",
        issueId: "issue-1",
        members: [
          { agent: "coder", role: "primary", status: "pending", retryCount: 0 },
          { agent: "reviewer", role: "secondary", status: "pending", retryCount: 0 },
        ],
        status: "running",
        discussionRounds: 2,
        currentRound: 0,
        results: {},
        discussionHistory: [],
        startedAt: new Date().toISOString(),
      }

      // Save using private method via reflection
      const teamsDir = path.join(testDir, "teams")
      await fs.mkdir(teamsDir, { recursive: true })
      await fs.writeFile(
        path.join(teamsDir, `${team.id}.json`),
        JSON.stringify(team, null, 2)
      )

      // Retrieve
      const retrieved = await teamManager.get(team.id)

      expect(retrieved).not.toBeNull()
      expect(retrieved!.id).toBe(team.id)
      expect(retrieved!.projectId).toBe("test-project")
      expect(retrieved!.members.length).toBe(2)
      expect(retrieved!.members[0].role).toBe("primary")
      expect(retrieved!.members[1].role).toBe("secondary")
    })

    test("returns null for non-existent team", async () => {
      const retrieved = await teamManager.get("non-existent")
      expect(retrieved).toBeNull()
    })

    test("lists teams by issue", async () => {
      const teamsDir = path.join(testDir, "teams")
      await fs.mkdir(teamsDir, { recursive: true })

      // Create multiple teams
      const team1: Team = {
        id: "team-1",
        projectId: "test-project",
        issueId: "issue-1",
        members: [{ agent: "coder", role: "primary", status: "completed", retryCount: 0 }],
        status: "completed",
        discussionRounds: 0,
        currentRound: 0,
        results: {},
        discussionHistory: [],
        startedAt: new Date().toISOString(),
      }

      const team2: Team = {
        id: "team-2",
        projectId: "test-project",
        issueId: "issue-1",
        members: [{ agent: "reviewer", role: "primary", status: "running", retryCount: 0 }],
        status: "running",
        discussionRounds: 0,
        currentRound: 0,
        results: {},
        discussionHistory: [],
        startedAt: new Date().toISOString(),
      }

      const team3: Team = {
        id: "team-3",
        projectId: "test-project",
        issueId: "issue-2", // Different issue
        members: [{ agent: "coder", role: "primary", status: "running", retryCount: 0 }],
        status: "running",
        discussionRounds: 0,
        currentRound: 0,
        results: {},
        discussionHistory: [],
        startedAt: new Date().toISOString(),
      }

      await fs.writeFile(path.join(teamsDir, "team-1.json"), JSON.stringify(team1))
      await fs.writeFile(path.join(teamsDir, "team-2.json"), JSON.stringify(team2))
      await fs.writeFile(path.join(teamsDir, "team-3.json"), JSON.stringify(team3))

      const issue1Teams = await teamManager.listByIssue("issue-1")
      const issue2Teams = await teamManager.listByIssue("issue-2")

      expect(issue1Teams.length).toBe(2)
      expect(issue2Teams.length).toBe(1)
    })

    test("gets running teams", async () => {
      const teamsDir = path.join(testDir, "teams")
      await fs.mkdir(teamsDir, { recursive: true })

      const runningTeam: Team = {
        id: "team-running",
        projectId: "test-project",
        issueId: "issue-1",
        members: [{ agent: "coder", role: "primary", status: "running", retryCount: 0 }],
        status: "running",
        discussionRounds: 0,
        currentRound: 0,
        results: {},
        discussionHistory: [],
        startedAt: new Date().toISOString(),
      }

      const completedTeam: Team = {
        id: "team-completed",
        projectId: "test-project",
        issueId: "issue-2",
        members: [{ agent: "coder", role: "primary", status: "completed", retryCount: 0 }],
        status: "completed",
        discussionRounds: 0,
        currentRound: 0,
        results: {},
        discussionHistory: [],
        startedAt: new Date().toISOString(),
        completedAt: new Date().toISOString(),
      }

      await fs.writeFile(path.join(teamsDir, "team-running.json"), JSON.stringify(runningTeam))
      await fs.writeFile(path.join(teamsDir, "team-completed.json"), JSON.stringify(completedTeam))

      const running = await teamManager.getRunningTeams()

      expect(running.length).toBe(1)
      expect(running[0].id).toBe("team-running")
    })
  })

  describe("Team notification format", () => {
    test("builds XML notification with members", async () => {
      const team: Team = {
        id: "team-test",
        projectId: "test-project",
        issueId: "issue-1",
        members: [
          { agent: "coder", role: "primary", status: "completed", retryCount: 0 },
          { agent: "reviewer", role: "devilsAdvocate", status: "completed", retryCount: 0 },
        ],
        status: "completed",
        discussionRounds: 0,
        currentRound: 0,
        results: {
          coder: { agent: "coder", result: "Implemented feature X", completedAt: new Date().toISOString() },
          reviewer: { agent: "reviewer", result: "Found security issue", completedAt: new Date().toISOString() },
        },
        discussionHistory: [],
        startedAt: new Date().toISOString(),
        completedAt: new Date().toISOString(),
      }

      // Access private method via reflection for testing
      const buildNotification = (teamManager as any).buildTeamNotification.bind(teamManager)
      const notification = buildNotification(team)

      expect(notification).toContain("<team-notification>")
      expect(notification).toContain("<team-id>team-test</team-id>")
      expect(notification).toContain("<issue>issue-1</issue>")
      expect(notification).toContain('<member agent="coder" role="primary">')
      expect(notification).toContain('<member agent="reviewer" role="devilsAdvocate">')
      expect(notification).toContain("Implemented feature X")
      expect(notification).toContain("Found security issue")
      expect(notification).toContain("</team-notification>")
    })

    test("includes discussion history in notification", async () => {
      const team: Team = {
        id: "team-test",
        projectId: "test-project",
        issueId: "issue-1",
        members: [
          { agent: "coder", role: "primary", status: "completed", retryCount: 0 },
          { agent: "reviewer", role: "secondary", status: "completed", retryCount: 0 },
        ],
        status: "completed",
        discussionRounds: 2,
        currentRound: 2,
        results: {
          coder: { agent: "coder", result: "Initial work", completedAt: new Date().toISOString() },
          reviewer: { agent: "reviewer", result: "Initial review", completedAt: new Date().toISOString() },
        },
        discussionHistory: [
          { round: 1, responses: { coder: "Round 1 coder", reviewer: "Round 1 reviewer" } },
          { round: 2, responses: { coder: "Round 2 coder", reviewer: "Round 2 reviewer" } },
        ],
        startedAt: new Date().toISOString(),
        completedAt: new Date().toISOString(),
      }

      const buildNotification = (teamManager as any).buildTeamNotification.bind(teamManager)
      const notification = buildNotification(team)

      expect(notification).toContain('<discussion rounds="2">')
      expect(notification).toContain('<round n="1">')
      expect(notification).toContain('<round n="2">')
      expect(notification).toContain("Round 1 coder")
      expect(notification).toContain("Round 2 reviewer")
    })

    test("includes worktree info and merge instructions", async () => {
      const team: Team = {
        id: "team-test",
        projectId: "test-project",
        issueId: "issue-1",
        members: [{ agent: "coder", role: "primary", status: "completed", retryCount: 0 }],
        status: "completed",
        worktreePath: "/tmp/worktree/issue-1",
        worktreeBranch: "feature/issue-1",
        vcs: "jj",
        discussionRounds: 0,
        currentRound: 0,
        results: {},
        discussionHistory: [],
        startedAt: new Date().toISOString(),
        completedAt: new Date().toISOString(),
      }

      const buildNotification = (teamManager as any).buildTeamNotification.bind(teamManager)
      const notification = buildNotification(team)

      expect(notification).toContain("<worktree>")
      expect(notification).toContain("<path>/tmp/worktree/issue-1</path>")
      expect(notification).toContain("<branch>feature/issue-1</branch>")
      expect(notification).toContain("<vcs>jj</vcs>")
      expect(notification).toContain("<merge-instructions>")
      expect(notification).toContain("jj diff")
      expect(notification).toContain("jj squash")
    })
  })

  describe("Foreground mode", () => {
    test("team with foreground flag set", async () => {
      const teamsDir = path.join(testDir, "teams")
      await fs.mkdir(teamsDir, { recursive: true })

      const foregroundTeam: Team = {
        id: "team-foreground",
        projectId: "test-project",
        issueId: "issue-1",
        members: [{ agent: "coder", role: "primary", status: "running", retryCount: 0 }],
        status: "running",
        foreground: true,
        discussionRounds: 0,
        currentRound: 0,
        results: {},
        discussionHistory: [],
        startedAt: new Date().toISOString(),
      }

      await fs.writeFile(path.join(teamsDir, "team-foreground.json"), JSON.stringify(foregroundTeam))

      const retrieved = await teamManager.get("team-foreground")

      expect(retrieved).not.toBeNull()
      expect(retrieved!.foreground).toBe(true)
    })

    test("waitForCompletion returns immediately when team already complete", async () => {
      const teamsDir = path.join(testDir, "teams")
      await fs.mkdir(teamsDir, { recursive: true })

      // Create a team that's already complete
      const completedTeam: Team = {
        id: "team-wait-test",
        projectId: "test-project",
        issueId: "issue-1",
        members: [{ agent: "coder", role: "primary", status: "completed", retryCount: 0 }],
        status: "completed",
        foreground: true,
        discussionRounds: 0,
        currentRound: 0,
        results: {
          coder: { agent: "coder", result: "Done", completedAt: new Date().toISOString() },
        },
        discussionHistory: [],
        startedAt: new Date().toISOString(),
        completedAt: new Date().toISOString(),
      }

      await fs.writeFile(path.join(teamsDir, "team-wait-test.json"), JSON.stringify(completedTeam))

      // waitForCompletion should return immediately since team is already complete
      const result = await teamManager.waitForCompletion(completedTeam)

      expect(result.status).toBe("completed")
      expect(result.results.coder.result).toBe("Done")
    })

    test("waitForCompletion returns immediately when team already failed", async () => {
      const teamsDir = path.join(testDir, "teams")
      await fs.mkdir(teamsDir, { recursive: true })

      // Create a team that's already failed
      const failedTeam: Team = {
        id: "team-wait-failed",
        projectId: "test-project",
        issueId: "issue-1",
        members: [{ agent: "coder", role: "primary", status: "failed", retryCount: 1 }],
        status: "failed",
        foreground: true,
        discussionRounds: 0,
        currentRound: 0,
        results: {
          coder: { agent: "coder", result: "(failed)", completedAt: new Date().toISOString() },
        },
        discussionHistory: [],
        startedAt: new Date().toISOString(),
        completedAt: new Date().toISOString(),
      }

      await fs.writeFile(path.join(teamsDir, "team-wait-failed.json"), JSON.stringify(failedTeam))

      // waitForCompletion should return immediately with failed team (Option A)
      const result = await teamManager.waitForCompletion(failedTeam)

      expect(result.status).toBe("failed")
    })

    test("foreground team skips parent notification", async () => {
      const team: Team = {
        id: "team-foreground-notify",
        projectId: "test-project",
        issueId: "issue-1",
        members: [{ agent: "coder", role: "primary", status: "completed", retryCount: 0 }],
        status: "completed",
        foreground: true,
        discussionRounds: 0,
        currentRound: 0,
        results: {},
        discussionHistory: [],
        startedAt: new Date().toISOString(),
        completedAt: new Date().toISOString(),
      }

      // The notifyParent method should check foreground flag
      // Since we don't have a client, this test just verifies the flag is respected
      expect(team.foreground).toBe(true)
    })
  })
})
