/**
 * Tests for project_focus tool and focus mode context injection
 */

import { describe, test, expect, beforeAll, afterAll } from "bun:test";
import * as fs from "node:fs/promises";
import * as path from "node:path";
import * as os from "node:os";

import { createProjectCreate } from "./project-create.js";
import { createProjectFocus } from "./project-focus.js";
import { ConfigManager } from "../config/index.js";
import { InMemoryIssueStorage } from "../issues/inmemory/index.js";
import { FocusManager, ProjectManager } from "../projects/index.js";
import { createMockLogger, createMockContext } from "../utils/testing/index.js";

const mockLogger = createMockLogger();
const mockContext = createMockContext();

describe("project_focus tool", () => {
	let testDir: string;
	let projectManager: ProjectManager;
	let projectId: string;

	beforeAll(async () => {
		testDir = await fs.mkdtemp(path.join(os.tmpdir(), "project-focus-test-"));

		const config = await ConfigManager.loadOrThrow();
		const issueStorage = new InMemoryIssueStorage({ prefix: "test" });
		const focus = new FocusManager();

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
				name: "Focus Test Project",
				type: "project",
				storage: "local",
			},
			mockContext,
		);

		projectId = projectManager.getFocusedProjectId() ?? "";

		projectManager.clearFocus();
	});

	afterAll(async () => {
		try {
			await fs.rm(testDir, { recursive: true, force: true });
		} catch {}
	});

	test("shows no focus when nothing is focused", async () => {
		const tool = createProjectFocus(projectManager, mockLogger);

		const result = await tool.execute({}, mockContext);

		expect(result).toContain("No project is currently focused");
		expect(result).toContain("project-focus");
	});

	test("sets focus to a project", async () => {
		const tool = createProjectFocus(projectManager, mockLogger);

		const result = await tool.execute({ projectId }, mockContext);

		expect(result).toContain("Focus Set");
		expect(result).toContain(projectId);

		expect(projectManager.getFocusedProjectId()).toBe(projectId);
	});

	test("shows current focus", async () => {
		const tool = createProjectFocus(projectManager, mockLogger);

		const result = await tool.execute({}, mockContext);

		expect(result).toContain("Current Focus");
		expect(result).toContain(projectId);
	});

	test("clears focus", async () => {
		const tool = createProjectFocus(projectManager, mockLogger);

		const result = await tool.execute({ clear: true }, mockContext);

		expect(result).toContain("Focus cleared");

		expect(projectManager.getFocusedProjectId()).toBeNull();
	});
});

describe("FocusManager", () => {
	test("serializes and restores focus state", () => {
		const focus = new FocusManager();

		focus.setFocus("test-project");

		const serialized = focus.serialize();
		expect(serialized).not.toBeNull();

		const focus2 = new FocusManager();
		if (!serialized) return;
		const restored = focus2.restore(serialized);

		expect(restored).toBe(true);
		expect(focus2.getProjectId()).toBe("test-project");
	});

	test("isFocusedOn checks project correctly", () => {
		const focus = new FocusManager();

		focus.setFocus("my-project");

		expect(focus.isFocusedOn("my-project")).toBe(true);
		expect(focus.isFocusedOn("other-project")).toBe(false);
	});
});
