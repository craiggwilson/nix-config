/**
 * Tests for VCS Adapters
 *
 * These tests verify the VCS adapter implementations work correctly.
 * They require git and jj to be installed and will skip if not available.
 */

import { describe, test, expect, beforeAll, afterAll } from "bun:test"
import * as fs from "node:fs/promises"
import * as path from "node:path"
import * as os from "node:os"
import { $ } from "bun"

import { GitAdapter } from "./git-adapter.js"
import { JujutsuAdapter } from "./jujutsu-adapter.js"
import type { VCSAdapter } from "./vcs-adapter.js"
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

// Check if jj is available
async function isJjAvailable(): Promise<boolean> {
  try {
    const result = await $`jj --version`.nothrow().quiet()
    return result.exitCode === 0
  } catch {
    return false
  }
}

describe("GitAdapter", () => {
  let testDir: string
  let repoDir: string
  let adapter: GitAdapter
  let gitAvailable: boolean

  beforeAll(async () => {
    gitAvailable = await isGitAvailable()
    if (!gitAvailable) {
      console.log("Skipping GitAdapter tests - git not available")
      return
    }

    // Create a temporary directory
    testDir = await fs.mkdtemp(path.join(os.tmpdir(), "git-adapter-test-"))
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

    adapter = new GitAdapter(repoDir, testShell, mockLogger)
  })

  afterAll(async () => {
    if (testDir) {
      await fs.rm(testDir, { recursive: true, force: true })
    }
  })

  test("type is git", () => {
    if (!gitAvailable) return
    expect(adapter.type).toBe("git")
  })

  test("getCurrentBranch returns branch name", async () => {
    if (!gitAvailable) return
    const branch = await adapter.getCurrentBranch()
    expect(["main", "master"]).toContain(branch)
  })

  test("getDefaultBranch returns main or master", async () => {
    if (!gitAvailable) return
    const branch = await adapter.getDefaultBranch()
    expect(["main", "master"]).toContain(branch)
  })

  test("hasUncommittedChanges returns false for clean repo", async () => {
    if (!gitAvailable) return
    const hasChanges = await adapter.hasUncommittedChanges()
    expect(hasChanges).toBe(false)
  })

  test("hasUncommittedChanges returns true after modification", async () => {
    if (!gitAvailable) return
    await fs.writeFile(path.join(repoDir, "new-file.txt"), "content")
    const hasChanges = await adapter.hasUncommittedChanges()
    expect(hasChanges).toBe(true)

    // Clean up
    await fs.rm(path.join(repoDir, "new-file.txt"))
  })

  test("createWorktree creates a new worktree", async () => {
    if (!gitAvailable) return

    const info = await adapter.createWorktree("test-worktree")

    expect(info.name).toBe("test-worktree")
    expect(info.branch).toBe("test-worktree")
    expect(info.isMain).toBe(false)

    // Verify directory exists
    const stat = await fs.stat(info.path)
    expect(stat.isDirectory()).toBe(true)

    // Clean up
    await adapter.removeWorktree("test-worktree")
  })

  test("listWorktrees includes main and created worktrees", async () => {
    if (!gitAvailable) return

    await adapter.createWorktree("list-test")

    const worktrees = await adapter.listWorktrees()

    expect(worktrees.length).toBeGreaterThanOrEqual(2)
    expect(worktrees.some((w) => w.isMain)).toBe(true)
    expect(worktrees.some((w) => w.name === "list-test")).toBe(true)

    // Clean up
    await adapter.removeWorktree("list-test")
  })

  test("removeWorktree removes the worktree", async () => {
    if (!gitAvailable) return

    const info = await adapter.createWorktree("remove-test")
    const removed = await adapter.removeWorktree("remove-test")

    expect(removed).toBe(true)

    // Verify directory is gone
    try {
      await fs.stat(info.path)
      expect(true).toBe(false) // Should not reach here
    } catch (e) {
      expect((e as NodeJS.ErrnoException).code).toBe("ENOENT")
    }
  })
})

describe("JujutsuAdapter", () => {
  let testDir: string
  let repoDir: string
  let adapter: JujutsuAdapter
  let jjAvailable: boolean

  beforeAll(async () => {
    jjAvailable = await isJjAvailable()
    if (!jjAvailable) {
      console.log("Skipping JujutsuAdapter tests - jj not available")
      return
    }

    // Create a temporary directory
    testDir = await fs.mkdtemp(path.join(os.tmpdir(), "jj-adapter-test-"))
    repoDir = path.join(testDir, "repo")

    // Initialize a jj repo (jj git init creates the repo at the path)
    await $`jj git init ${repoDir}`.quiet()

    // Create initial content
    await fs.writeFile(path.join(repoDir, "README.md"), "# Test Repo")
    await $`jj -R ${repoDir} commit -m "Initial commit"`.quiet()

    adapter = new JujutsuAdapter(repoDir, testShell, mockLogger)
  })

  afterAll(async () => {
    if (testDir) {
      await fs.rm(testDir, { recursive: true, force: true })
    }
  })

  test("type is jj", () => {
    if (!jjAvailable) return
    expect(adapter.type).toBe("jj")
  })

  test("getCurrentBranch returns change id", async () => {
    if (!jjAvailable) return
    const changeId = await adapter.getCurrentBranch()
    expect(changeId.length).toBeGreaterThan(0)
  })

  test("hasUncommittedChanges works", async () => {
    if (!jjAvailable) return
    // jj always has a working copy change, so this may vary
    const hasChanges = await adapter.hasUncommittedChanges()
    expect(typeof hasChanges).toBe("boolean")
  })

  test("createWorktree creates a new workspace", async () => {
    if (!jjAvailable) return

    const info = await adapter.createWorktree("test-workspace")

    expect(info.name).toBe("test-workspace")
    expect(info.isMain).toBe(false)

    // Verify directory exists
    const stat = await fs.stat(info.path)
    expect(stat.isDirectory()).toBe(true)

    // Clean up
    await adapter.removeWorktree("test-workspace")
  })

  test("listWorktrees includes workspaces", async () => {
    if (!jjAvailable) return

    await adapter.createWorktree("list-test-ws")

    const workspaces = await adapter.listWorktrees()

    expect(workspaces.length).toBeGreaterThanOrEqual(1)

    // Clean up
    await adapter.removeWorktree("list-test-ws")
  })

  test("removeWorktree removes the workspace", async () => {
    if (!jjAvailable) return

    const info = await adapter.createWorktree("remove-test-ws")
    const removed = await adapter.removeWorktree("remove-test-ws")

    expect(removed).toBe(true)

    // Verify directory is gone
    try {
      await fs.stat(info.path)
      expect(true).toBe(false) // Should not reach here
    } catch (e) {
      expect((e as NodeJS.ErrnoException).code).toBe("ENOENT")
    }
  })
})
