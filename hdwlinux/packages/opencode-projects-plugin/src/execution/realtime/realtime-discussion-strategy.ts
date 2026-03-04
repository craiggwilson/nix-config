/**
 * RealtimeDiscussionStrategy - Group chat model where agents drive the conversation
 *
 * Unlike round-based strategies where the orchestrator prompts each agent in turn,
 * in this strategy:
 * 1. All agents are given a shared channel (JSONL file) at the start
 * 2. Each agent does work, writes thinking to the channel, reads others' messages
 * 3. Agents decide themselves when to signal done
 * 4. The orchestrator watches the channel and waits for all agents to signal completion
 *
 * Transport: Polling-based shared JSONL inbox (one file per team).
 * Latency: 500-2000ms is acceptable for this experimental strategy.
 */

import type { Logger, OpencodeClient } from "../../utils/opencode-sdk/index.js"
import type { Team, TeamMember, DiscussionRound } from "../team-manager.js"
import type { Clock } from "../../utils/clock/index.js"
import type { TeamDiscussionStrategy } from "../discussion-strategy.js"
import { systemClock } from "../../utils/clock/index.js"
import { PermissionManager } from "../permission-manager.js"
import { InboxManager, type InboxMessage } from "./inbox-manager.js"
import { extractSignal } from "../convergence-signal.js"
import { waitForResponse } from "../response-poller.js"

/**
 * Configuration for RealtimeDiscussionStrategy.
 */
export interface RealtimeStrategyConfig {
  /** Base directory for inbox files (typically the project directory) */
  baseDir: string
  /** Polling interval for checking inbox (milliseconds) */
  pollIntervalMs: number
  /** Maximum time to wait for all agents to signal done (milliseconds) */
  maxWaitTimeMs: number
  /** Maximum time to wait for each agent's response per prompt (milliseconds) */
  promptTimeoutMs: number
  /**
   * Minimum number of exchanges each agent must complete before CONVERGED is honored.
   * Prevents trivially short discussions where agents exit after a single message.
   * Defaults to 2.
   */
  minRounds?: number
  /**
   * Number of consecutive poll cycles where any agent signals STUCK before the
   * arbiter is invoked. Prevents triggering on a single transient STUCK signal.
   * Defaults to 2.
   */
  stuckThreshold?: number
  /** Clock for timing operations (optional, uses system clock) */
  clock?: Clock
}

/**
 * Orchestrates realtime team discussions using a polling-based inbox.
 *
 * This strategy enables peer-to-peer agent communication where agents
 * drive the conversation themselves rather than being orchestrated round-by-round.
 *
 * Lifecycle:
 * 1. `onTeamStarted`: Initialize shared inbox, send initial context to all agents
 * 2. `onMemberCompleted`: Agent reads inbox, processes messages, may continue or signal done
 * 3. `onAllMembersCompleted`: Wait for all agents to signal done, then cleanup
 *
 * The strategy converts inbox messages into discussion rounds for compatibility
 * with the existing team infrastructure.
 */
export class RealtimeDiscussionStrategy implements TeamDiscussionStrategy {
  readonly type = "realtime" as const
  readonly memberLaunchOrdering = "concurrent" as const

  private log: Logger
  private client: OpencodeClient
  private config: RealtimeStrategyConfig
  private clock: Clock
  private inboxManager: InboxManager

  /** Tracks cursor position per agent for efficient polling */
  private agentCursors: Map<string, number> = new Map()

  /** Tracks how many chat exchanges each agent has completed */
  private agentExchangeCount: Map<string, number> = new Map()

  /**
   * Tracks how many consecutive poll cycles each agent has signaled STUCK.
   * Resets to 0 when an agent signals CONVERGED or CONTINUE.
   */
  private agentStuckCount: Map<string, number> = new Map()

  /**
   * Version counter per agent. Incremented before each prompt; checked before
   * posting the response to the inbox. Prevents a stale concurrent call from
   * posting a response that belongs to an earlier prompt cycle.
   */
  private agentPromptVersion: Map<string, number> = new Map()

