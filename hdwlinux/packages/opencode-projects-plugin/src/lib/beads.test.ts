/**
 * Tests for BeadsClient
 *
 * These tests require beads (bd) to be installed and available in PATH.
 */

import { describe, test, expect, beforeAll, afterAll } from "bun:test"
import * as fs from "node:fs/promises"
import * as path from "node:path"
import * as os from "node:os"
import { $ } from "bun"

import { BeadsClient } from "./beads.js"
import type { Logger, BunShell } from "./types.js"

// Mock logger
const mockLogger: Logger = {
  debug: async () => {},
  info: async () => {},
  warn: async () => {},
  error: async () => {},
}

// Create a shell adapter that matches the BunShell interface
// The OpenCode BunShell is similar to Bun's $ but with some differences
const createTestShell = (): BunShell => {
  // Return a function that matches the BunShell interface
  const shell = ((strings: TemplateStringsArray, ...expressions: unknown[]) => {
    // Reconstruct the command string
    let cmd = strings[0]
    for (let i = 0; i < expressions.length; i++) {
      cmd += String(expressions[i]) + strings[i + 1]
    }
    // Use Bun's shell with nothrow to avoid exceptions
    return $`${{ raw: cmd }}`.nothrow().quiet()
  }) as BunShell

  // Add required methods (they won't be used in tests but need to exist for type compatibility)
  shell.braces = (pattern: string) => [pattern]
  shell.escape = (input: string) => input
  shell.env = () => shell
  shell.cwd = () => shell
  shell.nothrow = () => shell
  shell.throws = () => shell

  return shell
}

describe("BeadsClient", () => {
  let client: BeadsClient
  let testDir: string
  let testShell: BunShell

  beforeAll(async () => {
    testShell = createTestShell()
    client = new BeadsClient(mockLogger)
    client.setShell(testShell)

    // Create a temporary directory for testing
    testDir = await fs.mkdtemp(path.join(os.tmpdir(), "beads-test-"))
  })

  afterAll(async () => {
    // Cleanup test directory
    try {
      await fs.rm(testDir, { recursive: true, force: true })
    } catch {
      // Ignore cleanup errors
    }
  })

  test("isAvailable returns true when bd is installed", async () => {
    const available = await client.isAvailable()
    expect(available).toBe(true)
  })

  test("init creates .beads directory", async () => {
    const success = await client.init(testDir)
    expect(success).toBe(true)

    // Verify .beads directory exists
    const beadsDir = path.join(testDir, ".beads")
    const stat = await fs.stat(beadsDir)
    expect(stat.isDirectory()).toBe(true)
  })

  test("isInitialized returns true after init", async () => {
    const initialized = await client.isInitialized(testDir)
    expect(initialized).toBe(true)
  })

  test("createIssue creates an issue and returns ID", async () => {
    const issueId = await client.createIssue(testDir, "Test Issue", {
      priority: 1,
      labels: ["test"],
    })

    expect(issueId).not.toBeNull()
    expect(typeof issueId).toBe("string")
  })

  test("listIssues returns all issues", async () => {
    const issues = await client.listIssues(testDir)
    expect(issues.length).toBeGreaterThanOrEqual(1)
  })

  test("getProjectStatus returns summary", async () => {
    const status = await client.getProjectStatus("test", testDir)
    expect(status).not.toBeNull()
    expect(status?.total).toBeGreaterThanOrEqual(1)
    expect(typeof status?.completed).toBe("number")
    expect(typeof status?.inProgress).toBe("number")
  })
})
