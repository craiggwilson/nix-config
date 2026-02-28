/**
 * Tests for input validation schemas
 */

import { describe, test, expect } from "bun:test"

import {
  ProjectNameSchema,
  ProjectIdSchema,
  IssueIdSchema,
  IssueTitleSchema,
  PrioritySchema,
  LabelSchema,
  LabelsSchema,
  WorkspacePathSchema,
  TimeoutMsSchema,
  DelegationIdSchema,
  AgentNameSchema,
  AgentsSchema,
  ProjectCreateArgsSchema,
  ProjectFocusArgsSchema,
  ProjectWorkOnIssueArgsSchema,
  validateToolArgs,
  formatValidationError,
  InputValidationError,
} from "./input-schemas.js"

describe("ProjectNameSchema", () => {
  test("accepts valid project names", () => {
    const validNames = [
      "My Project",
      "project-123",
      "Test Project with Spaces",
      "a",
      "A".repeat(100),
    ]

    for (const name of validNames) {
      const result = ProjectNameSchema.safeParse(name)
      expect(result.success).toBe(true)
    }
  })

  test("rejects empty names", () => {
    const result = ProjectNameSchema.safeParse("")
    expect(result.success).toBe(false)
  })

  test("rejects names exceeding max length", () => {
    const result = ProjectNameSchema.safeParse("a".repeat(101))
    expect(result.success).toBe(false)
  })

  test("rejects path traversal sequences", () => {
    const maliciousNames = ["../etc/passwd", "project/../../../etc"]

    for (const name of maliciousNames) {
      const result = ProjectNameSchema.safeParse(name)
      expect(result.success).toBe(false)
    }
  })
})

describe("ProjectIdSchema", () => {
  test("accepts valid project IDs", () => {
    const validIds = [
      "my-project",
      "project123",
      "test_project",
      "MyProject",
      "abc",
      "project-with-many-hyphens",
    ]

    for (const id of validIds) {
      const result = ProjectIdSchema.safeParse(id)
      expect(result.success).toBe(true)
    }
  })

  test("rejects IDs that are too short", () => {
    const result = ProjectIdSchema.safeParse("ab")
    expect(result.success).toBe(false)
  })

  test("rejects IDs that are too long", () => {
    const result = ProjectIdSchema.safeParse("a".repeat(65))
    expect(result.success).toBe(false)
  })

  test("rejects IDs starting with non-alphanumeric", () => {
    const invalidIds = ["-project", "_project", ".project"]

    for (const id of invalidIds) {
      const result = ProjectIdSchema.safeParse(id)
      expect(result.success).toBe(false)
    }
  })

  test("rejects IDs with forbidden characters", () => {
    const forbiddenIds = [
      "project/subdir",
      "project\\subdir",
      "project:name",
      "project*name",
    ]

    for (const id of forbiddenIds) {
      const result = ProjectIdSchema.safeParse(id)
      expect(result.success).toBe(false)
    }
  })
})

describe("IssueIdSchema", () => {
  test("accepts valid issue IDs", () => {
    const validIds = [
      "issue-123",
      "bd-a3f8",
      "bd-a3f8.1",
      "bd-a3f8.1.2",
      "PROJ-123",
      "task_1",
      "a",
    ]

    for (const id of validIds) {
      const result = IssueIdSchema.safeParse(id)
      expect(result.success).toBe(true)
    }
  })

  test("rejects empty issue IDs", () => {
    const result = IssueIdSchema.safeParse("")
    expect(result.success).toBe(false)
  })

  test("rejects IDs with path traversal", () => {
    const maliciousIds = ["../etc/passwd", "issue/../../../etc"]

    for (const id of maliciousIds) {
      const result = IssueIdSchema.safeParse(id)
      expect(result.success).toBe(false)
    }
  })

  test("rejects IDs with slashes", () => {
    const result = IssueIdSchema.safeParse("issue/subissue")
    expect(result.success).toBe(false)
  })
})

describe("IssueTitleSchema", () => {
  test("accepts valid titles", () => {
    const validTitles = [
      "Fix bug in login",
      "Add new feature",
      "A",
      "Title with special chars: @#$%",
    ]

    for (const title of validTitles) {
      const result = IssueTitleSchema.safeParse(title)
      expect(result.success).toBe(true)
    }
  })

  test("rejects empty titles", () => {
    const result = IssueTitleSchema.safeParse("")
    expect(result.success).toBe(false)
  })

  test("rejects titles exceeding max length", () => {
    const result = IssueTitleSchema.safeParse("a".repeat(501))
    expect(result.success).toBe(false)
  })
})

describe("PrioritySchema", () => {
  test("accepts valid priorities", () => {
    for (const priority of [0, 1, 2, 3]) {
      const result = PrioritySchema.safeParse(priority)
      expect(result.success).toBe(true)
    }
  })

  test("accepts undefined (optional)", () => {
    const result = PrioritySchema.safeParse(undefined)
    expect(result.success).toBe(true)
  })

  test("rejects negative priorities", () => {
    const result = PrioritySchema.safeParse(-1)
    expect(result.success).toBe(false)
  })

  test("rejects priorities above 3", () => {
    const result = PrioritySchema.safeParse(4)
    expect(result.success).toBe(false)
  })

  test("rejects non-integer priorities", () => {
    const result = PrioritySchema.safeParse(1.5)
    expect(result.success).toBe(false)
  })
})