  /**
   * Guards against concurrent `promptAgentToContinue` calls for the same agent.
   * A second call arriving while the first is still awaiting a response is
   * dropped — the in-flight call will post the response when it completes.
   */
  private agentExecuting: Set<string> = new Set()

  /**
   * @param log - Logger for diagnostic output
   * @param client - OpenCode client for session management
   * @param config - Configuration options
   */
  constructor(
    log: Logger,
    client: OpencodeClient,
    config: RealtimeStrategyConfig
  ) {
    this.log = log
    this.client = client
    this.config = config
    this.clock = config.clock ?? systemClock
    this.inboxManager = new InboxManager({
      baseDir: config.baseDir,
      clock: this.clock,
    })
  }

  /**
   * Called once after all member delegations have been started.
   *
   * Initializes the shared inbox and sends a system message announcing
   * the team discussion has started.
   */
  async onTeamStarted(team: Team): Promise<void> {
    await this.log.info(`Team ${team.id}: initializing realtime discussion inbox`)

    // Initialize the inbox
    await this.inboxManager.initialize(team.id)

    // Initialize per-agent state for all members
    for (const member of team.members) {
      this.agentCursors.set(member.agent, 0)
      this.agentExchangeCount.set(member.agent, 0)
      this.agentStuckCount.set(member.agent, 0)
      this.agentPromptVersion.set(member.agent, 0)
    }

    // Send system message announcing the discussion
    await this.inboxManager.sendMessage(team.id, {
      from: "system",
      to: "broadcast",
      text: this.buildTeamStartedMessage(team),
      type: "system",
    })

    await this.log.info(`Team ${team.id}: realtime inbox initialized with ${team.members.length} members`)
  }

  /**
   * Called each time a single member completes their initial work.
   *
   * In realtime mode, this is where we:
   * 1. Post the agent's work result to the shared inbox
   * 2. Prompt the agent to participate in the discussion
   *
   * Note: Returns empty array. Rounds are built in `onAllMembersCompleted`
   * after all agents have signaled done.
   */
  async onMemberCompleted(team: Team, member: TeamMember): Promise<DiscussionRound[]> {
    await this.log.info(`Team ${team.id}: ${member.agent} completed initial work, joining discussion`)

    const rounds: DiscussionRound[] = []

    // Get the member's work result
    const result = team.results[member.agent]
    if (!result) {
      await this.log.warn(`Team ${team.id}: ${member.agent} has no result to share`)
      return rounds
    }

    // Post the agent's work result to the inbox
    await this.inboxManager.sendMessage(team.id, {
      from: member.agent,
      to: "broadcast",
      text: this.formatWorkResult(member.agent, result.result),
      type: "chat",
      metadata: { phase: "initial-work" },
    })

    // If the agent has a session, prompt them to continue the discussion
    if (member.sessionId) {
      try {
        const response = await this.promptAgentForDiscussion(team, member)

        // Post the agent's discussion response to the inbox
        if (response && response.trim().length > 0) {
          await this.inboxManager.sendMessage(team.id, {
            from: member.agent,
            to: "broadcast",
            text: response,
            type: "chat",
            metadata: { phase: "discussion" },
          })

          const exchanges = (this.agentExchangeCount.get(member.agent) ?? 0) + 1
          this.agentExchangeCount.set(member.agent, exchanges)

          // Only honor CONVERGED after the agent has completed the minimum exchanges
          if (this.containsDoneSignal(response) && this.hasMetMinRounds(member.agent)) {
            await this.inboxManager.sendMessage(team.id, {
              from: member.agent,
              to: "broadcast",
              text: `${member.agent} has completed their analysis.`,
              type: "done",
            })
          }
        }
      } catch (error) {
        const errorMsg = error instanceof Error ? error.message : String(error)
        await this.log.warn(`Team ${team.id}: ${member.agent} discussion prompt failed: ${errorMsg}`)
      }
    }

    return rounds
  }

