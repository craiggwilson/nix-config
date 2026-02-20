/**
 * Tests for WorktreeManager
 */

import { describe, test, expect, beforeAll, afterAll } from "bun:test"
import * as fs from "node:fs/promises"
import * as path from "node:path"
import * as os from "node:os"
import { $ } from "bun"

import { WorktreeManager } from "./worktree-manager.js"
import { createMockLogger, createTestShell } from "../core/test-utils.js"

const mockLogger = createMockLogger()
const testShell = createTestShell()

// Check if git is available
async function isGitAvailable(): Promise<boolean> {
  try {
    const result = await $`git --version`.nothrow().quiet()
    return result.exitCode === 0
  } catch {
    return false
  }
}

describe("WorktreeManager", () => {
  let testDir: string
  let repoDir: string
  let manager: WorktreeManager
  let gitAvailable: boolean

  beforeAll(async () => {
    gitAvailable = await isGitAvailable()
    if (!gitAvailable) {
      console.log("Skipping WorktreeManager tests - git not available")
      return
    }

    // Create a temporary directory
    testDir = await fs.mkdtemp(path.join(os.tmpdir(), "worktree-manager-test-"))
    repoDir = path.join(testDir, "repo")

    // Initialize a git repo
    await fs.mkdir(repoDir, { recursive: true })
    await $`git -C ${repoDir} init`.quiet()
    await $`git -C ${repoDir} config user.email "test@test.com"`.quiet()
    await $`git -C ${repoDir} config user.name "Test"`.quiet()

    // Create initial commit
    await fs.writeFile(path.join(repoDir, "README.md"), "# Test Repo")
    await $`git -C ${repoDir} add .`.quiet()
    await $`git -C ${repoDir} commit -m "Initial commit"`.quiet()

    manager = new WorktreeManager(repoDir, testShell, mockLogger)
  })

  afterAll(async () => {
    if (testDir) {
      await fs.rm(testDir, { recursive: true, force: true })
    }
  })

  test("detectVCS detects git repository", async () => {
    if (!gitAvailable) return

    const adapter = await manager.detectVCS()

    expect(adapter).not.toBeNull()
    expect(manager.getVCSType()).toBe("git")
  })

  test("getVCSContext returns git context", async () => {
    if (!gitAvailable) return

    await manager.detectVCS()
    const context = manager.getVCSContext()

    expect(context).toContain("Git")
    expect(context).toContain("git status")
    expect(context).toContain("<vcs-context>")
  })

  test("createIsolatedWorktree creates worktree for issue", async () => {
    if (!gitAvailable) return

    const result = await manager.createIsolatedWorktree({
      projectId: "test-project",
      issueId: "issue-123",
    })

    expect(result.success).toBe(true)
    expect(result.info).not.toBeNull()
    expect(result.info!.name).toBe("test-project/issue-123")
    expect(result.info!.isMain).toBe(false)

    // Verify directory exists
    const stat = await fs.stat(result.info!.path)
    expect(stat.isDirectory()).toBe(true)

    // Clean up
    await manager.removeWorktree(result.info!.name)
  })

  test("listProjectWorktrees filters by project", async () => {
    if (!gitAvailable) return

    // Create worktrees for different projects
    await manager.createIsolatedWorktree({
      projectId: "project-a",
      issueId: "issue-1",
    })
    await manager.createIsolatedWorktree({
      projectId: "project-b",
      issueId: "issue-2",
    })

    const projectAWorktrees = await manager.listProjectWorktrees("project-a")
    const projectBWorktrees = await manager.listProjectWorktrees("project-b")

    expect(projectAWorktrees.length).toBe(1)
    expect(projectAWorktrees[0].name).toBe("project-a/issue-1")

    expect(projectBWorktrees.length).toBe(1)
    expect(projectBWorktrees[0].name).toBe("project-b/issue-2")

    // Clean up
    await manager.removeWorktree("project-a/issue-1")
    await manager.removeWorktree("project-b/issue-2")
  })

  test("getWorktree finds specific worktree", async () => {
    if (!gitAvailable) return

    await manager.createIsolatedWorktree({
      projectId: "find-project",
      issueId: "find-issue",
    })

    const worktree = await manager.getWorktree("find-project", "find-issue")

    expect(worktree).not.toBeNull()
    expect(worktree!.name).toBe("find-project/find-issue")

    // Clean up
    await manager.removeWorktree("find-project/find-issue")
  })

  test("listAllWorktrees includes main and created worktrees", async () => {
    if (!gitAvailable) return

    await manager.createIsolatedWorktree({
      projectId: "list-all",
      issueId: "issue",
    })

    const all = await manager.listAllWorktrees()

    expect(all.length).toBeGreaterThanOrEqual(2)
    expect(all.some((w) => w.isMain)).toBe(true)
    expect(all.some((w) => w.name === "list-all/issue")).toBe(true)

    // Clean up
    await manager.removeWorktree("list-all/issue")
  })

  test("removeWorktree removes the worktree", async () => {
    if (!gitAvailable) return

    const result = await manager.createIsolatedWorktree({
      projectId: "remove-test",
      issueId: "issue",
    })

    const removed = await manager.removeWorktree(result.info!.name)

    expect(removed).toBe(true)

    // Verify it's gone
    const worktree = await manager.getWorktree("remove-test", "issue")
    expect(worktree).toBeNull()
  })

  test("getCurrentBranch returns current branch", async () => {
    if (!gitAvailable) return

    const branch = await manager.getCurrentBranch()

    expect(branch).not.toBeNull()
    expect(["main", "master"]).toContain(branch!)
  })

  test("getDefaultBranch returns default branch", async () => {
    if (!gitAvailable) return

    const branch = await manager.getDefaultBranch()

    expect(branch).not.toBeNull()
    expect(["main", "master"]).toContain(branch!)
  })

  test("hasUncommittedChanges returns false for clean repo", async () => {
    if (!gitAvailable) return

    const hasChanges = await manager.hasUncommittedChanges()

    expect(hasChanges).toBe(false)
  })
})

describe("WorktreeManager without VCS", () => {
  test("detectVCS returns null for non-repo directory", async () => {
    const tempDir = await fs.mkdtemp(path.join(os.tmpdir(), "no-vcs-test-"))
    const manager = new WorktreeManager(tempDir, testShell, mockLogger)

    const adapter = await manager.detectVCS()

    expect(adapter).toBeNull()
    expect(manager.getVCSType()).toBeNull()
    expect(manager.getVCSContext()).toBeNull()

    await fs.rm(tempDir, { recursive: true, force: true })
  })
})
