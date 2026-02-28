/**
 * TeamManager - Orchestrates multi-agent team execution
 *
 * Every work-on-issue operation creates a Team (even single-agent).
 * This unifies the execution path and enables:
 * - Multiple agents working on the same issue
 * - Discussion rounds between agents
 * - Devil's advocate critical analysis
 * - Coordinated notifications to parent
 */

import * as fs from "node:fs/promises"
import * as path from "node:path"
import * as crypto from "node:crypto"

import type {
  Logger,
  OpencodeClient,
  Team,
  TeamMember,
  TeamMemberRole,
  TeamMemberResult,
  TeamConfig,
  CreateTeamOptions,
  DiscussionRound,
  VCSType,
  MessageItem,
  Part,
} from "../core/types.js"
import { promptSmallModel } from "../core/small-model.js"
import { discoverAgents, type AgentInfo } from "../core/agent-selector.js"
import { DEVILS_ADVOCATE_PROMPT, buildDevilsAdvocateSelectionPrompt } from "./devil-advocate.js"
import type { DelegationManager, Delegation, CreateDelegationOptions } from "./delegation-manager.js"
import type { WorktreeManager } from "./worktree-manager.js"

/**
 * Tools to disable in delegated sessions
 */
const DISABLED_TOOLS: Record<string, boolean> = {
  task: false,
  delegate: false,
  todowrite: false,
  plan_save: false,
  "project-create": false,
  "project-close": false,
  "project-create-issue": false,
  "project-update-issue": false,
  "project-work-on-issue": false,
}

/**
 * TeamManager - manages multi-agent team execution
 */
export class TeamManager {
  private projectDir: string
  private teamsDir: string
  private log: Logger
  private client: OpencodeClient
  private delegationManager!: DelegationManager
  private worktreeManager: WorktreeManager
  private config: TeamConfig

  // In-memory team cache
  private teams: Map<string, Team> = new Map()

  // Track teams by delegation ID for completion handling
  private delegationToTeam: Map<string, string> = new Map()

  // Pending completion promises for foreground mode
  private completionPromises: Map<string, (team: Team) => void> = new Map()

  constructor(
    projectDir: string,
    log: Logger,
    client: OpencodeClient,
    worktreeManager: WorktreeManager,
    config: TeamConfig
  ) {
    this.projectDir = projectDir
    this.teamsDir = path.join(projectDir, "teams")
    this.log = log
    this.client = client
    this.worktreeManager = worktreeManager
    this.config = config
  }

  /**
   * Set the delegation manager (called after construction to resolve circular dependency)
   */
  setDelegationManager(delegationManager: DelegationManager): void {
    this.delegationManager = delegationManager
  }

