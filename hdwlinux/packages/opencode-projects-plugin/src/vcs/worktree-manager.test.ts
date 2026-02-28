/**
 * Tests for WorktreeManager
 */

import { describe, test, expect, beforeAll, afterAll } from "bun:test"
import * as fs from "node:fs/promises"
import * as path from "node:path"
import * as os from "node:os"
import { $ } from "bun"

import { WorktreeManager } from "./worktree-manager.js"
import { createMockLogger, createTestShell } from "../utils/testing/index.js"

const mockLogger = createMockLogger()
const testShell = createTestShell()

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

    testDir = await fs.mkdtemp(path.join(os.tmpdir(), "worktree-manager-test-"))
    repoDir = path.join(testDir, "repo")

    await fs.mkdir(repoDir, { recursive: true })
    await $`git -C ${repoDir} init`.quiet()
    await $`git -C ${repoDir} config user.email "test@test.com"`.quiet()
    await $`git -C ${repoDir} config user.name "Test"`.quiet()

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

    expect(result.ok).toBe(true)
    if (result.ok) {
      expect(result.value.name).toBe("test-project/issue-123")
      expect(result.value.isMain).toBe(false)

      const stat = await fs.stat(result.value.path)
      expect(stat.isDirectory()).toBe(true)

      await manager.removeWorktree(result.value.name)
    }
  })

  test("listProjectWorktrees filters by project", async () => {
    if (!gitAvailable) return

    await manager.createIsolatedWorktree({
      projectId: "project-a",
      issueId: "issue-1",
    })
    await manager.createIsolatedWorktree({
      projectId: "project-b",
      issueId: "issue-2",
    })

    const projectAResult = await manager.listProjectWorktrees("project-a")
    const projectBResult = await manager.listProjectWorktrees("project-b")

    expect(projectAResult.ok).toBe(true)
    expect(projectBResult.ok).toBe(true)

    if (projectAResult.ok && projectBResult.ok) {
      expect(projectAResult.value.length).toBe(1)
      expect(projectAResult.value[0].name).toBe("project-a/issue-1")

      expect(projectBResult.value.length).toBe(1)
      expect(projectBResult.value[0].name).toBe("project-b/issue-2")
    }

    await manager.removeWorktree("project-a/issue-1")
    await manager.removeWorktree("project-b/issue-2")
  })

  test("getWorktree finds specific worktree", async () => {
    if (!gitAvailable) return

    await manager.createIsolatedWorktree({
      projectId: "find-project",
      issueId: "find-issue",
    })

    const result = await manager.getWorktree("find-project", "find-issue")

    expect(result.ok).toBe(true)
    if (result.ok) {
      expect(result.value).not.toBeNull()
      expect(result.value!.name).toBe("find-project/find-issue")
    }

    await manager.removeWorktree("find-project/find-issue")
  })

  test("listAllWorktrees includes main and created worktrees", async () => {
    if (!gitAvailable) return

    await manager.createIsolatedWorktree({
      projectId: "list-all",
      issueId: "issue",
    })

    const result = await manager.listAllWorktrees()

    expect(result.ok).toBe(true)
    if (result.ok) {
      expect(result.value.length).toBeGreaterThanOrEqual(2)
      expect(result.value.some((w) => w.isMain)).toBe(true)
      expect(result.value.some((w) => w.name === "list-all/issue")).toBe(true)
    }

    await manager.removeWorktree("list-all/issue")
  })

  test("removeWorktree removes the worktree", async () => {
    if (!gitAvailable) return

    const createResult = await manager.createIsolatedWorktree({
      projectId: "remove-test",
      issueId: "issue",
    })

    expect(createResult.ok).toBe(true)
    if (createResult.ok) {
      const removeResult = await manager.removeWorktree(createResult.value.name)
      expect(removeResult.ok).toBe(true)

      const getResult = await manager.getWorktree("remove-test", "issue")
      expect(getResult.ok).toBe(true)
      if (getResult.ok) {
        expect(getResult.value).toBeNull()
      }
    }
  })

  test("getCurrentBranch returns current branch", async () => {
    if (!gitAvailable) return

    const result = await manager.getCurrentBranch()

    expect(result.ok).toBe(true)
    if (result.ok) {
      expect(["main", "master"]).toContain(result.value)
    }
  })

  test("getDefaultBranch returns default branch", async () => {
    if (!gitAvailable) return

    const result = await manager.getDefaultBranch()

    expect(result.ok).toBe(true)
    if (result.ok) {
      expect(["main", "master"]).toContain(result.value)
    }
  })

  test("hasUncommittedChanges returns false for clean repo", async () => {
    if (!gitAvailable) return

    const result = await manager.hasUncommittedChanges()

    expect(result.ok).toBe(true)
    if (result.ok) {
      expect(result.value).toBe(false)
    }
  })
})

