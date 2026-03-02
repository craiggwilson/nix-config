/**
 * E2E tests for project lifecycle
 *
 * Tests the complete project lifecycle with actual file system operations:
 * - project-create with local and global storage
 * - project-focus (set, get, clear)
 * - project-status in all formats (summary, detailed, tree)
 * - project-list with scope and status filters
 * - project-close with all reasons (completed, cancelled, archived)
 *
 * Verifies directory structures are created correctly, metadata is accurate,
 * and cleanup works.
 */

import { describe, test, expect, beforeEach, afterEach, afterAll } from "bun:test"
import * as fs from "node:fs/promises"
import * as path from "node:path"
import * as os from "node:os"

import {
  createIntegrationFixture,
  cleanupTestDirectories,
  type IntegrationTestFixture,
} from "./integration-test-utils.js"
import { ConfigManager } from "../src/config/index.js"
import { FocusManager, ProjectManager } from "../src/projects/index.js"
import { InMemoryIssueStorage } from "../src/issues/inmemory/index.js"
import { createSilentLogger } from "./integration-test-utils.js"

describe("Project Lifecycle E2E", () => {
  let fixture: IntegrationTestFixture

  beforeEach(async () => {
    fixture = await createIntegrationFixture()
  })

  afterEach(async () => {
    await fixture.cleanup()
  })

  afterAll(async () => {
    await cleanupTestDirectories("opencode-e2e-test-")
  })

  describe("Storage: Local vs Global", () => {
    test("local storage creates project in repo .projects directory", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Local Storage E2E Test",
        type: "project",
        storage: "local",
        description: "Testing local storage path",
      })

      // Verify project directory is under repo/.projects/
      expect(project.projectDir).toContain(fixture.repoDir)
      expect(project.projectDir).toContain(".projects")
      expect(project.projectDir).toContain(project.projectId)

      // Verify directory exists
      const stat = await fs.stat(project.projectDir)
      expect(stat.isDirectory()).toBe(true)

      // Verify project.json exists and has correct content
      const metadataPath = path.join(project.projectDir, "project.json")
      const metadataContent = await fs.readFile(metadataPath, "utf8")
      const metadata = JSON.parse(metadataContent)

      expect(metadata.id).toBe(project.projectId)
      expect(metadata.name).toBe("Local Storage E2E Test")
      expect(metadata.storage).toBe("local")
      expect(metadata.type).toBe("project")
      expect(metadata.status).toBe("active")
      expect(metadata.workspace).toBe(fixture.repoDir)
    })

    test("global storage creates project in XDG data directory", async () => {
      // Create a separate fixture with a custom global projects dir
      const testDir = await fs.mkdtemp(path.join(os.tmpdir(), "opencode-e2e-global-"))
      const repoDir = path.join(testDir, "repo")
      await fs.mkdir(repoDir, { recursive: true })

      const logger = createSilentLogger()
      const config = await ConfigManager.loadOrThrow()
      const focus = new FocusManager()
      const issueStorage = new InMemoryIssueStorage({ prefix: "e2e" })

      const projectManager = new ProjectManager(
        config,
        issueStorage,
        focus,
        logger,
        repoDir
      )

      const project = await projectManager.createProject({
        name: "Global Storage E2E Test",
        type: "project",
        storage: "global",
        description: "Testing global storage path",
      })

      // Verify project directory is in global location
      const globalDir = config.getGlobalProjectsDir()
      expect(project.projectDir).toContain(globalDir)
      expect(project.projectDir).toContain(project.projectId)

      // Verify directory exists
      const stat = await fs.stat(project.projectDir)
      expect(stat.isDirectory()).toBe(true)

      // Verify metadata
      const metadataPath = path.join(project.projectDir, "project.json")
      const metadataContent = await fs.readFile(metadataPath, "utf8")
      const metadata = JSON.parse(metadataContent)

      expect(metadata.storage).toBe("global")

      // Cleanup
      await fs.rm(testDir, { recursive: true, force: true })
      await fs.rm(project.projectDir, { recursive: true, force: true })
    })

    test("local and global projects are listed separately", async () => {
      // Create local project
      const localProject = await fixture.projectManager.createProject({
        name: "Local List Test",
        storage: "local",
      })

      // List local only
      const localProjects = await fixture.projectManager.listProjects({ scope: "local" })
      expect(localProjects.some((p) => p.id === localProject.projectId)).toBe(true)
      expect(localProjects.every((p) => p.storage === "local")).toBe(true)
    })
  })

  describe("Focus Management: Set, Get, Clear", () => {
    test("setFocus sets the current project", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Focus Set Test",
        storage: "local",
      })

      // Creating a project auto-sets focus
      expect(fixture.focus.getProjectId()).toBe(project.projectId)
      expect(fixture.focus.isFocusedOn(project.projectId)).toBe(true)
    })

    test("getFocusedProjectId returns current focus", async () => {
      // Initially no focus
      fixture.focus.clear()
      expect(fixture.projectManager.getFocusedProjectId()).toBeNull()

      const project = await fixture.projectManager.createProject({
        name: "Focus Get Test",
        storage: "local",
      })

      expect(fixture.projectManager.getFocusedProjectId()).toBe(project.projectId)
    })

    test("clearFocus removes current focus", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Focus Clear Test",
        storage: "local",
      })

      expect(fixture.focus.getProjectId()).toBe(project.projectId)

      fixture.projectManager.clearFocus()
      expect(fixture.focus.getProjectId()).toBeNull()
      expect(fixture.projectManager.getFocusedProjectId()).toBeNull()
    })

    test("switching focus between projects", async () => {
      const project1 = await fixture.projectManager.createProject({
        name: "Focus Switch 1",
        storage: "local",
      })

      const project2 = await fixture.projectManager.createProject({
        name: "Focus Switch 2",
        storage: "local",
      })

      // Focus should be on project2 (last created)
      expect(fixture.focus.getProjectId()).toBe(project2.projectId)

      // Switch to project1
      fixture.projectManager.setFocus(project1.projectId)
      expect(fixture.focus.getProjectId()).toBe(project1.projectId)
      expect(fixture.focus.isFocusedOn(project1.projectId)).toBe(true)
      expect(fixture.focus.isFocusedOn(project2.projectId)).toBe(false)

      // Switch back to project2
      fixture.projectManager.setFocus(project2.projectId)
      expect(fixture.focus.getProjectId()).toBe(project2.projectId)
    })

    test("focus serialization and restoration", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Focus Serialize Test",
        storage: "local",
      })

      // Serialize
      const serialized = fixture.focus.serialize()
      expect(serialized).not.toBeNull()
      expect(serialized).toContain(project.projectId)

      // Clear and verify
      fixture.focus.clear()
      expect(fixture.focus.getProjectId()).toBeNull()

      // Restore
      const restored = fixture.focus.restore(serialized!)
      expect(restored).toBe(true)
      expect(fixture.focus.getProjectId()).toBe(project.projectId)
    })

    test("restore with invalid data returns false", () => {
      expect(fixture.focus.restore("invalid json")).toBe(false)
      expect(fixture.focus.restore("{}")).toBe(false)
      expect(fixture.focus.restore('{"foo": "bar"}')).toBe(false)
    })
  })

  describe("Project Status: All Formats", () => {
    test("getProjectStatus returns metadata and issue status", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Status Test",
        type: "roadmap",
        storage: "local",
        description: "Testing status retrieval",
      })

      // Add some issues
      await fixture.issueStorage.createIssue(project.projectDir, "Task 1", {
        parent: project.rootIssueId,
        priority: 1,
      })
      await fixture.issueStorage.createIssue(project.projectDir, "Task 2", {
        parent: project.rootIssueId,
        priority: 2,
      })

      const status = await fixture.projectManager.getProjectStatus(project.projectId)
      expect(status).not.toBeNull()

      if (status) {
        // Metadata checks
        expect(status.metadata.id).toBe(project.projectId)
        expect(status.metadata.name).toBe("Status Test")
        expect(status.metadata.type).toBe("roadmap")
        expect(status.metadata.description).toBe("Testing status retrieval")
        expect(status.metadata.status).toBe("active")

        // Issue status checks
        expect(status.issueStatus).not.toBeNull()
        if (status.issueStatus) {
          expect(status.issueStatus.total).toBe(3) // Root + 2 tasks
          expect(status.issueStatus.completed).toBe(0)
          expect(status.issueStatus.inProgress).toBe(0)
        }
      }
    })

    test("status reflects issue progress correctly", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Progress Test",
        storage: "local",
      })

      // Create issues with different states
      const task1Result = await fixture.issueStorage.createIssue(project.projectDir, "Open Task")
      const task2Result = await fixture.issueStorage.createIssue(project.projectDir, "In Progress Task")
      const task3Result = await fixture.issueStorage.createIssue(project.projectDir, "Closed Task")
      const task4Result = await fixture.issueStorage.createIssue(project.projectDir, "Blocked Task", {
        blockedBy: [task1Result.ok ? task1Result.value : ""],
      })

      // Set statuses
      if (task2Result.ok) {
        await fixture.issueStorage.claimIssue(task2Result.value, project.projectDir, "test-user")
      }
      if (task3Result.ok) {
        await fixture.issueStorage.updateStatus(task3Result.value, "closed", project.projectDir)
      }

      const status = await fixture.projectManager.getProjectStatus(project.projectId)
      expect(status).not.toBeNull()

      if (status?.issueStatus) {
        expect(status.issueStatus.total).toBe(5) // Root + 4 tasks
        expect(status.issueStatus.completed).toBe(1)
        expect(status.issueStatus.inProgress).toBe(1)
        expect(status.issueStatus.blocked).toBe(1)
        expect(status.issueStatus.blockers.length).toBe(1)
      }
    })

    test("listIssues returns all issues for tree view", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Tree View Test",
        storage: "local",
      })

      // Create hierarchical issues
      const epicResult = await fixture.issueStorage.createIssue(project.projectDir, "Epic 1", {
        parent: project.rootIssueId,
        labels: ["epic"],
      })
      const epicId = epicResult.ok ? epicResult.value : ""

      await fixture.issueStorage.createIssue(project.projectDir, "Task 1.1", {
        parent: epicId,
      })
      await fixture.issueStorage.createIssue(project.projectDir, "Task 1.2", {
        parent: epicId,
      })

      const issues = await fixture.projectManager.listIssues(project.projectId)
      expect(issues.length).toBe(4) // Root + Epic + 2 tasks

      // Verify hierarchy
      const epic = issues.find((i) => i.title === "Epic 1")
      expect(epic).toBeDefined()
      expect(epic?.parent).toBe(project.rootIssueId)

      const task1 = issues.find((i) => i.title === "Task 1.1")
      expect(task1).toBeDefined()
      expect(task1?.parent).toBe(epicId)
    })

    test("getReadyIssues returns only unblocked issues", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Ready Issues Test",
        storage: "local",
      })

      const task1Result = await fixture.issueStorage.createIssue(project.projectDir, "Ready Task")
      const task1Id = task1Result.ok ? task1Result.value : ""

      const task2Result = await fixture.issueStorage.createIssue(project.projectDir, "Blocked Task", {
        blockedBy: [task1Id],
      })
      const task2Id = task2Result.ok ? task2Result.value : ""

      const readyIssues = await fixture.projectManager.getReadyIssues(project.projectId)
      const readyIds = readyIssues.map((i) => i.id)

      expect(readyIds).toContain(task1Id)
      expect(readyIds).not.toContain(task2Id)
      if (project.rootIssueId) {
        expect(readyIds).toContain(project.rootIssueId)
      }
    })

    test("status returns null for non-existent project", async () => {
      const status = await fixture.projectManager.getProjectStatus("non-existent-project-id")
      expect(status).toBeNull()
    })
  })

  describe("Project List: Scope and Status Filters", () => {
    test("list with scope=local returns only local projects", async () => {
      await fixture.projectManager.createProject({
        name: "Local Only Test",
        storage: "local",
      })

      const projects = await fixture.projectManager.listProjects({ scope: "local" })
      expect(projects.length).toBeGreaterThan(0)
      expect(projects.every((p) => p.storage === "local")).toBe(true)
    })

    test("list with status=active returns only active projects", async () => {
      const activeProject = await fixture.projectManager.createProject({
        name: "Active Project",
        storage: "local",
      })

      const completedProject = await fixture.projectManager.createProject({
        name: "Completed Project",
        storage: "local",
      })

      await fixture.projectManager.closeProject(completedProject.projectId, {
        reason: "completed",
      })

      const activeProjects = await fixture.projectManager.listProjects({
        scope: "local",
        status: "active",
      })

      expect(activeProjects.some((p) => p.id === activeProject.projectId)).toBe(true)
      expect(activeProjects.some((p) => p.id === completedProject.projectId)).toBe(false)
    })

    test("list with status=completed returns only completed projects", async () => {
      const activeProject = await fixture.projectManager.createProject({
        name: "Active Project 2",
        storage: "local",
      })

      const completedProject = await fixture.projectManager.createProject({
        name: "Completed Project 2",
        storage: "local",
      })

      await fixture.projectManager.closeProject(completedProject.projectId, {
        reason: "completed",
      })

      const completedProjects = await fixture.projectManager.listProjects({
        scope: "local",
        status: "completed",
      })

      expect(completedProjects.some((p) => p.id === completedProject.projectId)).toBe(true)
      expect(completedProjects.some((p) => p.id === activeProject.projectId)).toBe(false)
    })

    test("list with status=all returns all projects", async () => {
      const project1 = await fixture.projectManager.createProject({
        name: "All Status Test 1",
        storage: "local",
      })

      const project2 = await fixture.projectManager.createProject({
        name: "All Status Test 2",
        storage: "local",
      })

      await fixture.projectManager.closeProject(project2.projectId, {
        reason: "completed",
      })

      const allProjects = await fixture.projectManager.listProjects({
        scope: "local",
        status: "all",
      })

      expect(allProjects.some((p) => p.id === project1.projectId)).toBe(true)
      expect(allProjects.some((p) => p.id === project2.projectId)).toBe(true)
    })

    test("list with combined filters", async () => {
      await fixture.projectManager.createProject({
        name: "Combined Filter Test",
        storage: "local",
      })

      const projects = await fixture.projectManager.listProjects({
        scope: "local",
        status: "active",
      })

      expect(projects.length).toBeGreaterThan(0)
      expect(projects.every((p) => p.storage === "local")).toBe(true)
      expect(projects.every((p) => p.status === "active")).toBe(true)
    })

    test("list returns empty array when no projects match", async () => {
      const projects = await fixture.projectManager.listProjects({
        scope: "local",
        status: "completed",
      })

      // No completed projects in fresh fixture
      expect(projects.length).toBe(0)
    })
  })

  describe("Project Close: All Reasons", () => {
    test("close with reason=completed sets status to completed", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Complete Close Test",
        storage: "local",
      })

      const closed = await fixture.projectManager.closeProject(project.projectId, {
        reason: "completed",
        summary: "All work finished successfully",
      })

      expect(closed).toBe(true)

      const metadata = await fixture.projectManager.getProject(project.projectId)
      expect(metadata?.status).toBe("completed")
      expect(metadata?.closeReason).toBe("completed")
      expect(metadata?.closeSummary).toBe("All work finished successfully")
      expect(metadata?.closedAt).toBeDefined()

      // Verify file was updated
      const metadataPath = path.join(project.projectDir, "project.json")
      const fileContent = await fs.readFile(metadataPath, "utf8")
      const fileMetadata = JSON.parse(fileContent)
      expect(fileMetadata.status).toBe("completed")
      expect(fileMetadata.closeReason).toBe("completed")
    })

    test("close with reason=cancelled sets status to archived", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Cancel Close Test",
        storage: "local",
      })

      const closed = await fixture.projectManager.closeProject(project.projectId, {
        reason: "cancelled",
        summary: "Project cancelled due to priority change",
      })

      expect(closed).toBe(true)

      const metadata = await fixture.projectManager.getProject(project.projectId)
      expect(metadata?.status).toBe("archived")
      expect(metadata?.closeReason).toBe("cancelled")
      expect(metadata?.closeSummary).toBe("Project cancelled due to priority change")
    })

    test("close with reason=archived sets status to archived", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Archive Close Test",
        storage: "local",
      })

      const closed = await fixture.projectManager.closeProject(project.projectId, {
        reason: "archived",
        summary: "Archived for future reference",
      })

      expect(closed).toBe(true)

      const metadata = await fixture.projectManager.getProject(project.projectId)
      expect(metadata?.status).toBe("archived")
      expect(metadata?.closeReason).toBe("archived")
    })

    test("close without summary leaves closeSummary undefined", async () => {
      const project = await fixture.projectManager.createProject({
        name: "No Summary Close Test",
        storage: "local",
      })

      await fixture.projectManager.closeProject(project.projectId, {
        reason: "completed",
      })

      const metadata = await fixture.projectManager.getProject(project.projectId)
      expect(metadata?.closeSummary).toBeUndefined()
    })

    test("close with default reason uses completed", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Default Reason Close Test",
        storage: "local",
      })

      await fixture.projectManager.closeProject(project.projectId, {})

      const metadata = await fixture.projectManager.getProject(project.projectId)
      expect(metadata?.closeReason).toBe("completed")
    })

    test("close non-existent project returns false", async () => {
      const closed = await fixture.projectManager.closeProject("non-existent-project", {
        reason: "completed",
      })

      expect(closed).toBe(false)
    })

    test("closing focused project clears focus", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Focus Clear on Close Test",
        storage: "local",
      })

      expect(fixture.focus.getProjectId()).toBe(project.projectId)

      await fixture.projectManager.closeProject(project.projectId, {
        reason: "completed",
      })

      expect(fixture.focus.getProjectId()).toBeNull()
    })

    test("closing non-focused project does not affect focus", async () => {
      const project1 = await fixture.projectManager.createProject({
        name: "Non-Focus Close 1",
        storage: "local",
      })

      const project2 = await fixture.projectManager.createProject({
        name: "Non-Focus Close 2",
        storage: "local",
      })

      // Focus is on project2
      expect(fixture.focus.getProjectId()).toBe(project2.projectId)

      // Close project1
      await fixture.projectManager.closeProject(project1.projectId, {
        reason: "completed",
      })

      // Focus should still be on project2
      expect(fixture.focus.getProjectId()).toBe(project2.projectId)
    })
  })

  describe("Directory Structure Verification", () => {
    test("project directory contains project.json with all required fields", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Dir Structure Test",
        type: "roadmap",
        storage: "local",
        description: "Testing directory structure",
      })

      const metadataPath = path.join(project.projectDir, "project.json")
      const content = await fs.readFile(metadataPath, "utf8")
      const metadata = JSON.parse(content)

      // Required fields
      expect(metadata.id).toBe(project.projectId)
      expect(metadata.name).toBe("Dir Structure Test")
      expect(metadata.type).toBe("roadmap")
      expect(metadata.storage).toBe("local")
      expect(metadata.status).toBe("active")
      expect(metadata.createdAt).toBeDefined()
      expect(metadata.workspace).toBe(fixture.repoDir)
      expect(metadata.description).toBe("Testing directory structure")
      expect(metadata.rootIssue).toBeDefined()
    })

    test("project directory path follows expected pattern", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Path Pattern Test",
        storage: "local",
      })

      // Path should be: repoDir/.projects/projectId
      const expectedPath = path.join(fixture.repoDir, ".projects", project.projectId)
      expect(project.projectDir).toBe(expectedPath)
    })

    test("getProjectDir returns correct path", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Get Dir Test",
        storage: "local",
      })

      const dir = await fixture.projectManager.getProjectDir(project.projectId)
      expect(dir).toBe(project.projectDir)
    })

    test("getProjectDir returns null for non-existent project", async () => {
      const dir = await fixture.projectManager.getProjectDir("non-existent-project")
      expect(dir).toBeNull()
    })

    test("project ID is generated correctly from name", async () => {
      const project = await fixture.projectManager.createProject({
        name: "My Test Project 123",
        storage: "local",
      })

      // ID should be slugified name + 6-char hex hash
      expect(project.projectId).toMatch(/^my-test-project-123-[a-f0-9]{6}$/)
    })

    test("special characters in name are sanitized", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Test & Project! @#$%",
        storage: "local",
      })

      // Special characters should be stripped/replaced
      expect(project.projectId).toMatch(/^test-project-[a-f0-9]{6}$/)
    })

    test("long names are truncated", async () => {
      const longName = "A".repeat(100)
      const project = await fixture.projectManager.createProject({
        name: longName,
        storage: "local",
      })

      // Name should be truncated to 30 chars + hash
      expect(project.projectId.length).toBeLessThanOrEqual(37) // 30 + 1 + 6
    })
  })

  describe("Metadata Accuracy", () => {
    test("project metadata contains all fields after creation", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Metadata Accuracy Test",
        type: "roadmap",
        storage: "local",
        description: "Testing metadata accuracy",
      })

      const metadata = await fixture.projectManager.getProject(project.projectId)
      expect(metadata).not.toBeNull()

      if (metadata) {
        expect(metadata.id).toBe(project.projectId)
        expect(metadata.name).toBe("Metadata Accuracy Test")
        expect(metadata.type).toBe("roadmap")
        expect(metadata.storage).toBe("local")
        expect(metadata.description).toBe("Testing metadata accuracy")
        expect(metadata.status).toBe("active")
        expect(metadata.createdAt).toBeDefined()
        expect(metadata.workspace).toBe(fixture.repoDir)
        expect(metadata.rootIssue).toBeDefined()

        // Closed fields should not be set
        expect(metadata.closedAt).toBeUndefined()
        expect(metadata.closeReason).toBeUndefined()
        expect(metadata.closeSummary).toBeUndefined()
      }
    })

    test("closed project metadata contains close fields", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Close Metadata Test",
        storage: "local",
      })

      await fixture.projectManager.closeProject(project.projectId, {
        reason: "completed",
        summary: "Test summary",
      })

      const metadata = await fixture.projectManager.getProject(project.projectId)
      expect(metadata).not.toBeNull()

      if (metadata) {
        expect(metadata.closedAt).toBeDefined()
        expect(metadata.closeReason).toBe("completed")
        expect(metadata.closeSummary).toBe("Test summary")

        // Verify closedAt is a valid ISO date
        const closedDate = new Date(metadata.closedAt!)
        expect(closedDate.getTime()).not.toBeNaN()
      }
    })

    test("getProject returns null for non-existent project", async () => {
      const metadata = await fixture.projectManager.getProject("non-existent-project")
      expect(metadata).toBeNull()
    })
  })

  describe("Cleanup Verification", () => {
    test("closed projects are still accessible", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Cleanup Access Test",
        storage: "local",
      })

      // Add issues
      await fixture.issueStorage.createIssue(project.projectDir, "Task 1", {
        parent: project.rootIssueId,
      })

      await fixture.projectManager.closeProject(project.projectId, {
        reason: "completed",
      })

      // Project should still be accessible
      const metadata = await fixture.projectManager.getProject(project.projectId)
      expect(metadata).not.toBeNull()

      // Issues should still be accessible
      const issues = await fixture.projectManager.listIssues(project.projectId)
      expect(issues.length).toBeGreaterThan(0)
    })

    test("project data persists after close", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Persist Test",
        storage: "local",
      })

      // Add issues before closing
      await fixture.issueStorage.createIssue(project.projectDir, "Task 1", {
        parent: project.rootIssueId,
      })
      await fixture.issueStorage.createIssue(project.projectDir, "Task 2", {
        parent: project.rootIssueId,
      })

      await fixture.projectManager.closeProject(project.projectId, {
        reason: "archived",
      })

      // Verify data persists
      const issues = await fixture.projectManager.listIssues(project.projectId)
      expect(issues.length).toBe(3) // Root + 2 tasks

      // Verify directory still exists
      const stat = await fs.stat(project.projectDir)
      expect(stat.isDirectory()).toBe(true)
    })

    test("project directory is not deleted on close", async () => {
      const project = await fixture.projectManager.createProject({
        name: "No Delete Test",
        storage: "local",
      })

      await fixture.projectManager.closeProject(project.projectId, {
        reason: "cancelled",
      })

      // Directory should still exist
      const exists = await fs.access(project.projectDir).then(() => true).catch(() => false)
      expect(exists).toBe(true)

      // project.json should still exist
      const metadataPath = path.join(project.projectDir, "project.json")
      const metadataExists = await fs.access(metadataPath).then(() => true).catch(() => false)
      expect(metadataExists).toBe(true)
    })
  })

  describe("Complete Lifecycle Flow", () => {
    test("full lifecycle: create → focus → add issues → status → close", async () => {
      // Step 1: Create project
      const project = await fixture.projectManager.createProject({
        name: "Full Lifecycle Test",
        type: "project",
        storage: "local",
        description: "Testing complete lifecycle",
      })

      expect(project.projectId).toBeDefined()
      expect(project.metadata.status).toBe("active")

      // Step 2: Verify focus was set
      expect(fixture.focus.getProjectId()).toBe(project.projectId)

      // Step 3: Add issues
      const task1Result = await fixture.issueStorage.createIssue(project.projectDir, "Task 1", {
        parent: project.rootIssueId,
        priority: 1,
      })
      expect(task1Result.ok).toBe(true)
      const task1Id = task1Result.ok ? task1Result.value : ""

      const task2Result = await fixture.issueStorage.createIssue(project.projectDir, "Task 2", {
        parent: project.rootIssueId,
        priority: 2,
        blockedBy: [task1Id],
      })
      expect(task2Result.ok).toBe(true)

      // Step 4: Check status
      const status = await fixture.projectManager.getProjectStatus(project.projectId)
      expect(status).not.toBeNull()
      expect(status?.issueStatus?.total).toBe(3) // Root + 2 tasks

      // Step 5: Get ready issues
      const readyIssues = await fixture.projectManager.getReadyIssues(project.projectId)
      const readyIds = readyIssues.map((i) => i.id)
      expect(readyIds).toContain(task1Id)

      // Step 6: Claim and complete task 1
      await fixture.issueStorage.claimIssue(task1Id, project.projectDir, "test-user")
      await fixture.issueStorage.updateStatus(task1Id, "closed", project.projectDir)

      // Step 7: Verify task 2 is now ready
      const readyAfter = await fixture.projectManager.getReadyIssues(project.projectId)
      const readyAfterIds = readyAfter.map((i) => i.id)
      expect(readyAfterIds).toContain(task2Result.ok ? task2Result.value : "")

      // Step 8: Close project
      const closed = await fixture.projectManager.closeProject(project.projectId, {
        reason: "completed",
        summary: "All tasks completed",
      })
      expect(closed).toBe(true)

      // Step 9: Verify final state
      const finalMetadata = await fixture.projectManager.getProject(project.projectId)
      expect(finalMetadata?.status).toBe("completed")
      expect(finalMetadata?.closeReason).toBe("completed")
      expect(fixture.focus.getProjectId()).toBeNull()
    })
  })
})
