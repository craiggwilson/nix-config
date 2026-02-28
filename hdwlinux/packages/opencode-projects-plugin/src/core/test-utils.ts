/**
 * Test utilities for opencode-projects plugin
 */

import { $ } from "bun"

import type { Logger, BunShell, OpencodeClient, ProjectToolContext, Team, CreateTeamOptions } from "./types.js"
import type { TeamManager } from "../execution/team-manager.js"

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
 * Check if a value is a raw shell expression { raw: string }
 */
function isRawExpression(value: unknown): value is { raw: string } {
  return (
    typeof value === "object" &&
    value !== null &&
    "raw" in value &&
    typeof (value as { raw: unknown }).raw === "string"
  )
}

/**
 * Create a test shell adapter that matches the BunShell interface
 *
 * This shell executes commands using Bun's native shell with the 'raw'
 * syntax, which allows executing command strings. This is needed because
 * the normal shell interpolation treats strings as single arguments.
 */
export function createTestShell(): BunShell {
  const createShellFn = (cwd?: string) => {
    const shellFn = ((strings: TemplateStringsArray, ...expressions: unknown[]) => {
      let cmd = strings[0]
      for (let i = 0; i < expressions.length; i++) {
        const expr = expressions[i]
        // Handle { raw: string } expressions - extract the raw string
        const exprStr = isRawExpression(expr) ? expr.raw : String(expr)
        cmd += exprStr + strings[i + 1]
      }
      // Use Bun's native shell with raw to execute command strings
      const baseShell = cwd ? $.cwd(cwd) : $
      return baseShell`${{ raw: cmd }}`.nothrow().quiet()
    }) as BunShell

    shellFn.braces = (pattern: string) => [pattern]
    shellFn.escape = (input: string) => input
    shellFn.env = () => shellFn
    shellFn.cwd = (newCwd: string) => createShellFn(newCwd)
    shellFn.nothrow = () => shellFn
    shellFn.throws = () => shellFn

    return shellFn
  }

  return createShellFn()
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

/**
 * Create a mock TeamManager for testing
 */
export function createMockTeamManager(): TeamManager {
  const teams = new Map<string, Team>()
  let teamCounter = 0

  return {
    setDelegationManager: () => {},
    create: async (options: CreateTeamOptions): Promise<Team> => {
      teamCounter++
      const teamId = `team-test-${teamCounter}`
      const agentName = options.agents?.[0] || "test-agent"
      const team: Team = {
        id: teamId,
        projectId: options.projectId,
        issueId: options.issueId,
        members: [
          {
            agent: agentName,
            role: "primary",
            status: "running",
            retryCount: 0,
          },
        ],
        status: "running",
        discussionRounds: 2,
        currentRound: 0,
        results: {},
        discussionHistory: [],
        parentSessionId: options.parentSessionId,
        parentAgent: options.parentAgent,
        startedAt: new Date().toISOString(),
      }
      teams.set(teamId, team)
      return team
    },
    handleDelegationComplete: async () => {},
    get: async (teamId: string) => teams.get(teamId) || null,
    listByIssue: async () => [],
    getRunningTeams: async () => Array.from(teams.values()).filter((t) => t.status === "running"),
  } as unknown as TeamManager
}
