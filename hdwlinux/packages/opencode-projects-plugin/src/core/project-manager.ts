/**
 * ProjectManager - Core business logic for project operations
 *
 * This class encapsulates all project management operations and can be used
 * independently of the OpenCode plugin context (e.g., for SDK usage).
 */

import * as fs from "node:fs/promises"
import * as path from "node:path"
import * as crypto from "node:crypto"

import type { IssueStorage, Issue, CreateIssueOptions, ProjectStatus } from "../storage/index.js"
import type { FocusManager } from "./focus-manager.js"
import type { ConfigManager } from "./config-manager.js"
import type {
  Logger,
  OpencodeClient,
  PlanningState,
  PlanningPhase,
  PlanningUnderstanding,
  BunShell,
  VCSType,
} from "./types.js"
import { PlanningManager } from "../planning/index.js"
import { IssueManager, type UpdateIssueOptions, type CompletionCommentOptions } from "./issue-manager.js"
import { WorktreeManager } from "../execution/worktree-manager.js"
import type { DelegationManager, Delegation } from "../execution/delegation-manager.js"

/**
 * Project metadata stored in project.json
 */
export interface ProjectMetadata {
  id: string
  name: string
  type: "roadmap" | "project"
  description?: string
  storage: "local" | "global"
  workspace?: string
  rootIssue?: string
  createdAt: string
  closedAt?: string
  closeReason?: string
  closeSummary?: string
  status: "active" | "completed" | "archived"
}

/**
 * Options for creating a project
 */
export interface CreateProjectOptions {
  name: string
  type?: "roadmap" | "project"
  workspace?: string
  storage?: "local" | "global"
  description?: string
}

/**
 * Options for listing projects
 */
export interface ListProjectsOptions {
  scope?: "local" | "global" | "all"
  status?: "active" | "completed" | "all"
}

/**
 * Options for closing a project
 */
export interface CloseProjectOptions {
  reason?: "completed" | "cancelled" | "archived"
  summary?: string
}

/**
 * Result of creating a project
 */
export interface CreateProjectResult {
  projectId: string
  projectDir: string
  rootIssueId?: string
  metadata: ProjectMetadata
}

/**
 * ProjectManager dependencies
 */
export interface ProjectManagerDeps {
  config: ConfigManager
  issueStorage: IssueStorage
  focus: FocusManager
  log: Logger
  repoRoot: string
  client?: OpencodeClient
  $?: BunShell
  delegationManager?: DelegationManager
}

/**
 * Options for starting work on an issue
 */
export interface StartWorkOptions {
  /** Create isolated worktree for code changes */
  isolate?: boolean
  /** Agent to use for delegation (auto-selected if not specified) */
  agent?: string
  /** Parent session ID for notifications */
  parentSessionId?: string
}

/**
 * Result of starting work on an issue
 */
export interface StartWorkResult {
  success: boolean
  issue: Issue
  delegation?: Delegation
  worktreePath?: string
  worktreeBranch?: string
  vcs?: VCSType
  error?: string
}

/**
 * Generate a project ID from name
 */
function generateProjectId(name: string): string {
  const slug = name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "")
    .slice(0, 30)

  const hash = crypto.randomBytes(3).toString("hex")
  return `${slug}-${hash}`
}

/**
 * ProjectManager - encapsulates all project operations
 */
export class ProjectManager {
  private config: ConfigManager
  private issueStorage: IssueStorage
  private issueManager: IssueManager
  private focus: FocusManager
  private log: Logger
  private repoRoot: string
  private client?: OpencodeClient
  private $?: BunShell
  private delegationManager?: DelegationManager

  constructor(deps: ProjectManagerDeps) {
    this.config = deps.config
    this.issueStorage = deps.issueStorage
    this.focus = deps.focus
    this.log = deps.log
    this.repoRoot = deps.repoRoot
    this.client = deps.client
    this.$ = deps.$
    this.delegationManager = deps.delegationManager

    // Create IssueManager with shared dependencies
    this.issueManager = new IssueManager({
      issueStorage: deps.issueStorage,
      focus: deps.focus,
      log: deps.log,
    })
  }

