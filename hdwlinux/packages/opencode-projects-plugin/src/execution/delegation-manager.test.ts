/**
 * Tests for DelegationManager
 */

import { describe, test, expect, beforeEach, afterAll } from "bun:test"
import * as fs from "node:fs/promises"
import * as path from "node:path"
import * as os from "node:os"

import { DelegationManager } from "./delegation-manager.js"
import { createMockLogger } from "../core/test-utils.js"

const mockLogger = createMockLogger()

describe("DelegationManager", () => {
  let testDir: string
  let manager: DelegationManager

  beforeEach(async () => {
    // Create a fresh temporary directory for each test
    testDir = await fs.mkdtemp(path.join(os.tmpdir(), "delegation-test-"))
    manager = new DelegationManager(testDir, mockLogger)
  })

  afterAll(async () => {
    // Cleanup all test directories
    try {
      const tmpDir = os.tmpdir()
      const entries = await fs.readdir(tmpDir)
      for (const entry of entries) {
        if (entry.startsWith("delegation-test-")) {
          await fs.rm(path.join(tmpDir, entry), { recursive: true, force: true })
        }
      }
    } catch {
      // Ignore cleanup errors
    }
  })

  describe("create", () => {
    test("creates a new delegation", async () => {
      const delegation = await manager.create("test-project", {
        issueId: "issue-123",
        prompt: "Implement the feature",
      })

      expect(delegation.id).toMatch(/^del-/)
      expect(delegation.projectId).toBe("test-project")
      expect(delegation.issueId).toBe("issue-123")
      expect(delegation.prompt).toBe("Implement the feature")
      expect(delegation.status).toBe("pending")
      expect(delegation.startedAt).toBeDefined()
    })

    test("persists delegation to disk", async () => {
      const delegation = await manager.create("test-project", {
        issueId: "issue-123",
        prompt: "Test prompt",
      })

      const filePath = path.join(testDir, "delegations", `${delegation.id}.json`)
      const content = await fs.readFile(filePath, "utf8")
      const saved = JSON.parse(content)

      expect(saved.id).toBe(delegation.id)
      expect(saved.issueId).toBe("issue-123")
    })

    test("includes optional fields", async () => {
      const delegation = await manager.create("test-project", {
        issueId: "issue-123",
        prompt: "Test prompt",
        worktreePath: "/path/to/worktree",
        agent: "coder",
      })

      expect(delegation.worktreePath).toBe("/path/to/worktree")
      expect(delegation.agent).toBe("coder")
    })
  })

  describe("get", () => {
    test("retrieves a delegation by ID", async () => {
      const created = await manager.create("test-project", {
        issueId: "issue-123",
        prompt: "Test prompt",
      })

      const retrieved = await manager.get(created.id)

      expect(retrieved).not.toBeNull()
      expect(retrieved!.id).toBe(created.id)
      expect(retrieved!.issueId).toBe("issue-123")
    })

    test("returns null for non-existent delegation", async () => {
      const retrieved = await manager.get("non-existent")

      expect(retrieved).toBeNull()
    })
  })

  describe("list", () => {
    test("lists all delegations", async () => {
      await manager.create("test-project", { issueId: "issue-1", prompt: "Prompt 1" })
      await manager.create("test-project", { issueId: "issue-2", prompt: "Prompt 2" })
      await manager.create("test-project", { issueId: "issue-3", prompt: "Prompt 3" })

      const delegations = await manager.list()

      expect(delegations.length).toBe(3)
    })

    test("filters by status", async () => {
      const d1 = await manager.create("test-project", { issueId: "issue-1", prompt: "Prompt 1" })
      await manager.create("test-project", { issueId: "issue-2", prompt: "Prompt 2" })

      await manager.complete(d1.id, "Done")

      const completed = await manager.list({ status: "completed" })
      const pending = await manager.list({ status: "pending" })

      expect(completed.length).toBe(1)
      expect(pending.length).toBe(1)
    })

    test("filters by issueId", async () => {
      await manager.create("test-project", { issueId: "issue-1", prompt: "Prompt 1" })
      await manager.create("test-project", { issueId: "issue-1", prompt: "Prompt 2" })
      await manager.create("test-project", { issueId: "issue-2", prompt: "Prompt 3" })

      const issue1Delegations = await manager.list({ issueId: "issue-1" })
      const issue2Delegations = await manager.list({ issueId: "issue-2" })

      expect(issue1Delegations.length).toBe(2)
      expect(issue2Delegations.length).toBe(1)
    })
  })

  describe("complete", () => {
    test("marks delegation as completed", async () => {
      const delegation = await manager.create("test-project", {
        issueId: "issue-123",
        prompt: "Test prompt",
      })

      const success = await manager.complete(delegation.id, "Task completed successfully")

      expect(success).toBe(true)

      const updated = await manager.get(delegation.id)
      expect(updated!.status).toBe("completed")
      expect(updated!.result).toBe("Task completed successfully")
      expect(updated!.completedAt).toBeDefined()
    })

    test("persists result to research directory", async () => {
      const delegation = await manager.create("test-project", {
        issueId: "issue-123",
        prompt: "Test prompt",
      })

      await manager.complete(delegation.id, "Task completed")

      const resultPath = path.join(testDir, "research", `delegation-${delegation.id}.md`)
      const content = await fs.readFile(resultPath, "utf8")

      expect(content).toContain("# Delegation: issue-123")
      expect(content).toContain("## Prompt")
      expect(content).toContain("Test prompt")
      expect(content).toContain("## Result")
      expect(content).toContain("Task completed")
    })
  })

  describe("fail", () => {
    test("marks delegation as failed", async () => {
      const delegation = await manager.create("test-project", {
        issueId: "issue-123",
        prompt: "Test prompt",
      })

      const success = await manager.fail(delegation.id, "Something went wrong")

      expect(success).toBe(true)

      const updated = await manager.get(delegation.id)
      expect(updated!.status).toBe("failed")
      expect(updated!.error).toBe("Something went wrong")
    })
  })

  describe("cancel", () => {
    test("cancels a pending delegation", async () => {
      const delegation = await manager.create("test-project", {
        issueId: "issue-123",
        prompt: "Test prompt",
      })

      const success = await manager.cancel(delegation.id)

      expect(success).toBe(true)

      const updated = await manager.get(delegation.id)
      expect(updated!.status).toBe("cancelled")
    })

    test("cannot cancel completed delegation", async () => {
      const delegation = await manager.create("test-project", {
        issueId: "issue-123",
        prompt: "Test prompt",
      })

      await manager.complete(delegation.id, "Done")
      const success = await manager.cancel(delegation.id)

      expect(success).toBe(false)
    })
  })

  describe("areAllComplete", () => {
    test("returns true when no delegations", async () => {
      const allComplete = await manager.areAllComplete("issue-123")

      expect(allComplete).toBe(true)
    })

    test("returns false when delegations are pending", async () => {
      await manager.create("test-project", { issueId: "issue-123", prompt: "Prompt" })

      const allComplete = await manager.areAllComplete("issue-123")

      expect(allComplete).toBe(false)
    })

    test("returns true when all delegations are complete", async () => {
      const d1 = await manager.create("test-project", { issueId: "issue-123", prompt: "Prompt 1" })
      const d2 = await manager.create("test-project", { issueId: "issue-123", prompt: "Prompt 2" })

      await manager.complete(d1.id, "Done 1")
      await manager.complete(d2.id, "Done 2")

      const allComplete = await manager.areAllComplete("issue-123")

      expect(allComplete).toBe(true)
    })
  })

  describe("getActiveDelegations", () => {
    test("returns only pending/running delegations", async () => {
      const d1 = await manager.create("test-project", { issueId: "issue-123", prompt: "Prompt 1" })
      await manager.create("test-project", { issueId: "issue-123", prompt: "Prompt 2" })

      await manager.complete(d1.id, "Done")

      const active = await manager.getActiveDelegations("issue-123")

      expect(active.length).toBe(1)
      expect(active[0].status).toBe("pending")
    })
  })
})
