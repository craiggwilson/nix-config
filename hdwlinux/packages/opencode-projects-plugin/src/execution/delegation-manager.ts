/**
 * DelegationManager - Manages background agent delegations
 *
 * Implements fire-and-forget delegation with:
 * - Background execution (no await on prompts)
 * - Session idle event handling for completion
 * - Configurable timeout
 * - Title/description generation via small model
 *
 * Note: Parent notification is handled via the onComplete callback.
 * All delegations are now part of a team (even single-agent work).
 */

import * as fs from "node:fs/promises"
import * as path from "node:path"
import * as crypto from "node:crypto"
import { z } from "zod"

import type { Logger, OpencodeClient, MessageItem, Part } from "../utils/opencode-sdk/index.js"
import type { TeamMemberRole } from "./team-manager.js"
import { formatDelegationError, type DelegationError } from "../utils/errors/index.js"
import { promptSmallModel } from "../agents/index.js"
import { metadataGenerationTemplate } from "../utils/prompts/index.js"
import type { Result } from "../utils/result/index.js"
import type { VCSType } from "../vcs/index.js"
import { withRetry, isRetryableError, type RetryError } from "../utils/retry/index.js"

/**
 * Zod schema for metadata generation response
 */
const MetadataResponseSchema = z.object({
  title: z.string(),
  description: z.string(),
})

/**
 * Lifecycle status of a delegation.
 *
 * State transitions:
 * - pending → running (when session starts)
 * - running → completed | failed | timeout | cancelled
 */
export type DelegationStatus = "pending" | "running" | "completed" | "failed" | "cancelled" | "timeout"

/**
 * A delegation represents a background agent task.
 *
 * Delegations are created by TeamManager and executed asynchronously.
 * The parent session is notified via callback when the delegation completes.
 */
export interface Delegation {
  /** Unique delegation identifier (format: del-{timestamp}-{random}) */
  id: string
  /** Project this delegation belongs to */
  projectId: string
  /** Filesystem path to the project directory */
  projectDir: string
  /** Issue being worked on */
  issueId: string
  /** Team this delegation is part of */
  teamId: string
  /** Role within the team (primary does implementation, others review) */
  role: TeamMemberRole
  /** Isolated worktree path (only for primary role with isolation) */
  worktreePath?: string
  /** Branch name in the worktree */
  worktreeBranch?: string
  /** Version control system type */
  vcs?: VCSType
  /** Current lifecycle status */
  status: DelegationStatus
  /** OpenCode session ID for this delegation */
  sessionId?: string
  /** Parent session to notify on completion */
  parentSessionId?: string
  /** Parent agent for notification routing */
  parentAgent?: string
  /** Agent assigned to this delegation */
  agent?: string
  /** Full prompt sent to the agent */
  prompt: string
  /** Generated title summarizing the work (via small model) */
  title?: string
  /** Generated description of the work (via small model) */
  description?: string
  /** Final result text from the agent */
  result?: string
  /** Error message if failed or timed out */
  error?: string
  /** ISO timestamp when delegation was created */
  startedAt: string
  /** ISO timestamp when delegation completed */
  completedAt?: string
  /**
   * Callback invoked when delegation completes.
   * Not serialized to disk - used for in-memory coordination.
   */
  onComplete?: DelegationCompleteCallback
}

/**
 * Callback signature for delegation completion notification.
 *
 * @param delegationId - The ID of the completed delegation
 */
export type DelegationCompleteCallback = (delegationId: string) => Promise<void>

/**
 * Options for creating a new delegation.
 */
