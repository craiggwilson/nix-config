/**
 * Tests for configuration validation with Zod schemas
 */

import { describe, test, expect } from "bun:test"
import { parseConfig, DEFAULT_CONFIG, BEADS_PATH, PROJECTS_PATH } from "./config-schema.js"

describe("Configuration Validation", () => {
  test("validates valid minimal configuration", () => {
    const config = {
      version: "0.9.0",
    }

    const result = parseConfig(config)

    expect(result.ok).toBe(true)
    if (result.ok) {
      expect(result.value.version).toBe("0.9.0")
      expect(result.value.defaults.storage).toBe("global")
      expect(result.value.defaults.vcs).toBe("auto")
    }
  })

  test("validates valid full configuration", () => {
    const config = {
      version: "0.9.0",
      defaults: {
        storage: "local",
        vcs: "jj",
      },
      projects: {
        "test-project": {
          storage: "global",
        },
      },
      worktrees: {
        autoCleanup: false,
        basePath: "/custom/path",
      },
      delegation: {
        timeoutMs: 60000,
        smallModelTimeoutMs: 10000,
      },
      teams: {
        discussionRounds: 3,
        discussionRoundTimeoutMs: 120000,
        maxTeamSize: 10,
        retryFailedMembers: false,
      },
    }

    const result = parseConfig(config)

    expect(result.ok).toBe(true)
    if (result.ok) {
      expect(result.value.defaults.storage).toBe("local")
      expect(result.value.defaults.vcs).toBe("jj")
      expect(result.value.projects["test-project"]?.storage).toBe("global")
      expect(result.value.worktrees.autoCleanup).toBe(false)
      expect(result.value.delegation.timeoutMs).toBe(60000)
      expect(result.value.teams.discussionRounds).toBe(3)
    }
  })

  test("rejects invalid storage value", () => {
    const config = {
      version: "0.9.0",
      defaults: {
        storage: "invalid",
      },
    }

    const result = parseConfig(config)

    expect(result.ok).toBe(false)
    if (!result.ok) {
      expect(result.error.message).toContain("defaults.storage")
    }
  })

  test("rejects invalid VCS value", () => {
    const config = {
      version: "0.9.0",
      defaults: {
        vcs: "svn",
      },
    }

    const result = parseConfig(config)

    expect(result.ok).toBe(false)
    if (!result.ok) {
      expect(result.error.message).toContain("defaults.vcs")
    }
  })

  test("rejects negative timeout values", () => {
    const config = {
      version: "0.9.0",
      delegation: {
        timeoutMs: -1000,
      },
    }

    const result = parseConfig(config)

    expect(result.ok).toBe(false)
    if (!result.ok) {
      expect(result.error.message).toContain("delegation.timeoutMs")
    }
  })

  test("rejects invalid team size", () => {
    const config = {
      version: "0.9.0",
      teams: {
        maxTeamSize: 0,
      },
    }

    const result = parseConfig(config)

    expect(result.ok).toBe(false)
    if (!result.ok) {
      expect(result.error.message).toContain("teams.maxTeamSize")
    }
  })

  test("default configuration is valid", () => {
    const result = parseConfig(DEFAULT_CONFIG)

    expect(result.ok).toBe(true)
    if (result.ok) {
      expect(result.value.version).toBe("0.9.0")
    }
  })

  test("hardcoded paths are constants", () => {
    expect(BEADS_PATH).toBe(".beads")
    expect(PROJECTS_PATH).toBe(".projects")
  })

  test("ignores unknown fields with warning", () => {
    const config = {
      version: "0.9.0",
      unknownField: "should be ignored",
      defaults: {
        storage: "global",
      },
    }

    const result = parseConfig(config)

    // Zod will strip unknown fields by default
    expect(result.ok).toBe(true)
    if (result.ok) {
      expect((result.value as any).unknownField).toBeUndefined()
    }
  })

  test("removed fields are not in schema", () => {
    const config = {
      version: "0.9.0",
      agents: {
        plannerModel: "gpt-4",
        researcherModel: "gpt-3.5",
      },
      defaults: {
        beadsPath: ".custom-beads",
        projectsPath: ".custom-projects",
      },
    }

    const result = parseConfig(config)

    // These fields should be stripped/ignored
    expect(result.ok).toBe(true)
    if (result.ok) {
      expect((result.value as any).agents).toBeUndefined()
      expect((result.value.defaults as any).beadsPath).toBeUndefined()
      expect((result.value.defaults as any).projectsPath).toBeUndefined()
    }
  })
})
