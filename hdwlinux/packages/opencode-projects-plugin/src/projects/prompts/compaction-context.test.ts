/**
 * Tests for compaction-context builders
 */

import { describe, it, expect } from "bun:test";

import {
	buildDelegationCompactionContext,
	buildTeamCompactionContext,
} from "./compaction-context.js";
import type { Delegation } from "../../delegation/index.js";
import type { Team } from "../../teams/index.js";

/**
 * Create a minimal Delegation object for testing.
 * Provides required fields with sensible defaults.
 */
function createTestDelegation(
	overrides: Partial<Delegation> & {
		id: string;
		projectId: string;
		issueId: string;
		status: Delegation["status"];
		startedAt: string;
	},
): Delegation {
	return {
		projectDir: "/tmp/project",
		teamId: "team-1",
		role: "primary",
		prompt: "Test prompt",
		...overrides,
	};
}

describe("buildDelegationCompactionContext", () => {
	it("returns empty context for no delegations", () => {
		const result = buildDelegationCompactionContext([], []);

		expect(result).toContain("<delegation-context>");
		expect(result).toContain("</delegation-context>");
		expect(result).not.toContain("## Running Delegations");
		expect(result).not.toContain("## Recent Completed Delegations");
	});

	it("includes running delegations", () => {
		const running: Delegation[] = [
			createTestDelegation({
				id: "del-123",
				projectId: "proj-1",
				issueId: "issue-1",
				agent: "coder",
				status: "running",
				startedAt: "2026-01-01T00:00:00Z",
				parentSessionId: "session-1",
				parentAgent: "planner",
			}),
		];

		const result = buildDelegationCompactionContext(running, []);

		expect(result).toContain("## Running Delegations");
		expect(result).toContain("del-123");
		expect(result).toContain("issue-1");
		expect(result).toContain("coder");
		expect(result).toContain("delegation-notification");
		expect(result).toContain("Do NOT poll");
	});

	it("includes worktree path when present", () => {
		const running: Delegation[] = [
			createTestDelegation({
				id: "del-123",
				projectId: "proj-1",
				issueId: "issue-1",
				status: "running",
				startedAt: "2026-01-01T00:00:00Z",
				worktreePath: "/tmp/worktree-123",
				parentSessionId: "session-1",
				parentAgent: "planner",
			}),
		];

		const result = buildDelegationCompactionContext(running, []);

		expect(result).toContain("Worktree:");
		expect(result).toContain("/tmp/worktree-123");
	});

	it("shows (auto) for delegations without agent", () => {
		const running: Delegation[] = [
			createTestDelegation({
				id: "del-123",
				projectId: "proj-1",
				issueId: "issue-1",
				status: "running",
				startedAt: "2026-01-01T00:00:00Z",
				parentSessionId: "session-1",
				parentAgent: "planner",
			}),
		];

		const result = buildDelegationCompactionContext(running, []);

		expect(result).toContain("(auto)");
	});

	it("includes completed delegations with status icons", () => {
		const completed: Delegation[] = [
			createTestDelegation({
				id: "del-success",
				projectId: "proj-1",
				issueId: "issue-1",
				title: "Successful task",
				status: "completed",
				startedAt: "2026-01-01T00:00:00Z",
				completedAt: "2026-01-01T01:00:00Z",
				parentSessionId: "session-1",
				parentAgent: "planner",
			}),
			createTestDelegation({
				id: "del-failed",
				projectId: "proj-1",
				issueId: "issue-2",
				title: "Failed task",
				status: "failed",
				startedAt: "2026-01-01T00:00:00Z",
				completedAt: "2026-01-01T01:00:00Z",
				parentSessionId: "session-1",
				parentAgent: "planner",
			}),
		];

		const result = buildDelegationCompactionContext([], completed);

		expect(result).toContain("## Recent Completed Delegations");
		expect(result).toContain("✅");
		expect(result).toContain("❌");
		expect(result).toContain("Successful task");
		expect(result).toContain("Failed task");
		expect(result).toContain("project-internal-delegation-read");
	});

	it("shows (no title) for delegations without title", () => {
		const completed: Delegation[] = [
			createTestDelegation({
				id: "del-123",
				projectId: "proj-1",
				issueId: "issue-1",
				status: "completed",
				startedAt: "2026-01-01T00:00:00Z",
				completedAt: "2026-01-01T01:00:00Z",
				parentSessionId: "session-1",
				parentAgent: "planner",
			}),
		];

		const result = buildDelegationCompactionContext([], completed);

		expect(result).toContain("(no title)");
	});

	it("includes both running and completed delegations", () => {
		const running: Delegation[] = [
			createTestDelegation({
				id: "del-running",
				projectId: "proj-1",
				issueId: "issue-1",
				status: "running",
				startedAt: "2026-01-01T00:00:00Z",
				parentSessionId: "session-1",
				parentAgent: "planner",
			}),
		];
		const completed: Delegation[] = [
			createTestDelegation({
				id: "del-done",
				projectId: "proj-1",
				issueId: "issue-2",
				status: "completed",
				startedAt: "2026-01-01T00:00:00Z",
				completedAt: "2026-01-01T01:00:00Z",
				parentSessionId: "session-1",
				parentAgent: "planner",
			}),
		];

		const result = buildDelegationCompactionContext(running, completed);

		expect(result).toContain("## Running Delegations");
		expect(result).toContain("## Recent Completed Delegations");
		expect(result).toContain("del-running");
		expect(result).toContain("del-done");
	});
});

