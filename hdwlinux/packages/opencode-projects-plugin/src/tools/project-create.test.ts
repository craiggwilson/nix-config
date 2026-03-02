/**
 * Tests for project_create tool
 */

import { describe, test, expect, beforeAll, afterAll } from "bun:test"
import * as fs from "node:fs/promises"
import * as path from "node:path"
import * as os from "node:os"

import { createProjectCreate } from "./project-create.js"
import { ConfigManager } from "../config/index.js"
import { InMemoryIssueStorage } from "../issues/inmemory/index.js"
import { FocusManager, ProjectManager } from "../projects/index.js"
import {
  createMockLogger,
  createMockClient,
  createTestShell,
  createMockContext,
  createMockTeamManager,
} from "../utils/testing/index.js"
import type { BunShell } from "../utils/opencode-sdk/index.js"
import type { TeamManager } from "../execution/index.js"

const mockLogger = createMockLogger()
const mockClient = createMockClient()
const mockContext = createMockContext()

describe("project_create tool", () => {
  let testDir: string
  let projectManager: ProjectManager
  let testShell: BunShell
  let issueStorage: InMemoryIssueStorage
  let teamManager: TeamManager

  beforeAll(async () => {

    testDir = await fs.mkdtemp(path.join(os.tmpdir(), "project-create-test-"))


    const config = await ConfigManager.loadOrThrow()
    issueStorage = new InMemoryIssueStorage({ prefix: "test" })
    const focus = new FocusManager()
    testShell = createTestShell()

    teamManager = createMockTeamManager()

    projectManager = new ProjectManager(
      config,
      issueStorage,
      focus,
      mockLogger,
      testDir,
      undefined,
      undefined,
      teamManager,
    )
  })

  afterAll(async () => {

    try {
      await fs.rm(testDir, { recursive: true, force: true })
    } catch {

    }
  })

  test("creates project directory structure", async () => {
    const tool = createProjectCreate(projectManager, mockLogger)

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

    // Subdirectories are created on-demand, not by default
    // Just verify the project directory exists
    expect((await fs.stat(projectDir)).isDirectory()).toBe(true)

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
    const tool = createProjectCreate(projectManager, mockLogger)


    const result = await tool.execute(
      {
        name: "Test Project",
        type: "project",
        storage: "local",
      },
      mockContext
    )

    expect(result).toContain("Project Created")


    const projectsDir = path.join(testDir, ".projects")
    const entries = await fs.readdir(projectsDir)
    expect(entries.length).toBe(2)


    expect(entries[0]).not.toBe(entries[1])
  })})
