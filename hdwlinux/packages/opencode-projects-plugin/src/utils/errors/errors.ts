/**
 * Custom error types for the opencode-projects plugin
 */

import * as os from "node:os";

import type { BaseError } from "../result/index.js";

/**
 * Patterns that indicate sensitive data in error messages.
 * Order matters - more specific patterns should come before generic ones.
 */
const SENSITIVE_PATTERNS: Array<{ pattern: RegExp; replacement: string }> = [
	// SSH private key markers (most specific, check first)
	{
		pattern:
			/-----BEGIN[^-]+PRIVATE KEY-----[\s\S]*?-----END[^-]+PRIVATE KEY-----/g,
		replacement: "[PRIVATE_KEY_REDACTED]",
	},
	// Generic bearer tokens (before generic token pattern)
	{
		pattern: /Bearer\s+[A-Za-z0-9\-_.~+/]+=*/gi,
		replacement: "Bearer [REDACTED]",
	},
	// AWS credentials
	{
		pattern: /\b(AKIA|ABIA|ACCA|ASIA)[A-Z0-9]{16}\b/g,
		replacement: "[AWS_KEY_REDACTED]",
	},
	// GitHub tokens
	{
		pattern: /\b(ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9_]{36,}\b/g,
		replacement: "[GITHUB_TOKEN_REDACTED]",
	},
	// Connection strings with credentials
	{ pattern: /:\/\/[^:]+:[^@]+@/g, replacement: "://[CREDENTIALS_REDACTED]@" },
	// API keys and tokens (various formats) - generic patterns last
	{
		pattern: /\b(api[_-]?key|apikey|token|auth)[=:\s]+['"]?[\w\-_.]+['"]?/gi,
		replacement: "$1=[REDACTED]",
	},
	{
		pattern:
			/\b(password|passwd|pwd|secret|credential)[=:\s]+['"]?[^\s'"]+['"]?/gi,
		replacement: "$1=[REDACTED]",
	},
	// Long base64-like strings that might be secrets (very generic, last)
	{
		pattern: /\b[A-Za-z0-9/+=]{40}\b/g,
		replacement: "[POSSIBLE_SECRET_REDACTED]",
	},
];

/**
 * Sanitize a string by removing sensitive data patterns
 */
function redactSensitiveData(text: string): string {
	let result = text;
	for (const { pattern, replacement } of SENSITIVE_PATTERNS) {
		result = result.replace(pattern, replacement);
	}
	return result;
}

/**
 * Convert absolute paths to relative paths for safer display.
 * Replaces home directory with ~ and removes other absolute path prefixes.
 */
function sanitizePaths(text: string): string {
	const homeDir = os.homedir();
	let result = text;

	// Replace home directory with ~
	if (homeDir) {
		const homePattern = new RegExp(escapeRegExp(homeDir), "g");
		result = result.replace(homePattern, "~");
	}

	// Replace common system paths with generic placeholders
	result = result.replace(/\/nix\/store\/[a-z0-9]+-/g, "/nix/store/.../");
	result = result.replace(/\/tmp\/[^\s/]+/g, "/tmp/...");
	result = result.replace(/\/var\/[^\s]+/g, "/var/...");

	// Remove absolute paths that might reveal system structure (but keep relative paths)
	// Match paths like /home/username/... or /Users/username/...
	result = result.replace(/\/(home|Users)\/[^/\s]+/g, "~");

	return result;
}

/**
 * Escape special regex characters in a string
 */
function escapeRegExp(str: string): string {
	return str.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

/**
 * Sanitize error output for safe display to users.
 * Removes sensitive data and normalizes paths.
 */
export function sanitizeErrorOutput(text: string): string {
	let result = text;
	result = redactSensitiveData(result);
	result = sanitizePaths(result);
	return result;
}

/**
 * Create a user-friendly error message from stderr output.
 * Extracts the most relevant error information while hiding internals.
 */
function _createUserFriendlyMessage(
	stderr: string,
	maxLength: number = 200,
): string {
	const sanitized = sanitizeErrorOutput(stderr);

	// Try to extract the most relevant error line
	const lines = sanitized.split("\n").filter((line) => line.trim());

	// Look for common error indicators
	const errorLine = lines.find(
		(line) =>
			line.toLowerCase().includes("error:") ||
			line.toLowerCase().includes("fatal:") ||
			line.toLowerCase().includes("failed:"),
	);

	if (errorLine) {
		const trimmed = errorLine.trim();
		return trimmed.length > maxLength
			? `${trimmed.slice(0, maxLength)}...`
			: trimmed;
	}

	// Fall back to first non-empty line
	const firstLine = lines[0]?.trim() || "Unknown error";
	return firstLine.length > maxLength
		? `${firstLine.slice(0, maxLength)}...`
		: firstLine;
}

/**
 * Base error class for all plugin errors
 */
export class ProjectsPluginError extends Error implements BaseError {
	constructor(
		message: string,
		public readonly code: string,
		public readonly recoverable: boolean = true,
		public readonly suggestion?: string,
		public readonly cause?: unknown,
	) {
		super(message);
		this.name = "ProjectsPluginError";
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
			"Use `project-list` to see available projects, or `project-create` to create a new one.",
		);
		this.name = "ProjectNotFoundError";
	}
}

/**
 * Error when an issue is not found
 */
export class IssueNotFoundError extends ProjectsPluginError {
	constructor(issueId: string, projectId?: string) {
		const context = projectId ? ` in project '${projectId}'` : "";
		super(
			`Issue '${issueId}' not found${context}`,
			"ISSUE_NOT_FOUND",
			true,
			"Use `project-status` to see available issues.",
		);
		this.name = "IssueNotFoundError";
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
			"Install beads from https://github.com/hdwlinux/beads or use in-memory storage.",
		);
		this.name = "BeadsNotAvailableError";
	}
}

