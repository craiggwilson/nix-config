/**
 * Configuration management for opencode-projects plugin
 */

import * as fs from "node:fs/promises"
import * as path from "node:path"
import * as os from "node:os"

import {
  type ProjectConfig,
  type ProjectOverrides,
  type Result,
  DEFAULT_CONFIG,
  BEADS_PATH,
  PROJECTS_PATH,
  parseConfig,
  ConfigValidationError,
} from "./config-schema.js"

const CONFIG_FILENAME = "opencode-projects.json"

/**
 * Get XDG config directory
 */
function getConfigDir(): string {
  const baseDir = process.env.XDG_CONFIG_HOME || path.join(os.homedir(), ".config")
  return path.join(baseDir, "opencode")
}

/**
 * Get XDG data directory
 */
export function getDataDir(): string {
  const baseDir = process.env.XDG_DATA_HOME || path.join(os.homedir(), ".local", "share")
  return path.join(baseDir, "opencode")
}

/**
 * Configuration loading error
 */
export class ConfigLoadError extends Error {
  constructor(
    message: string,
    public readonly cause?: unknown
  ) {
    super(message)
    this.name = "ConfigLoadError"
  }
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
   * Load configuration from disk with validation
   */
  static async load(): Promise<Result<ConfigManager, ConfigLoadError>> {
    const configPath = path.join(getConfigDir(), CONFIG_FILENAME)

    try {
      const content = await fs.readFile(configPath, "utf8")
      const parsed = JSON.parse(content)

      const validationResult = parseConfig(parsed)

      if (!validationResult.ok) {
        console.warn(validationResult.error.message)
        console.warn("Using default configuration")
        return { ok: true, value: new ConfigManager({ ...DEFAULT_CONFIG }) }
      }

      const config = mergeWithDefaults(validationResult.value)
      return { ok: true, value: new ConfigManager(config) }
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code === "ENOENT") {
        return { ok: true, value: new ConfigManager({ ...DEFAULT_CONFIG }) }
      }

      return {
        ok: false,
        error: new ConfigLoadError("Failed to load configuration", error),
      }
    }
  }

  /**
   * Load configuration or throw on error
   */
  static async loadOrThrow(): Promise<ConfigManager> {
    const result = await ConfigManager.load()
    if (!result.ok) {
      throw result.error
    }
    return result.value
  }

  /**
   * Save configuration to disk
   */
  async save(): Promise<void> {
    const configDir = getConfigDir()
    const configPath = path.join(configDir, CONFIG_FILENAME)
    const tempPath = `${configPath}.tmp.${process.pid}`

    await fs.mkdir(configDir, { recursive: true })
    await fs.writeFile(tempPath, JSON.stringify(this.config, null, 2), "utf8")
    await fs.rename(tempPath, configPath)
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
    return this.config.delegation.timeoutMs
  }

  /**
   * Get small model timeout in milliseconds
   */
  getSmallModelTimeoutMs(): number {
    return this.config.delegation.smallModelTimeoutMs
  }

  /**
   * Get team discussion rounds (0 = disabled)
   */
  getTeamDiscussionRounds(): number {
    return this.config.teams.discussionRounds
  }

  /**
   * Get team discussion round timeout in milliseconds
   */
  getTeamDiscussionRoundTimeoutMs(): number {
    return this.config.teams.discussionRoundTimeoutMs
  }

  /**
   * Get maximum team size
   */
  getTeamMaxSize(): number {
    return this.config.teams.maxTeamSize
  }

  /**
   * Get whether to retry failed team members
   */
  getTeamRetryFailedMembers(): boolean {
    return this.config.teams.retryFailedMembers
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
    return path.join(repoRoot, PROJECTS_PATH)
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
    return path.join(projectDir, BEADS_PATH)
  }
}

/**
 * Merge loaded configuration with defaults using explicit field-by-field merging
 */
function mergeWithDefaults(loaded: ProjectConfig): ProjectConfig {
  return {
    version: loaded.version,
    defaults: {
      storage: loaded.defaults.storage,
      vcs: loaded.defaults.vcs,
    },
    projects: loaded.projects,
    worktrees: {
      autoCleanup: loaded.worktrees.autoCleanup,
      basePath: loaded.worktrees.basePath,
    },
    delegation: {
      timeoutMs: loaded.delegation.timeoutMs,
      smallModelTimeoutMs: loaded.delegation.smallModelTimeoutMs,
    },
    teams: {
      discussionRounds: loaded.teams.discussionRounds,
      discussionRoundTimeoutMs: loaded.teams.discussionRoundTimeoutMs,
      maxTeamSize: loaded.teams.maxTeamSize,
      retryFailedMembers: loaded.teams.retryFailedMembers,
    },
  }
}