describe("WorktreeManager without VCS", () => {
  test("detectVCS returns error for non-repo directory", async () => {
    const tempDir = await fs.mkdtemp(path.join(os.tmpdir(), "no-vcs-test-"))
    const manager = new WorktreeManager(tempDir, testShell, mockLogger)

    const result = await manager.detectVCS()

    expect(result.ok).toBe(false)
    if (!result.ok) {
      expect(result.error.name).toBe("VCSNotDetectedError")
    }
    expect(manager.getVCSType()).toBeNull()
    expect(manager.getVCSContext()).toBeNull()

    await fs.rm(tempDir, { recursive: true, force: true })
  })
})

describe("WorktreeManager path traversal protection", () => {
  let testDir: string
  let repoDir: string
  let manager: WorktreeManager
  let gitAvailable: boolean

  beforeAll(async () => {
    gitAvailable = await isGitAvailable()
    if (!gitAvailable) {
      console.log("Skipping path traversal tests - git not available")
      return
    }

    testDir = await fs.mkdtemp(path.join(os.tmpdir(), "worktree-security-test-"))
    repoDir = path.join(testDir, "repo")

    await fs.mkdir(repoDir, { recursive: true })
    await $`git -C ${repoDir} init`.quiet()
    await $`git -C ${repoDir} config user.email "test@test.com"`.quiet()
    await $`git -C ${repoDir} config user.name "Test"`.quiet()
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

  test("rejects path traversal in projectId", async () => {
    if (!gitAvailable) return

    const result = await manager.createIsolatedWorktree({
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

    const result = await manager.createIsolatedWorktree({
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

    const result = await manager.createIsolatedWorktree({
      projectId: "valid-project",
      issueId: "issue/subissue",
    })

    expect(result.ok).toBe(false)
    if (!result.ok) {
      expect(result.error.name).toBe("WorktreeError")
    }
  })

  test("rejects backslashes in projectId", async () => {
    if (!gitAvailable) return

    const result = await manager.createIsolatedWorktree({
      projectId: "project\\subdir",
      issueId: "issue-1",
    })

    expect(result.ok).toBe(false)
    if (!result.ok) {
      expect(result.error.name).toBe("WorktreeError")
    }
  })

  test("getWorktree rejects path traversal in projectId", async () => {
    if (!gitAvailable) return

    const result = await manager.getWorktree("../../../etc", "passwd")

    expect(result.ok).toBe(false)
    if (!result.ok) {
      expect(result.error.name).toBe("WorktreeError")
    }
  })

  test("getWorktree rejects path traversal in issueId", async () => {
    if (!gitAvailable) return

    const result = await manager.getWorktree("valid-project", "../../../etc/passwd")

    expect(result.ok).toBe(false)
    if (!result.ok) {
      expect(result.error.name).toBe("WorktreeError")
    }
  })

  test("accepts valid hierarchical issue IDs with dots", async () => {
    if (!gitAvailable) return

    const result = await manager.createIsolatedWorktree({
      projectId: "test-project",
      issueId: "bd-a3f8.1.2",
    })

    expect(result.ok).toBe(true)
    if (result.ok) {
      expect(result.value.name).toBe("test-project/bd-a3f8.1.2")
      await manager.removeWorktree(result.value.name)
    }
  })
})
