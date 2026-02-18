/**
 * Agent Selector
 *
 * Uses the small model to intelligently select the best agent
 * for a given task. Falls back gracefully if small model is
 * not available.
 */

import type { Logger, OpencodeClient } from "./types.js"
import { promptSmallModel } from "./small-model.js"

/**
 * Information about an available agent
 */
export interface AgentInfo {
  name: string
  description?: string
}

/**
 * Context for agent selection
 */
export interface AgentSelectionContext {
  /** Available agents to choose from */
  agents: AgentInfo[]
  /** Description of the task to be performed */
  taskDescription: string
  /** Optional hint about the type of task */
  taskType?: "planning" | "coding" | "research" | "review" | "general"
}

/**
 * Response format from small model
 */
interface AgentSelectionResponse {
  agent: string
  reason: string
}

/**
 * Select the best agent for a task using the small model.
 *
 * Returns null if:
 * - Small model is not configured
 * - Selection times out
 * - Response is invalid
 * - Selected agent is not in the available list
 *
 * @param client - OpenCode client
 * @param log - Logger for debugging
 * @param context - Selection context with agents and task info
 * @returns Selected agent name or null
 */
export async function selectAgent(
  client: OpencodeClient,
  log: Logger,
  context: AgentSelectionContext
): Promise<string | null> {
  const { agents, taskDescription, taskType } = context

  if (agents.length === 0) {
    await log.info("No agents available for selection")
    return null
  }

  // Build the agent list for the prompt
  const agentList = agents
    .map((a) => `- ${a.name}: ${a.description || "(no description)"}`)
    .join("\n")

  // Build the prompt
  const taskTypeHint = taskType ? `\nTASK TYPE: ${taskType}` : ""
  const prompt = `Select the best agent for this task.

AVAILABLE AGENTS:
${agentList}
${taskTypeHint}
TASK DESCRIPTION:
${taskDescription.slice(0, 1000)}

Respond with ONLY valid JSON in this exact format:
{"agent": "agent-name", "reason": "brief reason for selection"}`

  const result = await promptSmallModel<AgentSelectionResponse>(client, log, {
    prompt,
    sessionTitle: "Agent Selection",
    timeoutMs: 30000,
  })

  if (!result.success) {
    await log.info(`Agent selection skipped: ${result.error}`)
    return null
  }

  if (!result.data?.agent) {
    await log.info("Agent selection returned no agent")
    return null
  }

  // Validate the selected agent exists
  const selectedAgent = agents.find((a) => a.name === result.data!.agent)
  if (!selectedAgent) {
    await log.warn(`Small model selected unknown agent: ${result.data.agent}`)
    return null
  }

  await log.info(`Selected agent: ${result.data.agent} (${result.data.reason})`)
  return result.data.agent
}

/**
 * Cache for available agents (shared across selectors)
 */
let cachedAgents: AgentInfo[] | null = null

/**
 * Discover available agents from the OpenCode SDK.
 * Results are cached for performance.
 *
 * @param client - OpenCode client
 * @param log - Logger for debugging
 * @returns List of available agents
 */
export async function discoverAgents(client: OpencodeClient, log: Logger): Promise<AgentInfo[]> {
  if (cachedAgents !== null) {
    return cachedAgents
  }

  try {
    const result = await client.app.agents({})
    const agents = result.data || []

    cachedAgents = agents.map((a: { name: string; description?: string }) => ({
      name: a.name,
      description: a.description,
    }))

    return cachedAgents
  } catch (error) {
    await log.warn(`Failed to discover agents: ${error}`)
    return []
  }
}

/**
 * Clear the agent cache.
 * Call this if agents may have changed.
 */
export function clearAgentCache(): void {
  cachedAgents = null
}
