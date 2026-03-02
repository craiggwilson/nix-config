/**
 * Integration tests for project lifecycle
 *
 * Tests the complete flow: create → issues → work → close
 *
 * CRITICAL: All tests use local storage in temporary directories to prevent
 * interference with actual projects.
 */

import { describe, test, expect, beforeEach, afterEach, afterAll } from "bun:test"

import {
  createIntegrationFixture,
  cleanupTestDirectories,
  type IntegrationTestFixture,
} from "./integration-test-utils.js"

describe("Project Lifecycle Integration", () => {
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

  describe("Complete project lifecycle", () => {
    test("create project → add issues → claim → close", async () => {
      // Step 1: Create a project
      const createResult = await fixture.projectManager.createProject({
        name: "Lifecycle Test Project",
        type: "project",
        description: "Testing the complete project lifecycle",
        storage: "local",
      })

      expect(createResult.projectId).toMatch(/^lifecycle-test-project-[a-f0-9]+$/)
      expect(createResult.metadata.status).toBe("active")
      expect(createResult.rootIssueId).toBeDefined()

      const projectId = createResult.projectId
      const projectDir = createResult.projectDir

      // Verify focus was set
      expect(fixture.focus.getProjectId()).toBe(projectId)

      // Step 2: Create child issues
      const issue1Result = await fixture.issueStorage.createIssue(projectDir, "Task 1: Setup", {
        parent: createResult.rootIssueId,
        priority: 1,
        labels: ["setup"],
      })
      expect(issue1Result.ok).toBe(true)
      const issue1Id = issue1Result.ok ? issue1Result.value : ""

      const issue2Result = await fixture.issueStorage.createIssue(projectDir, "Task 2: Implementation", {
        parent: createResult.rootIssueId,
        priority: 2,
        labels: ["implementation"],
        blockedBy: [issue1Id],
      })
      expect(issue2Result.ok).toBe(true)
      const issue2Id = issue2Result.ok ? issue2Result.value : ""

      const issue3Result = await fixture.issueStorage.createIssue(projectDir, "Task 3: Testing", {
        parent: createResult.rootIssueId,
        priority: 3,
        labels: ["testing"],
        blockedBy: [issue2Id],
      })
      expect(issue3Result.ok).toBe(true)

      // Step 3: Verify issue hierarchy
      const allIssues = await fixture.issueStorage.listIssues(projectDir)
      expect(allIssues.ok).toBe(true)
      if (allIssues.ok) {
        expect(allIssues.value.length).toBe(4) // Root + 3 tasks
      }

      // Step 4: Get ready issues (only Task 1 should be ready)
      const readyIssues = await fixture.issueStorage.getReadyIssues(projectDir)
      expect(readyIssues.ok).toBe(true)
      if (readyIssues.ok) {
        // Root issue and Task 1 should be ready (no blockers)
        const readyIds = readyIssues.value.map((i) => i.id)
        expect(readyIds).toContain(issue1Id)
        expect(readyIds).not.toContain(issue2Id) // Blocked by issue1
        expect(readyIds).not.toContain(issue3Result.ok ? issue3Result.value : "") // Blocked by issue2
      }

      // Step 5: Claim and complete Task 1
      const claimResult = await fixture.issueStorage.claimIssue(issue1Id, projectDir, "test-user")
      expect(claimResult.ok).toBe(true)

      const issue1 = await fixture.issueStorage.getIssue(issue1Id, projectDir)
      expect(issue1.ok).toBe(true)
      if (issue1.ok) {
        expect(issue1.value.status).toBe("in_progress")
        expect(issue1.value.assignee).toBe("test-user")
      }

      // Complete Task 1
      const closeResult = await fixture.issueStorage.updateStatus(issue1Id, "closed", projectDir)
      expect(closeResult.ok).toBe(true)

      // Step 6: Now Task 2 should be ready
      const readyAfterClose = await fixture.issueStorage.getReadyIssues(projectDir)
      expect(readyAfterClose.ok).toBe(true)
      if (readyAfterClose.ok) {
        const readyIds = readyAfterClose.value.map((i) => i.id)
        expect(readyIds).toContain(issue2Id) // Now unblocked
      }

      // Step 7: Get project status
      const status = await fixture.projectManager.getProjectStatus(projectId)
      expect(status).not.toBeNull()
      if (status) {
        expect(status.issueStatus?.total).toBe(4)
        expect(status.issueStatus?.completed).toBe(1)
      }

      // Step 8: Close the project
      const projectClosed = await fixture.projectManager.closeProject(projectId, {
        reason: "completed",
        summary: "All tasks completed successfully",
      })
      expect(projectClosed).toBe(true)

      // Verify project is closed
      const closedProject = await fixture.projectManager.getProject(projectId)
      expect(closedProject?.status).toBe("completed")
      expect(closedProject?.closeReason).toBe("completed")
      expect(closedProject?.closeSummary).toBe("All tasks completed successfully")

      // Verify focus was cleared
      expect(fixture.focus.getProjectId()).toBeNull()
    })

    test("project with multiple workspaces", async () => {
      // Create first project
      const project1 = await fixture.projectManager.createProject({
        name: "Project One",
        storage: "local",
      })

      // Create second project
      const project2 = await fixture.projectManager.createProject({
        name: "Project Two",
        storage: "local",
      })

      // Both projects should exist
      const projects = await fixture.projectManager.listProjects({ scope: "local" })
      expect(projects.length).toBe(2)

      // Focus should be on the last created project
      expect(fixture.focus.getProjectId()).toBe(project2.projectId)

      // Switch focus to first project
      fixture.focus.setFocus(project1.projectId)
      expect(fixture.focus.getProjectId()).toBe(project1.projectId)

      // Create issue in focused project
      const issueResult = await fixture.issueStorage.createIssue(
        project1.projectDir,
        "Issue in Project One"
      )
      expect(issueResult.ok).toBe(true)

      // Verify issue is in correct project
      const project1Issues = await fixture.issueStorage.listIssues(project1.projectDir)
      const project2Issues = await fixture.issueStorage.listIssues(project2.projectDir)

      expect(project1Issues.ok).toBe(true)
      expect(project2Issues.ok).toBe(true)

      if (project1Issues.ok && project2Issues.ok) {
        expect(project1Issues.value.length).toBe(2) // Root + new issue
        expect(project2Issues.value.length).toBe(1) // Just root
      }
    })

    test("project cancellation preserves data", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Cancelled Project",
        storage: "local",
      })

      // Add some issues
      await fixture.issueStorage.createIssue(project.projectDir, "Task 1", {
        parent: project.rootIssueId,
      })
      await fixture.issueStorage.createIssue(project.projectDir, "Task 2", {
        parent: project.rootIssueId,
      })

      // Cancel the project
      const cancelled = await fixture.projectManager.closeProject(project.projectId, {
        reason: "cancelled",
        summary: "Project cancelled due to priority change",
      })
      expect(cancelled).toBe(true)

      // Verify project is archived
      const cancelledProject = await fixture.projectManager.getProject(project.projectId)
      expect(cancelledProject?.status).toBe("archived")
      expect(cancelledProject?.closeReason).toBe("cancelled")

      // Issues should still be accessible
      const issues = await fixture.issueStorage.listIssues(project.projectDir)
      expect(issues.ok).toBe(true)
      if (issues.ok) {
        expect(issues.value.length).toBe(3) // Root + 2 tasks
      }
    })
  })

  describe("Issue dependency management", () => {
    test("complex dependency chain", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Dependency Test",
        storage: "local",
      })

      const projectDir = project.projectDir

      // Create a diamond dependency pattern:
      //     A
      //    / \
      //   B   C
      //    \ /
      //     D

      const aResult = await fixture.issueStorage.createIssue(projectDir, "Task A")
      const aId = aResult.ok ? aResult.value : ""

      const bResult = await fixture.issueStorage.createIssue(projectDir, "Task B", {
        blockedBy: [aId],
      })
      const bId = bResult.ok ? bResult.value : ""

      const cResult = await fixture.issueStorage.createIssue(projectDir, "Task C", {
        blockedBy: [aId],
      })
      const cId = cResult.ok ? cResult.value : ""

      const dResult = await fixture.issueStorage.createIssue(projectDir, "Task D", {
        blockedBy: [bId, cId],
      })
      const dId = dResult.ok ? dResult.value : ""

      // Initially only A should be ready
      let ready = await fixture.issueStorage.getReadyIssues(projectDir)
      expect(ready.ok).toBe(true)
      if (ready.ok) {
        const readyIds = ready.value.map((i) => i.id)
        expect(readyIds).toContain(aId)
        expect(readyIds).not.toContain(bId)
        expect(readyIds).not.toContain(cId)
        expect(readyIds).not.toContain(dId)
      }

      // Complete A
      await fixture.issueStorage.updateStatus(aId, "closed", projectDir)

      // Now B and C should be ready
      ready = await fixture.issueStorage.getReadyIssues(projectDir)
      if (ready.ok) {
        const readyIds = ready.value.map((i) => i.id)
        expect(readyIds).toContain(bId)
        expect(readyIds).toContain(cId)
        expect(readyIds).not.toContain(dId) // Still blocked by B and C
      }

      // Complete B only
      await fixture.issueStorage.updateStatus(bId, "closed", projectDir)

      // D should still be blocked (C not done)
      ready = await fixture.issueStorage.getReadyIssues(projectDir)
      if (ready.ok) {
        const readyIds = ready.value.map((i) => i.id)
        expect(readyIds).not.toContain(dId)
      }

      // Complete C
      await fixture.issueStorage.updateStatus(cId, "closed", projectDir)

      // Now D should be ready
      ready = await fixture.issueStorage.getReadyIssues(projectDir)
      if (ready.ok) {
        const readyIds = ready.value.map((i) => i.id)
        expect(readyIds).toContain(dId)
      }
    })

    test("adding dependency after creation", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Dynamic Deps",
        storage: "local",
      })

      const projectDir = project.projectDir

      // Create independent issues
      const issue1Result = await fixture.issueStorage.createIssue(projectDir, "Issue 1")
      const issue2Result = await fixture.issueStorage.createIssue(projectDir, "Issue 2")

      const issue1Id = issue1Result.ok ? issue1Result.value : ""
      const issue2Id = issue2Result.ok ? issue2Result.value : ""

      // Both should be ready initially
      let ready = await fixture.issueStorage.getReadyIssues(projectDir)
      if (ready.ok) {
        const readyIds = ready.value.map((i) => i.id)
        expect(readyIds).toContain(issue1Id)
        expect(readyIds).toContain(issue2Id)
      }

      // Add dependency: issue2 blocked by issue1
      const depResult = await fixture.issueStorage.addDependency(issue2Id, issue1Id, projectDir)
      expect(depResult.ok).toBe(true)

      // Now only issue1 should be ready
      ready = await fixture.issueStorage.getReadyIssues(projectDir)
      if (ready.ok) {
        const readyIds = ready.value.map((i) => i.id)
        expect(readyIds).toContain(issue1Id)
        expect(readyIds).not.toContain(issue2Id)
      }
    })
  })

  describe("Focus management", () => {
    test("focus tracks project and issue", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Focus Test",
        storage: "local",
      })

      // Set focus on project
      fixture.focus.setFocus(project.projectId)

      expect(fixture.focus.getProjectId()).toBe(project.projectId)
      expect(fixture.focus.isFocusedOn(project.projectId)).toBe(true)

      // Clear all focus
      fixture.focus.clear()
      expect(fixture.focus.getProjectId()).toBeNull()
    })
  })

  describe("Project status tracking", () => {
    test("status reflects issue progress", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Status Test",
        storage: "local",
      })

      const projectDir = project.projectDir

      // Create issues with various states
      const issue1Result = await fixture.issueStorage.createIssue(projectDir, "Open Issue")
      const issue2Result = await fixture.issueStorage.createIssue(projectDir, "In Progress Issue")
      const issue3Result = await fixture.issueStorage.createIssue(projectDir, "Closed Issue")
      const issue4Result = await fixture.issueStorage.createIssue(projectDir, "Blocked Issue", {
        blockedBy: [issue1Result.ok ? issue1Result.value : ""],
      })

      // Set statuses
      if (issue2Result.ok) {
        await fixture.issueStorage.claimIssue(issue2Result.value, projectDir)
      }
      if (issue3Result.ok) {
        await fixture.issueStorage.updateStatus(issue3Result.value, "closed", projectDir)
      }

      // Get project status
      const statusResult = await fixture.issueStorage.getProjectStatus(projectDir)
      expect(statusResult.ok).toBe(true)

      if (statusResult.ok) {
        const status = statusResult.value
        expect(status.total).toBe(5) // Root + 4 issues
        expect(status.completed).toBe(1)
        expect(status.inProgress).toBe(1)
        expect(status.blocked).toBe(1)
        expect(status.blockers.length).toBe(1)
        if (issue4Result.ok) {
          expect(status.blockers[0].issueId).toBe(issue4Result.value)
        }
      }
    })
  })

  describe("Project creation with storage options", () => {
    test("create project with local storage", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Local Storage Project",
        type: "project",
        storage: "local",
        description: "Testing local storage",
      })

      expect(project.metadata.storage).toBe("local")
      expect(project.projectDir).toContain(".projects")
      expect(project.projectDir).toContain(fixture.repoDir)

      // Verify directory structure was created
      const metadata = await fixture.projectManager.getProject(project.projectId)
      expect(metadata).not.toBeNull()
      expect(metadata?.storage).toBe("local")
    })

    test("create roadmap type project", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Roadmap Project",
        type: "roadmap",
        storage: "local",
        description: "Testing roadmap type",
      })

      expect(project.metadata.type).toBe("roadmap")
      expect(project.metadata.status).toBe("active")
    })

    test("create project type project", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Project Type",
        type: "project",
        storage: "local",
      })

      expect(project.metadata.type).toBe("project")
    })

    test("project ID is generated from name", async () => {
      const project = await fixture.projectManager.createProject({
        name: "My Test Project 123",
        storage: "local",
      })

      // ID should be slugified name + hash
      expect(project.projectId).toMatch(/^my-test-project-123-[a-f0-9]+$/)
    })

    test("project with special characters in name", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Test & Project! @#$%",
        storage: "local",
      })

      // Special characters should be stripped/replaced
      expect(project.projectId).toMatch(/^test-project-[a-f0-9]+$/)
    })
  })

  describe("Focus management operations", () => {
    test("set focus on project", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Focus Set Test",
        storage: "local",
      })

      // Creating a project auto-sets focus
      expect(fixture.focus.getProjectId()).toBe(project.projectId)

      // Create another project
      const project2 = await fixture.projectManager.createProject({
        name: "Focus Set Test 2",
        storage: "local",
      })

      // Focus should now be on project2
      expect(fixture.focus.getProjectId()).toBe(project2.projectId)

      // Manually set focus back to project1
      fixture.projectManager.setFocus(project.projectId)
      expect(fixture.focus.getProjectId()).toBe(project.projectId)
    })

    test("get focus when no project focused", async () => {
      // Initially no focus
      expect(fixture.focus.getProjectId()).toBeNull()
    })

    test("clear focus", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Focus Clear Test",
        storage: "local",
      })

      expect(fixture.focus.getProjectId()).toBe(project.projectId)

      fixture.projectManager.clearFocus()
      expect(fixture.focus.getProjectId()).toBeNull()
    })

    test("isFocusedOn returns correct value", async () => {
      const project1 = await fixture.projectManager.createProject({
        name: "Focus Check 1",
        storage: "local",
      })

      const project2 = await fixture.projectManager.createProject({
        name: "Focus Check 2",
        storage: "local",
      })

      // Focus is on project2 (last created)
      expect(fixture.focus.isFocusedOn(project2.projectId)).toBe(true)
      expect(fixture.focus.isFocusedOn(project1.projectId)).toBe(false)

      // Switch focus
      fixture.projectManager.setFocus(project1.projectId)
      expect(fixture.focus.isFocusedOn(project1.projectId)).toBe(true)
      expect(fixture.focus.isFocusedOn(project2.projectId)).toBe(false)
    })

    test("focus serialization and restoration", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Focus Serialize Test",
        storage: "local",
      })

      // Serialize current focus
      const serialized = fixture.focus.serialize()
      expect(serialized).not.toBeNull()

      // Clear and restore
      fixture.focus.clear()
      expect(fixture.focus.getProjectId()).toBeNull()

      const restored = fixture.focus.restore(serialized!)
      expect(restored).toBe(true)
      expect(fixture.focus.getProjectId()).toBe(project.projectId)
    })
  })

  describe("Project status formats", () => {
    test("getProjectStatus returns metadata and issue status", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Status Format Test",
        storage: "local",
        description: "Testing status formats",
      })

      // Add some issues
      await fixture.issueStorage.createIssue(project.projectDir, "Task 1", {
        parent: project.rootIssueId,
      })
      await fixture.issueStorage.createIssue(project.projectDir, "Task 2", {
        parent: project.rootIssueId,
      })

      const status = await fixture.projectManager.getProjectStatus(project.projectId)
      expect(status).not.toBeNull()

      if (status) {
        // Check metadata
        expect(status.metadata.id).toBe(project.projectId)
        expect(status.metadata.name).toBe("Status Format Test")
        expect(status.metadata.description).toBe("Testing status formats")
        expect(status.metadata.status).toBe("active")

        // Check issue status
        expect(status.issueStatus).not.toBeNull()
        if (status.issueStatus) {
          expect(status.issueStatus.total).toBe(3) // Root + 2 tasks
          expect(status.issueStatus.completed).toBe(0)
          expect(status.issueStatus.inProgress).toBe(0)
        }
      }
    })

    test("getProjectStatus returns null for non-existent project", async () => {
      const status = await fixture.projectManager.getProjectStatus("non-existent-project")
      expect(status).toBeNull()
    })

    test("listIssues returns all issues for tree view", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Tree View Test",
        storage: "local",
      })

      // Create hierarchical issues
      const epic1Result = await fixture.issueStorage.createIssue(project.projectDir, "Epic 1", {
        parent: project.rootIssueId,
        labels: ["epic"],
      })
      const epic1Id = epic1Result.ok ? epic1Result.value : ""

      await fixture.issueStorage.createIssue(project.projectDir, "Task 1.1", {
        parent: epic1Id,
      })
      await fixture.issueStorage.createIssue(project.projectDir, "Task 1.2", {
        parent: epic1Id,
      })

      const issues = await fixture.projectManager.listIssues(project.projectId)
      expect(issues.length).toBe(4) // Root + Epic + 2 tasks
    })

    test("getReadyIssues returns unblocked issues", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Ready Issues Test",
        storage: "local",
      })

      const task1Result = await fixture.issueStorage.createIssue(project.projectDir, "Task 1")
      const task1Id = task1Result.ok ? task1Result.value : ""

      await fixture.issueStorage.createIssue(project.projectDir, "Task 2", {
        blockedBy: [task1Id],
      })

      const readyIssues = await fixture.projectManager.getReadyIssues(project.projectId)
      
      // Root and Task 1 should be ready, Task 2 is blocked
      const readyIds = readyIssues.map((i) => i.id)
      expect(readyIds).toContain(task1Id)
      if (project.rootIssueId) {
        expect(readyIds).toContain(project.rootIssueId)
      }
    })
  })

  describe("Project list with filters", () => {
    test("list all local projects", async () => {
      await fixture.projectManager.createProject({
        name: "List Test 1",
        storage: "local",
      })
      await fixture.projectManager.createProject({
        name: "List Test 2",
        storage: "local",
      })

      // Use scope: "local" to avoid picking up global projects from other tests
      const projects = await fixture.projectManager.listProjects({ scope: "local" })
      expect(projects.length).toBe(2)
    })

    test("list projects with scope filter - local", async () => {
      await fixture.projectManager.createProject({
        name: "Local Project",
        storage: "local",
      })

      const localProjects = await fixture.projectManager.listProjects({ scope: "local" })
      expect(localProjects.length).toBe(1)
      expect(localProjects[0].storage).toBe("local")
    })

    test("list projects with status filter - active", async () => {
      const project1 = await fixture.projectManager.createProject({
        name: "Active Project",
        storage: "local",
      })
      const project2 = await fixture.projectManager.createProject({
        name: "Completed Project",
        storage: "local",
      })

      // Close project2
      await fixture.projectManager.closeProject(project2.projectId, { reason: "completed" })

      // Use scope: "local" to avoid picking up global projects
      const activeProjects = await fixture.projectManager.listProjects({ scope: "local", status: "active" })
      expect(activeProjects.length).toBe(1)
      expect(activeProjects[0].id).toBe(project1.projectId)
    })

    test("list projects with status filter - completed", async () => {
      const project1 = await fixture.projectManager.createProject({
        name: "Active Project 2",
        storage: "local",
      })
      const project2 = await fixture.projectManager.createProject({
        name: "Completed Project 2",
        storage: "local",
      })

      await fixture.projectManager.closeProject(project2.projectId, { reason: "completed" })

      // Use scope: "local" to avoid picking up global projects
      const completedProjects = await fixture.projectManager.listProjects({ scope: "local", status: "completed" })
      expect(completedProjects.length).toBe(1)
      expect(completedProjects[0].id).toBe(project2.projectId)
    })

    test("list projects with combined filters", async () => {
      await fixture.projectManager.createProject({
        name: "Combined Filter Test",
        storage: "local",
      })

      const projects = await fixture.projectManager.listProjects({
        scope: "local",
        status: "active",
      })
      expect(projects.length).toBe(1)
    })

    test("list returns empty array when no local projects match", async () => {
      // Use scope: "local" to only check local projects in this test directory
      const projects = await fixture.projectManager.listProjects({ scope: "local", status: "completed" })
      expect(projects.length).toBe(0)
    })
  })

  describe("Project close with all reasons", () => {
    test("close project with reason: completed", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Complete Test",
        storage: "local",
      })

      const closed = await fixture.projectManager.closeProject(project.projectId, {
        reason: "completed",
        summary: "All work finished successfully",
      })

      expect(closed).toBe(true)

      const closedProject = await fixture.projectManager.getProject(project.projectId)
      expect(closedProject?.status).toBe("completed")
      expect(closedProject?.closeReason).toBe("completed")
      expect(closedProject?.closeSummary).toBe("All work finished successfully")
      expect(closedProject?.closedAt).toBeDefined()
    })

    test("close project with reason: cancelled", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Cancel Test",
        storage: "local",
      })

      const closed = await fixture.projectManager.closeProject(project.projectId, {
        reason: "cancelled",
        summary: "Project cancelled due to priority change",
      })

      expect(closed).toBe(true)

      const closedProject = await fixture.projectManager.getProject(project.projectId)
      // Cancelled projects are marked as archived
      expect(closedProject?.status).toBe("archived")
      expect(closedProject?.closeReason).toBe("cancelled")
      expect(closedProject?.closeSummary).toBe("Project cancelled due to priority change")
    })

    test("close project with reason: archived", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Archive Test",
        storage: "local",
      })

      const closed = await fixture.projectManager.closeProject(project.projectId, {
        reason: "archived",
        summary: "Archived for future reference",
      })

      expect(closed).toBe(true)

      const closedProject = await fixture.projectManager.getProject(project.projectId)
      expect(closedProject?.status).toBe("archived")
      expect(closedProject?.closeReason).toBe("archived")
    })

    test("close project without summary", async () => {
      const project = await fixture.projectManager.createProject({
        name: "No Summary Test",
        storage: "local",
      })

      const closed = await fixture.projectManager.closeProject(project.projectId, {
        reason: "completed",
      })

      expect(closed).toBe(true)

      const closedProject = await fixture.projectManager.getProject(project.projectId)
      expect(closedProject?.closeSummary).toBeUndefined()
    })

    test("close project with default reason", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Default Reason Test",
        storage: "local",
      })

      const closed = await fixture.projectManager.closeProject(project.projectId, {})

      expect(closed).toBe(true)

      const closedProject = await fixture.projectManager.getProject(project.projectId)
      expect(closedProject?.closeReason).toBe("completed")
    })

    test("close non-existent project returns false", async () => {
      const closed = await fixture.projectManager.closeProject("non-existent-project", {
        reason: "completed",
      })

      expect(closed).toBe(false)
    })

    test("closing focused project clears focus", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Focus Clear on Close",
        storage: "local",
      })

      expect(fixture.focus.getProjectId()).toBe(project.projectId)

      await fixture.projectManager.closeProject(project.projectId, { reason: "completed" })

      expect(fixture.focus.getProjectId()).toBeNull()
    })

    test("closing non-focused project does not affect focus", async () => {
      const project1 = await fixture.projectManager.createProject({
        name: "Project 1",
        storage: "local",
      })
      const project2 = await fixture.projectManager.createProject({
        name: "Project 2",
        storage: "local",
      })

      // Focus is on project2
      expect(fixture.focus.getProjectId()).toBe(project2.projectId)

      // Close project1
      await fixture.projectManager.closeProject(project1.projectId, { reason: "completed" })

      // Focus should still be on project2
      expect(fixture.focus.getProjectId()).toBe(project2.projectId)
    })
  })

  describe("Directory structure verification", () => {
    test("project directory contains project.json", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Dir Structure Test",
        storage: "local",
      })

      const fs = await import("node:fs/promises")
      const path = await import("node:path")

      const metadataPath = path.join(project.projectDir, "project.json")
      const content = await fs.readFile(metadataPath, "utf8")
      const metadata = JSON.parse(content)

      expect(metadata.id).toBe(project.projectId)
      expect(metadata.name).toBe("Dir Structure Test")
      expect(metadata.status).toBe("active")
    })

    test("project directory is created in correct location for local storage", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Local Dir Test",
        storage: "local",
      })

      expect(project.projectDir).toContain(fixture.repoDir)
      expect(project.projectDir).toContain(".projects")
      expect(project.projectDir).toContain(project.projectId)
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
      const dir = await fixture.projectManager.getProjectDir("non-existent")
      expect(dir).toBeNull()
    })
  })

  describe("Metadata accuracy", () => {
    test("project metadata contains all required fields", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Metadata Test",
        type: "roadmap",
        storage: "local",
        description: "Testing metadata accuracy",
      })

      const metadata = await fixture.projectManager.getProject(project.projectId)
      expect(metadata).not.toBeNull()

      if (metadata) {
        expect(metadata.id).toBe(project.projectId)
        expect(metadata.name).toBe("Metadata Test")
        expect(metadata.type).toBe("roadmap")
        expect(metadata.storage).toBe("local")
        expect(metadata.description).toBe("Testing metadata accuracy")
        expect(metadata.status).toBe("active")
        expect(metadata.createdAt).toBeDefined()
        expect(metadata.workspace).toBe(fixture.repoDir)
        expect(metadata.rootIssue).toBeDefined()
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
      }
    })

    test("getProject returns null for non-existent project", async () => {
      const metadata = await fixture.projectManager.getProject("non-existent")
      expect(metadata).toBeNull()
    })
  })

  describe("Cleanup verification", () => {
    test("closed projects are still accessible", async () => {
      const project = await fixture.projectManager.createProject({
        name: "Cleanup Test",
        storage: "local",
      })

      await fixture.projectManager.closeProject(project.projectId, { reason: "completed" })

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

      await fixture.projectManager.closeProject(project.projectId, { reason: "archived" })

      // Verify data persists
      const issues = await fixture.projectManager.listIssues(project.projectId)
      expect(issues.length).toBe(3) // Root + 2 tasks
    })
  })
})