/**
 * Base class for VCS-related errors
 */
export class VCSError extends ProjectsPluginError {
	constructor(
		message: string,
		code: string,
		recoverable: boolean = true,
		suggestion?: string,
		cause?: unknown,
	) {
		super(message, code, recoverable, suggestion, cause);
		this.name = "VCSError";
	}
}

/**
 * Error when VCS is not detected
 */
export class VCSNotDetectedError extends VCSError {
	constructor(directory: string) {
		super(
			`No version control system detected in '${directory}'`,
			"VCS_NOT_DETECTED",
			true,
			"Initialize a jj or git repository first.",
		);
		this.name = "VCSNotDetectedError";
	}
}

/**
 * Error when a worktree already exists
 */
export class WorktreeExistsError extends VCSError {
	constructor(name: string, path: string) {
		super(
			`Worktree '${name}' already exists at ${path}`,
			"WORKTREE_EXISTS",
			true,
			"Use a different name or remove the existing worktree first.",
		);
		this.name = "WorktreeExistsError";
	}
}

/**
 * Error when a worktree operation fails
 */
export class WorktreeError extends VCSError {
	constructor(operation: string, details: string, cause?: unknown) {
		super(
			`Worktree ${operation} failed: ${details}`,
			"WORKTREE_ERROR",
			true,
			"Check VCS status and try again.",
			cause,
		);
		this.name = "WorktreeError";
	}
}

/**
 * Error when merge conflicts occur
 */
export class MergeConflictError extends VCSError {
	constructor(public readonly conflictFiles: string[]) {
		super(
			`Merge conflicts in ${conflictFiles.length} file(s)`,
			"MERGE_CONFLICT",
			true,
			"Resolve conflicts manually, then retry the merge.",
		);
		this.name = "MergeConflictError";
	}
}

/**
 * Error when a VCS command fails
 */
export class VCSCommandError extends VCSError {
	constructor(
		command: string,
		public readonly exitCode: number,
		public readonly stderr: string,
		cause?: unknown,
	) {
		super(
			`VCS command failed: ${command}`,
			"VCS_COMMAND_FAILED",
			true,
			`Command exited with code ${exitCode}. Check the error output for details.`,
			cause,
		);
		this.name = "VCSCommandError";
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
			"Use `project-focus(projectId)` to set context, or provide projectId explicitly.",
		);
		this.name = "NoProjectFocusedError";
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
			"Check your opencode-projects.json configuration file.",
		);
		this.name = "ConfigurationError";
	}
}

/**
 * Delegation error types - discriminated union for type-safe error handling
 */
export type DelegationError =
	| { type: "not_found"; delegationId: string }
	| {
			type: "invalid_status";
			delegationId: string;
			currentStatus: string;
			expectedStatus: string;
	  }
	| { type: "session_failed"; delegationId: string; message: string }
	| { type: "persistence_failed"; delegationId: string; message: string }
	| { type: "already_completed"; delegationId: string; status: string }
	| { type: "timeout"; delegationId: string; timeoutMs: number }
	| {
			type: "api_error";
			delegationId: string;
			operation: string;
			message: string;
			retryable: boolean;
			hint: string;
	  };