  /**
   * Called when ALL members have finished their initial work.
   *
   * In realtime mode, this is where we:
   * 1. Poll the inbox until all agents have signaled done
   * 2. Convert inbox messages into discussion rounds
   * 3. Clean up the inbox
   *
   * @returns Complete discussion history from the inbox
   */
  async onAllMembersCompleted(
    team: Team,
    onProgress?: (history: DiscussionRound[]) => Promise<void>
  ): Promise<DiscussionRound[]> {
    await this.log.info(`Team ${team.id}: all members completed, monitoring realtime discussion`)

    const agentNames = team.members.map((m) => m.agent)
    const startTime = this.clock.now()
    let arbiterInvoked = false

    try {
      // Poll until all agents signal done or timeout
      while (this.clock.now() - startTime < this.config.maxWaitTimeMs) {
        const allDone = await this.inboxManager.allAgentsDone(team.id, agentNames)

        if (allDone) {
          await this.log.info(`Team ${team.id}: all agents have signaled done`)
          break
        }

        // Check which agents haven't signaled done yet
        const doneAgents = await this.inboxManager.getDoneAgents(team.id)
        const pendingAgents = agentNames.filter((a) => !doneAgents.has(a))

        await this.log.debug(
          `Team ${team.id}: waiting for ${pendingAgents.length} agent(s) to signal done: ${pendingAgents.join(", ")}`
        )

        // Prompt pending agents concurrently to avoid N × timeout blocking
        const pendingMembers = pendingAgents
          .map((agentName) => team.members.find((m) => m.agent === agentName))
          .filter((m): m is TeamMember => m !== undefined && m.sessionId !== undefined)

        if (pendingMembers.length > 0) {
          const promptResults = await Promise.allSettled(
            pendingMembers.map((member) => this.promptAgentToContinue(team, member))
          )

          // Log any failures
          for (let i = 0; i < promptResults.length; i++) {
            const result = promptResults[i]
            if (result.status === "rejected") {
              const errorMsg = result.reason instanceof Error ? result.reason.message : String(result.reason)
              await this.log.debug(`Team ${team.id}: ${pendingMembers[i].agent} continue prompt failed: ${errorMsg}`)
            }
          }
        }

        // Check if the team is deadlocked — any agent stuck for too many consecutive cycles
        if (!arbiterInvoked && this.isTeamDeadlocked()) {
          await this.log.info(`Team ${team.id}: team is deadlocked, invoking arbiter`)
          arbiterInvoked = true
          await this.invokeArbiter(team)
        }

        await this.clock.sleep(this.config.pollIntervalMs)
      }

      // Convert inbox messages to discussion rounds
      const discussionHistory = await this.convertInboxToRounds(team)

      if (onProgress) {
        await onProgress(discussionHistory)
      }

      await this.log.info(`Team ${team.id}: realtime discussion complete with ${discussionHistory.length} round(s)`)

      return discussionHistory
    } finally {
      // Always cleanup inbox, even on error
      await this.inboxManager.cleanup(team.id)
      this.agentCursors.clear()
      this.agentExchangeCount.clear()
      this.agentStuckCount.clear()
      this.agentPromptVersion.clear()
      this.agentExecuting.clear()
    }
  }

  /**
   * Build the initial system message announcing the team discussion.
   */
  private buildTeamStartedMessage(team: Team): string {
    const memberList = team.members
      .map((m) => `- ${m.agent} (${m.role})`)
      .join("\n")

    const minRounds = this.config.minRounds ?? 2

    return `# Realtime Team Discussion Started

## Issue: ${team.issueId}

## Team Members
${memberList}

## Instructions

This is a realtime peer-to-peer discussion. You are expected to actively engage with your teammates — not just share your own analysis in isolation.

**Your obligations in every response:**
1. Directly address at least one specific point made by another agent (quote or paraphrase it)
2. Either agree with reasoning (and explain why), or challenge it with a concrete counter-argument
3. Raise any concerns, gaps, or risks you see in others' positions
4. Share additional insights that build on or contradict what others have said

**Do NOT signal CONVERGED unless you have:**
- Read and responded to every substantive point raised by other agents
- Either resolved your disagreements or explicitly accepted the trade-offs
- Confirmed there are no remaining concerns you haven't voiced

End each response with exactly one of these signals on its own line:

**CONVERGED** - You have exhausted your contributions and have nothing more to add. For the devil's advocate, this means you have no remaining blockers — not that you agree, but that you cannot find further reason to prevent convergence.
**STUCK** - There is a blocker that is not being addressed. Use this to veto convergence until the issue is resolved.
**CONTINUE** - You have more to contribute; explain what still needs to be resolved.

The discussion ends only when ALL agents signal CONVERGED. Any agent signaling STUCK prevents convergence.

**Minimum exchanges:** Each agent must complete at least ${minRounds} exchanges before CONVERGED is honored. CONVERGED signals before that threshold are treated as CONTINUE.`
  }