  /**
   * Create a team and start all delegations.
   *
   * This is the main entry point for work-on-issue operations.
   * Even single-agent work creates a team of 1.
   */
  async create(options: CreateTeamOptions): Promise<Team> {
    const {
      projectId,
      issueId,
      issueContext,
      isolate,
      parentSessionId,
      parentAgent,
    } = options

    // 1. Resolve team composition
    const agents = await this.resolveTeamComposition(options)
    if (agents.length === 0) {
      throw new Error("No agents available for team")
    }

    // Enforce max team size
    const teamAgents = agents.slice(0, this.config.maxTeamSize)

    await this.log.info(`Creating team with ${teamAgents.length} agent(s): ${teamAgents.join(", ")}`)

    // 2. Select devil's advocate (if multiple agents)
    let devilsAdvocateAgent: string | undefined
    if (teamAgents.length > 1) {
      devilsAdvocateAgent = await this.selectDevilsAdvocate(teamAgents, issueContext)
      if (devilsAdvocateAgent) {
        await this.log.info(`Devil's advocate: ${devilsAdvocateAgent}`)
      }
    }

    // 3. Create worktree if isolated
    let worktreePath: string | undefined
    let worktreeBranch: string | undefined
    let vcs: VCSType | undefined

    if (isolate) {
      const worktreeResult = await this.worktreeManager.createIsolatedWorktree({
        projectId,
        issueId,
      })

      if (worktreeResult.success && worktreeResult.info) {
        worktreePath = worktreeResult.info.path
        worktreeBranch = worktreeResult.info.branch
        vcs = this.worktreeManager.getVCSType() || undefined
        await this.log.info(`Created worktree at ${worktreePath}`)
      } else {
        await this.log.warn(`Failed to create worktree: ${worktreeResult.error}`)
      }
    }

    // 4. Create team record
    const teamId = this.generateId()
    const now = new Date().toISOString()

    const members: TeamMember[] = teamAgents.map((agent, index) => {
      let role: TeamMemberRole = "secondary"
      if (index === 0) {
        role = "primary"
      } else if (agent === devilsAdvocateAgent) {
        role = "devilsAdvocate"
      }

      return {
        agent,
        role,
        status: "pending",
        retryCount: 0,
      }
    })

    const team: Team = {
      id: teamId,
      projectId,
      issueId,
      members,
      status: "running",
      worktreePath,
      worktreeBranch,
      vcs,
      discussionRounds: teamAgents.length > 1 ? this.config.discussionRounds : 0,
      currentRound: 0,
      results: {},
      discussionHistory: [],
      parentSessionId,
      parentAgent,
      foreground: options.foreground,
      startedAt: now,
    }

    // Store in cache
    this.teams.set(teamId, team)
    await this.save(team)

    // 5. Create delegations for each member
    for (const member of members) {
      const prompt = this.buildMemberPrompt(team, member, issueContext)

      const delegationOptions: CreateDelegationOptions = {
        issueId,
        prompt,
        teamId,
        role: member.role,
        worktreePath: member.role === "primary" ? worktreePath : undefined,
        worktreeBranch,
        vcs,
        agent: member.agent,
        parentSessionId,
        parentAgent,
      }

      const delegation = await this.delegationManager.create(projectId, delegationOptions)
      member.delegationId = delegation.id
      member.sessionId = delegation.sessionId
      member.status = "running"

      // Track delegation -> team mapping
      this.delegationToTeam.set(delegation.id, teamId)
    }

    await this.save(team)
    await this.log.info(`Team ${teamId} started with ${members.length} member(s)`)

    // If foreground mode, wait for completion
    if (options.foreground) {
      await this.log.info(`Team ${teamId}: foreground mode, waiting for completion`)
      return await this.waitForCompletion(team)
    }

    return team
  }

  /**
   * Wait for a team to complete (foreground mode).
   *
   * Returns a promise that resolves when the team completes (success or failure).
   * The promise is resolved by handleDelegationComplete when all members finish.
   */
  async waitForCompletion(team: Team): Promise<Team> {
    // If already complete, return immediately
    const currentTeam = await this.get(team.id)
    if (currentTeam && (currentTeam.status === "completed" || currentTeam.status === "failed")) {
      await this.log.info(`Team ${team.id}: already complete with status ${currentTeam.status}`)
      return currentTeam
    }

    // Create a promise that will be resolved when the team completes
    return new Promise<Team>((resolve) => {
      this.completionPromises.set(team.id, resolve)
      this.log.info(`Team ${team.id}: waiting for completion promise`)
    })
  }

  /**
   * Resolve the completion promise for a team (called when team finishes)
   */
  private resolveCompletionPromise(team: Team): void {
    const resolve = this.completionPromises.get(team.id)
    if (resolve) {
      resolve(team)
      this.completionPromises.delete(team.id)
    }
  }

