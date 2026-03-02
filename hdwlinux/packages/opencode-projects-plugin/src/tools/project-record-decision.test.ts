/**
 * Tests for project-record-decision tool
 */

import { describe, test, expect, beforeAll, afterAll } from "bun:test"
import * as fs from "node:fs/promises"
import * as path from "node:path"
import * as os from "node:os"

import { createProjectCreate } from "./project-create.js"
import { createProjectRecordDecision } from "./project-record-decision.js"
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

describe("project-record-decision tool", () => {
  let testDir: string
  let projectManager: ProjectManager
  let issueStorage: InMemoryIssueStorage
  let projectId: string

  beforeAll(async () => {
    testDir = await fs.mkdtemp(path.join(os.tmpdir(), "project-record-decision-test-"))

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
        name: "Decision Test Project",
        type: "project",
        storage: "local",
        description: "A project for testing decisions",
      },
      mockContext
    )

    // Extract project ID from the result
    const idMatch = createResult.match(/\*\*ID:\*\* ([^\n]+)/)
    projectId = idMatch ? idMatch[1] : ""
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

    const tool = createProjectRecordDecision(projectManager, mockLogger)

    const result = await tool.execute(
      {
        title: "Test Decision",
        decision: "We decided to use X",
        rationale: "Because X is better",
      },
      mockContext
    )

    expect(result).toContain("No project focused")
    expect(result).toContain("project-focus")

    // Restore focus for other tests
    projectManager.setFocus(projectId)
  })

  test("records decision successfully", async () => {
    const tool = createProjectRecordDecision(projectManager, mockLogger)

    const result = await tool.execute(
      {
        title: "Use OAuth2 over SAML",
        decision: "We will use OAuth2 for authentication",
        rationale: "OAuth2 has better library support and is simpler to implement",
      },
      mockContext
    )

    expect(result).toContain("## Decision Recorded: Use OAuth2 over SAML")
    expect(result).toContain("**Status:** decided")
    expect(result).toContain("### Decision")
    expect(result).toContain("We will use OAuth2 for authentication")
    expect(result).toContain("### Rationale")
    expect(result).toContain("OAuth2 has better library support")
  })

  test("returns formatted response with decision details", async () => {
    const tool = createProjectRecordDecision(projectManager, mockLogger)

    const result = await tool.execute(
      {
        title: "Use PostgreSQL for persistence",
        decision: "PostgreSQL will be our primary database",
        rationale: "Strong ACID compliance and JSON support",
        status: "proposed",
      },
      mockContext
    )

    expect(result).toContain("**ID:**")
    expect(result).toContain("**Status:** proposed")
    expect(result).toContain("**File:**")
    expect(result).toMatch(/use-postgresql-for-persistence\.md/)
  })

  test("handles alternatives", async () => {
    const tool = createProjectRecordDecision(projectManager, mockLogger)

    const result = await tool.execute(
      {
        title: "Use React for frontend",
        decision: "React will be our frontend framework",
        rationale: "Large ecosystem and team familiarity",
        alternatives: [
          {
            name: "Vue.js",
            description: "Progressive framework with simpler learning curve",
            whyRejected: "Team has more React experience",
          },
          {
            name: "Svelte",
            description: "Compile-time framework with smaller bundle size",
            whyRejected: "Smaller ecosystem and fewer available libraries",
          },
        ],
      },
      mockContext
    )

    expect(result).toContain("### Alternatives Considered")
    expect(result).toContain("**Vue.js**")
    expect(result).toContain("Progressive framework with simpler learning curve")
    expect(result).toContain("*Why rejected:* Team has more React experience")
    expect(result).toContain("**Svelte**")
    expect(result).toContain("*Why rejected:* Smaller ecosystem")
  })

  test("handles source research links", async () => {
    const tool = createProjectRecordDecision(projectManager, mockLogger)

    const result = await tool.execute(
      {
        title: "Use GraphQL API",
        decision: "GraphQL will be our API layer",
        rationale: "Better client flexibility and reduced over-fetching",
        sourceResearch: ["research-api-patterns-abc123", "research-graphql-perf-def456"],
      },
      mockContext
    )

    // The tool records the decision successfully even with source research
    expect(result).toContain("## Decision Recorded: Use GraphQL API")
    expect(result).toContain("**Status:** decided")
  })

  test("handles related issues", async () => {
    const tool = createProjectRecordDecision(projectManager, mockLogger)

    const result = await tool.execute(
      {
        title: "Use Kubernetes for deployment",
        decision: "Kubernetes will be our container orchestration platform",
        rationale: "Industry standard with good tooling support",
        relatedIssues: ["test-123.1", "test-123.2"],
      },
      mockContext
    )

    expect(result).toContain("## Decision Recorded: Use Kubernetes for deployment")
    expect(result).toContain("**Status:** decided")
  })

  test("validates required fields - missing title", async () => {
    const tool = createProjectRecordDecision(projectManager, mockLogger)

    const result = await tool.execute(
      {
        decision: "We decided to use X",
        rationale: "Because X is better",
      },
      mockContext
    )

    expect(result).toContain("## Validation Error")
    expect(result).toContain("**Field:** title")
  })

  test("validates required fields - missing decision", async () => {
    const tool = createProjectRecordDecision(projectManager, mockLogger)

    const result = await tool.execute(
      {
        title: "Test Decision",
        rationale: "Because X is better",
      },
      mockContext
    )

    expect(result).toContain("## Validation Error")
    expect(result).toContain("**Field:** decision")
  })

  test("validates required fields - missing rationale", async () => {
    const tool = createProjectRecordDecision(projectManager, mockLogger)

    const result = await tool.execute(
      {
        title: "Test Decision",
        decision: "We decided to use X",
      },
      mockContext
    )

    expect(result).toContain("## Validation Error")
    expect(result).toContain("**Field:** rationale")
  })

  test("validates required fields - empty title", async () => {
    const tool = createProjectRecordDecision(projectManager, mockLogger)

    const result = await tool.execute(
      {
        title: "",
        decision: "We decided to use X",
        rationale: "Because X is better",
      },
      mockContext
    )

    expect(result).toContain("## Validation Error")
    expect(result).toContain("Title cannot be empty")
  })
})
