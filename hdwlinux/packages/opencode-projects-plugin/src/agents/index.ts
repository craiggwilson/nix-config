/**
 * Agents module - Agent interaction, selection, and small model utilities
 *
 * Note: PROJECT_RULES has moved to projects/prompts/project-rules.ts
 * Note: Devil's advocate templates have moved to utils/prompts/templates/devil-advocate.ts
 */

export { selectAgent, discoverAgents } from "./agent-selector.js"
export type { AgentInfo, AgentSelectionContext } from "./agent-selector.js"

export { promptSmallModel } from "./small-model.js"
export type { SmallModelOptions } from "./small-model.js"

// Re-export from utils/prompts for backward compatibility
export {
  DEVILS_ADVOCATE_PROMPT,
  buildDevilsAdvocateSelectionPrompt,
} from "../utils/prompts/templates/devil-advocate.js"