export interface CreateDelegationOptions {
  /** Issue to work on */
  issueId: string
  /** Full prompt to send to the agent */
  prompt: string
  /** Team this delegation belongs to */
  teamId: string
  /** Role within the team */
  role: TeamMemberRole
  /** Isolated worktree path (for primary role with isolation) */
  worktreePath?: string
  /** Branch name in the worktree */
  worktreeBranch?: string
  /** Version control system type */
  vcs?: "git" | "jj"
  /** Agent to assign (uses default if not specified) */
  agent?: string
  /** Parent session for notifications */
  parentSessionId?: string
  /** Parent agent for notification routing */
  parentAgent?: string
  /** Callback invoked when delegation completes */
  onComplete?: DelegationCompleteCallback
}

/**
 * Configuration options for DelegationManager.
 */
export interface DelegationManagerOptions {
  /** Maximum time a delegation can run before timeout (milliseconds) */
  timeoutMs: number
  /** Maximum time for small model metadata generation (milliseconds) */
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
 * Maximum number of completed delegations to keep in memory.
 * Older completed delegations are cleaned up to prevent unbounded memory growth.
 */
const MAX_COMPLETED_DELEGATIONS = 50

/**
 * Manages background agent delegations with fire-and-forget execution.
 *
 * Key responsibilities:
 * - Creating and starting delegations in background sessions
 * - Tracking delegation lifecycle via session events
 * - Generating metadata (title/description) via small model
 * - Persisting delegation state and results to disk
 *
 * Delegations are fire-and-forget: the create() method returns immediately
 * after starting the background session. Completion is detected via the
 * session.idle event, which triggers the onComplete callback.
 *
 * @example
 * ```typescript
 * const manager = new DelegationManager(log, client, { timeoutMs: 300000, smallModelTimeoutMs: 30000 });
 * const result = await manager.create(projectId, projectDir, {
 *   issueId: "proj-123",
 *   prompt: "Implement feature X",
 *   teamId: "team-abc",
 *   role: "primary",
 *   onComplete: async (id) => console.log(`Delegation ${id} complete`)
 * });
 * ```
 */
export class DelegationManager {
  private log: Logger
  private client?: OpencodeClient
  private timeoutMs: number
  private smallModelTimeoutMs: number

  /** Maps session IDs to delegation IDs for event routing */
  private sessionToDelegation: Map<string, string> = new Map()

  /** In-memory cache of delegations for fast lookup */
  private delegations: Map<string, Delegation> = new Map()

  /**
   * @param log - Logger for diagnostic output
   * @param client - OpenCode client for session management (undefined disables execution)
   * @param options - Configuration options
   */
  constructor(
    log: Logger,
    client: OpencodeClient | undefined,
    options: DelegationManagerOptions
  ) {
    this.log = log
    this.client = client
    this.timeoutMs = options.timeoutMs
    this.smallModelTimeoutMs = options.smallModelTimeoutMs
  }

