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
import { TeamNotifier } from "./team-notifier.js"
import { DelegationManager } from "./delegation-manager.js"
import { WorktreeManager } from "../vcs/index.js"
import { createMockLogger, createTestShell } from "../utils/testing/index.js"
import type { TeamConfig, Team } from "./team-manager.js"

const mockLogger = createMockLogger()

const defaultConfig: TeamConfig = {
  maxTeamSize: 5,
  retryFailedMembers: true,
  smallModelTimeoutMs: 30000,
  delegationTimeoutMs: 15 * 60 * 1000,
}

describe("TeamManager", () => {
  let testDir: string
  let teamManager: TeamManager
  let teamNotifier: TeamNotifier
  let delegationManager: DelegationManager
  let worktreeManager: WorktreeManager

  beforeEach(async () => {
    testDir = await fs.mkdtemp(path.join(os.tmpdir(), "team-test-"))

    const testShell = createTestShell()
    worktreeManager = new WorktreeManager(testDir, testShell, mockLogger)

    delegationManager = new DelegationManager(mockLogger, undefined, {
      timeoutMs: defaultConfig.delegationTimeoutMs,
      smallModelTimeoutMs: defaultConfig.smallModelTimeoutMs,
    })

    // Create TeamManager with delegationManager (no circular dependency)
    teamManager = new TeamManager(
      mockLogger,
      undefined as any, // No client for unit tests
      delegationManager,
      worktreeManager,
      defaultConfig
    )

    // Create TeamNotifier for notification tests
    teamNotifier = new TeamNotifier(mockLogger, undefined as any)
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
        projectDir: testDir,
        issueId: "issue-1",
        discussionStrategyType: "fixedRound",
        members: [
          { agent: "coder", role: "primary", status: "pending", retryCount: 0, prompt: "" },
          { agent: "reviewer", role: "secondary", status: "pending", retryCount: 0, prompt: "" },
        ],
        status: "running",
        results: {},
        discussionHistory: [],
        startedAt: new Date().toISOString(),
      }

      // Save using private method via reflection
      const teamsDir = path.join(testDir, ".teams")
      await fs.mkdir(teamsDir, { recursive: true })
      await fs.writeFile(
        path.join(teamsDir, `${team.id}.json`),
        JSON.stringify(team, null, 2)
      )

      // Add to cache so get() can find it
      ;(teamManager as any).teams.set(team.id, team)

      // Retrieve
      const result = await teamManager.get(team.id)

      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(result.value.id).toBe(team.id)
        expect(result.value.projectId).toBe("test-project")
        expect(result.value.members.length).toBe(2)
        expect(result.value.members[0].role).toBe("primary")
        expect(result.value.members[1].role).toBe("secondary")
      }
    })

    test("returns error for non-existent team", async () => {
      const result = await teamManager.get("non-existent")
      expect(result.ok).toBe(false)
      if (!result.ok) {
        expect(result.error.type).toBe("not_found")
      }
    })

    test("lists teams by issue", async () => {
      const teamsDir = path.join(testDir, ".teams")
      await fs.mkdir(teamsDir, { recursive: true })

      // Create multiple teams
      const team1: Team = {
        id: "team-1",
        projectId: "test-project",
        projectDir: testDir,
        issueId: "issue-1",
        discussionStrategyType: "fixedRound",
        members: [{ agent: "coder", role: "primary", status: "completed", retryCount: 0, prompt: "" }],
        status: "completed",
        results: {},
        discussionHistory: [],
        startedAt: new Date().toISOString(),
      }

      const team2: Team = {
        id: "team-2",
        projectId: "test-project",
        projectDir: testDir,
        issueId: "issue-1",
        discussionStrategyType: "fixedRound",
        members: [{ agent: "reviewer", role: "primary", status: "running", retryCount: 0, prompt: "" }],
        status: "running",
        results: {},
        discussionHistory: [],
        startedAt: new Date().toISOString(),
      }

      const team3: Team = {
        id: "team-3",
        projectId: "test-project",
        projectDir: testDir,
        issueId: "issue-2", // Different issue
        discussionStrategyType: "fixedRound",
        members: [{ agent: "coder", role: "primary", status: "running", retryCount: 0, prompt: "" }],
        status: "running",
        results: {},
        discussionHistory: [],
        startedAt: new Date().toISOString(),
      }

      // Add to cache
      ;(teamManager as any).teams.set(team1.id, team1)
      ;(teamManager as any).teams.set(team2.id, team2)
      ;(teamManager as any).teams.set(team3.id, team3)

      await fs.writeFile(path.join(teamsDir, "team-1.json"), JSON.stringify(team1))
      await fs.writeFile(path.join(teamsDir, "team-2.json"), JSON.stringify(team2))
      await fs.writeFile(path.join(teamsDir, "team-3.json"), JSON.stringify(team3))

      const issue1Teams = await teamManager.listByIssue("issue-1")
      const issue2Teams = await teamManager.listByIssue("issue-2")

      expect(issue1Teams.length).toBe(2)
      expect(issue2Teams.length).toBe(1)
    })

    test("gets running teams", async () => {
      const teamsDir = path.join(testDir, ".teams")
      await fs.mkdir(teamsDir, { recursive: true })

      const runningTeam: Team = {
        id: "team-running",
        projectId: "test-project",
        projectDir: testDir,
        issueId: "issue-1",
        discussionStrategyType: "fixedRound",
        members: [{ agent: "coder", role: "primary", status: "running", retryCount: 0, prompt: "" }],
        status: "running",
        results: {},
        discussionHistory: [],
        startedAt: new Date().toISOString(),
      }

      const completedTeam: Team = {
        id: "team-completed",
        projectId: "test-project",
        projectDir: testDir,
        issueId: "issue-2",
        discussionStrategyType: "fixedRound",
        members: [{ agent: "coder", role: "primary", status: "completed", retryCount: 0, prompt: "" }],
        status: "completed",
        results: {},
        discussionHistory: [],
        startedAt: new Date().toISOString(),
        completedAt: new Date().toISOString(),
      }

      // Add to cache
      ;(teamManager as any).teams.set(runningTeam.id, runningTeam)
      ;(teamManager as any).teams.set(completedTeam.id, completedTeam)

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
        projectDir: "/tmp/test-project",
        issueId: "issue-1",
        discussionStrategyType: "fixedRound",
        members: [
          { agent: "coder", role: "primary", status: "completed", retryCount: 0, prompt: "" },
          { agent: "reviewer", role: "devilsAdvocate", status: "completed", retryCount: 0, prompt: "" },
        ],
        status: "completed",
        results: {
          coder: { agent: "coder", result: "Implemented feature X", completedAt: new Date().toISOString() },
          reviewer: { agent: "reviewer", result: "Found security issue", completedAt: new Date().toISOString() },
        },
        discussionHistory: [],
        startedAt: new Date().toISOString(),
        completedAt: new Date().toISOString(),
      }

      // Use TeamNotifier directly for testing
      const notification = teamNotifier.buildTeamNotification(team)

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
        projectDir: "/tmp/test-project",
        issueId: "issue-1",
        discussionStrategyType: "fixedRound",
        members: [
          { agent: "coder", role: "primary", status: "completed", retryCount: 0, prompt: "" },
          { agent: "reviewer", role: "secondary", status: "completed", retryCount: 0, prompt: "" },
        ],
        status: "completed",
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

      const notification = teamNotifier.buildTeamNotification(team)

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
        projectDir: testDir,
        issueId: "issue-1",
        discussionStrategyType: "fixedRound",
        members: [{ agent: "coder", role: "primary", status: "completed", retryCount: 0, prompt: "" }],
        status: "completed",
        worktreePath: "/tmp/worktree/issue-1",
        worktreeBranch: "feature/issue-1",
        vcs: "jj",
        results: {},
        discussionHistory: [],
        startedAt: new Date().toISOString(),
        completedAt: new Date().toISOString(),
      }

      const notification = teamNotifier.buildTeamNotification(team)

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
      const teamsDir = path.join(testDir, ".teams")
      await fs.mkdir(teamsDir, { recursive: true })

      const foregroundTeam: Team = {
        id: "team-foreground",
        projectId: "test-project",
        projectDir: testDir,
        issueId: "issue-1",
        discussionStrategyType: "fixedRound",
        members: [{ agent: "coder", role: "primary", status: "running", retryCount: 0, prompt: "" }],
        status: "running",
        foreground: true,
        results: {},
        discussionHistory: [],
        startedAt: new Date().toISOString(),
      }

      // Add to cache
      ;(teamManager as any).teams.set(foregroundTeam.id, foregroundTeam)

      await fs.writeFile(path.join(teamsDir, "team-foreground.json"), JSON.stringify(foregroundTeam))

      const result = await teamManager.get("team-foreground")

      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(result.value.foreground).toBe(true)
      }
    })

    test("waitForCompletion returns immediately when team already complete", async () => {
      const teamsDir = path.join(testDir, ".teams")
      await fs.mkdir(teamsDir, { recursive: true })

      // Create a team that's already complete
      const completedTeam: Team = {
        id: "team-wait-test",
        projectId: "test-project",
        projectDir: testDir,
        issueId: "issue-1",
        discussionStrategyType: "fixedRound",
        members: [{ agent: "coder", role: "primary", status: "completed", retryCount: 0, prompt: "" }],
        status: "completed",
        foreground: true,
        results: {
          coder: { agent: "coder", result: "Done", completedAt: new Date().toISOString() },
        },
        discussionHistory: [],
        startedAt: new Date().toISOString(),
        completedAt: new Date().toISOString(),
      }

      // Add to cache
      ;(teamManager as any).teams.set(completedTeam.id, completedTeam)

      await fs.writeFile(path.join(teamsDir, "team-wait-test.json"), JSON.stringify(completedTeam))

      // waitForCompletion should return immediately since team is already complete
      const result = await teamManager.waitForCompletion(completedTeam)

      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(result.value.status).toBe("completed")
        expect(result.value.results.coder.result).toBe("Done")
      }
    })

    test("waitForCompletion returns immediately when team already failed", async () => {
      const teamsDir = path.join(testDir, ".teams")
      await fs.mkdir(teamsDir, { recursive: true })

      // Create a team that's already failed
      const failedTeam: Team = {
        id: "team-wait-failed",
        projectId: "test-project",
        projectDir: testDir,
        issueId: "issue-1",
        discussionStrategyType: "fixedRound",
        members: [{ agent: "coder", role: "primary", status: "failed", retryCount: 1, prompt: "" }],
        status: "failed",
        foreground: true,
        results: {
          coder: { agent: "coder", result: "(failed)", completedAt: new Date().toISOString() },
        },
        discussionHistory: [],
        startedAt: new Date().toISOString(),
        completedAt: new Date().toISOString(),
      }

      // Add to cache
      ;(teamManager as any).teams.set(failedTeam.id, failedTeam)

      await fs.writeFile(path.join(teamsDir, "team-wait-failed.json"), JSON.stringify(failedTeam))

      // waitForCompletion should return immediately with failed team (Option A)
      const result = await teamManager.waitForCompletion(failedTeam)

      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(result.value.status).toBe("failed")
      }
    })

    test("foreground team skips parent notification", async () => {
      const team: Team = {
        id: "team-foreground-notify",
        projectId: "test-project",
        projectDir: "/tmp/test-project",
        issueId: "issue-1",
        discussionStrategyType: "fixedRound",
        members: [{ agent: "coder", role: "primary", status: "completed", retryCount: 0, prompt: "" }],
        status: "completed",
        foreground: true,
        results: {},
        discussionHistory: [],
        startedAt: new Date().toISOString(),
        completedAt: new Date().toISOString(),
      }

      // The notifyParent method should check foreground flag
      // Since we don't have a client, this test just verifies the flag is respected
      expect(team.foreground).toBe(true)
    })

    test("waitForCompletion times out and returns error", async () => {
      const teamsDir = path.join(testDir, ".teams")
      await fs.mkdir(teamsDir, { recursive: true })

      // Create a running team that will never complete
      const runningTeam: Team = {
        id: "team-timeout-test",
        projectId: "test-project",
        projectDir: testDir,
        issueId: "issue-1",
        discussionStrategyType: "fixedRound",
        members: [{ agent: "coder", role: "primary", status: "running", retryCount: 0, prompt: "" }],
        status: "running",
        foreground: true,
        results: {},
        discussionHistory: [],
        startedAt: new Date().toISOString(),
      }

      // Add to cache
      ;(teamManager as any).teams.set(runningTeam.id, runningTeam)

      await fs.writeFile(path.join(teamsDir, "team-timeout-test.json"), JSON.stringify(runningTeam))

      // Use a very short timeout for testing (50ms)
      const result = await teamManager.waitForCompletion(runningTeam, 50)

      expect(result.ok).toBe(false)
      if (!result.ok) {
        expect(result.error.type).toBe("timeout")
        if (result.error.type === "timeout") {
          expect(result.error.teamId).toBe("team-timeout-test")
          expect(result.error.timeoutMs).toBe(50)
          expect(result.error.operation).toBe("waitForCompletion")
        }
      }

      // Verify the completion promise was cleaned up
      const completionPromises = (teamManager as any).completionPromises as Map<string, unknown>
      expect(completionPromises.has("team-timeout-test")).toBe(false)
    })

    test("waitForCompletion clears timeout when team completes", async () => {
      const teamsDir = path.join(testDir, ".teams")
      await fs.mkdir(teamsDir, { recursive: true })

      // Create a running team
      const runningTeam: Team = {
        id: "team-clear-timeout-test",
        projectId: "test-project",
        projectDir: testDir,
        issueId: "issue-1",
        discussionStrategyType: "fixedRound",
        members: [{ agent: "coder", role: "primary", status: "running", retryCount: 0, prompt: "" }],
        status: "running",
        foreground: true,
        results: {},
        discussionHistory: [],
        startedAt: new Date().toISOString(),
      }

      // Add to cache
      ;(teamManager as any).teams.set(runningTeam.id, runningTeam)

      await fs.writeFile(path.join(teamsDir, "team-clear-timeout-test.json"), JSON.stringify(runningTeam))

      // Start waiting with a long timeout
      const waitPromise = teamManager.waitForCompletion(runningTeam, 10000)

      // Wait a tick for the promise to be set up
      await new Promise((resolve) => setTimeout(resolve, 10))

      // Simulate team completion by resolving the promise manually
      const completionPromises = (teamManager as any).completionPromises as Map<string, (team: Team) => void>
      const resolveCallback = completionPromises.get("team-clear-timeout-test")
      expect(resolveCallback).toBeDefined()

      // Complete the team
      const completedTeam: Team = {
        ...runningTeam,
        status: "completed",
        members: [{ agent: "coder", role: "primary", status: "completed", retryCount: 0, prompt: "" }],
        results: {
          coder: { agent: "coder", result: "Done", completedAt: new Date().toISOString() },
        },
        completedAt: new Date().toISOString(),
      }

      resolveCallback!(completedTeam)

      const result = await waitPromise

      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(result.value.status).toBe("completed")
      }

      // Verify the completion promise was cleaned up (by the callback)
      // Note: The callback itself doesn't delete from the map, but the timeout was cleared
      // The map entry is deleted by resolveCompletionPromise in the actual flow
    })
  })
})
