/**
 * Agent Selector
 *
 * Uses the small model to intelligently select the best agent
 * for a given task. Falls back gracefully if small model is
 * not available.
 */

import { z } from "zod"
import type { Logger, OpencodeClient } from "../utils/opencode-sdk/index.js"
import { promptSmallModel } from "./small-model.js"
import { singleAgentSelectionTemplate } from "../utils/prompts/index.js"

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
  /** Timeout for small model query in milliseconds */
  timeoutMs: number
}

/**
 * Zod schema for agent selection response
 */
const AgentSelectionResponseSchema = z.object({
  agent: z.string(),
  reason: z.string(),
})

type AgentSelectionResponse = z.infer<typeof AgentSelectionResponseSchema>

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
  const { agents, taskDescription, taskType, timeoutMs } = context

  if (agents.length === 0) {
    await log.info("No agents available for selection")
    return null
  }

  // Build the prompt using template
  const taskTypeHint = taskType ? `\nTASK TYPE: ${taskType}` : ""
  const prompt = singleAgentSelectionTemplate.render({
    taskDescription: taskDescription + taskTypeHint,
    agents,
  })

  const result = await promptSmallModel(client, log, {
    prompt,
    sessionTitle: "Agent Selection",
    timeoutMs,
    schema: AgentSelectionResponseSchema,
  })

  if (!result.ok) {
    await log.info(`Agent selection skipped: ${result.error}`)
    return null
  }

  // Validate the selected agent exists
  const selectedAgent = agents.find((a) => a.name === result.value.agent)
  if (!selectedAgent) {
    await log.warn(`Small model selected unknown agent: ${result.value.agent}`)
    return null
  }

  await log.info(`Selected agent: ${result.value.agent} (${result.value.reason})`)
  return result.value.agent
}

/**
 * Discover available agents from the OpenCode SDK.
 *
 * Always fetches fresh from the SDK to ensure the small model
 * can make context-aware selections each time.
 *
 * @param client - OpenCode client
 * @param log - Logger for debugging
 * @returns List of available agents
 */
export async function discoverAgents(client: OpencodeClient, log: Logger): Promise<AgentInfo[]> {
  try {
    const result = await client.app.agents({})
    const agents = result.data || []

    return agents.map((a: { name: string; description?: string }) => ({
      name: a.name,
      description: a.description,
    }))
  } catch (error) {
    await log.warn(`Failed to discover agents: ${error}`)
    return []
  }
}