  /**
   * Handle delegation completion - check if team ready for next phase
   */
  async handleDelegationComplete(delegationId: string): Promise<void> {
    const teamId = this.delegationToTeam.get(delegationId)
    if (!teamId) {
      await this.log.debug(`Delegation ${delegationId} not associated with a team`)
      return
    }

    const team = await this.get(teamId)
    if (!team) {
      await this.log.warn(`Team ${teamId} not found for delegation ${delegationId}`)
      return
    }

    // Get the delegation to check its status
    const delegation = await this.delegationManager.get(delegationId)
    if (!delegation) {
      await this.log.warn(`Delegation ${delegationId} not found`)
      return
    }

    // Find and update the member
    const member = team.members.find((m) => m.delegationId === delegationId)
    if (!member) {
      await this.log.warn(`No member found for delegation ${delegationId}`)
      return
    }

    // Update member status based on delegation status
    if (delegation.status === "completed") {
      member.status = "completed"
      // Store the result
      team.results[member.agent] = {
        agent: member.agent,
        result: delegation.result || "(no result)",
        completedAt: delegation.completedAt || new Date().toISOString(),
      }
      await this.log.info(`Team ${teamId}: ${member.agent} completed`)
    } else if (delegation.status === "failed" || delegation.status === "timeout") {
      // Handle failure with retry (Option C)
      if (this.config.retryFailedMembers && member.retryCount < 1) {
        member.retryCount++
        await this.log.info(`Team ${teamId}: ${member.agent} failed, retrying (attempt ${member.retryCount})`)
        await this.retryMember(team, member)
        await this.save(team)
        return
      }

      member.status = "failed"
      team.results[member.agent] = {
        agent: member.agent,
        result: delegation.error || "(failed)",
        completedAt: new Date().toISOString(),
      }
      await this.log.warn(`Team ${teamId}: ${member.agent} failed after ${member.retryCount} retries`)
    }

    await this.save(team)

    // Check if all members complete
    const allComplete = team.members.every(
      (m) => m.status === "completed" || m.status === "failed"
    )

    if (!allComplete) {
      const pending = team.members.filter((m) => m.status === "pending" || m.status === "running")
      await this.log.info(`Team ${teamId}: waiting for ${pending.length} more member(s)`)
      return
    }

    await this.log.info(`Team ${teamId}: all members complete, proceeding to next phase`)

    // Check if all members failed
    const allFailed = team.members.every((m) => m.status === "failed")

    // Run discussion if enabled, multiple members, and not all failed
    if (team.discussionRounds > 0 && team.members.length > 1 && !allFailed) {
      team.status = "discussing"
      await this.save(team)
      await this.runDiscussion(team)
    }

    // Set final status based on member outcomes
    team.status = allFailed ? "failed" : "completed"
    team.completedAt = new Date().toISOString()
    await this.save(team)

    if (team.foreground) {
      // Foreground mode: resolve the waiting promise
      await this.log.info(`Team ${team.id}: foreground mode, resolving completion promise`)
      this.resolveCompletionPromise(team)
    } else {
      // Background mode: notify parent session
      await this.notifyParent(team)
    }

    // Clean up delegation mappings
    for (const m of team.members) {
      if (m.delegationId) {
        this.delegationToTeam.delete(m.delegationId)
      }
    }
  }

  /**
   * Resolve team composition from options
   */
  private async resolveTeamComposition(options: CreateTeamOptions): Promise<string[]> {
    const { agents, issueContext } = options

    // Explicit agents provided
    if (agents && agents.length > 0) {
      return agents
    }

    // No agents specified - use small model to auto-select team
    return await this.selectTeamComposition(issueContext)
  }

  /**
   * Select team composition using small model
   */
  private async selectTeamComposition(issueContext: string): Promise<string[]> {
    const agents = await discoverAgents(this.client, this.log)
    if (agents.length === 0) {
      return []
    }

    const agentList = agents
      .map((a) => `- ${a.name}: ${a.description || "(no description)"}`)
      .join("\n")

    const prompt = `Select 2-4 agents to work on this issue as a team.

ISSUE:
${issueContext.slice(0, 1000)}

AVAILABLE AGENTS:
${agentList}

RULES:
1. First agent is PRIMARY - does the main implementation work
2. Other agents REVIEW the primary's work
3. Choose agents with complementary skills
4. Consider: implementation, testing, security, documentation needs

Respond with JSON only:
{"agents": ["primary-agent", "reviewer-1", "reviewer-2"]}`

    const result = await promptSmallModel<{ agents: string[] }>(this.client, this.log, {
      prompt,
      sessionTitle: "Team Composition Selection",
      timeoutMs: this.config.smallModelTimeoutMs,
    })

    if (result.success && result.data?.agents && result.data.agents.length > 0) {
      // Validate agents exist
      const validAgents = result.data.agents.filter((name) =>
        agents.some((a) => a.name === name)
      )
      if (validAgents.length > 0) {
        return validAgents
      }
    }

    // Fallback: select single agent
    await this.log.info("Team composition selection failed, falling back to single agent")
    const selected = await this.selectSingleAgent(agents, issueContext)
    return selected ? [selected] : [agents[0].name]
  }