/**
 * Team error types - discriminated union for type-safe error handling
 */
export type TeamError =
	| { type: "not_found"; teamId: string }
	| { type: "no_agents_available"; issueContext: string }
	| {
			type: "invalid_status";
			teamId: string;
			currentStatus: string;
			expectedStatus: string;
	  }
	| { type: "persistence_failed"; teamId: string; message: string }
	| { type: "timeout"; teamId: string; timeoutMs: number; operation: string }
	| { type: "worktree_failed"; teamId: string; message: string }
	| { type: "member_not_found"; teamId: string; delegationId: string };

/**
 * Planning error types - discriminated union for type-safe error handling
 */
export type PlanningError =
	| { type: "no_session" }
	| { type: "cannot_advance"; currentPhase: string }
	| { type: "persistence_failed"; message: string };

/**
 * Format a DelegationError for display.
 * Sanitizes output to prevent information disclosure.
 */
export function formatDelegationError(error: DelegationError): string {
	switch (error.type) {
		case "not_found":
			return `Delegation '${error.delegationId}' not found`;
		case "invalid_status":
			return `Delegation '${error.delegationId}' has status '${error.currentStatus}', expected '${error.expectedStatus}'`;
		case "session_failed":
			return `Delegation '${error.delegationId}' session failed: ${sanitizeErrorOutput(error.message)}`;
		case "persistence_failed":
			return `Failed to persist delegation '${error.delegationId}': ${sanitizeErrorOutput(error.message)}`;
		case "already_completed":
			return `Delegation '${error.delegationId}' already completed with status '${error.status}'`;
		case "timeout":
			return `Delegation '${error.delegationId}' timed out after ${error.timeoutMs / 1000}s`;
		case "api_error": {
			const lines = [
				`Delegation '${error.delegationId}' API error during ${error.operation}: ${sanitizeErrorOutput(error.message)}`,
				"",
				`**Hint:** ${error.hint}`,
			];
			return lines.join("\n");
		}
	}
}

/**
 * Format a TeamError for display.
 * Sanitizes output to prevent information disclosure.
 */
export function formatTeamError(error: TeamError): string {
	switch (error.type) {
		case "not_found":
			return `Team '${error.teamId}' not found`;
		case "no_agents_available": {
			// Truncate and sanitize issue context to avoid leaking sensitive details
			const truncatedContext = error.issueContext.slice(0, 100);
			return `No agents available for team. Issue context: ${sanitizeErrorOutput(truncatedContext)}...`;
		}
		case "invalid_status":
			return `Team '${error.teamId}' has status '${error.currentStatus}', expected '${error.expectedStatus}'`;
		case "persistence_failed":
			return `Failed to persist team '${error.teamId}': ${sanitizeErrorOutput(error.message)}`;
		case "timeout":
			return `Team '${error.teamId}' operation '${error.operation}' timed out after ${error.timeoutMs / 1000}s`;
		case "worktree_failed":
			return `Team '${error.teamId}' worktree operation failed: ${sanitizeErrorOutput(error.message)}`;
		case "member_not_found":
			return `Team '${error.teamId}' member with delegation '${error.delegationId}' not found`;
	}
}

/**
 * Format a PlanningError for display.
 */
export function formatPlanningError(error: PlanningError): string {
	switch (error.type) {
		case "no_session":
			return "No planning session found. Use `project-plan(action='start')` to begin planning.";
		case "cannot_advance":
			return `Cannot advance from phase: ${error.currentPhase}`;
		case "persistence_failed":
			return `Failed to save planning state: ${sanitizeErrorOutput(error.message)}`;
	}
}

/**
 * Format an error for display to the user.
 * Sanitizes output to prevent information disclosure.
 */
export function formatError(error: unknown): string {
	if (error instanceof ProjectsPluginError) {
		// ProjectsPluginError messages are already controlled, but sanitize for safety
		const lines = [sanitizeErrorOutput(error.message)];
		if (error.suggestion) {
			lines.push("");
			lines.push(`**Suggestion:** ${error.suggestion}`);
		}
		return lines.join("\n");
	}

	if (error instanceof Error) {
		// Generic errors may contain sensitive information
		return sanitizeErrorOutput(error.message);
	}

	// Unknown error types - sanitize the string representation
	return sanitizeErrorOutput(String(error));
}
