/**
 * ProjectManager - Core business logic for project operations
 *
 * This class encapsulates all project management operations and can be used
 * independently of the OpenCode plugin context (e.g., for SDK usage).
 */

import * as fs from "node:fs/promises"
import * as path from "node:path"
import * as crypto from "node:crypto"

import type {
  IssueStorage,
  Issue,
  CreateIssueOptions,
  UpdateIssueOptions,
  CompletionCommentOptions,
  ProjectStatus,
  IssueStorageError,
} from "../issues/index.js"
import { StorageOperationError } from "../issues/index.js"
import type { Result } from "../utils/result/index.js"
import type { FocusManager } from "./focus-manager.js"
import type { ConfigManager } from "../config/index.js"
import type { Logger, OpencodeClient, BunShell } from "../utils/opencode-sdk/index.js"
import type { VCSType } from "../vcs/index.js"
import { PlanningManager } from "../planning/index.js"
import type { PlanningState, PlanningPhase, PlanningUnderstanding } from "../planning/index.js"
import type { PlanningError } from "../utils/errors/index.js"
import { err, ok } from "../utils/result/index.js"
import type { TeamManager } from "../execution/index.js"
import { ArtifactRegistry } from "../artifacts/index.js"
import { SessionManager } from "../sessions/index.js"
import { ResearchManager } from "../research/index.js"
import { DecisionManager } from "../decisions/index.js"

