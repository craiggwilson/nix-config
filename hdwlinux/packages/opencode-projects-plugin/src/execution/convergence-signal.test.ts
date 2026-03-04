/**
 * Tests for convergence-signal utilities
 */

import { describe, test, expect } from "bun:test"
import {
  extractSignal,
  hasValidSignal,
  ensureSignal,
  parseAgentSignals,
  countSignals,
} from "./convergence-signal.js"

describe("convergence-signal", () => {
  describe("extractSignal", () => {
    test("extracts CONVERGED from last line", () => {
      expect(extractSignal("My analysis\nCONVERGED")).toBe("CONVERGED")
    })

    test("extracts STUCK from last line", () => {
      expect(extractSignal("My analysis\nSTUCK")).toBe("STUCK")
    })

    test("extracts CONTINUE from last line", () => {
      expect(extractSignal("My analysis\nCONTINUE")).toBe("CONTINUE")
    })

    test("returns undefined if no valid signal on last line", () => {
      expect(extractSignal("My analysis")).toBeUndefined()
    })

    test("returns undefined for empty response", () => {
      expect(extractSignal("")).toBeUndefined()
    })

    test("ignores trailing empty lines when finding last non-empty line", () => {
      expect(extractSignal("My analysis\nCONVERGED\n\n")).toBe("CONVERGED")
    })

    test("returns undefined if signal appears mid-response but not on last line", () => {
      expect(extractSignal("CONVERGED in the middle\nsome more text")).toBeUndefined()
    })

    test("returns undefined for partial signal match", () => {
      expect(extractSignal("My analysis\nCONVERGED_EXTRA")).toBeUndefined()
    })

    test("handles whitespace around signal on last line", () => {
      expect(extractSignal("My analysis\n  CONVERGED  ")).toBe("CONVERGED")
    })

    test("handles multi-line response with signal at end", () => {
      const response = "Line 1\nLine 2\nLine 3\nCONTINUE"
      expect(extractSignal(response)).toBe("CONTINUE")
    })
  })

  describe("hasValidSignal", () => {
    test("returns true when valid signal is on last line", () => {
      expect(hasValidSignal("Analysis\nCONVERGED")).toBe(true)
    })

    test("returns false when no valid signal", () => {
      expect(hasValidSignal("Analysis without signal")).toBe(false)
    })

    test("returns false for empty response", () => {
      expect(hasValidSignal("")).toBe(false)
    })

    test("returns false when signal is not on last line", () => {
      expect(hasValidSignal("CONVERGED\nmore text")).toBe(false)
    })
  })

  describe("ensureSignal", () => {
    test("returns response unchanged when valid signal is present", () => {
      const response = "My analysis\nCONVERGED"
      expect(ensureSignal(response)).toBe(response)
    })

    test("appends CONTINUE by default when signal is missing", () => {
      expect(ensureSignal("My analysis")).toBe("My analysis\nCONTINUE")
    })

    test("appends provided default signal when missing", () => {
      expect(ensureSignal("My analysis", "STUCK")).toBe("My analysis\nSTUCK")
    })

    test("appends CONVERGED when specified as default", () => {
      expect(ensureSignal("My analysis", "CONVERGED")).toBe("My analysis\nCONVERGED")
    })

    test("trims response before appending signal", () => {
      expect(ensureSignal("My analysis   ")).toBe("My analysis\nCONTINUE")
    })

    test("preserves STUCK signal when already present", () => {
      const response = "My analysis\nSTUCK"
      expect(ensureSignal(response)).toBe(response)
    })
  })

  describe("parseAgentSignals", () => {
    test("parses signals from multiple agents", () => {
      const responses = {
        "agent-a": "Analysis\nCONVERGED",
        "agent-b": "Analysis\nSTUCK",
        "agent-c": "Analysis\nCONTINUE",
      }
      const signals = parseAgentSignals(responses)
      expect(signals["agent-a"]).toBe("CONVERGED")
      expect(signals["agent-b"]).toBe("STUCK")
      expect(signals["agent-c"]).toBe("CONTINUE")
    })

    test("returns undefined for agents with no valid signal", () => {
      const responses = {
        "agent-a": "Analysis without signal",
      }
      const signals = parseAgentSignals(responses)
      expect(signals["agent-a"]).toBeUndefined()
    })

    test("handles empty responses map", () => {
      expect(parseAgentSignals({})).toEqual({})
    })

    test("handles mixed valid and invalid signals", () => {
      const responses = {
        "agent-a": "Analysis\nCONVERGED",
        "agent-b": "No signal here",
      }
      const signals = parseAgentSignals(responses)
      expect(signals["agent-a"]).toBe("CONVERGED")
      expect(signals["agent-b"]).toBeUndefined()
    })
  })

  describe("countSignals", () => {
    test("counts each signal type correctly", () => {
      const signals = {
        "agent-a": "CONVERGED" as const,
        "agent-b": "STUCK" as const,
        "agent-c": "CONTINUE" as const,
      }
      const counts = countSignals(signals)
      expect(counts.CONVERGED).toBe(1)
      expect(counts.STUCK).toBe(1)
      expect(counts.CONTINUE).toBe(1)
      expect(counts.UNKNOWN).toBe(0)
    })

    test("counts undefined signals as UNKNOWN", () => {
      const signals = {
        "agent-a": "CONVERGED" as const,
        "agent-b": undefined,
      }
      const counts = countSignals(signals)
      expect(counts.CONVERGED).toBe(1)
      expect(counts.UNKNOWN).toBe(1)
    })

    test("handles all agents converged", () => {
      const signals = {
        "agent-a": "CONVERGED" as const,
        "agent-b": "CONVERGED" as const,
      }
      const counts = countSignals(signals)
      expect(counts.CONVERGED).toBe(2)
      expect(counts.STUCK).toBe(0)
      expect(counts.CONTINUE).toBe(0)
      expect(counts.UNKNOWN).toBe(0)
    })

    test("handles empty signals map", () => {
      const counts = countSignals({})
      expect(counts.CONVERGED).toBe(0)
      expect(counts.STUCK).toBe(0)
      expect(counts.CONTINUE).toBe(0)
      expect(counts.UNKNOWN).toBe(0)
    })
  })
})
