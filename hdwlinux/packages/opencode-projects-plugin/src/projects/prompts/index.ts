/**
 * Project prompts module
 *
 * Exports project-specific prompts and context builders.
 */

export { PROJECT_RULES } from "./project-rules.js"

export { buildFocusContext } from "./focus-context.js"

export {
  buildCompactionContext,
  buildDelegationCompactionContext,
  buildTeamCompactionContext,
} from "./compaction-context.js"
