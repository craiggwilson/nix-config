/**
 * Tests for TeamComposer
 */

import { describe, test, expect } from "bun:test"
import { TeamComposer, type TeamComposerConfig } from "./team-composer.js"
import { createMockLogger } from "../utils/testing/index.js"

const mockLogger = createMockLogger()

const defaultConfig: TeamComposerConfig = {
  maxTeamSize: 5,
  smallModelTimeoutMs: 30000,
}

describe("TeamComposer", () => {
  describe("resolveTeamComposition", () => {
    test("returns explicit agents when provided", async () => {
      const composer = new TeamComposer(
        mockLogger,
        undefined as any,
        defaultConfig
      )

      const agents = await composer.resolveTeamComposition(
        ["agent-1", "agent-2"],
        "Test issue context"
      )

      expect(agents).toEqual(["agent-1", "agent-2"])
    })

    test("enforces max team size on explicit agents", async () => {
      const config: TeamComposerConfig = {
        maxTeamSize: 2,
        smallModelTimeoutMs: 30000,
      }
      const composer = new TeamComposer(mockLogger, undefined as any, config)

      const agents = await composer.resolveTeamComposition(
        ["agent-1", "agent-2", "agent-3", "agent-4"],
        "Test issue context"
      )

      expect(agents.length).toBe(2)
      expect(agents).toEqual(["agent-1", "agent-2"])
    })

    test("returns empty array when no explicit agents and no client", async () => {
      const composer = new TeamComposer(
        mockLogger,
        undefined as any,
        defaultConfig
      )

      const agents = await composer.resolveTeamComposition(
        undefined,
        "Test issue context"
      )

      // Without a client, discoverAgents returns empty
      expect(agents).toEqual([])
    })
  })

  describe("selectDevilsAdvocate", () => {
    test("returns undefined for single agent team", async () => {
      const composer = new TeamComposer(
        mockLogger,
        undefined as any,
        defaultConfig
      )

      const result = await composer.selectDevilsAdvocate(
        ["primary-agent"],
        "Test issue"
      )

      expect(result).toBeUndefined()
    })

    test("returns second agent for two-agent team", async () => {
      const composer = new TeamComposer(
        mockLogger,
        undefined as any,
        defaultConfig
      )

      const result = await composer.selectDevilsAdvocate(
        ["primary-agent", "secondary-agent"],
        "Test issue"
      )

      expect(result).toBe("secondary-agent")
    })

    test("falls back to first non-primary when small model unavailable", async () => {
      const composer = new TeamComposer(
        mockLogger,
        undefined as any,
        defaultConfig
      )

      const result = await composer.selectDevilsAdvocate(
        ["primary", "agent-2", "agent-3"],
        "Test issue"
      )

      // Without client, falls back to first non-primary
      expect(result).toBe("agent-2")
    })
  })
})