/** Filename for project metadata */
const PROJECT_METADATA_FILE = "project.json"

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
  /** Override path for research artifacts */
  researchPath?: string
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
  /** Cached ArtifactRegistry instances per project */
  private artifactRegistries: Map<string, ArtifactRegistry> = new Map()
  /** Cached SessionManager instances per project */
  private sessionManagers: Map<string, SessionManager> = new Map()
  /** Cached ResearchManager instances per project */
  private researchManagers: Map<string, ResearchManager> = new Map()
  /** Cached DecisionManager instances per project */
  private decisionManagers: Map<string, DecisionManager> = new Map()

  constructor(
    private config: ConfigManager,
    private issueStorage: IssueStorage,
    private focus: FocusManager,
    private log: Logger,
    private repoRoot: string,
    private client?: OpencodeClient,
    private $?: BunShell,
    private teamManager?: TeamManager,
  ) {}

  /**
   * Set the team manager (for late binding)
   */
  setTeamManager(teamManager: TeamManager): void {
    this.teamManager = teamManager
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

    await fs.mkdir(projectDir, { recursive: true })

    const entries = await fs.readdir(projectDir)
    if (entries.length > 0) {
      throw new Error(`Project directory already exists at ${projectDir}`)
    }

    // Stealth mode configures global gitattributes/gitignore to hide beads files from git.
    // Only use it for local projects (inside a git repo). Global project dirs are not git
    // repos, so --stealth fails with "not a git repository".
    const initResult = await this.issueStorage.init(projectDir)

    if (!initResult.ok) {
      await this.log.warn("Failed to initialize issue storage")
    }
    let rootIssueId: string | null = null
    if (initResult.ok) {
      const createResult = await this.issueStorage.createIssue(projectDir, name, {
        priority: 0,
        description: description || `Root epic for ${name}`,
        labels: ["epic", type],
      })
      rootIssueId = createResult.ok ? createResult.value : null
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
      path.join(projectDir, PROJECT_METADATA_FILE),
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

    const issueStatusResult = await this.issueStorage.getProjectStatus(projectDir)
    const issueStatus = issueStatusResult.ok ? issueStatusResult.value : null

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
      path.join(projectDir, PROJECT_METADATA_FILE),
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
  ): Promise<Result<string, IssueStorageError>> {
    const projectDir = await this.findProjectDir(projectId)
    if (!projectDir) {
      return {
        ok: false,
        error: new StorageOperationError(
          `Project '${projectId}' not found`,
          "Use project-list to see available projects"
        ),
      }
    }

    // Default parent to root issue if not specified
    let effectiveOptions = options
    if (!options?.parent) {
      const metadata = await this.loadProjectMetadata(projectDir)
      if (metadata?.rootIssue) {
        effectiveOptions = { ...options, parent: metadata.rootIssue }
      }
    }

    return this.issueStorage.createIssue(projectDir, title, effectiveOptions)
  }

  /**
   * Get an issue by ID
   */
  async getIssue(projectId: string, issueId: string): Promise<Issue | null> {
    const projectDir = await this.findProjectDir(projectId)
    if (!projectDir) return null

    const result = await this.issueStorage.getIssue(issueId, projectDir)
    return result.ok ? result.value : null
  }

  /**
   * List issues in a project
   */
  async listIssues(projectId: string): Promise<Issue[]> {
    const projectDir = await this.findProjectDir(projectId)
    if (!projectDir) return []

    const result = await this.issueStorage.listIssues(projectDir)
    return result.ok ? result.value : []
  }

  /**
   * Get ready issues (no blockers)
   */
  async getReadyIssues(projectId: string): Promise<Issue[]> {
    const projectDir = await this.findProjectDir(projectId)
    if (!projectDir) return []

    const result = await this.issueStorage.getReadyIssues(projectDir)
    return result.ok ? result.value : []
  }

  /**
   * Claim an issue (sets status to in_progress)
   */
  async claimIssue(projectId: string, issueId: string, assignee?: string): Promise<boolean> {
    const projectDir = await this.findProjectDir(projectId)
    if (!projectDir) return false

    const result = await this.issueStorage.claimIssue(issueId, projectDir, assignee)

    if (result.ok) {
      await this.log.debug(`Claimed issue ${issueId}`)
    }

    return result.ok
  }

  /**
   * Claim an issue by project directory (for internal use when projectDir is already known)
   */
  async claimIssueByDir(projectDir: string, issueId: string, assignee?: string): Promise<boolean> {
    const result = await this.issueStorage.claimIssue(issueId, projectDir, assignee)

    if (result.ok) {
      await this.log.debug(`Claimed issue ${issueId}`)
    }

    return result.ok
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

    const result = await this.issueStorage.updateIssue(issueId, projectDir, options)

    return result.ok
  }

  /**
   * Add a comment to an issue
   */
  async addIssueComment(projectId: string, issueId: string, comment: string): Promise<boolean> {
    const projectDir = await this.findProjectDir(projectId)
    if (!projectDir) return false

    const result = await this.issueStorage.addComment(issueId, projectDir, comment)
    return result.ok
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

    const lines: string[] = []

    lines.push("[COMPLETED]")

    if (options.summary) {
      lines.push("")
      lines.push(options.summary)
    }

    if (options.mergeCommit) {
      lines.push("")
      lines.push(`Merge commit: ${options.mergeCommit}`)
    }

    if (options.artifacts && options.artifacts.length > 0) {
      lines.push("")
      lines.push("Artifacts:")
      for (const artifact of options.artifacts) {
        lines.push(`- ${artifact}`)
      }
    }

    const result = await this.issueStorage.addComment(issueId, projectDir, lines.join("\n"))
    return result.ok
  }

  /**
   * Set delegation metadata on an issue (by project directory)
   */
  async setDelegationMetadataByDir(
    projectDir: string,
    issueId: string,
    metadata: { delegationId: string; delegationStatus: string }
  ): Promise<boolean> {
    const result = await this.issueStorage.setDelegationMetadata(issueId, projectDir, metadata)
    return result.ok
  }

  /**
   * Get the currently focused project ID
   */
  getFocusedProjectId(): string | null {
    return this.focus.getProjectId()
  }

  /**
   * Set focus to a project
   */
  setFocus(projectId: string): void {
    this.focus.setFocus(projectId)
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
   * Start or continue a planning session.
   * Returns an error if the project is not found or if the operation fails.
   */
  async startOrContinuePlanning(projectId: string): Promise<Result<PlanningState, PlanningError>> {
    const manager = await this.getPlanningManager(projectId)
    if (!manager) {
      return err({ type: "no_session" })
    }

    return manager.startOrContinue()
  }

  /**
   * Advance to the next planning phase.
   * Returns an error if the project is not found or if the operation fails.
   */
  async advancePlanningPhase(projectId: string): Promise<Result<PlanningState, PlanningError>> {
    const manager = await this.getPlanningManager(projectId)
    if (!manager) {
      return err({ type: "no_session" })
    }

    return manager.advancePhase()
  }

  /**
   * Jump to a specific planning phase.
   * Returns an error if the project is not found or if the operation fails.
   */
  async setPlanningPhase(projectId: string, phase: PlanningPhase): Promise<Result<PlanningState, PlanningError>> {
    const manager = await this.getPlanningManager(projectId)
    if (!manager) {
      return err({ type: "no_session" })
    }

    return manager.setPhase(phase)
  }

  /**
   * Update the planning understanding.
   * Returns an error if the project is not found or if the operation fails.
   */
  async updatePlanningUnderstanding(
    projectId: string,
    updates: Partial<PlanningUnderstanding>
  ): Promise<Result<PlanningState, PlanningError>> {
    const manager = await this.getPlanningManager(projectId)
    if (!manager) {
      return err({ type: "no_session" })
    }

    return manager.updateUnderstanding(updates)
  }

  /**
   * Update open questions.
   * Returns an error if the project is not found or if the operation fails.
   */
  async updateOpenQuestions(projectId: string, questions: string[]): Promise<Result<PlanningState, PlanningError>> {
    const manager = await this.getPlanningManager(projectId)
    if (!manager) {
      return err({ type: "no_session" })
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

  // ============================================================================
  // Manager Accessors (lazily created and cached per project)
  // ============================================================================

  /**
   * Get the ArtifactRegistry for a project.
   * Creates and caches the registry if it doesn't exist.
   */
  async getArtifactRegistry(projectId: string): Promise<ArtifactRegistry | null> {
    const projectDir = await this.getProjectDir(projectId)
    if (!projectDir) return null

    if (!this.artifactRegistries.has(projectId)) {
      const registry = new ArtifactRegistry(projectDir, this.log)
      await registry.load()
      this.artifactRegistries.set(projectId, registry)
    }

    return this.artifactRegistries.get(projectId) || null
  }

  /**
   * Get the SessionManager for a project.
   * Creates and caches the manager if it doesn't exist.
   */
  async getSessionManager(projectId: string): Promise<SessionManager | null> {
    const projectDir = await this.getProjectDir(projectId)
    if (!projectDir) return null

    if (!this.sessionManagers.has(projectId)) {
      const manager = new SessionManager(projectDir, this.log)
      await manager.load()
      this.sessionManagers.set(projectId, manager)
    }

    return this.sessionManagers.get(projectId) || null
  }

  /**
   * Get the ResearchManager for a project.
   * Creates and caches the manager if it doesn't exist.
   */
  async getResearchManager(projectId: string): Promise<ResearchManager | null> {
    const projectDir = await this.getProjectDir(projectId)
    if (!projectDir) return null

    const artifactRegistry = await this.getArtifactRegistry(projectId)
    if (!artifactRegistry) return null

    if (!this.researchManagers.has(projectId)) {
      const metadata = await this.getProjectMetadata(projectId)
      const researchPath = metadata?.researchPath

      const manager = new ResearchManager(projectDir, artifactRegistry, this.log, researchPath)
      await manager.load()
      this.researchManagers.set(projectId, manager)
    }

    return this.researchManagers.get(projectId) || null
  }

  /**
   * Get the DecisionManager for a project.
   * Creates and caches the manager if it doesn't exist.
   */
  async getDecisionManager(projectId: string): Promise<DecisionManager | null> {
    const projectDir = await this.getProjectDir(projectId)
    if (!projectDir) return null

    const artifactRegistry = await this.getArtifactRegistry(projectId)
    if (!artifactRegistry) return null

    if (!this.decisionManagers.has(projectId)) {
      const manager = new DecisionManager(projectDir, artifactRegistry, this.log)
      await manager.load()
      this.decisionManagers.set(projectId, manager)
    }

    return this.decisionManagers.get(projectId) || null
  }

  /**
   * Get project metadata by ID.
   * Convenience method that loads metadata from the project directory.
   */
  async getProjectMetadata(projectId: string): Promise<ProjectMetadata | null> {
    const projectDir = await this.findProjectDir(projectId)
    if (!projectDir) return null

    return this.loadProjectMetadata(projectDir)
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
  async findProjectDir(projectId: string): Promise<string | null> {
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
      const content = await fs.readFile(path.join(projectDir, PROJECT_METADATA_FILE), "utf8")
      const metadata = JSON.parse(content) as ProjectMetadata
      return metadata
    } catch {
      return null
    }
  }
}
