/**
 * Integration test utilities
 *
 * Provides test fixtures and helpers for integration tests.
 * CRITICAL: All tests use local storage in temporary directories to prevent
 * interference with actual projects.
 */

import * as fs from "node:fs/promises"
import * as path from "node:path"
import * as os from "node:os"
import { $ } from "bun"

import { ConfigManager } from "../src/config/index.js"
import { DelegationManager, TeamManager, type TeamConfig } from "../src/execution/index.js"
import { InMemoryIssueStorage } from "../src/issues/inmemory/index.js"
import { ProjectManager, FocusManager } from "../src/projects/index.js"
import type { Logger, OpencodeClient, BunShell } from "../src/utils/opencode-sdk/index.js"
import { WorktreeManager } from "../src/vcs/index.js"

/**
 * Default team configuration for tests
 */
export const DEFAULT_TEAM_CONFIG: TeamConfig = {
  discussionRounds: 2,
  discussionRoundTimeoutMs: 5 * 60 * 1000,
  maxTeamSize: 5,
  retryFailedMembers: true,
  smallModelTimeoutMs: 30000,
  delegationTimeoutMs: 15 * 60 * 1000,
}

/**
 * Fast team configuration for timeout tests
 */
export const FAST_TIMEOUT_CONFIG: TeamConfig = {
  ...DEFAULT_TEAM_CONFIG,
  delegationTimeoutMs: 100, // 100ms for fast timeout tests
  smallModelTimeoutMs: 50,
  discussionRoundTimeoutMs: 100,
}

/**
 * Create a mock logger that captures log messages
 */
export interface CapturedLog {
  level: "debug" | "info" | "warn" | "error"
  message: string
  timestamp: Date
}

export function createCapturingLogger(): { logger: Logger; logs: CapturedLog[] } {
  const logs: CapturedLog[] = []

  const logger: Logger = {
    debug: async (message: string) => {
      logs.push({ level: "debug", message, timestamp: new Date() })
    },
    info: async (message: string) => {
      logs.push({ level: "info", message, timestamp: new Date() })
    },
    warn: async (message: string) => {
      logs.push({ level: "warn", message, timestamp: new Date() })
    },
    error: async (message: string) => {
      logs.push({ level: "error", message, timestamp: new Date() })
    },
  }

  return { logger, logs }
}

/**
 * Create a silent mock logger
 */
