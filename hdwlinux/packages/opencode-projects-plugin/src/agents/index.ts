/**
 * Agents module - Agent interaction, selection, and small model utilities
 */

export { selectAgent, discoverAgents } from "./agent-selector.js"
export type { AgentInfo, AgentSelectionContext } from "./agent-selector.js"

export { promptSmallModel } from "./small-model.js"
export type { SmallModelOptions } from "./small-model.js"

export { OPENCODE_PROJECTS_AGENT_CONFIG, OPENCODE_PROJECTS_AGENT_PROMPT } from "./projects-agent.js"