  /**
   * Format an agent's work result for posting to the inbox.
   */
  private formatWorkResult(agentName: string, result: string): string {
    return `## ${agentName}'s Initial Analysis

${result}`
  }

  /**
   * Prompt an agent to participate in the discussion.
   */
  private async promptAgentForDiscussion(
    team: Team,
    member: TeamMember
  ): Promise<string> {
    // Read recent messages from the inbox
    const cursor = this.agentCursors.get(member.agent) ?? 0
    const { messages, cursor: newCursor } = await this.inboxManager.readMessages(team.id, cursor)
    this.agentCursors.set(member.agent, newCursor)

    const inboxContext = this.formatInboxMessages(messages, member.agent)

    const minRounds = this.config.minRounds ?? 2
    const exchanges = this.agentExchangeCount.get(member.agent) ?? 0
    const remainingExchanges = Math.max(0, minRounds - exchanges - 1)
    const minRoundsNote = remainingExchanges > 0
      ? `\n**Note:** You must complete at least ${remainingExchanges} more exchange(s) before CONVERGED will be honored. Use CONTINUE for now.`
      : ""

    const prompt = buildDiscussionPrompt(team.issueId, inboxContext, minRoundsNote)

    const toolPermissions = PermissionManager.resolvePermissions(member.role)

    await this.client.session.prompt({
      path: { id: member.sessionId! },
      body: {
        agent: member.agent,
        parts: [{ type: "text", text: prompt }],
        noReply: false,
        tools: toolPermissions,
      },
    })

    return await waitForResponse(this.client, member.sessionId!, this.config.promptTimeoutMs, this.clock, this.log)
  }

