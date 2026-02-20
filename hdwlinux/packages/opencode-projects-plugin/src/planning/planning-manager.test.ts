/**
 * Tests for PlanningManager
 */

import { describe, it, expect, beforeEach, afterEach } from "bun:test"
import * as fs from "node:fs/promises"
import * as path from "node:path"
import * as os from "node:os"

import { PlanningManager } from "./planning-manager.js"
import type { PlanningState } from "../core/types.js"

// Mock logger
const mockLog = {
  info: async () => {},
  warn: async () => {},
  error: async () => {},
  debug: async () => {},
}

describe("PlanningManager", () => {
  let tempDir: string
  let manager: PlanningManager

  beforeEach(async () => {
    tempDir = await fs.mkdtemp(path.join(os.tmpdir(), "planning-test-"))
    manager = new PlanningManager(tempDir, mockLog)
  })

  afterEach(async () => {
    await fs.rm(tempDir, { recursive: true, force: true })
  })

  describe("getState", () => {
    it("returns null when no planning state exists", async () => {
      const state = await manager.getState()
      expect(state).toBeNull()
    })

    it("returns state when it exists", async () => {
      const initialState: PlanningState = {
        phase: "discovery",
        startedAt: "2026-01-01T00:00:00Z",
        lastUpdatedAt: "2026-01-01T00:00:00Z",
        understanding: { problem: "Test problem" },
        openQuestions: [],
        completedPhases: [],
      }
      await fs.writeFile(
        path.join(tempDir, "planning.json"),
        JSON.stringify(initialState)
      )

      const state = await manager.getState()
      expect(state).not.toBeNull()
      expect(state?.phase).toBe("discovery")
      expect(state?.understanding.problem).toBe("Test problem")
    })
  })

  describe("startOrContinue", () => {
    it("creates new state when none exists", async () => {
      const state = await manager.startOrContinue()

      expect(state.phase).toBe("discovery")
      expect(state.understanding).toEqual({})
      expect(state.openQuestions).toEqual([])
      expect(state.completedPhases).toEqual([])

      // Verify it was persisted
      const persisted = await manager.getState()
      expect(persisted).not.toBeNull()
      expect(persisted?.phase).toBe("discovery")
    })

    it("returns existing state when it exists", async () => {
      const initialState: PlanningState = {
        phase: "synthesis",
        startedAt: "2026-01-01T00:00:00Z",
        lastUpdatedAt: "2026-01-01T00:00:00Z",
        understanding: { problem: "Existing problem" },
        openQuestions: ["Question 1"],
        completedPhases: ["discovery"],
      }
      await fs.writeFile(
        path.join(tempDir, "planning.json"),
        JSON.stringify(initialState)
      )

      const state = await manager.startOrContinue()

      expect(state.phase).toBe("synthesis")
      expect(state.understanding.problem).toBe("Existing problem")
      expect(state.openQuestions).toEqual(["Question 1"])
    })
  })

  describe("advancePhase", () => {
    it("advances from discovery to synthesis", async () => {
      await manager.startOrContinue()

      const state = await manager.advancePhase()

      expect(state.phase).toBe("synthesis")
      expect(state.completedPhases).toContain("discovery")
    })

    it("advances from synthesis to breakdown", async () => {
      await manager.startOrContinue()
      await manager.advancePhase() // discovery -> synthesis

      const state = await manager.advancePhase()

      expect(state.phase).toBe("breakdown")
      expect(state.completedPhases).toContain("synthesis")
    })

    it("advances from breakdown to complete", async () => {
      await manager.startOrContinue()
      await manager.advancePhase() // discovery -> synthesis
      await manager.advancePhase() // synthesis -> breakdown

      const state = await manager.advancePhase()

      expect(state.phase).toBe("complete")
      expect(state.completedPhases).toContain("breakdown")
    })

    it("throws when trying to advance from complete", async () => {
      await manager.startOrContinue()
      await manager.advancePhase()
      await manager.advancePhase()
      await manager.advancePhase() // Now at complete

      await expect(manager.advancePhase()).rejects.toThrow("Cannot advance from phase: complete")
    })

    it("throws when no planning session exists", async () => {
      await expect(manager.advancePhase()).rejects.toThrow("No planning session found")
    })
  })

  describe("setPhase", () => {
    it("sets phase to specified value", async () => {
      await manager.startOrContinue()

      const state = await manager.setPhase("breakdown")

      expect(state.phase).toBe("breakdown")
    })

    it("allows jumping back to earlier phase", async () => {
      await manager.startOrContinue()
      await manager.advancePhase() // discovery -> synthesis

      const state = await manager.setPhase("discovery")

      expect(state.phase).toBe("discovery")
    })

    it("throws when no planning session exists", async () => {
      await expect(manager.setPhase("synthesis")).rejects.toThrow("No planning session found")
    })
  })

  describe("updateUnderstanding", () => {
    it("updates understanding fields", async () => {
      await manager.startOrContinue()

      const state = await manager.updateUnderstanding({
        problem: "New problem",
        goals: ["Goal 1", "Goal 2"],
      })

      expect(state.understanding.problem).toBe("New problem")
      expect(state.understanding.goals).toEqual(["Goal 1", "Goal 2"])
    })

    it("merges with existing understanding", async () => {
      await manager.startOrContinue()
      await manager.updateUnderstanding({ problem: "Initial problem" })

      const state = await manager.updateUnderstanding({
        goals: ["Goal 1"],
        timeline: "Q1 2026",
      })

      expect(state.understanding.problem).toBe("Initial problem")
      expect(state.understanding.goals).toEqual(["Goal 1"])
      expect(state.understanding.timeline).toBe("Q1 2026")
    })

    it("deduplicates array fields", async () => {
      await manager.startOrContinue()
      await manager.updateUnderstanding({ goals: ["Goal 1", "Goal 2"] })

      const state = await manager.updateUnderstanding({
        goals: ["Goal 1", "Goal 2", "Goal 3"],
      })

      expect(state.understanding.goals).toEqual(["Goal 1", "Goal 2", "Goal 3"])
    })
  })

  describe("open questions", () => {
    it("updates open questions", async () => {
      await manager.startOrContinue()

      const state = await manager.updateOpenQuestions(["Q1", "Q2", "Q3"])

      expect(state.openQuestions).toEqual(["Q1", "Q2", "Q3"])
    })

    it("replaces existing questions", async () => {
      await manager.startOrContinue()
      await manager.updateOpenQuestions(["Old Q1", "Old Q2"])

      const state = await manager.updateOpenQuestions(["New Q1"])

      expect(state.openQuestions).toEqual(["New Q1"])
    })
  })

  describe("isActive", () => {
    it("returns false when no planning session exists", async () => {
      const active = await manager.isActive()
      expect(active).toBe(false)
    })

    it("returns true when planning is in progress", async () => {
      await manager.startOrContinue()

      const active = await manager.isActive()
      expect(active).toBe(true)
    })

    it("returns false when planning is complete", async () => {
      await manager.startOrContinue()
      await manager.setPhase("complete")

      const active = await manager.isActive()
      expect(active).toBe(false)
    })
  })

  describe("formatting", () => {
    it("formats understanding", () => {
      const formatted = manager.formatUnderstanding({
        problem: "Test problem",
        goals: ["Goal 1", "Goal 2"],
        timeline: "Q1 2026",
      })

      expect(formatted).toContain("**Problem:** Test problem")
      expect(formatted).toContain("**Goals:** Goal 1, Goal 2")
      expect(formatted).toContain("**Timeline:** Q1 2026")
    })

    it("formats status", async () => {
      await manager.startOrContinue()
      await manager.updateUnderstanding({ problem: "Test problem" })

      const state = await manager.getState()
      const formatted = manager.formatStatus(state!)

      expect(formatted).toContain("**Phase:** discovery")
      expect(formatted).toContain("### Understanding")
      expect(formatted).toContain("Test problem")
    })

    it("gets phase guidance", () => {
      const discoveryGuidance = manager.getPhaseGuidance("discovery")
      expect(discoveryGuidance).toContain("Discovery Phase")
      expect(discoveryGuidance).toContain("What problem are we solving")

      const synthesisGuidance = manager.getPhaseGuidance("synthesis")
      expect(synthesisGuidance).toContain("Synthesis Phase")
      expect(synthesisGuidance).toContain("Consolidate findings")

      const breakdownGuidance = manager.getPhaseGuidance("breakdown")
      expect(breakdownGuidance).toContain("Breakdown Phase")
      expect(breakdownGuidance).toContain("Create actionable issues")

      const completeGuidance = manager.getPhaseGuidance("complete")
      expect(completeGuidance).toContain("Planning Complete")
    })
  })

  describe("action handlers", () => {
    it("handleStatus returns message when no session", async () => {
      const result = await manager.handleStatus("test-project")
      expect(result).toContain("No planning session found")
    })

    it("handleStatus returns formatted status", async () => {
      await manager.startOrContinue()
      const result = await manager.handleStatus("test-project")
      expect(result).toContain("Planning Status: test-project")
      expect(result).toContain("**Phase:** discovery")
    })

    it("handleStartOrContinue creates and returns session", async () => {
      const result = await manager.handleStartOrContinue("test-project")
      expect(result).toContain("Planning Session: test-project")
      expect(result).toContain("Discovery Phase")
    })

    it("handleSave updates understanding", async () => {
      await manager.startOrContinue()
      const result = await manager.handleSave(
        "test-project",
        JSON.stringify({ problem: "Saved problem" }),
        "Q1, Q2"
      )

      expect(result).toContain("Planning Progress Saved")

      const state = await manager.getState()
      expect(state?.understanding.problem).toBe("Saved problem")
      expect(state?.openQuestions).toEqual(["Q1", "Q2"])
    })

    it("handleAdvance moves to next phase", async () => {
      await manager.startOrContinue()
      const result = await manager.handleAdvance()

      expect(result).toContain("Advanced to Phase: synthesis")
      expect(result).toContain("Synthesis Phase")
    })

    it("handleSetPhase sets specific phase", async () => {
      await manager.startOrContinue()
      const result = await manager.handleSetPhase("breakdown")

      expect(result).toContain("Phase Set: breakdown")
      expect(result).toContain("Breakdown Phase")
    })
  })

  describe("buildContext", () => {
    it("returns null when no planning session", async () => {
      const context = await manager.buildContext()
      expect(context).toBeNull()
    })

    it("returns null when planning is complete", async () => {
      await manager.startOrContinue()
      await manager.setPhase("complete")

      const context = await manager.buildContext()
      expect(context).toBeNull()
    })

    it("returns context for active planning", async () => {
      await manager.startOrContinue()
      await manager.updateUnderstanding({ problem: "Test problem" })

      const context = await manager.buildContext()

      expect(context).not.toBeNull()
      expect(context).toContain("<planning-session>")
      expect(context).toContain("Active Planning")
      expect(context).toContain("**Phase:** discovery")
      expect(context).toContain("Test problem")
      expect(context).toContain("</planning-session>")
    })
  })
})
