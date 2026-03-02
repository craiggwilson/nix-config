/**
 * Tool type definitions
 *
 * Provides type aliases for the @opencode-ai/plugin tool types to:
 * 1. Centralize imports from the plugin package
 * 2. Allow for future customization if needed
 * 3. Provide consistent naming across the codebase
 */

import type { ToolContext, ToolDefinition } from "@opencode-ai/plugin"

/**
 * Tool definition type from the plugin package.
 *
 * This is the return type of the `tool()` function from @opencode-ai/plugin.
 * Each tool factory function (createProject*, etc.) returns this type.
 */
export type Tool = ToolDefinition

/**
 * Tool execution context provided by the plugin runtime.
 *
 * Contains session information, abort signals, and utility functions
 * for tool implementations.
 */
export type ProjectToolContext = ToolContext
