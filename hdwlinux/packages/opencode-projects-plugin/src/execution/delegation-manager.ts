/**
 * DelegationManager - Manages background agent delegations
 *
 * Implements fire-and-forget delegation with:
 * - Background execution (no await on prompts)
 * - Session idle event handling for completion
 * - Configurable timeout
 * - Title/description generation via small model
 *
 * Note: Parent notification is handled by TeamManager.
 * All delegations are now part of a team (even single-agent work).
 */

import * as fs from "node:fs/promises"
import * as path from "node:path"
import * as crypto from "node:crypto"

import type { Logger, OpencodeClient, MessageItem, Part, TeamMemberRole } from "../core/types.js"
import { promptSmallModel } from "../core/small-model.js"
import type { TeamManager } from "./team-manager.js"

/**
 * Delegation status
 */
export type DelegationStatus = "pending" | "running" | "completed" | "failed" | "cancelled" | "timeout"

/**
 * Delegation record
 */
export interface Delegation {
  id: string
  projectId: string
  issueId: string
  teamId: string
  role: TeamMemberRole
  worktreePath?: string
  worktreeBranch?: string
  vcs?: "git" | "jj"
  status: DelegationStatus
  sessionId?: string
  parentSessionId?: string
  parentAgent?: string
  agent?: string
  prompt: string
  title?: string
  description?: string
  result?: string
  error?: string
  startedAt: string
  completedAt?: string
}

/**
 * Options for creating a delegation
 */
export interface CreateDelegationOptions {
  issueId: string
  prompt: string
  teamId: string
  role: TeamMemberRole
  worktreePath?: string
  worktreeBranch?: string
  vcs?: "git" | "jj"
  agent?: string
  parentSessionId?: string
  parentAgent?: string
}

/**
 * Options for DelegationManager constructor
 */
export interface DelegationManagerOptions {
  /** Timeout for delegations in milliseconds */
  timeoutMs: number
  /** Timeout for small model queries in milliseconds */
  smallModelTimeoutMs: number
}

/**
 * Tools to disable in delegated sessions to prevent recursion and state modification
 */
const DISABLED_TOOLS: Record<string, boolean> = {
  // Prevent recursive delegation
  task: false,
  delegate: false,

  // Prevent state modifications
  todowrite: false,
  plan_save: false,
  "project-create": false,
  "project-close": false,
  "project-create-issue": false,
  "project-update-issue": false,
  "project-work-on-issue": false,
}

/**
 * DelegationManager - manages background delegations with fire-and-forget execution
 */
export class DelegationManager {
  private projectDir: string
  private delegationsDir: string
  private log: Logger
  private client?: OpencodeClient
  private timeoutMs: number
  private smallModelTimeoutMs: number
  private teamManager!: TeamManager

  // Session ID -> Delegation ID mapping for event lookup
  private sessionToDelegation: Map<string, string> = new Map()

  // In-memory delegation cache for fast lookup
  private delegations: Map<string, Delegation> = new Map()

  constructor(
    projectDir: string,
    log: Logger,
    client: OpencodeClient | undefined,
    options: DelegationManagerOptions
  ) {
    this.projectDir = projectDir
    this.delegationsDir = path.join(projectDir, "delegations")
    this.log = log
    this.client = client
    this.timeoutMs = options.timeoutMs
    this.smallModelTimeoutMs = options.smallModelTimeoutMs
  }

  /**
   * Set the team manager (called after construction to resolve circular dependency)
   */
  setTeamManager(teamManager: TeamManager): void {
    this.teamManager = teamManager
  }

  /**
   * Start a delegation in the background (fire-and-forget)
   */
  private async startDelegation(delegation: Delegation): Promise<void> {
    if (!this.client) return

    try {
      delegation.status = "running"
      this.delegations.set(delegation.id, delegation)
      await this.save(delegation)

      // Create a session for the delegation
      const sessionResult = await this.client.session.create({
        body: {
          title: `Delegation: ${delegation.issueId} (${delegation.role})`,
          parentID: delegation.parentSessionId,
        },
      })

      const sessionId = sessionResult.data?.id
      if (!sessionId) {
        await this.fail(delegation.id, "Failed to create session")
        return
      }

      delegation.sessionId = sessionId
      this.sessionToDelegation.set(sessionId, delegation.id)
      this.delegations.set(delegation.id, delegation)
      await this.save(delegation)

      // Set up timeout handler
      setTimeout(() => {
        this.handleTimeout(delegation.id)
      }, this.timeoutMs)

      // Fire the prompt (fire-and-forget)
      // Prompt is built by TeamManager, we just send it
      this.client.session
        .prompt({
          path: { id: sessionId },
          body: {
            agent: delegation.agent,
            parts: [{ type: "text", text: delegation.prompt }],
            tools: DISABLED_TOOLS,
          },
        })
        .catch(async (error: Error) => {
          await this.log.error(`Delegation ${delegation.id} prompt failed: ${error.message}`)
          await this.fail(delegation.id, error.message)
          // Notify TeamManager of failure
          await this.teamManager.handleDelegationComplete(delegation.id)
        })

      await this.log.info(`Delegation ${delegation.id} started in background (session: ${sessionId})`)
    } catch (error) {
      await this.log.error(`Failed to start delegation: ${error}`)
      delegation.status = "failed"
      delegation.error = String(error)
      this.delegations.set(delegation.id, delegation)
      await this.save(delegation)
    }
  }