  /**
   * Prompt an agent to continue the discussion or signal done.
   *
   * Guards against concurrent calls for the same agent: if a call is already
   * in-flight, the new call is dropped. The in-flight call will post the
   * response when it completes.
   */
  private async promptAgentToContinue(
    team: Team,
    member: TeamMember
  ): Promise<void> {
    // Drop concurrent calls for the same agent — the in-flight call handles it
    if (this.agentExecuting.has(member.agent)) {
      await this.log.debug(`Team ${team.id}: ${member.agent} already executing, skipping concurrent prompt`)
      return
    }

    // Read new messages since last check
    const cursor = this.agentCursors.get(member.agent) ?? 0
    const { messages, cursor: newCursor } = await this.inboxManager.readMessages(team.id, cursor)

    // Only prompt if there are new messages
    if (messages.length === 0) {
      return
    }

    this.agentCursors.set(member.agent, newCursor)

    // Increment version before sending the prompt so we can detect if a newer
    // prompt cycle supersedes this one before we post the response
    const version = (this.agentPromptVersion.get(member.agent) ?? 0) + 1
    this.agentPromptVersion.set(member.agent, version)

    this.agentExecuting.add(member.agent)
    try {
      const inboxContext = this.formatInboxMessages(messages, member.agent)

      const minRounds = this.config.minRounds ?? 2
      const exchanges = this.agentExchangeCount.get(member.agent) ?? 0
      const remainingExchanges = Math.max(0, minRounds - exchanges - 1)
      const minRoundsNote = remainingExchanges > 0
        ? `\n**Note:** You must complete at least ${remainingExchanges} more exchange(s) before CONVERGED will be honored. Use CONTINUE for now.`
        : ""

      const prompt = buildContinuationPrompt(team.issueId, inboxContext, minRoundsNote)

      const toolPermissions = PermissionManager.resolvePermissions(member.role)

      await this.client.session.prompt({
        path: { id: member.sessionId! },
        body: {
          agent: member.agent,
          parts: [{ type: "text", text: prompt }],
          noReply: false,
          tools: toolPermissions,
        },
      })

      const response = await waitForResponse(this.client, member.sessionId!, this.config.promptTimeoutMs, this.clock, this.log)

      // Discard the response if a newer prompt cycle has already superseded this one
      if (this.agentPromptVersion.get(member.agent) !== version) {
        await this.log.debug(`Team ${team.id}: ${member.agent} response discarded (stale version ${version})`)
        return
      }

      if (response && response.trim().length > 0) {
        // Post response to inbox
        await this.inboxManager.sendMessage(team.id, {
          from: member.agent,
          to: "broadcast",
          text: response,
          type: "chat",
          metadata: { phase: "continuation" },
        })

        const currentExchanges = (this.agentExchangeCount.get(member.agent) ?? 0) + 1
        this.agentExchangeCount.set(member.agent, currentExchanges)

        // Track STUCK signals to detect deadlock; reset on any other signal
        const signal = extractSignal(response)
        if (signal === "STUCK") {
          const stuckCount = (this.agentStuckCount.get(member.agent) ?? 0) + 1
          this.agentStuckCount.set(member.agent, stuckCount)
        } else {
          this.agentStuckCount.set(member.agent, 0)
        }

        // Only honor CONVERGED after the agent has completed the minimum exchanges
        if (this.containsDoneSignal(response) && this.hasMetMinRounds(member.agent)) {
          await this.inboxManager.sendMessage(team.id, {
            from: member.agent,
            to: "broadcast",
            text: `${member.agent} has completed their analysis.`,
            type: "done",
          })
        }
      }
    } catch (error) {
      // Timeout or error — agent may be busy, will retry on next poll
    } finally {
      this.agentExecuting.delete(member.agent)
    }
  }

  /**
   * Format inbox messages for display to an agent.
   */
  private formatInboxMessages(messages: InboxMessage[], excludeAgent?: string): string {
    const filtered = messages.filter((m) => m.from !== excludeAgent && m.from !== "system")

    if (filtered.length === 0) {
      return ""
    }

    return filtered
      .map((m) => {
        const timestamp = new Date(m.timestamp).toISOString()
        return `**[${timestamp}] ${m.from}:**\n${m.text}`
      })
      .join("\n\n---\n\n")
  }

  /**
   * Check if a response signals that the agent is done contributing.
   *
   * An agent is done when they signal CONVERGED. STUCK is not done — it is a
   * veto that keeps the discussion open. CONTINUE means more work remains.
   */
  private containsDoneSignal(response: string): boolean {
    return extractSignal(response) === "CONVERGED"
  }

  /**
   * Check if an agent has completed the minimum number of exchanges required
   * before their CONVERGED signal can be honored.
   */
  private hasMetMinRounds(agentName: string): boolean {
    const minRounds = this.config.minRounds ?? 2
    const exchanges = this.agentExchangeCount.get(agentName) ?? 0
    return exchanges >= minRounds
  }

  /**
   * Check if the team is deadlocked — any agent has signaled STUCK for at least
   * `stuckThreshold` consecutive poll cycles without making progress.
   */
  private isTeamDeadlocked(): boolean {
    const threshold = this.config.stuckThreshold ?? 2
    for (const count of this.agentStuckCount.values()) {
      if (count >= threshold) {
        return true
      }
    }
    return false
  }