describe("buildTeamCompactionContext", () => {
	it("includes team information", () => {
		const teams: Team[] = [
			{
				id: "team-123",
				projectId: "proj-1",
				projectDir: "/tmp/project",
				issueId: "issue-1",
				discussionStrategyType: "fixedRound",
				status: "running",
				members: [
					{
						agent: "coder",
						role: "primary",
						status: "running",
						retryCount: 0,
						prompt: "",
					},
					{
						agent: "reviewer",
						role: "secondary",
						status: "pending",
						retryCount: 0,
						prompt: "",
					},
				],
				results: {},
				discussionHistory: [],
				startedAt: "2026-01-01T00:00:00Z",
			},
		];

		const result = buildTeamCompactionContext(teams);

		expect(result).toContain("<team-context>");
		expect(result).toContain("</team-context>");
		expect(result).toContain("## Running Teams");
		expect(result).toContain("team-123");
		expect(result).toContain("issue-1");
		expect(result).toContain("coder (primary)");
		expect(result).toContain("reviewer (secondary)");
		expect(result).toContain("team-notification");
		expect(result).toContain("Do NOT poll");
	});

	it("shows discussion round for discussing teams", () => {
		const teams: Team[] = [
			{
				id: "team-123",
				projectId: "proj-1",
				projectDir: "/tmp/project",
				issueId: "issue-1",
				discussionStrategyType: "fixedRound",
				status: "discussing",
				members: [
					{
						agent: "coder",
						role: "primary",
						status: "running",
						retryCount: 0,
						prompt: "",
					},
				],
				results: {},
				discussionHistory: [
					{ round: 1, responses: { coder: "response 1" } },
					{ round: 2, responses: { coder: "response 2" } },
				],
				startedAt: "2026-01-01T00:00:00Z",
			},
		];

		const result = buildTeamCompactionContext(teams);

		expect(result).toContain("Discussion Rounds Completed:");
		expect(result).toContain("2");
	});

	it("includes worktree path when present", () => {
		const teams: Team[] = [
			{
				id: "team-123",
				projectId: "proj-1",
				projectDir: "/tmp/project",
				issueId: "issue-1",
				discussionStrategyType: "fixedRound",
				status: "running",
				members: [
					{
						agent: "coder",
						role: "primary",
						status: "running",
						retryCount: 0,
						prompt: "",
					},
				],
				results: {},
				discussionHistory: [],
				startedAt: "2026-01-01T00:00:00Z",
				worktreePath: "/tmp/team-worktree",
			},
		];

		const result = buildTeamCompactionContext(teams);

		expect(result).toContain("Worktree:");
		expect(result).toContain("/tmp/team-worktree");
	});

	it("handles multiple teams", () => {
		const teams: Team[] = [
			{
				id: "team-1",
				projectId: "proj-1",
				projectDir: "/tmp/project",
				issueId: "issue-1",
				discussionStrategyType: "fixedRound",
				status: "running",
				members: [
					{
						agent: "coder",
						role: "primary",
						status: "running",
						retryCount: 0,
						prompt: "",
					},
				],
				results: {},
				discussionHistory: [],
				startedAt: "2026-01-01T00:00:00Z",
			},
			{
				id: "team-2",
				projectId: "proj-1",
				projectDir: "/tmp/project",
				issueId: "issue-2",
				discussionStrategyType: "fixedRound",
				status: "discussing",
				members: [
					{
						agent: "reviewer",
						role: "primary",
						status: "running",
						retryCount: 0,
						prompt: "",
					},
				],
				results: {},
				discussionHistory: [],
				startedAt: "2026-01-01T00:00:00Z",
			},
		];

		const result = buildTeamCompactionContext(teams);

		expect(result).toContain("team-1");
		expect(result).toContain("team-2");
		expect(result).toContain("issue-1");
		expect(result).toContain("issue-2");
	});
});
