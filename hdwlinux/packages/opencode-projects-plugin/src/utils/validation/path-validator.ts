/**
 * Path validation utilities
 *
 * Provides validation for identifiers used in file path construction
 * to prevent path traversal attacks.
 */

import * as path from "node:path"

import type { Result } from "../result/index.js"
import { ok, err } from "../result/index.js"
import type { VCSError } from "../errors/index.js"
import { WorktreeError } from "../errors/index.js"

/**
 * Pattern for valid project IDs
 * Allows alphanumeric characters, hyphens, and underscores
 * Must start with alphanumeric, 3-64 characters
 */
const PROJECT_ID_PATTERN = /^[a-zA-Z0-9][a-zA-Z0-9_-]{2,63}$/

/**
 * Pattern for valid issue IDs
 * Allows alphanumeric characters, hyphens, underscores, and dots (for hierarchical IDs like bd-a3f8.1)
 * Must start with alphanumeric, 1-128 characters
 */
const ISSUE_ID_PATTERN = /^[a-zA-Z0-9][a-zA-Z0-9_.-]{0,127}$/

/**
 * Characters that are never allowed in path components
 */
const FORBIDDEN_CHARS = /[/\\:*?"<>|]/

/**
 * Path traversal patterns to detect
 */
const PATH_TRAVERSAL_PATTERNS = [
  /\.\./,           // Parent directory reference
  /^\.$/,           // Current directory reference at start
  /\/\.\//,         // Current directory in path
  /\\\.\\/,         // Windows current directory in path
]

/**
 * Validation result with detailed error information
 */
export interface PathValidationError {
  type: "invalid_format" | "forbidden_chars" | "path_traversal" | "path_escape"
  message: string
  value: string
}

/**
 * Validates a project ID for safe use in file paths
 *
 * @param projectId - The project ID to validate
 * @returns Result with the validated ID or an error
 */
export function validateProjectId(projectId: string): Result<string, PathValidationError> {
  if (!projectId || typeof projectId !== "string") {
    return err({
      type: "invalid_format",
      message: "Project ID must be a non-empty string",
      value: String(projectId),
    })
  }

  if (FORBIDDEN_CHARS.test(projectId)) {
    return err({
      type: "forbidden_chars",
      message: "Project ID contains forbidden characters (/, \\, :, *, ?, \", <, >, |)",
      value: projectId,
    })
  }

  for (const pattern of PATH_TRAVERSAL_PATTERNS) {
    if (pattern.test(projectId)) {
      return err({
        type: "path_traversal",
        message: "Project ID contains path traversal sequence",
        value: projectId,
      })
    }
  }

  if (!PROJECT_ID_PATTERN.test(projectId)) {
    return err({
      type: "invalid_format",
      message: "Project ID must be 3-64 characters, start with alphanumeric, and contain only alphanumeric, hyphens, or underscores",
      value: projectId,
    })
  }

  return ok(projectId)
}

/**
 * Validates an issue ID for safe use in file paths
 *
 * @param issueId - The issue ID to validate
 * @returns Result with the validated ID or an error
 */
export function validateIssueId(issueId: string): Result<string, PathValidationError> {
  if (!issueId || typeof issueId !== "string") {
    return err({
      type: "invalid_format",
      message: "Issue ID must be a non-empty string",
      value: String(issueId),
    })
  }

  if (FORBIDDEN_CHARS.test(issueId)) {
    return err({
      type: "forbidden_chars",
      message: "Issue ID contains forbidden characters (/, \\, :, *, ?, \", <, >, |)",
      value: issueId,
    })
  }

  for (const pattern of PATH_TRAVERSAL_PATTERNS) {
    if (pattern.test(issueId)) {
      return err({
        type: "path_traversal",
        message: "Issue ID contains path traversal sequence",
        value: issueId,
      })
    }
  }

  if (!ISSUE_ID_PATTERN.test(issueId)) {
    return err({
      type: "invalid_format",
      message: "Issue ID must be 1-128 characters, start with alphanumeric, and contain only alphanumeric, hyphens, underscores, or dots",
      value: issueId,
    })
  }

  return ok(issueId)
}

/**
 * Sanitizes a string for safe use in file paths by replacing unsafe characters
 *
 * This is a fallback for cases where strict validation isn't possible.
 * Prefer validateProjectId/validateIssueId when possible.
 *
 * @param input - The string to sanitize
 * @returns Sanitized string safe for use in paths
 */
export function sanitizePathComponent(input: string): string {
  if (!input || typeof input !== "string") {
    return ""
  }

  // Replace all potentially dangerous characters with hyphens
  // Note: We explicitly do NOT allow / or \ as they enable path traversal
  return input
    .replace(/[/\\:*?"<>|]/g, "-")  // Replace forbidden chars
    .replace(/\.\./g, "-")          // Replace parent directory references
    .replace(/^\./, "-")            // Replace leading dot
    .replace(/-+/g, "-")            // Collapse multiple hyphens
    .replace(/^-|-$/g, "")          // Trim leading/trailing hyphens
    .slice(0, 128)                  // Limit length
}

/**
 * Creates a safe worktree name from project and issue IDs
 *
 * Validates both IDs and returns the issue ID as the worktree name.
 * Since issue IDs already contain the project ID as a prefix (e.g.,
 * `convergent-team-discussion-2c57d5-4by.37`), prepending the project ID
 * again would be redundant.
 *
 * @param projectId - The project ID (validated but not included in the name)
 * @param issueId - The issue ID
 * @returns Result with the safe worktree name or a VCSError
 */
export function createSafeWorktreeName(
  projectId: string,
  issueId: string
): Result<string, VCSError> {
  const projectResult = validateProjectId(projectId)
  if (!projectResult.ok) {
    return err(
      new WorktreeError(
        "create",
        `Invalid project ID: ${projectResult.error.message}`
      )
    )
  }

  const issueResult = validateIssueId(issueId)
  if (!issueResult.ok) {
    return err(
      new WorktreeError(
        "create",
        `Invalid issue ID: ${issueResult.error.message}`
      )
    )
  }

  return ok(issueResult.value)
}

/**
 * Validates that a constructed path stays within the expected base directory
 *
 * This is a defense-in-depth check after path construction.
 *
 * @param basePath - The expected base directory (must be absolute)
 * @param constructedPath - The path to validate (must be absolute)
 * @returns Result indicating if the path is safe
 */
export function validatePathBoundary(
  basePath: string,
  constructedPath: string
): Result<string, PathValidationError> {
  // Normalize both paths to resolve any . or .. that might have slipped through
  const normalizedBase = path.resolve(basePath)
  const normalizedPath = path.resolve(constructedPath)

  // Check that the constructed path starts with the base path
  // We add a path separator to prevent prefix attacks (e.g., /base-evil matching /base)
  const baseWithSep = normalizedBase.endsWith(path.sep)
    ? normalizedBase
    : normalizedBase + path.sep

  if (!normalizedPath.startsWith(baseWithSep) && normalizedPath !== normalizedBase) {
    return err({
      type: "path_escape",
      message: `Path '${constructedPath}' escapes base directory '${basePath}'`,
      value: constructedPath,
    })
  }

  return ok(normalizedPath)
}
