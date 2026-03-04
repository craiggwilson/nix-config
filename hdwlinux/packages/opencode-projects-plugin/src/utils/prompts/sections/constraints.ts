/**
 * Reusable constraint sections for prompts
 *
 * These sections define common constraints that are applied to
 * delegated agents and team members.
 */

import type { PromptSection } from "../prompt.js"

/**
 * List of tools disabled in delegations
 */
export const DISABLED_TOOLS = [
  "project-create",
  "project-close",
  "project-create-issue",
  "project-update-issue",
  "project-work-on-issue",
  "question",
  "task",
  "delegate",
] as const

/**
 * Format the disabled tools as a bullet list
 */
export function disabledToolsList(): string {
  return `- ${DISABLED_TOOLS.slice(0, 5).join(", ")}
- ${DISABLED_TOOLS.slice(5).join(", ")} (no recursive delegation)`
}

/**
 * Standard constraints for delegated agents.
 *
 * Informs the agent that it's running as a background delegation
 * and lists the tools that are disabled.
 */
export const delegationConstraints: PromptSection = () => `
## Hard Blocks (NEVER violate)

- **Never commit** without being explicitly asked to
- **Never push to remote** under any circumstances
- **Never leave code in a broken state** — if you can't complete something, restore the previous working state and say so explicitly
- **Never deliver a final answer** before collecting all reviewer feedback

## Constraints

You are running as a background delegation. The following tools are disabled:
${disabledToolsList()}

Focus on completing your assigned role.`

/**
 * Read-only constraints for reviewers.
 *
 * Informs the agent that it should not modify files.
 */
export const readOnlyConstraints: PromptSection = () =>
  "Do NOT modify files - you are read-only."
