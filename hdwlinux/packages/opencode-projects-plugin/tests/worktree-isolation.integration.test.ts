/**
 * Integration tests for worktree isolation
 *
 * Tests worktree creation, isolation, and cleanup for code changes.
 *
 * CRITICAL: All tests use local storage in temporary directories to prevent
 * interference with actual projects.
 */

import { describe, test, expect, beforeAll, beforeEach, afterEach, afterAll } from "bun:test"
import * as fs from "node:fs/promises"
import * as path from "node:path"

import {
  createIntegrationFixture,
  cleanupTestDirectories,
  isGitAvailable,
  type IntegrationTestFixture,
} from "./integration-test-utils.js"

describe("Worktree Isolation Integration", () => {
  let fixture: IntegrationTestFixture
  let gitAvailable: boolean

  beforeAll(async () => {
    gitAvailable = await isGitAvailable()
    if (!gitAvailable) {
      console.log("Skipping worktree tests - git not available")
    }
  })

  beforeEach(async () => {
    if (!gitAvailable) return
    fixture = await createIntegrationFixture({ initGitRepo: true })
  })

  afterEach(async () => {
    if (fixture) {
      await fixture.cleanup()
    }
  })

  afterAll(async () => {
    await cleanupTestDirectories("opencode-integration-test-")
  })

  describe("Worktree creation", () => {
    test("creates isolated worktree for issue", async () => {
      if (!gitAvailable) return

      const project = await fixture.projectManager.createProject({
        name: "Worktree Test",
        storage: "local",
      })

      const issueResult = await fixture.issueStorage.createIssue(
        project.projectDir,
        "Code change task"
      )
      const issueId = issueResult.ok ? issueResult.value : ""

      const result = await fixture.worktreeManager.createIsolatedWorktree({
        projectId: project.projectId,
        issueId,
      })

      expect(result.ok).toBe(true)
      if (result.ok) {
        const worktree = result.value
        expect(worktree.name).toBe(`${project.projectId}/${issueId}`)
        expect(worktree.isMain).toBe(false)

        // Verify directory exists
        const stat = await fs.stat(worktree.path)
        expect(stat.isDirectory()).toBe(true)

        // Verify it's a separate working directory
        const readmeExists = await fs.access(path.join(worktree.path, "README.md"))
          .then(() => true)
          .catch(() => false)
        expect(readmeExists).toBe(true)

        // Clean up
        await fixture.worktreeManager.removeWorktree(worktree.name)
      }
    })

    test("creates worktree with custom base branch", async () => {
      if (!gitAvailable) return

      const project = await fixture.projectManager.createProject({
        name: "Base Branch Test",
        storage: "local",
      })

      // Get current branch name
      const branchResult = await fixture.worktreeManager.getCurrentBranch()
      expect(branchResult.ok).toBe(true)
      const baseBranch = branchResult.ok ? branchResult.value : "main"

      const result = await fixture.worktreeManager.createIsolatedWorktree({
        projectId: project.projectId,
        issueId: "issue-base",
        baseBranch,
      })

      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(result.value.branch).toBeDefined()
        await fixture.worktreeManager.removeWorktree(result.value.name)
      }
    })

    test("lists worktrees by project", async () => {
      if (!gitAvailable) return

      const projectA = await fixture.projectManager.createProject({
        name: "Project A",
        storage: "local",
      })

      const projectB = await fixture.projectManager.createProject({
        name: "Project B",
        storage: "local",
      })

      // Create worktrees for different projects
      await fixture.worktreeManager.createIsolatedWorktree({
        projectId: projectA.projectId,
        issueId: "issue-a1",
      })
      await fixture.worktreeManager.createIsolatedWorktree({
        projectId: projectA.projectId,
        issueId: "issue-a2",
      })
      await fixture.worktreeManager.createIsolatedWorktree({
        projectId: projectB.projectId,
        issueId: "issue-b1",
      })

      const projectAWorktrees = await fixture.worktreeManager.listProjectWorktrees(projectA.projectId)
      const projectBWorktrees = await fixture.worktreeManager.listProjectWorktrees(projectB.projectId)

      expect(projectAWorktrees.ok).toBe(true)
      expect(projectBWorktrees.ok).toBe(true)

      if (projectAWorktrees.ok && projectBWorktrees.ok) {
        expect(projectAWorktrees.value.length).toBe(2)
        expect(projectBWorktrees.value.length).toBe(1)
      }

      // Clean up
      await fixture.worktreeManager.removeWorktree(`${projectA.projectId}/issue-a1`)
      await fixture.worktreeManager.removeWorktree(`${projectA.projectId}/issue-a2`)
      await fixture.worktreeManager.removeWorktree(`${projectB.projectId}/issue-b1`)
    })

    test("gets specific worktree by issue", async () => {
      if (!gitAvailable) return

      const project = await fixture.projectManager.createProject({
        name: "Get Worktree Test",
        storage: "local",
      })

      await fixture.worktreeManager.createIsolatedWorktree({
        projectId: project.projectId,
        issueId: "find-me",
      })

      const result = await fixture.worktreeManager.getWorktree(project.projectId, "find-me")

      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(result.value).not.toBeNull()
        expect(result.value!.name).toBe(`${project.projectId}/find-me`)
      }

      // Clean up
      await fixture.worktreeManager.removeWorktree(`${project.projectId}/find-me`)
    })

    test("returns null for non-existent worktree", async () => {
      if (!gitAvailable) return

      const result = await fixture.worktreeManager.getWorktree("fake-project", "fake-issue")

      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(result.value).toBeNull()
      }
    })
  })

  describe("Worktree isolation", () => {
    test("changes in worktree are isolated from main", async () => {
      if (!gitAvailable) return

      const project = await fixture.projectManager.createProject({
        name: "Isolation Test",
        storage: "local",
      })

      const createResult = await fixture.worktreeManager.createIsolatedWorktree({
        projectId: project.projectId,
        issueId: "isolated-changes",
      })

      expect(createResult.ok).toBe(true)
      if (!createResult.ok) return

      const worktree = createResult.value

      // Create a file in the worktree
      const testFile = path.join(worktree.path, "new-feature.ts")
      await fs.writeFile(testFile, "export const feature = true;")

      // Verify file exists in worktree
      const existsInWorktree = await fs.access(testFile)
        .then(() => true)
        .catch(() => false)
      expect(existsInWorktree).toBe(true)

      // Verify file does NOT exist in main repo
      const existsInMain = await fs.access(path.join(fixture.repoDir, "new-feature.ts"))
        .then(() => true)
        .catch(() => false)
      expect(existsInMain).toBe(false)

      // Clean up
      await fixture.worktreeManager.removeWorktree(worktree.name)
    })

    test("worktree has its own branch", async () => {
      if (!gitAvailable) return

      const project = await fixture.projectManager.createProject({
        name: "Branch Test",
        storage: "local",
      })

      const createResult = await fixture.worktreeManager.createIsolatedWorktree({
        projectId: project.projectId,
        issueId: "branch-test",
      })

      expect(createResult.ok).toBe(true)
      if (!createResult.ok) return

      const worktree = createResult.value
      expect(worktree.branch).toBeDefined()
      expect(worktree.branch).not.toBe("main")
      expect(worktree.branch).not.toBe("master")

      // Clean up
      await fixture.worktreeManager.removeWorktree(worktree.name)
    })
  })

  describe("Worktree cleanup", () => {
    test("removes worktree and directory", async () => {
      if (!gitAvailable) return

      const project = await fixture.projectManager.createProject({
        name: "Cleanup Test",
        storage: "local",
      })

      const createResult = await fixture.worktreeManager.createIsolatedWorktree({
        projectId: project.projectId,
        issueId: "cleanup-me",
      })

      expect(createResult.ok).toBe(true)
      if (!createResult.ok) return

      const worktree = createResult.value
      const worktreePath = worktree.path

      // Verify it exists
      const existsBefore = await fs.access(worktreePath)
        .then(() => true)
        .catch(() => false)
      expect(existsBefore).toBe(true)

      // Remove it
      const removeResult = await fixture.worktreeManager.removeWorktree(worktree.name)
      expect(removeResult.ok).toBe(true)

      // Verify it's gone
      const existsAfter = await fs.access(worktreePath)
        .then(() => true)
        .catch(() => false)
      expect(existsAfter).toBe(false)

      // Verify getWorktree returns null
      const getResult = await fixture.worktreeManager.getWorktree(project.projectId, "cleanup-me")
      expect(getResult.ok).toBe(true)
      if (getResult.ok) {
        expect(getResult.value).toBeNull()
      }
    })
  })

  describe("VCS detection", () => {
    test("detects git repository", async () => {
      if (!gitAvailable) return

      const adapterResult = await fixture.worktreeManager.detectVCS()

      expect(adapterResult.ok).toBe(true)
      expect(fixture.worktreeManager.getVCSType()).toBe("git")
    })

    test("provides VCS context for prompts", async () => {
      if (!gitAvailable) return

      await fixture.worktreeManager.detectVCS()
      const context = fixture.worktreeManager.getVCSContext()

      expect(context).not.toBeNull()
      expect(context).toContain("<vcs-context>")
      expect(context).toContain("Git")
      expect(context).toContain("git status")
    })

    test("gets current branch", async () => {
      if (!gitAvailable) return

      const result = await fixture.worktreeManager.getCurrentBranch()

      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(["main", "master"]).toContain(result.value)
      }
    })

    test("gets default branch", async () => {
      if (!gitAvailable) return

      const result = await fixture.worktreeManager.getDefaultBranch()

      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(["main", "master"]).toContain(result.value)
      }
    })

    test("detects uncommitted changes", async () => {
      if (!gitAvailable) return

      // Clean repo should have no uncommitted changes
      const cleanResult = await fixture.worktreeManager.hasUncommittedChanges()
      expect(cleanResult.ok).toBe(true)
      if (cleanResult.ok) {
        expect(cleanResult.value).toBe(false)
      }

      // Create an uncommitted change
      await fs.writeFile(path.join(fixture.repoDir, "uncommitted.txt"), "test")

      const dirtyResult = await fixture.worktreeManager.hasUncommittedChanges()
      expect(dirtyResult.ok).toBe(true)
      if (dirtyResult.ok) {
        expect(dirtyResult.value).toBe(true)
      }
    })
  })

  describe("Path traversal protection", () => {
    test("rejects path traversal in projectId", async () => {
      if (!gitAvailable) return

      const result = await fixture.worktreeManager.createIsolatedWorktree({
        projectId: "../../../etc",
        issueId: "passwd",
      })

      expect(result.ok).toBe(false)
      if (!result.ok) {
        expect(result.error.name).toBe("WorktreeError")
      }
    })

    test("rejects path traversal in issueId", async () => {
      if (!gitAvailable) return

      const result = await fixture.worktreeManager.createIsolatedWorktree({
        projectId: "valid-project",
        issueId: "../../../etc/passwd",
      })

      expect(result.ok).toBe(false)
      if (!result.ok) {
        expect(result.error.name).toBe("WorktreeError")
      }
    })

    test("rejects slashes in issueId", async () => {
      if (!gitAvailable) return

      const result = await fixture.worktreeManager.createIsolatedWorktree({
        projectId: "valid-project",
        issueId: "issue/subissue",
      })

      expect(result.ok).toBe(false)
    })

    test("accepts valid hierarchical issue IDs with dots", async () => {
      if (!gitAvailable) return

      const project = await fixture.projectManager.createProject({
        name: "Dot Test",
        storage: "local",
      })

      const result = await fixture.worktreeManager.createIsolatedWorktree({
        projectId: project.projectId,
        issueId: "bd-a3f8.1.2",
      })

      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(result.value.name).toBe(`${project.projectId}/bd-a3f8.1.2`)
        await fixture.worktreeManager.removeWorktree(result.value.name)
      }
    })
  })

  describe("Worktree listing", () => {
    test("lists all worktrees including main", async () => {
      if (!gitAvailable) return

      const project = await fixture.projectManager.createProject({
        name: "List All Test",
        storage: "local",
      })

      await fixture.worktreeManager.createIsolatedWorktree({
        projectId: project.projectId,
        issueId: "list-all-1",
      })

      const result = await fixture.worktreeManager.listAllWorktrees()

      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(result.value.length).toBeGreaterThanOrEqual(2) // Main + created
        expect(result.value.some((w) => w.isMain)).toBe(true)
        expect(result.value.some((w) => w.name === `${project.projectId}/list-all-1`)).toBe(true)
      }

      // Clean up
      await fixture.worktreeManager.removeWorktree(`${project.projectId}/list-all-1`)
    })
  })
})

describe("Worktree without VCS", () => {
  test("detectVCS returns error for non-repo directory", async () => {
    const fixture = await createIntegrationFixture({ initGitRepo: false })

    try {
      const result = await fixture.worktreeManager.detectVCS()

      expect(result.ok).toBe(false)
      if (!result.ok) {
        expect(result.error.name).toBe("VCSNotDetectedError")
      }
      expect(fixture.worktreeManager.getVCSType()).toBeNull()
      expect(fixture.worktreeManager.getVCSContext()).toBeNull()
    } finally {
      await fixture.cleanup()
    }
  })
})
