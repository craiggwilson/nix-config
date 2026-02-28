/**
 * Zod schemas for runtime configuration validation
 */

import { z } from "zod"
import type { Result } from "../utils/result/index.js"

/**
 * Hardcoded paths - these are implementation details and should not be configurable
 */
export const BEADS_PATH = ".beads" as const
export const PROJECTS_PATH = ".projects" as const

/**
 * Default timeout for background delegations (15 minutes)
 */
export const DEFAULT_DELEGATION_TIMEOUT_MS = 15 * 60 * 1000

/**
 * Default timeout for small model queries (30 seconds)
 */
export const DEFAULT_SMALL_MODEL_TIMEOUT_MS = 30000

/**
 * Default number of discussion rounds for teams
 */
export const DEFAULT_TEAM_DISCUSSION_ROUNDS = 2

/**
 * Default timeout per discussion round (5 minutes)
 */
export const DEFAULT_TEAM_DISCUSSION_ROUND_TIMEOUT_MS = 5 * 60 * 1000

/**
 * Default maximum team size
 */
export const DEFAULT_TEAM_MAX_SIZE = 5

/**
 * Default retry failed members setting
 */
export const DEFAULT_TEAM_RETRY_FAILED_MEMBERS = true

/**
 * Schema for project-specific overrides
 */
export const ProjectOverridesSchema = z.object({
  storage: z.enum(["local", "global"]).optional(),
  workspaces: z.array(z.string()).optional(),
})

/**
 * Schema for worktree settings
 */
export const WorktreeSettingsSchema = z.object({
  autoCleanup: z.boolean().default(true),
  basePath: z.string().optional(),
})

/**
 * Schema for delegation settings
 */
export const DelegationSettingsSchema = z.object({
  timeoutMs: z.number().int().positive().default(DEFAULT_DELEGATION_TIMEOUT_MS),
  smallModelTimeoutMs: z.number().int().positive().default(DEFAULT_SMALL_MODEL_TIMEOUT_MS),
})

/**
 * Schema for team settings
 */
export const TeamSettingsSchema = z.object({
  discussionRounds: z.number().int().min(0).default(DEFAULT_TEAM_DISCUSSION_ROUNDS),
  discussionRoundTimeoutMs: z.number().int().positive().default(DEFAULT_TEAM_DISCUSSION_ROUND_TIMEOUT_MS),
  maxTeamSize: z.number().int().positive().default(DEFAULT_TEAM_MAX_SIZE),
  retryFailedMembers: z.boolean().default(DEFAULT_TEAM_RETRY_FAILED_MEMBERS),
})

/**
 * Schema for default settings
 */
export const DefaultsSchema = z.object({
  storage: z.enum(["local", "global"]).default("global"),
  vcs: z.enum(["auto", "git", "jj"]).default("auto"),
})

/**
 * Main configuration schema
 */
export const ProjectConfigSchema = z.object({
  version: z.string(),
  defaults: DefaultsSchema.optional().default({ storage: "global", vcs: "auto" }),
  projects: z.record(z.string(), ProjectOverridesSchema).optional().default({}),
  worktrees: WorktreeSettingsSchema.optional().default({ autoCleanup: true }),
  delegation: DelegationSettingsSchema.optional().default({
    timeoutMs: DEFAULT_DELEGATION_TIMEOUT_MS,
    smallModelTimeoutMs: DEFAULT_SMALL_MODEL_TIMEOUT_MS,
  }),
  teams: TeamSettingsSchema.optional().default({
    discussionRounds: DEFAULT_TEAM_DISCUSSION_ROUNDS,
    discussionRoundTimeoutMs: DEFAULT_TEAM_DISCUSSION_ROUND_TIMEOUT_MS,
    maxTeamSize: DEFAULT_TEAM_MAX_SIZE,
    retryFailedMembers: DEFAULT_TEAM_RETRY_FAILED_MEMBERS,
  }),
})

/**
 * Infer TypeScript types from schemas
 */
export type ProjectConfig = z.infer<typeof ProjectConfigSchema>
export type ProjectOverrides = z.infer<typeof ProjectOverridesSchema>
export type WorktreeSettings = z.infer<typeof WorktreeSettingsSchema>
export type DelegationSettings = z.infer<typeof DelegationSettingsSchema>
export type TeamSettings = z.infer<typeof TeamSettingsSchema>
export type Defaults = z.infer<typeof DefaultsSchema>

/**
 * Configuration validation error
 */
export class ConfigValidationError extends Error {
  constructor(
    message: string,
    public readonly issues: z.ZodIssue[]
  ) {
    super(message)
    this.name = "ConfigValidationError"
  }
}

/**
 * Parse and validate configuration from unknown data
 */
export function parseConfig(data: unknown): Result<ProjectConfig, ConfigValidationError> {
  const result = ProjectConfigSchema.safeParse(data)

  if (!result.success) {
    const message = `Configuration validation failed:\n${result.error.issues
      .map((issue) => `  - ${issue.path.join(".")}: ${issue.message}`)
      .join("\n")}`

    return {
      ok: false,
      error: new ConfigValidationError(message, result.error.issues),
    }
  }

  return { ok: true, value: result.data }
}

/**
 * Default configuration
 */
export const DEFAULT_CONFIG: ProjectConfig = {
  version: "0.9.0",
  defaults: {
    storage: "global",
    vcs: "auto",
  },
  projects: {},
  worktrees: {
    autoCleanup: true,
  },
  delegation: {
    timeoutMs: DEFAULT_DELEGATION_TIMEOUT_MS,
    smallModelTimeoutMs: DEFAULT_SMALL_MODEL_TIMEOUT_MS,
  },
  teams: {
    discussionRounds: DEFAULT_TEAM_DISCUSSION_ROUNDS,
    discussionRoundTimeoutMs: DEFAULT_TEAM_DISCUSSION_ROUND_TIMEOUT_MS,
    maxTeamSize: DEFAULT_TEAM_MAX_SIZE,
    retryFailedMembers: DEFAULT_TEAM_RETRY_FAILED_MEMBERS,
  },
}
