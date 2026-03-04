/**
 * Tests for PlanningManager
 */

import { describe, it, expect, beforeEach, afterEach } from "bun:test";
import * as fs from "node:fs/promises";
import * as path from "node:path";
import * as os from "node:os";

import { PlanningManager } from "./planning-manager.js";
import type { PlanningState } from "./planning-manager.js";

// Mock logger
const mockLog = {
	info: async () => {},
	warn: async () => {},
	error: async () => {},
	debug: async () => {},
};

/**
 * Helper to unwrap a Result, failing the test if it's an error
 */
function unwrapResult<T, E>(
	result: { ok: true; value: T } | { ok: false; error: E },
): T {
	if (!result.ok) {
		throw new Error(
			`Expected ok result, got error: ${JSON.stringify(result.error)}`,
		);
	}
	return result.value;
}

describe("PlanningManager", () => {
	let tempDir: string;
	let manager: PlanningManager;

	beforeEach(async () => {
		tempDir = await fs.mkdtemp(path.join(os.tmpdir(), "planning-test-"));
		manager = new PlanningManager(tempDir, mockLog);
	});

	afterEach(async () => {
		await fs.rm(tempDir, { recursive: true, force: true });
	});

	describe("getState", () => {
		it("returns null when no planning state exists", async () => {
			const state = await manager.getState();
			expect(state).toBeNull();
		});

		it("returns state when it exists", async () => {
			const initialState: PlanningState = {
				phase: "discovery",
				startedAt: "2026-01-01T00:00:00Z",
				lastUpdatedAt: "2026-01-01T00:00:00Z",
				understanding: { problem: "Test problem" },
				openQuestions: [],
				completedPhases: [],
			};
			await fs.writeFile(
				path.join(tempDir, "planning.json"),
				JSON.stringify(initialState),
			);

			const state = await manager.getState();
			expect(state).not.toBeNull();
			expect(state?.phase).toBe("discovery");
			expect(state?.understanding.problem).toBe("Test problem");
		});
	});

	describe("startOrContinue", () => {
		it("creates new state when none exists", async () => {
			const result = await manager.startOrContinue();
			expect(result.ok).toBe(true);
			const state = unwrapResult(result);

			expect(state.phase).toBe("discovery");
			expect(state.understanding).toEqual({});
			expect(state.openQuestions).toEqual([]);
			expect(state.completedPhases).toEqual([]);

			// Verify it was persisted
			const persisted = await manager.getState();
			expect(persisted).not.toBeNull();
			expect(persisted?.phase).toBe("discovery");
		});

		it("returns existing state when it exists", async () => {
			const initialState: PlanningState = {
				phase: "synthesis",
				startedAt: "2026-01-01T00:00:00Z",
				lastUpdatedAt: "2026-01-01T00:00:00Z",
				understanding: { problem: "Existing problem" },
				openQuestions: ["Question 1"],
				completedPhases: ["discovery"],
			};
			await fs.writeFile(
				path.join(tempDir, "planning.json"),
				JSON.stringify(initialState),
			);

			const result = await manager.startOrContinue();
			expect(result.ok).toBe(true);
			const state = unwrapResult(result);

			expect(state.phase).toBe("synthesis");
			expect(state.understanding.problem).toBe("Existing problem");
			expect(state.openQuestions).toEqual(["Question 1"]);
		});
	});

	describe("advancePhase", () => {
		it("advances from discovery to synthesis", async () => {
			unwrapResult(await manager.startOrContinue());

			const result = await manager.advancePhase();
			expect(result.ok).toBe(true);
			const state = unwrapResult(result);

			expect(state.phase).toBe("synthesis");
			expect(state.completedPhases).toContain("discovery");
		});

		it("advances from synthesis to breakdown", async () => {
			unwrapResult(await manager.startOrContinue());
			unwrapResult(await manager.advancePhase()); // discovery -> synthesis

			const result = await manager.advancePhase();
			expect(result.ok).toBe(true);
			const state = unwrapResult(result);

			expect(state.phase).toBe("breakdown");
			expect(state.completedPhases).toContain("synthesis");
		});

		it("advances from breakdown to complete", async () => {
			unwrapResult(await manager.startOrContinue());
			unwrapResult(await manager.advancePhase()); // discovery -> synthesis
			unwrapResult(await manager.advancePhase()); // synthesis -> breakdown

			const result = await manager.advancePhase();
			expect(result.ok).toBe(true);
			const state = unwrapResult(result);

			expect(state.phase).toBe("complete");
			expect(state.completedPhases).toContain("breakdown");
		});

		it("returns error when trying to advance from complete", async () => {
			unwrapResult(await manager.startOrContinue());
			unwrapResult(await manager.advancePhase());
			unwrapResult(await manager.advancePhase());
			unwrapResult(await manager.advancePhase()); // Now at complete

			const result = await manager.advancePhase();
			expect(result.ok).toBe(false);
			if (!result.ok) {
				expect(result.error.type).toBe("cannot_advance");
				if (result.error.type === "cannot_advance") {
					expect(result.error.currentPhase).toBe("complete");
				}
			}
		});

		it("returns error when no planning session exists", async () => {
			const result = await manager.advancePhase();
			expect(result.ok).toBe(false);
			if (!result.ok) {
				expect(result.error.type).toBe("no_session");
			}
		});
	});

	describe("setPhase", () => {
		it("sets phase to specified value", async () => {
			unwrapResult(await manager.startOrContinue());

			const result = await manager.setPhase("breakdown");
			expect(result.ok).toBe(true);
			const state = unwrapResult(result);

			expect(state.phase).toBe("breakdown");
		});

		it("allows jumping back to earlier phase", async () => {
			unwrapResult(await manager.startOrContinue());
			unwrapResult(await manager.advancePhase()); // discovery -> synthesis

			const result = await manager.setPhase("discovery");
			expect(result.ok).toBe(true);
			const state = unwrapResult(result);

			expect(state.phase).toBe("discovery");
		});

		it("returns error when no planning session exists", async () => {
			const result = await manager.setPhase("synthesis");
			expect(result.ok).toBe(false);
			if (!result.ok) {
				expect(result.error.type).toBe("no_session");
			}
		});
	});

	describe("updateUnderstanding", () => {
		it("updates understanding fields", async () => {
			unwrapResult(await manager.startOrContinue());

			const result = await manager.updateUnderstanding({
				problem: "New problem",
				goals: ["Goal 1", "Goal 2"],
			});
			expect(result.ok).toBe(true);
			const state = unwrapResult(result);

			expect(state.understanding.problem).toBe("New problem");
			expect(state.understanding.goals).toEqual(["Goal 1", "Goal 2"]);
		});

		it("merges with existing understanding", async () => {
			unwrapResult(await manager.startOrContinue());
			unwrapResult(
				await manager.updateUnderstanding({ problem: "Initial problem" }),
			);

			const result = await manager.updateUnderstanding({
				goals: ["Goal 1"],
				timeline: "Q1 2026",
			});
			expect(result.ok).toBe(true);
			const state = unwrapResult(result);

			expect(state.understanding.problem).toBe("Initial problem");
			expect(state.understanding.goals).toEqual(["Goal 1"]);
			expect(state.understanding.timeline).toBe("Q1 2026");
		});

		it("deduplicates array fields", async () => {
			unwrapResult(await manager.startOrContinue());
			unwrapResult(
				await manager.updateUnderstanding({ goals: ["Goal 1", "Goal 2"] }),
			);

			const result = await manager.updateUnderstanding({
				goals: ["Goal 1", "Goal 2", "Goal 3"],
			});
			expect(result.ok).toBe(true);
			const state = unwrapResult(result);

			expect(state.understanding.goals).toEqual(["Goal 1", "Goal 2", "Goal 3"]);
		});

		it("returns error when no planning session exists", async () => {
			const result = await manager.updateUnderstanding({ problem: "Test" });
			expect(result.ok).toBe(false);
			if (!result.ok) {
				expect(result.error.type).toBe("no_session");
			}
		});
	});

	describe("open questions", () => {
		it("updates open questions", async () => {
			unwrapResult(await manager.startOrContinue());

			const result = await manager.updateOpenQuestions(["Q1", "Q2", "Q3"]);
			expect(result.ok).toBe(true);
			const state = unwrapResult(result);

			expect(state.openQuestions).toEqual(["Q1", "Q2", "Q3"]);
		});

		it("replaces existing questions", async () => {
			unwrapResult(await manager.startOrContinue());
			unwrapResult(await manager.updateOpenQuestions(["Old Q1", "Old Q2"]));

			const result = await manager.updateOpenQuestions(["New Q1"]);
			expect(result.ok).toBe(true);
			const state = unwrapResult(result);

			expect(state.openQuestions).toEqual(["New Q1"]);
		});

		it("returns error when no planning session exists", async () => {
			const result = await manager.updateOpenQuestions(["Q1"]);
			expect(result.ok).toBe(false);
			if (!result.ok) {
				expect(result.error.type).toBe("no_session");
			}
		});
	});

	describe("isActive", () => {
		it("returns false when no planning session exists", async () => {
			const active = await manager.isActive();
			expect(active).toBe(false);
		});

		it("returns true when planning is in progress", async () => {
			unwrapResult(await manager.startOrContinue());

			const active = await manager.isActive();
			expect(active).toBe(true);
		});

		it("returns false when planning is complete", async () => {
			unwrapResult(await manager.startOrContinue());
			unwrapResult(await manager.setPhase("complete"));

			const active = await manager.isActive();
			expect(active).toBe(false);
		});
	});

	describe("formatting", () => {
		it("formats understanding", () => {
			const formatted = manager.formatUnderstanding({
				problem: "Test problem",
				goals: ["Goal 1", "Goal 2"],
				timeline: "Q1 2026",
			});

			expect(formatted).toContain("**Problem:** Test problem");
			expect(formatted).toContain("**Goals:** Goal 1, Goal 2");
			expect(formatted).toContain("**Timeline:** Q1 2026");
		});

		it("formats status", async () => {
			unwrapResult(await manager.startOrContinue());
			unwrapResult(
				await manager.updateUnderstanding({ problem: "Test problem" }),
			);

			const state = await manager.getState();
			if (!state) return;
			const formatted = manager.formatStatus(state);

			expect(formatted).toContain("**Phase:** discovery");
			expect(formatted).toContain("### Understanding");
			expect(formatted).toContain("Test problem");
		});

		it("gets phase guidance", () => {
			const discoveryGuidance = manager.getPhaseGuidance("discovery");
			expect(discoveryGuidance).toContain("Discovery Phase");
			expect(discoveryGuidance).toContain("What problem are we solving");

			const synthesisGuidance = manager.getPhaseGuidance("synthesis");
			expect(synthesisGuidance).toContain("Synthesis Phase");
			expect(synthesisGuidance).toContain("Consolidate findings");

			const breakdownGuidance = manager.getPhaseGuidance("breakdown");
			expect(breakdownGuidance).toContain("Breakdown Phase");
			expect(breakdownGuidance).toContain("Create actionable issues");

			const completeGuidance = manager.getPhaseGuidance("complete");
			expect(completeGuidance).toContain("Planning Complete");
		});
	});

	describe("action handlers", () => {
		it("handleStatus returns message when no session", async () => {
			const result = await manager.handleStatus("test-project");
			expect(result).toContain("No planning session found");
		});

		it("handleStatus returns formatted status", async () => {
			unwrapResult(await manager.startOrContinue());
			const result = await manager.handleStatus("test-project");
			expect(result).toContain("Planning Status: test-project");
			expect(result).toContain("**Phase:** discovery");
		});

		it("handleStartOrContinue creates and returns session", async () => {
			const result = await manager.handleStartOrContinue("test-project");
			expect(result).toContain("Planning Session: test-project");
			expect(result).toContain("Discovery Phase");
		});

		it("handleSave updates understanding", async () => {
			unwrapResult(await manager.startOrContinue());
			const result = await manager.handleSave(
				"test-project",
				JSON.stringify({ problem: "Saved problem" }),
				"Q1, Q2",
			);

			expect(result).toContain("Planning Progress Saved");

			const state = await manager.getState();
			expect(state?.understanding.problem).toBe("Saved problem");
			expect(state?.openQuestions).toEqual(["Q1", "Q2"]);
		});

		it("handleAdvance moves to next phase", async () => {
			unwrapResult(await manager.startOrContinue());
			const result = await manager.handleAdvance();

			expect(result).toContain("Advanced to Phase: synthesis");
			expect(result).toContain("Synthesis Phase");
		});

		it("handleAdvance returns error message when no session", async () => {
			const result = await manager.handleAdvance();
			expect(result).toContain("No planning session found");
		});

		it("handleAdvance returns error message when cannot advance", async () => {
			unwrapResult(await manager.startOrContinue());
			unwrapResult(await manager.setPhase("complete"));
			const result = await manager.handleAdvance();
			expect(result).toContain("Cannot advance from phase: complete");
		});

		it("handleSetPhase sets specific phase", async () => {
			unwrapResult(await manager.startOrContinue());
			const result = await manager.handleSetPhase("breakdown");

			expect(result).toContain("Phase Set: breakdown");
			expect(result).toContain("Breakdown Phase");
		});

		it("handleSetPhase returns error message when no session", async () => {
			const result = await manager.handleSetPhase("breakdown");
			expect(result).toContain("No planning session found");
		});
	});

	describe("buildContext", () => {
		it("returns null when no planning session", async () => {
			const context = await manager.buildContext();
			expect(context).toBeNull();
		});

		it("returns null when planning is complete", async () => {
			unwrapResult(await manager.startOrContinue());
			unwrapResult(await manager.setPhase("complete"));

			const context = await manager.buildContext();
			expect(context).toBeNull();
		});

		it("returns context for active planning", async () => {
			unwrapResult(await manager.startOrContinue());
			unwrapResult(
				await manager.updateUnderstanding({ problem: "Test problem" }),
			);

			const context = await manager.buildContext();

			expect(context).not.toBeNull();
			expect(context).toContain("<planning-session>");
			expect(context).toContain("Active Planning");
			expect(context).toContain("**Phase:** discovery");
			expect(context).toContain("Test problem");
			expect(context).toContain("</planning-session>");
		});
	});
});
