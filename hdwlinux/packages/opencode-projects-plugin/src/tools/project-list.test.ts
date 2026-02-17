/**
 * Tests for project_list and project_status tools
 */

import { describe, test, expect, beforeAll, afterAll } from "bun:test"
import * as fs from "node:fs/promises"
import * as path from "node:path"
import * as os from "node:os"

import { createProjectCreate } from "./project-create.js"
import { createProjectList } from "./project-list.js"
import { createProjectStatus } from "./project-status.js"
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

describe("project_list and project_status tools", () => {
  let testDir: string
  let projectManager: ProjectManager
  let testShell: BunShell
  let toolDeps: ToolDepsV2
  let projectId: string

  beforeAll(async () => {

    testDir = await fs.mkdtemp(path.join(os.tmpdir(), "project-list-test-"))


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
        name: "List Test Project",
        type: "project",
        storage: "local",
        description: "A project for testing list/status",
      },
      mockContext
    )


    projectId = projectManager.getFocusedProjectId()!
  })

  afterAll(async () => {

    try {
      await fs.rm(testDir, { recursive: true, force: true })
    } catch {

    }
  })

  describe("project_list", () => {
    test("lists local projects", async () => {
      const tool = createProjectList(toolDeps)

      const result = await tool.execute({ scope: "local" }, mockContext)

      expect(result).toContain("Projects")
      expect(result).toContain("List Test Project")
      expect(result).toContain("Local")
    })

    test("returns empty message when no projects", async () => {

      const emptyDir = await fs.mkdtemp(path.join(os.tmpdir(), "empty-test-"))
      const config = await ConfigManager.load()
      const emptyManager = new ProjectManager({
        config,
        issueStorage: new InMemoryIssueStorage(),
        focus: new FocusManager(),
        log: mockLogger,
        repoRoot: emptyDir,
      })

      const tool = createProjectList({
        client: mockClient,
        projectManager: emptyManager,
        log: mockLogger,
        $: testShell,
      })

      const result = await tool.execute({ scope: "local" }, mockContext)

      expect(result).toContain("No projects found")


      await fs.rm(emptyDir, { recursive: true, force: true })
    })

    test("filters by status", async () => {
      const tool = createProjectList(toolDeps)


      const activeResult = await tool.execute({ status: "active" }, mockContext)
      expect(activeResult).toContain("List Test Project")


      const completedResult = await tool.execute({ status: "completed" }, mockContext)
      expect(completedResult).toContain("No projects found")
    })
  })

  describe("project_status", () => {
    test("shows status for focused project", async () => {
      const tool = createProjectStatus(toolDeps)

      const result = await tool.execute({}, mockContext)

      expect(result).toContain("List Test Project")
      expect(result).toContain("Progress")
      expect(result).toContain("active")
    })

    test("shows status for specific project", async () => {
      const tool = createProjectStatus(toolDeps)

      const result = await tool.execute({ projectId }, mockContext)

      expect(result).toContain("List Test Project")
    })

    test("returns error for non-existent project", async () => {
      projectManager.clearFocus()

      const tool = createProjectStatus(toolDeps)

      const result = await tool.execute({ projectId: "non-existent-project" }, mockContext)

      expect(result).toContain("not found")


      projectManager.setFocus(projectId)
    })

    test("prompts when no project focused", async () => {

      projectManager.clearFocus()

      const tool = createProjectStatus(toolDeps)

      const result = await tool.execute({}, mockContext)

      expect(result).toContain("No project specified")
      expect(result).toContain("project_focus")


      projectManager.setFocus(projectId)
    })
  })
})
