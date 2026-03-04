/**
 * Tests for TeamNotifier
 */

import { describe, test, expect } from "bun:test";
import { TeamNotifier } from "./team-notifier.js";
import { createMockLogger } from "../utils/testing/index.js";
import type { Team } from "./team-manager.js";

const mockLogger = createMockLogger();

describe("TeamNotifier", () => {
	describe("buildTeamNotification", () => {
		test("builds basic XML notification", () => {
			const notifier = new TeamNotifier(mockLogger, undefined as any);

			const team: Team = {
				id: "team-123",
				projectId: "proj-1",
				projectDir: "/tmp/test",
				issueId: "issue-1",
				discussionStrategyType: "fixedRound",
				members: [
					{
						agent: "coder",
						role: "primary",
						status: "completed",
						retryCount: 0,
						prompt: "",
					},
				],
				status: "completed",
				results: {
					coder: {
						agent: "coder",
						result: "Implementation complete",
						completedAt: "2024-01-01T00:00:00Z",
					},
				},
				discussionHistory: [],
				startedAt: "2024-01-01T00:00:00Z",
				completedAt: "2024-01-01T01:00:00Z",
			};

			const notification = notifier.buildTeamNotification(team);

			expect(notification).toContain("<team-notification>");
			expect(notification).toContain("<team-id>team-123</team-id>");
			expect(notification).toContain("<issue>issue-1</issue>");
			expect(notification).toContain("<status>completed</status>");
			expect(notification).toContain('<member agent="coder" role="primary">');
			expect(notification).toContain("Implementation complete");
			expect(notification).toContain("</team-notification>");
		});

		test("includes worktree info when present", () => {
			const notifier = new TeamNotifier(mockLogger, undefined as any);

			const team: Team = {
				id: "team-123",
				projectId: "proj-1",
				projectDir: "/tmp/test",
				issueId: "issue-1",
				discussionStrategyType: "fixedRound",
				members: [
					{
						agent: "coder",
						role: "primary",
						status: "completed",
						retryCount: 0,
						prompt: "",
					},
				],
				status: "completed",
				worktreePath: "/tmp/worktree/issue-1",
				worktreeBranch: "feature/issue-1",
				vcs: "jj",
				results: {},
				discussionHistory: [],
				startedAt: "2024-01-01T00:00:00Z",
				completedAt: "2024-01-01T01:00:00Z",
			};

			const notification = notifier.buildTeamNotification(team);

			expect(notification).toContain("<worktree>");
			expect(notification).toContain("<path>/tmp/worktree/issue-1</path>");
			expect(notification).toContain("<branch>feature/issue-1</branch>");
			expect(notification).toContain("<vcs>jj</vcs>");
			expect(notification).toContain("</worktree>");
		});

		test("includes discussion history when present", () => {
			const notifier = new TeamNotifier(mockLogger, undefined as any);

			const team: Team = {
				id: "team-123",
				projectId: "proj-1",
				projectDir: "/tmp/test",
				issueId: "issue-1",
				discussionStrategyType: "fixedRound",
				members: [
					{
						agent: "coder",
						role: "primary",
						status: "completed",
						retryCount: 0,
						prompt: "",
					},
					{
						agent: "reviewer",
						role: "secondary",
						status: "completed",
						retryCount: 0,
						prompt: "",
					},
				],
				status: "completed",
				results: {},
				discussionHistory: [
					{
						round: 1,
						responses: { coder: "Round 1 coder", reviewer: "Round 1 reviewer" },
					},
					{
						round: 2,
						responses: { coder: "Round 2 coder", reviewer: "Round 2 reviewer" },
					},
				],
				startedAt: "2024-01-01T00:00:00Z",
				completedAt: "2024-01-01T01:00:00Z",
			};

			const notification = notifier.buildTeamNotification(team);

			expect(notification).toContain('<discussion rounds="2">');
			expect(notification).toContain('<round n="1">');
			expect(notification).toContain('<round n="2">');
			expect(notification).toContain("Round 1 coder");
			expect(notification).toContain("Round 2 reviewer");
		});

		test("includes merge instructions for jj worktree", () => {
			const notifier = new TeamNotifier(mockLogger, undefined as any);

			const team: Team = {
				id: "team-123",
				projectId: "proj-1",
				projectDir: "/tmp/test",
				issueId: "issue-1",
				discussionStrategyType: "fixedRound",
				members: [],
				status: "completed",
				worktreePath: "/tmp/worktree",
				worktreeBranch: "feature-branch",
				vcs: "jj",
				results: {},
				discussionHistory: [],
				startedAt: "2024-01-01T00:00:00Z",
			};

			const notification = notifier.buildTeamNotification(team);

			expect(notification).toContain("<merge-instructions>");
			expect(notification).toContain("jj diff");
			expect(notification).toContain("jj squash");
			expect(notification).toContain("jj workspace forget");
		});

		test("includes merge instructions for git worktree", () => {
			const notifier = new TeamNotifier(mockLogger, undefined as any);

			const team: Team = {
				id: "team-123",
				projectId: "proj-1",
				projectDir: "/tmp/test",
				issueId: "issue-1",
				discussionStrategyType: "fixedRound",
				members: [],
				status: "completed",
				worktreePath: "/tmp/worktree",
				worktreeBranch: "feature-branch",
				vcs: "git",
				results: {},
				discussionHistory: [],
				startedAt: "2024-01-01T00:00:00Z",
			};

			const notification = notifier.buildTeamNotification(team);

			expect(notification).toContain("<merge-instructions>");
			expect(notification).toContain("git diff");
			expect(notification).toContain("git merge");
			expect(notification).toContain("git worktree remove");
		});
	});

	describe("XML escaping", () => {
		test("escapes special characters in team data", () => {
			const notifier = new TeamNotifier(mockLogger, undefined as any);

			const team: Team = {
				id: "team-<script>alert('xss')</script>",
				projectId: "proj-1",
				projectDir: "/tmp/test",
				issueId: "issue-with-&-ampersand",
				discussionStrategyType: "fixedRound",
				members: [
					{
						agent: 'agent-with-"quotes"',
						role: "primary",
						status: "completed",
						retryCount: 0,
						prompt: "",
					},
				],
				status: "completed",
				results: {
					'agent-with-"quotes"': {
						agent: 'agent-with-"quotes"',
						result: "Result with <html> tags & special chars",
						completedAt: "2024-01-01T00:00:00Z",
					},
				},
				discussionHistory: [],
				startedAt: "2024-01-01T00:00:00Z",
			};

			const notification = notifier.buildTeamNotification(team);

			// Verify special characters are escaped
			expect(notification).toContain("&lt;script&gt;");
			expect(notification).toContain("&amp;-ampersand");
			expect(notification).toContain("&quot;quotes&quot;");
			expect(notification).toContain("&lt;html&gt;");
			// Verify raw special characters are NOT present
			expect(notification).not.toContain("<script>");
			expect(notification).not.toContain("&-ampersand");
		});

		test("escapes discussion responses", () => {
			const notifier = new TeamNotifier(mockLogger, undefined as any);

			const team: Team = {
				id: "team-123",
				projectId: "proj-1",
				projectDir: "/tmp/test",
				issueId: "issue-1",
				discussionStrategyType: "fixedRound",
				members: [
					{
						agent: "coder",
						role: "primary",
						status: "completed",
						retryCount: 0,
						prompt: "",
					},
				],
				status: "completed",
				results: {},
				discussionHistory: [
					{
						round: 1,
						responses: { coder: "Response with <code> and & symbols" },
					},
				],
				startedAt: "2024-01-01T00:00:00Z",
			};

			const notification = notifier.buildTeamNotification(team);

			expect(notification).toContain("&lt;code&gt;");
			expect(notification).toContain("&amp; symbols");
		});
	});

	describe("getMergeInstructions", () => {
		test("generates jj instructions", () => {
			const notifier = new TeamNotifier(mockLogger, undefined as any);

			const team: Team = {
				id: "team-123",
				projectId: "proj-1",
				projectDir: "/tmp/test",
				issueId: "issue-1",
				discussionStrategyType: "fixedRound",
				members: [],
				status: "completed",
				worktreePath: "/tmp/worktree",
				worktreeBranch: "my-branch",
				vcs: "jj",
				results: {},
				discussionHistory: [],
				startedAt: "2024-01-01T00:00:00Z",
			};

			const instructions = notifier.getMergeInstructions(team);

			expect(instructions).toContain("jj diff --from main --to my-branch@");
			expect(instructions).toContain("jj squash --from my-branch@");
			expect(instructions).toContain("jj workspace forget my-branch");
		});

		test("generates git instructions", () => {
			const notifier = new TeamNotifier(mockLogger, undefined as any);

			const team: Team = {
				id: "team-123",
				projectId: "proj-1",
				projectDir: "/tmp/test",
				issueId: "issue-1",
				discussionStrategyType: "fixedRound",
				members: [],
				status: "completed",
				worktreePath: "/tmp/worktree",
				worktreeBranch: "my-branch",
				vcs: "git",
				results: {},
				discussionHistory: [],
				startedAt: "2024-01-01T00:00:00Z",
			};

			const instructions = notifier.getMergeInstructions(team);

			expect(instructions).toContain("git diff main..my-branch");
			expect(instructions).toContain("git merge my-branch");
			expect(instructions).toContain("git worktree remove /tmp/worktree");
			expect(instructions).toContain("git branch -d my-branch");
		});

		test("uses issueId as branch when worktreeBranch not set", () => {
			const notifier = new TeamNotifier(mockLogger, undefined as any);

			const team: Team = {
				id: "team-123",
				projectId: "proj-1",
				projectDir: "/tmp/test",
				issueId: "issue-123",
				discussionStrategyType: "fixedRound",
				members: [],
				status: "completed",
				worktreePath: "/tmp/worktree",
				vcs: "jj",
				results: {},
				discussionHistory: [],
				startedAt: "2024-01-01T00:00:00Z",
			};

			const instructions = notifier.getMergeInstructions(team);

			expect(instructions).toContain("issue-123");
		});
	});

	describe("Non-isolated teams", () => {
		test("notification excludes worktree info when not isolated", () => {
			const notifier = new TeamNotifier(mockLogger, undefined as any);

			const team: Team = {
				id: "team-non-isolated",
				projectId: "proj-1",
				projectDir: "/tmp/test",
				issueId: "issue-research",
				discussionStrategyType: "fixedRound",
				members: [
					{
						agent: "researcher",
						role: "primary",
						status: "completed",
						retryCount: 0,
						prompt: "",
					},
				],
				status: "completed",
				// No worktreePath, worktreeBranch, or vcs - this is non-isolated
				results: {
					researcher: {
						agent: "researcher",
						result: "Research findings complete",
						completedAt: "2024-01-01T00:00:00Z",
					},
				},
				discussionHistory: [],
				startedAt: "2024-01-01T00:00:00Z",
				completedAt: "2024-01-01T01:00:00Z",
			};

			const notification = notifier.buildTeamNotification(team);

			// Should NOT contain worktree-related elements
			expect(notification).not.toContain("<worktree>");
			expect(notification).not.toContain("<merge-instructions>");
			expect(notification).not.toContain("<path>");
			expect(notification).not.toContain("<branch>");
			expect(notification).not.toContain("<vcs>");

			// Should still contain basic notification structure
			expect(notification).toContain("<team-notification>");
			expect(notification).toContain("<team-id>team-non-isolated</team-id>");
			expect(notification).toContain("<issue>issue-research</issue>");
			expect(notification).toContain("<status>completed</status>");
			expect(notification).toContain("Research findings complete");
		});

		test("getMergeInstructions returns null for non-isolated team", () => {
			const notifier = new TeamNotifier(mockLogger, undefined as any);

			const team: Team = {
				id: "team-no-worktree",
				projectId: "proj-1",
				projectDir: "/tmp/test",
				issueId: "issue-1",
				discussionStrategyType: "fixedRound",
				members: [],
				status: "completed",
				// No worktreePath or vcs
				results: {},
				discussionHistory: [],
				startedAt: "2024-01-01T00:00:00Z",
			};

			const instructions = notifier.getMergeInstructions(team);

			expect(instructions).toBeNull();
		});

		test("foreground non-isolated team notification has results inline", () => {
			const notifier = new TeamNotifier(mockLogger, undefined as any);

			const team: Team = {
				id: "team-fg-non-isolated",
				projectId: "proj-1",
				projectDir: "/tmp/test",
				issueId: "issue-analysis",
				discussionStrategyType: "fixedRound",
				members: [
					{
						agent: "analyst",
						role: "primary",
						status: "completed",
						retryCount: 0,
						prompt: "",
					},
				],
				status: "completed",
				foreground: true,
				results: {
					analyst: {
						agent: "analyst",
						result: "Analysis complete: 5 recommendations",
						completedAt: "2024-01-01T00:00:00Z",
					},
				},
				discussionHistory: [],
				startedAt: "2024-01-01T00:00:00Z",
				completedAt: "2024-01-01T01:00:00Z",
			};

			const notification = notifier.buildTeamNotification(team);

			// Results should be included
			expect(notification).toContain("Analysis complete: 5 recommendations");
			// No worktree info
			expect(notification).not.toContain("<worktree>");
			expect(notification).not.toContain("<merge-instructions>");
		});
	});

	describe("Multi-agent team notifications", () => {
		test("2-agent team notification includes both members", () => {
			const notifier = new TeamNotifier(mockLogger, undefined as any);

			const team: Team = {
				id: "team-2-agent",
				projectId: "proj-1",
				projectDir: "/tmp/test",
				issueId: "issue-1",
				discussionStrategyType: "fixedRound",
				members: [
					{
						agent: "implementer",
						role: "primary",
						status: "completed",
						retryCount: 0,
						prompt: "",
					},
					{
						agent: "reviewer",
						role: "secondary",
						status: "completed",
						retryCount: 0,
						prompt: "",
					},
				],
				status: "completed",
				results: {
					implementer: {
						agent: "implementer",
						result: "Feature implemented",
						completedAt: "2024-01-01T00:00:00Z",
					},
					reviewer: {
						agent: "reviewer",
						result: "Code review passed",
						completedAt: "2024-01-01T00:00:00Z",
					},
				},
				discussionHistory: [
					{
						round: 1,
						responses: {
							implementer: "Addressed review comments",
							reviewer: "Changes look good",
						},
					},
				],
				startedAt: "2024-01-01T00:00:00Z",
				completedAt: "2024-01-01T01:00:00Z",
			};

			const notification = notifier.buildTeamNotification(team);

			// Both members should be present
			expect(notification).toContain(
				'<member agent="implementer" role="primary">',
			);
			expect(notification).toContain(
				'<member agent="reviewer" role="secondary">',
			);
			// Both results should be present
			expect(notification).toContain("Feature implemented");
			expect(notification).toContain("Code review passed");
			// Discussion should be present
			expect(notification).toContain('<discussion rounds="1">');
			expect(notification).toContain("Addressed review comments");
			expect(notification).toContain("Changes look good");
		});

		test("3-agent team notification includes devil's advocate role", () => {
			const notifier = new TeamNotifier(mockLogger, undefined as any);

			const team: Team = {
				id: "team-3-agent",
				projectId: "proj-1",
				projectDir: "/tmp/test",
				issueId: "issue-1",
				discussionStrategyType: "fixedRound",
				members: [
					{
						agent: "typescript-expert",
						role: "primary",
						status: "completed",
						retryCount: 0,
						prompt: "",
					},
					{
						agent: "code-reviewer",
						role: "secondary",
						status: "completed",
						retryCount: 0,
						prompt: "",
					},
					{
						agent: "security-expert",
						role: "devilsAdvocate",
						status: "completed",
						retryCount: 0,
						prompt: "",
					},
				],
				status: "completed",
				results: {
					"typescript-expert": {
						agent: "typescript-expert",
						result: "Auth flow implemented",
						completedAt: "2024-01-01T00:00:00Z",
					},
					"code-reviewer": {
						agent: "code-reviewer",
						result: "Code structure approved",
						completedAt: "2024-01-01T00:00:00Z",
					},
					"security-expert": {
						agent: "security-expert",
						result:
							"## Concerns\n- Input validation\n\n## Verdict\nApproved with changes",
						completedAt: "2024-01-01T00:00:00Z",
					},
				},
				discussionHistory: [
					{
						round: 1,
						responses: {
							"typescript-expert": "Initial implementation",
							"code-reviewer": "Structure looks good",
							"security-expert": "Security concerns raised",
						},
					},
					{
						round: 2,
						responses: {
							"typescript-expert": "Security fixes applied",
							"code-reviewer": "Fixes look correct",
							"security-expert": "Concerns addressed",
						},
					},
				],
				startedAt: "2024-01-01T00:00:00Z",
				completedAt: "2024-01-01T01:00:00Z",
			};

			const notification = notifier.buildTeamNotification(team);

			// All three members should be present with correct roles
			expect(notification).toContain(
				'<member agent="typescript-expert" role="primary">',
			);
			expect(notification).toContain(
				'<member agent="code-reviewer" role="secondary">',
			);
			expect(notification).toContain(
				'<member agent="security-expert" role="devilsAdvocate">',
			);

			// All results should be present
			expect(notification).toContain("Auth flow implemented");
			expect(notification).toContain("Code structure approved");
			expect(notification).toContain("Concerns");
			expect(notification).toContain("Verdict");

			// Both discussion rounds should be present
			expect(notification).toContain('<discussion rounds="2">');
			expect(notification).toContain('<round n="1">');
			expect(notification).toContain('<round n="2">');
			expect(notification).toContain("Security concerns raised");
			expect(notification).toContain("Concerns addressed");
		});

		test("notification synthesizes all agent contributions", () => {
			const notifier = new TeamNotifier(mockLogger, undefined as any);

			const team: Team = {
				id: "team-synthesis",
				projectId: "proj-1",
				projectDir: "/tmp/test",
				issueId: "issue-1",
				discussionStrategyType: "fixedRound",
				members: [
					{
						agent: "primary",
						role: "primary",
						status: "completed",
						retryCount: 0,
						prompt: "",
					},
					{
						agent: "secondary",
						role: "secondary",
						status: "completed",
						retryCount: 0,
						prompt: "",
					},
					{
						agent: "critic",
						role: "devilsAdvocate",
						status: "completed",
						retryCount: 0,
						prompt: "",
					},
				],
				status: "completed",
				results: {
					primary: {
						agent: "primary",
						result: "Primary contribution",
						completedAt: "2024-01-01T00:00:00Z",
					},
					secondary: {
						agent: "secondary",
						result: "Secondary contribution",
						completedAt: "2024-01-01T00:00:00Z",
					},
					critic: {
						agent: "critic",
						result: "Critical contribution",
						completedAt: "2024-01-01T00:00:00Z",
					},
				},
				discussionHistory: [
					{
						round: 1,
						responses: {
							primary: "Primary discussion",
							secondary: "Secondary discussion",
							critic: "Critical discussion",
						},
					},
				],
				startedAt: "2024-01-01T00:00:00Z",
				completedAt: "2024-01-01T01:00:00Z",
			};

			const notification = notifier.buildTeamNotification(team);

			// Count occurrences of each agent's contributions
			const primaryCount = (notification.match(/primary/gi) || []).length;
			const secondaryCount = (notification.match(/secondary/gi) || []).length;
			const criticCount = (notification.match(/critic/gi) || []).length;

			// Each agent should appear multiple times (in member tag, result, and discussion)
			expect(primaryCount).toBeGreaterThanOrEqual(3);
			expect(secondaryCount).toBeGreaterThanOrEqual(3);
			expect(criticCount).toBeGreaterThanOrEqual(3);
		});
	});
});
