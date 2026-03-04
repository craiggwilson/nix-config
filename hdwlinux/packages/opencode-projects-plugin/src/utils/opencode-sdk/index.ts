/**
 * OpenCode SDK type definitions
 *
 * Types for interacting with the OpenCode SDK client API.
 */

import type { ToolContext, PluginInput } from "@opencode-ai/plugin"

/**
 * BunShell type extracted from PluginInput
 */
export type BunShell = PluginInput["$"]

// ============================================================================
// Session Event Types
// ============================================================================

/**
 * Session status - represents the current activity state of a session
 */
export type SessionStatus =
  | { type: "idle" }
  | { type: "busy" }
  | { type: "retry"; attempt: number; message: string; next: number }

/**
 * Event fired when a session's status changes
 */
export type EventSessionStatus = {
  type: "session.status"
  properties: {
    sessionID: string
    status: SessionStatus
  }
}

/**
 * Event fired when a session becomes idle (no active processing)
 */
export type EventSessionIdle = {
  type: "session.idle"
  properties: {
    sessionID: string
  }
}

/**
 * Event fired when a session is compacted (conversation history summarized)
 */
export type EventSessionCompacted = {
  type: "session.compacted"
  properties: {
    sessionID: string
  }
}

/**
 * Event fired when a new session is created
 */
export type EventSessionCreated = {
  type: "session.created"
  properties: {
    info: Session
  }
}

/**
 * Event fired when a session is updated
 */
export type EventSessionUpdated = {
  type: "session.updated"
  properties: {
    info: Session
  }
}

/**
 * Event fired when a session is deleted (on app exit or new session start)
 */
export type EventSessionDeleted = {
  type: "session.deleted"
  properties: {
    info: Session
  }
}

/**
 * Event fired when a session encounters an error
 */
export type EventSessionError = {
  type: "session.error"
  properties: {
    sessionID?: string
    error?: unknown
  }
}

/**
 * Union of all known event types.
 * Used for type-safe event handling in the plugin event handler.
 */
export type Event =
  | EventSessionStatus
  | EventSessionIdle
  | EventSessionCompacted
  | EventSessionCreated
  | EventSessionUpdated
  | EventSessionDeleted
  | EventSessionError

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
    }) => Promise<{ data?: MessageInfo }>
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
