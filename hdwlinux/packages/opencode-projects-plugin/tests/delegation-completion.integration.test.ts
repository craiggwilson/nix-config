/**
 * Integration tests for delegation completion and parent notification
 *
 * Tests the delegation lifecycle: create → run → complete → notify parent
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
  waitFor,
  type IntegrationTestFixture,
} from "./integration-test-utils.js"
import type { CreateDelegationOptions } from "../src/execution/delegation-manager.js"

/**
 * Helper to create delegation options with required fields
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

describe("Delegation Completion Integration", () => {
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

  describe("Delegation lifecycle", () => {
    test("creates delegation with all required fields", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Delegation Test",
        storage: "local",
      })

      const issueResult = await fixture.issueStorage.createIssue(
        project.projectDir,
        "Delegation task"
      )
      const issueId = issueResult.ok ? issueResult.value : ""

      const result = await fixture.delegationManager.create(
        project.projectId,
        project.projectDir,
        createDelegationOptions({
          issueId,
          prompt: "Implement the feature",
          agent: "coder",
          parentSessionId: "parent-session-1",
          parentAgent: "orchestrator",
        })
      )

      expect(result.ok).toBe(true)
      if (result.ok) {
        const delegation = result.value
        expect(delegation.id).toMatch(/^del-/)
        expect(delegation.projectId).toBe(project.projectId)
        expect(delegation.issueId).toBe(issueId)
        expect(delegation.prompt).toBe("Implement the feature")
        expect(delegation.agent).toBe("coder")
        expect(delegation.parentSessionId).toBe("parent-session-1")
        expect(delegation.parentAgent).toBe("orchestrator")
        expect(delegation.teamId).toBe("team-test")
        expect(delegation.role).toBe("primary")
      }
    })

    test("persists delegation to disk", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Persistence Test",
        storage: "local",
      })

      const result = await fixture.delegationManager.create(
        project.projectId,
        project.projectDir,
        createDelegationOptions({
          issueId: "issue-123",
          prompt: "Test prompt",
        })
      )

      expect(result.ok).toBe(true)
      if (result.ok) {
        const delegation = result.value
        const filePath = path.join(project.projectDir, "delegations", `${delegation.id}.json`)
        const content = await fs.readFile(filePath, "utf8")
        const saved = JSON.parse(content)

        expect(saved.id).toBe(delegation.id)
        expect(saved.issueId).toBe("issue-123")
        expect(saved.prompt).toBe("Test prompt")
      }
    })

    test("completes delegation with result", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Completion Test",
        storage: "local",
      })

      const createResult = await fixture.delegationManager.create(
        project.projectId,
        project.projectDir,
        createDelegationOptions({
          issueId: "issue-123",
          prompt: "Implement feature",
        })
      )

      expect(createResult.ok).toBe(true)
      if (!createResult.ok) return

      const delegation = createResult.value
      const completeResult = await fixture.delegationManager.complete(
        delegation.id,
        "Feature implemented successfully with tests"
      )

      expect(completeResult.ok).toBe(true)

      const getResult = await fixture.delegationManager.get(delegation.id)
      expect(getResult.ok).toBe(true)
      if (getResult.ok) {
        expect(getResult.value.status).toBe("completed")
        expect(getResult.value.result).toBe("Feature implemented successfully with tests")
        expect(getResult.value.completedAt).toBeDefined()
      }
    })

    test("persists result markdown file", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Result File Test",
        storage: "local",
      })

      const createResult = await fixture.delegationManager.create(
        project.projectId,
        project.projectDir,
        createDelegationOptions({
          issueId: "issue-456",
          prompt: "Write documentation",
        })
      )

      expect(createResult.ok).toBe(true)
      if (!createResult.ok) return

      const delegation = createResult.value
      await fixture.delegationManager.complete(delegation.id, "Documentation written")

      const resultPath = path.join(project.projectDir, "delegations", `${delegation.id}.md`)
      const content = await fs.readFile(resultPath, "utf8")

      expect(content).toContain("issue-456")
      expect(content).toContain("## Prompt")
      expect(content).toContain("Write documentation")
      expect(content).toContain("## Result")
      expect(content).toContain("Documentation written")
    })
  })

  describe("Delegation failure handling", () => {
    test("marks delegation as failed with error", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Failure Test",
        storage: "local",
      })

      const createResult = await fixture.delegationManager.create(
        project.projectId,
        project.projectDir,
        createDelegationOptions({
          issueId: "issue-fail",
          prompt: "Risky operation",
        })
      )

      expect(createResult.ok).toBe(true)
      if (!createResult.ok) return

      const delegation = createResult.value
      const failResult = await fixture.delegationManager.fail(
        delegation.id,
        "Operation failed: timeout exceeded"
      )

      expect(failResult.ok).toBe(true)

      const getResult = await fixture.delegationManager.get(delegation.id)
      expect(getResult.ok).toBe(true)
      if (getResult.ok) {
        expect(getResult.value.status).toBe("failed")
        expect(getResult.value.error).toBe("Operation failed: timeout exceeded")
      }
    })

    test("cancels pending delegation", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Cancel Test",
        storage: "local",
      })

      const createResult = await fixture.delegationManager.create(
        project.projectId,
        project.projectDir,
        createDelegationOptions({
          issueId: "issue-cancel",
          prompt: "Cancellable task",
        })
      )

      expect(createResult.ok).toBe(true)
      if (!createResult.ok) return

      const delegation = createResult.value
      const cancelResult = await fixture.delegationManager.cancel(delegation.id)

      expect(cancelResult.ok).toBe(true)

      const getResult = await fixture.delegationManager.get(delegation.id)
      expect(getResult.ok).toBe(true)
      if (getResult.ok) {
        expect(getResult.value.status).toBe("cancelled")
      }
    })

    test("cannot cancel completed delegation", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Cancel Completed Test",
        storage: "local",
      })

      const createResult = await fixture.delegationManager.create(
        project.projectId,
        project.projectDir,
        createDelegationOptions({
          issueId: "issue-done",
          prompt: "Already done",
        })
      )

      expect(createResult.ok).toBe(true)
      if (!createResult.ok) return

      const delegation = createResult.value
      await fixture.delegationManager.complete(delegation.id, "Done")

      const cancelResult = await fixture.delegationManager.cancel(delegation.id)
      expect(cancelResult.ok).toBe(false)
      if (!cancelResult.ok) {
        expect(cancelResult.error.type).toBe("already_completed")
      }
    })
  })

  describe("Delegation listing and filtering", () => {
    test("lists all delegations", async () => {
      const project = await fixture.projectManager.createProject({
        name: "List Test",
        storage: "local",
      })

      await fixture.delegationManager.create(
        project.projectId,
        project.projectDir,
        createDelegationOptions({ issueId: "issue-1", prompt: "Task 1" })
      )
      await fixture.delegationManager.create(
        project.projectId,
        project.projectDir,
        createDelegationOptions({ issueId: "issue-2", prompt: "Task 2" })
      )
      await fixture.delegationManager.create(
        project.projectId,
        project.projectDir,
        createDelegationOptions({ issueId: "issue-3", prompt: "Task 3" })
      )

      const delegations = await fixture.delegationManager.list()
      expect(delegations.length).toBe(3)
    })

    test("filters by status", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Filter Status Test",
        storage: "local",
      })

      const d1Result = await fixture.delegationManager.create(
        project.projectId,
        project.projectDir,
        createDelegationOptions({ issueId: "issue-1", prompt: "Task 1" })
      )
      await fixture.delegationManager.create(
        project.projectId,
        project.projectDir,
        createDelegationOptions({ issueId: "issue-2", prompt: "Task 2" })
      )

      if (d1Result.ok) {
        await fixture.delegationManager.complete(d1Result.value.id, "Done")
      }

      const completed = await fixture.delegationManager.list({ status: "completed" })
      // With mock client, delegations transition to "running" immediately
      const running = await fixture.delegationManager.list({ status: "running" })

      expect(completed.length).toBe(1)
      expect(running.length).toBe(1)
    })

    test("filters by issueId", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Filter Issue Test",
        storage: "local",
      })

      await fixture.delegationManager.create(
        project.projectId,
        project.projectDir,
        createDelegationOptions({ issueId: "issue-A", prompt: "Task A1" })
      )
      await fixture.delegationManager.create(
        project.projectId,
        project.projectDir,
        createDelegationOptions({ issueId: "issue-A", prompt: "Task A2" })
      )
      await fixture.delegationManager.create(
        project.projectId,
        project.projectDir,
        createDelegationOptions({ issueId: "issue-B", prompt: "Task B1" })
      )

      const issueADelegations = await fixture.delegationManager.list({ issueId: "issue-A" })
      const issueBDelegations = await fixture.delegationManager.list({ issueId: "issue-B" })

      expect(issueADelegations.length).toBe(2)
      expect(issueBDelegations.length).toBe(1)
    })

    test("gets active delegations for issue", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Active Test",
        storage: "local",
      })

      const d1Result = await fixture.delegationManager.create(
        project.projectId,
        project.projectDir,
        createDelegationOptions({ issueId: "issue-active", prompt: "Task 1" })
      )
      await fixture.delegationManager.create(
        project.projectId,
        project.projectDir,
        createDelegationOptions({ issueId: "issue-active", prompt: "Task 2" })
      )

      if (d1Result.ok) {
        await fixture.delegationManager.complete(d1Result.value.id, "Done")
      }

      const active = await fixture.delegationManager.getActiveDelegations("issue-active")
      expect(active.length).toBe(1)
      expect(active[0].prompt).toBe("Task 2")
    })
  })

  describe("Delegation completion tracking", () => {
    test("areAllComplete returns true when no delegations", async () => {
      const allComplete = await fixture.delegationManager.areAllComplete("non-existent-issue")
      expect(allComplete).toBe(true)
    })

    test("areAllComplete returns false when delegations pending", async () => {
      const project = await fixture.projectManager.createProject({
        name: "All Complete Test",
        storage: "local",
      })

      await fixture.delegationManager.create(
        project.projectId,
        project.projectDir,
        createDelegationOptions({ issueId: "issue-pending", prompt: "Pending task" })
      )

      const allComplete = await fixture.delegationManager.areAllComplete("issue-pending")
      expect(allComplete).toBe(false)
    })

    test("areAllComplete returns true when all completed", async () => {
      const project = await fixture.projectManager.createProject({
        name: "All Done Test",
        storage: "local",
      })

      const d1Result = await fixture.delegationManager.create(
        project.projectId,
        project.projectDir,
        createDelegationOptions({ issueId: "issue-done", prompt: "Task 1" })
      )
      const d2Result = await fixture.delegationManager.create(
        project.projectId,
        project.projectDir,
        createDelegationOptions({ issueId: "issue-done", prompt: "Task 2" })
      )

      if (d1Result.ok) await fixture.delegationManager.complete(d1Result.value.id, "Done 1")
      if (d2Result.ok) await fixture.delegationManager.complete(d2Result.value.id, "Done 2")

      const allComplete = await fixture.delegationManager.areAllComplete("issue-done")
      expect(allComplete).toBe(true)
    })

    test("areAllComplete returns true when all failed", async () => {
      const project = await fixture.projectManager.createProject({
        name: "All Failed Test",
        storage: "local",
      })

      const d1Result = await fixture.delegationManager.create(
        project.projectId,
        project.projectDir,
        createDelegationOptions({ issueId: "issue-failed", prompt: "Task 1" })
      )

      if (d1Result.ok) await fixture.delegationManager.fail(d1Result.value.id, "Error")

      const allComplete = await fixture.delegationManager.areAllComplete("issue-failed")
      expect(allComplete).toBe(true)
    })
  })

  describe("Delegation with different roles", () => {
    test("supports primary role", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Primary Role Test",
        storage: "local",
      })

      const result = await fixture.delegationManager.create(
        project.projectId,
        project.projectDir,
        createDelegationOptions({
          issueId: "issue-primary",
          prompt: "Primary task",
          role: "primary",
        })
      )

      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(result.value.role).toBe("primary")
      }
    })

    test("supports secondary role", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Secondary Role Test",
        storage: "local",
      })

      const result = await fixture.delegationManager.create(
        project.projectId,
        project.projectDir,
        createDelegationOptions({
          issueId: "issue-secondary",
          prompt: "Review task",
          role: "secondary",
        })
      )

      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(result.value.role).toBe("secondary")
      }
    })

    test("supports devilsAdvocate role", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Devils Advocate Test",
        storage: "local",
      })

      const result = await fixture.delegationManager.create(
        project.projectId,
        project.projectDir,
        createDelegationOptions({
          issueId: "issue-devil",
          prompt: "Critical review",
          role: "devilsAdvocate",
        })
      )

      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(result.value.role).toBe("devilsAdvocate")
      }
    })
  })

  describe("Delegation with worktree info", () => {
    test("stores worktree path and branch", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Worktree Info Test",
        storage: "local",
      })

      const result = await fixture.delegationManager.create(
        project.projectId,
        project.projectDir,
        createDelegationOptions({
          issueId: "issue-wt",
          prompt: "Code changes",
          worktreePath: "/tmp/worktree/issue-wt",
          worktreeBranch: "feature/issue-wt",
          vcs: "git",
        })
      )

      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(result.value.worktreePath).toBe("/tmp/worktree/issue-wt")
        expect(result.value.worktreeBranch).toBe("feature/issue-wt")
        expect(result.value.vcs).toBe("git")
      }
    })
  })

  describe("Recent completed delegations", () => {
    test("gets recent completed delegations for compaction", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Recent Test",
        storage: "local",
      })

      // Create and complete several delegations
      for (let i = 0; i < 5; i++) {
        const result = await fixture.delegationManager.create(
          project.projectId,
          project.projectDir,
          createDelegationOptions({
            issueId: `issue-${i}`,
            prompt: `Task ${i}`,
          })
        )
        if (result.ok) {
          await fixture.delegationManager.complete(result.value.id, `Result ${i}`)
        }
      }

      const recent = await fixture.delegationManager.getRecentCompletedDelegations(3)
      expect(recent.length).toBe(3)
      expect(recent.every((d) => d.status === "completed")).toBe(true)
    })
  })
})
