/**
 * Tests for BeadsIssueStorage
 */

import { describe, test, expect, beforeEach } from "bun:test"
import { BeadsIssueStorage } from "./storage.js"
import type { Logger, BunShell } from "../../utils/opencode-sdk/index.js"

/**
 * Creates a mock shell that captures executed commands and returns configured responses
 */
function createMockShell(responses: Map<string, { stdout: string; stderr: string; exitCode: number }>) {
  const executedCommands: string[] = []

  const createShellFn = (cwd?: string) => {
    const shellFn = ((strings: TemplateStringsArray, ...expressions: unknown[]) => {
      let cmd = strings[0]
      for (let i = 0; i < expressions.length; i++) {
        const expr = expressions[i]
        const exprStr =
          typeof expr === "object" && expr !== null && "raw" in expr
            ? (expr as { raw: string }).raw
            : String(expr)
        cmd += exprStr + strings[i + 1]
      }
      executedCommands.push(cmd)

      // Find matching response based on command content
      let response = { stdout: "", stderr: "", exitCode: 0 }
      for (const [pattern, resp] of responses) {
        if (cmd.includes(pattern)) {
          response = resp
          break
        }
      }

      return {
        nothrow: () => ({
          quiet: async () => response,
        }),
        quiet: () => ({
          nothrow: async () => response,
        }),
        then: async (resolve: (value: unknown) => void) => resolve(response),
      }
    }) as unknown as BunShell

    shellFn.braces = (pattern: string) => [pattern]
    shellFn.escape = (str: string) => `'${str.replace(/'/g, "'\\''")}'`
    shellFn.env = () => shellFn
    shellFn.cwd = (newCwd: string) => createShellFn(newCwd)
    shellFn.nothrow = () => shellFn
    shellFn.throws = () => shellFn

    return shellFn
  }

  return {
    shell: createShellFn() as BunShell,
    getExecutedCommands: () => executedCommands,
  }
}

describe("BeadsIssueStorage", () => {
  let storage: BeadsIssueStorage
  let mockLogger: Logger

  beforeEach(() => {
    mockLogger = {
      debug: async () => {},
      info: async () => {},
      warn: async () => {},
      error: async () => {},
    } as Logger

    storage = new BeadsIssueStorage(mockLogger)
  })

  describe("listIssues", () => {
    test("passes --all flag when all option is true", async () => {
      const { shell, getExecutedCommands } = createMockShell(
        new Map([
          [
            "bd",
            {
              stdout: "[]",
              stderr: "",
              exitCode: 0,
            },
          ],
        ])
      )

      storage.setShell(shell)
      await storage.listIssues("/tmp/test", { all: true })

      const commands = getExecutedCommands()
      expect(commands.length).toBeGreaterThan(0)
      expect(commands.some((cmd) => cmd.includes("--all"))).toBe(true)
    })

    test("passes --status flag when status option is provided", async () => {
      const { shell, getExecutedCommands } = createMockShell(
        new Map([
          [
            "bd",
            {
              stdout: "[]",
              stderr: "",
              exitCode: 0,
            },
          ],
        ])
      )

      storage.setShell(shell)
      await storage.listIssues("/tmp/test", { status: "closed" })

      const commands = getExecutedCommands()
      expect(commands.length).toBeGreaterThan(0)
      expect(commands.some((cmd) => cmd.includes("--status") && cmd.includes("closed"))).toBe(true)
    })

    test("all option takes precedence over status option", async () => {
      const { shell, getExecutedCommands } = createMockShell(
        new Map([
          [
            "bd",
            {
              stdout: "[]",
              stderr: "",
              exitCode: 0,
            },
          ],
        ])
      )

      storage.setShell(shell)
      await storage.listIssues("/tmp/test", { all: true, status: "open" })

      const commands = getExecutedCommands()
      expect(commands.length).toBeGreaterThan(0)
      // Should have --all but not --status
      expect(commands.some((cmd) => cmd.includes("--all"))).toBe(true)
      expect(commands.some((cmd) => cmd.includes("--status"))).toBe(false)
    })
  })

  describe("getProjectStatus", () => {
    test("correctly counts closed issues", async () => {
      const issuesJson = JSON.stringify([
        { id: "proj-1", title: "Issue 1", status: "closed" },
        { id: "proj-2", title: "Issue 2", status: "closed" },
        { id: "proj-3", title: "Issue 3", status: "open" },
      ])

      const { shell } = createMockShell(
        new Map([
          [
            "bd",
            {
              stdout: issuesJson,
              stderr: "",
              exitCode: 0,
            },
          ],
        ])
      )

      storage.setShell(shell)
      const result = await storage.getProjectStatus("/tmp/test")

      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(result.value.total).toBe(3)
        expect(result.value.completed).toBe(2)
        expect(result.value.inProgress).toBe(0)
      }
    })

    test("correctly counts in-progress issues alongside closed ones", async () => {
      const issuesJson = JSON.stringify([
        { id: "proj-1", title: "Issue 1", status: "closed" },
        { id: "proj-2", title: "Issue 2", status: "in_progress" },
        { id: "proj-3", title: "Issue 3", status: "in_progress" },
        { id: "proj-4", title: "Issue 4", status: "open" },
      ])

      const { shell } = createMockShell(
        new Map([
          [
            "bd",
            {
              stdout: issuesJson,
              stderr: "",
              exitCode: 0,
            },
          ],
        ])
      )

      storage.setShell(shell)
      const result = await storage.getProjectStatus("/tmp/test")

      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(result.value.total).toBe(4)
        expect(result.value.completed).toBe(1)
        expect(result.value.inProgress).toBe(2)
      }
    })

    test("uses --all flag to fetch all issues including closed", async () => {
      const { shell, getExecutedCommands } = createMockShell(
        new Map([
          [
            "bd",
            {
              stdout: "[]",
              stderr: "",
              exitCode: 0,
            },
          ],
        ])
      )

      storage.setShell(shell)
      await storage.getProjectStatus("/tmp/test")

      const commands = getExecutedCommands()
      expect(commands.length).toBeGreaterThan(0)
      expect(commands.some((cmd) => cmd.includes("--all"))).toBe(true)
    })

    test("correctly identifies blocked issues with open blockers", async () => {
      const issuesJson = JSON.stringify([
        { id: "proj-1", title: "Blocker", status: "open" },
        { id: "proj-2", title: "Blocked", status: "open", blocked_by: ["proj-1"] },
        { id: "proj-3", title: "Not blocked", status: "open" },
      ])

      const { shell } = createMockShell(
        new Map([
          [
            "bd",
            {
              stdout: issuesJson,
              stderr: "",
              exitCode: 0,
            },
          ],
        ])
      )

      storage.setShell(shell)
      const result = await storage.getProjectStatus("/tmp/test")

      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(result.value.blocked).toBe(1)
        expect(result.value.blockers).toHaveLength(1)
        expect(result.value.blockers[0].issueId).toBe("proj-2")
      }
    })

    test("does not count issue as blocked when blocker is closed", async () => {
      const issuesJson = JSON.stringify([
        { id: "proj-1", title: "Blocker", status: "closed" },
        { id: "proj-2", title: "Was blocked", status: "open", blocked_by: ["proj-1"] },
      ])

      const { shell } = createMockShell(
        new Map([
          [
            "bd",
            {
              stdout: issuesJson,
              stderr: "",
              exitCode: 0,
            },
          ],
        ])
      )

      storage.setShell(shell)
      const result = await storage.getProjectStatus("/tmp/test")

      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(result.value.blocked).toBe(0)
        expect(result.value.blockers).toHaveLength(0)
      }
    })
  })
})
