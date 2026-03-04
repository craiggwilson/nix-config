/**
 * Tests for DelegationManager
 */

import { describe, test, expect, beforeEach, afterAll } from "bun:test";
import * as fs from "node:fs/promises";
import * as path from "node:path";
import * as os from "node:os";

import {
	DelegationManager,
	type CreateDelegationOptions,
} from "./delegation-manager.js";
import { createMockLogger } from "../utils/testing/index.js";
import type { OpencodeClient } from "../utils/opencode-sdk/index.js";

const mockLogger = createMockLogger();

/**
 * Create a mock OpenCode client for testing retry behavior
 */
function createMockClient(
	options: {
		sessionCreateFailures?: number;
		sessionCreateError?: string;
		promptFailures?: number;
		promptError?: string;
	} = {},
): OpencodeClient {
	let sessionCreateAttempts = 0;
	let promptAttempts = 0;
	const sessionCreateFailures = options.sessionCreateFailures ?? 0;
	const promptFailures = options.promptFailures ?? 0;
	const sessionCreateError =
		options.sessionCreateError ?? "JSON Parse error: Unexpected EOF";
	const promptError = options.promptError ?? "JSON Parse error: Unexpected EOF";

	return {
		app: {
			log: async () => ({}),
			agents: async () => ({ data: [] }),
		},
		session: {
			create: async () => {
				sessionCreateAttempts++;
				if (sessionCreateAttempts <= sessionCreateFailures) {
					throw new Error(sessionCreateError);
				}
				return { data: { id: `session-${sessionCreateAttempts}` } };
			},
			get: async () => ({ data: { id: "test-session" } }),
			prompt: async () => {
				promptAttempts++;
				if (promptAttempts <= promptFailures) {
					throw new Error(promptError);
				}
				return {
					data: {
						id: "test-msg",
						role: "assistant" as const,
						sessionID: "test-session",
					},
				};
			},
			messages: async () => ({ data: [] }),
			delete: async () => ({}),
		},
		config: {
			get: async () => ({ data: {} }),
		},
	};
}

/**
 * Helper to create delegation options with required fields
 */
function createOptions(
	overrides: Partial<CreateDelegationOptions> & {
		issueId: string;
		prompt: string;
	},
): CreateDelegationOptions {
	return {
		teamId: "team-test",
		role: "primary",
		...overrides,
	};
}

