/**
 * TeamManager - Orchestrates multi-agent team execution
 *
 * Every work-on-issue operation creates a Team (even single-agent).
 * This unifies the execution path and enables:
 * - Multiple agents working on the same issue
 * - Discussion rounds between agents
 * - Devil's advocate critical analysis
 * - Coordinated notifications to parent
 *
 * Delegates to:
 * - TeamComposer: Agent selection and team composition
 * - TeamDiscussionStrategy: Discussion coordination between agents
 * - TeamNotifier: Parent notification and XML generation
 */

import * as fs from "node:fs/promises"
import * as path from "node:path"
import * as crypto from "node:crypto"

import type { Result } from "../utils/result/index.js"
import type { VCSType } from "../vcs/index.js"
import type { Logger, OpencodeClient } from "../utils/opencode-sdk/index.js"
import type { TeamError } from "../utils/errors/index.js"
import type { Clock, TimeoutHandle } from "../utils/clock/index.js"
import { systemClock } from "../utils/clock/index.js"
import {
  teamMemberTemplate,
  type TeamMemberData,
} from "../utils/prompts/index.js"
import type {
  DelegationManager,
  CreateDelegationOptions,
  Delegation,
} from "./delegation-manager.js"
import type { WorktreeManager } from "../vcs/index.js"
import { TeamComposer, type TeamComposerConfig } from "./team-composer.js"
import type { TeamDiscussionStrategy, DiscussionStrategyType } from "./discussion-strategy.js"
import { TeamNotifier } from "./team-notifier.js"


/**
 * Role of a team member in multi-agent execution.
 *
 * - primary: Does the main implementation work
 * - secondary: Reviews and provides feedback on primary's work
 * - devilsAdvocate: Critically analyzes for potential issues and edge cases
 * - mediator: Injected dynamically when a discussion reaches an impasse after the arbiter fails;
 *   reviews the full history and proposes a path forward
 */
export type TeamMemberRole = "primary" | "secondary" | "devilsAdvocate" | "mediator"

/**
 * Lifecycle status of a team.
 *
 * State transitions:
 * - running → discussing (when all members complete initial work)
 * - discussing → completed | failed (after discussion rounds)
 * - running → completed | failed (if no discussion rounds)
 */
export type TeamStatus = "running" | "discussing" | "completed" | "failed"

/**
 * Lifecycle status of a team member.
 */
export type TeamMemberStatus = "pending" | "running" | "completed" | "failed" | "timeout"

/**
 * A member of a team working on an issue.
 */
export interface TeamMember {
  /** Agent name (e.g., "typescript-expert", "security-reviewer") */
  agent: string
  /** Role in the team */
  role: TeamMemberRole
  /** Associated delegation ID for tracking */
  delegationId?: string
  /** Session ID for discussion continuity */
  sessionId?: string
  /** Current lifecycle status */
  status: TeamMemberStatus
  /** Number of retry attempts after failure */
  retryCount: number
  /** The prompt used for this member's delegation, stored for retry reuse */
  prompt: string
}

/**
 * Result from a team member's initial work phase.
 */
export interface TeamMemberResult {
  /** Agent name */
  agent: string
  /** Full result text from the agent */
  result: string
  /** ISO timestamp when the work completed */
  completedAt: string
}

/**
 * A single round of team discussion.
 *
 * After initial work completes, team members discuss their findings
 * in multiple rounds to reach consensus and identify issues.
 */
export interface DiscussionRound {
  /** Round number (1-based) */
  round: number
  /** Responses from each agent, keyed by agent name */
  responses: Record<string, string>
}

/**
 * A team of agents working on an issue.
 *
 * Teams coordinate multiple agents working on the same issue:
 * - Primary agent does implementation
 * - Secondary agents review and provide feedback
 * - Devil's advocate critically analyzes for issues
 * - Discussion rounds allow agents to refine their analysis
 */
