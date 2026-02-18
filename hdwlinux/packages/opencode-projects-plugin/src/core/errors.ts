/**
 * Custom error types for the opencode-projects plugin
 */

/**
 * Base error class for all plugin errors
 */
export class ProjectsPluginError extends Error {
  constructor(
    message: string,
    public readonly code: string,
    public readonly recoverable: boolean = true,
    public readonly suggestion?: string
  ) {
    super(message)
    this.name = "ProjectsPluginError"
  }
}

/**
 * Error when a project is not found
 */
export class ProjectNotFoundError extends ProjectsPluginError {
  constructor(projectId: string) {
    super(
      `Project '${projectId}' not found`,
      "PROJECT_NOT_FOUND",
      true,
      "Use `project_list` to see available projects, or `project_create` to create a new one."
    )
    this.name = "ProjectNotFoundError"
  }
}

/**
 * Error when an issue is not found
 */
export class IssueNotFoundError extends ProjectsPluginError {
  constructor(issueId: string, projectId?: string) {
    const context = projectId ? ` in project '${projectId}'` : ""
    super(
      `Issue '${issueId}' not found${context}`,
      "ISSUE_NOT_FOUND",
      true,
      "Use `project_status` to see available issues."
    )
    this.name = "IssueNotFoundError"
  }
}

/**
 * Error when beads CLI is not available
 */
export class BeadsNotAvailableError extends ProjectsPluginError {
  constructor() {
    super(
      "beads (bd) CLI not found in PATH",
      "BEADS_NOT_AVAILABLE",
      false,
      "Install beads from https://github.com/hdwlinux/beads or use in-memory storage."
    )
    this.name = "BeadsNotAvailableError"
  }
}

/**
 * Error when VCS is not detected
 */
export class VCSNotDetectedError extends ProjectsPluginError {
  constructor(directory: string) {
    super(
      `No version control system detected in '${directory}'`,
      "VCS_NOT_DETECTED",
      true,
      "Initialize a git or jj repository first."
    )
    this.name = "VCSNotDetectedError"
  }
}

/**
 * Error when a worktree operation fails
 */
export class WorktreeError extends ProjectsPluginError {
  constructor(operation: string, details: string) {
    super(
      `Worktree ${operation} failed: ${details}`,
      "WORKTREE_ERROR",
      true,
      "Check VCS status and try again."
    )
    this.name = "WorktreeError"
  }
}

/**
 * Error when merge conflicts occur
 */
export class MergeConflictError extends ProjectsPluginError {
  constructor(public readonly conflictFiles: string[]) {
    super(
      `Merge conflicts in ${conflictFiles.length} file(s)`,
      "MERGE_CONFLICT",
      true,
      "Resolve conflicts manually, then retry the merge."
    )
    this.name = "MergeConflictError"
  }
}

/**
 * Error when no project is focused
 */
export class NoProjectFocusedError extends ProjectsPluginError {
  constructor() {
    super(
      "No project is currently focused",
      "NO_PROJECT_FOCUSED",
      true,
      "Use `project_focus(projectId)` to set context, or provide projectId explicitly."
    )
    this.name = "NoProjectFocusedError"
  }
}

/**
 * Error when configuration is invalid
 */
export class ConfigurationError extends ProjectsPluginError {
  constructor(field: string, message: string) {
    super(
      `Configuration error in '${field}': ${message}`,
      "CONFIGURATION_ERROR",
      true,
      "Check your opencode-projects.json configuration file."
    )
    this.name = "ConfigurationError"
  }
}

/**
 * Format an error for display to the user
 */
export function formatError(error: unknown): string {
  if (error instanceof ProjectsPluginError) {
    const lines = [error.message]
    if (error.suggestion) {
      lines.push("")
      lines.push(`**Suggestion:** ${error.suggestion}`)
    }
    return lines.join("\n")
  }

  if (error instanceof Error) {
    return error.message
  }

  return String(error)
}