describe("LabelSchema", () => {
  test("accepts valid labels", () => {
    const validLabels = ["bug", "feature", "high-priority", "needs_review"]

    for (const label of validLabels) {
      const result = LabelSchema.safeParse(label)
      expect(result.success).toBe(true)
    }
  })

  test("rejects empty labels", () => {
    const result = LabelSchema.safeParse("")
    expect(result.success).toBe(false)
  })

  test("rejects labels with spaces", () => {
    const result = LabelSchema.safeParse("high priority")
    expect(result.success).toBe(false)
  })

  test("rejects labels starting with non-alphanumeric", () => {
    const result = LabelSchema.safeParse("-label")
    expect(result.success).toBe(false)
  })
})

describe("LabelsSchema", () => {
  test("accepts valid label arrays", () => {
    const result = LabelsSchema.safeParse(["bug", "feature", "urgent"])
    expect(result.success).toBe(true)
  })

  test("accepts empty arrays", () => {
    const result = LabelsSchema.safeParse([])
    expect(result.success).toBe(true)
  })

  test("accepts undefined (optional)", () => {
    const result = LabelsSchema.safeParse(undefined)
    expect(result.success).toBe(true)
  })

  test("rejects arrays with too many labels", () => {
    const tooManyLabels = Array.from({ length: 21 }, (_, i) => `label${i}`)
    const result = LabelsSchema.safeParse(tooManyLabels)
    expect(result.success).toBe(false)
  })

  test("rejects arrays with invalid labels", () => {
    const result = LabelsSchema.safeParse(["valid", "invalid label"])
    expect(result.success).toBe(false)
  })
})

describe("WorkspacePathSchema", () => {
  test("accepts valid absolute paths (Unix)", () => {
    const validPaths = ["/home/user/project", "/tmp/test", "/"]

    for (const p of validPaths) {
      const result = WorkspacePathSchema.safeParse(p)
      expect(result.success).toBe(true)
    }
  })

  test("accepts valid absolute paths (Windows)", () => {
    const validPaths = ["C:\\Users\\test", "D:/Projects/test"]

    for (const p of validPaths) {
      const result = WorkspacePathSchema.safeParse(p)
      expect(result.success).toBe(true)
    }
  })

  test("accepts undefined (optional)", () => {
    const result = WorkspacePathSchema.safeParse(undefined)
    expect(result.success).toBe(true)
  })

  test("rejects relative paths", () => {
    const relativePaths = ["./project", "project", "../parent"]

    for (const p of relativePaths) {
      const result = WorkspacePathSchema.safeParse(p)
      expect(result.success).toBe(false)
    }
  })

  test("rejects paths with traversal sequences", () => {
    const result = WorkspacePathSchema.safeParse("/home/user/../../../etc/passwd")
    expect(result.success).toBe(false)
  })
})

describe("TimeoutMsSchema", () => {
  test("accepts valid timeout values", () => {
    const validTimeouts = [1000, 30000, 60000, 3600000]

    for (const timeout of validTimeouts) {
      const result = TimeoutMsSchema.safeParse(timeout)
      expect(result.success).toBe(true)
    }
  })

  test("rejects timeouts below minimum", () => {
    const result = TimeoutMsSchema.safeParse(999)
    expect(result.success).toBe(false)
  })

  test("rejects timeouts above maximum", () => {
    const result = TimeoutMsSchema.safeParse(3600001)
    expect(result.success).toBe(false)
  })

  test("rejects non-integer timeouts", () => {
    const result = TimeoutMsSchema.safeParse(1000.5)
    expect(result.success).toBe(false)
  })

  test("rejects negative timeouts", () => {
    const result = TimeoutMsSchema.safeParse(-1000)
    expect(result.success).toBe(false)
  })
})

describe("DelegationIdSchema", () => {
  test("accepts valid delegation IDs", () => {
    const validIds = ["del-abc123", "delegation_1", "DEL-XYZ"]

    for (const id of validIds) {
      const result = DelegationIdSchema.safeParse(id)
      expect(result.success).toBe(true)
    }
  })

  test("rejects empty delegation IDs", () => {
    const result = DelegationIdSchema.safeParse("")
    expect(result.success).toBe(false)
  })

  test("rejects IDs with path traversal", () => {
    const result = DelegationIdSchema.safeParse("../etc/passwd")
    expect(result.success).toBe(false)
  })
})

describe("AgentNameSchema", () => {
  test("accepts valid agent names", () => {
    const validNames = [
      "typescript-expert",
      "codeReviewer",
      "agent_1",
      "TestAgent",
    ]

    for (const name of validNames) {
      const result = AgentNameSchema.safeParse(name)
      expect(result.success).toBe(true)
    }
  })

  test("rejects names starting with non-letter", () => {
    const invalidNames = ["1agent", "-agent", "_agent"]

    for (const name of invalidNames) {
      const result = AgentNameSchema.safeParse(name)
      expect(result.success).toBe(false)
    }
  })

  test("rejects empty names", () => {
    const result = AgentNameSchema.safeParse("")
    expect(result.success).toBe(false)
  })
})

