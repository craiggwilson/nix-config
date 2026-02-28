/**
 * Zod schemas for validating user-provided inputs at API boundaries
 *
 * These schemas provide runtime validation for all tool handler inputs,
 * preventing security issues (path traversal) and reliability issues
 * (invalid values causing downstream errors).
 */

import { z } from "zod"
import type { Result, BaseError } from "../result/index.js"
import { ok, err } from "../result/index.js"

/**
 * Input validation error
 */
export class InputValidationError implements BaseError {
  readonly name = "InputValidationError"
  readonly code = "INPUT_VALIDATION_FAILED"
  readonly recoverable = true

  constructor(
    readonly message: string,
    readonly field: string,
    readonly value: unknown,
    readonly suggestion?: string,
    readonly cause?: unknown
  ) {}
}

/**
 * Characters forbidden in path-like identifiers
 */
const FORBIDDEN_PATH_CHARS = /[/\\:*?"<>|]/

/**
 * Path traversal patterns
 */
const PATH_TRAVERSAL_PATTERNS = [/\.\./, /^\.$/]

/**
 * Custom refinement for path-safe strings
 */
function isPathSafe(value: string): boolean {
  if (FORBIDDEN_PATH_CHARS.test(value)) return false
  for (const pattern of PATH_TRAVERSAL_PATTERNS) {
    if (pattern.test(value)) return false
  }
  return true
}

// ============================================================================
// Project Schemas
// ============================================================================

/**
 * Schema for project names (used during creation)
 * More permissive than project IDs since names are transformed into IDs
 */
export const ProjectNameSchema = z
  .string()
  .min(1, "Project name cannot be empty")
  .max(100, "Project name cannot exceed 100 characters")
  .refine(
    (val) => !PATH_TRAVERSAL_PATTERNS.some((p) => p.test(val)),
    "Project name cannot contain path traversal sequences"
  )

/**
 * Schema for project IDs (used for lookups)
 * Must be alphanumeric with hyphens/underscores, 3-64 chars
 */
export const ProjectIdSchema = z
  .string()
  .min(3, "Project ID must be at least 3 characters")
  .max(64, "Project ID cannot exceed 64 characters")
  .regex(
    /^[a-zA-Z0-9][a-zA-Z0-9_-]*$/,
    "Project ID must start with alphanumeric and contain only alphanumeric, hyphens, or underscores"
  )
  .refine(isPathSafe, "Project ID contains forbidden characters")

/**
 * Schema for optional project ID (defaults to focused project)
 */
export const OptionalProjectIdSchema = ProjectIdSchema.optional()

// ============================================================================
// Issue Schemas
// ============================================================================

/**
 * Schema for issue IDs
 * Allows hierarchical IDs like "bd-a3f8.1.2"
 */
export const IssueIdSchema = z
  .string()
  .min(1, "Issue ID cannot be empty")
  .max(128, "Issue ID cannot exceed 128 characters")
  .regex(
    /^[a-zA-Z0-9][a-zA-Z0-9_.-]*$/,
    "Issue ID must start with alphanumeric and contain only alphanumeric, hyphens, underscores, or dots"
  )
  .refine(isPathSafe, "Issue ID contains forbidden characters")

/**
 * Schema for optional issue ID
 */
export const OptionalIssueIdSchema = IssueIdSchema.optional()

/**
 * Schema for issue titles
 */
export const IssueTitleSchema = z
  .string()
  .min(1, "Issue title cannot be empty")
  .max(500, "Issue title cannot exceed 500 characters")

/**
 * Schema for issue descriptions
 */
export const IssueDescriptionSchema = z
  .string()
  .max(50000, "Issue description cannot exceed 50000 characters")
  .optional()

/**
 * Schema for priority values (0=highest, 3=lowest)
 */
export const PrioritySchema = z
  .number()
  .int("Priority must be an integer")
  .min(0, "Priority must be between 0 and 3")
  .max(3, "Priority must be between 0 and 3")
  .optional()

/**
 * Schema for labels
 */
export const LabelSchema = z
  .string()
  .min(1, "Label cannot be empty")
  .max(50, "Label cannot exceed 50 characters")
  .regex(/^[a-zA-Z0-9][a-zA-Z0-9_-]*$/, "Label must be alphanumeric with hyphens or underscores")

/**
 * Schema for label arrays
 */
export const LabelsSchema = z.array(LabelSchema).max(20, "Cannot have more than 20 labels").optional()

/**
 * Schema for blocked-by issue ID arrays
 */
export const BlockedBySchema = z
  .array(IssueIdSchema)
  .max(50, "Cannot have more than 50 blockers")
  .optional()

// ============================================================================
// Workspace/Path Schemas
// ============================================================================

/**
 * Schema for workspace paths
 * Must be absolute paths without traversal sequences
 */
export const WorkspacePathSchema = z
  .string()
  .min(1, "Workspace path cannot be empty")
  .max(4096, "Workspace path cannot exceed 4096 characters")
  .refine(
    (val) => val.startsWith("/") || /^[A-Za-z]:[\\/]/.test(val),
    "Workspace path must be absolute"
  )
  .refine(
    (val) => !val.includes(".."),
    "Workspace path cannot contain path traversal sequences"
  )
  .optional()

// ============================================================================
// Delegation/Timeout Schemas
// ============================================================================

/**
 * Schema for timeout values in milliseconds
 */
export const TimeoutMsSchema = z
  .number()
  .int("Timeout must be an integer")
  .min(1000, "Timeout must be at least 1 second (1000ms)")
  .max(3600000, "Timeout cannot exceed 1 hour (3600000ms)")

/**
 * Schema for delegation IDs
 */
export const DelegationIdSchema = z
  .string()
  .min(1, "Delegation ID cannot be empty")
  .max(128, "Delegation ID cannot exceed 128 characters")
  .regex(
    /^[a-zA-Z0-9][a-zA-Z0-9_-]*$/,
    "Delegation ID must start with alphanumeric and contain only alphanumeric, hyphens, or underscores"
  )
  .refine(isPathSafe, "Delegation ID contains forbidden characters")

// ============================================================================
// Agent Schemas
// ============================================================================

/**
 * Schema for agent names
 */
export const AgentNameSchema = z
  .string()
  .min(1, "Agent name cannot be empty")
  .max(64, "Agent name cannot exceed 64 characters")
  .regex(
    /^[a-zA-Z][a-zA-Z0-9_-]*$/,
    "Agent name must start with a letter and contain only alphanumeric, hyphens, or underscores"
  )

/**
 * Schema for agent name arrays
 */
export const AgentsSchema = z
  .array(AgentNameSchema)
  .min(1, "Must specify at least one agent")
  .max(10, "Cannot have more than 10 agents")
  .optional()

// ============================================================================
// Composite Schemas for Tool Arguments
// ============================================================================

/**
 * Schema for project-create arguments
 */
export const ProjectCreateArgsSchema = z.object({
  name: ProjectNameSchema,
  type: z.enum(["roadmap", "project"]).optional(),
  workspace: WorkspacePathSchema,
  storage: z.enum(["local", "global"]).optional(),
  description: z.string().max(5000, "Description cannot exceed 5000 characters").optional(),
})

/**
 * Schema for project-focus arguments
 */
export const ProjectFocusArgsSchema = z.object({
  projectId: OptionalProjectIdSchema,
  clear: z.boolean().optional(),
})

/**
 * Schema for project-close arguments
 */
export const ProjectCloseArgsSchema = z.object({
  projectId: ProjectIdSchema,
  reason: z.enum(["completed", "cancelled", "archived"]).optional(),
  summary: z.string().max(10000, "Summary cannot exceed 10000 characters").optional(),
})

/**
 * Schema for project-list arguments
 */
export const ProjectListArgsSchema = z.object({
  scope: z.enum(["local", "global", "all"]).optional(),
  status: z.enum(["active", "completed", "all"]).optional(),
})

/**
 * Schema for project-status arguments
 */
export const ProjectStatusArgsSchema = z.object({
  projectId: OptionalProjectIdSchema,
  format: z.enum(["summary", "detailed", "tree"]).optional(),
})

/**
 * Schema for project-create-issue arguments
 */
export const ProjectCreateIssueArgsSchema = z.object({
  title: IssueTitleSchema,
  projectId: OptionalProjectIdSchema,
  description: IssueDescriptionSchema,
  priority: PrioritySchema,
  parent: OptionalIssueIdSchema,
  blockedBy: BlockedBySchema,
  labels: LabelsSchema,
})

/**
 * Schema for project-update-issue arguments
 */
export const ProjectUpdateIssueArgsSchema = z.object({
  issueId: IssueIdSchema,
  projectId: OptionalProjectIdSchema,
  status: z.enum(["open", "in_progress", "closed"]).optional(),
  assignee: z.string().max(100, "Assignee cannot exceed 100 characters").optional(),
  priority: PrioritySchema,
  description: IssueDescriptionSchema,
  labels: LabelsSchema,
  blockedBy: BlockedBySchema,
  mergeWorktree: z.boolean().optional(),
  mergeStrategy: z.enum(["squash", "merge", "rebase"]).optional(),
  comment: z.string().max(10000, "Comment cannot exceed 10000 characters").optional(),
  artifacts: z.array(z.string().max(500)).max(50, "Cannot have more than 50 artifacts").optional(),
})

/**
 * Schema for project-work-on-issue arguments
 */
export const ProjectWorkOnIssueArgsSchema = z.object({
  issueId: IssueIdSchema,
  isolate: z.boolean().optional(),
  agents: AgentsSchema,
  foreground: z.boolean().optional(),
})

/**
 * Schema for project-internal-delegation-read arguments
 */
export const ProjectDelegationReadArgsSchema = z.object({
  id: DelegationIdSchema,
  projectId: OptionalProjectIdSchema,
})

/**
 * Schema for project-plan arguments
 */
export const ProjectPlanArgsSchema = z.object({
  projectId: OptionalProjectIdSchema,
  action: z.enum(["start", "continue", "save", "advance", "phase", "status"]).optional(),
  phase: z.enum(["discovery", "synthesis", "breakdown", "complete"]).optional(),
  understanding: z.string().max(50000, "Understanding cannot exceed 50000 characters").optional(),
  openQuestions: z.string().max(5000, "Open questions cannot exceed 5000 characters").optional(),
})

// ============================================================================
// Validation Helper Functions
// ============================================================================

/**
 * Validate input against a schema and return a Result
 */
export function validateInput<T>(
  schema: z.ZodType<T>,
  input: unknown,
  fieldName: string = "input"
): Result<T, InputValidationError> {
  const result = schema.safeParse(input)

  if (!result.success) {
    const firstIssue = result.error.issues[0]
    const path = firstIssue?.path.join(".") || fieldName
    const message = firstIssue?.message || "Validation failed"

    return err(
      new InputValidationError(
        `Invalid ${path}: ${message}`,
        path,
        input,
        getSuggestion(firstIssue),
        result.error
      )
    )
  }

  return ok(result.data)
}

/**
 * Validate tool arguments and return a Result
 */
export function validateToolArgs<T>(
  schema: z.ZodType<T>,
  args: unknown
): Result<T, InputValidationError> {
  return validateInput(schema, args, "arguments")
}

/**
 * Format a validation error for user display
 */
export function formatValidationError(error: InputValidationError): string {
  const lines: string[] = []

  lines.push(`## Validation Error`)
  lines.push("")
  lines.push(`**Field:** ${error.field}`)
  lines.push(`**Error:** ${error.message}`)

  if (error.suggestion) {
    lines.push("")
    lines.push(`**Suggestion:** ${error.suggestion}`)
  }

  return lines.join("\n")
}

/**
 * Get a helpful suggestion based on the validation issue
 */
function getSuggestion(issue: z.core.$ZodIssue | undefined): string | undefined {
  if (!issue) return undefined

  const path = issue.path.join(".")
  const issueAny = issue as unknown as Record<string, unknown>

  if (issue.code === "too_small" && typeof issueAny.minimum === "number") {
    return `Provide a value with at least ${issueAny.minimum} characters`
  }

  if (issue.code === "too_big" && typeof issueAny.maximum === "number") {
    return `Reduce the value to at most ${issueAny.maximum} characters`
  }

  if (issue.code === "invalid_format" && issueAny.format === "regex") {
    if (path.includes("projectId") || path.includes("issueId")) {
      return "Use only alphanumeric characters, hyphens, and underscores"
    }
    if (path.includes("agent")) {
      return "Agent names must start with a letter and contain only alphanumeric characters, hyphens, or underscores"
    }
  }

  if (issue.code === "custom" && issue.message.includes("path traversal")) {
    return "Remove any '..' or '.' sequences from the value"
  }

  if (issue.code === "custom" && issue.message.includes("absolute")) {
    return "Provide an absolute path starting with '/' (Unix) or 'C:\\' (Windows)"
  }

  return undefined
}

// ============================================================================
// Type Exports
// ============================================================================

export type ProjectCreateArgs = z.infer<typeof ProjectCreateArgsSchema>
export type ProjectFocusArgs = z.infer<typeof ProjectFocusArgsSchema>
export type ProjectCloseArgs = z.infer<typeof ProjectCloseArgsSchema>
export type ProjectListArgs = z.infer<typeof ProjectListArgsSchema>
export type ProjectStatusArgs = z.infer<typeof ProjectStatusArgsSchema>
export type ProjectCreateIssueArgs = z.infer<typeof ProjectCreateIssueArgsSchema>
export type ProjectUpdateIssueArgs = z.infer<typeof ProjectUpdateIssueArgsSchema>
export type ProjectWorkOnIssueArgs = z.infer<typeof ProjectWorkOnIssueArgsSchema>
export type ProjectDelegationReadArgs = z.infer<typeof ProjectDelegationReadArgsSchema>
export type ProjectPlanArgs = z.infer<typeof ProjectPlanArgsSchema>
