/**
 * Permission management for delegated agents
 *
 * Provides fine-grained tool access control based on team member roles:
 * - Primary agents get write access for implementation
 * - Reviewers/researchers get read-only access
 * - All delegated agents are blocked from recursive delegation and state modification
 *
 * Note: The current OpenCode SDK only supports boolean tool permissions (true/false).
 * Pattern-based bash permissions (e.g., "sudo *": "deny") would require SDK changes.
 * This implementation uses the boolean format for compatibility.
 */

import type { TeamMemberRole } from "./team-manager.js";

/**
 * Tool permission configuration for delegated agents.
 *
 * Maps tool names to boolean values:
 * - true: Tool is permitted
 * - false: Tool is blocked
 *
 * This format is compatible with the OpenCode SDK's session.prompt() tools parameter.
 */
export type ToolPermissions = Record<string, boolean>;

/**
 * Tools that are always disabled for all delegated agents.
 *
 * These prevent recursive delegation and state modifications that could
 * cause coordination issues or infinite loops.
 */
const ALWAYS_DISABLED_TOOLS: readonly string[] = [
	"delegate",
	"project-close",
	"project-create",
	"project-create-issue",
	"project-update-issue",
	"project-work-on-issue",
	"question",
	"task",
	"todowrite",
] as const;

/**
 * Write tools that are disabled for read-only roles (secondary, devilsAdvocate).
 *
 * Primary agents retain access to these tools for implementation work.
 */
const WRITE_TOOLS: readonly string[] = ["edit", "write"] as const;

/**
 * Resolve permissions for a given team member role.
 *
 * Returns a permission configuration suitable for passing to the
 * OpenCode SDK's session.prompt() tools parameter.
 *
 * @param role - The team member's role
 * @returns Tool permissions for the role (false = disabled)
 *
 * @example
 * ```typescript
 * const permissions = resolvePermissions("primary")
 * // Use in session.prompt({ tools: permissions })
 * ```
 */
export function resolvePermissions(role: TeamMemberRole): ToolPermissions {
	const permissions: ToolPermissions = {};

	for (const tool of ALWAYS_DISABLED_TOOLS) {
		permissions[tool] = false;
	}

	if (role !== "primary") {
		for (const tool of WRITE_TOOLS) {
			permissions[tool] = false;
		}
	}

	return permissions;
}

/**
 * Get the list of tools that are always disabled for delegated agents.
 *
 * Useful for documentation and testing.
 */
export function getAlwaysDisabledTools(): readonly string[] {
	return ALWAYS_DISABLED_TOOLS;
}

/**
 * Get the list of write tools (disabled for read-only roles).
 *
 * Useful for documentation and testing.
 */
export function getWriteTools(): readonly string[] {
	return WRITE_TOOLS;
}

/**
 * Check if a role has write access.
 *
 * @param role - The team member's role
 * @returns true if the role can use write tools
 */
export function hasWriteAccess(role: TeamMemberRole): boolean {
	return role === "primary";
}

/**
 * Check if a role is read-only.
 *
 * @param role - The team member's role
 * @returns true if the role is restricted to read-only tools
 */
export function isReadOnly(role: TeamMemberRole): boolean {
	return role !== "primary";
}