  /**
   * Invoke the primary agent as arbiter to break a deadlock.
   *
   * Posts the arbiter's decision to the inbox so all agents can see it and
   * potentially unblock. The arbiter is the primary agent acting as final
   * decision-maker with full visibility into the discussion history.
   */
  private async invokeArbiter(team: Team): Promise<void> {
    const primary = team.members.find((m) => m.role === "primary")
    if (!primary?.sessionId) {
      await this.log.warn(`Team ${team.id}: no primary agent available for arbiter`)
      return
    }

    const allMessages = await this.inboxManager.readAllMessages(team.id)
    const stuckAgents = Array.from(this.agentStuckCount.entries())
      .filter(([, count]) => count >= (this.config.stuckThreshold ?? 2))
      .map(([agent]) => agent)

    const prompt = buildArbiterPrompt(team.issueId, stuckAgents, allMessages)
    const toolPermissions = PermissionManager.resolvePermissions(primary.role)

    try {
      await this.client.session.prompt({
        path: { id: primary.sessionId },
        body: {
          agent: primary.agent,
          parts: [{ type: "text", text: prompt }],
          noReply: false,
          tools: toolPermissions,
        },
      })

      const response = await waitForResponse(this.client, primary.sessionId, this.config.promptTimeoutMs, this.clock, this.log)

      if (response && response.trim().length > 0) {
        await this.inboxManager.sendMessage(team.id, {
          from: `${primary.agent} (arbiter)`,
          to: "broadcast",
          text: response,
          type: "chat",
          metadata: { phase: "arbiter" },
        })

        // Reset stuck counts so agents can respond to the arbiter's decision
        for (const agent of this.agentStuckCount.keys()) {
          this.agentStuckCount.set(agent, 0)
        }

        await this.log.info(`Team ${team.id}: arbiter decision posted to inbox`)
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error)
      await this.log.warn(`Team ${team.id}: arbiter invocation failed: ${errorMsg}`)
    }
  }

  /**
   * Convert inbox messages into discussion rounds.
   *
   * Groups messages by time windows to create logical "rounds" for
   * compatibility with the existing team infrastructure.
   */
  private async convertInboxToRounds(team: Team): Promise<DiscussionRound[]> {
    const messages = await this.inboxManager.readAllMessages(team.id)

    // Filter out system and done messages
    const chatMessages = messages.filter(
      (m) => m.type === "chat" && m.from !== "system"
    )

    if (chatMessages.length === 0) {
      return []
    }

    // Group messages into rounds based on time windows (5 minute windows)
    const roundWindowMs = 5 * 60 * 1000
    const rounds: DiscussionRound[] = []
    let currentRound: DiscussionRound | null = null
    let roundStartTime = 0

    for (const message of chatMessages) {
      if (!currentRound || message.timestamp - roundStartTime > roundWindowMs) {
        // Start a new round
        if (currentRound) {
          rounds.push(currentRound)
        }
        currentRound = {
          round: rounds.length + 1,
          responses: {},
        }
        roundStartTime = message.timestamp
      }

      // Add message to current round
      // If agent already has a response in this round, append to it
      if (currentRound.responses[message.from]) {
        currentRound.responses[message.from] += "\n\n---\n\n" + message.text
      } else {
        currentRound.responses[message.from] = message.text
      }
    }

    // Don't forget the last round
    if (currentRound && Object.keys(currentRound.responses).length > 0) {
      rounds.push(currentRound)
    }

    return rounds
  }

  /**
   * Get the inbox manager for testing purposes.
   * @internal
   */
  get _inboxManager(): InboxManager {
    return this.inboxManager
  }

  /**
   * Get the exchange count map for testing purposes.
   * @internal
   */
  get _agentExchangeCount(): Map<string, number> {
    return this.agentExchangeCount
  }

  /**
   * Get the stuck count map for testing purposes.
   * @internal
   */
  get _agentStuckCount(): Map<string, number> {
    return this.agentStuckCount
  }

  /**
   * Get the prompt version map for testing purposes.
   * @internal
   */
  get _agentPromptVersion(): Map<string, number> {
    return this.agentPromptVersion
  }

  /**
   * Get the executing agents set for testing purposes.
   * @internal
   */
  get _agentExecuting(): Set<string> {
    return this.agentExecuting
  }

}

/**
 * Build the initial discussion prompt for an agent joining the realtime discussion.
 *
 * Instructs the agent to contribute to the discussion and end with an explicit
 * convergence signal so the orchestrator can determine when all agents are done.
 */
