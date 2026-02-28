/**
 * Tests for shell utilities
 */

import { describe, test, expect } from "bun:test"
import { buildCommand } from "./shell.js"
import { createTestShell } from "../testing/index.js"

describe("buildCommand", () => {
  test("escapes arguments with special characters", () => {
    const $ = createTestShell()
    
    const cmd = buildCommand($, "bd", ["create", "--force", "Test; rm -rf /"])
    
    expect(cmd).toContain("bd")
    expect(cmd).toContain("create")
    expect(cmd).toContain("--force")
    expect(cmd).toContain('"Test; rm -rf /"')
  })

  test("escapes arguments with quotes", () => {
    const $ = createTestShell()
    
    const cmd = buildCommand($, "bd", ["create", 'Title with "quotes"'])
    
    expect(cmd).toContain("bd")
    expect(cmd).toContain("create")
  })

  test("escapes arguments with newlines", () => {
    const $ = createTestShell()
    
    const cmd = buildCommand($, "bd", ["create", "Title\nwith\nnewlines"])
    
    expect(cmd).toContain("bd")
    expect(cmd).toContain("create")
  })

  test("handles empty arguments", () => {
    const $ = createTestShell()
    
    const cmd = buildCommand($, "bd", [])
    
    expect(cmd).toBe("bd")
  })

  test("handles multiple arguments", () => {
    const $ = createTestShell()
    
    const cmd = buildCommand($, "git", ["-C", "/path/to/repo", "status", "--porcelain"])
    
    expect(cmd).toContain("git")
    expect(cmd).toContain("-C")
    expect(cmd).toContain("status")
    expect(cmd).toContain("--porcelain")
  })

  test("escapes backtick command substitution", () => {
    const $ = createTestShell()
    
    const cmd = buildCommand($, "bd", ["create", "test`whoami`"])
    
    // The backticks should be escaped so they don't execute
    expect(cmd).toContain("bd")
    expect(cmd).toContain("create")
    // Bun's shell.escape() escapes backticks with backslashes inside double quotes
    expect(cmd).toContain("\\`whoami\\`")
  })

  test("escapes $() command substitution", () => {
    const $ = createTestShell()
    
    const cmd = buildCommand($, "bd", ["create", "$(cat /etc/passwd)"])
    
    // The $() should be escaped so it doesn't execute
    expect(cmd).toContain("bd")
    expect(cmd).toContain("create")
    // Bun's shell.escape() escapes $ with backslash inside double quotes
    expect(cmd).toContain("\\$(cat /etc/passwd)")
  })

  test("escapes pipe and redirect operators", () => {
    const $ = createTestShell()
    
    const cmd = buildCommand($, "bd", ["create", "test | cat > /tmp/pwned"])
    
    // The pipe and redirect should be quoted to prevent shell interpretation
    expect(cmd).toContain("bd")
    expect(cmd).toContain("create")
    // The entire argument should be quoted
    expect(cmd).toContain('"test | cat > /tmp/pwned"')
  })
})