  /**
   * Select a single agent using small model
   */
  private async selectSingleAgent(agents: AgentInfo[], issueContext: string): Promise<string | null> {
    const agentList = agents
      .map((a) => `- ${a.name}: ${a.description || "(no description)"}`)
      .join("\n")

    const prompt = `Select the best agent for this task.

AVAILABLE AGENTS:
${agentList}

TASK DESCRIPTION:
${issueContext.slice(0, 1000)}

Respond with ONLY valid JSON in this exact format:
{"agent": "agent-name", "reason": "brief reason for selection"}`

    const result = await promptSmallModel<{ agent: string }>(this.client, this.log, {
      prompt,
      sessionTitle: "Agent Selection",
      timeoutMs: this.config.smallModelTimeoutMs,
    })

    if (result.success && result.data?.agent) {
      const valid = agents.find((a) => a.name === result.data!.agent)
      if (valid) {
        return result.data.agent
      }
    }

    return null
  }

  /**
   * Select which non-primary agent should be devil's advocate
   */
  private async selectDevilsAdvocate(
    teamAgents: string[],
    issueContext: string
  ): Promise<string | undefined> {
    const nonPrimary = teamAgents.slice(1)

    if (nonPrimary.length === 0) {
      return undefined
    }

    if (nonPrimary.length === 1) {
      // Only one option
      return nonPrimary[0]
    }

    const prompt = buildDevilsAdvocateSelectionPrompt(teamAgents, issueContext)
    if (!prompt) {
      return nonPrimary[0]
    }

    const result = await promptSmallModel<{ devilsAdvocate: string }>(this.client, this.log, {
      prompt,
      sessionTitle: "Devil's Advocate Selection",
      timeoutMs: this.config.smallModelTimeoutMs,
    })

    if (result.success && result.data?.devilsAdvocate) {
      if (nonPrimary.includes(result.data.devilsAdvocate)) {
        return result.data.devilsAdvocate
      }
    }

    // Fallback to first non-primary
    return nonPrimary[0]
  }

  /**
   * Build the prompt for a team member
   */
  private buildMemberPrompt(team: Team, member: TeamMember, issueContext: string): string {
    const lines: string[] = []

    if (member.role === "primary") {
      lines.push(`# Task: ${team.issueId}`)
      lines.push("")
      lines.push(`You are the PRIMARY agent for this task. Your role: ${member.agent}`)
      lines.push("")
      lines.push("## Issue")
      lines.push("")
      lines.push(issueContext)
      lines.push("")
      lines.push("## Your Responsibilities")
      lines.push("")
      lines.push("1. Complete the main work for this issue")
      lines.push("2. Write code, make changes, implement the solution")
      lines.push("3. Commit your changes with clear messages")

      if (team.worktreePath) {
        lines.push("")
        lines.push("## Worktree")
        lines.push("")
        lines.push(`You are working in an isolated worktree at: ${team.worktreePath}`)
        lines.push("Make all your changes there.")
      }

      if (team.members.length > 1) {
        lines.push("")
        lines.push("## Note")
        lines.push("")
        lines.push("Other agents will review your work. Focus on quality implementation.")
      }
    } else {
      // Secondary or Devil's Advocate
      lines.push(`# Review Task: ${team.issueId}`)
      lines.push("")
      lines.push(`You are a REVIEWER for this task. Your role: ${member.agent}`)
      lines.push("")
      lines.push("## Issue")
      lines.push("")
      lines.push(issueContext)
      lines.push("")

      const primary = team.members.find((m) => m.role === "primary")
      lines.push("## Primary Agent's Work")
      lines.push("")
      lines.push(`The primary agent (${primary?.agent || "unknown"}) is implementing this. Your job is to:`)
      lines.push("1. Review their approach and implementation")
      lines.push("2. Identify issues, risks, or improvements")
      lines.push("3. Provide constructive feedback")

      if (team.worktreePath) {
        lines.push("")
        lines.push("## Worktree")
        lines.push("")
        lines.push(`The code is in an isolated worktree at: ${team.worktreePath}`)
        lines.push("You can read files there to review the implementation.")
        lines.push("Do NOT modify files - you are read-only.")
      }

      if (member.role === "devilsAdvocate") {
        lines.push("")
        lines.push(DEVILS_ADVOCATE_PROMPT)
      }
    }

    lines.push("")
    lines.push("## Constraints")
    lines.push("")
    lines.push("You are running as a background delegation. The following tools are disabled:")
    lines.push("- project-create, project-close, project-create-issue, project-update-issue, project-work-on-issue")
    lines.push("- task, delegate (no recursive delegation)")
    lines.push("")
    lines.push("Focus on completing your assigned role.")

    return lines.join("\n")
  }

