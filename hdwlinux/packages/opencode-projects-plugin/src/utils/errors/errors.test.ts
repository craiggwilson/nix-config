import { describe, it, expect } from "bun:test"
import * as os from "node:os"
import {
  sanitizeErrorOutput,
  formatBeadsError,
  formatDelegationError,
  formatTeamError,
  formatError,
  ProjectsPluginError,
  type BeadsError,
  type DelegationError,
  type TeamError,
} from "./errors"

describe("sanitizeErrorOutput", () => {
  describe("path sanitization", () => {
    it("should replace home directory with ~", () => {
      const homeDir = os.homedir()
      const input = `Error at ${homeDir}/projects/test/file.ts`
      const result = sanitizeErrorOutput(input)
      expect(result).toContain("~")
      expect(result).not.toContain(homeDir)
    })

    it("should sanitize /home/username paths", () => {
      const input = "Error at /home/secretuser/projects/test.ts"
      const result = sanitizeErrorOutput(input)
      expect(result).not.toContain("secretuser")
      expect(result).toContain("~")
    })

    it("should sanitize /Users/username paths (macOS)", () => {
      const input = "Error at /Users/secretuser/Documents/project/file.ts"
      const result = sanitizeErrorOutput(input)
      expect(result).not.toContain("secretuser")
      expect(result).toContain("~")
    })

    it("should sanitize nix store paths", () => {
      const input = "Error in /nix/store/abc123def456-package/bin/tool"
      const result = sanitizeErrorOutput(input)
      expect(result).toContain("/nix/store/.../")
      expect(result).not.toContain("abc123def456")
    })

    it("should sanitize /tmp paths", () => {
      const input = "Temp file at /tmp/secret-session-12345/data.json"
      const result = sanitizeErrorOutput(input)
      expect(result).toContain("/tmp/...")
      expect(result).not.toContain("secret-session-12345")
    })

    it("should sanitize /var paths", () => {
      const input = "Log at /var/log/myapp/secret.log"
      const result = sanitizeErrorOutput(input)
      expect(result).toContain("/var/...")
      expect(result).not.toContain("secret.log")
    })
  })

  describe("sensitive data redaction", () => {
    it("should redact API keys", () => {
      const input = "Failed with api_key=sk_live_abc123xyz"
      const result = sanitizeErrorOutput(input)
      expect(result).toContain("[REDACTED]")
      expect(result).not.toContain("sk_live_abc123xyz")
    })

    it("should redact tokens", () => {
      const input = "Auth failed: token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"
      const result = sanitizeErrorOutput(input)
      expect(result).toContain("[REDACTED]")
      expect(result).not.toContain("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9")
    })

    it("should redact passwords", () => {
      const input = "Connection failed: password=supersecret123"
      const result = sanitizeErrorOutput(input)
      expect(result).toContain("[REDACTED]")
      expect(result).not.toContain("supersecret123")
    })

    it("should redact GitHub tokens", () => {
      const input = "Auth error with ghp_1234567890abcdefghijklmnopqrstuvwxyz12"
      const result = sanitizeErrorOutput(input)
      expect(result).toContain("[GITHUB_TOKEN_REDACTED]")
      expect(result).not.toContain("ghp_1234567890abcdefghijklmnopqrstuvwxyz12")
    })

    it("should redact AWS access keys", () => {
      const input = "AWS error: AKIAIOSFODNN7EXAMPLE"
      const result = sanitizeErrorOutput(input)
      expect(result).toContain("[AWS_KEY_REDACTED]")
      expect(result).not.toContain("AKIAIOSFODNN7EXAMPLE")
    })

    it("should redact Bearer tokens", () => {
      const input = "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0"
      const result = sanitizeErrorOutput(input)
      expect(result).toContain("Bearer [REDACTED]")
      expect(result).not.toContain("eyJhbGciOiJIUzI1NiJ9")
    })

    it("should redact connection string credentials", () => {
      const input = "mongodb://admin:secretpassword@localhost:27017/db"
      const result = sanitizeErrorOutput(input)
      expect(result).toContain("[CREDENTIALS_REDACTED]")
      expect(result).not.toContain("admin:secretpassword")
    })

    it("should redact private keys", () => {
      const input = `Error with key:
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA0Z3VS5JJcds3xfn/ygWyF8PbnGy
-----END RSA PRIVATE KEY-----`
      const result = sanitizeErrorOutput(input)
      expect(result).toContain("[PRIVATE_KEY_REDACTED]")
      expect(result).not.toContain("MIIEpAIBAAKCAQEA0Z3VS5JJcds3xfn")
    })
  })

  describe("combined sanitization", () => {
    it("should handle multiple sensitive items", () => {
      const homeDir = os.homedir()
      const input = `Error at ${homeDir}/config with password=secret123 and token=abc123`
      const result = sanitizeErrorOutput(input)
      expect(result).not.toContain(homeDir)
      expect(result).not.toContain("secret123")
      expect(result).toContain("[REDACTED]")
    })

    it("should preserve non-sensitive content", () => {
      const input = "Error: File not found at ./relative/path.ts"
      const result = sanitizeErrorOutput(input)
      expect(result).toBe("Error: File not found at ./relative/path.ts")
    })
  })
})

