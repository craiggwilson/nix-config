/**
 * Tests for VCS Adapters
 *
 * These tests verify the VCS adapter implementations work correctly.
 * They require git and jj to be installed and will skip if not available.
 */

import { describe, test, expect, beforeAll, afterAll } from "bun:test";
import * as fs from "node:fs/promises";
import * as path from "node:path";
import * as os from "node:os";
import { $ } from "bun";

import { GitAdapter } from "./git/adapter.js";
import { JujutsuAdapter } from "./jujutsu/adapter.js";
import { createMockLogger, createTestShell } from "../utils/testing/index.js";

const mockLogger = createMockLogger();
const testShell = createTestShell();

async function isGitAvailable(): Promise<boolean> {
	try {
		const result = await $`git --version`.nothrow().quiet();
		return result.exitCode === 0;
	} catch {
		return false;
	}
}

async function isJjAvailable(): Promise<boolean> {
	try {
		const result = await $`jj --version`.nothrow().quiet();
		return result.exitCode === 0;
	} catch {
		return false;
	}
}

describe("GitAdapter", () => {
	let testDir: string;
	let repoDir: string;
	let adapter: GitAdapter;
	let gitAvailable: boolean;

	beforeAll(async () => {
		gitAvailable = await isGitAvailable();
		if (!gitAvailable) {
			console.log("Skipping GitAdapter tests - git not available");
			return;
		}

		testDir = await fs.mkdtemp(path.join(os.tmpdir(), "git-adapter-test-"));
		repoDir = path.join(testDir, "repo");

		await fs.mkdir(repoDir, { recursive: true });
		await $`git -C ${repoDir} init`.quiet();
		await $`git -C ${repoDir} config user.email "test@test.com"`.quiet();
		await $`git -C ${repoDir} config user.name "Test"`.quiet();

		await fs.writeFile(path.join(repoDir, "README.md"), "# Test Repo");
		await $`git -C ${repoDir} add .`.quiet();
		await $`git -C ${repoDir} commit -m "Initial commit"`.quiet();

		adapter = new GitAdapter(repoDir, testShell, mockLogger);
	});

	afterAll(async () => {
		if (testDir) {
			await fs.rm(testDir, { recursive: true, force: true });
		}
	});

	test("type is git", () => {
		if (!gitAvailable) return;
		expect(adapter.type).toBe("git");
	});

	test("getCurrentBranch returns branch name", async () => {
		if (!gitAvailable) return;
		const result = await adapter.getCurrentBranch();
		expect(result.ok).toBe(true);
		if (result.ok) {
			expect(["main", "master"]).toContain(result.value);
		}
	});

	test("getDefaultBranch returns main or master", async () => {
		if (!gitAvailable) return;
		const result = await adapter.getDefaultBranch();
		expect(result.ok).toBe(true);
		if (result.ok) {
			expect(["main", "master"]).toContain(result.value);
		}
	});

	test("hasUncommittedChanges returns false for clean repo", async () => {
		if (!gitAvailable) return;
		const result = await adapter.hasUncommittedChanges();
		expect(result.ok).toBe(true);
		if (result.ok) {
			expect(result.value).toBe(false);
		}
	});

	test("hasUncommittedChanges returns true after modification", async () => {
		if (!gitAvailable) return;
		await fs.writeFile(path.join(repoDir, "new-file.txt"), "content");
		const result = await adapter.hasUncommittedChanges();
		expect(result.ok).toBe(true);
		if (result.ok) {
			expect(result.value).toBe(true);
		}

		await fs.rm(path.join(repoDir, "new-file.txt"));
	});

	test("createWorktree creates a new worktree", async () => {
		if (!gitAvailable) return;

		const result = await adapter.createWorktree("test-worktree");

		expect(result.ok).toBe(true);
		if (result.ok) {
			expect(result.value.name).toBe("test-worktree");
			expect(result.value.branch).toBe("test-worktree");
			expect(result.value.isMain).toBe(false);

			const stat = await fs.stat(result.value.path);
			expect(stat.isDirectory()).toBe(true);
		}

		await adapter.removeWorktree("test-worktree");
	});

	test("listWorktrees includes main and created worktrees", async () => {
		if (!gitAvailable) return;

		await adapter.createWorktree("list-test");

		const result = await adapter.listWorktrees();

		expect(result.ok).toBe(true);
		if (result.ok) {
			expect(result.value.length).toBeGreaterThanOrEqual(2);
			expect(result.value.some((w) => w.isMain)).toBe(true);
			expect(result.value.some((w) => w.name === "list-test")).toBe(true);
		}

		await adapter.removeWorktree("list-test");
	});

	test("removeWorktree removes the worktree", async () => {
		if (!gitAvailable) return;

		const createResult = await adapter.createWorktree("remove-test");
		expect(createResult.ok).toBe(true);

		if (createResult.ok) {
			const removeResult = await adapter.removeWorktree("remove-test");
			expect(removeResult.ok).toBe(true);

			try {
				await fs.stat(createResult.value.path);
				expect(true).toBe(false); // Should not reach here
			} catch (e) {
				expect((e as NodeJS.ErrnoException).code).toBe("ENOENT");
			}
		}
	});
});

