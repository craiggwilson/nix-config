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
import type { Logger, OpencodeClient } from "./types.js"
import {
  InterviewManager,
  ArtifactManager,
  PlanningDelegator,
  type InterviewSession,
  type InterviewSummary,
  type ArtifactType,
  type ArtifactMetadata,
  type RoadmapContent,
  type ArchitectureContent,
  type RisksContent,
  type SuccessCriteriaContent,
  type PlanningPhase,
  type AgentInfo,
  type DelegationResult,
} from "../planning/index.js"

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
  private focus: FocusManager
  private log: Logger
  private repoRoot: string
  private client?: OpencodeClient
  private planningDelegator?: PlanningDelegator

  constructor(deps: ProjectManagerDeps) {
    this.config = deps.config
    this.issueStorage = deps.issueStorage
    this.focus = deps.focus
    this.log = deps.log
    this.repoRoot = deps.repoRoot
    this.client = deps.client

    if (this.client) {
      this.planningDelegator = new PlanningDelegator(this.client, this.log)
    }
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
   * Create an issue in a project
   */
  async createIssue(
    projectId: string,
    title: string,
    options?: CreateIssueOptions
  ): Promise<string | null> {
    const projectDir = await this.findProjectDir(projectId)
    if (!projectDir) return null

    return this.issueStorage.createIssue(projectDir, title, options)
  }

  /**
   * Get an issue by ID
   */
  async getIssue(projectId: string, issueId: string): Promise<Issue | null> {
    const projectDir = await this.findProjectDir(projectId)
    if (!projectDir) return null

    return this.issueStorage.getIssue(issueId, projectDir)
  }

  /**
   * List issues in a project
   */
  async listIssues(projectId: string): Promise<Issue[]> {
    const projectDir = await this.findProjectDir(projectId)
    if (!projectDir) return []

    return this.issueStorage.listIssues(projectDir)
  }

  /**
   * Get ready issues (no blockers)
   */
  async getReadyIssues(projectId: string): Promise<Issue[]> {
    const projectDir = await this.findProjectDir(projectId)
    if (!projectDir) return []

    return this.issueStorage.getReadyIssues(projectDir)
  }

  /**
   * Claim an issue
   */
  async claimIssue(projectId: string, issueId: string, assignee?: string): Promise<boolean> {
    const projectDir = await this.findProjectDir(projectId)
    if (!projectDir) return false

    const claimed = await this.issueStorage.claimIssue(issueId, projectDir, assignee)

    if (claimed) {

      this.focus.setIssueFocus(issueId)
    }

    return claimed
  }

  /**
   * Update an issue
   */
  async updateIssue(
    projectId: string,
    issueId: string,
    options: {
      status?: "open" | "in_progress" | "closed"
      assignee?: string
      priority?: number
      description?: string
      labels?: string[]
      blockedBy?: string[]
    }
  ): Promise<boolean> {
    const projectDir = await this.findProjectDir(projectId)
    if (!projectDir) return false

    const updated = await this.issueStorage.updateIssue(issueId, projectDir, options)
    if (updated && options.status === "closed") {
      if (this.focus.getIssueId() === issueId) {
        this.focus.clearIssueFocus()
      }
    }

    return updated
  }

  /**
   * Add a comment to an issue
   */
  async addIssueComment(projectId: string, issueId: string, comment: string): Promise<boolean> {
    const projectDir = await this.findProjectDir(projectId)
    if (!projectDir) return false

    return this.issueStorage.addComment(issueId, projectDir, comment)
  }

  /**
   * Add a completion comment when closing an issue
   */
  async addCompletionComment(
    projectId: string,
    issueId: string,
    options: {
      summary?: string
      artifacts?: string[]
      mergeCommit?: string
    }
  ): Promise<boolean> {
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

    return this.addIssueComment(projectId, issueId, lines.join("\n"))
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

  /**
   * Get an InterviewManager for a project
   */
  async getInterviewManager(projectId: string): Promise<InterviewManager | null> {
    const projectDir = await this.findProjectDir(projectId)
    if (!projectDir) return null

    return new InterviewManager(projectDir)
  }

  /**
   * Start a new interview session for a project
   */
  async startInterview(
    projectId: string,
    phase: "discovery" | "refinement" | "breakdown",
    topic?: string
  ): Promise<InterviewSession | null> {
    const manager = await this.getInterviewManager(projectId)
    if (!manager) return null

    return manager.startSession(projectId, phase, topic)
  }

  /**
   * Resume an existing interview session
   */
  async resumeInterview(projectId: string, sessionId: string): Promise<InterviewSession | null> {
    const manager = await this.getInterviewManager(projectId)
    if (!manager) return null

    return manager.resumeSession(sessionId)
  }

  /**
   * Get the most recent active interview for a project
   */
  async getActiveInterview(projectId: string): Promise<InterviewSession | null> {
    const manager = await this.getInterviewManager(projectId)
    if (!manager) return null

    return manager.getMostRecentActiveSession()
  }

  /**
   * List all interviews for a project
   */
  async listInterviews(projectId: string): Promise<InterviewSummary[]> {
    const manager = await this.getInterviewManager(projectId)
    if (!manager) return []

    return manager.listSessions()
  }

  /**
   * Add an exchange to the current interview
   */
  async addInterviewExchange(
    projectId: string,
    role: "assistant" | "user",
    content: string
  ): Promise<boolean> {
    const manager = await this.getInterviewManager(projectId)
    if (!manager) return false
    const session = await manager.getMostRecentActiveSession()
    if (!session) return false

    await manager.resumeSession(session.id)
    await manager.addExchange(role, content)
    return true
  }

  /**
   * Complete the current interview
   */
  async completeInterview(projectId: string): Promise<boolean> {
    const manager = await this.getInterviewManager(projectId)
    if (!manager) return false

    const session = await manager.getMostRecentActiveSession()
    if (!session) return false

    await manager.resumeSession(session.id)
    await manager.completeSession()
    return true
  }

  /**
   * Get interview context for prompt injection
   */
  async getInterviewContext(projectId: string): Promise<string | null> {
    const manager = await this.getInterviewManager(projectId)
    if (!manager) return null

    const session = await manager.getMostRecentActiveSession()
    if (!session) return null

    await manager.resumeSession(session.id)
    return manager.getInterviewContext()
  }

  /**
   * Get an ArtifactManager for a project
   */
  async getArtifactManager(projectId: string): Promise<ArtifactManager | null> {
    const projectDir = await this.findProjectDir(projectId)
    if (!projectDir) return null

    return new ArtifactManager(projectDir)
  }

  /**
   * List all artifacts for a project
   */
  async listArtifacts(projectId: string): Promise<ArtifactMetadata[]> {
    const manager = await this.getArtifactManager(projectId)
    if (!manager) return []

    return manager.listArtifacts()
  }

  /**
   * Check if an artifact exists
   */
  async artifactExists(projectId: string, type: ArtifactType): Promise<boolean> {
    const manager = await this.getArtifactManager(projectId)
    if (!manager) return false

    return manager.artifactExists(type)
  }

  /**
   * Read an artifact's content
   */
  async readArtifact(projectId: string, type: ArtifactType): Promise<string | null> {
    const manager = await this.getArtifactManager(projectId)
    if (!manager) return null

    return manager.readArtifact(type)
  }

  /**
   * Generate a roadmap artifact
   */
  async generateRoadmap(projectId: string, content: RoadmapContent): Promise<string | null> {
    const manager = await this.getArtifactManager(projectId)
    if (!manager) return null

    return manager.generateRoadmap(content)
  }

  /**
   * Generate an architecture artifact
   */
  async generateArchitecture(
    projectId: string,
    content: ArchitectureContent
  ): Promise<string | null> {
    const manager = await this.getArtifactManager(projectId)
    if (!manager) return null

    return manager.generateArchitecture(content)
  }

  /**
   * Generate a risks artifact
   */
  async generateRisks(projectId: string, content: RisksContent): Promise<string | null> {
    const manager = await this.getArtifactManager(projectId)
    if (!manager) return null

    return manager.generateRisks(content)
  }

  /**
   * Generate a success criteria artifact
   */
  async generateSuccessCriteria(
    projectId: string,
    content: SuccessCriteriaContent
  ): Promise<string | null> {
    const manager = await this.getArtifactManager(projectId)
    if (!manager) return null

    return manager.generateSuccessCriteria(content)
  }

  /**
   * Check if planning delegation is available
   */
  isDelegationAvailable(): boolean {
    return !!this.planningDelegator
  }

  /**
   * Discover available agents from the SDK
   */
  async discoverAgents(): Promise<AgentInfo[]> {
    if (!this.planningDelegator) return []
    return this.planningDelegator.listAgents()
  }

  /**
   * Find the best agent for a planning phase
   * Returns null if no suitable agent is found
   */
  async findAgentForPhase(phase: PlanningPhase): Promise<string | null> {
    if (!this.planningDelegator) return null
    return this.planningDelegator.findAgentForPhase(phase)
  }

  /**
   * Delegate planning work
   *
   * Discovers available agents and selects the best match for the phase.
   * Falls back to letting OpenCode decide if no suitable agent is found.
   */
  async delegatePlanning(
    projectId: string,
    prompt: string,
    options?: {
      context?: string
      phase?: PlanningPhase
      preferredAgent?: string
    }
  ): Promise<DelegationResult> {
    if (!this.planningDelegator) {
      return {
        success: false,
        error: "Planning delegation not available (no client configured)",
      }
    }

    return this.planningDelegator.delegate({
      prompt,
      context: options?.context,
      projectId,
      phase: options?.phase,
      preferredAgent: options?.preferredAgent,
    })
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
