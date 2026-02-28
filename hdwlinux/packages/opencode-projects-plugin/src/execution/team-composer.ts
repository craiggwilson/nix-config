/**
 * TeamComposer - Handles agent selection and team composition
 *
 * Responsible for:
 * - Selecting team composition using small model
 * - Selecting single agents for tasks
 * - Selecting devil's advocate from team members
 */

import { z } from "zod"

import type { Logger, OpencodeClient } from "../utils/opencode-sdk/index.js"
import {
  promptSmallModel,
  discoverAgents,
  type AgentInfo,
} from "../agents/index.js"
import {
  teamCompositionTemplate,
  singleAgentSelectionTemplate,
  devilsAdvocateSelectionTemplate,
} from "../utils/prompts/index.js"

/**
 * Configuration options for TeamComposer.
 */
export interface TeamComposerConfig {
  /** Maximum number of agents in a team */
  maxTeamSize: number
  /** Maximum time for small model queries (milliseconds) */
  smallModelTimeoutMs: number
}

/**
 * Zod schemas for small model responses
 */
const TeamCompositionResponseSchema = z.object({
  agents: z.array(z.string()),
})

const AgentSelectionResponseSchema = z.object({
  agent: z.string(),
  reason: z.string().optional(),
})

const DevilsAdvocateResponseSchema = z.object({
  devilsAdvocate: z.string(),
})

/**
 * Handles agent selection and team composition using a small model.
 *
 * Uses a fast small model to analyze issue context and select appropriate
 * agents for the team. Supports:
 * - Multi-agent team composition based on issue requirements
 * - Single agent selection for simpler tasks
 * - Devil's advocate selection for critical analysis
 *
 * Falls back to first available agent if small model selection fails.
 */
export class TeamComposer {
  private log: Logger
  private client: OpencodeClient
  private config: TeamComposerConfig

  /**
   * @param log - Logger for diagnostic output
   * @param client - OpenCode client for small model queries
   * @param config - Configuration options
   */
  constructor(log: Logger, client: OpencodeClient, config: TeamComposerConfig) {
    this.log = log
    this.client = client
    this.config = config
  }

  /**
   * Resolve team composition from explicit agents or auto-select.
   *
   * If explicit agents are provided, uses those (truncated to maxTeamSize).
   * Otherwise, uses small model to select appropriate agents for the issue.
   *
   * @param explicitAgents - Explicitly specified agents, or undefined for auto-selection
   * @param issueContext - Issue title and description for context
   * @returns List of agent names for the team
   */
  async resolveTeamComposition(
    explicitAgents: string[] | undefined,
    issueContext: string
  ): Promise<string[]> {
    if (explicitAgents && explicitAgents.length > 0) {
      return explicitAgents.slice(0, this.config.maxTeamSize)
    }

    const agents = await this.selectTeamComposition(issueContext)
    return agents.slice(0, this.config.maxTeamSize)
  }

  /**
   * Select team composition using small model.
   *
   * Discovers available agents and uses small model to select the best
   * combination for the given issue. Falls back to single agent selection
   * if team composition fails.
   *
   * @param issueContext - Issue title and description for context
   * @returns List of selected agent names
   */
  async selectTeamComposition(issueContext: string): Promise<string[]> {
    const agents = await discoverAgents(this.client, this.log)
    if (agents.length === 0) {
      return []
    }

    const prompt = teamCompositionTemplate.render({
      issueContext,
      agents,
    })

    const result = await promptSmallModel(this.client, this.log, {
      prompt,
      sessionTitle: "Team Composition Selection",
      timeoutMs: this.config.smallModelTimeoutMs,
      schema: TeamCompositionResponseSchema,
    })

    if (result.ok && result.value.agents.length > 0) {
      const validAgents = result.value.agents.filter((name) =>
        agents.some((a) => a.name === name)
      )
      if (validAgents.length > 0) {
        return validAgents
      }
    }

    await this.log.info("Team composition selection failed, falling back to single agent")
    const selected = await this.selectSingleAgent(agents, issueContext)
    return selected ? [selected] : [agents[0].name]
  }

  /**
   * Select a single agent using small model.
   *
   * Used as fallback when team composition fails, or for simple tasks
   * that only need one agent.
   *
   * @param agents - Available agents to choose from
   * @param issueContext - Issue title and description for context
   * @returns Selected agent name, or null if selection failed
   */
  async selectSingleAgent(
    agents: AgentInfo[],
    issueContext: string
  ): Promise<string | null> {
    const prompt = singleAgentSelectionTemplate.render({
      taskDescription: issueContext,
      agents,
    })

    const result = await promptSmallModel(this.client, this.log, {
      prompt,
      sessionTitle: "Agent Selection",
      timeoutMs: this.config.smallModelTimeoutMs,
      schema: AgentSelectionResponseSchema,
    })

    if (result.ok) {
      const valid = agents.find((a) => a.name === result.value.agent)
      if (valid) {
        return result.value.agent
      }
    }

    return null
  }

  /**
   * Select which non-primary agent should be devil's advocate.
   *
   * The devil's advocate role critically analyzes the primary agent's work
   * for potential issues, edge cases, and improvements.
   *
   * @param teamAgents - All team agents (first is primary)
   * @param issueContext - Issue title and description for context
   * @returns Selected devil's advocate agent name, or undefined if single-agent team
   */
  async selectDevilsAdvocate(
    teamAgents: string[],
    issueContext: string
  ): Promise<string | undefined> {
    const nonPrimary = teamAgents.slice(1)

    if (nonPrimary.length === 0) {
      return undefined
    }

    if (nonPrimary.length === 1) {
      return nonPrimary[0]
    }

    const prompt = devilsAdvocateSelectionTemplate.render({
      teamMembers: teamAgents,
      issueContext,
    })
    if (!prompt) {
      return nonPrimary[0]
    }

    const result = await promptSmallModel(this.client, this.log, {
      prompt,
      sessionTitle: "Devil's Advocate Selection",
      timeoutMs: this.config.smallModelTimeoutMs,
      schema: DevilsAdvocateResponseSchema,
    })

    if (result.ok) {
      if (nonPrimary.includes(result.value.devilsAdvocate)) {
        return result.value.devilsAdvocate
      }
    }

    return nonPrimary[0]
  }
}