  /**
   * Retry a failed member
   */
  private async retryMember(team: Team, member: TeamMember): Promise<void> {
    if (!member.delegationId) return

    // Get the original delegation for context
    const originalDelegation = await this.delegationManager.get(member.delegationId)
    if (!originalDelegation) return

    // Remove old mapping
    this.delegationToTeam.delete(member.delegationId)

    // Create a new delegation
    const delegationOptions: CreateDelegationOptions = {
      issueId: team.issueId,
      prompt: originalDelegation.prompt + "\n\n[RETRY: Previous attempt failed. Please try again.]",
      teamId: team.id,
      role: member.role,
      worktreePath: member.role === "primary" ? team.worktreePath : undefined,
      worktreeBranch: team.worktreeBranch,
      vcs: team.vcs,
      agent: member.agent,
      parentSessionId: team.parentSessionId,
      parentAgent: team.parentAgent,
    }

    const newDelegation = await this.delegationManager.create(team.projectId, delegationOptions)
    member.delegationId = newDelegation.id
    member.sessionId = newDelegation.sessionId
    member.status = "running"

    // Track new delegation
    this.delegationToTeam.set(newDelegation.id, team.id)
  }

  /**
   * Run discussion rounds
   */
  private async runDiscussion(team: Team): Promise<void> {
    await this.log.info(`Team ${team.id}: starting ${team.discussionRounds} discussion round(s)`)

    for (let round = 1; round <= team.discussionRounds; round++) {
      team.currentRound = round
      await this.save(team)

      await this.log.info(`Team ${team.id}: discussion round ${round}/${team.discussionRounds}`)

      const roundResponses: Record<string, string> = {}
      const context = this.buildDiscussionContext(team, round)

      for (const member of team.members) {
        if (!member.sessionId) {
          await this.log.warn(`Team ${team.id}: ${member.agent} has no session for discussion`)
          roundResponses[member.agent] = "(no session)"
          continue
        }

        try {
          const response = await this.sendDiscussionPrompt(team, member, round, context)
          roundResponses[member.agent] = response
          await this.log.debug(`Team ${team.id}: ${member.agent} responded to round ${round}`)
        } catch (error) {
          const errorMsg = error instanceof Error ? error.message : String(error)
          await this.log.warn(`Team ${team.id}: ${member.agent} discussion failed: ${errorMsg}`)
          roundResponses[member.agent] = `(error: ${errorMsg})`
        }
      }

      team.discussionHistory.push({ round, responses: roundResponses })
      await this.save(team)
    }

    await this.log.info(`Team ${team.id}: discussion complete`)
  }

  /**
   * Build context for a discussion round
   */
  private buildDiscussionContext(team: Team, round: number): string {
    const lines: string[] = []

    // Primary agent's work
    const primary = team.members.find((m) => m.role === "primary")
    if (primary && team.results[primary.agent]) {
      lines.push("## Primary Agent's Implementation")
      lines.push("")
      lines.push(team.results[primary.agent].result)
      lines.push("")
    }

    // Other agents' initial findings
    lines.push("## Team Findings")
    lines.push("")
    for (const member of team.members) {
      if (member.role !== "primary" && team.results[member.agent]) {
        lines.push(`### ${member.agent}`)
        lines.push("")
        lines.push(team.results[member.agent].result)
        lines.push("")
      }
    }

    // Previous discussion rounds
    if (round > 1 && team.discussionHistory.length > 0) {
      lines.push("## Previous Discussion")
      lines.push("")
      for (const prevRound of team.discussionHistory) {
        lines.push(`### Round ${prevRound.round}`)
        lines.push("")
        for (const [agent, response] of Object.entries(prevRound.responses)) {
          lines.push(`**${agent}:**`)
          lines.push(response)
          lines.push("")
        }
      }
    }

    return lines.join("\n")
  }

