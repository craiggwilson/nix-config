/**
 * PlanningDelegator - Delegates planning work to available agents
 *
 * Discovers available agents from the OpenCode SDK and selects
 * the best match for the planning task. Falls back to letting
 * OpenCode decide if no suitable agent is found.
 */

import type { Logger } from "../core/types.js"

// Use any for client to avoid SDK type compatibility issues
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type DelegationClient = any

/**
 * Planning phase types
 */
export type PlanningPhase = "discovery" | "refinement" | "breakdown"

/**
 * Agent info from SDK
 */
export interface AgentInfo {
  name: string
  description?: string
}

/**
 * Delegation request
 */
export interface DelegationRequest {
  prompt: string
  context?: string
  projectId: string
  phase?: PlanningPhase
  preferredAgent?: string // User can specify a preferred agent
}

/**
 * Delegation result
 */
export interface DelegationResult {
  success: boolean
  sessionId?: string
  response?: string
  agentUsed?: string // Which agent was actually used
  error?: string
}

/**
 * Keywords to match agents to planning phases
 */
const PHASE_KEYWORDS: Record<PlanningPhase, string[]> = {
  discovery: ["roadmap", "vision", "strategy", "okr", "quarter", "initiative"],
  refinement: ["project", "plan", "scope", "resource", "risk", "stakeholder"],
  breakdown: ["task", "sprint", "story", "acceptance", "estimate", "backlog"],
}

/**
 * PlanningDelegator - delegates to available agents
 */
export class PlanningDelegator {
  private client: DelegationClient
  private log: Logger
  private cachedAgents: AgentInfo[] | null = null

  constructor(client: DelegationClient, log: Logger) {
    this.client = client
    this.log = log
  }

  /**
   * Discover available agents from the SDK
   */
  async discoverAgents(): Promise<AgentInfo[]> {
    if (this.cachedAgents !== null) {
      return this.cachedAgents
    }

    try {
      const result = await this.client.app.agents()
      const agents = result.data || []

      const mapped: AgentInfo[] = agents.map((a: { name: string; description?: string }) => ({
        name: a.name,
        description: a.description,
      }))

      this.cachedAgents = mapped
      return mapped
    } catch (error) {
      await this.log.warn(`Failed to discover agents: ${error}`)
      return []
    }
  }

  /**
   * Clear the agent cache (useful if agents change)
   */
  clearCache(): void {
    this.cachedAgents = null
  }

  /**
   * Find the best agent for a planning phase
   * Returns null if no suitable agent is found
   */
  async findAgentForPhase(phase: PlanningPhase): Promise<string | null> {
    const agents = await this.discoverAgents()

    if (agents.length === 0) {
      return null
    }

    const keywords = PHASE_KEYWORDS[phase]


    const scored = agents.map((agent) => {
      const searchText = `${agent.name} ${agent.description || ""}`.toLowerCase()
      let score = 0

      for (const keyword of keywords) {
        if (searchText.includes(keyword)) {
          score += 1
        }
      }

      return { agent, score }
    })


    scored.sort((a, b) => b.score - a.score)


    if (scored[0].score > 0) {
      return scored[0].agent.name
    }

    return null
  }

  /**
   * List all available agents
   */
  async listAgents(): Promise<AgentInfo[]> {
    return this.discoverAgents()
  }

  /**
   * Check if a specific agent is available
   */
  async isAgentAvailable(agentName: string): Promise<boolean> {
    const agents = await this.discoverAgents()
    return agents.some((a) => a.name === agentName)
  }

  /**
   * Delegate planning work
   *
   * If preferredAgent is specified and available, uses that.
   * Otherwise, tries to find a suitable agent for the phase.
   * If no suitable agent is found, lets OpenCode decide.
   */
  async delegate(request: DelegationRequest): Promise<DelegationResult> {
    const { prompt, context, projectId, phase, preferredAgent } = request

    await this.log.info(`Delegating planning for project ${projectId}`)


    let agentToUse: string | undefined

    if (preferredAgent) {
      const available = await this.isAgentAvailable(preferredAgent)
      if (available) {
        agentToUse = preferredAgent
        await this.log.info(`Using preferred agent: ${preferredAgent}`)
      } else {
        await this.log.warn(`Preferred agent '${preferredAgent}' not available`)
      }
    }

    if (!agentToUse && phase) {
      const suggested = await this.findAgentForPhase(phase)
      if (suggested) {
        agentToUse = suggested
        await this.log.info(`Using suggested agent for ${phase}: ${suggested}`)
      }
    }

    if (!agentToUse) {
      await this.log.info("No specific agent selected, letting OpenCode decide")
    }

    try {

      const sessionOptions: { body?: { agent?: string; title?: string } } = {
        body: {
          title: `Planning: ${projectId}`,
        },
      }

      if (agentToUse) {
        sessionOptions.body!.agent = agentToUse
      }

      const sessionResult = await this.client.session.create(sessionOptions)

      const sessionId = sessionResult.data?.id
      if (!sessionId) {
        return {
          success: false,
          error: "Failed to create session for delegation",
        }
      }


      const fullPrompt = this.buildPrompt(prompt, context, projectId, phase)


      const promptResult = await this.client.session.prompt({
        path: { id: sessionId },
        body: { content: fullPrompt },
      })


      const messages = await this.client.session.messages({ path: { id: sessionId } })
      const lastMessage = messages.data?.slice(-1)[0]

      return {
        success: true,
        sessionId,
        response: lastMessage?.content || promptResult.data?.content,
        agentUsed: agentToUse,
      }
    } catch (error) {
      await this.log.error(`Delegation failed: ${error}`)
      return {
        success: false,
        error: String(error),
      }
    }
  }

  /**
   * Build a prompt for the delegation
   */
  private buildPrompt(
    prompt: string,
    context: string | undefined,
    projectId: string,
    phase?: PlanningPhase
  ): string {
    const lines: string[] = []

    lines.push(`# Planning Request for Project: ${projectId}`)
    lines.push("")

    if (context) {
      lines.push("## Context")
      lines.push("")
      lines.push(context)
      lines.push("")
    }

    lines.push("## Request")
    lines.push("")
    lines.push(prompt)
    lines.push("")


    if (phase) {
      lines.push("## Expected Output")
      lines.push("")

      switch (phase) {
        case "discovery":
          lines.push("Please provide:")
          lines.push("1. A clear vision statement")
          lines.push("2. Key milestones with target dates")
          lines.push("3. Deliverables for each milestone")
          lines.push("4. Dependencies between milestones")
          lines.push("5. Assumptions and constraints")
          break

        case "refinement":
          lines.push("Please provide:")
          lines.push("1. Project scope and objectives")
          lines.push("2. Resource requirements")
          lines.push("3. Risk assessment")
          lines.push("4. Success criteria")
          lines.push("5. Stakeholder alignment plan")
          break

        case "breakdown":
          lines.push("Please provide:")
          lines.push("1. User stories with acceptance criteria")
          lines.push("2. Task breakdown with estimates")
          lines.push("3. Priority assignments (P0-P3)")
          lines.push("4. Dependencies between tasks")
          lines.push("5. Sprint/iteration groupings")
          break
      }
    }

    return lines.join("\n")
  }
}