export interface Team {
  /** Unique team identifier (format: team-{timestamp}-{random}) */
  id: string
  /** Project this team belongs to */
  projectId: string
  /** Filesystem path to the project directory */
  projectDir: string
  /** Issue being worked on */
  issueId: string
  /** Team members with their roles and status */
  members: TeamMember[]
  /** Current team lifecycle status */
  status: TeamStatus
  /** Shared worktree path (if isolated execution) */
  worktreePath?: string
  /** Branch name in the worktree */
  worktreeBranch?: string
  /** Version control system type */
  vcs?: VCSType
  /** The discussion strategy type used for this team — persisted for observability */
  discussionStrategyType: DiscussionStrategyType
  /** The live discussion strategy instance — not persisted, absent when loaded from disk */
  strategy?: TeamDiscussionStrategy
  /** Results from each member's initial work, keyed by agent name */
  results: Record<string, TeamMemberResult>
  /** History of all discussion rounds */
  discussionHistory: DiscussionRound[]
  /** Parent session to notify on completion */
  parentSessionId?: string
  /** Parent agent for notification routing */
  parentAgent?: string
  /** Whether running in foreground mode (synchronous) */
  foreground?: boolean
  /** ISO timestamp when the team was created */
  startedAt: string
  /** ISO timestamp when the team completed */
  completedAt?: string
}

/**
 * Options for creating a new team.
 */
export interface CreateTeamOptions {
  /** Project ID */
  projectId: string
  /** Filesystem path to the project directory */
  projectDir: string
  /** Issue ID to work on */
  issueId: string
  /** Issue context (title + description) for agent selection */
  issueContext: string
  /** Agents to use. If undefined, small model auto-selects a team. */
  agents?: string[]
  /** Create isolated worktree for the primary agent */
  isolate?: boolean
  /** Parent session ID for notifications */
  parentSessionId?: string
  /** Parent agent for notification routing */
  parentAgent?: string
  /** Wait for completion instead of fire-and-forget */
  foreground?: boolean
  /** Discussion strategy to use for this team */
  discussionStrategy: TeamDiscussionStrategy
}

/**
 * Configuration options for TeamManager.
 */
export interface TeamConfig {
  /** Maximum number of agents in a team */
  maxTeamSize: number
  /** Whether to retry failed members once */
  retryFailedMembers: boolean
  /** Maximum time for small model queries (milliseconds) */
  smallModelTimeoutMs: number
  /** Maximum time for delegations (milliseconds) */
  delegationTimeoutMs: number
  /** Clock for timing operations (optional, uses system clock) */
  clock?: Clock
}

/**
 * Maximum number of completed teams to keep in memory.
 * Older completed teams are cleaned up to prevent unbounded memory growth.
 */
const MAX_COMPLETED_TEAMS = 50

/**
 * Orchestrates multi-agent team execution for issue work.
 *
 * Every work-on-issue operation creates a Team (even single-agent work).
 * This unifies the execution path and enables:
 * - Multiple agents working on the same issue with different roles
 * - Discussion rounds between agents to refine analysis
 * - Devil's advocate critical analysis
 * - Coordinated notifications to parent session
 *
 * Delegates specialized responsibilities to:
 * - TeamComposer: Agent selection and team composition
 * - TeamDiscussionStrategy: Discussion coordination between agents
 * - TeamNotifier: Parent notification and XML generation
 *
 * @example
 * ```typescript
 * const manager = new TeamManager(log, client, delegationManager, worktreeManager, config);
 * const result = await manager.create({
 *   projectId: "proj-123",
 *   projectDir: "/path/to/project",
 *   issueId: "proj-123.1",
 *   issueContext: "Implement user authentication",
 *   isolate: true,
 *   foreground: true
 * });
 * ```
 */
export class TeamManager {
  private log: Logger
  private client: OpencodeClient
  private delegationManager: DelegationManager
  private worktreeManager: WorktreeManager
  private config: TeamConfig
  private clock: Clock

  /** Handles agent selection and team composition */
  private composer: TeamComposer
  /** Handles parent session notifications */
  private notifier: TeamNotifier