  /**
   * Get the IssueManager instance for direct issue operations
   */
  getIssueManager(): IssueManager {
    return this.issueManager
  }

  /**
   * Set the delegation manager (for late binding)
   */
  setDelegationManager(delegationManager: DelegationManager): void {
    this.delegationManager = delegationManager
  }

  /**
   * Create a new project
   */
  async createProject(options: CreateProjectOptions): Promise<CreateProjectResult> {
    const { name, type = "project", workspace, storage, description } = options

    await this.log.info(`Creating project: ${name}`)
    const projectId = generateProjectId(name)
    const effectiveWorkspace = workspace || this.repoRoot
    const effectiveStorage = storage || this.config.getDefaultStorage()
    const projectDir = this.config.resolveProjectDir(projectId, effectiveWorkspace, effectiveStorage)
    try {
      await fs.access(projectDir)
      throw new Error(`Project directory already exists at ${projectDir}`)
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code !== "ENOENT") {
        throw error
      }
      // Directory doesn't exist, good to proceed
    }
    await fs.mkdir(projectDir, { recursive: true })
    await fs.mkdir(path.join(projectDir, "research"), { recursive: true })
    await fs.mkdir(path.join(projectDir, "interviews"), { recursive: true })
    await fs.mkdir(path.join(projectDir, "plans"), { recursive: true })
    const storageInitialized = await this.issueStorage.init(projectDir, {
      stealth: effectiveStorage === "global",
    })

    if (!storageInitialized) {
      await this.log.warn("Failed to initialize issue storage")
    }
    let rootIssueId: string | null = null
    if (storageInitialized) {
      rootIssueId = await this.issueStorage.createIssue(projectDir, name, {
        priority: 0,
        description: description || `Root epic for ${name}`,
        labels: ["epic", type],
      })
    }
    const metadata: ProjectMetadata = {
      id: projectId,
      name,
      type,
      description,
      storage: effectiveStorage,
      workspace: effectiveWorkspace,
      rootIssue: rootIssueId || undefined,
      createdAt: new Date().toISOString(),
      status: "active",
    }

    await fs.writeFile(
      path.join(projectDir, "project.json"),
      JSON.stringify(metadata, null, 2),
      "utf8"
    )
    this.config.setProjectOverrides(projectId, {
      storage: effectiveStorage,
      workspaces: [effectiveWorkspace],
    })
    await this.config.save()
    this.focus.setFocus(projectId)

