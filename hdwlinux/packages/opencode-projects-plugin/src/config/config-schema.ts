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
 * Schema for fixed-round discussion strategy settings
 */
export const FixedRoundDiscussionSettingsSchema = z.object({
  rounds: z.number().int().positive().default(2),
  roundTimeoutMs: z.number().int().positive().default(5 * 60 * 1000),
})

/**
 * Schema for convergence discussion strategy settings
 */
export const ConvergenceDiscussionSettingsSchema = z.object({
  maxRounds: z.number().int().positive().default(10),
  roundTimeoutMs: z.number().int().positive().default(5 * 60 * 1000),
})

/**
 * Schema for realtime discussion strategy settings
 */
export const RealtimeDiscussionSettingsSchema = z.object({
  /** Polling interval for checking inbox (milliseconds) */
  pollIntervalMs: z.number().int().positive().default(1000),
  /** Maximum time to wait for all agents to signal done (milliseconds) */
  maxWaitTimeMs: z.number().int().positive().default(30 * 60 * 1000),
  /** Maximum time to wait for each agent's response per prompt (milliseconds) */
  promptTimeoutMs: z.number().int().positive().default(5 * 60 * 1000),
})

/**
 * Schema for team discussion settings, keyed by strategy type
 */
export const TeamDiscussionsSchema = z.object({
  default: z.enum(["fixedRound", "dynamicRound", "realtime"]).default("fixedRound"),
  fixedRound: FixedRoundDiscussionSettingsSchema.default(FixedRoundDiscussionSettingsSchema.parse({})),
  dynamicRound: ConvergenceDiscussionSettingsSchema.default(ConvergenceDiscussionSettingsSchema.parse({})),
  realtime: RealtimeDiscussionSettingsSchema.default(RealtimeDiscussionSettingsSchema.parse({})),
})

/**
 * Schema for team settings
 */
export const TeamSettingsSchema = z.object({
  maxTeamSize: z.number().int().positive().default(DEFAULT_TEAM_MAX_SIZE),
  retryFailedMembers: z.boolean().default(DEFAULT_TEAM_RETRY_FAILED_MEMBERS),
})

/**
 * Schema for default settings
 */
export const DefaultsSchema = z.object({
  storage: z.enum(["local", "global"]).default("local"),
  vcs: z.enum(["auto", "git", "jj"]).default("auto"),
})

/**
 * Main configuration schema
 */
export const ProjectConfigSchema = z.object({
  version: z.string().default("0.9.0"),
  defaults: DefaultsSchema.default(DefaultsSchema.parse({})),
  projects: z.record(z.string(), ProjectOverridesSchema).default({}),
  worktrees: WorktreeSettingsSchema.default(WorktreeSettingsSchema.parse({})),
  delegation: DelegationSettingsSchema.default(DelegationSettingsSchema.parse({})),
  teamDiscussions: TeamDiscussionsSchema.default(TeamDiscussionsSchema.parse({})),
  teams: TeamSettingsSchema.default(TeamSettingsSchema.parse({})),
})

/**
 * Infer TypeScript types from schemas
 */
export type ProjectConfig = z.infer<typeof ProjectConfigSchema>
export type ProjectOverrides = z.infer<typeof ProjectOverridesSchema>
export type WorktreeSettings = z.infer<typeof WorktreeSettingsSchema>
export type DelegationSettings = z.infer<typeof DelegationSettingsSchema>
export type FixedRoundDiscussionSettings = z.infer<typeof FixedRoundDiscussionSettingsSchema>
export type ConvergenceDiscussionSettings = z.infer<typeof ConvergenceDiscussionSettingsSchema>
export type RealtimeDiscussionSettings = z.infer<typeof RealtimeDiscussionSettingsSchema>
export type TeamDiscussions = z.infer<typeof TeamDiscussionsSchema>
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
 * Generate the default configuration by parsing an empty object through the schema.
 * All defaults are defined in the schema itself.
 */
export function defaultConfig(): ProjectConfig {
  return ProjectConfigSchema.parse({})
}
