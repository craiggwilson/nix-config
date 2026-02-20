/**
 * Configuration management for opencode-projects plugin
 */

import * as fs from "node:fs/promises"
import * as path from "node:path"
import * as os from "node:os"

import type { ProjectConfig, ProjectOverrides } from "./types.js"

const CONFIG_FILENAME = "opencode-projects.json"

/** Default timeout for background delegations (15 minutes) */
const DEFAULT_DELEGATION_TIMEOUT_MS = 15 * 60 * 1000

/** Default timeout for small model queries (30 seconds) */
const DEFAULT_SMALL_MODEL_TIMEOUT_MS = 30000

/**
 * Validation error for configuration
 */
export interface ConfigValidationError {
  field: string
  message: string
  value?: unknown
}

/**
 * Validation result
 */
export interface ConfigValidationResult {
  valid: boolean
  errors: ConfigValidationError[]
  warnings: ConfigValidationError[]
}

/**
 * Default configuration
 */
const DEFAULT_CONFIG: ProjectConfig = {
  version: "1.0.0",
  defaults: {
    storage: "local",
    beadsPath: ".beads",
    projectsPath: ".projects",
    vcs: "auto",
  },
  projects: {},
  agents: {},
  worktrees: {
    autoCleanup: true,
  },
  delegation: {
    timeoutMs: DEFAULT_DELEGATION_TIMEOUT_MS,
    smallModelTimeoutMs: DEFAULT_SMALL_MODEL_TIMEOUT_MS,
  },
}

/**
 * Get XDG config directory
 */
function getConfigDir(): string {
  return process.env.XDG_CONFIG_HOME || path.join(os.homedir(), ".config", "opencode")
}

/**
 * Get XDG data directory
 */
export function getDataDir(): string {
  return process.env.XDG_DATA_HOME || path.join(os.homedir(), ".local", "share", "opencode")
}

/**
 * Configuration manager
 */
export class ConfigManager {
  private config: ProjectConfig

  private constructor(config: ProjectConfig) {
    this.config = config
  }

  /**
   * Load configuration from disk
   */
  static async load(): Promise<ConfigManager> {
    const configPath = path.join(getConfigDir(), CONFIG_FILENAME)

    try {
      const content = await fs.readFile(configPath, "utf8")
      const loaded = JSON.parse(content) as Partial<ProjectConfig>

      const config: ProjectConfig = {
        ...DEFAULT_CONFIG,
        ...loaded,
        defaults: { ...DEFAULT_CONFIG.defaults, ...loaded.defaults },
        agents: { ...DEFAULT_CONFIG.agents, ...loaded.agents },
        worktrees: { ...DEFAULT_CONFIG.worktrees, ...loaded.worktrees },
      }

      const manager = new ConfigManager(config)
      const validation = manager.validate()

      if (!validation.valid) {
        console.warn("Configuration validation errors:")
        for (const error of validation.errors) {
          console.warn(`  - ${error.field}: ${error.message}`)
        }
      }

      for (const warning of validation.warnings) {
        console.warn(`Config warning: ${warning.field}: ${warning.message}`)
      }

      return manager
    } catch {
      return new ConfigManager({ ...DEFAULT_CONFIG })
    }
  }

  /**
   * Validate the current configuration
   */
  validate(): ConfigValidationResult {
    const errors: ConfigValidationError[] = []
    const warnings: ConfigValidationError[] = []

    // Validate version
    if (!this.config.version) {
      errors.push({ field: "version", message: "Version is required" })
    }

    // Validate defaults.storage
    const validStorageValues = ["local", "global"]
    if (!validStorageValues.includes(this.config.defaults.storage)) {
      errors.push({
        field: "defaults.storage",
        message: `Must be one of: ${validStorageValues.join(", ")}`,
        value: this.config.defaults.storage,
      })
    }

    // Validate defaults.vcs
    const validVcsValues = ["auto", "git", "jj"]
    if (!validVcsValues.includes(this.config.defaults.vcs)) {
      errors.push({
        field: "defaults.vcs",
        message: `Must be one of: ${validVcsValues.join(", ")}`,
        value: this.config.defaults.vcs,
      })
    }

    // Validate paths don't contain dangerous characters
    const pathFields = ["defaults.beadsPath", "defaults.projectsPath"]
    for (const field of pathFields) {
      const value = field === "defaults.beadsPath"
        ? this.config.defaults.beadsPath
        : this.config.defaults.projectsPath

      if (value.includes("..")) {
        errors.push({
          field,
          message: "Path cannot contain '..'",
          value,
        })
      }
    }

    // Warn about unknown top-level fields
    const knownFields = ["version", "defaults", "projects", "agents", "worktrees", "delegation"]
    for (const key of Object.keys(this.config)) {
      if (!knownFields.includes(key)) {
        warnings.push({
          field: key,
          message: "Unknown configuration field (may be ignored)",
        })
      }
    }

    return {
      valid: errors.length === 0,
      errors,
      warnings,
    }
  }

