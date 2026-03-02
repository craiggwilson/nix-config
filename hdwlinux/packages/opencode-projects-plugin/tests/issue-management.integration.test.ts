/**
 * Integration tests for issue management
 *
 * Tests the full issue management workflow:
 * - Create epics, tasks, subtasks (3-level hierarchy)
 * - Set priorities (P0-P3) and verify ordering
 * - Create blocked-by dependencies and verify they're respected
 * - Update issue status (open → in_progress → closed)
 * - Add labels and verify filtering
 * - Add comments to issues
 * - Verify project-status tree format shows hierarchy correctly
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
import { renderIssueTree, buildIssueTree } from "../src/issues/index.js"

describe("Issue Management Integration", () => {
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

  describe("3-level hierarchy (epic → task → subtask)", () => {
    test("creates and retrieves 3-level issue hierarchy", async () => {
      // Arrange
      const project = await fixture.projectManager.createProject({
        name: "Hierarchy Test",
        type: "project",
        storage: "local",
      })
      const projectDir = project.projectDir

      // Act: Create epic (level 1)
      const epicResult = await fixture.issueStorage.createIssue(
        projectDir,
        "Epic: User Authentication",
        {
          priority: 0,
          labels: ["epic", "auth"],
          description: "Implement complete user authentication system",
        }
      )
      expect(epicResult.ok).toBe(true)
      const epicId = epicResult.ok ? epicResult.value : ""

      // Act: Create tasks under epic (level 2)
      const task1Result = await fixture.issueStorage.createIssue(
        projectDir,
        "Task: Login Flow",
        {
          parent: epicId,
          priority: 1,
          labels: ["task", "frontend"],
        }
      )
      expect(task1Result.ok).toBe(true)
      const task1Id = task1Result.ok ? task1Result.value : ""

      const task2Result = await fixture.issueStorage.createIssue(
        projectDir,
        "Task: Password Reset",
        {
          parent: epicId,
          priority: 2,
          labels: ["task", "backend"],
        }
      )
      expect(task2Result.ok).toBe(true)
      const task2Id = task2Result.ok ? task2Result.value : ""

      // Act: Create subtasks under task1 (level 3)
      const subtask1Result = await fixture.issueStorage.createIssue(
        projectDir,
        "Subtask: Design login form",
        {
          parent: task1Id,
          priority: 2,
          labels: ["subtask", "design"],
        }
      )
      expect(subtask1Result.ok).toBe(true)
      const subtask1Id = subtask1Result.ok ? subtask1Result.value : ""

      const subtask2Result = await fixture.issueStorage.createIssue(
        projectDir,
        "Subtask: Implement form validation",
        {
          parent: task1Id,
          priority: 3,
          labels: ["subtask", "frontend"],
        }
      )
      expect(subtask2Result.ok).toBe(true)
      const subtask2Id = subtask2Result.ok ? subtask2Result.value : ""

      // Assert: Verify hierarchical IDs
      expect(task1Id).toBe(`${epicId}.1`)
      expect(task2Id).toBe(`${epicId}.2`)
      expect(subtask1Id).toBe(`${task1Id}.1`)
      expect(subtask2Id).toBe(`${task1Id}.2`)

      // Assert: Verify parent relationships
      const epic = await fixture.issueStorage.getIssue(epicId, projectDir)
      const task1 = await fixture.issueStorage.getIssue(task1Id, projectDir)
      const subtask1 = await fixture.issueStorage.getIssue(subtask1Id, projectDir)

      expect(epic.ok).toBe(true)
      expect(task1.ok).toBe(true)
      expect(subtask1.ok).toBe(true)

      if (epic.ok) expect(epic.value.parent).toBeUndefined()
      if (task1.ok) expect(task1.value.parent).toBe(epicId)
      if (subtask1.ok) expect(subtask1.value.parent).toBe(task1Id)

      // Assert: Verify getChildren returns correct children
      const epicChildren = await fixture.issueStorage.getChildren(epicId, projectDir)
      expect(epicChildren.ok).toBe(true)
      if (epicChildren.ok) {
        expect(epicChildren.value.length).toBe(2)
        expect(epicChildren.value.map((i) => i.id)).toContain(task1Id)
        expect(epicChildren.value.map((i) => i.id)).toContain(task2Id)
      }

      const task1Children = await fixture.issueStorage.getChildren(task1Id, projectDir)
      expect(task1Children.ok).toBe(true)
      if (task1Children.ok) {
        expect(task1Children.value.length).toBe(2)
        expect(task1Children.value.map((i) => i.id)).toContain(subtask1Id)
        expect(task1Children.value.map((i) => i.id)).toContain(subtask2Id)
      }
    })

    test("getTree returns full hierarchy from root", async () => {
      // Arrange
      const project = await fixture.projectManager.createProject({
        name: "Tree Test",
        storage: "local",
      })
      const projectDir = project.projectDir

      // Create 3-level hierarchy
      const epicResult = await fixture.issueStorage.createIssue(projectDir, "Epic")
      const epicId = epicResult.ok ? epicResult.value : ""

      const taskResult = await fixture.issueStorage.createIssue(projectDir, "Task", {
        parent: epicId,
      })
      const taskId = taskResult.ok ? taskResult.value : ""

      await fixture.issueStorage.createIssue(projectDir, "Subtask", {
        parent: taskId,
      })

      // Act
      const treeResult = await fixture.issueStorage.getTree(projectDir, epicId)

      // Assert
      expect(treeResult.ok).toBe(true)
      if (treeResult.ok) {
        expect(treeResult.value.length).toBe(3) // Epic + Task + Subtask
        const ids = treeResult.value.map((i) => i.id)
        expect(ids).toContain(epicId)
        expect(ids).toContain(taskId)
      }
    })
  })

  describe("Priority management (P0-P3)", () => {
    test("creates issues with different priorities", async () => {
      // Arrange
      const project = await fixture.projectManager.createProject({
        name: "Priority Test",
        storage: "local",
      })
      const projectDir = project.projectDir

      // Act: Create issues with P0-P3 priorities
      const p0Result = await fixture.issueStorage.createIssue(projectDir, "Critical Bug", {
        priority: 0,
      })
      const p1Result = await fixture.issueStorage.createIssue(projectDir, "High Priority", {
        priority: 1,
      })
      const p2Result = await fixture.issueStorage.createIssue(projectDir, "Medium Priority", {
        priority: 2,
      })
      const p3Result = await fixture.issueStorage.createIssue(projectDir, "Low Priority", {
        priority: 3,
      })

      // Assert: All created successfully
      expect(p0Result.ok).toBe(true)
      expect(p1Result.ok).toBe(true)
      expect(p2Result.ok).toBe(true)
      expect(p3Result.ok).toBe(true)

      // Assert: Priorities are stored correctly
      const p0Issue = await fixture.issueStorage.getIssue(
        p0Result.ok ? p0Result.value : "",
        projectDir
      )
      const p1Issue = await fixture.issueStorage.getIssue(
        p1Result.ok ? p1Result.value : "",
        projectDir
      )
      const p2Issue = await fixture.issueStorage.getIssue(
        p2Result.ok ? p2Result.value : "",
        projectDir
      )
      const p3Issue = await fixture.issueStorage.getIssue(
        p3Result.ok ? p3Result.value : "",
        projectDir
      )

      expect(p0Issue.ok && p0Issue.value.priority).toBe(0)
      expect(p1Issue.ok && p1Issue.value.priority).toBe(1)
      expect(p2Issue.ok && p2Issue.value.priority).toBe(2)
      expect(p3Issue.ok && p3Issue.value.priority).toBe(3)
    })

    test("updates issue priority", async () => {
      // Arrange
      const project = await fixture.projectManager.createProject({
        name: "Priority Update Test",
        storage: "local",
      })
      const projectDir = project.projectDir

      const issueResult = await fixture.issueStorage.createIssue(projectDir, "Test Issue", {
        priority: 3,
      })
      const issueId = issueResult.ok ? issueResult.value : ""

      // Act: Update priority from P3 to P0
      const updateResult = await fixture.issueStorage.updateIssue(issueId, projectDir, {
        priority: 0,
      })

      // Assert
      expect(updateResult.ok).toBe(true)
      const updated = await fixture.issueStorage.getIssue(issueId, projectDir)
      expect(updated.ok).toBe(true)
      if (updated.ok) {
        expect(updated.value.priority).toBe(0)
      }
    })

    test("tree renderer shows priority badges", async () => {
      // Arrange
      const project = await fixture.projectManager.createProject({
        name: "Priority Badge Test",
        storage: "local",
      })
      const projectDir = project.projectDir

      await fixture.issueStorage.createIssue(projectDir, "P0 Issue", { priority: 0 })
      await fixture.issueStorage.createIssue(projectDir, "P1 Issue", { priority: 1 })
      await fixture.issueStorage.createIssue(projectDir, "No Priority Issue")

      // Act
      const listResult = await fixture.issueStorage.listIssues(projectDir)
      expect(listResult.ok).toBe(true)
      if (!listResult.ok) return

      const treeOutput = renderIssueTree(listResult.value)

      // Assert
      expect(treeOutput).toContain("[P0]")
      expect(treeOutput).toContain("[P1]")
      expect(treeOutput).toContain("No Priority Issue")
      // No priority badge for issue without priority
      const lines = treeOutput.split("\n")
      const noPriorityLine = lines.find((l) => l.includes("No Priority Issue"))
      expect(noPriorityLine).not.toContain("[P")
    })
  })

  describe("Blocked-by dependencies", () => {
    test("creates issues with blockedBy dependencies", async () => {
      // Arrange
      const project = await fixture.projectManager.createProject({
        name: "Dependency Test",
        storage: "local",
      })
      const projectDir = project.projectDir

      // Act: Create blocker and blocked issues
      const blockerResult = await fixture.issueStorage.createIssue(
        projectDir,
        "Setup Infrastructure"
      )
      const blockerId = blockerResult.ok ? blockerResult.value : ""

      const blockedResult = await fixture.issueStorage.createIssue(
        projectDir,
        "Deploy Application",
        {
          blockedBy: [blockerId],
        }
      )
      const blockedId = blockedResult.ok ? blockedResult.value : ""

      // Assert
      const blocked = await fixture.issueStorage.getIssue(blockedId, projectDir)
      expect(blocked.ok).toBe(true)
      if (blocked.ok) {
        expect(blocked.value.blockedBy).toContain(blockerId)
      }
    })

    test("getReadyIssues excludes blocked issues", async () => {
      // Arrange
      const project = await fixture.projectManager.createProject({
        name: "Ready Issues Test",
        storage: "local",
      })
      const projectDir = project.projectDir

      const blockerResult = await fixture.issueStorage.createIssue(projectDir, "Blocker")
      const blockerId = blockerResult.ok ? blockerResult.value : ""

      const blockedResult = await fixture.issueStorage.createIssue(projectDir, "Blocked", {
        blockedBy: [blockerId],
      })
      const blockedId = blockedResult.ok ? blockedResult.value : ""

      const readyResult = await fixture.issueStorage.createIssue(projectDir, "Ready")
      const readyId = readyResult.ok ? readyResult.value : ""

      // Act
      const ready = await fixture.issueStorage.getReadyIssues(projectDir)

      // Assert
      expect(ready.ok).toBe(true)
      if (ready.ok) {
        const readyIds = ready.value.map((i) => i.id)
        expect(readyIds).toContain(blockerId) // Blocker is ready
        expect(readyIds).toContain(readyId) // Ready issue is ready
        expect(readyIds).not.toContain(blockedId) // Blocked is NOT ready
      }
    })

    test("closing blocker unblocks dependent issues", async () => {
      // Arrange
      const project = await fixture.projectManager.createProject({
        name: "Unblock Test",
        storage: "local",
      })
      const projectDir = project.projectDir

      const blockerResult = await fixture.issueStorage.createIssue(projectDir, "Blocker")
      const blockerId = blockerResult.ok ? blockerResult.value : ""

      const blockedResult = await fixture.issueStorage.createIssue(projectDir, "Blocked", {
        blockedBy: [blockerId],
      })
      const blockedId = blockedResult.ok ? blockedResult.value : ""

      // Verify initially blocked
      let ready = await fixture.issueStorage.getReadyIssues(projectDir)
      expect(ready.ok).toBe(true)
      if (ready.ok) {
        expect(ready.value.map((i) => i.id)).not.toContain(blockedId)
      }

      // Act: Close the blocker
      await fixture.issueStorage.updateStatus(blockerId, "closed", projectDir)

      // Assert: Blocked issue is now ready
      ready = await fixture.issueStorage.getReadyIssues(projectDir)
      expect(ready.ok).toBe(true)
      if (ready.ok) {
        expect(ready.value.map((i) => i.id)).toContain(blockedId)
      }
    })

    test("multiple blockers all must be closed", async () => {
      // Arrange
      const project = await fixture.projectManager.createProject({
        name: "Multi-Blocker Test",
        storage: "local",
      })
      const projectDir = project.projectDir

      const blocker1Result = await fixture.issueStorage.createIssue(projectDir, "Blocker 1")
      const blocker2Result = await fixture.issueStorage.createIssue(projectDir, "Blocker 2")
      const blocker1Id = blocker1Result.ok ? blocker1Result.value : ""
      const blocker2Id = blocker2Result.ok ? blocker2Result.value : ""

      const blockedResult = await fixture.issueStorage.createIssue(projectDir, "Blocked", {
        blockedBy: [blocker1Id, blocker2Id],
      })
      const blockedId = blockedResult.ok ? blockedResult.value : ""

      // Close only blocker1
      await fixture.issueStorage.updateStatus(blocker1Id, "closed", projectDir)

      // Assert: Still blocked (blocker2 is open)
      let ready = await fixture.issueStorage.getReadyIssues(projectDir)
      expect(ready.ok).toBe(true)
      if (ready.ok) {
        expect(ready.value.map((i) => i.id)).not.toContain(blockedId)
      }

      // Close blocker2
      await fixture.issueStorage.updateStatus(blocker2Id, "closed", projectDir)

      // Assert: Now unblocked
      ready = await fixture.issueStorage.getReadyIssues(projectDir)
      expect(ready.ok).toBe(true)
      if (ready.ok) {
        expect(ready.value.map((i) => i.id)).toContain(blockedId)
      }
    })

    test("addDependency creates blocker relationship after creation", async () => {
      // Arrange
      const project = await fixture.projectManager.createProject({
        name: "Add Dependency Test",
        storage: "local",
      })
      const projectDir = project.projectDir

      const issue1Result = await fixture.issueStorage.createIssue(projectDir, "Issue 1")
      const issue2Result = await fixture.issueStorage.createIssue(projectDir, "Issue 2")
      const issue1Id = issue1Result.ok ? issue1Result.value : ""
      const issue2Id = issue2Result.ok ? issue2Result.value : ""

      // Both should be ready initially
      let ready = await fixture.issueStorage.getReadyIssues(projectDir)
      expect(ready.ok).toBe(true)
      if (ready.ok) {
        expect(ready.value.map((i) => i.id)).toContain(issue1Id)
        expect(ready.value.map((i) => i.id)).toContain(issue2Id)
      }

      // Act: Add dependency
      const depResult = await fixture.issueStorage.addDependency(issue2Id, issue1Id, projectDir)
      expect(depResult.ok).toBe(true)

      // Assert: issue2 is now blocked
      ready = await fixture.issueStorage.getReadyIssues(projectDir)
      expect(ready.ok).toBe(true)
      if (ready.ok) {
        expect(ready.value.map((i) => i.id)).toContain(issue1Id)
        expect(ready.value.map((i) => i.id)).not.toContain(issue2Id)
      }
    })

    test("tree renderer shows blocked icon", async () => {
      // Arrange
      const project = await fixture.projectManager.createProject({
        name: "Blocked Icon Test",
        storage: "local",
      })
      const projectDir = project.projectDir

      const blockerResult = await fixture.issueStorage.createIssue(projectDir, "Blocker")
      const blockerId = blockerResult.ok ? blockerResult.value : ""

      await fixture.issueStorage.createIssue(projectDir, "Blocked Issue", {
        blockedBy: [blockerId],
      })

      // Act
      const listResult = await fixture.issueStorage.listIssues(projectDir)
      expect(listResult.ok).toBe(true)
      if (!listResult.ok) return

      const treeOutput = renderIssueTree(listResult.value)

      // Assert: Blocked icon (⏳) should appear
      expect(treeOutput).toContain("⏳")
    })
  })

  describe("Status transitions (open → in_progress → closed)", () => {
    test("new issues start with open status", async () => {
      // Arrange
      const project = await fixture.projectManager.createProject({
        name: "Status Test",
        storage: "local",
      })
      const projectDir = project.projectDir

      // Act
      const issueResult = await fixture.issueStorage.createIssue(projectDir, "New Issue")
      const issueId = issueResult.ok ? issueResult.value : ""

      // Assert
      const issue = await fixture.issueStorage.getIssue(issueId, projectDir)
      expect(issue.ok).toBe(true)
      if (issue.ok) {
        expect(issue.value.status).toBe("open")
      }
    })

    test("claimIssue transitions to in_progress", async () => {
      // Arrange
      const project = await fixture.projectManager.createProject({
        name: "Claim Test",
        storage: "local",
      })
      const projectDir = project.projectDir

      const issueResult = await fixture.issueStorage.createIssue(projectDir, "Test Issue")
      const issueId = issueResult.ok ? issueResult.value : ""

      // Act
      const claimResult = await fixture.issueStorage.claimIssue(issueId, projectDir, "test-user")

      // Assert
      expect(claimResult.ok).toBe(true)
      const issue = await fixture.issueStorage.getIssue(issueId, projectDir)
      expect(issue.ok).toBe(true)
      if (issue.ok) {
        expect(issue.value.status).toBe("in_progress")
        expect(issue.value.assignee).toBe("test-user")
      }
    })

    test("updateStatus transitions through all states", async () => {
      // Arrange
      const project = await fixture.projectManager.createProject({
        name: "Status Transition Test",
        storage: "local",
      })
      const projectDir = project.projectDir

      const issueResult = await fixture.issueStorage.createIssue(projectDir, "Test Issue")
      const issueId = issueResult.ok ? issueResult.value : ""

      // Act & Assert: open → in_progress
      await fixture.issueStorage.updateStatus(issueId, "in_progress", projectDir)
      let issue = await fixture.issueStorage.getIssue(issueId, projectDir)
      expect(issue.ok && issue.value.status).toBe("in_progress")

      // Act & Assert: in_progress → closed
      await fixture.issueStorage.updateStatus(issueId, "closed", projectDir)
      issue = await fixture.issueStorage.getIssue(issueId, projectDir)
      expect(issue.ok && issue.value.status).toBe("closed")

      // Act & Assert: closed → open (reopen)
      await fixture.issueStorage.updateStatus(issueId, "open", projectDir)
      issue = await fixture.issueStorage.getIssue(issueId, projectDir)
      expect(issue.ok && issue.value.status).toBe("open")
    })

    test("getProjectStatus reflects status counts", async () => {
      // Arrange
      const project = await fixture.projectManager.createProject({
        name: "Status Count Test",
        storage: "local",
      })
      const projectDir = project.projectDir

      // Create issues with different statuses
      const openResult = await fixture.issueStorage.createIssue(projectDir, "Open Issue")
      const inProgressResult = await fixture.issueStorage.createIssue(
        projectDir,
        "In Progress Issue"
      )
      const closedResult = await fixture.issueStorage.createIssue(projectDir, "Closed Issue")

      const inProgressId = inProgressResult.ok ? inProgressResult.value : ""
      const closedId = closedResult.ok ? closedResult.value : ""

      await fixture.issueStorage.updateStatus(inProgressId, "in_progress", projectDir)
      await fixture.issueStorage.updateStatus(closedId, "closed", projectDir)

      // Act
      const statusResult = await fixture.issueStorage.getProjectStatus(projectDir)

      // Assert
      expect(statusResult.ok).toBe(true)
      if (statusResult.ok) {
        expect(statusResult.value.total).toBe(4) // Root + 3 issues
        expect(statusResult.value.completed).toBe(1)
        expect(statusResult.value.inProgress).toBe(1)
      }
    })

    test("tree renderer shows status icons", async () => {
      // Arrange
      const project = await fixture.projectManager.createProject({
        name: "Status Icon Test",
        storage: "local",
      })
      const projectDir = project.projectDir

      const openResult = await fixture.issueStorage.createIssue(projectDir, "Open Issue")
      const inProgressResult = await fixture.issueStorage.createIssue(
        projectDir,
        "In Progress Issue"
      )
      const closedResult = await fixture.issueStorage.createIssue(projectDir, "Closed Issue")

      await fixture.issueStorage.updateStatus(
        inProgressResult.ok ? inProgressResult.value : "",
        "in_progress",
        projectDir
      )
      await fixture.issueStorage.updateStatus(
        closedResult.ok ? closedResult.value : "",
        "closed",
        projectDir
      )

      // Act
      const listResult = await fixture.issueStorage.listIssues(projectDir)
      expect(listResult.ok).toBe(true)
      if (!listResult.ok) return

      const treeOutput = renderIssueTree(listResult.value)

      // Assert
      expect(treeOutput).toContain("⬜") // Open
      expect(treeOutput).toContain("🔄") // In Progress
      expect(treeOutput).toContain("✅") // Closed
    })
  })

  describe("Labels and filtering", () => {
    test("creates issues with labels", async () => {
      // Arrange
      const project = await fixture.projectManager.createProject({
        name: "Labels Test",
        storage: "local",
      })
      const projectDir = project.projectDir

      // Act
      const issueResult = await fixture.issueStorage.createIssue(projectDir, "Labeled Issue", {
        labels: ["frontend", "urgent", "bug"],
      })
      const issueId = issueResult.ok ? issueResult.value : ""

      // Assert
      const issue = await fixture.issueStorage.getIssue(issueId, projectDir)
      expect(issue.ok).toBe(true)
      if (issue.ok) {
        expect(issue.value.labels).toContain("frontend")
        expect(issue.value.labels).toContain("urgent")
        expect(issue.value.labels).toContain("bug")
      }
    })

    test("filters issues by label", async () => {
      // Arrange
      const project = await fixture.projectManager.createProject({
        name: "Label Filter Test",
        storage: "local",
      })
      const projectDir = project.projectDir

      await fixture.issueStorage.createIssue(projectDir, "Frontend Issue", {
        labels: ["frontend"],
      })
      await fixture.issueStorage.createIssue(projectDir, "Backend Issue", {
        labels: ["backend"],
      })
      await fixture.issueStorage.createIssue(projectDir, "Full Stack Issue", {
        labels: ["frontend", "backend"],
      })

      // Act: Filter by frontend label
      const frontendResult = await fixture.issueStorage.listIssues(projectDir, {
        labels: ["frontend"],
      })

      // Assert
      expect(frontendResult.ok).toBe(true)
      if (frontendResult.ok) {
        expect(frontendResult.value.length).toBe(2) // Frontend + Full Stack
        const titles = frontendResult.value.map((i) => i.title)
        expect(titles).toContain("Frontend Issue")
        expect(titles).toContain("Full Stack Issue")
        expect(titles).not.toContain("Backend Issue")
      }
    })

    test("updates issue labels", async () => {
      // Arrange
      const project = await fixture.projectManager.createProject({
        name: "Label Update Test",
        storage: "local",
      })
      const projectDir = project.projectDir

      const issueResult = await fixture.issueStorage.createIssue(projectDir, "Test Issue", {
        labels: ["old-label"],
      })
      const issueId = issueResult.ok ? issueResult.value : ""

      // Act
      const updateResult = await fixture.issueStorage.updateIssue(issueId, projectDir, {
        labels: ["new-label", "another-label"],
      })

      // Assert
      expect(updateResult.ok).toBe(true)
      const issue = await fixture.issueStorage.getIssue(issueId, projectDir)
      expect(issue.ok).toBe(true)
      if (issue.ok) {
        expect(issue.value.labels).toContain("new-label")
        expect(issue.value.labels).toContain("another-label")
        expect(issue.value.labels).not.toContain("old-label")
      }
    })
  })

  describe("Comments", () => {
    test("adds comment to issue", async () => {
      // Arrange
      const project = await fixture.projectManager.createProject({
        name: "Comments Test",
        storage: "local",
      })
      const projectDir = project.projectDir

      const issueResult = await fixture.issueStorage.createIssue(projectDir, "Test Issue")
      const issueId = issueResult.ok ? issueResult.value : ""

      // Act
      const commentResult = await fixture.issueStorage.addComment(
        issueId,
        projectDir,
        "This is a test comment"
      )

      // Assert
      expect(commentResult.ok).toBe(true)
    })

    test("adds multiple comments to issue", async () => {
      // Arrange
      const project = await fixture.projectManager.createProject({
        name: "Multi-Comment Test",
        storage: "local",
      })
      const projectDir = project.projectDir

      const issueResult = await fixture.issueStorage.createIssue(projectDir, "Test Issue")
      const issueId = issueResult.ok ? issueResult.value : ""

      // Act
      await fixture.issueStorage.addComment(issueId, projectDir, "First comment")
      await fixture.issueStorage.addComment(issueId, projectDir, "Second comment")
      await fixture.issueStorage.addComment(issueId, projectDir, "Third comment")

      // Assert: All comments added successfully (no errors)
      // Note: InMemoryIssueStorage doesn't expose comments for retrieval,
      // but we verify the operations succeed
      const result = await fixture.issueStorage.addComment(issueId, projectDir, "Fourth comment")
      expect(result.ok).toBe(true)
    })
  })

  describe("Tree format display", () => {
    test("renderIssueTree shows correct hierarchy", async () => {
      // Arrange
      const project = await fixture.projectManager.createProject({
        name: "Tree Display Test",
        storage: "local",
      })
      const projectDir = project.projectDir

      // Create 3-level hierarchy
      const epicResult = await fixture.issueStorage.createIssue(projectDir, "Epic: Feature X")
      const epicId = epicResult.ok ? epicResult.value : ""

      const task1Result = await fixture.issueStorage.createIssue(projectDir, "Task: Design", {
        parent: epicId,
      })
      const task1Id = task1Result.ok ? task1Result.value : ""

      const task2Result = await fixture.issueStorage.createIssue(projectDir, "Task: Implement", {
        parent: epicId,
      })

      await fixture.issueStorage.createIssue(projectDir, "Subtask: Mockups", {
        parent: task1Id,
      })
      await fixture.issueStorage.createIssue(projectDir, "Subtask: Review", {
        parent: task1Id,
      })

      // Act
      const listResult = await fixture.issueStorage.listIssues(projectDir)
      expect(listResult.ok).toBe(true)
      if (!listResult.ok) return

      const treeOutput = renderIssueTree(listResult.value)

      // Assert: Tree structure is visible
      expect(treeOutput).toContain("Epic: Feature X")
      expect(treeOutput).toContain("Task: Design")
      expect(treeOutput).toContain("Task: Implement")
      expect(treeOutput).toContain("Subtask: Mockups")
      expect(treeOutput).toContain("Subtask: Review")

      // Assert: Tree connectors are present
      expect(treeOutput).toMatch(/[├└]──/)
    })

    test("buildIssueTree creates correct node structure", async () => {
      // Arrange
      const project = await fixture.projectManager.createProject({
        name: "Build Tree Test",
        storage: "local",
      })
      const projectDir = project.projectDir

      const epicResult = await fixture.issueStorage.createIssue(projectDir, "Epic")
      const epicId = epicResult.ok ? epicResult.value : ""

      const taskResult = await fixture.issueStorage.createIssue(projectDir, "Task", {
        parent: epicId,
      })
      const taskId = taskResult.ok ? taskResult.value : ""

      await fixture.issueStorage.createIssue(projectDir, "Subtask", {
        parent: taskId,
      })

      // Act
      const listResult = await fixture.issueStorage.listIssues(projectDir)
      expect(listResult.ok).toBe(true)
      if (!listResult.ok) return

      const tree = buildIssueTree(listResult.value)

      // Assert: Find the epic node (excluding root project issue)
      const epicNode = tree.find((n) => n.issue.title === "Epic")
      expect(epicNode).toBeDefined()
      if (epicNode) {
        expect(epicNode.children.length).toBe(1)
        expect(epicNode.children[0].issue.title).toBe("Task")
        expect(epicNode.children[0].children.length).toBe(1)
        expect(epicNode.children[0].children[0].issue.title).toBe("Subtask")
      }
    })

    test("empty project shows no issues message", () => {
      // Act
      const treeOutput = renderIssueTree([])

      // Assert
      expect(treeOutput).toBe("(no issues)")
    })
  })

  describe("Complete workflow integration", () => {
    test("full issue management workflow", async () => {
      // This test exercises the complete workflow described in the issue

      // Step 1: Create project
      const project = await fixture.projectManager.createProject({
        name: "Complete Workflow Test",
        type: "project",
        description: "Testing complete issue management workflow",
        storage: "local",
      })
      const projectDir = project.projectDir
      const projectId = project.projectId

      // Step 2: Create 3-level hierarchy
      // Epic
      const epicResult = await fixture.issueStorage.createIssue(
        projectDir,
        "Epic: Authentication System",
        {
          priority: 0,
          labels: ["epic", "security"],
          description: "Implement complete authentication system",
        }
      )
      const epicId = epicResult.ok ? epicResult.value : ""

      // Tasks under epic
      const task1Result = await fixture.issueStorage.createIssue(projectDir, "Task: Login API", {
        parent: epicId,
        priority: 1,
        labels: ["task", "backend"],
      })
      const task1Id = task1Result.ok ? task1Result.value : ""

      const task2Result = await fixture.issueStorage.createIssue(projectDir, "Task: Login UI", {
        parent: epicId,
        priority: 1,
        labels: ["task", "frontend"],
        blockedBy: [task1Id], // UI blocked by API
      })
      const task2Id = task2Result.ok ? task2Result.value : ""

      // Subtasks under task1
      const subtask1Result = await fixture.issueStorage.createIssue(
        projectDir,
        "Subtask: Design API schema",
        {
          parent: task1Id,
          priority: 2,
          labels: ["subtask", "design"],
        }
      )
      const subtask1Id = subtask1Result.ok ? subtask1Result.value : ""

      const subtask2Result = await fixture.issueStorage.createIssue(
        projectDir,
        "Subtask: Implement endpoints",
        {
          parent: task1Id,
          priority: 2,
          labels: ["subtask", "implementation"],
          blockedBy: [subtask1Id], // Implementation blocked by design
        }
      )
      const subtask2Id = subtask2Result.ok ? subtask2Result.value : ""

      // Step 3: Verify hierarchy
      expect(task1Id).toBe(`${epicId}.1`)
      expect(task2Id).toBe(`${epicId}.2`)
      expect(subtask1Id).toBe(`${task1Id}.1`)
      expect(subtask2Id).toBe(`${task1Id}.2`)

      // Step 4: Verify dependencies
      let ready = await fixture.issueStorage.getReadyIssues(projectDir)
      expect(ready.ok).toBe(true)
      if (ready.ok) {
        const readyIds = ready.value.map((i) => i.id)
        expect(readyIds).toContain(subtask1Id) // Design is ready
        expect(readyIds).not.toContain(subtask2Id) // Implementation blocked
        expect(readyIds).not.toContain(task2Id) // UI blocked by API
      }

      // Step 5: Work through the workflow
      // Claim and complete subtask1 (design)
      await fixture.issueStorage.claimIssue(subtask1Id, projectDir, "designer")
      await fixture.issueStorage.addComment(subtask1Id, projectDir, "Starting API design")
      await fixture.issueStorage.updateStatus(subtask1Id, "closed", projectDir)
      await fixture.issueStorage.addComment(subtask1Id, projectDir, "Design complete")

      // Now subtask2 should be ready
      ready = await fixture.issueStorage.getReadyIssues(projectDir)
      if (ready.ok) {
        expect(ready.value.map((i) => i.id)).toContain(subtask2Id)
      }

      // Complete subtask2 (implementation)
      await fixture.issueStorage.claimIssue(subtask2Id, projectDir, "developer")
      await fixture.issueStorage.updateStatus(subtask2Id, "closed", projectDir)

      // Complete task1 (API)
      await fixture.issueStorage.updateStatus(task1Id, "closed", projectDir)

      // Now task2 (UI) should be ready
      ready = await fixture.issueStorage.getReadyIssues(projectDir)
      if (ready.ok) {
        expect(ready.value.map((i) => i.id)).toContain(task2Id)
      }

      // Step 6: Verify project status
      const status = await fixture.projectManager.getProjectStatus(projectId)
      expect(status).not.toBeNull()
      if (status && status.issueStatus) {
        expect(status.issueStatus.completed).toBeGreaterThan(0)
      }

      // Step 7: Verify tree display
      const listResult = await fixture.issueStorage.listIssues(projectDir)
      expect(listResult.ok).toBe(true)
      if (listResult.ok) {
        const treeOutput = renderIssueTree(listResult.value)

        // Verify hierarchy is displayed
        expect(treeOutput).toContain("Epic: Authentication System")
        expect(treeOutput).toContain("Task: Login API")
        expect(treeOutput).toContain("Task: Login UI")
        expect(treeOutput).toContain("Subtask: Design API schema")
        expect(treeOutput).toContain("Subtask: Implement endpoints")

        // Verify status icons
        expect(treeOutput).toContain("✅") // Closed issues
      }

      // Step 8: Verify label filtering
      const backendResult = await fixture.issueStorage.listIssues(projectDir, {
        labels: ["backend"],
      })
      expect(backendResult.ok).toBe(true)
      if (backendResult.ok) {
        expect(backendResult.value.some((i) => i.title === "Task: Login API")).toBe(true)
        expect(backendResult.value.some((i) => i.title === "Task: Login UI")).toBe(false)
      }
    })
  })
})
