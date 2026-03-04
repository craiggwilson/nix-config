/**
 * Tests for TeamComposer
 */

import { describe, test, expect } from "bun:test";
import { TeamComposer, type TeamComposerConfig } from "./team-composer.js";
import { createMockLogger } from "../utils/testing/index.js";

const mockLogger = createMockLogger();

const defaultConfig: TeamComposerConfig = {
	maxTeamSize: 5,
	smallModelTimeoutMs: 30000,
};

describe("TeamComposer", () => {
	describe("resolveTeamComposition", () => {
		test("returns explicit agents when provided", async () => {
			const composer = new TeamComposer(
				mockLogger,
				undefined as any,
				defaultConfig,
			);

			const agents = await composer.resolveTeamComposition(
				["agent-1", "agent-2"],
				"Test issue context",
			);

			expect(agents).toEqual(["agent-1", "agent-2"]);
		});

		test("enforces max team size on explicit agents", async () => {
			const config: TeamComposerConfig = {
				maxTeamSize: 2,
				smallModelTimeoutMs: 30000,
			};
			const composer = new TeamComposer(mockLogger, undefined as any, config);

			const agents = await composer.resolveTeamComposition(
				["agent-1", "agent-2", "agent-3", "agent-4"],
				"Test issue context",
			);

			expect(agents.length).toBe(2);
			expect(agents).toEqual(["agent-1", "agent-2"]);
		});

		test("returns empty array when no explicit agents and no client", async () => {
			const composer = new TeamComposer(
				mockLogger,
				undefined as any,
				defaultConfig,
			);

			const agents = await composer.resolveTeamComposition(
				undefined,
				"Test issue context",
			);

			// Without a client, discoverAgents returns empty
			expect(agents).toEqual([]);
		});
	});

	describe("selectDevilsAdvocate", () => {
		test("returns undefined for single agent team", async () => {
			const composer = new TeamComposer(
				mockLogger,
				undefined as any,
				defaultConfig,
			);

			const result = await composer.selectDevilsAdvocate(
				["primary-agent"],
				"Test issue",
			);

			expect(result).toBeUndefined();
		});

		test("returns second agent for two-agent team", async () => {
			const composer = new TeamComposer(
				mockLogger,
				undefined as any,
				defaultConfig,
			);

			const result = await composer.selectDevilsAdvocate(
				["primary-agent", "secondary-agent"],
				"Test issue",
			);

			expect(result).toBe("secondary-agent");
		});

		test("falls back to first non-primary when small model unavailable", async () => {
			const composer = new TeamComposer(
				mockLogger,
				undefined as any,
				defaultConfig,
			);

			const result = await composer.selectDevilsAdvocate(
				["primary", "agent-2", "agent-3"],
				"Test issue",
			);

			// Without client, falls back to first non-primary
			expect(result).toBe("agent-2");
		});

		test("selects devil's advocate from 3-agent team", async () => {
			const composer = new TeamComposer(
				mockLogger,
				undefined as any,
				defaultConfig,
			);

			// With 3 agents and no client, should fall back to first non-primary
			const result = await composer.selectDevilsAdvocate(
				["typescript-expert", "code-reviewer", "security-expert"],
				"Implement authentication flow",
			);

			// Falls back to first non-primary (code-reviewer)
			expect(result).toBe("code-reviewer");
		});

		test("handles empty non-primary list gracefully", async () => {
			const composer = new TeamComposer(
				mockLogger,
				undefined as any,
				defaultConfig,
			);

			const result = await composer.selectDevilsAdvocate(
				["only-primary"],
				"Test issue",
			);

			expect(result).toBeUndefined();
		});
	});

	describe("Team composition validation", () => {
		test("explicit 2-agent team is preserved", async () => {
			const composer = new TeamComposer(
				mockLogger,
				undefined as any,
				defaultConfig,
			);

			const agents = await composer.resolveTeamComposition(
				["primary-agent", "secondary-agent"],
				"Test issue context",
			);

			expect(agents).toEqual(["primary-agent", "secondary-agent"]);
		});

		test("explicit 3-agent team is preserved", async () => {
			const composer = new TeamComposer(
				mockLogger,
				undefined as any,
				defaultConfig,
			);

			const agents = await composer.resolveTeamComposition(
				["primary-agent", "secondary-agent", "devils-advocate-agent"],
				"Test issue context",
			);

			expect(agents).toEqual([
				"primary-agent",
				"secondary-agent",
				"devils-advocate-agent",
			]);
		});

		test("team size is enforced for explicit agents", async () => {
			const config: TeamComposerConfig = {
				maxTeamSize: 3,
				smallModelTimeoutMs: 30000,
			};
			const composer = new TeamComposer(mockLogger, undefined as any, config);

			const agents = await composer.resolveTeamComposition(
				["agent-1", "agent-2", "agent-3", "agent-4", "agent-5"],
				"Test issue context",
			);

			expect(agents.length).toBe(3);
			expect(agents).toEqual(["agent-1", "agent-2", "agent-3"]);
		});

		test("first agent is always primary", async () => {
			const composer = new TeamComposer(
				mockLogger,
				undefined as any,
				defaultConfig,
			);

			const agents = await composer.resolveTeamComposition(
				["implementer", "reviewer", "critic"],
				"Test issue context",
			);

			// First agent should be the primary
			expect(agents[0]).toBe("implementer");
		});
	});

	describe("Devil's advocate role assignment", () => {
		test("devil's advocate is never the primary agent", async () => {
			const composer = new TeamComposer(
				mockLogger,
				undefined as any,
				defaultConfig,
			);

			// Test multiple times to ensure consistency
			for (let i = 0; i < 5; i++) {
				const result = await composer.selectDevilsAdvocate(
					["primary-agent", "secondary-1", "secondary-2"],
					"Test issue",
				);

				expect(result).toBeDefined();
				expect(result).not.toBe("primary-agent");
				if (result) {
					expect(["secondary-1", "secondary-2"]).toContain(result);
				}
			}
		});

		test("devil's advocate selection with security-focused issue", async () => {
			const composer = new TeamComposer(
				mockLogger,
				undefined as any,
				defaultConfig,
			);

			// Without a client, falls back to first non-primary
			const result = await composer.selectDevilsAdvocate(
				["typescript-expert", "security-expert", "code-reviewer"],
				"Implement user authentication with password hashing and session management",
			);

			// Falls back to first non-primary (security-expert)
			expect(result).toBe("security-expert");
		});
	});
});
