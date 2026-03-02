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
import { TeamNotifier, type Team, type TeamMember } from "../src/execution/index.js"

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

  describe("Foreground non-isolated delegation", () => {
    test("creates team without worktree when isolate=false", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Non-Isolated Test",
        storage: "local",
      })

      const issueResult = await fixture.issueStorage.createIssue(
        project.projectDir,
        "Research task - no code changes"
      )
      const issueId = issueResult.ok ? issueResult.value : ""

      const teamsDir = path.join(project.projectDir, ".teams")
      await fs.mkdir(teamsDir, { recursive: true })

      // Simulate a non-isolated team (no worktreePath)
      const team: Team = {
        id: "team-non-isolated-1",
        projectId: project.projectId,
        projectDir: project.projectDir,
        issueId,
        members: [{ agent: "coder", role: "primary", status: "completed", retryCount: 0 }],
        status: "completed",
        foreground: true,
        // No worktreePath - this is the key difference for non-isolated mode
        discussionRounds: 0,
        currentRound: 0,
        results: {
          coder: { agent: "coder", result: "Research completed", completedAt: new Date().toISOString() },
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

      const result = await fixture.teamManager.get(team.id)
      expect(result.ok).toBe(true)

      if (result.ok) {
        // Verify no worktree was created
        expect(result.value.worktreePath).toBeUndefined()
        expect(result.value.worktreeBranch).toBeUndefined()
        expect(result.value.vcs).toBeUndefined()
        expect(result.value.foreground).toBe(true)
        expect(result.value.status).toBe("completed")
      }
    })

    test("foreground non-isolated team returns results inline", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Inline Results Test",
        storage: "local",
      })

      const teamsDir = path.join(project.projectDir, ".teams")
      await fs.mkdir(teamsDir, { recursive: true })

      const expectedResult = "Analysis complete: Found 3 issues to address"
      const team: Team = {
        id: "team-inline-results-1",
        projectId: project.projectId,
        projectDir: project.projectDir,
        issueId: "issue-analysis",
        members: [{ agent: "analyst", role: "primary", status: "completed", retryCount: 0 }],
        status: "completed",
        foreground: true,
        discussionRounds: 0,
        currentRound: 0,
        results: {
          analyst: { agent: "analyst", result: expectedResult, completedAt: new Date().toISOString() },
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

      const result = await fixture.teamManager.waitForCompletion(team)
      expect(result.ok).toBe(true)

      if (result.ok) {
        expect(result.value.results.analyst).toBeDefined()
        expect(result.value.results.analyst.result).toBe(expectedResult)
      }
    })

    test("non-isolated team with multiple agents has no worktree", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Multi-Agent Non-Isolated",
        storage: "local",
      })

      const teamsDir = path.join(project.projectDir, ".teams")
      await fs.mkdir(teamsDir, { recursive: true })

      // Multi-agent team without isolation
      const team: Team = {
        id: "team-multi-non-isolated-1",
        projectId: project.projectId,
        projectDir: project.projectDir,
        issueId: "issue-research",
        members: [
          { agent: "researcher", role: "primary", status: "completed", retryCount: 0 },
          { agent: "reviewer", role: "secondary", status: "completed", retryCount: 0 },
        ],
        status: "completed",
        foreground: true,
        // No worktree fields
        discussionRounds: 1,
        currentRound: 1,
        results: {
          researcher: { agent: "researcher", result: "Research findings", completedAt: new Date().toISOString() },
          reviewer: { agent: "reviewer", result: "Review approved", completedAt: new Date().toISOString() },
        },
        discussionHistory: [
          {
            round: 1,
            responses: {
              researcher: "I found these key insights...",
              reviewer: "The analysis looks thorough.",
            },
          },
        ],
        startedAt: new Date().toISOString(),
        completedAt: new Date().toISOString(),
      }

      await fs.writeFile(
        path.join(teamsDir, `${team.id}.json`),
        JSON.stringify(team, null, 2)
      )
      ;(fixture.teamManager as any).teams.set(team.id, team)

      const result = await fixture.teamManager.get(team.id)
      expect(result.ok).toBe(true)

      if (result.ok) {
        expect(result.value.worktreePath).toBeUndefined()
        expect(result.value.members.length).toBe(2)
        expect(result.value.discussionHistory.length).toBe(1)
      }
    })

    test("issue status transitions correctly for non-isolated work", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Status Transition Test",
        storage: "local",
      })

      const issueResult = await fixture.issueStorage.createIssue(
        project.projectDir,
        "Status test issue"
      )
      expect(issueResult.ok).toBe(true)
      const issueId = issueResult.ok ? issueResult.value : ""

      // Verify initial status
      const initialIssue = await fixture.issueStorage.getIssue(issueId, project.projectDir)
      expect(initialIssue.ok).toBe(true)
      if (initialIssue.ok) {
        expect(initialIssue.value.status).toBe("open")
      }

      // Claim the issue (simulates what work-on-issue does)
      const claimResult = await fixture.issueStorage.claimIssue(issueId, project.projectDir)
      expect(claimResult.ok).toBe(true)

      // Verify status changed to in_progress
      const claimedIssue = await fixture.issueStorage.getIssue(issueId, project.projectDir)
      expect(claimedIssue.ok).toBe(true)
      if (claimedIssue.ok) {
        expect(claimedIssue.value.status).toBe("in_progress")
      }

      // Set delegation metadata (simulates what work-on-issue does)
      const metadataResult = await fixture.issueStorage.setDelegationMetadata(
        issueId,
        project.projectDir,
        { delegationId: "team-123", delegationStatus: "completed" }
      )
      expect(metadataResult.ok).toBe(true)

      // Verify metadata was set (stored separately from issue)
      const metadataGet = await fixture.issueStorage.getDelegationMetadata(issueId, project.projectDir)
      expect(metadataGet.ok).toBe(true)
      if (metadataGet.ok && metadataGet.value) {
        expect(metadataGet.value.delegationId).toBe("team-123")
        expect(metadataGet.value.delegationStatus).toBe("completed")
      }
    })

    test("no worktree artifacts left behind for non-isolated work", async () => {
      const project = await fixture.projectManager.createProject({
        name: "No Artifacts Test",
        storage: "local",
      })

      // List worktrees before
      const worktreesBefore = await fixture.worktreeManager.listAllWorktrees()

      // Create a non-isolated team (no worktree creation)
      const teamsDir = path.join(project.projectDir, ".teams")
      await fs.mkdir(teamsDir, { recursive: true })

      const team: Team = {
        id: "team-no-artifacts-1",
        projectId: project.projectId,
        projectDir: project.projectDir,
        issueId: "issue-clean",
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

      // List worktrees after
      const worktreesAfter = await fixture.worktreeManager.listAllWorktrees()

      // Verify no new worktrees were created
      if (worktreesBefore.ok && worktreesAfter.ok) {
        expect(worktreesAfter.value.length).toBe(worktreesBefore.value.length)
      }
    })
  })

  describe("Multi-agent team composition", () => {
    test("creates 2-agent team with primary and secondary roles", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Two Agent Team",
        storage: "local",
      })

      const issueResult = await fixture.issueStorage.createIssue(
        project.projectDir,
        "Two agent task"
      )
      const issueId = issueResult.ok ? issueResult.value : ""

      const teamsDir = path.join(project.projectDir, ".teams")
      await fs.mkdir(teamsDir, { recursive: true })

      // Create a 2-agent team (primary + secondary)
      const team: Team = {
        id: "team-2-agent-1",
        projectId: project.projectId,
        projectDir: project.projectDir,
        issueId,
        members: [
          { agent: "typescript-expert", role: "primary", status: "completed", retryCount: 0 },
          { agent: "code-reviewer", role: "secondary", status: "completed", retryCount: 0 },
        ],
        status: "completed",
        discussionRounds: 2,
        currentRound: 2,
        results: {
          "typescript-expert": {
            agent: "typescript-expert",
            result: "Implemented the feature with proper typing",
            completedAt: new Date().toISOString(),
          },
          "code-reviewer": {
            agent: "code-reviewer",
            result: "Code review passed with minor suggestions",
            completedAt: new Date().toISOString(),
          },
        },
        discussionHistory: [
          {
            round: 1,
            responses: {
              "typescript-expert": "Initial implementation approach",
              "code-reviewer": "Looks good, consider edge cases",
            },
          },
          {
            round: 2,
            responses: {
              "typescript-expert": "Added edge case handling",
              "code-reviewer": "Approved",
            },
          },
        ],
        startedAt: new Date().toISOString(),
        completedAt: new Date().toISOString(),
      }

      await fs.writeFile(
        path.join(teamsDir, `${team.id}.json`),
        JSON.stringify(team, null, 2)
      )
      ;(fixture.teamManager as any).teams.set(team.id, team)

      const result = await fixture.teamManager.get(team.id)
      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(result.value.members.length).toBe(2)
        expect(result.value.members[0].role).toBe("primary")
        expect(result.value.members[1].role).toBe("secondary")
        expect(result.value.discussionRounds).toBe(2)
        expect(result.value.discussionHistory.length).toBe(2)
      }
    })

    test("creates 3-agent team with primary, secondary, and devil's advocate", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Three Agent Team",
        storage: "local",
      })

      const issueResult = await fixture.issueStorage.createIssue(
        project.projectDir,
        "Three agent task with security review"
      )
      const issueId = issueResult.ok ? issueResult.value : ""

      const teamsDir = path.join(project.projectDir, ".teams")
      await fs.mkdir(teamsDir, { recursive: true })

      // Create a 3-agent team (primary + secondary + devil's advocate)
      const team: Team = {
        id: "team-3-agent-1",
        projectId: project.projectId,
        projectDir: project.projectDir,
        issueId,
        members: [
          { agent: "typescript-expert", role: "primary", status: "completed", retryCount: 0 },
          { agent: "code-reviewer", role: "secondary", status: "completed", retryCount: 0 },
          { agent: "security-expert", role: "devilsAdvocate", status: "completed", retryCount: 0 },
        ],
        status: "completed",
        discussionRounds: 2,
        currentRound: 2,
        results: {
          "typescript-expert": {
            agent: "typescript-expert",
            result: "Implemented authentication flow",
            completedAt: new Date().toISOString(),
          },
          "code-reviewer": {
            agent: "code-reviewer",
            result: "Code structure looks good",
            completedAt: new Date().toISOString(),
          },
          "security-expert": {
            agent: "security-expert",
            result: "## Concerns\n- Input validation needed\n\n## Risks\n- Potential XSS vulnerability\n\n## Verdict\nRequest changes",
            completedAt: new Date().toISOString(),
          },
        },
        discussionHistory: [
          {
            round: 1,
            responses: {
              "typescript-expert": "Initial auth implementation",
              "code-reviewer": "Structure is clean",
              "security-expert": "Found potential security issues",
            },
          },
          {
            round: 2,
            responses: {
              "typescript-expert": "Addressed security concerns",
              "code-reviewer": "Changes look good",
              "security-expert": "Security issues resolved",
            },
          },
        ],
        startedAt: new Date().toISOString(),
        completedAt: new Date().toISOString(),
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
        // Verify devil's advocate is present
        const devilsAdvocate = result.value.members.find((m) => m.role === "devilsAdvocate")
        expect(devilsAdvocate).toBeDefined()
        expect(devilsAdvocate?.agent).toBe("security-expert")
      }
    })

    test("devil's advocate result contains critical analysis structure", async () => {
      const notifier = new TeamNotifier(fixture.logger, fixture.client)

      const team: Team = {
        id: "team-da-structure-1",
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
            result: "Implemented user login",
            completedAt: new Date().toISOString(),
          },
          "security-expert": {
            agent: "security-expert",
            result: `## Concerns
- Password hashing uses weak algorithm

## Risks
- Brute force attacks possible
- Session fixation vulnerability

## Gaps
- No rate limiting implemented
- Missing CSRF protection

## Alternative Approaches
- Use bcrypt instead of MD5
- Implement JWT with refresh tokens

## Verdict
Request changes - security issues must be addressed`,
            completedAt: new Date().toISOString(),
          },
        },
        discussionHistory: [],
        startedAt: new Date().toISOString(),
        completedAt: new Date().toISOString(),
      }

      const notification = notifier.buildTeamNotification(team)

      // Verify devil's advocate role is in notification
      expect(notification).toContain('role="devilsAdvocate"')
      // Verify critical analysis sections are present
      expect(notification).toContain("Concerns")
      expect(notification).toContain("Risks")
      expect(notification).toContain("Gaps")
      expect(notification).toContain("Alternative Approaches")
      expect(notification).toContain("Verdict")
    })
  })

  describe("Discussion rounds structure", () => {
    test("discussion rounds have proper round numbers", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Discussion Rounds Test",
        storage: "local",
      })

      const teamsDir = path.join(project.projectDir, ".teams")
      await fs.mkdir(teamsDir, { recursive: true })

      const team: Team = {
        id: "team-rounds-1",
        projectId: project.projectId,
        projectDir: project.projectDir,
        issueId: "issue-1",
        members: [
          { agent: "agent-a", role: "primary", status: "completed", retryCount: 0 },
          { agent: "agent-b", role: "secondary", status: "completed", retryCount: 0 },
        ],
        status: "completed",
        discussionRounds: 3,
        currentRound: 3,
        results: {
          "agent-a": { agent: "agent-a", result: "Work done", completedAt: new Date().toISOString() },
          "agent-b": { agent: "agent-b", result: "Review done", completedAt: new Date().toISOString() },
        },
        discussionHistory: [
          { round: 1, responses: { "agent-a": "Round 1 A", "agent-b": "Round 1 B" } },
          { round: 2, responses: { "agent-a": "Round 2 A", "agent-b": "Round 2 B" } },
          { round: 3, responses: { "agent-a": "Round 3 A", "agent-b": "Round 3 B" } },
        ],
        startedAt: new Date().toISOString(),
        completedAt: new Date().toISOString(),
      }

      await fs.writeFile(
        path.join(teamsDir, `${team.id}.json`),
        JSON.stringify(team, null, 2)
      )
      ;(fixture.teamManager as any).teams.set(team.id, team)

      const result = await fixture.teamManager.get(team.id)
      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(result.value.discussionHistory.length).toBe(3)
        // Verify round numbers are sequential
        expect(result.value.discussionHistory[0].round).toBe(1)
        expect(result.value.discussionHistory[1].round).toBe(2)
        expect(result.value.discussionHistory[2].round).toBe(3)
        // Verify each round has responses from all agents
        for (const round of result.value.discussionHistory) {
          expect(Object.keys(round.responses)).toContain("agent-a")
          expect(Object.keys(round.responses)).toContain("agent-b")
        }
      }
    })

    test("notification includes all discussion rounds", async () => {
      const notifier = new TeamNotifier(fixture.logger, fixture.client)

      const team: Team = {
        id: "team-notify-rounds-1",
        projectId: "test-project",
        projectDir: fixture.testDir,
        issueId: "issue-1",
        members: [
          { agent: "primary-agent", role: "primary", status: "completed", retryCount: 0 },
          { agent: "reviewer-agent", role: "secondary", status: "completed", retryCount: 0 },
          { agent: "devils-advocate", role: "devilsAdvocate", status: "completed", retryCount: 0 },
        ],
        status: "completed",
        discussionRounds: 2,
        currentRound: 2,
        results: {
          "primary-agent": { agent: "primary-agent", result: "Implementation", completedAt: new Date().toISOString() },
          "reviewer-agent": { agent: "reviewer-agent", result: "Review", completedAt: new Date().toISOString() },
          "devils-advocate": { agent: "devils-advocate", result: "Critical analysis", completedAt: new Date().toISOString() },
        },
        discussionHistory: [
          {
            round: 1,
            responses: {
              "primary-agent": "First round primary response",
              "reviewer-agent": "First round reviewer response",
              "devils-advocate": "First round DA response",
            },
          },
          {
            round: 2,
            responses: {
              "primary-agent": "Second round primary response",
              "reviewer-agent": "Second round reviewer response",
              "devils-advocate": "Second round DA response",
            },
          },
        ],
        startedAt: new Date().toISOString(),
        completedAt: new Date().toISOString(),
      }

      const notification = notifier.buildTeamNotification(team)

      // Verify discussion section exists
      expect(notification).toContain('<discussion rounds="2">')
      expect(notification).toContain('<round n="1">')
      expect(notification).toContain('<round n="2">')
      // Verify all agent responses are included
      expect(notification).toContain("First round primary response")
      expect(notification).toContain("First round reviewer response")
      expect(notification).toContain("First round DA response")
      expect(notification).toContain("Second round primary response")
      expect(notification).toContain("Second round reviewer response")
      expect(notification).toContain("Second round DA response")
    })

    test("single-agent team has no discussion rounds", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Single Agent No Discussion",
        storage: "local",
      })

      const teamsDir = path.join(project.projectDir, ".teams")
      await fs.mkdir(teamsDir, { recursive: true })

      const team: Team = {
        id: "team-single-no-discuss-1",
        projectId: project.projectId,
        projectDir: project.projectDir,
        issueId: "issue-1",
        members: [
          { agent: "solo-agent", role: "primary", status: "completed", retryCount: 0 },
        ],
        status: "completed",
        discussionRounds: 0, // Single agent = no discussion
        currentRound: 0,
        results: {
          "solo-agent": { agent: "solo-agent", result: "Work done", completedAt: new Date().toISOString() },
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

      const result = await fixture.teamManager.get(team.id)
      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(result.value.discussionRounds).toBe(0)
        expect(result.value.discussionHistory.length).toBe(0)
      }
    })
  })

  describe("Result synthesis", () => {
    test("final result includes all agent contributions", async () => {
      const notifier = new TeamNotifier(fixture.logger, fixture.client)

      const team: Team = {
        id: "team-synthesis-1",
        projectId: "test-project",
        projectDir: fixture.testDir,
        issueId: "issue-1",
        members: [
          { agent: "implementer", role: "primary", status: "completed", retryCount: 0 },
          { agent: "reviewer", role: "secondary", status: "completed", retryCount: 0 },
          { agent: "critic", role: "devilsAdvocate", status: "completed", retryCount: 0 },
        ],
        status: "completed",
        discussionRounds: 1,
        currentRound: 1,
        results: {
          implementer: {
            agent: "implementer",
            result: "Created new API endpoint with validation",
            completedAt: new Date().toISOString(),
          },
          reviewer: {
            agent: "reviewer",
            result: "Code follows best practices, tests are comprehensive",
            completedAt: new Date().toISOString(),
          },
          critic: {
            agent: "critic",
            result: "Rate limiting should be added, error messages could leak info",
            completedAt: new Date().toISOString(),
          },
        },
        discussionHistory: [
          {
            round: 1,
            responses: {
              implementer: "Added rate limiting as suggested",
              reviewer: "Rate limiting implementation looks good",
              critic: "Concerns addressed, approved",
            },
          },
        ],
        startedAt: new Date().toISOString(),
        completedAt: new Date().toISOString(),
      }

      const notification = notifier.buildTeamNotification(team)

      // Verify all member results are in notification
      expect(notification).toContain('<member agent="implementer" role="primary">')
      expect(notification).toContain('<member agent="reviewer" role="secondary">')
      expect(notification).toContain('<member agent="critic" role="devilsAdvocate">')
      
      // Verify all results are included
      expect(notification).toContain("Created new API endpoint with validation")
      expect(notification).toContain("Code follows best practices")
      expect(notification).toContain("Rate limiting should be added")
      
      // Verify discussion synthesis
      expect(notification).toContain("Added rate limiting as suggested")
      expect(notification).toContain("Concerns addressed, approved")
    })

    test("failed member results are included in synthesis", async () => {
      const notifier = new TeamNotifier(fixture.logger, fixture.client)

      const team: Team = {
        id: "team-partial-fail-1",
        projectId: "test-project",
        projectDir: fixture.testDir,
        issueId: "issue-1",
        members: [
          { agent: "primary-agent", role: "primary", status: "completed", retryCount: 0 },
          { agent: "failed-reviewer", role: "secondary", status: "failed", retryCount: 1 },
        ],
        status: "completed", // Team can still complete if primary succeeds
        discussionRounds: 0,
        currentRound: 0,
        results: {
          "primary-agent": {
            agent: "primary-agent",
            result: "Implementation complete",
            completedAt: new Date().toISOString(),
          },
          "failed-reviewer": {
            agent: "failed-reviewer",
            result: "(failed)",
            completedAt: new Date().toISOString(),
          },
        },
        discussionHistory: [],
        startedAt: new Date().toISOString(),
        completedAt: new Date().toISOString(),
      }

      const notification = notifier.buildTeamNotification(team)

      // Verify both members are in notification
      expect(notification).toContain('<member agent="primary-agent" role="primary">')
      expect(notification).toContain('<member agent="failed-reviewer" role="secondary">')
      // Verify failed status is shown
      expect(notification).toContain("<status>failed</status>")
      expect(notification).toContain("<status>completed</status>")
    })
  })
})
