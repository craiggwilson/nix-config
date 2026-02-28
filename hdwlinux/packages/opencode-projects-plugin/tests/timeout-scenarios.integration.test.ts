/**
 * Integration tests for timeout scenarios
 *
 * Tests delegation timeout handling, team timeout, and recovery.
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
  FAST_TIMEOUT_CONFIG,
  waitFor,
  type IntegrationTestFixture,
} from "./integration-test-utils.js"
import type { Team } from "../src/execution/team-manager.js"
import type { CreateDelegationOptions } from "../src/execution/delegation-manager.js"

/**
 * Helper to create delegation options
 */
function createDelegationOptions(
  overrides: Partial<CreateDelegationOptions> & { issueId: string; prompt: string }
): CreateDelegationOptions {
  return {
    teamId: "team-test",
    role: "primary",
    ...overrides,
  }
}

describe("Timeout Scenarios Integration", () => {
  let fixture: IntegrationTestFixture

  beforeEach(async () => {
    // Use fast timeout config for these tests
    fixture = await createIntegrationFixture({
      teamConfig: FAST_TIMEOUT_CONFIG,
    })
  })

  afterEach(async () => {
    await fixture.cleanup()
  })

  afterAll(async () => {
    await cleanupTestDirectories("opencode-integration-test-")
  })

  describe("Delegation timeout handling", () => {
    test("delegation can be marked as timed out", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Timeout Test",
        storage: "local",
      })

      const createResult = await fixture.delegationManager.create(
        project.projectId,
        project.projectDir,
        createDelegationOptions({
          issueId: "issue-timeout",
          prompt: "Long running task",
        })
      )

      expect(createResult.ok).toBe(true)
      if (!createResult.ok) return

      const delegation = createResult.value

      // Simulate timeout by marking as timed out
      const timeoutResult = await fixture.delegationManager.timeout(delegation.id)
      expect(timeoutResult.ok).toBe(true)

      // Verify status
      const getResult = await fixture.delegationManager.get(delegation.id)
      expect(getResult.ok).toBe(true)
      if (getResult.ok) {
        expect(getResult.value.status).toBe("timeout")
      }
    })

    test("timed out delegation counts as complete for areAllComplete", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Timeout Complete Test",
        storage: "local",
      })

      const createResult = await fixture.delegationManager.create(
        project.projectId,
        project.projectDir,
        createDelegationOptions({
          issueId: "issue-timeout-complete",
          prompt: "Task that times out",
        })
      )

      expect(createResult.ok).toBe(true)
      if (!createResult.ok) return

      // Before timeout, not complete
      let allComplete = await fixture.delegationManager.areAllComplete("issue-timeout-complete")
      expect(allComplete).toBe(false)

      // Mark as timed out
      await fixture.delegationManager.timeout(createResult.value.id)

      // After timeout, should be complete (terminal state)
      allComplete = await fixture.delegationManager.areAllComplete("issue-timeout-complete")
      expect(allComplete).toBe(true)
    })

    test("timed out delegation not in active list", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Timeout Active Test",
        storage: "local",
      })

      const createResult = await fixture.delegationManager.create(
        project.projectId,
        project.projectDir,
        createDelegationOptions({
          issueId: "issue-timeout-active",
          prompt: "Task",
        })
      )

      expect(createResult.ok).toBe(true)
      if (!createResult.ok) return

      // Before timeout, should be active
      let active = await fixture.delegationManager.getActiveDelegations("issue-timeout-active")
      expect(active.length).toBe(1)

      // Mark as timed out
      await fixture.delegationManager.timeout(createResult.value.id)

      // After timeout, should not be active
      active = await fixture.delegationManager.getActiveDelegations("issue-timeout-active")
      expect(active.length).toBe(0)
    })
  })

  describe("Team timeout handling", () => {
    test("team with timed out member", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Team Timeout Test",
        storage: "local",
      })

      const teamsDir = path.join(project.projectDir, ".teams")
      await fs.mkdir(teamsDir, { recursive: true })

      // Create team with one timed out member
      const team: Team = {
        id: "team-timeout-1",
        projectId: project.projectId,
        projectDir: project.projectDir,
        issueId: "issue-1",
        members: [
          { agent: "coder", role: "primary", status: "timeout", retryCount: 0 },
          { agent: "reviewer", role: "secondary", status: "completed", retryCount: 0 },
        ],
        status: "completed", // Team can still complete if some members timeout
        discussionRounds: 0,
        currentRound: 0,
        results: {
          reviewer: {
            agent: "reviewer",
            result: "Review complete",
            completedAt: new Date().toISOString(),
          },
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
        const timedOutMember = result.value.members.find((m) => m.agent === "coder")
        expect(timedOutMember?.status).toBe("timeout")
      }
    })

    test("team fails when all members timeout", async () => {
      const project = await fixture.projectManager.createProject({
        name: "All Timeout Test",
        storage: "local",
      })

      const teamsDir = path.join(project.projectDir, ".teams")
      await fs.mkdir(teamsDir, { recursive: true })

      const team: Team = {
        id: "team-all-timeout",
        projectId: project.projectId,
        projectDir: project.projectDir,
        issueId: "issue-1",
        members: [
          { agent: "coder", role: "primary", status: "timeout", retryCount: 0 },
          { agent: "reviewer", role: "secondary", status: "timeout", retryCount: 0 },
        ],
        status: "failed",
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

      const result = await fixture.teamManager.get(team.id)
      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(result.value.status).toBe("failed")
        expect(result.value.members.every((m) => m.status === "timeout")).toBe(true)
      }
    })
  })

  describe("Retry after timeout", () => {
    test("delegation can be retried after timeout", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Retry Test",
        storage: "local",
      })

      // Create and timeout first delegation
      const firstResult = await fixture.delegationManager.create(
        project.projectId,
        project.projectDir,
        createDelegationOptions({
          issueId: "issue-retry",
          prompt: "First attempt",
        })
      )

      expect(firstResult.ok).toBe(true)
      if (!firstResult.ok) return

      await fixture.delegationManager.timeout(firstResult.value.id)

      // Create retry delegation for same issue
      const retryResult = await fixture.delegationManager.create(
        project.projectId,
        project.projectDir,
        createDelegationOptions({
          issueId: "issue-retry",
          prompt: "Retry attempt",
        })
      )

      expect(retryResult.ok).toBe(true)
      if (!retryResult.ok) return

      // Both delegations should exist
      const delegations = await fixture.delegationManager.list({ issueId: "issue-retry" })
      expect(delegations.length).toBe(2)

      // One timed out, one running (with mock client, delegations start running immediately)
      const timedOut = delegations.filter((d) => d.status === "timeout")
      const running = delegations.filter((d) => d.status === "running")
      expect(timedOut.length).toBe(1)
      expect(running.length).toBe(1)
    })

    test("team member retry count tracks attempts", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Retry Count Test",
        storage: "local",
      })

      const teamsDir = path.join(project.projectDir, ".teams")
      await fs.mkdir(teamsDir, { recursive: true })

      // Team with member that has been retried
      const team: Team = {
        id: "team-retry-count",
        projectId: project.projectId,
        projectDir: project.projectDir,
        issueId: "issue-1",
        members: [
          { agent: "flaky-agent", role: "primary", status: "running", retryCount: 3 },
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
        expect(result.value.members[0].retryCount).toBe(3)
      }
    })
  })

  describe("Timeout with worktree", () => {
    test("timed out delegation preserves worktree info", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Worktree Timeout Test",
        storage: "local",
      })

      const createResult = await fixture.delegationManager.create(
        project.projectId,
        project.projectDir,
        createDelegationOptions({
          issueId: "issue-wt-timeout",
          prompt: "Code changes",
          worktreePath: "/tmp/worktree/issue-wt-timeout",
          worktreeBranch: "feature/issue-wt-timeout",
          vcs: "git",
        })
      )

      expect(createResult.ok).toBe(true)
      if (!createResult.ok) return

      await fixture.delegationManager.timeout(createResult.value.id)

      const getResult = await fixture.delegationManager.get(createResult.value.id)
      expect(getResult.ok).toBe(true)
      if (getResult.ok) {
        expect(getResult.value.status).toBe("timeout")
        // Worktree info should be preserved for potential recovery
        expect(getResult.value.worktreePath).toBe("/tmp/worktree/issue-wt-timeout")
        expect(getResult.value.worktreeBranch).toBe("feature/issue-wt-timeout")
      }
    })
  })

  describe("Multiple delegation timeout scenarios", () => {
    test("mixed completion states", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Mixed States Test",
        storage: "local",
      })

      // Create multiple delegations
      const d1Result = await fixture.delegationManager.create(
        project.projectId,
        project.projectDir,
        createDelegationOptions({ issueId: "issue-mixed", prompt: "Task 1" })
      )
      const d2Result = await fixture.delegationManager.create(
        project.projectId,
        project.projectDir,
        createDelegationOptions({ issueId: "issue-mixed", prompt: "Task 2" })
      )
      const d3Result = await fixture.delegationManager.create(
        project.projectId,
        project.projectDir,
        createDelegationOptions({ issueId: "issue-mixed", prompt: "Task 3" })
      )

      expect(d1Result.ok && d2Result.ok && d3Result.ok).toBe(true)
      if (!d1Result.ok || !d2Result.ok || !d3Result.ok) return

      // Set different states
      await fixture.delegationManager.complete(d1Result.value.id, "Done")
      await fixture.delegationManager.timeout(d2Result.value.id)
      await fixture.delegationManager.fail(d3Result.value.id, "Error")

      // All should be in terminal states
      const allComplete = await fixture.delegationManager.areAllComplete("issue-mixed")
      expect(allComplete).toBe(true)

      // No active delegations
      const active = await fixture.delegationManager.getActiveDelegations("issue-mixed")
      expect(active.length).toBe(0)

      // Verify individual states
      const delegations = await fixture.delegationManager.list({ issueId: "issue-mixed" })
      const states = delegations.map((d) => d.status).sort()
      expect(states).toEqual(["completed", "failed", "timeout"])
    })

    test("partial timeout with some success", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Partial Timeout Test",
        storage: "local",
      })

      const d1Result = await fixture.delegationManager.create(
        project.projectId,
        project.projectDir,
        createDelegationOptions({ issueId: "issue-partial", prompt: "Fast task" })
      )
      const d2Result = await fixture.delegationManager.create(
        project.projectId,
        project.projectDir,
        createDelegationOptions({ issueId: "issue-partial", prompt: "Slow task" })
      )

      expect(d1Result.ok && d2Result.ok).toBe(true)
      if (!d1Result.ok || !d2Result.ok) return

      // One completes, one times out
      await fixture.delegationManager.complete(d1Result.value.id, "Fast task done")
      await fixture.delegationManager.timeout(d2Result.value.id)

      // Should still be considered complete (all in terminal state)
      const allComplete = await fixture.delegationManager.areAllComplete("issue-partial")
      expect(allComplete).toBe(true)

      // Get recent completed (includes timeout)
      const recent = await fixture.delegationManager.getRecentCompletedDelegations(10)
      const issueRecent = recent.filter((d) => d.issueId === "issue-partial")
      expect(issueRecent.length).toBe(2)
    })
  })
})
