/**
 * Tool type definitions
 */

import type { ToolContext } from "@opencode-ai/plugin"

/**
 * Tool definition type that doesn't expose Zod internals.
 * Used as return type for createProject* functions to avoid TypeScript declaration errors.
 *
 * Note: This is intentionally loose to avoid exposing Zod types in declaration files.
 * The actual runtime type is more specific.
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export type Tool = any

/**
 * Tool context - re-export from plugin package
 */
export type ProjectToolContext = ToolContext