  /** In-memory cache of teams for fast lookup */
  private teams: Map<string, Team> = new Map()

  /** Maps delegation IDs to team IDs for completion handling */
  private delegationToTeam: Map<string, string> = new Map()

  /** Pending completion promises for foreground mode */
  private completionPromises: Map<string, (team: Team) => void> = new Map()

  /**
   * Stores issue context for teams using sequential launch ordering.
   *
   * Secondary delegations are created after the primary completes, so the
   * issue context must be retained in memory until that point.
   */
  private pendingIssueContexts: Map<string, string> = new Map()

  /**
   * @param log - Logger for diagnostic output
   * @param client - OpenCode client for session management
   * @param delegationManager - Manager for individual agent delegations
   * @param worktreeManager - Manager for VCS worktree operations
   * @param config - Team configuration options
   */
  constructor(
    log: Logger,
    client: OpencodeClient,
    delegationManager: DelegationManager,
    worktreeManager: WorktreeManager,
    config: TeamConfig
  ) {
    this.log = log
    this.client = client
    this.delegationManager = delegationManager
    this.worktreeManager = worktreeManager
    this.config = config
    this.clock = config.clock ?? systemClock

    // Initialize delegate components
    const composerConfig: TeamComposerConfig = {
      maxTeamSize: config.maxTeamSize,
      smallModelTimeoutMs: config.smallModelTimeoutMs,
    }
    this.composer = new TeamComposer(log, client, composerConfig)
    this.notifier = new TeamNotifier(log, client)
  }

  /**
   * Create a team and start all delegations.
   *
   * This is the main entry point for work-on-issue operations.
   * Even single-agent work creates a team of 1.
   */
  async create(options: CreateTeamOptions): Promise<Result<Team, TeamError>> {
    const {
      projectId,
      projectDir,
      issueId,
      issueContext,
      isolate,
      parentSessionId,
      parentAgent,
      discussionStrategy,
    } = options

    // 1. Resolve team composition via TeamComposer
    const agents = await this.composer.resolveTeamComposition(
      options.agents,
      issueContext
    )
    if (agents.length === 0) {
      return {
        ok: false,
        error: { type: "no_agents_available", issueContext },
      }
    }

    await this.log.info(
      `Creating team with ${agents.length} agent(s): ${agents.join(", ")}`
    )

    // 2. Select devil's advocate (if multiple agents)
    let devilsAdvocateAgent: string | undefined
    if (agents.length > 1) {
      devilsAdvocateAgent = await this.composer.selectDevilsAdvocate(
        agents,
        issueContext
      )
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

      if (worktreeResult.ok) {
        worktreePath = worktreeResult.value.path
        worktreeBranch = worktreeResult.value.branch
        vcs = this.worktreeManager.getVCSType() || undefined
        await this.log.info(`Created worktree at ${worktreePath}`)
      } else {
        await this.log.warn(
          `Failed to create worktree: ${worktreeResult.error.message}`
        )
      }
    }

    // 4. Create team record
    const team = this.buildTeamRecord({
      agents,
      devilsAdvocateAgent,
      projectId,
      projectDir,
      issueId,
      worktreePath,
      worktreeBranch,
      vcs,
      parentSessionId,
      parentAgent,
      foreground: options.foreground,
      discussionStrategy,
    })

    // Store in cache
    this.teams.set(team.id, team)
    const saveResult = await this.save(team)
    if (!saveResult.ok) {
      // Clean up worktree if we created one
      if (worktreeBranch) {
        await this.cleanupWorktreeOnFailure(team)
      }
      return saveResult
    }

    // 5. Create delegations for each member
    const delegationResult = await this.createMemberDelegations(
      team,
      issueContext
    )
    if (!delegationResult.ok) {
      // Clean up worktree if delegation creation failed
      if (worktreeBranch) {
        await this.cleanupWorktreeOnFailure(team)
      }
      return delegationResult
    }

    const finalSaveResult = await this.save(team)
    if (!finalSaveResult.ok) {
      // Clean up worktree if final save failed
      if (worktreeBranch) {
        await this.cleanupWorktreeOnFailure(team)
      }
      return finalSaveResult
    }

    await this.log.info(
      `Team ${team.id} started with ${team.members.length} member(s)`
    )

    // Notify strategy that all delegations have been started
    if (team.strategy?.onTeamStarted) {
      await team.strategy.onTeamStarted(team)
    }

    // If foreground mode, wait for completion
    if (options.foreground) {
      await this.log.info(`Team ${team.id}: foreground mode, waiting for completion`)
      return await this.waitForCompletion(team)
    }

    return { ok: true, value: team }
  }

