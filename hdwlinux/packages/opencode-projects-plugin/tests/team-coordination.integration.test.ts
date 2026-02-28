/**
 * Integration tests for team coordination
 *
 * Tests multi-agent team execution, discussion rounds, and coordination.
 *
 * CRITICAL: All tests use local storage in temporary directories to prevent
 * interference with actual projects.
 */

import { describe, test, expect, beforeEach, afterEach, afterAll } from "bun:test"
import * as fs from "node:fs/promises"
import * as path from "node:path"

import {
  createIntegrationFixture,
  cleanupTestDirectories,
  DEFAULT_TEAM_CONFIG,
  type IntegrationTestFixture,
} from "./integration-test-utils.js"
import type { Team, TeamMember } from "../src/execution/team-manager.js"
import { TeamNotifier } from "../src/execution/team-notifier.js"

describe("Team Coordination Integration", () => {
  let fixture: IntegrationTestFixture

  beforeEach(async () => {
    fixture = await createIntegrationFixture()
  })

  afterEach(async () => {
    await fixture.cleanup()
  })

  afterAll(async () => {
    await cleanupTestDirectories("opencode-integration-test-")
  })

  describe("Team creation and persistence", () => {
    test("creates team with single agent", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Single Agent Team",
        storage: "local",
      })

      const issueResult = await fixture.issueStorage.createIssue(
        project.projectDir,
        "Single agent task"
      )
      const issueId = issueResult.ok ? issueResult.value : ""

      // Create team manually (simulating what work-on-issue does)
      const teamsDir = path.join(project.projectDir, ".teams")
      await fs.mkdir(teamsDir, { recursive: true })

      const team: Team = {
        id: "team-single-1",
        projectId: project.projectId,
        projectDir: project.projectDir,
        issueId,
        members: [
          { agent: "coder", role: "primary", status: "pending", retryCount: 0 },
        ],
        status: "running",
        discussionRounds: 0,
        currentRound: 0,
        results: {},
        discussionHistory: [],
        startedAt: new Date().toISOString(),
      }

      await fs.writeFile(
        path.join(teamsDir, `${team.id}.json`),
        JSON.stringify(team, null, 2)
      )

      // Add to manager cache
      ;(fixture.teamManager as any).teams.set(team.id, team)

      // Verify retrieval
      const result = await fixture.teamManager.get(team.id)
      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(result.value.members.length).toBe(1)
        expect(result.value.members[0].agent).toBe("coder")
        expect(result.value.members[0].role).toBe("primary")
      }
    })

    test("creates team with multiple agents", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Multi Agent Team",
        storage: "local",
      })

      const issueResult = await fixture.issueStorage.createIssue(
        project.projectDir,
        "Multi agent task"
      )
      const issueId = issueResult.ok ? issueResult.value : ""

      const teamsDir = path.join(project.projectDir, ".teams")
      await fs.mkdir(teamsDir, { recursive: true })

      const team: Team = {
        id: "team-multi-1",
        projectId: project.projectId,
        projectDir: project.projectDir,
        issueId,
        members: [
          { agent: "coder", role: "primary", status: "pending", retryCount: 0 },
          { agent: "reviewer", role: "secondary", status: "pending", retryCount: 0 },
          { agent: "security-expert", role: "devilsAdvocate", status: "pending", retryCount: 0 },
        ],
        status: "running",
        discussionRounds: 2,
        currentRound: 0,
        results: {},
        discussionHistory: [],
        startedAt: new Date().toISOString(),
      }

      await fs.writeFile(
        path.join(teamsDir, `${team.id}.json`),
        JSON.stringify(team, null, 2)
      )
      ;(fixture.teamManager as any).teams.set(team.id, team)

      const result = await fixture.teamManager.get(team.id)
      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(result.value.members.length).toBe(3)
        expect(result.value.members.map((m) => m.role)).toEqual([
          "primary",
          "secondary",
          "devilsAdvocate",
        ])
      }
    })

    test("lists teams by issue", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Team List Test",
        storage: "local",
      })

      const issue1Result = await fixture.issueStorage.createIssue(project.projectDir, "Issue 1")
      const issue2Result = await fixture.issueStorage.createIssue(project.projectDir, "Issue 2")

      const issue1Id = issue1Result.ok ? issue1Result.value : ""
      const issue2Id = issue2Result.ok ? issue2Result.value : ""

      const teamsDir = path.join(project.projectDir, ".teams")
      await fs.mkdir(teamsDir, { recursive: true })

      // Create teams for different issues
      const team1: Team = {
        id: "team-list-1",
        projectId: project.projectId,
        projectDir: project.projectDir,
        issueId: issue1Id,
        members: [{ agent: "coder", role: "primary", status: "completed", retryCount: 0 }],
        status: "completed",
        discussionRounds: 0,
        currentRound: 0,
        results: {},
        discussionHistory: [],
        startedAt: new Date().toISOString(),
      }

      const team2: Team = {
        id: "team-list-2",
        projectId: project.projectId,
        projectDir: project.projectDir,
        issueId: issue1Id,
        members: [{ agent: "reviewer", role: "primary", status: "running", retryCount: 0 }],
        status: "running",
        discussionRounds: 0,
        currentRound: 0,
        results: {},
        discussionHistory: [],
        startedAt: new Date().toISOString(),
      }

      const team3: Team = {
        id: "team-list-3",
        projectId: project.projectId,
        projectDir: project.projectDir,
        issueId: issue2Id,
        members: [{ agent: "coder", role: "primary", status: "running", retryCount: 0 }],
        status: "running",
        discussionRounds: 0,
        currentRound: 0,
        results: {},
        discussionHistory: [],
        startedAt: new Date().toISOString(),
      }

      for (const team of [team1, team2, team3]) {
        await fs.writeFile(
          path.join(teamsDir, `${team.id}.json`),
          JSON.stringify(team, null, 2)
        )
        ;(fixture.teamManager as any).teams.set(team.id, team)
      }

      const issue1Teams = await fixture.teamManager.listByIssue(issue1Id)
      const issue2Teams = await fixture.teamManager.listByIssue(issue2Id)

      expect(issue1Teams.length).toBe(2)
      expect(issue2Teams.length).toBe(1)
    })

    test("gets running teams only", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Running Teams Test",
        storage: "local",
      })

      const teamsDir = path.join(project.projectDir, ".teams")
      await fs.mkdir(teamsDir, { recursive: true })

      const runningTeam: Team = {
        id: "team-running",
        projectId: project.projectId,
        projectDir: project.projectDir,
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
        projectId: project.projectId,
        projectDir: project.projectDir,
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

      const failedTeam: Team = {
        id: "team-failed",
        projectId: project.projectId,
        projectDir: project.projectDir,
        issueId: "issue-3",
        members: [{ agent: "coder", role: "primary", status: "failed", retryCount: 1 }],
        status: "failed",
        discussionRounds: 0,
        currentRound: 0,
        results: {},
        discussionHistory: [],
        startedAt: new Date().toISOString(),
        completedAt: new Date().toISOString(),
      }

      for (const team of [runningTeam, completedTeam, failedTeam]) {
        await fs.writeFile(
          path.join(teamsDir, `${team.id}.json`),
          JSON.stringify(team, null, 2)
        )
        ;(fixture.teamManager as any).teams.set(team.id, team)
      }

      const running = await fixture.teamManager.getRunningTeams()
      expect(running.length).toBe(1)
      expect(running[0].id).toBe("team-running")
    })
  })

  describe("Team notification format", () => {
    test("builds notification with all member results", async () => {
      const notifier = new TeamNotifier(fixture.logger, fixture.client)

      const team: Team = {
        id: "team-notify-1",
        projectId: "test-project",
        projectDir: fixture.testDir,
        issueId: "issue-1",
        members: [
          { agent: "coder", role: "primary", status: "completed", retryCount: 0 },
          { agent: "reviewer", role: "secondary", status: "completed", retryCount: 0 },
        ],
        status: "completed",
        discussionRounds: 0,
        currentRound: 0,
        results: {
          coder: {
            agent: "coder",
            result: "Implemented the feature with proper error handling",
            completedAt: new Date().toISOString(),
          },
          reviewer: {
            agent: "reviewer",
            result: "Code looks good, approved with minor suggestions",
            completedAt: new Date().toISOString(),
          },
        },
        discussionHistory: [],
        startedAt: new Date().toISOString(),
        completedAt: new Date().toISOString(),
      }

      const notification = notifier.buildTeamNotification(team)

      expect(notification).toContain("<team-notification>")
      expect(notification).toContain("<team-id>team-notify-1</team-id>")
      expect(notification).toContain("<issue>issue-1</issue>")
      expect(notification).toContain('<member agent="coder" role="primary">')
      expect(notification).toContain('<member agent="reviewer" role="secondary">')
      expect(notification).toContain("Implemented the feature")
      expect(notification).toContain("Code looks good")
      expect(notification).toContain("</team-notification>")
    })

    test("includes discussion history in notification", async () => {
      const notifier = new TeamNotifier(fixture.logger, fixture.client)

      const team: Team = {
        id: "team-discuss-1",
        projectId: "test-project",
        projectDir: fixture.testDir,
        issueId: "issue-1",
        members: [
          { agent: "coder", role: "primary", status: "completed", retryCount: 0 },
          { agent: "reviewer", role: "secondary", status: "completed", retryCount: 0 },
        ],
        status: "completed",
        discussionRounds: 2,
        currentRound: 2,
        results: {
          coder: { agent: "coder", result: "Final implementation", completedAt: new Date().toISOString() },
          reviewer: { agent: "reviewer", result: "Final review", completedAt: new Date().toISOString() },
        },
        discussionHistory: [
          {
            round: 1,
            responses: {
              coder: "Initial implementation approach",
              reviewer: "Concerns about performance",
            },
          },
          {
            round: 2,
            responses: {
              coder: "Addressed performance concerns",
              reviewer: "Looks good now",
            },
          },
        ],
        startedAt: new Date().toISOString(),
        completedAt: new Date().toISOString(),
      }

      const notification = notifier.buildTeamNotification(team)

      expect(notification).toContain('<discussion rounds="2">')
      expect(notification).toContain('<round n="1">')
      expect(notification).toContain('<round n="2">')
      expect(notification).toContain("Initial implementation approach")
      expect(notification).toContain("Concerns about performance")
      expect(notification).toContain("Addressed performance concerns")
      expect(notification).toContain("Looks good now")
    })

    test("includes devil's advocate feedback", async () => {
      const notifier = new TeamNotifier(fixture.logger, fixture.client)

      const team: Team = {
        id: "team-devil-1",
        projectId: "test-project",
        projectDir: fixture.testDir,
        issueId: "issue-1",
        members: [
          { agent: "coder", role: "primary", status: "completed", retryCount: 0 },
          { agent: "security-expert", role: "devilsAdvocate", status: "completed", retryCount: 0 },
        ],
        status: "completed",
        discussionRounds: 0,
        currentRound: 0,
        results: {
          coder: {
            agent: "coder",
            result: "Implemented authentication flow",
            completedAt: new Date().toISOString(),
          },
          "security-expert": {
            agent: "security-expert",
            result: "CRITICAL: Found SQL injection vulnerability in login handler",
            completedAt: new Date().toISOString(),
          },
        },
        discussionHistory: [],
        startedAt: new Date().toISOString(),
        completedAt: new Date().toISOString(),
      }

      const notification = notifier.buildTeamNotification(team)

      expect(notification).toContain('<member agent="security-expert" role="devilsAdvocate">')
      expect(notification).toContain("SQL injection vulnerability")
    })
  })

  describe("Team member status tracking", () => {
    test("tracks individual member completion", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Member Status Test",
        storage: "local",
      })

      const teamsDir = path.join(project.projectDir, ".teams")
      await fs.mkdir(teamsDir, { recursive: true })

      // Simulate team progression
      const team: Team = {
        id: "team-status-1",
        projectId: project.projectId,
        projectDir: project.projectDir,
        issueId: "issue-1",
        members: [
          { agent: "coder", role: "primary", status: "completed", retryCount: 0 },
          { agent: "reviewer", role: "secondary", status: "running", retryCount: 0 },
          { agent: "tester", role: "secondary", status: "pending", retryCount: 0 },
        ],
        status: "running",
        discussionRounds: 0,
        currentRound: 0,
        results: {
          coder: {
            agent: "coder",
            result: "Implementation complete",
            completedAt: new Date().toISOString(),
          },
        },
        discussionHistory: [],
        startedAt: new Date().toISOString(),
      }

      await fs.writeFile(
        path.join(teamsDir, `${team.id}.json`),
        JSON.stringify(team, null, 2)
      )
      ;(fixture.teamManager as any).teams.set(team.id, team)

      const result = await fixture.teamManager.get(team.id)
      expect(result.ok).toBe(true)

      if (result.ok) {
        const members = result.value.members
        expect(members.find((m) => m.agent === "coder")?.status).toBe("completed")
        expect(members.find((m) => m.agent === "reviewer")?.status).toBe("running")
        expect(members.find((m) => m.agent === "tester")?.status).toBe("pending")
      }
    })

    test("tracks retry count on failures", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Retry Test",
        storage: "local",
      })

      const teamsDir = path.join(project.projectDir, ".teams")
      await fs.mkdir(teamsDir, { recursive: true })

      const team: Team = {
        id: "team-retry-1",
        projectId: project.projectId,
        projectDir: project.projectDir,
        issueId: "issue-1",
        members: [
          { agent: "flaky-agent", role: "primary", status: "running", retryCount: 2 },
        ],
        status: "running",
        discussionRounds: 0,
        currentRound: 0,
        results: {},
        discussionHistory: [],
        startedAt: new Date().toISOString(),
      }

      await fs.writeFile(
        path.join(teamsDir, `${team.id}.json`),
        JSON.stringify(team, null, 2)
      )
      ;(fixture.teamManager as any).teams.set(team.id, team)

      const result = await fixture.teamManager.get(team.id)
      expect(result.ok).toBe(true)

      if (result.ok) {
        expect(result.value.members[0].retryCount).toBe(2)
      }
    })
  })

  describe("Foreground mode", () => {
    test("foreground team waits for completion", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Foreground Test",
        storage: "local",
      })

      const teamsDir = path.join(project.projectDir, ".teams")
      await fs.mkdir(teamsDir, { recursive: true })

      // Create already-completed foreground team
      const team: Team = {
        id: "team-fg-1",
        projectId: project.projectId,
        projectDir: project.projectDir,
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

      await fs.writeFile(
        path.join(teamsDir, `${team.id}.json`),
        JSON.stringify(team, null, 2)
      )
      ;(fixture.teamManager as any).teams.set(team.id, team)

      // waitForCompletion should return immediately for completed team
      const result = await fixture.teamManager.waitForCompletion(team)
      expect(result.ok).toBe(true)

      if (result.ok) {
        expect(result.value.status).toBe("completed")
      }
    })

    test("foreground failed team returns failure", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Foreground Fail Test",
        storage: "local",
      })

      const teamsDir = path.join(project.projectDir, ".teams")
      await fs.mkdir(teamsDir, { recursive: true })

      const team: Team = {
        id: "team-fg-fail-1",
        projectId: project.projectId,
        projectDir: project.projectDir,
        issueId: "issue-1",
        members: [{ agent: "coder", role: "primary", status: "failed", retryCount: 3 }],
        status: "failed",
        foreground: true,
        discussionRounds: 0,
        currentRound: 0,
        results: {},
        discussionHistory: [],
        startedAt: new Date().toISOString(),
        completedAt: new Date().toISOString(),
      }

      await fs.writeFile(
        path.join(teamsDir, `${team.id}.json`),
        JSON.stringify(team, null, 2)
      )
      ;(fixture.teamManager as any).teams.set(team.id, team)

      const result = await fixture.teamManager.waitForCompletion(team)
      expect(result.ok).toBe(true)

      if (result.ok) {
        expect(result.value.status).toBe("failed")
      }
    })
  })
})
