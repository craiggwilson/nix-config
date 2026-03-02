/**
 * Tests for project-save-artifact tool
 */

import { describe, test, expect, beforeAll, afterAll } from "bun:test"
import * as fs from "node:fs/promises"
import * as path from "node:path"
import * as os from "node:os"

import { createProjectCreate } from "./project-create.js"
import { createProjectSaveArtifact } from "./project-save-artifact.js"
import { ConfigManager } from "../config/index.js"
import { InMemoryIssueStorage } from "../issues/inmemory/index.js"
import { FocusManager, ProjectManager } from "../projects/index.js"
import {
  createMockLogger,
  createMockContext,
  createMockTeamManager,
} from "../utils/testing/index.js"

const mockLogger = createMockLogger()
const mockContext = createMockContext()

describe("project-save-artifact tool", () => {
  let testDir: string
  let projectManager: ProjectManager
  let issueStorage: InMemoryIssueStorage
  let projectId: string
  let projectDir: string

  beforeAll(async () => {
    testDir = await fs.mkdtemp(path.join(os.tmpdir(), "project-save-artifact-test-"))

    const config = await ConfigManager.loadOrThrow()
    issueStorage = new InMemoryIssueStorage({ prefix: "test" })
    const focus = new FocusManager()
    const teamManager = createMockTeamManager()

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

    // Create a project using the tool (which handles focus automatically)
    const createTool = createProjectCreate(projectManager, mockLogger)
    const createResult = await createTool.execute(
      {
        name: "Artifact Test Project",
        type: "project",
        storage: "local",
        description: "A project for testing artifacts",
      },
      mockContext
    )

    // Extract project ID from the result
    const idMatch = createResult.match(/\*\*ID:\*\* ([^\n]+)/)
    projectId = idMatch ? idMatch[1] : ""
    projectDir = (await projectManager.getProjectDir(projectId))!

    // Create a test artifact file inside the project
    const researchDir = path.join(projectDir, "research")
    await fs.mkdir(researchDir, { recursive: true })
    await fs.writeFile(
      path.join(researchDir, "test-research.md"),
      "# Test Research\n\nSome research content."
    )

    // Create a test artifact file outside the project (external)
    await fs.writeFile(
      path.join(testDir, "external-doc.md"),
      "# External Document\n\nSome external content."
    )
  })

  afterAll(async () => {
    try {
      await fs.rm(testDir, { recursive: true, force: true })
    } catch {
      // Ignore cleanup errors
    }
  })

  test("returns error when no project focused", async () => {
    // Clear focus
    projectManager.clearFocus()

    const tool = createProjectSaveArtifact(projectManager, mockLogger)

    const result = await tool.execute(
      {
        title: "Test Artifact",
        type: "research",
        path: "research/test-research.md",
      },
      mockContext
    )

    expect(result).toContain("No project focused")
    expect(result).toContain("project-focus")

    // Restore focus for other tests
    projectManager.setFocus(projectId)
  })

  test("registers artifact successfully", async () => {
    const tool = createProjectSaveArtifact(projectManager, mockLogger)

    const result = await tool.execute(
      {
        title: "Authentication Research",
        type: "research",
        path: path.join(projectDir, "research", "test-research.md"),
      },
      mockContext
    )

    expect(result).toContain("## Artifact Registered: Authentication Research")
    expect(result).toContain("**Type:** research")
    expect(result).toContain("**External:** No")
  })

  test("returns formatted response with artifact details", async () => {
    const tool = createProjectSaveArtifact(projectManager, mockLogger)

    // Create another test file
    await fs.writeFile(
      path.join(projectDir, "research", "api-patterns.md"),
      "# API Patterns\n\nResearch on API patterns."
    )

    const result = await tool.execute(
      {
        title: "API Patterns Analysis",
        type: "research",
        path: path.join(projectDir, "research", "api-patterns.md"),
        summary: "Analysis of REST vs GraphQL patterns",
        sourceIssue: "test-123.1",
      },
      mockContext
    )

    expect(result).toContain("**ID:**")
    expect(result).toContain("**Type:** research")
    expect(result).toContain("**Path:**")
    expect(result).toContain("**Source Issue:** test-123.1")
    expect(result).toContain("### Summary")
    expect(result).toContain("Analysis of REST vs GraphQL patterns")
  })

  test("handles external paths correctly", async () => {
    const tool = createProjectSaveArtifact(projectManager, mockLogger)

    const externalPath = path.join(testDir, "external-doc.md")

    const result = await tool.execute(
      {
        title: "External Documentation",
        type: "documentation",
        path: externalPath,
      },
      mockContext
    )

    expect(result).toContain("## Artifact Registered: External Documentation")
    expect(result).toContain("**Type:** documentation")
    expect(result).toContain("**External:** Yes (outside project directory)")
  })

  test("handles relative paths correctly", async () => {
    const tool = createProjectSaveArtifact(projectManager, mockLogger)

    // Create a file in the current working directory
    const relativeTestFile = path.join(process.cwd(), "relative-test-artifact.md")
    await fs.writeFile(relativeTestFile, "# Relative Test\n\nContent.")

    try {
      const result = await tool.execute(
        {
          title: "Relative Path Artifact",
          type: "deliverable",
          path: "relative-test-artifact.md",
        },
        mockContext
      )

      expect(result).toContain("## Artifact Registered: Relative Path Artifact")
      expect(result).toContain("**Type:** deliverable")
    } finally {
      // Clean up
      await fs.rm(relativeTestFile, { force: true })
    }
  })

  test("validates required fields - missing title", async () => {
    const tool = createProjectSaveArtifact(projectManager, mockLogger)

    const result = await tool.execute(
      {
        type: "research",
        path: "research/test.md",
      },
      mockContext
    )

    expect(result).toContain("## Validation Error")
    expect(result).toContain("**Field:** title")
  })

  test("validates required fields - missing type", async () => {
    const tool = createProjectSaveArtifact(projectManager, mockLogger)

    const result = await tool.execute(
      {
        title: "Test Artifact",
        path: "research/test.md",
      },
      mockContext
    )

    expect(result).toContain("## Validation Error")
    expect(result).toContain("**Field:** type")
  })

  test("validates required fields - missing path", async () => {
    const tool = createProjectSaveArtifact(projectManager, mockLogger)

    const result = await tool.execute(
      {
        title: "Test Artifact",
        type: "research",
      },
      mockContext
    )

    expect(result).toContain("## Validation Error")
    expect(result).toContain("**Field:** path")
  })

  test("validates required fields - empty title", async () => {
    const tool = createProjectSaveArtifact(projectManager, mockLogger)

    const result = await tool.execute(
      {
        title: "",
        type: "research",
        path: "research/test.md",
      },
      mockContext
    )

    expect(result).toContain("## Validation Error")
    expect(result).toContain("Title cannot be empty")
  })

  test("validates required fields - empty path", async () => {
    const tool = createProjectSaveArtifact(projectManager, mockLogger)

    const result = await tool.execute(
      {
        title: "Test Artifact",
        type: "research",
        path: "",
      },
      mockContext
    )

    expect(result).toContain("## Validation Error")
    expect(result).toContain("Path cannot be empty")
  })

  test("validates artifact type format", async () => {
    const tool = createProjectSaveArtifact(projectManager, mockLogger)

    const result = await tool.execute(
      {
        title: "Test Artifact",
        type: "Invalid Type!", // Invalid: contains uppercase and special chars
        path: "research/test.md",
      },
      mockContext
    )

    expect(result).toContain("## Validation Error")
    expect(result).toContain("lowercase alphanumeric")
  })
})
