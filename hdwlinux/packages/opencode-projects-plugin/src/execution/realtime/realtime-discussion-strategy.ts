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

import type { Logger, OpencodeClient, MessageItem, Part } from "../../utils/opencode-sdk/index.js"
import type { Team, TeamMember, DiscussionRound } from "../team-manager.js"
import type { Clock } from "../../utils/clock/index.js"
import type { TeamDiscussionStrategy } from "../discussion-strategy.js"
import { systemClock } from "../../utils/clock/index.js"
import { PermissionManager } from "../permission-manager.js"
import { InboxManager, type InboxMessage } from "./inbox-manager.js"

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
  /** Clock for timing operations (optional, uses system clock) */
  clock?: Clock
}

/**
 * Default configuration values.
 */
const DEFAULT_POLL_INTERVAL_MS = 1000
const DEFAULT_MAX_WAIT_TIME_MS = 30 * 60 * 1000 // 30 minutes
const DEFAULT_PROMPT_TIMEOUT_MS = 5 * 60 * 1000 // 5 minutes

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

  private log: Logger
  private client: OpencodeClient
  private config: RealtimeStrategyConfig
  private clock: Clock
  private inboxManager: InboxManager

  /** Tracks cursor position per agent for efficient polling */
  private agentCursors: Map<string, number> = new Map()

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
    this.config = {
      ...config,
      pollIntervalMs: config.pollIntervalMs ?? DEFAULT_POLL_INTERVAL_MS,
      maxWaitTimeMs: config.maxWaitTimeMs ?? DEFAULT_MAX_WAIT_TIME_MS,
      promptTimeoutMs: config.promptTimeoutMs ?? DEFAULT_PROMPT_TIMEOUT_MS,
    }
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

    // Initialize cursors for all agents
    for (const member of team.members) {
      this.agentCursors.set(member.agent, 0)
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

          // Check if the agent signaled done
          if (this.containsDoneSignal(response)) {
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
    }
  }

  /**
   * Build the initial system message announcing the team discussion.
   */
  private buildTeamStartedMessage(team: Team): string {
    const memberList = team.members
      .map((m) => `- ${m.agent} (${m.role})`)
      .join("\n")

    return `# Realtime Team Discussion Started

## Issue: ${team.issueId}

## Team Members
${memberList}

## Instructions

This is a realtime discussion channel. You can:
1. Share your findings and analysis
2. Read and respond to other agents' messages
3. Ask questions or raise concerns
4. Signal when you're done with your analysis

When you have completed your analysis and have no more to add, include "DONE" in your response.

The discussion will continue until all agents signal completion.`
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

    const prompt = `# Realtime Discussion - ${team.issueId}

## Recent Messages from Team
${inboxContext || "(No new messages)"}

## Your Task

Review the messages above and contribute to the discussion:
1. Share any additional insights or concerns
2. Respond to questions from other agents
3. Highlight points of agreement or disagreement

When you have completed your analysis and have nothing more to add, include "DONE" on its own line.

Keep your response focused and actionable.`

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

    return await this.waitForResponse(member.sessionId!, this.config.promptTimeoutMs)
  }

  /**
   * Prompt an agent to continue the discussion or signal done.
   */
  private async promptAgentToContinue(
    team: Team,
    member: TeamMember
  ): Promise<void> {
    // Read new messages since last check
    const cursor = this.agentCursors.get(member.agent) ?? 0
    const { messages, cursor: newCursor } = await this.inboxManager.readMessages(team.id, cursor)

    // Only prompt if there are new messages
    if (messages.length === 0) {
      return
    }

    this.agentCursors.set(member.agent, newCursor)

    const inboxContext = this.formatInboxMessages(messages, member.agent)

    const prompt = `# New Messages in Discussion - ${team.issueId}

${inboxContext}

## Your Task

Review the new messages and either:
1. Respond with additional insights or concerns
2. Signal "DONE" if you have nothing more to add

Keep your response brief.`

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

    try {
      const response = await this.waitForResponse(member.sessionId!, this.config.promptTimeoutMs)

      if (response && response.trim().length > 0) {
        // Post response to inbox
        await this.inboxManager.sendMessage(team.id, {
          from: member.agent,
          to: "broadcast",
          text: response,
          type: "chat",
          metadata: { phase: "continuation" },
        })

        // Check for done signal
        if (this.containsDoneSignal(response)) {
          await this.inboxManager.sendMessage(team.id, {
            from: member.agent,
            to: "broadcast",
            text: `${member.agent} has completed their analysis.`,
            type: "done",
          })
        }
      }
    } catch (error) {
      // Timeout or error - agent may be busy, will retry on next poll
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
   * Check if a response contains a "done" signal.
   *
   * Requires "DONE" to appear as a standalone line (case-insensitive).
   * This avoids false positives like "ABANDONED" or "I AM NOT DONE".
   */
  private containsDoneSignal(response: string): boolean {
    const lines = response.split("\n").map((l) => l.trim().toUpperCase())
    return lines.some((line) => line === "DONE")
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
   * Wait for a response from a session with timeout.
   */
  private async waitForResponse(
    sessionId: string,
    timeoutMs: number
  ): Promise<string> {
    const startTime = this.clock.now()
    const pollInterval = 2000

    while (this.clock.now() - startTime < timeoutMs) {
      await this.clock.sleep(pollInterval)

      try {
        const messages = await this.client.session.messages({
          path: { id: sessionId },
        })

        const messageData: MessageItem[] | undefined = messages.data
        if (!messageData || messageData.length === 0) {
          continue
        }

        const assistantMessages = messageData.filter(
          (m) => m.info?.role === "assistant"
        )
        if (assistantMessages.length === 0) {
          continue
        }

        const lastMessage = assistantMessages[assistantMessages.length - 1]
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
   * Get the inbox manager for testing purposes.
   * @internal
   */
  get _inboxManager(): InboxManager {
    return this.inboxManager
  }
}
