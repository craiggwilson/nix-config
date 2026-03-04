/**
 * Tests for ConvergenceAssessor
 */

import { describe, test, expect } from "bun:test";
import { ConvergenceAssessor } from "./convergence-assessor.js";
import { createMockLogger } from "../../utils/testing/index.js";
import type { DiscussionRound } from "../../teams/index.js";
import type { OpencodeClient } from "../../utils/opencode-sdk/index.js";

const mockLogger = createMockLogger();

function makeRound(responses: Record<string, string>): DiscussionRound {
	return { round: 1, responses };
}

function makeClientWithResponse(jsonResponse: string): OpencodeClient {
	return {
		config: {
			get: async () => ({ data: { small_model: "test-model" } }),
		},
		session: {
			create: async () => ({ data: { id: "session-123" } }),
			prompt: async () => ({
				data: { parts: [{ type: "text", text: jsonResponse }] },
			}),
			delete: async () => ({}),
			get: async () => ({ data: { id: "session-123" } }),
			messages: async () => ({ data: [] }),
		},
		app: {
			log: async () => ({}),
			agents: async () => ({ data: [] }),
		},
	} as unknown as OpencodeClient;
}

function makeClientWithNoSmallModel(): OpencodeClient {
	return {
		config: {
			get: async () => ({ data: {} }),
		},
		session: {
			create: async () => ({ data: { id: "session-123" } }),
			prompt: async () => ({ data: {} }),
			delete: async () => ({}),
			get: async () => ({ data: { id: "session-123" } }),
			messages: async () => ({ data: [] }),
		},
		app: {
			log: async () => ({}),
			agents: async () => ({ data: [] }),
		},
	} as unknown as OpencodeClient;
}

describe("ConvergenceAssessor", () => {
	describe("assess", () => {
		test("returns converged state when small model says converged", async () => {
			const response = JSON.stringify({
				agentSignals: { "agent-a": "CONVERGED", "agent-b": "CONVERGED" },
				state: "converged",
				summary: "All agents agree",
			});
			const client = makeClientWithResponse(response);
			const assessor = new ConvergenceAssessor(mockLogger, client, {
				smallModelTimeoutMs: 5000,
			});

			const round = makeRound({
				"agent-a": "I agree **CONVERGED**",
				"agent-b": "Looks good **CONVERGED**",
			});
			const result = await assessor.assess(round, 1, 5);

			expect(result.state).toBe("converged");
			expect(result.agentSignals["agent-a"]).toBe("CONVERGED");
			expect(result.agentSignals["agent-b"]).toBe("CONVERGED");
			expect(result.summary).toBe("All agents agree");
		});

		test("returns stuck state when small model says stuck", async () => {
			const response = JSON.stringify({
				agentSignals: { "agent-a": "STUCK", "agent-b": "CONTINUE" },
				state: "stuck",
				summary: "Agent A has unresolved concerns",
			});
			const client = makeClientWithResponse(response);
			const assessor = new ConvergenceAssessor(mockLogger, client, {
				smallModelTimeoutMs: 5000,
			});

			const round = makeRound({
				"agent-a": "My concerns are ignored **STUCK**",
				"agent-b": "Making progress **CONTINUE**",
			});
			const result = await assessor.assess(round, 2, 5);

			expect(result.state).toBe("stuck");
			expect(result.agentSignals["agent-a"]).toBe("STUCK");
			expect(result.agentSignals["agent-b"]).toBe("CONTINUE");
		});

		test("returns continue state when small model says continue", async () => {
			const response = JSON.stringify({
				agentSignals: { "agent-a": "CONTINUE", "agent-b": "CONTINUE" },
				state: "continue",
				summary: "Discussion progressing",
			});
			const client = makeClientWithResponse(response);
			const assessor = new ConvergenceAssessor(mockLogger, client, {
				smallModelTimeoutMs: 5000,
			});

			const round = makeRound({
				"agent-a": "Still discussing **CONTINUE**",
				"agent-b": "More to cover **CONTINUE**",
			});
			const result = await assessor.assess(round, 1, 5);

			expect(result.state).toBe("continue");
		});

		test("falls back to continue when no small model configured", async () => {
			const client = makeClientWithNoSmallModel();
			const assessor = new ConvergenceAssessor(mockLogger, client, {
				smallModelTimeoutMs: 5000,
			});

			const round = makeRound({
				"agent-a": "Some response",
				"agent-b": "Another response",
			});
			const result = await assessor.assess(round, 1, 5);

			expect(result.state).toBe("continue");
			expect(result.agentSignals["agent-a"]).toBe("CONTINUE");
			expect(result.agentSignals["agent-b"]).toBe("CONTINUE");
			expect(result.summary).toContain("unavailable");
		});

		test("falls back to continue when small model returns invalid JSON", async () => {
			const client = makeClientWithResponse("not valid json at all");
			const assessor = new ConvergenceAssessor(mockLogger, client, {
				smallModelTimeoutMs: 5000,
			});

			const round = makeRound({ "agent-a": "Some response" });
			const result = await assessor.assess(round, 1, 5);

			expect(result.state).toBe("continue");
			expect(result.agentSignals["agent-a"]).toBe("CONTINUE");
		});

		test("falls back to continue when small model returns wrong schema", async () => {
			const response = JSON.stringify({ wrong: "schema" });
			const client = makeClientWithResponse(response);
			const assessor = new ConvergenceAssessor(mockLogger, client, {
				smallModelTimeoutMs: 5000,
			});

			const round = makeRound({ "agent-a": "Some response" });
			const result = await assessor.assess(round, 1, 5);

			expect(result.state).toBe("continue");
		});

		test("fallback assessment includes all agents from round", async () => {
			const client = makeClientWithNoSmallModel();
			const assessor = new ConvergenceAssessor(mockLogger, client, {
				smallModelTimeoutMs: 5000,
			});

			const round = makeRound({
				"agent-a": "Response A",
				"agent-b": "Response B",
				"agent-c": "Response C",
			});
			const result = await assessor.assess(round, 1, 5);

			expect(result.agentSignals["agent-a"]).toBe("CONTINUE");
			expect(result.agentSignals["agent-b"]).toBe("CONTINUE");
			expect(result.agentSignals["agent-c"]).toBe("CONTINUE");
		});
	});
});