  /**
   * Handle session.idle event - called when a delegated session becomes idle
   * 
   * This is the primary completion handler. The session.idle event fires when
   * the agent has finished processing and is waiting for input.
   */
  async handleSessionIdle(sessionId: string): Promise<void> {
    const delegationId = this.sessionToDelegation.get(sessionId)
    if (!delegationId) return

    // Try in-memory cache first, fall back to disk
    let delegation: Delegation | null | undefined = this.delegations.get(delegationId)
    if (!delegation) {
      delegation = await this.get(delegationId)
    }
    if (!delegation || delegation.status !== "running") return

    await this.log.info(`Delegation ${delegation.id} session idle, marking complete`)

    // Get the result from session messages
    const result = await this.getSessionResult(sessionId)

    // Generate title and description using small model
    const metadata = await this.generateMetadata(result)

    // Update delegation
    delegation.status = "completed"
    delegation.result = result
    delegation.title = metadata.title
    delegation.description = metadata.description
    delegation.completedAt = new Date().toISOString()

    // Update in-memory cache and persist
    this.delegations.set(delegation.id, delegation)
    await this.save(delegation)

    // Persist result to file
    await this.persistResult(delegation)

    // Notify TeamManager (handles parent notification)
    await this.teamManager.handleDelegationComplete(delegation.id)

    // Clean up session mapping
    this.sessionToDelegation.delete(sessionId)
  }

  /**
   * Find a delegation by its session ID
   */
  findBySession(sessionId: string): string | undefined {
    return this.sessionToDelegation.get(sessionId)
  }

  /**
   * Get a delegation by ID
   */
  async get(delegationId: string): Promise<Delegation | null> {
    // Issue #6: Check in-memory cache first
    const cached = this.delegations.get(delegationId)
    if (cached) return cached

    try {
      const filePath = path.join(this.delegationsDir, `${delegationId}.json`)
      const content = await fs.readFile(filePath, "utf8")
      const delegation = JSON.parse(content) as Delegation
      // Cache for future lookups
      this.delegations.set(delegationId, delegation)
      return delegation
    } catch {
      return null
    }
  }

  /**
   * List all delegations
   */
  async list(options?: { status?: DelegationStatus; issueId?: string }): Promise<Delegation[]> {
    const delegations: Delegation[] = []

    try {
      await fs.mkdir(this.delegationsDir, { recursive: true })
      const files = await fs.readdir(this.delegationsDir)

      for (const file of files) {
        if (file.endsWith(".json")) {
          const content = await fs.readFile(path.join(this.delegationsDir, file), "utf8")
          const delegation = JSON.parse(content) as Delegation
          delegations.push(delegation)
        }
      }
    } catch {
      // Directory doesn't exist
    }

    let filtered = delegations

    if (options?.status) {
      filtered = filtered.filter((d) => d.status === options.status)
    }

    if (options?.issueId) {
      filtered = filtered.filter((d) => d.issueId === options.issueId)
    }

    return filtered.sort(
      (a, b) => new Date(b.startedAt).getTime() - new Date(a.startedAt).getTime()
    )
  }

/**
   * Create and start a new delegation
   */
  async create(projectId: string, options: CreateDelegationOptions): Promise<Delegation> {
    const {
      issueId,
      prompt,
      teamId,
      role,
      worktreePath,
      worktreeBranch,
      vcs,
      agent,
      parentSessionId,
      parentAgent,
    } = options

    // Generate delegation ID
    const delegationId = this.generateId()
    const now = new Date().toISOString()

    // Create delegation record
    const delegation: Delegation = {
      id: delegationId,
      projectId,
      issueId,
      teamId,
      role,
      worktreePath,
      worktreeBranch,
      vcs,
      status: "pending",
      parentSessionId,
      parentAgent,
      agent,
      prompt,
      startedAt: now,
    }

    // Save initial state
    this.delegations.set(delegationId, delegation)
    await this.save(delegation)

    await this.log.info(`Created delegation ${delegationId} for issue ${issueId} (team: ${teamId}, role: ${role})`)

    // Start the delegation
    await this.startDelegation(delegation)

    return delegation
  }