describe("formatBeadsError", () => {
  it("should format not_available error", () => {
    const error: BeadsError = { type: "not_available" }
    const result = formatBeadsError(error)
    expect(result).toContain("beads (bd) CLI not found")
  })

  it("should format shell_not_initialized error", () => {
    const error: BeadsError = { type: "shell_not_initialized" }
    const result = formatBeadsError(error)
    expect(result).toContain("shell not initialized")
  })

  it("should sanitize command_failed stderr", () => {
    const error: BeadsError = {
      type: "command_failed",
      command: "/home/user/bin/bd list",
      exitCode: 1,
      stderr: "Error: password=secret123 at /home/user/config",
    }
    const result = formatBeadsError(error)
    expect(result).not.toContain("/home/user")
    expect(result).not.toContain("secret123")
    expect(result).toContain("exit code 1")
  })

  it("should sanitize parse_error message", () => {
    const error: BeadsError = {
      type: "parse_error",
      message: "Invalid JSON at /home/user/data.json with token=abc123",
    }
    const result = formatBeadsError(error)
    expect(result).not.toContain("/home/user")
    expect(result).toContain("[REDACTED]")
  })

  it("should sanitize timeout command", () => {
    const error: BeadsError = {
      type: "timeout",
      command: "/usr/local/bin/bd --auth-token=secret123 list",
      timeoutMs: 30000,
    }
    const result = formatBeadsError(error)
    expect(result).toContain("30s")
    expect(result).not.toContain("secret123")
  })
})

describe("formatDelegationError", () => {
  it("should format not_found error", () => {
    const error: DelegationError = { type: "not_found", delegationId: "del-123" }
    const result = formatDelegationError(error)
    expect(result).toBe("Delegation 'del-123' not found")
  })

  it("should sanitize session_failed message", () => {
    const error: DelegationError = {
      type: "session_failed",
      delegationId: "del-123",
      message: "Failed at /home/user/project with password=secret",
    }
    const result = formatDelegationError(error)
    expect(result).not.toContain("/home/user")
    expect(result).not.toContain("secret")
    expect(result).toContain("del-123")
  })

  it("should sanitize persistence_failed message", () => {
    const error: DelegationError = {
      type: "persistence_failed",
      delegationId: "del-456",
      message: "Write failed to /var/data/secret.json",
    }
    const result = formatDelegationError(error)
    expect(result).toContain("/var/...")
    expect(result).toContain("del-456")
  })
})

describe("formatTeamError", () => {
  it("should format not_found error", () => {
    const error: TeamError = { type: "not_found", teamId: "team-123" }
    const result = formatTeamError(error)
    expect(result).toBe("Team 'team-123' not found")
  })

  it("should sanitize no_agents_available context", () => {
    const error: TeamError = {
      type: "no_agents_available",
      issueContext: "Working on /home/user/secret-project with api_key=abc123 and more context here",
    }
    const result = formatTeamError(error)
    expect(result).not.toContain("/home/user")
    expect(result).not.toContain("abc123")
    expect(result).toContain("...")
  })

  it("should sanitize worktree_failed message", () => {
    const error: TeamError = {
      type: "worktree_failed",
      teamId: "team-456",
      message: "Failed to create at /home/user/worktrees/secret",
    }
    const result = formatTeamError(error)
    expect(result).not.toContain("/home/user")
    expect(result).toContain("team-456")
  })
})

describe("formatError", () => {
  it("should format ProjectsPluginError with suggestion", () => {
    const error = new ProjectsPluginError("Test error", "TEST_CODE", true, "Try this instead")
    const result = formatError(error)
    expect(result).toContain("Test error")
    expect(result).toContain("**Suggestion:**")
    expect(result).toContain("Try this instead")
  })

  it("should sanitize ProjectsPluginError message", () => {
    const error = new ProjectsPluginError(
      "Error at /home/user/project with password=secret",
      "TEST_CODE"
    )
    const result = formatError(error)
    expect(result).not.toContain("/home/user")
    expect(result).not.toContain("secret")
  })

  it("should sanitize generic Error message", () => {
    const error = new Error("Failed at /home/user/config with token=abc123")
    const result = formatError(error)
    expect(result).not.toContain("/home/user")
    expect(result).not.toContain("abc123")
  })

  it("should sanitize string errors", () => {
    const result = formatError("Error: password=secret123 at /home/user/file")
    expect(result).not.toContain("secret123")
    expect(result).not.toContain("/home/user")
  })

  it("should handle unknown error types", () => {
    const result = formatError({ custom: "error", path: "/home/user/secret" })
    expect(result).not.toContain("/home/user")
  })
})