  /**
   * Build the team record from resolved options.
   *
   * Assigns roles to agents: first agent is primary, one is devil's advocate
   * (if selected), rest are secondary reviewers.
   */
  private buildTeamRecord(options: {
    agents: string[]
    devilsAdvocateAgent?: string
    projectId: string
    projectDir: string
    issueId: string
    worktreePath?: string
    worktreeBranch?: string
    vcs?: VCSType
    parentSessionId?: string
    parentAgent?: string
    foreground?: boolean
    discussionStrategy: TeamDiscussionStrategy
  }): Team {
    const {
      agents,
      devilsAdvocateAgent,
      projectId,
      projectDir,
      issueId,
      worktreePath,
      worktreeBranch,
      vcs,
      parentSessionId,
      parentAgent,
      foreground,
      discussionStrategy,
    } = options

    const teamId = this.generateId()
    const now = this.clock.toISOString()

    const members: TeamMember[] = agents.map((agent, index) => {
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
        prompt: "",
      }
    })

    return {
      id: teamId,
      projectId,
      projectDir,
      issueId,
      members,
      status: "running",
      worktreePath,
      worktreeBranch,
      vcs,
      discussionStrategyType: discussionStrategy.type,
      strategy: discussionStrategy,
      results: {},
      discussionHistory: [],
      parentSessionId,
      parentAgent,
      foreground,
      startedAt: now,
    }
  }

  /**
   * Create delegations for all team members.
   *
   * For sequential strategies, only the primary delegation is launched here.
   * Secondary delegations are deferred until the primary completes so reviewers
   * can inspect finished work immediately rather than polling for changes.
   *
   * For concurrent strategies, all delegations are launched immediately.
   */
  private async createMemberDelegations(
    team: Team,
    issueContext: string
  ): Promise<Result<void, TeamError>> {
    const isSequential = team.strategy?.memberLaunchOrdering === "sequential"

    const membersToLaunch = isSequential
      ? team.members.filter((m) => m.role === "primary")
      : team.members

    if (isSequential && team.members.length > 1) {
      this.pendingIssueContexts.set(team.id, issueContext)
    }

    for (const member of membersToLaunch) {
      const prompt = this.buildMemberPrompt(team, member, issueContext)
      member.prompt = prompt

      const result = await this.launchDelegation(team, member)
      if (!result.ok) {
        return result
      }
    }

    return { ok: true, value: undefined }
  }

  /**
   * Launch secondary delegations after the primary completes.
   *
   * Called by sequential strategies once the primary member finishes,
   * so reviewers can inspect completed work rather than polling for changes.
   */
  private async launchSecondaryDelegations(team: Team): Promise<void> {
    const issueContext = this.pendingIssueContexts.get(team.id)
    if (!issueContext) return

    this.pendingIssueContexts.delete(team.id)

    const secondaryMembers = team.members.filter((m) => m.role !== "primary")
    if (secondaryMembers.length === 0) return

    await this.log.info(
      `Team ${team.id}: primary complete, launching ${secondaryMembers.length} secondary delegation(s)`
    )

    for (const member of secondaryMembers) {
      const prompt = this.buildMemberPrompt(team, member, issueContext)
      member.prompt = prompt

      const result = await this.launchDelegation(team, member)
      if (!result.ok) {
        const msg = "message" in result.error ? result.error.message : result.error.type
        await this.log.error(
          `Team ${team.id}: failed to create secondary delegation for ${member.agent}: ${msg}`
        )
        member.status = "failed"
        team.results[member.agent] = {
          agent: member.agent,
          result: `Failed to create delegation: ${msg}`,
          completedAt: this.clock.toISOString(),
        }
        continue
      }
    }

    await this.save(team)
  }

  /**
   * Default timeout for waitForCompletion (30 minutes).
   * Prevents indefinitely hung promises when a team never completes.
   */
  private static readonly DEFAULT_WAIT_TIMEOUT_MS = 30 * 60 * 1000

  /**
   * Wait for a team to complete (foreground mode).
   *
   * Returns a promise that resolves when the team completes (success or failure),
   * or rejects with a timeout error if the team doesn't complete within the timeout.
   *
   * @param team - The team to wait for
   * @param timeoutMs - Maximum time to wait (default: 30 minutes)
   * @returns The completed team, or a timeout error
   */
  async waitForCompletion(
    team: Team,
    timeoutMs: number = TeamManager.DEFAULT_WAIT_TIMEOUT_MS
  ): Promise<Result<Team, TeamError>> {
    // If already complete, return immediately
    const currentTeamResult = await this.get(team.id)
    if (currentTeamResult.ok) {
      const currentTeam = currentTeamResult.value
      if (
        currentTeam.status === "completed" ||
        currentTeam.status === "failed"
      ) {
        await this.log.info(
          `Team ${team.id}: already complete with status ${currentTeam.status}`
        )
        return { ok: true, value: currentTeam }
      }
    }

    // Create a promise that will be resolved when the team completes or times out
    return new Promise<Result<Team, TeamError>>((resolve) => {
      const timeoutId = this.clock.setTimeout(() => {
        this.completionPromises.delete(team.id)
        this.log.warn(
          `Team ${team.id}: timed out after ${timeoutMs / 1000}s waiting for completion`
        )
        resolve({
          ok: false,
          error: {
            type: "timeout",
            teamId: team.id,
            timeoutMs,
            operation: "waitForCompletion",
          },
        })
      }, timeoutMs)

      this.completionPromises.set(team.id, (completedTeam: Team) => {
        this.clock.clearTimeout(timeoutId)
        resolve({ ok: true, value: completedTeam })
      })
      this.log.info(`Team ${team.id}: waiting for completion promise (timeout: ${timeoutMs / 1000}s)`)
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
   * Resolves the team, member, and delegation for a given delegation ID.
   *
   * Returns `null` if any lookup fails, logging the reason at the appropriate level.
   */
  private async loadTeamForDelegation(
    delegationId: string
  ): Promise<{ team: Team; member: TeamMember; delegation: Delegation } | null> {
    const teamId = this.delegationToTeam.get(delegationId)
    if (!teamId) {
      await this.log.debug(
        `Delegation ${delegationId} not associated with a team`
      )
      return null
    }

    const teamResult = await this.get(teamId)
    if (!teamResult.ok) {
      await this.log.warn(
        `Team ${teamId} not found for delegation ${delegationId}`
      )
      return null
    }
    const team = teamResult.value

    const delegationResult = await this.delegationManager.get(delegationId)
    if (!delegationResult.ok) {
      await this.log.warn(`Delegation ${delegationId} not found`)
      return null
    }

    const member = team.members.find((m) => m.delegationId === delegationId)
    if (!member) {
      await this.log.warn(`No member found for delegation ${delegationId}`)
      return null
    }

    return { team, member, delegation: delegationResult.value }
  }

  /**
   * Handle delegation completion callback.
   *
   * Called when a member's delegation completes. Updates member status,
   * handles retries for failures, and triggers team finalization when
   * all members are done.
   *
   * @param delegationId - The completed delegation ID
   */
  async handleDelegationComplete(delegationId: string): Promise<void> {
    const loaded = await this.loadTeamForDelegation(delegationId)
    if (!loaded) return
    const { team, member, delegation } = loaded

    // Update member status based on delegation outcome
    await this.updateMemberStatus(team, member, delegation)
    await this.save(team)

    // Notify strategy that this member has completed; accumulate any returned rounds
    if (team.strategy?.onMemberCompleted) {
      const rounds = await team.strategy.onMemberCompleted(team, member)
      if (rounds.length > 0) {
        team.discussionHistory.push(...rounds)
        await this.save(team)
      }
    }

    // For sequential strategies, launch secondary delegations once the primary finishes
    if (
      member.role === "primary" &&
      team.strategy?.memberLaunchOrdering === "sequential" &&
      this.pendingIssueContexts.has(team.id)
    ) {
      await this.launchSecondaryDelegations(team)
    }

    // Check if all members are done
    const allComplete = team.members.every(
      (m) => m.status === "completed" || m.status === "failed"
    )

    if (!allComplete) {
      const pending = team.members.filter(
        (m) => m.status === "pending" || m.status === "running"
      )
      await this.log.info(
        `Team ${team.id}: waiting for ${pending.length} more member(s)`
      )
      return
    }

    await this.log.info(
      `Team ${team.id}: all members complete, proceeding to next phase`
    )
    await this.finalizeTeam(team)
  }

  /**
   * Update member status based on delegation result.
   *
   * Handles success, failure, and timeout cases. For failures, triggers
   * retry if configured and retry count not exceeded.
   */
  private async updateMemberStatus(
    team: Team,
    member: TeamMember,
    delegation: { status: string; result?: string; error?: string; completedAt?: string }
  ): Promise<void> {
    // Validate delegation status
    const validStatuses = ["completed", "failed", "timeout", "running", "pending"]
    if (!validStatuses.includes(delegation.status)) {
      await this.log.warn(
        `Team ${team.id}: unexpected delegation status "${delegation.status}" for ${member.agent}`
      )
    }

    if (delegation.status === "completed") {
      member.status = "completed"
      team.results[member.agent] = {
        agent: member.agent,
        result: delegation.result || "(no result)",
        completedAt: delegation.completedAt || this.clock.toISOString(),
      }
      await this.log.info(`Team ${team.id}: ${member.agent} completed`)
    } else if (
      delegation.status === "failed" ||
      delegation.status === "timeout"
    ) {
      // Handle failure with retry
      if (this.config.retryFailedMembers && member.retryCount < 1) {
        member.retryCount++
        await this.log.info(
          `Team ${team.id}: ${member.agent} failed, retrying (attempt ${member.retryCount})`
        )
        await this.retryMember(team, member)
        // Save team state after retry to persist retryCount and new delegationId
        await this.save(team)
        return
      }

      member.status = "failed"
      team.results[member.agent] = {
        agent: member.agent,
        result: delegation.error || "(failed)",
        completedAt: this.clock.toISOString(),
      }
      await this.log.warn(
        `Team ${team.id}: ${member.agent} failed after ${member.retryCount} retries`
      )
    }
  }

  /**
   * Finalize team after all members complete.
   *
   * Runs discussion rounds if enabled, sets final status, and notifies
   * parent session (background mode) or resolves completion promise (foreground mode).
   *
   * On failure, cleans up any orphaned worktrees to prevent resource leaks.
   */
  private async finalizeTeam(team: Team): Promise<void> {
    const allFailed = team.members.every((m) => m.status === "failed")

    if (!allFailed && team.members.length > 1 && team.strategy?.onAllMembersCompleted) {
      team.status = "discussing"
      await this.save(team)

      const rounds = await team.strategy.onAllMembersCompleted(
        team,
        async (_history) => {
          await this.save(team)
        }
      )
      team.discussionHistory = rounds
    }

    // Set final status based on member outcomes
    team.status = allFailed ? "failed" : "completed"
    team.completedAt = this.clock.toISOString()
    await this.save(team)

    // Clean up worktree on failure to prevent orphaned workspaces
    if (allFailed && team.worktreePath && team.worktreeBranch) {
      await this.cleanupWorktreeOnFailure(team)
    }

    if (team.foreground) {
      // Foreground mode: resolve the waiting promise
      await this.log.info(
        `Team ${team.id}: foreground mode, resolving completion promise`
      )
      this.resolveCompletionPromise(team)
    } else {
      // Background mode: notify parent session via TeamNotifier
      await this.notifier.notifyParent(team)
    }

    // Clean up delegation mappings and prune old completed teams
    for (const m of team.members) {
      if (m.delegationId) {
        this.delegationToTeam.delete(m.delegationId)
      }
    }
    this.pruneCompletedTeams()
  }

  /**
   * Clean up worktree when a team fails completely.
   *
   * Prevents orphaned worktrees from accumulating when delegations fail
   * during startup (e.g., JSON parse errors, connection issues).
   */
  private async cleanupWorktreeOnFailure(team: Team): Promise<void> {
    if (!team.worktreeBranch) return

    const worktreeName = team.worktreeBranch

    await this.log.info(
      `Team ${team.id}: cleaning up worktree '${worktreeName}' after failure`
    )

    const removeResult = await this.worktreeManager.removeWorktree(worktreeName)
    if (!removeResult.ok) {
      // Log but don't fail - worktree cleanup is best-effort
      await this.log.warn(
        `Team ${team.id}: failed to clean up worktree '${worktreeName}': ${removeResult.error.message}`
      )
    } else {
      await this.log.info(
        `Team ${team.id}: successfully cleaned up worktree '${worktreeName}'`
      )
    }
  }

  /**
   * Prune old completed teams from in-memory cache to prevent unbounded memory growth.
   * Keeps the most recent MAX_COMPLETED_TEAMS completed teams.
   */
  private pruneCompletedTeams(): void {
    const completed = Array.from(this.teams.values())
      .filter((t) => t.status === "completed" || t.status === "failed")
      .sort((a, b) => new Date(b.completedAt || b.startedAt).getTime() - new Date(a.completedAt || a.startedAt).getTime())

    if (completed.length > MAX_COMPLETED_TEAMS) {
      const toRemove = completed.slice(MAX_COMPLETED_TEAMS)
      for (const team of toRemove) {
        this.teams.delete(team.id)
        // Also clean up any remaining delegation mappings for this team
        for (const member of team.members) {
          if (member.delegationId) {
            this.delegationToTeam.delete(member.delegationId)
          }
        }
      }
    }
  }

  /**
   * Build the prompt for a team member based on their role.
   *
   * Primary agents get implementation instructions with worktree access.
   * Reviewers and devil's advocates get analysis instructions.
   */
  private buildMemberPrompt(
    team: Team,
    member: TeamMember,
    issueContext: string
  ): string {
    const primary = team.members.find((m) => m.role === "primary")

    const data: TeamMemberData =
      member.role === "primary"
        ? {
            role: "primary",
            agent: member.agent,
            hasReviewers: team.members.length > 1,
            issueContext,
            issueId: team.issueId,
            projectDir: team.projectDir,
            worktreePath: team.worktreePath,
          }
        : {
            role: member.role === "devilsAdvocate" ? "devilsAdvocate" : "reviewer",
            agent: member.agent,
            isConcurrent: team.strategy?.memberLaunchOrdering === "concurrent",
            issueContext,
            issueId: team.issueId,
            primaryAgent: primary?.agent || "unknown",
            projectDir: team.projectDir,
            worktreePath: team.worktreePath,
          }

    return teamMemberTemplate.render(data)
  }

  /**
   * Creates and tracks a delegation for a team member using `member.prompt`.
   *
   * On success, updates `member.delegationId`, `member.sessionId`, `member.status`,
   * and registers the delegation in `delegationToTeam`.
   */
  private async launchDelegation(
    team: Team,
    member: TeamMember
  ): Promise<Result<void, TeamError>> {
    const delegationOptions: CreateDelegationOptions = {
      issueId: team.issueId,
      prompt: member.prompt,
      teamId: team.id,
      role: member.role,
      worktreePath: team.worktreePath,
      worktreeBranch: team.worktreeBranch,
      vcs: team.vcs,
      agent: member.agent,
      parentSessionId: team.parentSessionId,
      parentAgent: team.parentAgent,
      onComplete: (delegationId: string) =>
        this.handleDelegationComplete(delegationId),
    }

    const delegationResult = await this.delegationManager.create(
      team.projectId,
      team.projectDir,
      delegationOptions
    )
    if (!delegationResult.ok) {
      return {
        ok: false,
        error: {
          type: "persistence_failed",
          teamId: team.id,
          message: `Failed to create delegation: ${delegationResult.error.type}`,
        },
      }
    }

    const delegation = delegationResult.value
    member.delegationId = delegation.id
    member.sessionId = delegation.sessionId
    member.status = "running"
    this.delegationToTeam.set(delegation.id, team.id)

    return { ok: true, value: undefined }
  }

  /**
   * Retry a failed member by creating a new delegation using the stored prompt.
   */
  private async retryMember(team: Team, member: TeamMember): Promise<void> {
    // Remove old delegation mapping before creating a new one
    if (member.delegationId) {
      this.delegationToTeam.delete(member.delegationId)
    }

    const result = await this.launchDelegation(team, member)
    if (!result.ok) {
      const msg = "message" in result.error ? result.error.message : result.error.type
      await this.log.error(
        `Failed to create retry delegation: ${msg}`
      )
    }
  }

  /**
   * Get a team by ID from the in-memory cache.
   *
   * @param teamId - The team ID to look up
   * @returns The team if found, or a not_found error
   */
  async get(teamId: string): Promise<Result<Team, TeamError>> {
    // Check cache first
    const cached = this.teams.get(teamId)
    if (cached) {
      return { ok: true, value: cached }
    }

    // Team not in cache - cannot retrieve without knowing project directory
    return { ok: false, error: { type: "not_found", teamId } }
  }

  /**
   * Save a team to disk as JSON.
   *
   * Persists to {projectDir}/teams/{teamId}.json
   */
  private async save(team: Team): Promise<Result<void, TeamError>> {
    try {
      this.teams.set(team.id, team)
      const teamsDir = path.join(team.projectDir, "teams")
      await fs.mkdir(teamsDir, { recursive: true })
      const filePath = path.join(teamsDir, `${team.id}.json`)
      const { strategy: _strategy, ...persistable } = team
      await fs.writeFile(filePath, JSON.stringify(persistable, null, 2), "utf8")
      return { ok: true, value: undefined }
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error)
      return {
        ok: false,
        error: { type: "persistence_failed", teamId: team.id, message },
      }
    }
  }

  /**
   * List teams for an issue from the in-memory cache.
   *
   * @param issueId - The issue to list teams for
   * @returns Teams for the issue, sorted by start time (newest first)
   */
  async listByIssue(issueId: string): Promise<Team[]> {
    const teams = Array.from(this.teams.values()).filter(
      (t) => t.issueId === issueId
    )

    return teams.sort(
      (a, b) => new Date(b.startedAt).getTime() - new Date(a.startedAt).getTime()
    )
  }

  /**
   * Get all running teams from the in-memory cache.
   *
   * @returns Teams with status "running" or "discussing"
   */
  async getRunningTeams(): Promise<Team[]> {
    return Array.from(this.teams.values()).filter(
      (t) => t.status === "running" || t.status === "discussing"
    )
  }

  /**
   * Generate a unique team ID.
   *
   * Format: team-{base36-timestamp}-{hex-random}
   */
  private generateId(): string {
    const timestamp = this.clock.now().toString(36)
    const random = crypto.randomBytes(4).toString("hex")
    return `team-${timestamp}-${random}`
  }

  // Expose delegate components for testing
  /** @internal */
  get _composer(): TeamComposer {
    return this.composer
  }



  /** @internal */
  get _notifier(): TeamNotifier {
    return this.notifier
  }
}