  /**
   * Get recent completed delegations for compaction context (Issue #7)
   */
  async getRecentCompletedDelegations(limit: number = 10): Promise<Delegation[]> {
    const all = await this.list()
    return all
      .filter((d) => d.status === "completed" || d.status === "failed" || d.status === "timeout")
      .slice(0, limit)
  }

  /**
   * Mark a delegation as complete with result
   */
  async complete(delegationId: string, result: string): Promise<boolean> {
    const delegation = await this.get(delegationId)
    if (!delegation) return false

    delegation.status = "completed"
    delegation.result = result
    delegation.completedAt = new Date().toISOString()

    await this.save(delegation)
    await this.persistResult(delegation)
    await this.log.info(`Delegation ${delegationId} completed`)

    return true
  }

  /**
   * Mark a delegation as failed
   */
  async fail(delegationId: string, error: string): Promise<boolean> {
    const delegation = await this.get(delegationId)
    if (!delegation) return false

    delegation.status = "failed"
    delegation.error = error
    delegation.completedAt = new Date().toISOString()

    await this.save(delegation)
    await this.persistResult(delegation)
    await this.log.warn(`Delegation ${delegationId} failed: ${error}`)

    return true
  }

  /**
   * Cancel a delegation
   */
  async cancel(delegationId: string): Promise<boolean> {
    const delegation = await this.get(delegationId)
    if (!delegation) return false

    if (delegation.status === "completed" || delegation.status === "failed") {
      return false
    }

    delegation.status = "cancelled"
    delegation.completedAt = new Date().toISOString()

    // Try to delete the session
    if (delegation.sessionId && this.client) {
      try {
        await this.client.session.delete({ path: { id: delegation.sessionId } })
      } catch {
        // Ignore
      }
      this.sessionToDelegation.delete(delegation.sessionId)
    }

    await this.save(delegation)
    await this.log.info(`Delegation ${delegationId} cancelled`)

    return true
  }

  /**
   * Check if all delegations for an issue are complete
   */
  async areAllComplete(issueId: string): Promise<boolean> {
    const delegations = await this.list({ issueId })

    if (delegations.length === 0) return true

    return delegations.every(
      (d) => d.status === "completed" || d.status === "failed" || d.status === "cancelled" || d.status === "timeout"
    )
  }

  /**
   * Get pending/running delegations for an issue
   */
  async getActiveDelegations(issueId: string): Promise<Delegation[]> {
    const delegations = await this.list({ issueId })

    return delegations.filter((d) => d.status === "pending" || d.status === "running")
  }

  /**
   * Handle delegation timeout
   */
  private async handleTimeout(delegationId: string): Promise<void> {
    const delegation = await this.get(delegationId)
    if (!delegation || delegation.status !== "running") return

    await this.log.warn(`Delegation ${delegationId} timed out after ${this.timeoutMs / 1000}s`)

    // Try to get partial result
    let result = "(timed out - no result)"
    if (delegation.sessionId) {
      result = await this.getSessionResult(delegation.sessionId)
      result += "\n\n[TIMEOUT REACHED - PARTIAL RESULT]"

      // Try to delete the session
      if (this.client) {
        try {
          await this.client.session.delete({ path: { id: delegation.sessionId } })
        } catch {
          // Ignore
        }
      }
      this.sessionToDelegation.delete(delegation.sessionId)
    }

    delegation.status = "timeout"
    delegation.error = `Timed out after ${this.timeoutMs / 1000}s`
    delegation.result = result
    delegation.completedAt = new Date().toISOString()
    this.delegations.set(delegation.id, delegation)
    await this.save(delegation)

    // Persist partial result
    await this.persistResult(delegation)

    // Notify TeamManager (handles parent notification)
    await this.teamManager.handleDelegationComplete(delegation.id)
  }

  /**
   * Get result text from a session's messages
   * 
   * Issue #4: Only extract text from the LAST assistant message, not all messages.
   * This avoids including intermediate tool results and partial responses.
   */
  private async getSessionResult(sessionId: string): Promise<string> {
    if (!this.client) return "(no client)"

    try {
      const messages = await this.client.session.messages({
        path: { id: sessionId },
      })

      const messageData: MessageItem[] | undefined = messages.data

      await this.log.debug(`getSessionResult: ${messageData?.length || 0} messages in session ${sessionId}`)

      if (!messageData || messageData.length === 0) {
        return "(no messages)"
      }

      // Find assistant messages
      const assistantMessages = messageData.filter((m) => m.info?.role === "assistant")
      if (assistantMessages.length === 0) {
        return "(no assistant response)"
      }

      await this.log.debug(`getSessionResult: found ${assistantMessages.length} assistant messages`)

      // Issue #4: Take only the LAST assistant message
      const lastMessage = assistantMessages[assistantMessages.length - 1]

      // If last message has an error, try the second-to-last
      if (lastMessage.info?.error) {
        await this.log.debug(`getSessionResult: last message has error: ${lastMessage.info.error.name}`)
        if (assistantMessages.length > 1) {
          const fallback = assistantMessages[assistantMessages.length - 2]
          if (!fallback.info?.error) {
            await this.log.debug(`getSessionResult: using second-to-last message as fallback`)
            return this.extractTextFromMessage(fallback)
          }
        }
        return "(last message had error)"
      }

      return this.extractTextFromMessage(lastMessage)
    } catch (error) {
      return `(error retrieving result: ${error})`
    }
  }

