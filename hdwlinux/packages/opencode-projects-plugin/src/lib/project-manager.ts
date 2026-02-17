/**
 * ProjectManager - Core business logic for project operations
 *
 * This class encapsulates all project management operations and can be used
 * independently of the OpenCode plugin context (e.g., for SDK usage).
 */

import * as fs from "node:fs/promises"
import * as path from "node:path"
import * as crypto from "node:crypto"

import type { IssueStorage, Issue, CreateIssueOptions, ProjectStatus } from "./issue-storage.js"
import type { FocusManager } from "./focus.js"
import type { ConfigManager } from "./config.js"
import type { Logger } from "./types.js"

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

  constructor(deps: ProjectManagerDeps) {
    this.config = deps.config
    this.issueStorage = deps.issueStorage
    this.focus = deps.focus
    this.log = deps.log
    this.repoRoot = deps.repoRoot
  }

  /**
   * Create a new project
   */
  async createProject(options: CreateProjectOptions): Promise<CreateProjectResult> {
    const { name, type = "project", workspace, storage, description } = options

    await this.log.info(`Creating project: ${name}`)

    // Generate project ID
    const projectId = generateProjectId(name)

    // Determine workspace root
    const effectiveWorkspace = workspace || this.repoRoot

    // Determine storage location
    const effectiveStorage = storage || this.config.getDefaultStorage()

    // Get project directory
    const projectDir = this.config.resolveProjectDir(projectId, effectiveWorkspace, effectiveStorage)

    // Check if project already exists
    try {
      await fs.access(projectDir)
      throw new Error(`Project directory already exists at ${projectDir}`)
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code !== "ENOENT") {
        throw error
      }
      // Directory doesn't exist, good to proceed
    }

    // Create directory structure
    await fs.mkdir(projectDir, { recursive: true })
    await fs.mkdir(path.join(projectDir, "research"), { recursive: true })
    await fs.mkdir(path.join(projectDir, "interviews"), { recursive: true })
    await fs.mkdir(path.join(projectDir, "plans"), { recursive: true })

    // Initialize issue storage
    const storageInitialized = await this.issueStorage.init(projectDir, {
      stealth: effectiveStorage === "global",
    })

    if (!storageInitialized) {
      await this.log.warn("Failed to initialize issue storage")
    }

    // Create root epic
    let rootIssueId: string | null = null
    if (storageInitialized) {
      rootIssueId = await this.issueStorage.createIssue(projectDir, name, {
        priority: 0,
        description: description || `Root epic for ${name}`,
        labels: ["epic", type],
      })
    }

    // Create project metadata
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

    // Save project overrides to config
    this.config.setProjectOverrides(projectId, {
      storage: effectiveStorage,
      workspaces: [effectiveWorkspace],
    })
    await this.config.save()

    // Set focus to new project
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

    // Scan local projects
    if (scope === "local" || scope === "all") {
      const localDir = this.config.getLocalProjectsDir(this.repoRoot)
      const localProjects = await this.scanProjectsDir(localDir, "local")
      projects.push(...localProjects)
    }

    // Scan global projects
    if (scope === "global" || scope === "all") {
      const globalDir = this.config.getGlobalProjectsDir()
      const globalProjects = await this.scanProjectsDir(globalDir, "global")
      projects.push(...globalProjects)
    }

    // Filter by status
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

    // Update metadata
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

    // Clear focus if this project was focused
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
      // Set issue focus
      this.focus.setIssueFocus(issueId)
    }

    return claimed
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