  /**
   * Send a discussion prompt to a member and wait for response
   */
  private async sendDiscussionPrompt(
    team: Team,
    member: TeamMember,
    round: number,
    context: string
  ): Promise<string> {
    const prompt = `# Discussion Round ${round}/${team.discussionRounds}

## Issue: ${team.issueId}

${context}

## Your Task

As ${member.agent}, provide your updated analysis considering:
1. New insights from other agents
2. Remaining concerns
3. Points of agreement or disagreement
4. Final recommendations

Keep response focused and actionable.`

    // Send prompt with noReply: false to get response
    await this.client.session.prompt({
      path: { id: member.sessionId! },
      body: {
        agent: member.agent,
        parts: [{ type: "text", text: prompt }],
        noReply: false,
        tools: DISABLED_TOOLS,
      },
    })

    // Wait for response with timeout
    return await this.waitForResponse(member.sessionId!, this.config.discussionRoundTimeoutMs)
  }

  /**
   * Wait for a response from a session with timeout
   */
  private async waitForResponse(sessionId: string, timeoutMs: number): Promise<string> {
    const startTime = Date.now()
    const pollInterval = 2000 // 2 seconds

    while (Date.now() - startTime < timeoutMs) {
      await this.sleep(pollInterval)

      try {
        const messages = await this.client.session.messages({
          path: { id: sessionId },
        })

        const messageData: MessageItem[] | undefined = messages.data
        if (!messageData || messageData.length === 0) {
          continue
        }

        // Find the last assistant message
        const assistantMessages = messageData.filter((m) => m.info?.role === "assistant")
        if (assistantMessages.length === 0) {
          continue
        }

        const lastMessage = assistantMessages[assistantMessages.length - 1]

        // Check if it's a new message (after our prompt)
        // We look for text content
        const parts: Part[] = lastMessage.parts || []
        const textParts = parts.filter((p) => p.type === "text")
        const text = textParts.map((p) => p.text || "").join("\n")

        if (text && text.length > 0) {
          return text
        }
      } catch (error) {
        await this.log.debug(`Error polling session ${sessionId}: ${error}`)
      }
    }

    throw new Error(`Timeout waiting for response after ${timeoutMs / 1000}s`)
  }

  /**
   * Notify parent session with aggregated team results
   */
  private async notifyParent(team: Team): Promise<void> {
    if (!team.parentSessionId) {
      await this.log.info(`Team ${team.id}: no parent session to notify`)
      return
    }

    const notification = this.buildTeamNotification(team)

    try {
      await this.client.session.prompt({
        path: { id: team.parentSessionId },
        body: {
          noReply: false,
          agent: team.parentAgent,
          parts: [{ type: "text", text: notification }],
        },
      })

      await this.log.info(`Team ${team.id}: notified parent session ${team.parentSessionId}`)
    } catch (error) {
      await this.log.warn(`Team ${team.id}: failed to notify parent: ${error}`)
    }
  }