    return {
      projectId,
      projectDir,
      rootIssueId: rootIssueId || undefined,
      metadata,
    }
  }

  /**
   * List all projects
   */
  async listProjects(options: ListProjectsOptions = {}): Promise<ProjectMetadata[]> {
    const { scope = "all", status = "all" } = options

    const projects: ProjectMetadata[] = []
    if (scope === "local" || scope === "all") {
      const localDir = this.config.getLocalProjectsDir(this.repoRoot)
      const localProjects = await this.scanProjectsDir(localDir, "local")
      projects.push(...localProjects)
    }
    if (scope === "global" || scope === "all") {
      const globalDir = this.config.getGlobalProjectsDir()
      const globalProjects = await this.scanProjectsDir(globalDir, "global")
      projects.push(...globalProjects)
    }
    if (status === "all") {
      return projects
    }

    return projects.filter((p) => p.status === status)
  }

  /**
   * Get project metadata by ID
   */
  async getProject(projectId: string): Promise<ProjectMetadata | null> {
    const projectDir = await this.findProjectDir(projectId)
    if (!projectDir) return null

    return this.loadProjectMetadata(projectDir)
  }

  /**
   * Get project directory by ID
   */
  async getProjectDir(projectId: string): Promise<string | null> {
    return this.findProjectDir(projectId)
  }

  /**
   * Get project status including issue progress
   */
  async getProjectStatus(projectId: string): Promise<{
    metadata: ProjectMetadata
    issueStatus: ProjectStatus | null
  } | null> {
    const projectDir = await this.findProjectDir(projectId)
    if (!projectDir) return null

    const metadata = await this.loadProjectMetadata(projectDir)
    if (!metadata) return null

    const issueStatus = await this.issueStorage.getProjectStatus(projectDir)

    return { metadata, issueStatus }
  }

  /**
   * Close a project
   */
  async closeProject(projectId: string, options: CloseProjectOptions = {}): Promise<boolean> {
    const { reason = "completed", summary } = options

    const projectDir = await this.findProjectDir(projectId)
    if (!projectDir) return false

    const metadata = await this.loadProjectMetadata(projectDir)
    if (!metadata) return false
    metadata.status = reason === "cancelled" ? "archived" : reason
    metadata.closedAt = new Date().toISOString()
    metadata.closeReason = reason
    if (summary) {
      metadata.closeSummary = summary
    }

    await fs.writeFile(
      path.join(projectDir, "project.json"),
      JSON.stringify(metadata, null, 2),
      "utf8"
    )
    if (this.focus.isFocusedOn(projectId)) {
      this.focus.clear()
    }

    await this.log.info(`Closed project: ${projectId}`)
    return true
  }

  /**
   * Create an issue in a project.
   * If no parent is specified, defaults to the project's root issue.
   */
  async createIssue(
    projectId: string,
    title: string,
    options?: CreateIssueOptions
  ): Promise<string | null> {
    const projectDir = await this.findProjectDir(projectId)
    if (!projectDir) return null

    // Default parent to root issue if not specified
    let effectiveOptions = options
    if (!options?.parent) {
      const metadata = await this.loadProjectMetadata(projectDir)
      if (metadata?.rootIssue) {
        effectiveOptions = { ...options, parent: metadata.rootIssue }
      }
    }

    return this.issueManager.createIssue(projectDir, title, effectiveOptions)
  }

  /**
   * Get an issue by ID
   */
  async getIssue(projectId: string, issueId: string): Promise<Issue | null> {
    const projectDir = await this.findProjectDir(projectId)
    if (!projectDir) return null

    return this.issueManager.getIssue(projectDir, issueId)
  }

  /**
   * List issues in a project
   */
  async listIssues(projectId: string): Promise<Issue[]> {
    const projectDir = await this.findProjectDir(projectId)
    if (!projectDir) return []

    return this.issueManager.listIssues(projectDir)
  }

  /**
   * Get ready issues (no blockers)
   */
  async getReadyIssues(projectId: string): Promise<Issue[]> {
    const projectDir = await this.findProjectDir(projectId)
    if (!projectDir) return []

    return this.issueManager.getReadyIssues(projectDir)
  }

  /**
   * Claim an issue
   */
  async claimIssue(projectId: string, issueId: string, assignee?: string): Promise<boolean> {
    const projectDir = await this.findProjectDir(projectId)
    if (!projectDir) return false

    return this.issueManager.claimIssue(projectDir, issueId, assignee)
  }

  /**
   * Update an issue
   */
  async updateIssue(
    projectId: string,
    issueId: string,
    options: UpdateIssueOptions
  ): Promise<boolean> {
    const projectDir = await this.findProjectDir(projectId)
    if (!projectDir) return false

    return this.issueManager.updateIssue(projectDir, issueId, options)
  }

  /**
   * Add a comment to an issue
   */
  async addIssueComment(projectId: string, issueId: string, comment: string): Promise<boolean> {
    const projectDir = await this.findProjectDir(projectId)
    if (!projectDir) return false

    return this.issueManager.addComment(projectDir, issueId, comment)
  }

  /**
   * Add a completion comment when closing an issue
   */
  async addCompletionComment(
    projectId: string,
    issueId: string,
    options: CompletionCommentOptions
  ): Promise<boolean> {
    const projectDir = await this.findProjectDir(projectId)
    if (!projectDir) return false

    return this.issueManager.addCompletionComment(projectDir, issueId, options)
  }

  /**
   * Start work on an issue with a background agent.
   *
   * This method:
   * 1. Validates the issue exists and is not already in progress
   * 2. Optionally creates an isolated worktree (if isolate=true)
   * 3. Claims the issue (sets status to in_progress)
   * 4. Creates a delegation to a background agent
   * 5. Stores delegation metadata on the issue
   *
   * @param projectId - Project ID
   * @param issueId - Issue ID to work on
   * @param options - Options for starting work
   * @returns Result with delegation info or error
   */
  async startWorkOnIssue(
    projectId: string,
    issueId: string,
    options: StartWorkOptions = {}
  ): Promise<StartWorkResult> {
    const { isolate = false, agent, parentSessionId } = options

    // Validate delegation manager is available
    if (!this.delegationManager) {
      return {
        success: false,
        issue: { id: issueId, title: "", status: "open", priority: 2, createdAt: "", updatedAt: "" },
        error: "Delegation manager not available. Cannot start background work.",
      }
    }

    // Get project directory
    const projectDir = await this.findProjectDir(projectId)
    if (!projectDir) {
      return {
        success: false,
        issue: { id: issueId, title: "", status: "open", priority: 2, createdAt: "", updatedAt: "" },
        error: `Project '${projectId}' not found.`,
      }
    }

    // Get the issue
    const issue = await this.issueManager.getIssue(projectDir, issueId)
    if (!issue) {
      return {
        success: false,
        issue: { id: issueId, title: "", status: "open", priority: 2, createdAt: "", updatedAt: "" },
        error: `Issue '${issueId}' not found in project '${projectId}'.`,
      }
    }

    // Check if already in progress
    if (issue.status === "in_progress") {
      return {
        success: false,
        issue,
        error: `Issue '${issueId}' is already in progress${issue.assignee ? ` (assigned to ${issue.assignee})` : ""}.`,
      }
    }

    await this.log.info(`Starting work on issue ${issueId} in project ${projectId} (isolate=${isolate})`)

    // Variables for worktree (only used if isolate=true)
    let worktreePath: string | undefined
    let worktreeBranch: string | undefined
    let vcs: VCSType | undefined

    // Create worktree if isolate=true
    if (isolate) {
      if (!this.$) {
        return {
          success: false,
          issue,
          error: "Shell not available. Cannot create isolated worktree.",
        }
      }

      const worktreeManager = new WorktreeManager(this.repoRoot, this.$, this.log)
      const adapter = await worktreeManager.detectVCS()

      if (!adapter) {
        return {
          success: false,
          issue,
          error: "No VCS detected (git or jj required). Cannot create isolated worktree.",
        }
      }

      vcs = worktreeManager.getVCSType() || undefined

      const worktreeResult = await worktreeManager.createIsolatedWorktree({
        projectId,
        issueId,
      })

      if (!worktreeResult.success || !worktreeResult.info) {
        return {
          success: false,
          issue,
          error: `Failed to create worktree: ${worktreeResult.error || "Unknown error"}`,
        }
      }

      worktreePath = worktreeResult.info.path
      worktreeBranch = worktreeResult.info.branch
    }

    // Claim the issue
    const claimed = await this.issueManager.claimIssue(projectDir, issueId)
    if (!claimed) {
      return {
        success: false,
        issue,
        error: `Failed to claim issue '${issueId}'. Check issue storage configuration.`,
      }
    }

    // Create delegation
    const delegation = await this.delegationManager.create(projectId, {
      issueId,
      prompt: `Work on issue: ${issue.title}\n\n${issue.description || ""}`,
      worktreePath,
      worktreeBranch,
      vcs,
      agent,
      parentSessionId,
    })

    // Store delegation metadata on the issue
    await this.issueManager.setDelegationMetadata(projectDir, issueId, {
      delegationId: delegation.id,
      delegationStatus: "running",
    })

    return {
      success: true,
      issue,
      delegation,
      worktreePath,
      worktreeBranch,
      vcs,
    }
  }

  /**
   * Get the currently focused project ID
   */
  getFocusedProjectId(): string | null {
    return this.focus.getProjectId()
  }

  /**
   * Get the currently focused issue ID
   */
  getFocusedIssueId(): string | null {
    return this.focus.getIssueId()
  }

  /**
   * Set focus to a project
   */
  setFocus(projectId: string, issueId?: string): void {
    this.focus.setFocus(projectId, issueId)
  }

  /**
   * Clear focus
   */
  clearFocus(): void {
    this.focus.clear()
  }

  // ============================================================================
  // Planning State Management (delegates to PlanningManager)
  // ============================================================================

  /**
   * Get a PlanningManager for a project
   */
  async getPlanningManager(projectId: string): Promise<PlanningManager | null> {
    const projectDir = await this.findProjectDir(projectId)
    if (!projectDir) return null

    return new PlanningManager(projectDir, this.log)
  }

  /**
   * Get the planning state for a project
   */
  async getPlanningState(projectId: string): Promise<PlanningState | null> {
    const manager = await this.getPlanningManager(projectId)
    if (!manager) return null

    return manager.getState()
  }

  /**
   * Start or continue a planning session
   */
  async startOrContinuePlanning(projectId: string): Promise<PlanningState> {
    const manager = await this.getPlanningManager(projectId)
    if (!manager) {
      throw new Error(`Project not found: ${projectId}`)
    }

    return manager.startOrContinue()
  }

  /**
   * Advance to the next planning phase
   */
  async advancePlanningPhase(projectId: string): Promise<PlanningState> {
    const manager = await this.getPlanningManager(projectId)
    if (!manager) {
      throw new Error(`Project not found: ${projectId}`)
    }

    return manager.advancePhase()
  }

  /**
   * Jump to a specific planning phase
   */
  async setPlanningPhase(projectId: string, phase: PlanningPhase): Promise<PlanningState> {
    const manager = await this.getPlanningManager(projectId)
    if (!manager) {
      throw new Error(`Project not found: ${projectId}`)
    }

    return manager.setPhase(phase)
  }

  /**
   * Update the planning understanding
   */
  async updatePlanningUnderstanding(
    projectId: string,
    updates: Partial<PlanningUnderstanding>
  ): Promise<PlanningState> {
    const manager = await this.getPlanningManager(projectId)
    if (!manager) {
      throw new Error(`Project not found: ${projectId}`)
    }

    return manager.updateUnderstanding(updates)
  }

  /**
   * Update open questions
   */
  async updateOpenQuestions(projectId: string, questions: string[]): Promise<PlanningState> {
    const manager = await this.getPlanningManager(projectId)
    if (!manager) {
      throw new Error(`Project not found: ${projectId}`)
    }

    return manager.updateOpenQuestions(questions)
  }

  /**
   * Check if planning is active for a project
   */
  async isPlanningActive(projectId: string): Promise<boolean> {
    const manager = await this.getPlanningManager(projectId)
    if (!manager) return false

    return manager.isActive()
  }

  /**
   * Scan a directory for projects
   */
  private async scanProjectsDir(
    dir: string,
    storage: "local" | "global"
  ): Promise<ProjectMetadata[]> {
    const projects: ProjectMetadata[] = []

    try {
      const entries = await fs.readdir(dir, { withFileTypes: true })

      for (const entry of entries) {
        if (!entry.isDirectory()) continue

        const projectDir = path.join(dir, entry.name)
        const metadata = await this.loadProjectMetadata(projectDir)

        if (metadata) {
          metadata.storage = storage // Ensure storage is set correctly
          projects.push(metadata)
        }
      }
    } catch {
      // Directory doesn't exist
    }

    return projects
  }

  /**
   * Find project directory by ID
   */
  private async findProjectDir(projectId: string): Promise<string | null> {
    // Check local first
    const localDir = path.join(this.config.getLocalProjectsDir(this.repoRoot), projectId)
    try {
      await fs.access(localDir)
      return localDir
    } catch {
      // Not in local
    }

    // Check global
    const globalDir = path.join(this.config.getGlobalProjectsDir(), projectId)
    try {
      await fs.access(globalDir)
      return globalDir
    } catch {
      // Not in global
    }

    return null
  }

  /**
   * Load project metadata from directory
   */
  private async loadProjectMetadata(projectDir: string): Promise<ProjectMetadata | null> {
    try {
      const content = await fs.readFile(path.join(projectDir, "project.json"), "utf8")
      return JSON.parse(content) as ProjectMetadata
    } catch {
      return null
    }
  }
}
