/**
 * Tests for ProjectManager
 */

import { describe, test, expect, beforeEach, afterAll } from "bun:test"
import * as fs from "node:fs/promises"
import * as path from "node:path"
import * as os from "node:os"

import { ProjectManager } from "./project-manager.js"
import { ConfigManager } from "./config-manager.js"
import { InMemoryIssueStorage } from "../storage/index.js"
import { FocusManager } from "./focus-manager.js"
import { createMockLogger } from "./test-utils.js"

describe("ProjectManager", () => {
  let testDir: string
  let manager: ProjectManager
  let config: ConfigManager
  let issueStorage: InMemoryIssueStorage
  let focus: FocusManager

  beforeEach(async () => {

    testDir = await fs.mkdtemp(path.join(os.tmpdir(), "project-manager-test-"))


    config = await ConfigManager.load()
    issueStorage = new InMemoryIssueStorage({ prefix: "test" })
    focus = new FocusManager()

    manager = new ProjectManager({
      config,
      issueStorage,
      focus,
      log: createMockLogger(),
      repoRoot: testDir,
    })
  })

  afterAll(async () => {

    try {
      const tmpDir = os.tmpdir()
      const entries = await fs.readdir(tmpDir)
      for (const entry of entries) {
        if (entry.startsWith("project-manager-test-")) {
          await fs.rm(path.join(tmpDir, entry), { recursive: true, force: true })
        }
      }
    } catch {

    }
  })

  describe("createProject", () => {
    test("creates project with directory structure", async () => {
      const result = await manager.createProject({
        name: "Test Project",
        type: "project",
        description: "A test project",
      })

      expect(result.projectId).toMatch(/^test-project-[a-f0-9]+$/)
      expect(result.metadata.name).toBe("Test Project")
      expect(result.metadata.type).toBe("project")
      expect(result.metadata.status).toBe("active")

  
      const projectDir = result.projectDir
      expect((await fs.stat(path.join(projectDir, "research"))).isDirectory()).toBe(true)
      expect((await fs.stat(path.join(projectDir, "interviews"))).isDirectory()).toBe(true)
      expect((await fs.stat(path.join(projectDir, "plans"))).isDirectory()).toBe(true)
    })

    test("creates root issue in storage", async () => {
      const result = await manager.createProject({
        name: "Issue Test",
        type: "roadmap",
      })

      expect(result.rootIssueId).not.toBeUndefined()


      const issue = await issueStorage.getIssue(result.rootIssueId!, result.projectDir)
      expect(issue).not.toBeNull()
      expect(issue?.title).toBe("Issue Test")
      expect(issue?.labels).toContain("epic")
      expect(issue?.labels).toContain("roadmap")
    })

    test("sets focus to new project", async () => {
      const result = await manager.createProject({ name: "Focus Test" })

      expect(manager.getFocusedProjectId()).toBe(result.projectId)
    })

    test("generates unique IDs for same name", async () => {
      const result1 = await manager.createProject({ name: "Duplicate" })
      const result2 = await manager.createProject({ name: "Duplicate" })

      expect(result1.projectId).not.toBe(result2.projectId)
    })
  })

  describe("listProjects", () => {
    test("lists created projects", async () => {
      await manager.createProject({ name: "Project 1" })
      await manager.createProject({ name: "Project 2" })

      const projects = await manager.listProjects({ scope: "local" })

      expect(projects.length).toBe(2)
      expect(projects.map((p) => p.name)).toContain("Project 1")
      expect(projects.map((p) => p.name)).toContain("Project 2")
    })

    test("filters by status", async () => {
      const result = await manager.createProject({ name: "Active Project" })
      await manager.createProject({ name: "Closed Project" })
      await manager.closeProject(result.projectId)

      const active = await manager.listProjects({ status: "active" })
      const completed = await manager.listProjects({ status: "completed" })

      expect(active.length).toBe(1)
      expect(active[0].name).toBe("Closed Project")
      expect(completed.length).toBe(1)
      expect(completed[0].name).toBe("Active Project")
    })
  })

  describe("getProject", () => {
    test("returns project metadata", async () => {
      const result = await manager.createProject({
        name: "Get Test",
        description: "Test description",
      })

      const project = await manager.getProject(result.projectId)

      expect(project).not.toBeNull()
      expect(project?.name).toBe("Get Test")
      expect(project?.description).toBe("Test description")
    })

    test("returns null for non-existent project", async () => {
      const project = await manager.getProject("non-existent")

      expect(project).toBeNull()
    })
  })

  describe("getProjectStatus", () => {
    test("returns project status with issue counts", async () => {
      const result = await manager.createProject({ name: "Status Test" })


      await manager.createIssue(result.projectId, "Open Issue")
      const claimedId = await manager.createIssue(result.projectId, "Claimed Issue")
      await manager.claimIssue(result.projectId, claimedId!)

      const status = await manager.getProjectStatus(result.projectId)

      expect(status).not.toBeNull()
      expect(status?.metadata.name).toBe("Status Test")
      expect(status?.issueStatus?.total).toBe(3) // Root + 2 created
      expect(status?.issueStatus?.inProgress).toBe(1)
    })
  })

  describe("closeProject", () => {
    test("closes project with reason", async () => {
      const result = await manager.createProject({ name: "Close Test" })

      const closed = await manager.closeProject(result.projectId, {
        reason: "completed",
        summary: "All done!",
      })

      expect(closed).toBe(true)

      const project = await manager.getProject(result.projectId)
      expect(project?.status).toBe("completed")
      expect(project?.closeReason).toBe("completed")
      expect(project?.closeSummary).toBe("All done!")
    })

    test("clears focus when closing focused project", async () => {
      const result = await manager.createProject({ name: "Focus Clear Test" })

      expect(manager.getFocusedProjectId()).toBe(result.projectId)

      await manager.closeProject(result.projectId)

      expect(manager.getFocusedProjectId()).toBeNull()
    })
  })

  describe("issue operations", () => {
    test("creates and retrieves issues", async () => {
      const result = await manager.createProject({ name: "Issue Ops Test" })

      const issueId = await manager.createIssue(result.projectId, "Test Issue", {
        priority: 1,
        description: "Test description",
      })

      expect(issueId).not.toBeNull()

      const issue = await manager.getIssue(result.projectId, issueId!)
      expect(issue?.title).toBe("Test Issue")
      expect(issue?.priority).toBe(1)
    })

    test("lists issues in project", async () => {
      const result = await manager.createProject({ name: "List Issues Test" })

      await manager.createIssue(result.projectId, "Issue 1")
      await manager.createIssue(result.projectId, "Issue 2")

      const issues = await manager.listIssues(result.projectId)

      expect(issues.length).toBe(3) // Root + 2 created
    })

    test("claims issue and sets focus", async () => {
      const result = await manager.createProject({ name: "Claim Test" })
      const issueId = await manager.createIssue(result.projectId, "Claimable")

      const claimed = await manager.claimIssue(result.projectId, issueId!)

      expect(claimed).toBe(true)
      expect(manager.getFocusedIssueId()).toBe(issueId)

      const issue = await manager.getIssue(result.projectId, issueId!)
      expect(issue?.status).toBe("in_progress")
    })

    test("gets ready issues", async () => {
      const result = await manager.createProject({ name: "Ready Test" })

      const blockerId = await manager.createIssue(result.projectId, "Blocker")
      const blockedId = await manager.createIssue(result.projectId, "Blocked")
      const readyId = await manager.createIssue(result.projectId, "Ready")


      const projectDir = await manager.getProjectDir(result.projectId)
      await issueStorage.addDependency(blockedId!, blockerId!, projectDir!)

      const ready = await manager.getReadyIssues(result.projectId)


      expect(ready.map((i) => i.id)).toContain(readyId!)
      expect(ready.map((i) => i.id)).toContain(blockerId!)
      expect(ready.map((i) => i.id)).not.toContain(blockedId!)
    })
  })

  describe("focus management", () => {
    test("setFocus and clearFocus work correctly", async () => {
      const result = await manager.createProject({ name: "Focus Mgmt Test" })
      const issueId = await manager.createIssue(result.projectId, "Focus Issue")

      manager.clearFocus()
      expect(manager.getFocusedProjectId()).toBeNull()

      manager.setFocus(result.projectId, issueId!)
      expect(manager.getFocusedProjectId()).toBe(result.projectId)
      expect(manager.getFocusedIssueId()).toBe(issueId)
    })
  })
})