  /**
   * Start a delegation in the background (fire-and-forget).
   *
   * Creates an OpenCode session with retry logic, sets up timeout handling,
   * and fires the prompt. Does not await the prompt response - completion
   * is handled via session.idle event.
   *
   * Retries on transient errors (JSON parse errors, connection issues, etc.)
   * with exponential backoff.
   */
  private async startDelegation(delegation: Delegation): Promise<void> {
    if (!this.client) return

    try {
      delegation.status = "running"
      this.delegations.set(delegation.id, delegation)
      const saveResult = await this.save(delegation)
      if (!saveResult.ok) {
        await this.log.error(`Failed to save delegation ${delegation.id}: ${formatDelegationError(saveResult.error)}`)
        return
      }

      // Create a session for the delegation with retry logic
      const sessionResult = await withRetry(
        "session.create",
        async () => {
          const result = await this.client!.session.create({
            body: {
              title: `Delegation: ${delegation.issueId} (${delegation.role})`,
              parentID: delegation.parentSessionId,
            },
          })
          if (!result.data?.id) {
            throw new Error("Session creation returned no session ID")
          }
          return result.data.id
        },
        this.log,
        { maxAttempts: 3, initialDelayMs: 500, maxDelayMs: 5000 }
      )

      if (!sessionResult.ok) {
        const retryError = sessionResult.error
        const errorMessage = this.formatApiError("session.create", retryError)
        await this.log.error(`Delegation ${delegation.id} failed to create session: ${errorMessage}`)
        const failResult = await this.fail(delegation.id, errorMessage)
        if (!failResult.ok) {
          await this.log.error(`Failed to mark delegation as failed: ${failResult.error.type}`)
        }
        // Notify via callback so team can handle the failure
        if (delegation.onComplete) await delegation.onComplete(delegation.id)
        return
      }

      const sessionId = sessionResult.value
      delegation.sessionId = sessionId
      this.sessionToDelegation.set(sessionId, delegation.id)
      this.delegations.set(delegation.id, delegation)
      const saveResult2 = await this.save(delegation)
      if (!saveResult2.ok) {
        await this.log.error(`Failed to save delegation ${delegation.id}: ${formatDelegationError(saveResult2.error)}`)
      }

      // Set up timeout handler
      setTimeout(() => {
        this.handleTimeout(delegation.id)
      }, this.timeoutMs)

      // Fire the prompt with retry logic (fire-and-forget)
      this.firePromptWithRetry(delegation, sessionId)

      await this.log.info(`Delegation ${delegation.id} started in background (session: ${sessionId})`)
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error)
      await this.log.error(`Failed to start delegation ${delegation.id}: ${errorMessage}`)
      delegation.status = "failed"
      delegation.error = errorMessage
      this.delegations.set(delegation.id, delegation)
      const saveResult = await this.save(delegation)
      if (!saveResult.ok) {
        await this.log.error(`Failed to save delegation ${delegation.id}: ${formatDelegationError(saveResult.error)}`)
      }
      // Notify via callback so team can handle the failure
      if (delegation.onComplete) await delegation.onComplete(delegation.id)
    }
  }

  /**
   * Fire the prompt with retry logic (fire-and-forget).
   *
   * Retries on transient errors with exponential backoff.
   * On final failure, marks the delegation as failed and notifies.
   */
  private firePromptWithRetry(delegation: Delegation, sessionId: string): void {
    if (!this.client) return

    withRetry(
      "session.prompt",
      async () => {
        const result = await this.client!.session.prompt({
          path: { id: sessionId },
          body: {
            agent: delegation.agent,
            parts: [{ type: "text", text: delegation.prompt }],
            tools: DISABLED_TOOLS,
          },
        })
        // Check for error in response
        if (!result.data) {
          throw new Error("Prompt returned no response data")
        }
        return result
      },
      this.log,
      { maxAttempts: 3, initialDelayMs: 500, maxDelayMs: 5000 }
    ).then(async (result) => {
      if (!result.ok) {
        const retryError = result.error
        const errorMessage = this.formatApiError("session.prompt", retryError)
        await this.log.error(`Delegation ${delegation.id} prompt failed: ${errorMessage}`)
        const failResult = await this.fail(delegation.id, errorMessage)
        if (!failResult.ok) {
          await this.log.error(`Failed to mark delegation as failed: ${failResult.error.type}`)
        }
        // Notify via callback
        if (delegation.onComplete) await delegation.onComplete(delegation.id)
      }
    }).catch(async (error: Error) => {
      // Catch any unexpected errors from the retry logic itself
      await this.log.error(`Delegation ${delegation.id} prompt failed unexpectedly: ${error.message}`)
      const failResult = await this.fail(delegation.id, error.message)
      if (!failResult.ok) {
        await this.log.error(`Failed to mark delegation as failed: ${failResult.error.type}`)
      }
      if (delegation.onComplete) await delegation.onComplete(delegation.id)
    })
  }

  /**
   * Format a RetryError into a user-friendly error message.
   */
  private formatApiError(operation: string, error: RetryError): string {
    const lines = [
      `API call '${operation}' failed after ${error.attempts} attempt(s): ${error.lastError}`,
    ]
    if (error.wasRetryable) {
      lines.push("This appears to be a transient error (network issue, server overload, etc.).")
      lines.push("Hint: Try again in a few moments, or check network connectivity.")
    } else {
      lines.push("Hint: Check the OpenCode logs for more details.")
    }
    return lines.join(" ")
  }

