/**
 * Tests for project_create tool
 */

import { describe, test, expect, beforeAll, afterAll } from "bun:test"
import * as fs from "node:fs/promises"
import * as path from "node:path"
import * as os from "node:os"

import { createProjectCreate } from "./project-create.js"
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
import type { BunShell } from "../core/types.js"

const mockLogger = createMockLogger()
const mockClient = createMockClient()
const mockContext = createMockContext()

describe("project_create tool", () => {
  let testDir: string
  let projectManager: ProjectManager
  let testShell: BunShell
  let issueStorage: InMemoryIssueStorage

  beforeAll(async () => {

    testDir = await fs.mkdtemp(path.join(os.tmpdir(), "project-create-test-"))


    const config = await ConfigManager.load()
    issueStorage = new InMemoryIssueStorage({ prefix: "test" })
    const focus = new FocusManager()
    testShell = createTestShell()

    projectManager = new ProjectManager({
      config,
      issueStorage,
      focus,
      log: mockLogger,
      repoRoot: testDir,
    })
  })

  afterAll(async () => {

    try {
      await fs.rm(testDir, { recursive: true, force: true })
    } catch {

    }
  })

  test("creates project directory structure", async () => {
    const tool = createProjectCreate({
      client: mockClient,
      projectManager,
      issueStorage,
      log: mockLogger,
      $: testShell,
    })

    const result = await tool.execute(
      {
        name: "Test Project",
        type: "project",
        storage: "local",
        description: "A test project",
      },
      mockContext
    )


    expect(result).toContain("Project Created")
    expect(result).toContain("Test Project")


    const projectsDir = path.join(testDir, ".projects")
    const entries = await fs.readdir(projectsDir)
    expect(entries.length).toBe(1)

    const projectDir = path.join(projectsDir, entries[0])


    const researchDir = path.join(projectDir, "research")
    const interviewsDir = path.join(projectDir, "interviews")
    const plansDir = path.join(projectDir, "plans")

    expect((await fs.stat(researchDir)).isDirectory()).toBe(true)
    expect((await fs.stat(interviewsDir)).isDirectory()).toBe(true)
    expect((await fs.stat(plansDir)).isDirectory()).toBe(true)


    const metadataPath = path.join(projectDir, "project.json")
    const metadata = JSON.parse(await fs.readFile(metadataPath, "utf8"))

    expect(metadata.name).toBe("Test Project")
    expect(metadata.type).toBe("project")
    expect(metadata.description).toBe("A test project")
    expect(metadata.status).toBe("active")
  })

  test("sets focus to new project", async () => {

    const focusedId = projectManager.getFocusedProjectId()
    expect(focusedId).not.toBeNull()
    expect(focusedId).toMatch(/^test-project-/)
  })

  test("generates unique project IDs", async () => {
    const tool = createProjectCreate({
      client: mockClient,
      projectManager,
      issueStorage,
      log: mockLogger,
      $: testShell,
    })


    const result = await tool.execute(
      {
        name: "Test Project",
        type: "project",
      },
      mockContext
    )

    expect(result).toContain("Project Created")


    const projectsDir = path.join(testDir, ".projects")
    const entries = await fs.readdir(projectsDir)
    expect(entries.length).toBe(2)


    expect(entries[0]).not.toBe(entries[1])
  })
})