  /**
   * Build XML notification for parent
   */
  private buildTeamNotification(team: Team): string {
    const lines: string[] = []

    lines.push("<team-notification>")
    lines.push(`  <team-id>${team.id}</team-id>`)
    lines.push(`  <issue>${team.issueId}</issue>`)
    lines.push(`  <status>${team.status}</status>`)

    if (team.worktreePath) {
      lines.push("  <worktree>")
      lines.push(`    <path>${team.worktreePath}</path>`)
      lines.push(`    <branch>${team.worktreeBranch || team.issueId}</branch>`)
      lines.push(`    <vcs>${team.vcs || "unknown"}</vcs>`)
      lines.push("  </worktree>")
    }

    lines.push("  <members>")
    for (const member of team.members) {
      const result = team.results[member.agent]
      lines.push(`    <member agent="${member.agent}" role="${member.role}">`)
      lines.push(`      <status>${member.status}</status>`)
      if (result) {
        lines.push("      <result>")
        lines.push(result.result)
        lines.push("      </result>")
      }
      lines.push("    </member>")
    }
    lines.push("  </members>")

    if (team.discussionHistory.length > 0) {
      lines.push(`  <discussion rounds="${team.discussionHistory.length}">`)
      for (const round of team.discussionHistory) {
        lines.push(`    <round n="${round.round}">`)
        for (const [agent, response] of Object.entries(round.responses)) {
          lines.push(`      <response agent="${agent}">${response}</response>`)
        }
        lines.push("    </round>")
      }
      lines.push("  </discussion>")
    }

    if (team.worktreePath && team.vcs) {
      lines.push("  <merge-instructions>")
      lines.push(this.getMergeInstructions(team))
      lines.push("  </merge-instructions>")
    }

    lines.push("</team-notification>")

    return lines.join("\n")
  }

  /**
   * Get VCS-specific merge instructions
   */
  private getMergeInstructions(team: Team): string {
    const branch = team.worktreeBranch || team.issueId

    if (team.vcs === "jj") {
      return `Review and merge the changes from the jj workspace:
1. Review: \`jj diff --from main --to ${branch}\`
2. Squash: \`jj squash --from ${branch}\` (from main workspace)
3. Clean up: \`jj workspace forget ${branch}\``
    } else {
      return `Review and merge the changes from the git worktree:
1. Review: \`git diff main..${branch}\`
2. Merge: \`git merge ${branch}\`
3. Clean up: \`git worktree remove ${team.worktreePath} && git branch -d ${branch}\``
    }
  }

  /**
   * Get a team by ID
   */
  async get(teamId: string): Promise<Team | null> {
    // Check cache first
    const cached = this.teams.get(teamId)
    if (cached) return cached

    // Load from disk
    try {
      const filePath = path.join(this.teamsDir, `${teamId}.json`)
      const content = await fs.readFile(filePath, "utf8")
      const team = JSON.parse(content) as Team
      this.teams.set(teamId, team)
      return team
    } catch {
      return null
    }
  }

  /**
   * Save a team to disk
   */
  private async save(team: Team): Promise<void> {
    this.teams.set(team.id, team)
    await fs.mkdir(this.teamsDir, { recursive: true })
    const filePath = path.join(this.teamsDir, `${team.id}.json`)
    await fs.writeFile(filePath, JSON.stringify(team, null, 2), "utf8")
  }

  /**
   * List teams for an issue
   */
  async listByIssue(issueId: string): Promise<Team[]> {
    const teams: Team[] = []

    try {
      await fs.mkdir(this.teamsDir, { recursive: true })
      const files = await fs.readdir(this.teamsDir)

      for (const file of files) {
        if (file.endsWith(".json")) {
          const content = await fs.readFile(path.join(this.teamsDir, file), "utf8")
          const team = JSON.parse(content) as Team
          if (team.issueId === issueId) {
            teams.push(team)
          }
        }
      }
    } catch {
      // Directory doesn't exist
    }

    return teams.sort(
      (a, b) => new Date(b.startedAt).getTime() - new Date(a.startedAt).getTime()
    )
  }

  /**
   * Get all running teams
   */
  async getRunningTeams(): Promise<Team[]> {
    const teams: Team[] = []

    try {
      await fs.mkdir(this.teamsDir, { recursive: true })
      const files = await fs.readdir(this.teamsDir)

      for (const file of files) {
        if (file.endsWith(".json")) {
          const content = await fs.readFile(path.join(this.teamsDir, file), "utf8")
          const team = JSON.parse(content) as Team
          if (team.status === "running" || team.status === "discussing") {
            teams.push(team)
          }
        }
      }
    } catch {
      // Directory doesn't exist
    }

    return teams
  }

  /**
   * Generate a unique team ID
   */
  private generateId(): string {
    const timestamp = Date.now().toString(36)
    const random = crypto.randomBytes(4).toString("hex")
    return `team-${timestamp}-${random}`
  }

  /**
   * Sleep utility
   */
  private sleep(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms))
  }
}