export function buildDiscussionPrompt(issueId: string, inboxContext: string, minRoundsNote = ""): string {
  return `# Realtime Discussion - ${issueId}

## Messages from Your Teammates
${inboxContext || "(No messages yet — share your initial analysis and any concerns)"}

## Your Task

Engage substantively with your teammates. You must:
1. **Directly respond** to specific points made by other agents — quote or paraphrase what they said, then agree or push back with reasoning
2. **Challenge positions** you find incomplete, risky, or wrong — do not let weak arguments pass unchallenged
3. **Raise concerns** about gaps, risks, or trade-offs that haven't been addressed
4. **Build on agreements** by adding depth, caveats, or implementation considerations

Do NOT signal CONVERGED unless you have responded to every substantive point from other agents and have no remaining concerns to voice.

End your response with exactly one of these signals on its own line:

**CONVERGED** - You have exhausted your contributions and have nothing more to add. For the devil's advocate, this means you have no remaining blockers — not that you agree, but that you cannot find further reason to prevent convergence.
**STUCK** - There is a blocker that is not being addressed. Use this to veto convergence until the issue is resolved.
**CONTINUE** - You have more to contribute; explain what still needs to be resolved.
${minRoundsNote}`
}

/**
 * Build the continuation prompt for an agent with new inbox messages.
 *
 * Used when polling detects new messages for an agent that has not yet signaled
 * CONVERGED. Instructs the agent to respond and re-emit a convergence signal.
 */
export function buildContinuationPrompt(issueId: string, inboxContext: string, minRoundsNote = ""): string {
  return `# New Messages in Discussion - ${issueId}

${inboxContext}

## Your Task

Your teammates have spoken — now respond directly to what they said. You must:
1. **Address specific points** — pick out the key claims or arguments and respond to each one explicitly
2. **Challenge or affirm with reasoning** — don't just say "I agree" or "I disagree"; explain *why*
3. **Raise anything unresolved** — if a concern hasn't been addressed, say so clearly

Only signal CONVERGED if you have genuinely engaged with all outstanding points and have nothing more to add. If you haven't yet responded to something important, signal CONTINUE and address it.

End your response with exactly one of these signals on its own line:

**CONVERGED** - You have exhausted your contributions and have nothing more to add. For the devil's advocate, this means you have no remaining blockers — not that you agree, but that you cannot find further reason to prevent convergence.
**STUCK** - There is a blocker that is not being addressed; use this to prevent convergence.
**CONTINUE** - You have more to contribute; explain what still needs to be resolved.
${minRoundsNote}`
}

/**
 * Build the arbiter prompt for the primary agent to break a realtime deadlock.
 *
 * Unlike the dynamicRound arbiter which receives structured discussion rounds,
 * this arbiter receives the raw inbox message history so it has full context
 * of the peer-to-peer conversation that led to the deadlock.
 */
export function buildArbiterPrompt(
  issueId: string,
  stuckAgents: string[],
  inboxMessages: InboxMessage[]
): string {
  const chatMessages = inboxMessages.filter((m) => m.type === "chat" && m.from !== "system")
  const historyText = chatMessages
    .map((m) => {
      const timestamp = new Date(m.timestamp).toISOString()
      return `**[${timestamp}] ${m.from}:**\n${m.text}`
    })
    .join("\n\n---\n\n")

  const stuckList = stuckAgents.length > 0
    ? `The following agent(s) are stuck: ${stuckAgents.join(", ")}.`
    : "The team has been unable to converge."

  return `# Arbiter Decision Required

## Issue: ${issueId}

The realtime discussion has reached a deadlock. ${stuckList}

## Full Discussion History

${historyText || "(No messages yet)"}

## Your Role as Arbiter

You are the primary agent and final decision-maker. Review the full discussion and:

1. Identify the core points of disagreement
2. Evaluate the merits of each position
3. Make a final binding decision that resolves the deadlock
4. Explain your reasoning clearly

Your decision will be posted to the shared inbox so all agents can see it. Be decisive and specific. After your decision, agents will have the opportunity to signal CONVERGED.

End your response with exactly one of these signals on its own line:

**CONVERGED** - Your decision resolves the deadlock and you have nothing more to add.
**CONTINUE** - Your decision is posted but you expect further discussion before convergence.`
}
