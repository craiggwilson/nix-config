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
 * - DiscussionCoordinator: Multi-round discussion logic
 * - TeamNotifier: Parent notification and XML generation
 */

import * as fs from "node:fs/promises"
import * as path from "node:path"
import * as crypto from "node:crypto"

import type { VCSType } from "../vcs/index.js"
import type { Logger, OpencodeClient } from "../utils/opencode-sdk/index.js"
import type { TeamError } from "../utils/errors/index.js"
import {
  teamMemberTemplate,
  type TeamMemberData,
} from "../utils/prompts/index.js"
import type {
  DelegationManager,
  CreateDelegationOptions,
} from "./delegation-manager.js"
import type { WorktreeManager } from "../vcs/index.js"
import { TeamComposer, type TeamComposerConfig } from "./team-composer.js"
import { DiscussionCoordinator, type DiscussionCoordinatorConfig } from "./discussion-coordinator.js"
import { TeamNotifier } from "./team-notifier.js"

/**
 * Role of a team member in multi-agent execution.
 *
 * - primary: Does the main implementation work, has access to worktree
 * - secondary: Reviews and provides feedback on primary's work
 * - devilsAdvocate: Critically analyzes for potential issues and edge cases
 */
export type TeamMemberRole = "primary" | "secondary" | "devilsAdvocate"

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
  /** Number of discussion rounds (0 = disabled) */
  discussionRounds: number
  /** Current discussion round (0 = initial work phase) */
  currentRound: number
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
}

/**
 * Configuration options for TeamManager.
 */
