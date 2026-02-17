/**
 * Structured logging for opencode-projects plugin
 */

import type { OpencodeClient, Logger } from "./types.js"

const SERVICE_NAME = "opencode-projects"

/**
 * Create a structured logger that sends messages to OpenCode's log API.
 * Catches errors silently to avoid disrupting tool execution.
 */
export function createLogger(client: OpencodeClient): Logger {
  const log = async (level: "debug" | "info" | "warn" | "error", message: string): Promise<void> => {
    try {
      await client.app.log({
        body: { service: SERVICE_NAME, level, message },
      })
    } catch {
      // Silently ignore logging errors
    }
  }

  return {
    debug: (msg: string) => log("debug", msg),
    info: (msg: string) => log("info", msg),
    warn: (msg: string) => log("warn", msg),
    error: (msg: string) => log("error", msg),
  }
}