export function createSilentLogger(): Logger {
  return {
    debug: async () => {},
    info: async () => {},
    warn: async () => {},
    error: async () => {},
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
 * Create a test shell adapter
 */
export function createTestShell(): BunShell {
  const createShellFn = (cwd?: string) => {
    const shellFn = ((strings: TemplateStringsArray, ...expressions: unknown[]) => {
      let cmd = strings[0]
      for (let i = 0; i < expressions.length; i++) {
        const expr = expressions[i]
        const exprStr = isRawExpression(expr) ? expr.raw : String(expr)
        cmd += exprStr + strings[i + 1]
      }
      const baseShell = cwd ? $.cwd(cwd) : $
      return baseShell`${{ raw: cmd }}`.nothrow().quiet()
    }) as BunShell

    shellFn.braces = (pattern: string) => [pattern]
    shellFn.escape = $.escape
    shellFn.env = () => shellFn
    shellFn.cwd = (newCwd: string) => createShellFn(newCwd)
    shellFn.nothrow = () => shellFn
    shellFn.throws = () => shellFn

    return shellFn
  }

  return createShellFn()
}

/**
 * Mock OpenCode client that tracks calls
 */
export interface MockClientCalls {
  sessionCreates: Array<{ title?: string; parentID?: string }>
  prompts: Array<{ sessionId: string; agent?: string; text: string }>
  messages: Array<{ sessionId: string }>
}

export function createMockClient(options?: {
  onPrompt?: (sessionId: string, text: string) => void
  simulateFailure?: boolean
}): { client: OpencodeClient; calls: MockClientCalls } {
  const calls: MockClientCalls = {
    sessionCreates: [],
    prompts: [],
    messages: [],
  }

  let sessionCounter = 0

  const client: OpencodeClient = {
    app: {
      log: async () => ({}),
      agents: async () => ({ data: [{ name: "test-agent" }, { name: "coder" }, { name: "reviewer" }] }),
    },
    session: {
      create: async (opts) => {
        sessionCounter++
        const sessionId = `test-session-${sessionCounter}`
        calls.sessionCreates.push({
          title: opts?.body?.title,
          parentID: opts?.body?.parentID,
        })
        return { data: { id: sessionId } }
      },
      get: async (opts) => {
        return { data: { id: opts?.path?.id || "test-session" } }
      },
      prompt: async (opts) => {
        const sessionId = opts?.path?.id || "unknown"
        const firstPart = opts?.body?.parts?.[0]
        const text = firstPart?.type === "text" && firstPart.text ? firstPart.text : ""
        calls.prompts.push({
          sessionId,
          agent: opts?.body?.agent,
          text,
        })
        options?.onPrompt?.(sessionId, text)

        if (options?.simulateFailure) {
          throw new Error("Simulated prompt failure")
        }

        return {
          data: {
            id: `msg-${Date.now()}`,
            role: "assistant" as const,
            sessionID: sessionId,
          },
        }
      },
      messages: async (opts) => {
        const sessionId = opts?.path?.id || "unknown"
        calls.messages.push({ sessionId })
        return { data: [] }
      },
      delete: async () => ({}),
    },
    config: {
      get: async () => ({ data: {} }),
    },
  }

  return { client, calls }
}

/**
 * Integration test fixture that sets up all components
 */
export interface IntegrationTestFixture {
  testDir: string
  repoDir: string
  config: ConfigManager
  focus: FocusManager
  issueStorage: InMemoryIssueStorage
  projectManager: ProjectManager
  delegationManager: DelegationManager
  teamManager: TeamManager
  worktreeManager: WorktreeManager
  logger: Logger
  logs: CapturedLog[]
  client: OpencodeClient
  clientCalls: MockClientCalls
  cleanup: () => Promise<void>
}

/**
 * Create a complete integration test fixture
 *
 * CRITICAL: Uses local storage only (temporary directory) to prevent
 * interference with actual projects.
 */
export async function createIntegrationFixture(options?: {
  teamConfig?: Partial<TeamConfig>
  initGitRepo?: boolean
  clientOptions?: Parameters<typeof createMockClient>[0]
}): Promise<IntegrationTestFixture> {
  // Create temporary directory for test isolation
  const testDir = await fs.mkdtemp(path.join(os.tmpdir(), "opencode-integration-test-"))
  const repoDir = path.join(testDir, "repo")
  await fs.mkdir(repoDir, { recursive: true })

  // Initialize git repo if requested (needed for worktree tests)
  if (options?.initGitRepo) {
    await $`git -C ${repoDir} init`.quiet()
    await $`git -C ${repoDir} config user.email "test@test.com"`.quiet()
    await $`git -C ${repoDir} config user.name "Test"`.quiet()
    await fs.writeFile(path.join(repoDir, "README.md"), "# Test Repo")
    await $`git -C ${repoDir} add .`.quiet()
    await $`git -C ${repoDir} commit -m "Initial commit"`.quiet()
  }

  // Create components
  const { logger, logs } = createCapturingLogger()
  const { client, calls: clientCalls } = createMockClient(options?.clientOptions)
  const config = await ConfigManager.loadOrThrow()
  const focus = new FocusManager()
  const issueStorage = new InMemoryIssueStorage({ prefix: "int" })
  const testShell = createTestShell()
  const worktreeManager = new WorktreeManager(repoDir, testShell, logger)

  const teamConfig: TeamConfig = {
    ...DEFAULT_TEAM_CONFIG,
    ...options?.teamConfig,
  }

  const delegationManager = new DelegationManager(logger, client, {
    timeoutMs: teamConfig.delegationTimeoutMs,
    smallModelTimeoutMs: teamConfig.smallModelTimeoutMs,
  })

  const teamManager = new TeamManager(
    logger,
    client,
    delegationManager,
    worktreeManager,
    teamConfig
  )

  const projectManager = new ProjectManager(
    config,
    issueStorage,
    focus,
    logger,
    repoDir
  )

  const cleanup = async () => {
    try {
      await fs.rm(testDir, { recursive: true, force: true })
    } catch {
      // Ignore cleanup errors
    }
  }

  return {
    testDir,
    repoDir,
    config,
    focus,
    issueStorage,
    projectManager,
    delegationManager,
    teamManager,
    worktreeManager,
    logger,
    logs,
    client,
    clientCalls,
    cleanup,
  }
}

/**
 * Wait for a condition with timeout
 */
export async function waitFor(
  condition: () => boolean | Promise<boolean>,
  options?: { timeoutMs?: number; intervalMs?: number }
): Promise<boolean> {
  const timeoutMs = options?.timeoutMs ?? 5000
  const intervalMs = options?.intervalMs ?? 50
  const startTime = Date.now()

  while (Date.now() - startTime < timeoutMs) {
    if (await condition()) {
      return true
    }
    await new Promise((resolve) => setTimeout(resolve, intervalMs))
  }

  return false
}

/**
 * Check if git is available
 */
export async function isGitAvailable(): Promise<boolean> {
  try {
    const result = await $`git --version`.nothrow().quiet()
    return result.exitCode === 0
  } catch {
    return false
  }
}

/**
 * Clean up all test directories matching a pattern
 */
export async function cleanupTestDirectories(pattern: string): Promise<void> {
  try {
    const tmpDir = os.tmpdir()
    const entries = await fs.readdir(tmpDir)
    for (const entry of entries) {
      if (entry.startsWith(pattern)) {
        await fs.rm(path.join(tmpDir, entry), { recursive: true, force: true })
      }
    }
  } catch {
    // Ignore cleanup errors
  }
}