  /**
   * Handle session.idle event from OpenCode.
   *
   * This is the primary completion handler. When a delegated session becomes idle
   * (agent finished processing), this method:
   * 1. Retrieves the result from session messages
   * 2. Generates title/description via small model
   * 3. Updates delegation status and persists to disk
   * 4. Invokes the onComplete callback for parent notification
   *
   * @param sessionId - The OpenCode session ID that became idle
   */
  async handleSessionIdle(sessionId: string): Promise<void> {
    const delegationId = this.sessionToDelegation.get(sessionId)
    if (!delegationId) return

    // Try in-memory cache first
    const getResult = await this.get(delegationId)
    if (!getResult.ok) {
      await this.log.warn(`Delegation ${delegationId} not found for session ${sessionId}`)
      return
    }

    const delegation = getResult.value
    if (delegation.status !== "running") return

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
    const saveResult = await this.save(delegation)
    if (!saveResult.ok) {
      await this.log.error(`Failed to save delegation ${delegation.id}: ${formatDelegationError(saveResult.error)}`)
    }

    // Persist result to file
    await this.persistResult(delegation)

    // Notify via callback (handles parent notification)
    if (delegation.onComplete) await delegation.onComplete(delegation.id)

    // Clean up session mapping and prune old completed delegations
    this.sessionToDelegation.delete(sessionId)
    this.pruneCompletedDelegations()
  }

  /**
   * Prune old completed delegations from in-memory cache to prevent unbounded memory growth.
   * Keeps the most recent MAX_COMPLETED_DELEGATIONS completed delegations.
   */
  private pruneCompletedDelegations(): void {
    const completed = Array.from(this.delegations.values())
      .filter((d) => d.status === "completed" || d.status === "failed" || d.status === "timeout" || d.status === "cancelled")
      .sort((a, b) => new Date(b.completedAt || b.startedAt).getTime() - new Date(a.completedAt || a.startedAt).getTime())

    if (completed.length > MAX_COMPLETED_DELEGATIONS) {
      const toRemove = completed.slice(MAX_COMPLETED_DELEGATIONS)
      for (const delegation of toRemove) {
        this.delegations.delete(delegation.id)
      }
    }
  }

  /**
   * Find a delegation ID by its associated session ID.
   *
   * @param sessionId - The OpenCode session ID
   * @returns The delegation ID, or undefined if not found
   */
  findBySession(sessionId: string): string | undefined {
    return this.sessionToDelegation.get(sessionId)
  }

  /**
   * Get a delegation by ID from the in-memory cache.
   *
   * Note: Only returns delegations that are currently cached. Completed delegations
   * may be pruned from cache but remain persisted on disk.
   *
   * @param delegationId - The delegation ID to look up
   * @returns The delegation if found, or a not_found error
   */
  async get(delegationId: string): Promise<Result<Delegation, DelegationError>> {
    const delegation = this.delegations.get(delegationId)
    if (!delegation) {
      return { ok: false, error: { type: "not_found", delegationId } }
    }
    return { ok: true, value: delegation }
  }

  /**
   * List delegations from the in-memory cache with optional filtering.
   *
   * @param options - Filter criteria
   * @param options.status - Filter by delegation status
   * @param options.issueId - Filter by issue ID
   * @param options.projectId - Filter by project ID
   * @returns Delegations matching the criteria, sorted by start time (newest first)
   */
  async list(options?: { status?: DelegationStatus; issueId?: string; projectId?: string }): Promise<Delegation[]> {
    let filtered = Array.from(this.delegations.values())

    if (options?.status) {
      filtered = filtered.filter((d) => d.status === options.status)
    }

    if (options?.issueId) {
      filtered = filtered.filter((d) => d.issueId === options.issueId)
    }

    if (options?.projectId) {
      filtered = filtered.filter((d) => d.projectId === options.projectId)
    }

    return filtered.sort(
      (a, b) => new Date(b.startedAt).getTime() - new Date(a.startedAt).getTime()
    )
  }

