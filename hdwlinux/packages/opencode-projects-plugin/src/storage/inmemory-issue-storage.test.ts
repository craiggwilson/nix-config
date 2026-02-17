/**
 * Tests for InMemoryIssueStorage
 */

import { describe, test, expect, beforeEach } from "bun:test"

import { InMemoryIssueStorage } from "./inmemory-issue-storage.js"

describe("InMemoryIssueStorage", () => {
  let storage: InMemoryIssueStorage
  const projectDir = "/test/project"

  beforeEach(() => {
    storage = new InMemoryIssueStorage({ prefix: "test" })
  })

  test("isAvailable always returns true", async () => {
    expect(await storage.isAvailable()).toBe(true)
  })

  test("init and isInitialized work correctly", async () => {
    expect(await storage.isInitialized(projectDir)).toBe(false)

    await storage.init(projectDir)

    expect(await storage.isInitialized(projectDir)).toBe(true)
  })

  test("createIssue creates an issue and returns ID", async () => {
    await storage.init(projectDir)

    const id = await storage.createIssue(projectDir, "Test Issue", {
      priority: 1,
      description: "A test issue",
      labels: ["test"],
    })

    expect(id).not.toBeNull()
    expect(id).toMatch(/^test-[a-f0-9]+$/)
  })

  test("createIssue with parent creates hierarchical ID", async () => {
    await storage.init(projectDir)

    const parentId = await storage.createIssue(projectDir, "Parent Issue")
    const childId = await storage.createIssue(projectDir, "Child Issue", {
      parent: parentId!,
    })

    expect(childId).toBe(`${parentId}.1`)


    const child2Id = await storage.createIssue(projectDir, "Child Issue 2", {
      parent: parentId!,
    })

    expect(child2Id).toBe(`${parentId}.2`)
  })

  test("getIssue retrieves issue details", async () => {
    await storage.init(projectDir)

    const id = await storage.createIssue(projectDir, "Get Test Issue", {
      priority: 2,
      description: "Description here",
    })

    const issue = await storage.getIssue(id!, projectDir)

    expect(issue).not.toBeNull()
    expect(issue?.title).toBe("Get Test Issue")
    expect(issue?.priority).toBe(2)
    expect(issue?.description).toBe("Description here")
    expect(issue?.status).toBe("open")
  })

  test("getIssue returns null for non-existent issue", async () => {
    await storage.init(projectDir)

    const issue = await storage.getIssue("non-existent", projectDir)

    expect(issue).toBeNull()
  })

  test("listIssues returns all issues", async () => {
    await storage.init(projectDir)

    await storage.createIssue(projectDir, "Issue 1")
    await storage.createIssue(projectDir, "Issue 2")
    await storage.createIssue(projectDir, "Issue 3")

    const issues = await storage.listIssues(projectDir)

    expect(issues.length).toBe(3)
  })

  test("listIssues filters by status", async () => {
    await storage.init(projectDir)

    const id1 = await storage.createIssue(projectDir, "Open Issue")
    const id2 = await storage.createIssue(projectDir, "Closed Issue")

    await storage.updateStatus(id2!, "closed", projectDir)

    const openIssues = await storage.listIssues(projectDir, { status: "open" })
    const closedIssues = await storage.listIssues(projectDir, { status: "closed" })

    expect(openIssues.length).toBe(1)
    expect(openIssues[0].title).toBe("Open Issue")
    expect(closedIssues.length).toBe(1)
    expect(closedIssues[0].title).toBe("Closed Issue")
  })

  test("claimIssue updates status and assignee", async () => {
    await storage.init(projectDir)

    const id = await storage.createIssue(projectDir, "Claim Test")

    const claimed = await storage.claimIssue(id!, projectDir, "test-user")

    expect(claimed).toBe(true)

    const issue = await storage.getIssue(id!, projectDir)
    expect(issue?.status).toBe("in_progress")
    expect(issue?.assignee).toBe("test-user")
  })

  test("updateStatus changes issue status", async () => {
    await storage.init(projectDir)

    const id = await storage.createIssue(projectDir, "Status Test")

    await storage.updateStatus(id!, "in_progress", projectDir)
    let issue = await storage.getIssue(id!, projectDir)
    expect(issue?.status).toBe("in_progress")

    await storage.updateStatus(id!, "closed", projectDir)
    issue = await storage.getIssue(id!, projectDir)
    expect(issue?.status).toBe("closed")
  })

  test("addDependency creates blocker relationship", async () => {
    await storage.init(projectDir)

    const blockerId = await storage.createIssue(projectDir, "Blocker")
    const blockedId = await storage.createIssue(projectDir, "Blocked")

    const added = await storage.addDependency(blockedId!, blockerId!, projectDir)

    expect(added).toBe(true)

    const blocked = await storage.getIssue(blockedId!, projectDir)
    expect(blocked?.blockedBy).toContain(blockerId!)
  })

  test("getReadyIssues returns unblocked open issues", async () => {
    await storage.init(projectDir)

    const blockerId = await storage.createIssue(projectDir, "Blocker")
    const blockedId = await storage.createIssue(projectDir, "Blocked")
    const readyId = await storage.createIssue(projectDir, "Ready")

    await storage.addDependency(blockedId!, blockerId!, projectDir)

    const ready = await storage.getReadyIssues(projectDir)

    expect(ready.length).toBe(2) // Blocker and Ready are ready
    expect(ready.map((i) => i.id)).toContain(blockerId!)
    expect(ready.map((i) => i.id)).toContain(readyId!)
    expect(ready.map((i) => i.id)).not.toContain(blockedId!)
  })

  test("getReadyIssues includes blocked issues when blocker is closed", async () => {
    await storage.init(projectDir)

    const blockerId = await storage.createIssue(projectDir, "Blocker")
    const blockedId = await storage.createIssue(projectDir, "Blocked")

    await storage.addDependency(blockedId!, blockerId!, projectDir)


    let ready = await storage.getReadyIssues(projectDir)
    expect(ready.map((i) => i.id)).not.toContain(blockedId!)


    await storage.updateStatus(blockerId!, "closed", projectDir)


    ready = await storage.getReadyIssues(projectDir)
    expect(ready.map((i) => i.id)).toContain(blockedId!)
  })

  test("getProjectStatus returns correct summary", async () => {
    await storage.init(projectDir)

    const id1 = await storage.createIssue(projectDir, "Open 1")
    const id2 = await storage.createIssue(projectDir, "Open 2")
    const id3 = await storage.createIssue(projectDir, "In Progress")
    const id4 = await storage.createIssue(projectDir, "Closed")
    const id5 = await storage.createIssue(projectDir, "Blocked")

    await storage.claimIssue(id3!, projectDir)
    await storage.updateStatus(id4!, "closed", projectDir)
    await storage.addDependency(id5!, id1!, projectDir)

    const status = await storage.getProjectStatus(projectDir)

    expect(status).not.toBeNull()
    expect(status?.total).toBe(5)
    expect(status?.completed).toBe(1)
    expect(status?.inProgress).toBe(1)
    expect(status?.blocked).toBe(1)
    expect(status?.blockers.length).toBe(1)
    expect(status?.blockers[0].issueId).toBe(id5!)
  })

  test("clear removes all data", async () => {
    await storage.init(projectDir)
    await storage.createIssue(projectDir, "Test")

    storage.clear()

    expect(await storage.isInitialized(projectDir)).toBe(false)
    expect((await storage.listIssues(projectDir)).length).toBe(0)
  })
})
