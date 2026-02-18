/**
 * Tests for project_focus tool and focus mode context injection
 */

import { describe, test, expect, beforeAll, afterAll } from "bun:test"
import * as fs from "node:fs/promises"
import * as path from "node:path"
import * as os from "node:os"

import { createProjectCreate } from "./project-create.js"
import { createProjectFocus } from "./project-focus.js"
import { createIssueCreate } from "./issue-create.js"
import { ConfigManager } from "../core/config-manager.js"
import { InMemoryIssueStorage } from "../storage/inmemory-issue-storage.js"
import { FocusManager } from "../core/focus-manager.js"
import { ProjectManager } from "../core/project-manager.js"
import {
  createMockLogger,
  createMockClient,
  createTestShell,
  createMockContext,
} from "../core/test-utils.js"
import type { BunShell, ToolDepsV2 } from "../core/types.js"

const mockLogger = createMockLogger()
const mockClient = createMockClient()
const mockContext = createMockContext()

describe("project_focus tool", () => {
  let testDir: string
  let projectManager: ProjectManager
  let testShell: BunShell
  let toolDeps: ToolDepsV2
  let projectId: string

  beforeAll(async () => {

    testDir = await fs.mkdtemp(path.join(os.tmpdir(), "project-focus-test-"))


    const config = await ConfigManager.load()
    const issueStorage = new InMemoryIssueStorage({ prefix: "test" })
    const focus = new FocusManager()
    testShell = createTestShell()

    projectManager = new ProjectManager({
      config,
      issueStorage,
      focus,
      log: mockLogger,
      repoRoot: testDir,
    })

    toolDeps = {
      client: mockClient,
      projectManager,
      log: mockLogger,
      $: testShell,
    }


    const createTool = createProjectCreate(toolDeps)

    await createTool.execute(
      {
        name: "Focus Test Project",
        type: "project",
        storage: "local",
      },
      mockContext
    )


    projectId = projectManager.getFocusedProjectId()!


    projectManager.clearFocus()
  })

  afterAll(async () => {

    try {
      await fs.rm(testDir, { recursive: true, force: true })
    } catch {

    }
  })

  test("shows no focus when nothing is focused", async () => {
    const tool = createProjectFocus(toolDeps)

    const result = await tool.execute({}, mockContext)

    expect(result).toContain("No project is currently focused")
    expect(result).toContain("project_focus")
  })

  test("sets focus to a project", async () => {
    const tool = createProjectFocus(toolDeps)

    const result = await tool.execute({ projectId }, mockContext)

    expect(result).toContain("Focus Set")
    expect(result).toContain(projectId)


    expect(projectManager.getFocusedProjectId()).toBe(projectId)
  })

  test("shows current focus", async () => {
    const tool = createProjectFocus(toolDeps)

    const result = await tool.execute({}, mockContext)

    expect(result).toContain("Current Focus")
    expect(result).toContain(projectId)
  })

  test("sets focus to a specific issue", async () => {

    const issueTool = createIssueCreate(toolDeps)

    const issueResult = await issueTool.execute(
      {
        title: "Test Issue for Focus",
        projectId,
      },
      mockContext
    )


    const issueIdMatch = issueResult.match(/Issue Created:\s+([\w.-]+)/)
    expect(issueIdMatch).not.toBeNull()
    const issueId = issueIdMatch![1]


    const focusTool = createProjectFocus(toolDeps)

    const result = await focusTool.execute({ issueId }, mockContext)

    expect(result).toContain("Issue Focus Set")
    expect(result).toContain(issueId)


    expect(projectManager.getFocusedIssueId()).toBe(issueId)
  })

  test("clears focus", async () => {
    const tool = createProjectFocus(toolDeps)

    const result = await tool.execute({ clear: true }, mockContext)

    expect(result).toContain("Focus cleared")


    expect(projectManager.getFocusedProjectId()).toBeNull()
  })
})

describe("FocusManager", () => {
  test("serializes and restores focus state", () => {
    const focus = new FocusManager()

    focus.setFocus("test-project", "test-issue")

    const serialized = focus.serialize()
    expect(serialized).not.toBeNull()


    const focus2 = new FocusManager()
    const restored = focus2.restore(serialized!)

    expect(restored).toBe(true)
    expect(focus2.getProjectId()).toBe("test-project")
    expect(focus2.getIssueId()).toBe("test-issue")
  })

  test("isFocusedOn checks project correctly", () => {
    const focus = new FocusManager()

    focus.setFocus("my-project")

    expect(focus.isFocusedOn("my-project")).toBe(true)
    expect(focus.isFocusedOn("other-project")).toBe(false)
  })

  test("clearIssueFocus keeps project focus", () => {
    const focus = new FocusManager()

    focus.setFocus("my-project", "my-issue")
    expect(focus.getIssueId()).toBe("my-issue")

    focus.clearIssueFocus()

    expect(focus.getProjectId()).toBe("my-project")
    expect(focus.getIssueId()).toBeNull()
  })
})
