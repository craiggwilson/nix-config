/**
 * Zod schemas for beads CLI JSON responses
 *
 * Provides runtime validation for all beads command outputs to prevent
 * silent data corruption if beads changes its output format.
 */

import { z } from "zod"
import type { Issue, IssueStatus } from "../issue-storage.js"
import type { BaseError, Result } from "../../utils/result/index.js"

/**
 * Beads error discriminated union
 */
export type BeadsError =
  | BeadsNotAvailableError
  | BeadsCommandFailedError
  | BeadsParseError
  | BeadsTimeoutError

/**
 * Error when beads CLI is not available
 */
export class BeadsNotAvailableError implements BaseError {
  readonly name = "BeadsNotAvailableError"
  readonly code = "BEADS_NOT_AVAILABLE"
  readonly recoverable = false
  readonly suggestion = "Install beads CLI from https://github.com/steveyegge/beads"

  constructor(
    public readonly message: string = "beads (bd) CLI not found in PATH",
    public readonly cause?: unknown
  ) {}
}

/**
 * Error when a beads command fails
 */
export class BeadsCommandFailedError implements BaseError {
  readonly name = "BeadsCommandFailedError"
  readonly code = "BEADS_COMMAND_FAILED"
  readonly recoverable = true

  constructor(
    public readonly message: string,
    public readonly stderr: string,
    public readonly exitCode: number,
    public readonly suggestion?: string,
    public readonly cause?: unknown
  ) {}
}

/**
 * Error when parsing beads output fails
 */
export class BeadsParseError implements BaseError {
  readonly name = "BeadsParseError"
  readonly code = "BEADS_PARSE_ERROR"
  readonly recoverable = false
  readonly suggestion = "This may indicate a beads CLI version mismatch or corrupted output"

  constructor(
    public readonly message: string,
    public readonly zodError?: z.ZodError,
    public readonly cause?: unknown
  ) {}
}

/**
 * Error when a beads command times out
 */
export class BeadsTimeoutError implements BaseError {
  readonly name = "BeadsTimeoutError"
  readonly code = "BEADS_TIMEOUT"
  readonly recoverable = true
  readonly suggestion = "Try again or increase the timeout value"

  constructor(
    public readonly message: string,
    public readonly timeoutMs: number,
    public readonly cause?: unknown
  ) {}
}

/**
 * Schema for beads issue status
 */
const BeadsStatusSchema = z
  .enum(["todo", "open", "in_progress", "in-progress", "active", "done", "closed", "completed"])
  .transform((val): IssueStatus => {
    const normalized = val.toLowerCase()
    if (normalized === "todo" || normalized === "open") return "open"
    if (normalized === "in_progress" || normalized === "in-progress" || normalized === "active")
      return "in_progress"
    if (normalized === "done" || normalized === "closed" || normalized === "completed")
      return "closed"
    return "open"
  })

/**
 * Schema for a single beads issue from JSON output
 */
export const BeadsIssueSchema = z.object({
  id: z.string().min(1),
  title: z.string().min(1),
  description: z.string().optional(),
  status: BeadsStatusSchema,
  priority: z.number().int().min(0).max(3).default(2),
  assignee: z.string().optional(),
  parent: z.string().optional(),
  blocked_by: z.array(z.string()).default([]),
  labels: z.array(z.string()).default([]),
  created_at: z.string().optional(),
  updated_at: z.string().optional(),
})

/**
 * Schema for beads list/show/tree commands (array of issues)
 */
export const BeadsIssueArraySchema = z.array(BeadsIssueSchema)

/**
 * Type inferred from BeadsIssueSchema
 */
export type BeadsIssueRaw = z.infer<typeof BeadsIssueSchema>

/**
 * Parse and validate a beads issue from raw JSON data
 */
export function parseBeadsIssue(data: unknown): Result<Issue, BeadsParseError> {
  const result = BeadsIssueSchema.safeParse(data)

  if (!result.success) {
    return {
      ok: false,
      error: new BeadsParseError(
        `Invalid beads issue data: ${result.error.message}`,
        result.error
      ),
    }
  }

  const issue = result.data
  return {
    ok: true,
    value: {
      id: issue.id,
      title: issue.title,
      description: issue.description,
      status: issue.status,
      priority: issue.priority,
      assignee: issue.assignee,
      parent: issue.parent,
      blockedBy: issue.blocked_by,
      labels: issue.labels,
      createdAt: issue.created_at || new Date().toISOString(),
      updatedAt: issue.updated_at || new Date().toISOString(),
    },
  }
}

/**
 * Parse and validate an array of beads issues from raw JSON data
 */
export function parseBeadsIssueArray(data: unknown): Result<Issue[], BeadsParseError> {
  const result = BeadsIssueArraySchema.safeParse(data)

  if (!result.success) {
    return {
      ok: false,
      error: new BeadsParseError(
        `Invalid beads issue array data: ${result.error.message}`,
        result.error
      ),
    }
  }

  const issues: Issue[] = result.data.map((issue) => ({
    id: issue.id,
    title: issue.title,
    description: issue.description,
    status: issue.status,
    priority: issue.priority,
    assignee: issue.assignee,
    parent: issue.parent,
    blockedBy: issue.blocked_by,
    labels: issue.labels,
    createdAt: issue.created_at || new Date().toISOString(),
    updatedAt: issue.updated_at || new Date().toISOString(),
  }))

  return { ok: true, value: issues }
}

/**
 * Parse JSON string safely
 */
export function parseJSON(jsonString: string): Result<unknown, BeadsParseError> {
  try {
    const parsed = JSON.parse(jsonString)
    return { ok: true, value: parsed }
  } catch (error) {
    return {
      ok: false,
      error: new BeadsParseError(
        `Failed to parse JSON: ${error instanceof Error ? error.message : String(error)}`,
        undefined,
        error
      ),
    }
  }
}
