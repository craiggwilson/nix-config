/**
 * Tests for InMemoryIssueStorage
 */

import { describe, test, expect, beforeEach } from "bun:test"

import { InMemoryIssueStorage } from "./storage.js"

describe("InMemoryIssueStorage", () => {
  let storage: InMemoryIssueStorage
  const projectDir = "/test/project"

  beforeEach(() => {
    storage = new InMemoryIssueStorage({ prefix: "test" })
  })

  test("isAvailable always returns true", async () => {
    const result = await storage.isAvailable()
    expect(result.ok).toBe(true)
    if (result.ok) expect(result.value).toBe(true)
  })

  test("init and isInitialized work correctly", async () => {
    const beforeResult = await storage.isInitialized(projectDir)
    expect(beforeResult.ok).toBe(true)
    if (beforeResult.ok) expect(beforeResult.value).toBe(false)

    await storage.init(projectDir)

    const afterResult = await storage.isInitialized(projectDir)
    expect(afterResult.ok).toBe(true)
    if (afterResult.ok) expect(afterResult.value).toBe(true)
  })

  test("createIssue creates an issue and returns ID", async () => {
    await storage.init(projectDir)

    const result = await storage.createIssue(projectDir, "Test Issue", {
      priority: 1,
      description: "A test issue",
      labels: ["test"],
    })

    expect(result.ok).toBe(true)
    if (result.ok) {
      expect(result.value).toMatch(/^test-[a-f0-9]+$/)
    }
  })

  test("createIssue with parent creates hierarchical ID", async () => {
    await storage.init(projectDir)

    const parentResult = await storage.createIssue(projectDir, "Parent Issue")
    expect(parentResult.ok).toBe(true)
    const parentId = parentResult.ok ? parentResult.value : ""

    const childResult = await storage.createIssue(projectDir, "Child Issue", {
      parent: parentId,
    })
    expect(childResult.ok).toBe(true)
    if (childResult.ok) expect(childResult.value).toBe(`${parentId}.1`)

    const child2Result = await storage.createIssue(projectDir, "Child Issue 2", {
      parent: parentId,
    })
    expect(child2Result.ok).toBe(true)
    if (child2Result.ok) expect(child2Result.value).toBe(`${parentId}.2`)
  })

  test("getIssue retrieves issue details", async () => {
    await storage.init(projectDir)

    const createResult = await storage.createIssue(projectDir, "Get Test Issue", {
      priority: 2,
      description: "Description here",
    })
    expect(createResult.ok).toBe(true)
    const id = createResult.ok ? createResult.value : ""

    const result = await storage.getIssue(id, projectDir)

    expect(result.ok).toBe(true)
    if (result.ok) {
      expect(result.value.title).toBe("Get Test Issue")
      expect(result.value.priority).toBe(2)
      expect(result.value.description).toBe("Description here")
      expect(result.value.status).toBe("open")
    }
  })

  test("getIssue returns error for non-existent issue", async () => {
    await storage.init(projectDir)

    const result = await storage.getIssue("non-existent", projectDir)

    expect(result.ok).toBe(false)
  })

  test("listIssues returns all issues", async () => {
    await storage.init(projectDir)

    await storage.createIssue(projectDir, "Issue 1")
    await storage.createIssue(projectDir, "Issue 2")
    await storage.createIssue(projectDir, "Issue 3")

    const result = await storage.listIssues(projectDir)

    expect(result.ok).toBe(true)
    if (result.ok) expect(result.value.length).toBe(3)
  })

  test("listIssues filters by status", async () => {
    await storage.init(projectDir)

    await storage.createIssue(projectDir, "Open Issue")
    const id2Result = await storage.createIssue(projectDir, "Closed Issue")
    const id2 = id2Result.ok ? id2Result.value : ""

    await storage.updateStatus(id2, "closed", projectDir)

    const openResult = await storage.listIssues(projectDir, { status: "open" })
    const closedResult = await storage.listIssues(projectDir, { status: "closed" })

    expect(openResult.ok).toBe(true)
    expect(closedResult.ok).toBe(true)
    if (openResult.ok) {
      expect(openResult.value.length).toBe(1)
      expect(openResult.value[0].title).toBe("Open Issue")
    }
    if (closedResult.ok) {
      expect(closedResult.value.length).toBe(1)
      expect(closedResult.value[0].title).toBe("Closed Issue")
    }
  })

  test("claimIssue updates status and assignee", async () => {
    await storage.init(projectDir)

    const createResult = await storage.createIssue(projectDir, "Claim Test")
    const id = createResult.ok ? createResult.value : ""

    const claimResult = await storage.claimIssue(id, projectDir, "test-user")

    expect(claimResult.ok).toBe(true)

    const issueResult = await storage.getIssue(id, projectDir)
    expect(issueResult.ok).toBe(true)
    if (issueResult.ok) {
      expect(issueResult.value.status).toBe("in_progress")
      expect(issueResult.value.assignee).toBe("test-user")
    }
  })

  test("updateStatus changes issue status", async () => {
    await storage.init(projectDir)

    const createResult = await storage.createIssue(projectDir, "Status Test")
    const id = createResult.ok ? createResult.value : ""

    await storage.updateStatus(id, "in_progress", projectDir)
    let issueResult = await storage.getIssue(id, projectDir)
    expect(issueResult.ok).toBe(true)
    if (issueResult.ok) expect(issueResult.value.status).toBe("in_progress")

    await storage.updateStatus(id, "closed", projectDir)
    issueResult = await storage.getIssue(id, projectDir)
    expect(issueResult.ok).toBe(true)
    if (issueResult.ok) expect(issueResult.value.status).toBe("closed")
  })

  test("addDependency creates blocker relationship", async () => {
    await storage.init(projectDir)

    const blockerResult = await storage.createIssue(projectDir, "Blocker")
    const blockedResult = await storage.createIssue(projectDir, "Blocked")
    const blockerId = blockerResult.ok ? blockerResult.value : ""
    const blockedId = blockedResult.ok ? blockedResult.value : ""

    const addResult = await storage.addDependency(blockedId, blockerId, projectDir)

    expect(addResult.ok).toBe(true)

    const getBlockedResult = await storage.getIssue(blockedId, projectDir)
    expect(getBlockedResult.ok).toBe(true)
    if (getBlockedResult.ok) expect(getBlockedResult.value.blockedBy).toContain(blockerId)
  })

  test("getReadyIssues returns unblocked open issues", async () => {
    await storage.init(projectDir)

    const blockerResult = await storage.createIssue(projectDir, "Blocker")
    const blockedResult = await storage.createIssue(projectDir, "Blocked")
    const readyResult = await storage.createIssue(projectDir, "Ready")
    const blockerId = blockerResult.ok ? blockerResult.value : ""
    const blockedId = blockedResult.ok ? blockedResult.value : ""
    const readyId = readyResult.ok ? readyResult.value : ""

    await storage.addDependency(blockedId, blockerId, projectDir)

    const result = await storage.getReadyIssues(projectDir)

    expect(result.ok).toBe(true)
    if (result.ok) {
      expect(result.value.length).toBe(2) // Blocker and Ready are ready
      expect(result.value.map((i) => i.id)).toContain(blockerId)
      expect(result.value.map((i) => i.id)).toContain(readyId)
      expect(result.value.map((i) => i.id)).not.toContain(blockedId)
    }
  })

  test("getReadyIssues includes blocked issues when blocker is closed", async () => {
    await storage.init(projectDir)

    const blockerResult = await storage.createIssue(projectDir, "Blocker")
    const blockedResult = await storage.createIssue(projectDir, "Blocked")
    const blockerId = blockerResult.ok ? blockerResult.value : ""
    const blockedId = blockedResult.ok ? blockedResult.value : ""

    await storage.addDependency(blockedId, blockerId, projectDir)

    let readyResult = await storage.getReadyIssues(projectDir)
    expect(readyResult.ok).toBe(true)
    if (readyResult.ok) expect(readyResult.value.map((i) => i.id)).not.toContain(blockedId)

    await storage.updateStatus(blockerId, "closed", projectDir)

    readyResult = await storage.getReadyIssues(projectDir)
    expect(readyResult.ok).toBe(true)
    if (readyResult.ok) expect(readyResult.value.map((i) => i.id)).toContain(blockedId)
  })

  test("getProjectStatus returns correct summary", async () => {
    await storage.init(projectDir)

    await storage.createIssue(projectDir, "Open 1")
    await storage.createIssue(projectDir, "Open 2")
    const id3Result = await storage.createIssue(projectDir, "In Progress")
    const id4Result = await storage.createIssue(projectDir, "Closed")
    const id5Result = await storage.createIssue(projectDir, "Blocked")
    const id1Result = await storage.listIssues(projectDir)
    const id1 = id1Result.ok ? id1Result.value[0].id : ""
    const id3 = id3Result.ok ? id3Result.value : ""
    const id4 = id4Result.ok ? id4Result.value : ""
    const id5 = id5Result.ok ? id5Result.value : ""

    await storage.claimIssue(id3, projectDir)
    await storage.updateStatus(id4, "closed", projectDir)
    await storage.addDependency(id5, id1, projectDir)

    const statusResult = await storage.getProjectStatus(projectDir)

    expect(statusResult.ok).toBe(true)
    if (statusResult.ok) {
      expect(statusResult.value.total).toBe(5)
      expect(statusResult.value.completed).toBe(1)
      expect(statusResult.value.inProgress).toBe(1)
      expect(statusResult.value.blocked).toBe(1)
      expect(statusResult.value.blockers.length).toBe(1)
      expect(statusResult.value.blockers[0].issueId).toBe(id5)
    }
  })

  test("getProjectStatus decreases blocked count when blocker is closed", async () => {
    await storage.init(projectDir)

    const blockerResult = await storage.createIssue(projectDir, "Blocker")
    const blockedResult = await storage.createIssue(projectDir, "Blocked")
    const blockerId = blockerResult.ok ? blockerResult.value : ""
    const blockedId = blockedResult.ok ? blockedResult.value : ""

    await storage.addDependency(blockedId, blockerId, projectDir)

    // Initially, blocked count should be 1
    let statusResult = await storage.getProjectStatus(projectDir)
    expect(statusResult.ok).toBe(true)
    if (statusResult.ok) {
      expect(statusResult.value.blocked).toBe(1)
      expect(statusResult.value.blockers.length).toBe(1)
    }

    // Close the blocker
    await storage.updateStatus(blockerId, "closed", projectDir)

    // Now blocked count should be 0 since the blocker is closed
    statusResult = await storage.getProjectStatus(projectDir)
    expect(statusResult.ok).toBe(true)
    if (statusResult.ok) {
      expect(statusResult.value.blocked).toBe(0)
      expect(statusResult.value.blockers.length).toBe(0)
      expect(statusResult.value.completed).toBe(1)
    }
  })

  test("clear removes all data", async () => {
    await storage.init(projectDir)
    await storage.createIssue(projectDir, "Test")

    storage.clear()

    const initResult = await storage.isInitialized(projectDir)
    expect(initResult.ok).toBe(true)
    if (initResult.ok) expect(initResult.value).toBe(false)

    const listResult = await storage.listIssues(projectDir)
    expect(listResult.ok).toBe(true)
    if (listResult.ok) expect(listResult.value.length).toBe(0)
  })
})