  /**
   * Save configuration to disk
   */
  async save(): Promise<void> {
    const configDir = getConfigDir()
    const configPath = path.join(configDir, CONFIG_FILENAME)

    await fs.mkdir(configDir, { recursive: true })
    await fs.writeFile(configPath, JSON.stringify(this.config, null, 2), "utf8")
  }

  /**
   * Get a configuration value by key path
   */
  get<K extends keyof ProjectConfig>(key: K): ProjectConfig[K] {
    return this.config[key]
  }

  /**
   * Get default storage location
   */
  getDefaultStorage(): "local" | "global" {
    return this.config.defaults.storage
  }

  /**
   * Get default beads path
   */
  getDefaultBeadsPath(): string {
    return this.config.defaults.beadsPath
  }

  /**
   * Get default projects path
   */
  getDefaultProjectsPath(): string {
    return this.config.defaults.projectsPath
  }

  /**
   * Get default VCS setting
   */
  getDefaultVCS(): "auto" | "git" | "jj" {
    return this.config.defaults.vcs
  }

  /**
   * Get project-specific overrides
   */
  getProjectOverrides(projectId: string): ProjectOverrides | undefined {
    return this.config.projects[projectId]
  }

  /**
   * Set project-specific overrides
   */
  setProjectOverrides(projectId: string, overrides: ProjectOverrides): void {
    this.config.projects[projectId] = overrides
  }

  /**
   * Get worktree settings
   */
  getWorktreeSettings(): { autoCleanup: boolean; basePath?: string } {
    return this.config.worktrees
  }

  /**
   * Get delegation timeout in milliseconds
   */
  getDelegationTimeoutMs(): number {
    return this.config.delegation?.timeoutMs ?? DEFAULT_DELEGATION_TIMEOUT_MS
  }

  /**
   * Get small model timeout in milliseconds
   */
  getSmallModelTimeoutMs(): number {
    return this.config.delegation?.smallModelTimeoutMs ?? DEFAULT_SMALL_MODEL_TIMEOUT_MS
  }

  /**
   * Get global projects directory
   */
  getGlobalProjectsDir(): string {
    return path.join(getDataDir(), "projects")
  }

  /**
   * Get local projects directory for a repository
   */
  getLocalProjectsDir(repoRoot: string): string {
    return path.join(repoRoot, this.config.defaults.projectsPath)
  }

  /**
   * Resolve project directory based on storage setting
   */
  resolveProjectDir(projectId: string, repoRoot: string, storage?: "local" | "global"): string {
    const effectiveStorage = storage || this.getProjectOverrides(projectId)?.storage || this.getDefaultStorage()

    if (effectiveStorage === "global") {
      return path.join(this.getGlobalProjectsDir(), projectId)
    }

    return path.join(this.getLocalProjectsDir(repoRoot), projectId)
  }

  /**
   * Resolve beads directory for a project
   */
  resolveBeadsDir(projectId: string, repoRoot: string, storage?: "local" | "global"): string {
    const projectDir = this.resolveProjectDir(projectId, repoRoot, storage)
    const beadsPath = this.getProjectOverrides(projectId)?.beadsPath || this.getDefaultBeadsPath()

    return path.join(projectDir, beadsPath)
  }
}
