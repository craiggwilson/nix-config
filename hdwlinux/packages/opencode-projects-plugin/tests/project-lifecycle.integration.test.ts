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
})
