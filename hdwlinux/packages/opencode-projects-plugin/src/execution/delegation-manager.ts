/**
 * DelegationManager - Manages background agent delegations
 *
 * Implements fire-and-forget delegation with:
 * - Background execution (no await on prompts)
 * - Session idle event handling for completion
 * - Batched notifications for parallel delegations
 * - Configurable timeout
 * - Title/description generation via small model
 */

import * as fs from "node:fs/promises"
import * as path from "node:path"
import * as crypto from "node:crypto"

import type { Logger, OpencodeClient, MessageItem, Part } from "../core/types.js"
import { selectAgent, discoverAgents } from "../core/agent-selector.js"
import { promptSmallModel } from "../core/small-model.js"

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
  worktreePath?: string
  worktreeBranch?: string
  vcs?: "git" | "jj"
  status: DelegationStatus
  sessionId?: string
  parentSessionId?: string
  rootSessionId?: string
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
  worktreePath?: string
  worktreeBranch?: string
  vcs?: "git" | "jj"
  agent?: string
  parentSessionId?: string
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

  // Session ID -> Delegation ID mapping for event lookup
  private sessionToDelegation: Map<string, string> = new Map()

  // Track pending delegations per root session for batched notifications
  private pendingByRoot: Map<string, Set<string>> = new Map()

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
   * Create a new delegation and start it in the background.
   *
   * The delegation runs asynchronously - this method returns immediately
   * after firing the prompt. Completion is handled via session.idle events.
   */
  async create(projectId: string, options: CreateDelegationOptions): Promise<Delegation> {
    const { issueId, prompt, worktreePath, parentSessionId } = options
    let { agent } = options

    // If no agent specified and we have a client, use small model to select
    if (!agent && this.client) {
      const agents = await discoverAgents(this.client, this.log)
      if (agents.length > 0) {
        agent =
          (await selectAgent(this.client, this.log, {
            agents,
            taskDescription: prompt,
            taskType: "coding",
            timeoutMs: this.smallModelTimeoutMs,
          })) || undefined
      }
    }

    const id = this.generateId()
    const now = new Date().toISOString()

    // Resolve root session ID for batched notifications
    const rootSessionId = parentSessionId
      ? await this.resolveRootSession(parentSessionId)
      : undefined

    const delegation: Delegation = {
      id,
      projectId,
      issueId,
      worktreePath,
      worktreeBranch: options.worktreeBranch,
      vcs: options.vcs,
      status: "pending",
      sessionId: undefined,
      parentSessionId,
      rootSessionId,
      agent,
      prompt,
      startedAt: now,
    }

    await this.save(delegation)
    await this.log.info(`Created delegation ${id} for issue ${issueId}`)

    // If we have a client, start the delegation in the background
    if (this.client) {
      await this.startDelegation(delegation)
    }

    return delegation
  }

  /**
   * Start a delegation in the background (fire-and-forget)
   */
  private async startDelegation(delegation: Delegation): Promise<void> {
    if (!this.client) return

    try {
      delegation.status = "running"
      await this.save(delegation)

      // Create a session for the delegation
      const sessionResult = await this.client.session.create({
        body: {
          agent: delegation.agent,
          title: `Delegation: ${delegation.issueId}`,
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
      await this.save(delegation)

      // Track for batched notifications
      if (delegation.rootSessionId) {
        const pending = this.pendingByRoot.get(delegation.rootSessionId) || new Set()
        pending.add(delegation.id)
        this.pendingByRoot.set(delegation.rootSessionId, pending)
      }

      // Set up timeout handler
      setTimeout(() => {
        this.handleTimeout(delegation.id)
      }, this.timeoutMs)

      // Fire the prompt (fire-and-forget)
      // Completion is handled via session.idle events
      this.client.session
        .prompt({
          path: { id: sessionId },
          body: {
            agent: delegation.agent,
            parts: [{ type: "text", text: this.buildPrompt(delegation) }],
            tools: DISABLED_TOOLS,
          },
        })
        .catch(async (error: Error) => {
          await this.log.error(`Delegation ${delegation.id} prompt failed: ${error.message}`)
          await this.fail(delegation.id, error.message)
          await this.notifyParent(delegation)
        })

      await this.log.info(`Delegation ${delegation.id} started in background (session: ${sessionId})`)
    } catch (error) {
      await this.log.error(`Failed to start delegation: ${error}`)
      delegation.status = "failed"
      delegation.error = String(error)
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

    const delegation = await this.get(delegationId)
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
    await this.save(delegation)

    // Persist result to file
    await this.persistResult(delegation)

    // Notify parent session
    await this.notifyParent(delegation)

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
    try {
      const filePath = path.join(this.delegationsDir, `${delegationId}.json`)
      const content = await fs.readFile(filePath, "utf8")
      return JSON.parse(content) as Delegation
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
   * Get all running delegations
   */
  async getRunningDelegations(): Promise<Delegation[]> {
    return this.list({ status: "running" })
  }

  /**
   * Get count of pending delegations for a root session
   */
  getPendingCount(rootSessionId: string): number {
    return this.pendingByRoot.get(rootSessionId)?.size || 0
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
    await this.save(delegation)

    // Persist partial result
    await this.persistResult(delegation)

    // Notify parent
    await this.notifyParent(delegation)
  }

  /**
   * Get result text from a session's messages
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

      // Log message roles for debugging
      const roles = messageData.map((m) => m.info?.role).join(", ")
      await this.log.debug(`getSessionResult: message roles: ${roles}`)

      // Find assistant messages
      const assistantMessages = messageData.filter((m) => m.info?.role === "assistant")
      if (assistantMessages.length === 0) {
        return "(no assistant response)"
      }

      // Collect text from all assistant messages, skipping aborted ones
      const allTextParts: string[] = []
      
      for (const message of assistantMessages) {
        // Skip messages with errors (aborted, etc.)
        if (message.info?.error) {
          await this.log.debug(`getSessionResult: skipping message with error: ${message.info.error.name}`)
          continue
        }
        
        const parts: Part[] = message.parts || []
        const textParts = parts.filter((p) => p.type === "text")
        
        for (const part of textParts) {
          if (part.text) {
            allTextParts.push(part.text)
          }
        }
      }
      
      await this.log.debug(`getSessionResult: collected ${allTextParts.length} text parts from ${assistantMessages.length} assistant messages`)

      const result = allTextParts.join("\n")
      
      await this.log.debug(`getSessionResult: result length: ${result.length}`)
      
      return result || "(no text content)"
    } catch (error) {
      return `(error retrieving result: ${error})`
    }
  }

  /**
   * Resolve the root session ID by walking up the parent chain
   */
  private async resolveRootSession(sessionId: string): Promise<string> {
    if (!this.client) return sessionId

    let currentId = sessionId
    const visited = new Set<string>()

    while (true) {
      if (visited.has(currentId)) break
      visited.add(currentId)

      try {
        const session = await this.client.session.get({
          path: { id: currentId },
        })

        const parentId = session.data?.parentID
        if (!parentId) break

        currentId = parentId
      } catch {
        break
      }
    }

    return currentId
  }

  /**
   * Notify parent session that delegation is complete.
   * Uses batching: individual notifications are silent (noReply: true),
   * but when ALL delegations for a root complete, triggers a response.
   */
  private async notifyParent(delegation: Delegation): Promise<void> {
    if (!this.client || !delegation.rootSessionId) return

    const rootSessionId = delegation.rootSessionId

    // Remove from pending set
    const pendingSet = this.pendingByRoot.get(rootSessionId)
    if (pendingSet) {
      pendingSet.delete(delegation.id)
    }

    const allComplete = !pendingSet || pendingSet.size === 0
    const remainingCount = pendingSet?.size || 0

    // Clean up if all complete
    if (allComplete && pendingSet) {
      this.pendingByRoot.delete(rootSessionId)
    }

    // Build notification
    const statusText = delegation.status === "completed" ? "complete" : delegation.status
    const progressNote =
      remainingCount > 0
        ? `\n\n**${remainingCount} delegation(s) still in progress.** You will be notified when ALL complete.`
        : ""

    // Build worktree section with VCS-specific merge instructions
    let worktreeSection = ""
    if (delegation.worktreePath && delegation.vcs) {
      const mergeInstructions = this.getMergeInstructions(delegation)
      worktreeSection = `
<worktree>
  <path>${delegation.worktreePath}</path>
  <branch>${delegation.worktreeBranch || delegation.issueId}</branch>
  <vcs>${delegation.vcs}</vcs>
</worktree>
<merge-instructions>
${mergeInstructions}
</merge-instructions>`
    }

    const notification = `<delegation-notification>
<delegation-id>${delegation.id}</delegation-id>
<issue>${delegation.issueId}</issue>
<status>${statusText}</status>
${delegation.title ? `<title>${delegation.title}</title>` : ""}
${delegation.description ? `<description>${delegation.description}</description>` : ""}${worktreeSection}
<result>
${delegation.result || "(no result)"}
</result>
${delegation.error ? `<error>${delegation.error}</error>` : ""}
</delegation-notification>${progressNote}`

    try {
      // Send notification (noReply unless all complete)
      await this.client.session.prompt({
        path: { id: rootSessionId },
        body: {
          noReply: !allComplete,
          parts: [{ type: "text", text: notification }],
        },
      })

      // If all complete, send a final notification that triggers response
      if (allComplete) {
        await this.client.session.prompt({
          path: { id: rootSessionId },
          body: {
            noReply: false,
            parts: [
              {
                type: "text",
                text: "<delegation-notification>\n<status>all-complete</status>\n<summary>All delegations complete. Review the results above and continue.</summary>\n</delegation-notification>",
              },
            ],
          },
        })
      }

      await this.log.info(
        `Notified root session ${rootSessionId} (allComplete=${allComplete}, remaining=${remainingCount})`
      )
    } catch (error) {
      await this.log.warn(`Failed to notify parent: ${error}`)
    }
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
   * Get VCS-specific merge instructions for a delegation
   */
  private getMergeInstructions(delegation: Delegation): string {
    const branch = delegation.worktreeBranch || delegation.issueId
    const worktreePath = delegation.worktreePath || ""

    if (delegation.vcs === "jj") {
      return `Review and merge the changes from the jj workspace:
1. Review: \`jj diff --from main --to ${branch}\`
2. Squash: \`jj squash --from ${branch}\` (from main workspace)
3. Clean up: \`jj workspace forget ${branch}\``
    } else {
      // git
      return `Review and merge the changes from the git worktree:
1. Review: \`git diff main..${branch}\`
2. Merge: \`git merge ${branch}\`
3. Clean up: \`git worktree remove ${worktreePath} && git branch -d ${branch}\``
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
   * Build the full prompt for a delegation
   */
  private buildPrompt(delegation: Delegation): string {
    const lines: string[] = []

    lines.push(`# Delegated Task: ${delegation.issueId}`)
    lines.push("")
    lines.push(`**Project:** ${delegation.projectId}`)
    lines.push(`**Delegation ID:** ${delegation.id}`)

    if (delegation.worktreePath) {
      lines.push(`**Worktree:** ${delegation.worktreePath}`)
      lines.push("")
      lines.push("You are working in an isolated worktree. Make your changes there.")
    }

    lines.push("")
    lines.push("## Task")
    lines.push("")
    lines.push(delegation.prompt)
    lines.push("")
    lines.push("## Instructions")
    lines.push("")
    lines.push("1. Complete the task described above")
    lines.push("2. Commit your changes with clear commit messages")
    lines.push("3. Provide a summary of what you accomplished")
    lines.push("")
    lines.push("## Constraints")
    lines.push("")
    lines.push("You are running as a background delegation. The following tools are disabled:")
    lines.push("- project-create, project-close, project-create-issue, project-update-issue, project-work-on-issue")
    lines.push("- task, delegate (no recursive delegation)")
    lines.push("")
    lines.push("Focus on completing the assigned task. Do not create new issues or projects.")

    return lines.join("\n")
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
