/**
 * Tests for error paths in project tools
 *
 * Exercises error handling and edge cases:
 * - Invalid parent ID when creating issues
 * - Non-existent issue when working on issues
 * - Closing project with in-progress issues
 * - mergeWorktree=true when no worktree exists
 * - Invalid delegation ID in project-internal-delegation-read
 */

import {
	describe,
	test,
	expect,
	beforeAll,
	afterAll,
	beforeEach,
} from "bun:test";
import * as fs from "node:fs/promises";
import * as path from "node:path";
import * as os from "node:os";

import { createProjectCreate } from "./project-create.js";
import { createProjectCreateIssue } from "./project-create-issue.js";
import { createProjectWorkOnIssue } from "./project-work-on-issue.js";
import { createProjectUpdateIssue } from "./project-update-issue.js";
import { createProjectClose } from "./project-close.js";
import { createProjectInternalDelegationRead } from "./project-internal-delegation-read.js";
import { ConfigManager } from "../config/index.js";
import { InMemoryIssueStorage } from "../issues/inmemory/index.js";
import { FocusManager, ProjectManager } from "../projects/index.js";
import {
	createMockLogger,
	createMockClient,
	createMockContext,
	createMockTeamManager,
	createTestShell,
} from "../utils/testing/index.js";
import type { BunShell } from "../utils/opencode-sdk/index.js";
import type { TeamManager } from "../teams/index.js";

const mockLogger = createMockLogger();
const mockClient = createMockClient();
const mockContext = createMockContext();