describe("AgentsSchema", () => {
  test("accepts valid agent arrays", () => {
    const result = AgentsSchema.safeParse(["typescript-expert", "reviewer"])
    expect(result.success).toBe(true)
  })

  test("accepts undefined (optional)", () => {
    const result = AgentsSchema.safeParse(undefined)
    expect(result.success).toBe(true)
  })

  test("rejects empty arrays", () => {
    const result = AgentsSchema.safeParse([])
    expect(result.success).toBe(false)
  })

  test("rejects arrays with too many agents", () => {
    const tooManyAgents = Array.from({ length: 11 }, (_, i) => `agent${i}`)
    const result = AgentsSchema.safeParse(tooManyAgents)
    expect(result.success).toBe(false)
  })
})

describe("ProjectCreateArgsSchema", () => {
  test("accepts valid create args", () => {
    const validArgs = {
      name: "My New Project",
      type: "project" as const,
      storage: "global" as const,
      description: "A test project",
    }

    const result = ProjectCreateArgsSchema.safeParse(validArgs)
    expect(result.success).toBe(true)
  })

  test("accepts minimal args", () => {
    const result = ProjectCreateArgsSchema.safeParse({ name: "Test" })
    expect(result.success).toBe(true)
  })

  test("rejects missing name", () => {
    const result = ProjectCreateArgsSchema.safeParse({})
    expect(result.success).toBe(false)
  })

  test("rejects invalid type", () => {
    const result = ProjectCreateArgsSchema.safeParse({
      name: "Test",
      type: "invalid",
    })
    expect(result.success).toBe(false)
  })
})

describe("ProjectFocusArgsSchema", () => {
  test("accepts valid focus args", () => {
    const validArgs = {
      projectId: "my-project",
      issueId: "issue-123",
    }

    const result = ProjectFocusArgsSchema.safeParse(validArgs)
    expect(result.success).toBe(true)
  })

  test("accepts empty args (get current focus)", () => {
    const result = ProjectFocusArgsSchema.safeParse({})
    expect(result.success).toBe(true)
  })

  test("accepts clear flag", () => {
    const result = ProjectFocusArgsSchema.safeParse({ clear: true })
    expect(result.success).toBe(true)
  })

  test("rejects invalid project ID", () => {
    const result = ProjectFocusArgsSchema.safeParse({
      projectId: "../etc/passwd",
    })
    expect(result.success).toBe(false)
  })
})

describe("ProjectWorkOnIssueArgsSchema", () => {
  test("accepts valid work args", () => {
    const validArgs = {
      issueId: "issue-123",
      isolate: true,
      agents: ["typescript-expert"],
      foreground: false,
    }

    const result = ProjectWorkOnIssueArgsSchema.safeParse(validArgs)
    expect(result.success).toBe(true)
  })

  test("accepts minimal args", () => {
    const result = ProjectWorkOnIssueArgsSchema.safeParse({
      issueId: "issue-123",
    })
    expect(result.success).toBe(true)
  })

  test("rejects missing issue ID", () => {
    const result = ProjectWorkOnIssueArgsSchema.safeParse({})
    expect(result.success).toBe(false)
  })

  test("rejects invalid agent names", () => {
    const result = ProjectWorkOnIssueArgsSchema.safeParse({
      issueId: "issue-123",
      agents: ["1invalid"],
    })
    expect(result.success).toBe(false)
  })
})

describe("validateToolArgs", () => {
  test("returns ok result for valid args", () => {
    const result = validateToolArgs(ProjectCreateArgsSchema, { name: "Test" })
    expect(result.ok).toBe(true)
    if (result.ok) {
      expect(result.value.name).toBe("Test")
    }
  })

  test("returns error result for invalid args", () => {
    const result = validateToolArgs(ProjectCreateArgsSchema, {})
    expect(result.ok).toBe(false)
    if (!result.ok) {
      expect(result.error).toBeInstanceOf(InputValidationError)
      expect(result.error.field).toBe("name")
    }
  })
})

describe("formatValidationError", () => {
  test("formats error with field and message", () => {
    const error = new InputValidationError(
      "Invalid name: too short",
      "name",
      "",
      "Provide at least 3 characters"
    )

    const formatted = formatValidationError(error)

    expect(formatted).toContain("Validation Error")
    expect(formatted).toContain("name")
    expect(formatted).toContain("Invalid name: too short")
    expect(formatted).toContain("Provide at least 3 characters")
  })

  test("formats error without suggestion", () => {
    const error = new InputValidationError("Invalid value", "field", null)

    const formatted = formatValidationError(error)

    expect(formatted).toContain("Validation Error")
    expect(formatted).toContain("field")
    expect(formatted).not.toContain("Suggestion")
  })
})