  /**
   * Create and start a new delegation.
   *
   * This is the main entry point for creating delegations. It:
   * 1. Creates the delegation record
   * 2. Persists initial state to disk
   * 3. Starts the background session (fire-and-forget)
   *
   * @param projectId - Project this delegation belongs to
   * @param projectDir - Filesystem path to the project directory
   * @param options - Delegation configuration
   * @returns The created delegation, or an error if creation failed
   */
  async create(projectId: string, projectDir: string, options: CreateDelegationOptions): Promise<Result<Delegation, DelegationError>> {
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
      onComplete,
    } = options

    // Generate delegation ID
    const delegationId = this.generateId()
    const now = new Date().toISOString()

    // Create delegation record
    const delegation: Delegation = {
      id: delegationId,
      projectId,
      projectDir,
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
      onComplete,
    }

    // Save initial state
    this.delegations.set(delegationId, delegation)
    const saveResult = await this.save(delegation)
    if (!saveResult.ok) {
      return saveResult
    }

    await this.log.info(`Created delegation ${delegationId} for issue ${issueId} (team: ${teamId}, role: ${role})`)

    // Start the delegation
    await this.startDelegation(delegation)

    return { ok: true, value: delegation }
  }

  /**
   * Get recent completed delegations for session compaction context.
   *
   * Used to provide context about recent work when compacting long sessions.
   *
   * @param limit - Maximum number of delegations to return (default: 10)
   * @returns Recent completed/failed/timed-out delegations, newest first
   */
  async getRecentCompletedDelegations(limit: number = 10): Promise<Delegation[]> {
    const all = await this.list()
    return all
      .filter((d) => d.status === "completed" || d.status === "failed" || d.status === "timeout")
      .slice(0, limit)
  }

  /**
   * Mark a delegation as complete with the given result.
   *
   * Typically called internally via handleSessionIdle, but can be called
   * directly for manual completion.
   *
   * @param delegationId - The delegation to complete
   * @param result - The result text from the agent
   * @returns The updated delegation, or an error if not found or already complete
   */
  async complete(delegationId: string, result: string): Promise<Result<Delegation, DelegationError>> {
    const getResult = await this.get(delegationId)
    if (!getResult.ok) {
      return getResult
    }

    const delegation = getResult.value

    if (delegation.status !== "running" && delegation.status !== "pending") {
      return {
        ok: false,
        error: {
          type: "already_completed",
          delegationId,
          status: delegation.status,
        },
      }
    }

    delegation.status = "completed"
    delegation.result = result
    delegation.completedAt = new Date().toISOString()

    const saveResult = await this.save(delegation)
    if (!saveResult.ok) {
      return saveResult
    }

    await this.persistResult(delegation)
    await this.log.info(`Delegation ${delegationId} completed`)

    // Prune old completed delegations to prevent unbounded memory growth
    this.pruneCompletedDelegations()

    return { ok: true, value: delegation }
  }

  /**
   * Mark a delegation as failed with an error message.
   *
   * @param delegationId - The delegation to mark as failed
   * @param error - Error message describing the failure
   * @returns The updated delegation, or an error if not found or already complete
   */
  async fail(delegationId: string, error: string): Promise<Result<Delegation, DelegationError>> {
    const getResult = await this.get(delegationId)
    if (!getResult.ok) {
      return getResult
    }

    const delegation = getResult.value

    if (delegation.status !== "running" && delegation.status !== "pending") {
      return {
        ok: false,
        error: {
          type: "already_completed",
          delegationId,
          status: delegation.status,
        },
      }
    }

    delegation.status = "failed"
    delegation.error = error
    delegation.completedAt = new Date().toISOString()

    const saveResult = await this.save(delegation)
    if (!saveResult.ok) {
      return saveResult
    }

    await this.persistResult(delegation)
    await this.log.warn(`Delegation ${delegationId} failed: ${error}`)

    // Prune old completed delegations to prevent unbounded memory growth
    this.pruneCompletedDelegations()

    return { ok: true, value: delegation }
  }

  /**
   * Mark a delegation as timed out.
   *
   * Called by the timeout handler when a delegation exceeds its time limit.
   *
   * @param delegationId - The delegation to mark as timed out
   * @returns The updated delegation, or an error if not found or already complete
   */
  async timeout(delegationId: string): Promise<Result<Delegation, DelegationError>> {
    const getResult = await this.get(delegationId)
    if (!getResult.ok) {
      return getResult
    }

    const delegation = getResult.value

    if (delegation.status !== "running" && delegation.status !== "pending") {
      return {
        ok: false,
        error: {
          type: "already_completed",
          delegationId,
          status: delegation.status,
        },
      }
    }

    delegation.status = "timeout"
    delegation.error = `Timed out after ${this.timeoutMs / 1000}s`
    delegation.completedAt = new Date().toISOString()

    const saveResult = await this.save(delegation)
    if (!saveResult.ok) {
      return saveResult
    }

    await this.persistResult(delegation)
    await this.log.warn(`Delegation ${delegationId} timed out`)

    return { ok: true, value: delegation }
  }

  /**
   * Cancel a running or pending delegation.
   *
   * Attempts to delete the associated session and marks the delegation as cancelled.
   *
   * @param delegationId - The delegation to cancel
   * @returns The updated delegation, or an error if not found or already complete
   */
  async cancel(delegationId: string): Promise<Result<Delegation, DelegationError>> {
    const getResult = await this.get(delegationId)
    if (!getResult.ok) {
      return getResult
    }

    const delegation = getResult.value

    if (delegation.status === "completed" || delegation.status === "failed") {
      return {
        ok: false,
        error: {
          type: "already_completed",
          delegationId,
          status: delegation.status,
        },
      }
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

    const saveResult = await this.save(delegation)
    if (!saveResult.ok) {
      return saveResult
    }

    await this.log.info(`Delegation ${delegationId} cancelled`)

    // Prune old completed delegations to prevent unbounded memory growth
    this.pruneCompletedDelegations()

    return { ok: true, value: delegation }
  }

  /**
   * Check if all delegations for an issue have finished (completed, failed, cancelled, or timed out).
   *
   * @param issueId - The issue to check
   * @returns true if no active delegations remain for the issue
   */
  async areAllComplete(issueId: string): Promise<boolean> {
    const delegations = await this.list({ issueId })

    if (delegations.length === 0) return true

    return delegations.every(
      (d) => d.status === "completed" || d.status === "failed" || d.status === "cancelled" || d.status === "timeout"
    )
  }

  /**
   * Get active (pending or running) delegations for an issue.
   *
   * @param issueId - The issue to check
   * @returns Delegations that are still in progress
   */
  async getActiveDelegations(issueId: string): Promise<Delegation[]> {
    const delegations = await this.list({ issueId })

    return delegations.filter((d) => d.status === "pending" || d.status === "running")
  }

  /**
   * Handle delegation timeout.
   *
   * Called by setTimeout when a delegation exceeds its time limit.
   * Attempts to retrieve partial results before marking as timed out.
   */
  private async handleTimeout(delegationId: string): Promise<void> {
    const getResult = await this.get(delegationId)
    if (!getResult.ok || getResult.value.status !== "running") return

    const delegation = getResult.value

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
    const saveResult = await this.save(delegation)
    if (!saveResult.ok) {
      await this.log.error(`Failed to save delegation ${delegation.id}: ${formatDelegationError(saveResult.error)}`)
    }

    // Persist partial result
    await this.persistResult(delegation)

    // Notify via callback (handles parent notification)
    if (delegation.onComplete) await delegation.onComplete(delegation.id)

    // Prune old completed delegations to prevent unbounded memory growth
    this.pruneCompletedDelegations()
  }

  /**
   * Extract the final result text from a session's messages.
   *
   * Only extracts text from the LAST assistant message to avoid including
   * intermediate tool results and partial responses. If the last message
   * has an error, falls back to the second-to-last message.
   *
   * @param sessionId - The session to extract results from
   * @returns The result text, or an error placeholder if unavailable
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
   * Extract text content from a message's parts.
   *
   * @param message - The message to extract text from
   * @returns Concatenated text from all text parts, or a placeholder if empty
   */
  private extractTextFromMessage(message: MessageItem): string {
    const parts: Part[] = message.parts || []
    const textParts = parts.filter((p) => p.type === "text")
    const text = textParts.map((p) => (p as { text?: string }).text || "").join("\n")
    return text || "(no text content)"
  }

  /**
   * Generate title and description for a delegation result using small model.
   *
   * Uses a fast small model to summarize the delegation result into a
   * concise title (max 30 chars) and description (max 200 chars).
   * Falls back to simple text extraction if the small model is unavailable.
   *
   * @param result - The full result text to summarize
   * @returns Generated title and description
   */
  private async generateMetadata(
    result: string
  ): Promise<{ title: string; description: string }> {
    if (!this.client) {
      return this.fallbackMetadata(result)
    }

    const prompt = metadataGenerationTemplate.render({ result })

    const response = await promptSmallModel(this.client, this.log, {
      prompt,
      sessionTitle: "Metadata Generation",
      timeoutMs: this.smallModelTimeoutMs,
      schema: MetadataResponseSchema,
    })

    if (response.ok) {
      return {
        title: response.value.title.slice(0, 30),
        description: response.value.description.slice(0, 200),
      }
    }

    return this.fallbackMetadata(result)
  }

  /**
   * Fallback metadata generation when small model is unavailable.
   *
   * Uses simple text extraction: first line for title, first 200 chars for description.
   */
  private fallbackMetadata(result: string): { title: string; description: string } {
    const firstLine = result.split("\n")[0] || "Delegation Complete"
    return {
      title: firstLine.slice(0, 30),
      description: result.slice(0, 200),
    }
  }

  /**
   * Generate a unique delegation ID.
   *
   * Format: del-{base36-timestamp}-{hex-random}
   */
  private generateId(): string {
    const timestamp = Date.now().toString(36)
    const random = crypto.randomBytes(4).toString("hex")
    return `del-${timestamp}-${random}`
  }

  /**
   * Save a delegation to disk as JSON.
   *
   * Persists to {projectDir}/delegations/{delegationId}.json
   */
  private async save(delegation: Delegation): Promise<Result<void, DelegationError>> {
    try {
      const delegationsDir = path.join(delegation.projectDir, "delegations")
      await fs.mkdir(delegationsDir, { recursive: true })
      const filePath = path.join(delegationsDir, `${delegation.id}.json`)
      await fs.writeFile(filePath, JSON.stringify(delegation, null, 2), "utf8")
      return { ok: true, value: undefined }
    } catch (error) {
      return {
        ok: false,
        error: {
          type: "persistence_failed",
          delegationId: delegation.id,
          message: error instanceof Error ? error.message : String(error),
        },
      }
    }
  }

  /**
   * Persist delegation result as a human-readable markdown file.
   *
   * Creates {projectDir}/delegations/{delegationId}.md with metadata,
   * prompt, result, and any error information.
   */
  private async persistResult(delegation: Delegation): Promise<void> {
    const delegationsDir = path.join(delegation.projectDir, "delegations")
    await fs.mkdir(delegationsDir, { recursive: true })

    const filename = `${delegation.id}.md`
    const filePath = path.join(delegationsDir, filename)

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
