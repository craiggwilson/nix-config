/**
 * Tests for project_list and project_status tools
 */

import { describe, test, expect, beforeAll, afterAll } from "bun:test";
import * as fs from "node:fs/promises";
import * as path from "node:path";
import * as os from "node:os";

import { createProjectCreate } from "./project-create.js";
import { createProjectList } from "./project-list.js";
import { createProjectStatus } from "./project-status.js";
import { ConfigManager } from "../config/index.js";
import { InMemoryIssueStorage } from "../issues/inmemory/index.js";
import { FocusManager, ProjectManager } from "../projects/index.js";
import {
	createMockLogger,
	createMockClient,
	createTestShell,
	createMockContext,
} from "../utils/testing/index.js";
import type { BunShell } from "../utils/opencode-sdk/index.js";

const mockLogger = createMockLogger();
const _mockClient = createMockClient();
const mockContext = createMockContext();

describe("project_list and project_status tools", () => {
	let testDir: string;
	let projectManager: ProjectManager;
	let _testShell: BunShell;
	let projectId: string;

	beforeAll(async () => {
		testDir = await fs.mkdtemp(path.join(os.tmpdir(), "project-list-test-"));

		const config = await ConfigManager.loadOrThrow();
		const issueStorage = new InMemoryIssueStorage({ prefix: "test" });
		const focus = new FocusManager();
		_testShell = createTestShell();

		projectManager = new ProjectManager(
			config,
			issueStorage,
			focus,
			mockLogger,
			testDir,
		);

		const createTool = createProjectCreate(projectManager, mockLogger);

		await createTool.execute(
			{
				name: "List Test Project",
				type: "project",
				storage: "local",
				description: "A project for testing list/status",
			},
			mockContext,
		);

		projectId = projectManager.getFocusedProjectId() ?? "";
	});

	afterAll(async () => {
		try {
			await fs.rm(testDir, { recursive: true, force: true });
		} catch {}
	});

	describe("project_list", () => {
		test("lists local projects", async () => {
			const tool = createProjectList(projectManager, mockLogger);

			const result = await tool.execute({ scope: "local" }, mockContext);

			expect(result).toContain("Projects");
			expect(result).toContain("List Test Project");
			expect(result).toContain("Local");
		});

		test("returns empty message when no projects", async () => {
			const emptyDir = await fs.mkdtemp(path.join(os.tmpdir(), "empty-test-"));
			const config = await ConfigManager.loadOrThrow();
			const emptyManager = new ProjectManager(
				config,
				new InMemoryIssueStorage(),
				new FocusManager(),
				mockLogger,
				emptyDir,
			);

			const tool = createProjectList(emptyManager, mockLogger);

			const result = await tool.execute({ scope: "local" }, mockContext);

			expect(result).toContain("No projects found");

			await fs.rm(emptyDir, { recursive: true, force: true });
		});

		test("filters by status", async () => {
			const tool = createProjectList(projectManager, mockLogger);

			// Always use scope: "local" to avoid interference from global projects
			const activeResult = await tool.execute(
				{ status: "active", scope: "local" },
				mockContext,
			);
			expect(activeResult).toContain("List Test Project");

			const completedResult = await tool.execute(
				{ status: "completed", scope: "local" },
				mockContext,
			);
			expect(completedResult).toContain("No projects found");
		});
	});

	describe("project_status", () => {
		test("shows status for focused project", async () => {
			const tool = createProjectStatus(projectManager, mockLogger);

			const result = await tool.execute({}, mockContext);

			expect(result).toContain("List Test Project");
			expect(result).toContain("Progress");
			expect(result).toContain("active");
		});

		test("shows status for specific project", async () => {
			const tool = createProjectStatus(projectManager, mockLogger);

			const result = await tool.execute({ projectId }, mockContext);

			expect(result).toContain("List Test Project");
		});

		test("returns error for non-existent project", async () => {
			projectManager.clearFocus();

			const tool = createProjectStatus(projectManager, mockLogger);

			const result = await tool.execute(
				{ projectId: "non-existent-project" },
				mockContext,
			);

			expect(result).toContain("not found");

			projectManager.setFocus(projectId);
		});

		test("prompts when no project focused", async () => {
			projectManager.clearFocus();

			const tool = createProjectStatus(projectManager, mockLogger);

			const result = await tool.execute({}, mockContext);

			expect(result).toContain("No project specified");
			expect(result).toContain("project-focus");

			projectManager.setFocus(projectId);
		});

		test("shows artifact and decision counts when present", async () => {
			// Register an artifact
			const artifactRegistry =
				await projectManager.getArtifactRegistry(projectId);
			if (artifactRegistry) {
				await artifactRegistry.register({
					title: "Test Research",
					type: "research",
					path: "research/test.md",
					absolutePath: path.join(testDir, "research/test.md"),
					external: false,
					summary: "Test research artifact",
				});
			}

			// Record a decision
			const decisionManager =
				await projectManager.getDecisionManager(projectId);
			if (decisionManager) {
				await decisionManager.recordDecision({
					title: "Test Decision",
					decision: "Use approach A",
					rationale: "It is simpler",
				});
			}

			const tool = createProjectStatus(projectManager, mockLogger);
			const result = await tool.execute({ projectId }, mockContext);

			expect(result).toContain("Knowledge Base");
			expect(result).toContain("Artifacts");
			expect(result).toContain("Decisions");
		});
	});
});