  /**
   * Extract text content from a message
   */
  private extractTextFromMessage(message: MessageItem): string {
    const parts: Part[] = message.parts || []
    const textParts = parts.filter((p) => p.type === "text")
    const text = textParts.map((p) => (p as { text?: string }).text || "").join("\n")
    return text || "(no text content)"
  }

  /**
   * Generate title and description for a delegation result using small model
   */
  private async generateMetadata(
    result: string
  ): Promise<{ title: string; description: string }> {
    if (!this.client) {
      return this.fallbackMetadata(result)
    }

    const response = await promptSmallModel<{ title: string; description: string }>(
      this.client,
      this.log,
      {
        prompt: `Generate a title and description for this delegation result.

RULES:
- Title: 2-5 words, max 30 characters, summarize the outcome
- Description: 2-3 sentences, max 200 characters, describe what was accomplished

RESULT:
${result.slice(0, 2000)}

Respond with ONLY valid JSON:
{"title": "Your Title", "description": "Your description."}`,
        sessionTitle: "Metadata Generation",
        timeoutMs: this.smallModelTimeoutMs,
      }
    )

    if (response.success && response.data?.title && response.data?.description) {
      return {
        title: response.data.title.slice(0, 30),
        description: response.data.description.slice(0, 200),
      }
    }

    return this.fallbackMetadata(result)
  }

  /**
   * Fallback metadata generation when small model is unavailable
   */
  private fallbackMetadata(result: string): { title: string; description: string } {
    const firstLine = result.split("\n")[0] || "Delegation Complete"
    return {
      title: firstLine.slice(0, 30),
      description: result.slice(0, 200),
    }
  }

  /**
   * Generate a unique delegation ID
   */
  private generateId(): string {
    const timestamp = Date.now().toString(36)
    const random = crypto.randomBytes(4).toString("hex")
    return `del-${timestamp}-${random}`
  }

  /**
   * Save a delegation to disk
   */
  private async save(delegation: Delegation): Promise<void> {
    await fs.mkdir(this.delegationsDir, { recursive: true })
    const filePath = path.join(this.delegationsDir, `${delegation.id}.json`)
    await fs.writeFile(filePath, JSON.stringify(delegation, null, 2), "utf8")
  }

  /**
   * Persist delegation result to delegations directory
   */
  private async persistResult(delegation: Delegation): Promise<void> {
    await fs.mkdir(this.delegationsDir, { recursive: true })

    const filename = `${delegation.id}.md`
    const filePath = path.join(this.delegationsDir, filename)

    const lines: string[] = []

    lines.push(`# ${delegation.title || `Delegation: ${delegation.issueId}`}`)
    lines.push("")

    if (delegation.description) {
      lines.push(`> ${delegation.description}`)
      lines.push("")
    }

    lines.push("## Metadata")
    lines.push("")
    lines.push(`| Field | Value |`)
    lines.push(`|-------|-------|`)
    lines.push(`| ID | ${delegation.id} |`)
    lines.push(`| Project | ${delegation.projectId} |`)
    lines.push(`| Issue | ${delegation.issueId} |`)
    lines.push(`| Status | ${delegation.status} |`)
    lines.push(`| Started | ${delegation.startedAt} |`)
    lines.push(`| Completed | ${delegation.completedAt || "N/A"} |`)

    if (delegation.agent) {
      lines.push(`| Agent | ${delegation.agent} |`)
    }

    if (delegation.worktreePath) {
      lines.push(`| Worktree | ${delegation.worktreePath} |`)
    }

    lines.push("")
    lines.push("## Prompt")
    lines.push("")
    lines.push(delegation.prompt)
    lines.push("")

    if (delegation.result) {
      lines.push("## Result")
      lines.push("")
      lines.push(delegation.result)
      lines.push("")
    }

    if (delegation.error) {
      lines.push("## Error")
      lines.push("")
      lines.push("```")
      lines.push(delegation.error)
      lines.push("```")
      lines.push("")
    }

    lines.push("---")
    lines.push("")
    lines.push(`*Generated: ${new Date().toISOString()}*`)

    await fs.writeFile(filePath, lines.join("\n"), "utf8")
  }
}
