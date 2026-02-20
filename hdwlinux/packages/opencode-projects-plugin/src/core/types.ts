/**
 * Shared type definitions for opencode-projects plugin
 */

import type { ToolContext, PluginInput } from "@opencode-ai/plugin"

/**
 * BunShell type extracted from PluginInput
 */
export type BunShell = PluginInput["$"]

/**
 * OpenCode SDK client type (simplified for our needs)
 */
export interface OpencodeClient {
  app: {
    log: (args: {
      body: { service: string; level: string; message: string; extra?: Record<string, unknown> }
    }) => Promise<unknown>
    agents: (args: Record<string, never>) => Promise<{ data?: Agent[] }>
  }
  session: {
    create: (args: { body: { title?: string; parentID?: string; agent?: string } }) => Promise<{ data?: Session }>
    get: (args: { path: { id: string } }) => Promise<{ data?: Session }>
    prompt: (args: {
      path: { id: string }
      body: {
        agent?: string
        parts: Part[]
        noReply?: boolean
        tools?: Record<string, boolean>
      }
    }) => Promise<{ data?: Message }>
    messages: (args: { path: { id: string } }) => Promise<{ data?: MessageItem[] }>
    delete: (args: { path: { id: string } }) => Promise<unknown>
  }
  config: {
    get: () => Promise<{ data?: PluginConfig }>
  }
}

/**
 * Agent configuration from OpenCode
 */
export interface Agent {
  /** Unique agent name/identifier */
  name: string
  /** Human-readable description of the agent's capabilities */
  description?: string
  /** Agent mode (e.g., "coder", "researcher") */
  mode?: string
}

/**
 * OpenCode session representing a conversation context
 */
export interface Session {
  /** Unique session identifier */
  id: string
  /** Human-readable session title */
  title?: string
  /** Parent session ID for nested sessions */
  parentID?: string
}

/**
 * Message part representing content in a conversation
 */
export interface Part {
  /** Content type */
  type: "text" | "image" | "file"
  /** Text content (for text type) */
  text?: string
}

/**
 * Message error information
 */
export interface MessageError {
  /** Error name/type */
  name: string
  /** Error message */
  message?: string
}

/**
 * Message metadata in a conversation
 */
export interface MessageInfo {
  /** Unique message identifier */
  id: string
  /** Message author role */
  role: "user" | "assistant"
  /** Session this message belongs to */
  sessionID: string
  /** Error information if the message was aborted or failed */
  error?: MessageError
}

/**
 * Message in a conversation (alias for backward compatibility)
 */
export type Message = MessageInfo

/**
 * Message item containing metadata and content parts
 */
export interface MessageItem {
  /** Message metadata */
  info: MessageInfo
  /** Content parts of the message */
  parts: Part[]
}

/**
 * OpenCode plugin configuration
 */
export interface PluginConfig {
  /** Small model to use for quick queries */
  small_model?: string
  /** Agent-specific configurations */
  agent?: Record<string, AgentConfig>
}

/**
 * Agent-specific configuration
 */
export interface AgentConfig {
  /** Permission settings for tools */
  permission?: Record<string, PermissionEntry>
}

/**
 * Permission entry for tool access control
 */
export type PermissionEntry = "ask" | "allow" | "deny" | Record<string, "ask" | "allow" | "deny">

/**
 * Logger interface
 */
export interface Logger {
  debug: (msg: string) => Promise<void>
  info: (msg: string) => Promise<void>
  warn: (msg: string) => Promise<void>
  error: (msg: string) => Promise<void>
}

/**
 * Tool context - re-export from plugin package
 */
export type ProjectToolContext = ToolContext

/**
 * Project configuration
 */
export interface ProjectConfig {
  version: string
  defaults: {
    storage: "local" | "global"
    beadsPath: string
    projectsPath: string
    vcs: "auto" | "git" | "jj"
  }
  projects: Record<string, ProjectOverrides>
  agents: {
    plannerModel?: string
    researcherModel?: string
  }
  worktrees: {
    autoCleanup: boolean
    basePath?: string
  }
  delegation?: {
    /** Timeout for background delegations in milliseconds (default: 15 minutes) */
    timeoutMs?: number
    /** Timeout for small model queries in milliseconds (default: 30 seconds) */
    smallModelTimeoutMs?: number
  }
}

/**
 * Per-project configuration overrides
 */
export interface ProjectOverrides {
  /** Storage location override */
  storage?: "local" | "global"
  /** Associated workspaces */
  workspaces?: string[]
  /** Custom beads path for this project */
  beadsPath?: string
}

/**
 * Project metadata
 */
export interface Project {
  id: string
  name: string
  description?: string
  storage: "local" | "global"
  workspace?: string
  beadsPath: string
  projectsPath: string
  createdAt: string
  status: "active" | "completed" | "archived"
}

/**
 * Beads issue
 */
export interface BeadsIssue {
  id: string
  title: string
  description?: string
  status: "open" | "in_progress" | "closed"
  priority?: number
  assignee?: string
  parent?: string
  blockedBy?: string[]
  labels?: string[]
  createdAt?: string
  updatedAt?: string
}

/**
 * Project status summary
 */
export interface ProjectStatus {
  total: number
  completed: number
  inProgress: number
  blocked: number
  blockers: Array<{
    issueId: string
    title: string
    blockedBy: string[]
  }>
}

/**
 * Focus state
 */
export interface FocusState {
  projectId: string
  issueId?: string
}

/**
 * VCS type
 */
export type VCSType = "git" | "jj"

/**
 * Worktree info
 */
export interface WorktreeInfo {
  path: string
  branch: string
  issueId: string
  vcs: VCSType
  status: "active" | "merged" | "abandoned"
}

/**
 * Dependencies provided to tool implementations.
 *
 * These dependencies are injected by the plugin during initialization
 * and provide access to core managers and utilities.
 */
export interface ToolDeps {
  /** OpenCode SDK client for API calls */
  client: OpencodeClient
  /** Project manager for project/issue operations */
  projectManager: ProjectManager
  /** Issue storage backend (beads or in-memory) */
  issueStorage: IssueStorage
  /** Logger for debug/info/warn/error messages */
  log: Logger
  /** Bun shell for executing commands */
  $: BunShell
  /** Delegation manager for background agent work (optional) */
  delegationManager?: DelegationManager
}

/**
 * Planning phase
 */
export type PlanningPhase = "discovery" | "synthesis" | "breakdown" | "complete"

/**
 * Planning decision
 */
export interface PlanningDecision {
  decision: string
  rationale: string
}

/**
 * Accumulated understanding from planning
 */
export interface PlanningUnderstanding {
  problem?: string
  goals?: string[]
  stakeholders?: string[]
  timeline?: string
  constraints?: string[]
  technicalContext?: string
  risks?: string[]
  decisions?: PlanningDecision[]
}

/**
 * Planning state persisted to .projects/<id>/planning.json
 */
export interface PlanningState {
  phase: PlanningPhase
  startedAt: string
  lastUpdatedAt: string
  understanding: PlanningUnderstanding
  openQuestions: string[]
  completedPhases: PlanningPhase[]
}

// Forward declarations for manager types
export type ConfigManager = import("./config-manager.js").ConfigManager
export type FocusManager = import("./focus-manager.js").FocusManager
export type ProjectManager = import("./project-manager.js").ProjectManager
export type IssueStorage = import("../storage/issue-storage.js").IssueStorage
export type DelegationManager = import("../execution/delegation-manager.js").DelegationManager