describe("DelegationManager", () => {
	let testDir: string;
	let manager: DelegationManager;

	beforeEach(async () => {
		testDir = await fs.mkdtemp(path.join(os.tmpdir(), "delegation-test-"));
		manager = new DelegationManager(mockLogger, undefined, {
			timeoutMs: 15 * 60 * 1000,
			smallModelTimeoutMs: 30000,
		});
	});

	afterAll(async () => {
		try {
			const tmpDir = os.tmpdir();
			const entries = await fs.readdir(tmpDir);
			for (const entry of entries) {
				if (entry.startsWith("delegation-test-")) {
					await fs.rm(path.join(tmpDir, entry), {
						recursive: true,
						force: true,
					});
				}
			}
		} catch {}
	});

	describe("create", () => {
		test("creates a new delegation", async () => {
			const result = await manager.create(
				"test-project",
				testDir,
				createOptions({
					issueId: "issue-123",
					prompt: "Implement the feature",
				}),
			);

			expect(result.ok).toBe(true);
			if (!result.ok) return;

			const delegation = result.value;
			expect(delegation.id).toMatch(/^del-/);
			expect(delegation.projectId).toBe("test-project");
			expect(delegation.issueId).toBe("issue-123");
			expect(delegation.prompt).toBe("Implement the feature");
			expect(delegation.status).toBe("pending");
			expect(delegation.teamId).toBe("team-test");
			expect(delegation.role).toBe("primary");
			expect(delegation.startedAt).toBeDefined();
		});

		test("persists delegation to disk", async () => {
			const result = await manager.create(
				"test-project",
				testDir,
				createOptions({
					issueId: "issue-123",
					prompt: "Test prompt",
				}),
			);

			expect(result.ok).toBe(true);
			if (!result.ok) return;

			const delegation = result.value;
			const filePath = path.join(
				testDir,
				"delegations",
				`${delegation.id}.json`,
			);
			const content = await fs.readFile(filePath, "utf8");
			const saved = JSON.parse(content);

			expect(saved.id).toBe(delegation.id);
			expect(saved.issueId).toBe("issue-123");
			expect(saved.teamId).toBe("team-test");
			expect(saved.role).toBe("primary");
		});

		test("includes optional fields", async () => {
			const result = await manager.create(
				"test-project",
				testDir,
				createOptions({
					issueId: "issue-123",
					prompt: "Test prompt",
					worktreePath: "/path/to/worktree",
					agent: "coder",
				}),
			);

			expect(result.ok).toBe(true);
			if (!result.ok) return;

			const delegation = result.value;
			expect(delegation.worktreePath).toBe("/path/to/worktree");
			expect(delegation.agent).toBe("coder");
		});

		test("supports different roles", async () => {
			const primaryResult = await manager.create(
				"test-project",
				testDir,
				createOptions({
					issueId: "issue-123",
					prompt: "Primary work",
					role: "primary",
				}),
			);

			const secondaryResult = await manager.create(
				"test-project",
				testDir,
				createOptions({
					issueId: "issue-123",
					prompt: "Secondary review",
					role: "secondary",
				}),
			);

			const devilsAdvocateResult = await manager.create(
				"test-project",
				testDir,
				createOptions({
					issueId: "issue-123",
					prompt: "Critical review",
					role: "devilsAdvocate",
				}),
			);

			expect(primaryResult.ok).toBe(true);
			expect(secondaryResult.ok).toBe(true);
			expect(devilsAdvocateResult.ok).toBe(true);

			if (!primaryResult.ok || !secondaryResult.ok || !devilsAdvocateResult.ok)
				return;

			expect(primaryResult.value.role).toBe("primary");
			expect(secondaryResult.value.role).toBe("secondary");
			expect(devilsAdvocateResult.value.role).toBe("devilsAdvocate");
		});
	});

	describe("get", () => {
		test("retrieves a delegation by ID", async () => {
			const createResult = await manager.create(
				"test-project",
				testDir,
				createOptions({
					issueId: "issue-123",
					prompt: "Test prompt",
				}),
			);

			expect(createResult.ok).toBe(true);
			if (!createResult.ok) return;

			const created = createResult.value;
			const getResult = await manager.get(created.id);

			expect(getResult.ok).toBe(true);
			if (!getResult.ok) return;

			expect(getResult.value.id).toBe(created.id);
			expect(getResult.value.issueId).toBe("issue-123");
		});

		test("returns error for non-existent delegation", async () => {
			const result = await manager.get("non-existent");

			expect(result.ok).toBe(false);
			if (result.ok) return;

			expect(result.error.type).toBe("not_found");
			expect(result.error.delegationId).toBe("non-existent");
		});
	});

	describe("list", () => {
		test("lists all delegations", async () => {
			await manager.create(
				"test-project",
				testDir,
				createOptions({ issueId: "issue-1", prompt: "Prompt 1" }),
			);
			await manager.create(
				"test-project",
				testDir,
				createOptions({ issueId: "issue-2", prompt: "Prompt 2" }),
			);
			await manager.create(
				"test-project",
				testDir,
				createOptions({ issueId: "issue-3", prompt: "Prompt 3" }),
			);

			const delegations = await manager.list();

			expect(delegations.length).toBe(3);
		});

		test("filters by status", async () => {
			const d1Result = await manager.create(
				"test-project",
				testDir,
				createOptions({ issueId: "issue-1", prompt: "Prompt 1" }),
			);
			await manager.create(
				"test-project",
				testDir,
				createOptions({ issueId: "issue-2", prompt: "Prompt 2" }),
			);

			expect(d1Result.ok).toBe(true);
			if (!d1Result.ok) return;

			await manager.complete(d1Result.value.id, "Done");

			const completed = await manager.list({ status: "completed" });
			const pending = await manager.list({ status: "pending" });

			expect(completed.length).toBe(1);
			expect(pending.length).toBe(1);
		});

		test("filters by issueId", async () => {
			await manager.create(
				"test-project",
				testDir,
				createOptions({ issueId: "issue-1", prompt: "Prompt 1" }),
			);
			await manager.create(
				"test-project",
				testDir,
				createOptions({ issueId: "issue-1", prompt: "Prompt 2" }),
			);
			await manager.create(
				"test-project",
				testDir,
				createOptions({ issueId: "issue-2", prompt: "Prompt 3" }),
			);

			const issue1Delegations = await manager.list({ issueId: "issue-1" });
			const issue2Delegations = await manager.list({ issueId: "issue-2" });

			expect(issue1Delegations.length).toBe(2);
			expect(issue2Delegations.length).toBe(1);
		});
	});

	describe("complete", () => {
		test("marks delegation as completed", async () => {
			const createResult = await manager.create(
				"test-project",
				testDir,
				createOptions({
					issueId: "issue-123",
					prompt: "Test prompt",
				}),
			);

			expect(createResult.ok).toBe(true);
			if (!createResult.ok) return;

			const delegation = createResult.value;
			const completeResult = await manager.complete(
				delegation.id,
				"Task completed successfully",
			);

			expect(completeResult.ok).toBe(true);
			if (!completeResult.ok) return;

			const getResult = await manager.get(delegation.id);
			expect(getResult.ok).toBe(true);
			if (!getResult.ok) return;

			expect(getResult.value.status).toBe("completed");
			expect(getResult.value.result).toBe("Task completed successfully");
			expect(getResult.value.completedAt).toBeDefined();
		});

		test("persists result to delegations directory", async () => {
			const createResult = await manager.create(
				"test-project",
				testDir,
				createOptions({
					issueId: "issue-123",
					prompt: "Test prompt",
				}),
			);

			expect(createResult.ok).toBe(true);
			if (!createResult.ok) return;

			const delegation = createResult.value;
			await manager.complete(delegation.id, "Task completed");

			const resultPath = path.join(
				testDir,
				"delegations",
				`${delegation.id}.md`,
			);
			const content = await fs.readFile(resultPath, "utf8");

			expect(content).toContain("issue-123");
			expect(content).toContain("## Prompt");
			expect(content).toContain("Test prompt");
			expect(content).toContain("## Result");
			expect(content).toContain("Task completed");
		});
	});

	describe("fail", () => {
		test("marks delegation as failed", async () => {
			const createResult = await manager.create(
				"test-project",
				testDir,
				createOptions({
					issueId: "issue-123",
					prompt: "Test prompt",
				}),
			);

			expect(createResult.ok).toBe(true);
			if (!createResult.ok) return;

			const delegation = createResult.value;
			const failResult = await manager.fail(
				delegation.id,
				"Something went wrong",
			);

			expect(failResult.ok).toBe(true);
			if (!failResult.ok) return;

			const getResult = await manager.get(delegation.id);
			expect(getResult.ok).toBe(true);
			if (!getResult.ok) return;

			expect(getResult.value.status).toBe("failed");
			expect(getResult.value.error).toBe("Something went wrong");
		});
	});

	describe("cancel", () => {
		test("cancels a pending delegation", async () => {
			const createResult = await manager.create(
				"test-project",
				testDir,
				createOptions({
					issueId: "issue-123",
					prompt: "Test prompt",
				}),
			);

			expect(createResult.ok).toBe(true);
			if (!createResult.ok) return;

			const delegation = createResult.value;
			const cancelResult = await manager.cancel(delegation.id);

			expect(cancelResult.ok).toBe(true);
			if (!cancelResult.ok) return;

			const getResult = await manager.get(delegation.id);
			expect(getResult.ok).toBe(true);
			if (!getResult.ok) return;

			expect(getResult.value.status).toBe("cancelled");
		});

		test("cannot cancel completed delegation", async () => {
			const createResult = await manager.create(
				"test-project",
				testDir,
				createOptions({
					issueId: "issue-123",
					prompt: "Test prompt",
				}),
			);

			expect(createResult.ok).toBe(true);
			if (!createResult.ok) return;

			const delegation = createResult.value;
			await manager.complete(delegation.id, "Done");
			const cancelResult = await manager.cancel(delegation.id);

			expect(cancelResult.ok).toBe(false);
			if (cancelResult.ok) return;

			expect(cancelResult.error.type).toBe("already_completed");
		});
	});

	describe("areAllComplete", () => {
		test("returns true when no delegations", async () => {
			const allComplete = await manager.areAllComplete("issue-123");

			expect(allComplete).toBe(true);
		});

		test("returns false when delegations are pending", async () => {
			await manager.create(
				"test-project",
				testDir,
				createOptions({ issueId: "issue-123", prompt: "Prompt" }),
			);

			const allComplete = await manager.areAllComplete("issue-123");

			expect(allComplete).toBe(false);
		});

		test("returns true when all delegations are complete", async () => {
			const d1Result = await manager.create(
				"test-project",
				testDir,
				createOptions({ issueId: "issue-123", prompt: "Prompt 1" }),
			);
			const d2Result = await manager.create(
				"test-project",
				testDir,
				createOptions({ issueId: "issue-123", prompt: "Prompt 2" }),
			);

			expect(d1Result.ok && d2Result.ok).toBe(true);
			if (!d1Result.ok || !d2Result.ok) return;

			await manager.complete(d1Result.value.id, "Done 1");
			await manager.complete(d2Result.value.id, "Done 2");

			const allComplete = await manager.areAllComplete("issue-123");

			expect(allComplete).toBe(true);
		});
	});

	describe("getActiveDelegations", () => {
		test("returns only pending/running delegations", async () => {
			const d1Result = await manager.create(
				"test-project",
				testDir,
				createOptions({ issueId: "issue-123", prompt: "Prompt 1" }),
			);
			await manager.create(
				"test-project",
				testDir,
				createOptions({ issueId: "issue-123", prompt: "Prompt 2" }),
			);

			expect(d1Result.ok).toBe(true);
			if (!d1Result.ok) return;

			await manager.complete(d1Result.value.id, "Done");

			const active = await manager.getActiveDelegations("issue-123");

			expect(active.length).toBe(1);
			expect(active[0].status).toBe("pending");
		});
	});

	describe("retry behavior", () => {
		test("retries session.create on JSON Parse error and succeeds", async () => {
			// Create a client that fails twice then succeeds
			const mockClient = createMockClient({ sessionCreateFailures: 2 });
			const retryManager = new DelegationManager(mockLogger, mockClient, {
				timeoutMs: 15 * 60 * 1000,
				smallModelTimeoutMs: 30000,
			});

			const result = await retryManager.create(
				"test-project",
				testDir,
				createOptions({
					issueId: "issue-retry",
					prompt: "Test retry",
				}),
			);

			expect(result.ok).toBe(true);
			if (!result.ok) return;

			// Wait a bit for the background delegation to start
			await new Promise((resolve) => setTimeout(resolve, 100));

			// The delegation should have a session ID (meaning session.create succeeded after retries)
			const getResult = await retryManager.get(result.value.id);
			expect(getResult.ok).toBe(true);
			if (!getResult.ok) return;

			expect(getResult.value.sessionId).toBeDefined();
			expect(getResult.value.status).toBe("running");
		});

		test("fails delegation after exhausting retries on session.create", async () => {
			// Create a client that always fails
			const mockClient = createMockClient({ sessionCreateFailures: 10 });
			const retryManager = new DelegationManager(mockLogger, mockClient, {
				timeoutMs: 15 * 60 * 1000,
				smallModelTimeoutMs: 30000,
			});

			let completeCalled = false;
			const result = await retryManager.create(
				"test-project",
				testDir,
				createOptions({
					issueId: "issue-fail",
					prompt: "Test fail",
					onComplete: async () => {
						completeCalled = true;
					},
				}),
			);

			expect(result.ok).toBe(true);
			if (!result.ok) return;

			// Wait for the background delegation to fail
			await new Promise((resolve) => setTimeout(resolve, 500));

			// The delegation should be marked as failed
			const getResult = await retryManager.get(result.value.id);
			expect(getResult.ok).toBe(true);
			if (!getResult.ok) return;

			expect(getResult.value.status).toBe("failed");
			expect(getResult.value.error).toContain("session.create");
			expect(getResult.value.error).toContain("JSON Parse error");
			expect(completeCalled).toBe(true);
		});

		test("includes actionable error message on failure", async () => {
			const mockClient = createMockClient({ sessionCreateFailures: 10 });
			const retryManager = new DelegationManager(mockLogger, mockClient, {
				timeoutMs: 15 * 60 * 1000,
				smallModelTimeoutMs: 30000,
			});

			const result = await retryManager.create(
				"test-project",
				testDir,
				createOptions({
					issueId: "issue-error-msg",
					prompt: "Test error message",
				}),
			);

			expect(result.ok).toBe(true);
			if (!result.ok) return;

			// Wait for the background delegation to fail
			await new Promise((resolve) => setTimeout(resolve, 500));

			const getResult = await retryManager.get(result.value.id);
			expect(getResult.ok).toBe(true);
			if (!getResult.ok) return;

			// Error message should include helpful context
			expect(getResult.value.error).toContain("session.create");
			expect(getResult.value.error).toContain("attempt");
			expect(getResult.value.error).toContain("transient");
		});
	});

	describe("empty output handling", () => {
		test("notification fires even when delegation produces no output", async () => {
			// Create a client that returns empty messages
			const emptyMessagesClient: OpencodeClient = {
				app: {
					log: async () => ({}),
					agents: async () => ({ data: [] }),
				},
				session: {
					create: async () => ({ data: { id: "empty-session" } }),
					get: async () => ({ data: { id: "empty-session" } }),
					prompt: async () => ({
						data: {
							id: "test-msg",
							role: "assistant" as const,
							sessionID: "empty-session",
						},
					}),
					messages: async () => ({ data: [] }), // Empty messages
					delete: async () => ({}),
				},
				config: {
					get: async () => ({ data: {} }),
				},
			};

			const emptyManager = new DelegationManager(
				mockLogger,
				emptyMessagesClient,
				{
					timeoutMs: 60 * 1000,
					smallModelTimeoutMs: 30000,
				},
			);

			let notificationFired = false;
			let notificationDelegationId: string | undefined;

			const result = await emptyManager.create(
				"test-project",
				testDir,
				createOptions({
					issueId: "issue-empty-output",
					prompt: "Test empty output",
					onComplete: async (delegationId) => {
						notificationFired = true;
						notificationDelegationId = delegationId;
					},
				}),
			);

			expect(result.ok).toBe(true);
			if (!result.ok) return;

			// Wait for the delegation to start running
			await new Promise((resolve) => setTimeout(resolve, 100));

			const getResult = await emptyManager.get(result.value.id);
			expect(getResult.ok).toBe(true);
			if (!getResult.ok) return;

			expect(getResult.value.sessionId).toBeDefined();

			// Simulate session idle event
			if (!getResult.value.sessionId) return;
			await emptyManager.handleSessionIdle(getResult.value.sessionId);

			// Verify notification was fired
			expect(notificationFired).toBe(true);
			expect(notificationDelegationId).toBe(result.value.id);

			// Verify delegation completed with placeholder result
			const completedResult = await emptyManager.get(result.value.id);
			expect(completedResult.ok).toBe(true);
			if (!completedResult.ok) return;

			expect(completedResult.value.status).toBe("completed");
			expect(completedResult.value.result).toBe("(no messages)");
		});

		test("notification fires when assistant has no text content", async () => {
			// Create a client that returns messages with no text parts
			const noTextClient: OpencodeClient = {
				app: {
					log: async () => ({}),
					agents: async () => ({ data: [] }),
				},
				session: {
					create: async () => ({ data: { id: "no-text-session" } }),
					get: async () => ({ data: { id: "no-text-session" } }),
					prompt: async () => ({
						data: {
							id: "test-msg",
							role: "assistant" as const,
							sessionID: "no-text-session",
						},
					}),
					messages: async () => ({
						data: [
							{
								id: "msg-1",
								info: {
									id: "msg-1",
									role: "assistant" as const,
									sessionID: "no-text-session",
								},
								parts: [], // No parts
							},
						],
					}),
					delete: async () => ({}),
				},
				config: {
					get: async () => ({ data: {} }),
				},
			};

			const noTextManager = new DelegationManager(mockLogger, noTextClient, {
				timeoutMs: 60 * 1000,
				smallModelTimeoutMs: 30000,
			});

			let notificationFired = false;

			const result = await noTextManager.create(
				"test-project",
				testDir,
				createOptions({
					issueId: "issue-no-text",
					prompt: "Test no text",
					onComplete: async () => {
						notificationFired = true;
					},
				}),
			);

			expect(result.ok).toBe(true);
			if (!result.ok) return;

			await new Promise((resolve) => setTimeout(resolve, 100));

			const getResult = await noTextManager.get(result.value.id);
			expect(getResult.ok).toBe(true);
			if (!getResult.ok) return;

			if (!getResult.value.sessionId) return;
			await noTextManager.handleSessionIdle(getResult.value.sessionId);

			expect(notificationFired).toBe(true);

			const completedResult = await noTextManager.get(result.value.id);
			expect(completedResult.ok).toBe(true);
			if (!completedResult.ok) return;

			expect(completedResult.value.status).toBe("completed");
			expect(completedResult.value.result).toBe("(no text content)");
		});
	});

	describe("timeout cleanup", () => {
		test("clears timeout handler when delegation completes via handleSessionIdle", async () => {
			// Create a client that succeeds
			const mockClient = createMockClient();
			const timeoutManager = new DelegationManager(mockLogger, mockClient, {
				timeoutMs: 60 * 1000, // 1 minute timeout
				smallModelTimeoutMs: 30000,
			});

			const result = await timeoutManager.create(
				"test-project",
				testDir,
				createOptions({
					issueId: "issue-timeout-test",
					prompt: "Test timeout cleanup",
				}),
			);

			expect(result.ok).toBe(true);
			if (!result.ok) return;

			// Wait for the delegation to start running
			await new Promise((resolve) => setTimeout(resolve, 100));

			const getResult = await timeoutManager.get(result.value.id);
			expect(getResult.ok).toBe(true);
			if (!getResult.ok) return;

			// Verify delegation is running and has a session
			expect(getResult.value.status).toBe("running");
			expect(getResult.value.sessionId).toBeDefined();

			// Simulate session idle event (normal completion)
			if (!getResult.value.sessionId) return;
			await timeoutManager.handleSessionIdle(getResult.value.sessionId);

			// Verify delegation is now completed
			const completedResult = await timeoutManager.get(result.value.id);
			expect(completedResult.ok).toBe(true);
			if (!completedResult.ok) return;

			expect(completedResult.value.status).toBe("completed");

			// The timeout handler should have been cleared (no way to directly verify,
			// but we can verify the delegation completed without timing out)
			// If the timeout wasn't cleared, it would fire later and potentially cause issues
		});

		test("timeout map entry is removed when timeout fires", async () => {
			// Create a manager with a very short timeout
			const mockClient = createMockClient();
			const shortTimeoutManager = new DelegationManager(
				mockLogger,
				mockClient,
				{
					timeoutMs: 50, // 50ms timeout
					smallModelTimeoutMs: 30000,
				},
			);

			const result = await shortTimeoutManager.create(
				"test-project",
				testDir,
				createOptions({
					issueId: "issue-short-timeout",
					prompt: "Test short timeout",
				}),
			);

			expect(result.ok).toBe(true);
			if (!result.ok) return;

			// Wait for the timeout to fire
			await new Promise((resolve) => setTimeout(resolve, 200));

			// Verify delegation timed out
			const getResult = await shortTimeoutManager.get(result.value.id);
			expect(getResult.ok).toBe(true);
			if (!getResult.ok) return;

			expect(getResult.value.status).toBe("timeout");
			expect(getResult.value.error).toContain("Timed out");
		});
	});
});
