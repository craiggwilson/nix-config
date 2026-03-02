/**
 * PermissionManager - Role-based permission model for delegated agents
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

import type { TeamMemberRole } from "./delegation-manager.js"

/**
 * Tool permission configuration for delegated agents.
 *
 * Maps tool names to boolean values:
 * - true: Tool is permitted
 * - false: Tool is blocked
 *
 * This format is compatible with the OpenCode SDK's session.prompt() tools parameter.
 */
export type ToolPermissions = Record<string, boolean>

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
] as const

/**
 * Write tools that are disabled for read-only roles (secondary, devilsAdvocate).
 *
 * Primary agents retain access to these tools for implementation work.
 */
const WRITE_TOOLS: readonly string[] = [
  "edit",
  "write",
] as const

/**
 * Manages role-based permissions for delegated agents.
 *
 * Provides permission configurations that enforce:
 * - Primary agents: Full tool access (except delegation/state tools)
 * - Secondary/reviewer agents: Read-only access (no edit/write)
 * - Devil's advocate agents: Same as secondary (read-only)
 *
 * All delegated agents are blocked from recursive delegation and
 * project state modifications.
 *
 * @example
 * ```typescript
 * const permissions = PermissionManager.resolvePermissions("primary")
 * // Use in session.prompt({ tools: permissions })
 * ```
 */
export class PermissionManager {
  /**
   * Resolve permissions for a given team member role.
   *
   * Returns a permission configuration suitable for passing to the
   * OpenCode SDK's session.prompt() tools parameter.
   *
   * @param role - The team member's role
   * @returns Tool permissions for the role (false = disabled)
   */
  static resolvePermissions(role: TeamMemberRole): ToolPermissions {
    const permissions: ToolPermissions = {}

    // Always disable recursive delegation and state modification tools
    for (const tool of ALWAYS_DISABLED_TOOLS) {
      permissions[tool] = false
    }

    // Role-specific permissions
    if (role === "primary") {
      // Primary agents retain write access - no additional restrictions
    } else {
      // Secondary and devilsAdvocate roles are read-only
      for (const tool of WRITE_TOOLS) {
        permissions[tool] = false
      }
    }

    return permissions
  }

  /**
   * Get the list of tools that are always disabled for delegated agents.
   *
   * Useful for documentation and testing.
   */
  static getAlwaysDisabledTools(): readonly string[] {
    return ALWAYS_DISABLED_TOOLS
  }

  /**
   * Get the list of write tools (disabled for read-only roles).
   *
   * Useful for documentation and testing.
   */
  static getWriteTools(): readonly string[] {
    return WRITE_TOOLS
  }

  /**
   * Check if a role has write access.
   *
   * @param role - The team member's role
   * @returns true if the role can use write tools
   */
  static hasWriteAccess(role: TeamMemberRole): boolean {
    return role === "primary"
  }
}