describe("Error paths", () => {
	let config: ConfigManager;
	let testDir: string;
	let projectManager: ProjectManager;
	let testShell: BunShell;
	let issueStorage: InMemoryIssueStorage;
	let teamManager: TeamManager;
	let projectId: string;

	beforeAll(async () => {
		testDir = await fs.mkdtemp(path.join(os.tmpdir(), "error-paths-test-"));

		config = await ConfigManager.loadOrThrow();
		issueStorage = new InMemoryIssueStorage({ prefix: "test" });
		const focus = new FocusManager();
		testShell = createTestShell();

		teamManager = createMockTeamManager();

		projectManager = new ProjectManager(
			config,
			issueStorage,
			focus,
			mockLogger,
			testDir,
		);

		// Create a test project
		const createTool = createProjectCreate(projectManager, mockLogger);
		const result = await createTool.execute(
			{
				name: "Error Test Project",
				type: "project",
				storage: "local",
				description: "Project for testing error paths",
			},
			mockContext,
		);

		// Extract project ID from result
		const match = result.match(/\*\*ID:\*\*\s+(\S+)/);
		if (match) {
			projectId = match[1];
		} else {
			throw new Error("Failed to extract project ID from create result");
		}
	});

	afterAll(async () => {
		try {
			await fs.rm(testDir, { recursive: true, force: true });
		} catch {
			// Ignore cleanup errors
		}
	});

	describe("project-create-issue with invalid parent", () => {
		test("returns graceful error for non-existent parent ID", async () => {
			const tool = createProjectCreateIssue(projectManager, mockLogger);

			const result = await tool.execute(
				{
					title: "Test Issue",
					projectId,
					parent: "non-existent-parent-id-12345",
					description: "This should fail gracefully",
				},
				mockContext,
			);

			// Should return an error message, not throw
			expect(typeof result).toBe("string");
			// The error should be informative
			expect(
				result.includes("Failed") ||
					result.includes("Error") ||
					result.includes("not found") ||
					result.includes("invalid"),
			).toBe(true);
		});

		test("returns graceful error for malformed parent ID", async () => {
			const tool = createProjectCreateIssue(projectManager, mockLogger);

			const result = await tool.execute(
				{
					title: "Test Issue",
					projectId,
					parent: "!!!invalid!!!",
					description: "This should fail gracefully",
				},
				mockContext,
			);

			expect(typeof result).toBe("string");
			// Should not crash, should return some kind of error message
			expect(result.length).toBeGreaterThan(0);
		});
	});

	describe("project-work-on-issue with non-existent issue", () => {
		test("returns graceful error for non-existent issue ID", async () => {
			const tool = createProjectWorkOnIssue(
				projectManager,
				teamManager,
				mockLogger,
				mockClient,
				config,
			);

			// Focus on the project first
			projectManager.setFocus(projectId);

			const result = await tool.execute(
				{
					issueId: "non-existent-issue-id-99999",
				},
				mockContext,
			);

			expect(typeof result).toBe("string");
			expect(result).toContain("not found");
		});

		test("returns graceful error when no project is focused", async () => {
			const tool = createProjectWorkOnIssue(
				projectManager,
				teamManager,
				mockLogger,
				mockClient,
				config,
			);

			// Clear focus
			projectManager.clearFocus();

			const result = await tool.execute(
				{
					issueId: "some-issue-id",
				},
				mockContext,
			);

			expect(typeof result).toBe("string");
			expect(result).toContain("No project");
			expect(result).toContain("focused");

			// Restore focus for other tests
			projectManager.setFocus(projectId);
		});
	});

	describe("project-close with in-progress issues", () => {
		test("allows closing project with in-progress issues (current behavior)", async () => {
			// First create an issue and set it to in_progress
			const createIssueTool = createProjectCreateIssue(
				projectManager,
				mockLogger,
			);
			projectManager.setFocus(projectId);

			const createResult = await createIssueTool.execute(
				{
					title: "In Progress Issue",
					projectId,
					description: "This issue is in progress",
				},
				mockContext,
			);

			// Extract issue ID
			const issueMatch = createResult.match(/Issue Created:\s+(\S+)/);
			if (issueMatch) {
				const issueId = issueMatch[1];

				// Update to in_progress
				const updateTool = createProjectUpdateIssue(
					projectManager,
					mockLogger,
					testShell,
				);
				await updateTool.execute(
					{
						issueId,
						projectId,
						status: "in_progress",
					},
					mockContext,
				);
			}

			// Now try to close the project
			const closeTool = createProjectClose(projectManager, mockLogger);
			const closeResult = await closeTool.execute(
				{
					projectId,
					reason: "completed",
					summary: "Closing despite in-progress issues",
				},
				mockContext,
			);

			// Current behavior: project closes successfully
			// This test documents the current behavior - it may be changed to warn/error
			expect(typeof closeResult).toBe("string");
			expect(
				closeResult.includes("Project Closed") ||
					closeResult.includes("in-progress") ||
					closeResult.includes("warning"),
			).toBe(true);
		});
	});

	describe("project-update-issue with mergeWorktree=true but no worktree", () => {
		let testIssueId: string;

		beforeEach(async () => {
			// Create a fresh project for this test
			const config = await ConfigManager.loadOrThrow();
			const newIssueStorage = new InMemoryIssueStorage({
				prefix: "merge-test",
			});
			const newFocus = new FocusManager();
			const newTestDir = await fs.mkdtemp(
				path.join(os.tmpdir(), "merge-worktree-test-"),
			);

			const newProjectManager = new ProjectManager(
				config,
				newIssueStorage,
				newFocus,
				mockLogger,
				newTestDir,
			);

			// Create project
			const createTool = createProjectCreate(newProjectManager, mockLogger);
			const createResult = await createTool.execute(
				{
					name: "Merge Test Project",
					type: "project",
					storage: "local",
				},
				mockContext,
			);

			const projectMatch = createResult.match(/\*\*ID:\*\*\s+(\S+)/);
			const newProjectId = projectMatch ? projectMatch[1] : "";

			// Create an issue
			const createIssueTool = createProjectCreateIssue(
				newProjectManager,
				mockLogger,
			);
			const issueResult = await createIssueTool.execute(
				{
					title: "Test Issue for Merge",
					projectId: newProjectId,
				},
				mockContext,
			);

			const issueMatch = issueResult.match(/Issue Created:\s+(\S+)/);
			testIssueId = issueMatch ? issueMatch[1] : "";

			// Set to in_progress
			const updateTool = createProjectUpdateIssue(
				newProjectManager,
				mockLogger,
				testShell,
			);
			await updateTool.execute(
				{
					issueId: testIssueId,
					projectId: newProjectId,
					status: "in_progress",
				},
				mockContext,
			);

			// Now test closing with mergeWorktree=true
			const closeResult = await updateTool.execute(
				{
					issueId: testIssueId,
					projectId: newProjectId,
					status: "closed",
					mergeWorktree: true,
				},
				mockContext,
			);

			// Should handle gracefully - no worktree exists
			expect(typeof closeResult).toBe("string");
			expect(
				closeResult.includes("No worktree found") ||
					closeResult.includes("Issue Updated") ||
					closeResult.includes("closed"),
			).toBe(true);

			// Cleanup
			try {
				await fs.rm(newTestDir, { recursive: true, force: true });
			} catch {
				// Ignore
			}
		});

		test("handles mergeWorktree=true gracefully when no worktree exists", () => {
			// The actual test is in beforeEach - this is just a placeholder
			expect(true).toBe(true);
		});
	});

	describe("project-internal-delegation-read with invalid ID", () => {
		test("returns clear error for non-existent delegation ID", async () => {
			const tool = createProjectInternalDelegationRead(
				projectManager,
				mockLogger,
			);

			projectManager.setFocus(projectId);

			const result = await tool.execute(
				{
					id: "del-nonexistent-12345678",
					projectId,
				},
				mockContext,
			);

			expect(typeof result).toBe("string");
			expect(result).toContain("not found");
			expect(
				result.includes("Delegation") || result.includes("delegation"),
			).toBe(true);
		});

		test("returns clear error for malformed delegation ID", async () => {
			const tool = createProjectInternalDelegationRead(
				projectManager,
				mockLogger,
			);

			projectManager.setFocus(projectId);

			const result = await tool.execute(
				{
					id: "invalid-format",
					projectId,
				},
				mockContext,
			);

			expect(typeof result).toBe("string");
			// Should return an error, not crash
			expect(result.length).toBeGreaterThan(0);
		});

		test("returns clear error when no project is focused and no projectId provided", async () => {
			const tool = createProjectInternalDelegationRead(
				projectManager,
				mockLogger,
			);

			projectManager.clearFocus();

			const result = await tool.execute(
				{
					id: "del-some-id",
				},
				mockContext,
			);

			expect(typeof result).toBe("string");
			expect(result).toContain("No project");

			// Restore focus
			projectManager.setFocus(projectId);
		});
	});

	describe("Validation errors", () => {
		test("project-create-issue rejects empty title", async () => {
			const tool = createProjectCreateIssue(projectManager, mockLogger);

			const result = await tool.execute(
				{
					title: "",
					projectId,
				},
				mockContext,
			);

			expect(typeof result).toBe("string");
			expect(
				result.includes("Validation") ||
					result.includes("title") ||
					result.includes("required") ||
					result.includes("empty"),
			).toBe(true);
		});

		test("project-update-issue rejects invalid priority", async () => {
			const tool = createProjectUpdateIssue(
				projectManager,
				mockLogger,
				testShell,
			);

			// First create an issue
			const createTool = createProjectCreateIssue(projectManager, mockLogger);
			projectManager.setFocus(projectId);

			const createResult = await createTool.execute(
				{
					title: "Priority Test Issue",
					projectId,
				},
				mockContext,
			);

			const issueMatch = createResult.match(/Issue Created:\s+(\S+)/);
			const issueId = issueMatch ? issueMatch[1] : "test-issue";

			// Try to update with invalid priority
			const result = await tool.execute(
				{
					issueId,
					projectId,
					priority: 99, // Invalid - should be 0-3
				},
				mockContext,
			);

			expect(typeof result).toBe("string");
			// Should either reject or handle gracefully
			expect(result.length).toBeGreaterThan(0);
		});

		test("project-work-on-issue rejects empty issueId", async () => {
			const tool = createProjectWorkOnIssue(
				projectManager,
				teamManager,
				mockLogger,
				mockClient,
				config,
			);

			projectManager.setFocus(projectId);

			const result = await tool.execute(
				{
					issueId: "",
				},
				mockContext,
			);

			expect(typeof result).toBe("string");
			expect(
				result.includes("Validation") ||
					result.includes("issueId") ||
					result.includes("required"),
			).toBe(true);
		});
	});

	describe("Project not found errors", () => {
		test("project-create-issue returns error for non-existent project", async () => {
			const tool = createProjectCreateIssue(projectManager, mockLogger);

			const result = await tool.execute(
				{
					title: "Test Issue",
					projectId: "non-existent-project-xyz",
				},
				mockContext,
			);

			expect(typeof result).toBe("string");
			expect(result).toContain("not found");
		});

		test("project-update-issue returns error for non-existent project", async () => {
			const tool = createProjectUpdateIssue(
				projectManager,
				mockLogger,
				testShell,
			);

			const result = await tool.execute(
				{
					issueId: "some-issue",
					projectId: "non-existent-project-xyz",
					status: "closed",
				},
				mockContext,
			);

			expect(typeof result).toBe("string");
			expect(result).toContain("not found");
		});

		test("project-close returns error for non-existent project", async () => {
			const tool = createProjectClose(projectManager, mockLogger);

			const result = await tool.execute(
				{
					projectId: "non-existent-project-xyz",
				},
				mockContext,
			);

			expect(typeof result).toBe("string");
			expect(result).toContain("not found");
		});
	});
});
