/**
 * Configuration management for opencode-projects plugin
 */

import * as fs from "node:fs/promises"
import * as path from "node:path"
import * as os from "node:os"

import type { ProjectConfig, ProjectOverrides } from "./types.js"

const CONFIG_FILENAME = "opencode-projects.json"

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

      // Merge with defaults
      const config: ProjectConfig = {
        ...DEFAULT_CONFIG,
        ...loaded,
        defaults: { ...DEFAULT_CONFIG.defaults, ...loaded.defaults },
        agents: { ...DEFAULT_CONFIG.agents, ...loaded.agents },
        worktrees: { ...DEFAULT_CONFIG.worktrees, ...loaded.worktrees },
      }

      return new ConfigManager(config)
    } catch {
      // Config doesn't exist or is invalid, use defaults
      return new ConfigManager({ ...DEFAULT_CONFIG })
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
