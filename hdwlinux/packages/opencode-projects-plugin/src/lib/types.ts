/**
 * Shared type definitions for opencode-projects plugin
 */

import type { ToolContext } from "@opencode-ai/plugin"

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
    create: (args: { body: { title?: string; parentID?: string } }) => Promise<{ data?: Session }>
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

export interface Agent {
  name: string
  description?: string
  mode?: string
}

export interface Session {
  id: string
  title?: string
  parentID?: string
}

export interface Part {
  type: "text" | "image" | "file"
  text?: string
}

export interface Message {
  id: string
  role: "user" | "assistant"
  sessionID: string
}

export interface MessageItem {
  info: Message
  parts: Part[]
}

export interface PluginConfig {
  small_model?: string
  agent?: Record<string, AgentConfig>
}

export interface AgentConfig {
  permission?: Record<string, PermissionEntry>
}

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
 * Tool context with required fields
 */
export interface ProjectToolContext extends ToolContext {
  sessionID: string
  messageID: string
  agent: string
}

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
}

export interface ProjectOverrides {
  storage?: "local" | "global"
  workspaces?: string[]
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
 * Tool dependencies passed to tool creators
 */
export interface ToolDeps {
  client: OpencodeClient
  config: ConfigManager
  beads: BeadsClient
  focus: FocusManager
  repoRoot: string
  log: Logger
}

// Forward declarations for manager types
export type ConfigManager = import("./config.js").ConfigManager
export type BeadsClient = import("./beads.js").BeadsClient
export type FocusManager = import("./focus.js").FocusManager