describe("JujutsuAdapter", () => {
	let testDir: string;
	let repoDir: string;
	let adapter: JujutsuAdapter;
	let jjAvailable: boolean;

	beforeAll(async () => {
		jjAvailable = await isJjAvailable();
		if (!jjAvailable) {
			console.log("Skipping JujutsuAdapter tests - jj not available");
			return;
		}

		testDir = await fs.mkdtemp(path.join(os.tmpdir(), "jj-adapter-test-"));
		repoDir = path.join(testDir, "repo");

		await $`jj git init ${repoDir}`.quiet();

		await fs.writeFile(path.join(repoDir, "README.md"), "# Test Repo");
		await $`jj -R ${repoDir} commit -m "Initial commit"`.quiet();

		adapter = new JujutsuAdapter(repoDir, testShell, mockLogger);
	});

	afterAll(async () => {
		if (testDir) {
			await fs.rm(testDir, { recursive: true, force: true });
		}
	});

	test("type is jj", () => {
		if (!jjAvailable) return;
		expect(adapter.type).toBe("jj");
	});

	test("getCurrentBranch returns change id", async () => {
		if (!jjAvailable) return;
		const result = await adapter.getCurrentBranch();
		expect(result.ok).toBe(true);
		if (result.ok) {
			expect(result.value.length).toBeGreaterThan(0);
		}
	});

	test("hasUncommittedChanges works", async () => {
		if (!jjAvailable) return;
		const result = await adapter.hasUncommittedChanges();
		expect(result.ok).toBe(true);
		if (result.ok) {
			expect(typeof result.value).toBe("boolean");
		}
	});

	test("createWorktree creates a new workspace", async () => {
		if (!jjAvailable) return;

		const result = await adapter.createWorktree("test-workspace");

		expect(result.ok).toBe(true);
		if (result.ok) {
			expect(result.value.name).toBe("test-workspace");
			expect(result.value.isMain).toBe(false);

			const stat = await fs.stat(result.value.path);
			expect(stat.isDirectory()).toBe(true);
		}

		await adapter.removeWorktree("test-workspace");
	});

	test("listWorktrees includes workspaces", async () => {
		if (!jjAvailable) return;

		await adapter.createWorktree("list-test-ws");

		const result = await adapter.listWorktrees();

		expect(result.ok).toBe(true);
		if (result.ok) {
			expect(result.value.length).toBeGreaterThanOrEqual(1);
			expect(result.value.some((w) => w.name === "list-test-ws")).toBe(true);
		}

		await adapter.removeWorktree("list-test-ws");
	});

	test("removeWorktree removes the workspace", async () => {
		if (!jjAvailable) return;

		await adapter.createWorktree("remove-test-ws");
		const result = await adapter.removeWorktree("remove-test-ws");

		expect(result.ok).toBe(true);
	});

	test("createWorktree succeeds when stale directory exists", async () => {
		if (!jjAvailable) return;

		// Simulate a stale directory from a previous failed attempt
		const worktreeBase = adapter.getWorktreeBasePath();
		const stalePath = path.join(worktreeBase, "stale-ws");
		await fs.mkdir(stalePath, { recursive: true });
		await fs.writeFile(
			path.join(stalePath, "stale-file.txt"),
			"leftover content",
		);

		// createWorktree should clean up the stale directory and succeed
		const result = await adapter.createWorktree("stale-ws");

		expect(result.ok).toBe(true);
		if (result.ok) {
			expect(result.value.name).toBe("stale-ws");
			expect(result.value.isMain).toBe(false);

			const stat = await fs.stat(result.value.path);
			expect(stat.isDirectory()).toBe(true);
		}

		await adapter.removeWorktree("stale-ws");
	});
});
