/**
 * Test utilities for opencode-projects plugin
 */

import { $ } from "bun"

import type { Logger, BunShell, OpencodeClient, ProjectToolContext } from "./types.js"

/**
 * Create a mock logger that does nothing
 */
export function createMockLogger(): Logger {
  return {
    debug: async () => {},
    info: async () => {},
    warn: async () => {},
    error: async () => {},
  }
}

/**
 * Create a mock OpenCode client
 */
export function createMockClient(): OpencodeClient {
  return {
    app: {
      log: async () => ({}),
      agents: async () => ({ data: [] }),
    },
    session: {
      create: async () => ({ data: { id: "test-session" } }),
      get: async () => ({ data: { id: "test-session" } }),
      prompt: async () => ({
        data: { id: "test-msg", role: "assistant" as const, sessionID: "test-session" },
      }),
      messages: async () => ({ data: [] }),
      delete: async () => ({}),
    },
    config: {
      get: async () => ({ data: {} }),
    },
  }
}

/**
 * Create a test shell adapter that matches the BunShell interface
 */
export function createTestShell(): BunShell {
  const shell = ((strings: TemplateStringsArray, ...expressions: unknown[]) => {
    let cmd = strings[0]
    for (let i = 0; i < expressions.length; i++) {
      cmd += String(expressions[i]) + strings[i + 1]
    }
    return $`${{ raw: cmd }}`.nothrow().quiet()
  }) as BunShell

  shell.braces = (pattern: string) => [pattern]
  shell.escape = (input: string) => input
  shell.env = () => shell
  shell.cwd = () => shell
  shell.nothrow = () => shell
  shell.throws = () => shell

  return shell
}

/**
 * Create a mock tool context
 */
export function createMockContext(overrides?: Partial<ProjectToolContext>): ProjectToolContext {
  return {
    sessionID: "test-session",
    messageID: "test-message",
    agent: "test-agent",
    directory: "/test/directory",
    worktree: "/test/worktree",
    abort: new AbortController().signal,
    metadata: () => {},
    ask: async () => {},
    ...overrides,
  }
}