export interface TeamConfig {
  /** Number of discussion rounds after initial work (0 = disabled) */
  discussionRounds: number
  /** Maximum time per discussion round (milliseconds) */
  discussionRoundTimeoutMs: number
  /** Maximum number of agents in a team */
  maxTeamSize: number
  /** Whether to retry failed members once */
  retryFailedMembers: boolean
  /** Maximum time for small model queries (milliseconds) */
  smallModelTimeoutMs: number
  /** Maximum time for delegations (milliseconds) */
  delegationTimeoutMs: number
}
import type { Result } from "../utils/result/index.js"

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
 * - DiscussionCoordinator: Multi-round discussion logic
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

  /** Handles agent selection and team composition */
  private composer: TeamComposer
  /** Manages multi-round discussion logic */
  private discussionCoordinator: DiscussionCoordinator
  /** Handles parent session notifications */
  private notifier: TeamNotifier

  /** In-memory cache of teams for fast lookup */
  private teams: Map<string, Team> = new Map()

  /** Maps delegation IDs to team IDs for completion handling */
  private delegationToTeam: Map<string, string> = new Map()

  /** Pending completion promises for foreground mode */
  private completionPromises: Map<string, (team: Team) => void> = new Map()

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

    // Initialize delegate components
    const composerConfig: TeamComposerConfig = {
      maxTeamSize: config.maxTeamSize,
      smallModelTimeoutMs: config.smallModelTimeoutMs,
    }
    this.composer = new TeamComposer(log, client, composerConfig)

    const discussionConfig: DiscussionCoordinatorConfig = {
      discussionRoundTimeoutMs: config.discussionRoundTimeoutMs,
    }
    this.discussionCoordinator = new DiscussionCoordinator(
      log,
      client,
      discussionConfig
    )

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
    } = options

    const teamId = this.generateId()
    const now = new Date().toISOString()

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
      discussionRounds: agents.length > 1 ? this.config.discussionRounds : 0,
      currentRound: 0,
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
   * Each member gets a delegation with a role-specific prompt.
   * Primary agent gets worktree access; others work in read-only mode.
   */
  private async createMemberDelegations(
    team: Team,
    issueContext: string
  ): Promise<Result<void, TeamError>> {
    for (const member of team.members) {
      const prompt = this.buildMemberPrompt(team, member, issueContext)

      const delegationOptions: CreateDelegationOptions = {
        issueId: team.issueId,
        prompt,
        teamId: team.id,
        role: member.role,
        worktreePath: member.role === "primary" ? team.worktreePath : undefined,
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

      // Track delegation -> team mapping
      this.delegationToTeam.set(delegation.id, team.id)
    }

    return { ok: true, value: undefined }
  }

  /**
   * Wait for a team to complete (foreground mode).
   *
   * Returns a promise that resolves when the team completes (success or failure).
   * The promise is resolved by handleDelegationComplete when all members finish.
   *
   * @param team - The team to wait for
   * @returns The completed team, or an error
   */
  async waitForCompletion(team: Team): Promise<Result<Team, TeamError>> {
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

    // Create a promise that will be resolved when the team completes
    return new Promise<Result<Team, TeamError>>((resolve) => {
      this.completionPromises.set(team.id, (completedTeam: Team) => {
        resolve({ ok: true, value: completedTeam })
      })
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
   * Handle delegation completion callback.
   *
   * Called when a member's delegation completes. Updates member status,
   * handles retries for failures, and triggers team finalization when
   * all members are done.
   *
   * @param delegationId - The completed delegation ID
   */
  async handleDelegationComplete(delegationId: string): Promise<void> {
    const teamId = this.delegationToTeam.get(delegationId)
    if (!teamId) {
      await this.log.debug(
        `Delegation ${delegationId} not associated with a team`
      )
      return
    }

    const teamResult = await this.get(teamId)
    if (!teamResult.ok) {
      await this.log.warn(
        `Team ${teamId} not found for delegation ${delegationId}`
      )
      return
    }
    const team = teamResult.value

    // Get the delegation to check its status
    const delegationResult = await this.delegationManager.get(delegationId)
    if (!delegationResult.ok) {
      await this.log.warn(`Delegation ${delegationId} not found`)
      return
    }
    const delegation = delegationResult.value

    // Find and update the member
    const member = team.members.find((m) => m.delegationId === delegationId)
    if (!member) {
      await this.log.warn(`No member found for delegation ${delegationId}`)
      return
    }

    // Update member status based on delegation status
    await this.updateMemberStatus(team, member, delegation)
    await this.save(team)

    // Check if all members complete
    const allComplete = team.members.every(
      (m) => m.status === "completed" || m.status === "failed"
    )

    if (!allComplete) {
      const pending = team.members.filter(
        (m) => m.status === "pending" || m.status === "running"
      )
      await this.log.info(
        `Team ${teamId}: waiting for ${pending.length} more member(s)`
      )
      return
    }

    await this.log.info(
      `Team ${teamId}: all members complete, proceeding to next phase`
    )

    // Finalize team
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
        completedAt: delegation.completedAt || new Date().toISOString(),
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
        completedAt: new Date().toISOString(),
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

    // Run discussion if enabled, multiple members, and not all failed
    if (team.discussionRounds > 0 && team.members.length > 1 && !allFailed) {
      team.status = "discussing"
      await this.save(team)

      // Run discussion via DiscussionCoordinator
      team.discussionHistory = await this.discussionCoordinator.runDiscussion(
        team,
        async (round, _responses) => {
          team.currentRound = round
          await this.save(team)
        }
      )
    }

    // Set final status based on member outcomes
    team.status = allFailed ? "failed" : "completed"
    team.completedAt = new Date().toISOString()
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

    // Extract worktree name from branch (format: projectId/issueId)
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
            issueId: team.issueId,
            issueContext,
            worktreePath: team.worktreePath,
            hasReviewers: team.members.length > 1,
          }
        : {
            role: member.role === "devilsAdvocate" ? "devilsAdvocate" : "reviewer",
            agent: member.agent,
            issueId: team.issueId,
            issueContext,
            worktreePath: team.worktreePath,
            primaryAgent: primary?.agent || "unknown",
          }

    return teamMemberTemplate.render(data)
  }

  /**
   * Retry a failed member by creating a new delegation.
   *
   * Appends a retry notice to the original prompt and creates a fresh delegation.
   */
  private async retryMember(team: Team, member: TeamMember): Promise<void> {
    if (!member.delegationId) return

    // Get the original delegation for context
    const originalDelegationResult = await this.delegationManager.get(
      member.delegationId
    )
    if (!originalDelegationResult.ok) return
    const originalDelegation = originalDelegationResult.value

    // Remove old mapping
    this.delegationToTeam.delete(member.delegationId)

    // Create a new delegation
    const delegationOptions: CreateDelegationOptions = {
      issueId: team.issueId,
      prompt:
        originalDelegation.prompt +
        "\n\n[RETRY: Previous attempt failed. Please try again.]",
      teamId: team.id,
      role: member.role,
      worktreePath: member.role === "primary" ? team.worktreePath : undefined,
      worktreeBranch: team.worktreeBranch,
      vcs: team.vcs,
      agent: member.agent,
      parentSessionId: team.parentSessionId,
      parentAgent: team.parentAgent,
      onComplete: (delegationId: string) =>
        this.handleDelegationComplete(delegationId),
    }

    const newDelegationResult = await this.delegationManager.create(
      team.projectId,
      team.projectDir,
      delegationOptions
    )
    if (!newDelegationResult.ok) {
      await this.log.error(
        `Failed to create retry delegation: ${newDelegationResult.error.type}`
      )
      return
    }
    const newDelegation = newDelegationResult.value

    member.delegationId = newDelegation.id
    member.sessionId = newDelegation.sessionId
    member.status = "running"

    // Track new delegation
    this.delegationToTeam.set(newDelegation.id, team.id)
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
      await fs.writeFile(filePath, JSON.stringify(team, null, 2), "utf8")
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
    const timestamp = Date.now().toString(36)
    const random = crypto.randomBytes(4).toString("hex")
    return `team-${timestamp}-${random}`
  }

  // Expose delegate components for testing
  /** @internal */
  get _composer(): TeamComposer {
    return this.composer
  }

  /** @internal */
  get _discussionCoordinator(): DiscussionCoordinator {
    return this.discussionCoordinator
  }

  /** @internal */
  get _notifier(): TeamNotifier {
    return this.notifier
  }
}
