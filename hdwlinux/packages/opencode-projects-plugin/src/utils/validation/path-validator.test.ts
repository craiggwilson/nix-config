/**
 * Tests for path validation utilities
 */

import { describe, test, expect } from "bun:test";
import * as path from "node:path";

import {
	validateProjectId,
	validateIssueId,
	sanitizePathComponent,
	createSafeWorktreeName,
	validatePathBoundary,
} from "./path-validator.js";

describe("validateProjectId", () => {
	test("accepts valid project IDs", () => {
		const validIds = [
			"my-project",
			"project123",
			"test_project",
			"MyProject",
			"a1b",
			"project-with-many-hyphens",
			"project_with_underscores",
			"MixedCase123",
		];

		for (const id of validIds) {
			const result = validateProjectId(id);
			expect(result.ok).toBe(true);
			if (result.ok) {
				expect(result.value).toBe(id);
			}
		}
	});

	test("rejects empty or non-string values", () => {
		expect(validateProjectId("").ok).toBe(false);
		expect(validateProjectId(null as unknown as string).ok).toBe(false);
		expect(validateProjectId(undefined as unknown as string).ok).toBe(false);
	});

	test("rejects IDs with path traversal sequences", () => {
		const maliciousIds = [
			"../etc/passwd",
			"..\\windows\\system32",
			"project/../../../etc",
			"project/./hidden",
			"..",
			".",
		];

		for (const id of maliciousIds) {
			const result = validateProjectId(id);
			expect(result.ok).toBe(false);
			if (!result.ok) {
				expect([
					"path_traversal",
					"forbidden_chars",
					"invalid_format",
				]).toContain(result.error.type);
			}
		}
	});

	test("rejects IDs with forbidden characters", () => {
		const forbiddenIds = [
			"project/subdir",
			"project\\subdir",
			"project:name",
			"project*name",
			"project?name",
			'project"name',
			"project<name",
			"project>name",
			"project|name",
		];

		for (const id of forbiddenIds) {
			const result = validateProjectId(id);
			expect(result.ok).toBe(false);
			if (!result.ok) {
				expect(result.error.type).toBe("forbidden_chars");
			}
		}
	});

	test("rejects IDs that are too short", () => {
		const result = validateProjectId("ab");
		expect(result.ok).toBe(false);
		if (!result.ok) {
			expect(result.error.type).toBe("invalid_format");
		}
	});

	test("rejects IDs that start with non-alphanumeric", () => {
		const invalidStarts = ["-project", "_project", ".project"];

		for (const id of invalidStarts) {
			const result = validateProjectId(id);
			expect(result.ok).toBe(false);
		}
	});
});

describe("validateIssueId", () => {
	test("accepts valid issue IDs", () => {
		const validIds = [
			"issue-123",
			"bd-a3f8",
			"bd-a3f8.1",
			"bd-a3f8.1.2",
			"PROJ-123",
			"task_1",
			"a",
			"issue-with-dots.and.more",
		];

		for (const id of validIds) {
			const result = validateIssueId(id);
			expect(result.ok).toBe(true);
			if (result.ok) {
				expect(result.value).toBe(id);
			}
		}
	});

	test("rejects IDs with path traversal sequences", () => {
		const maliciousIds = ["../etc/passwd", "issue/../../../etc", ".."];

		for (const id of maliciousIds) {
			const result = validateIssueId(id);
			expect(result.ok).toBe(false);
		}
	});

	test("rejects IDs with slashes", () => {
		const result = validateIssueId("issue/subissue");
		expect(result.ok).toBe(false);
		if (!result.ok) {
			expect(result.error.type).toBe("forbidden_chars");
		}
	});
});

describe("sanitizePathComponent", () => {
	test("removes forbidden characters", () => {
		expect(sanitizePathComponent("project/name")).toBe("project-name");
		expect(sanitizePathComponent("project\\name")).toBe("project-name");
		expect(sanitizePathComponent("project:name")).toBe("project-name");
		expect(sanitizePathComponent("project*name")).toBe("project-name");
	});

	test("removes path traversal sequences", () => {
		expect(sanitizePathComponent("../etc")).toBe("etc");
		expect(sanitizePathComponent("project/../etc")).toBe("project-etc");
		expect(sanitizePathComponent("..")).toBe("");
	});

	test("handles leading dots", () => {
		expect(sanitizePathComponent(".hidden")).toBe("hidden");
	});

	test("collapses multiple hyphens", () => {
		expect(sanitizePathComponent("a---b")).toBe("a-b");
		expect(sanitizePathComponent("a//b")).toBe("a-b");
	});

	test("handles empty input", () => {
		expect(sanitizePathComponent("")).toBe("");
		expect(sanitizePathComponent(null as unknown as string)).toBe("");
	});

	test("limits length", () => {
		const longInput = "a".repeat(200);
		expect(sanitizePathComponent(longInput).length).toBeLessThanOrEqual(128);
	});
});

describe("createSafeWorktreeName", () => {
	test("creates valid worktree names", () => {
		const result = createSafeWorktreeName("my-project", "issue-123");
		expect(result.ok).toBe(true);
		if (result.ok) {
			expect(result.value).toBe("issue-123");
		}
	});

	test("accepts hierarchical issue IDs", () => {
		const result = createSafeWorktreeName("project-abc", "bd-a3f8.1.2");
		expect(result.ok).toBe(true);
		if (result.ok) {
			expect(result.value).toBe("bd-a3f8.1.2");
		}
	});

	test("rejects path traversal in project ID", () => {
		const result = createSafeWorktreeName("../../../etc", "issue-1");
		expect(result.ok).toBe(false);
	});

	test("rejects path traversal in issue ID", () => {
		const result = createSafeWorktreeName("project", "../../../etc/passwd");
		expect(result.ok).toBe(false);
	});

	test("rejects slashes in issue ID", () => {
		const result = createSafeWorktreeName("project", "issue/subissue");
		expect(result.ok).toBe(false);
	});
});

describe("validatePathBoundary", () => {
	test("accepts paths within boundary", () => {
		const base = "/home/user/worktrees";
		const constructed = "/home/user/worktrees/project/issue";

		const result = validatePathBoundary(base, constructed);
		expect(result.ok).toBe(true);
	});

	test("rejects paths that escape boundary", () => {
		const base = "/home/user/worktrees";
		const escaped = "/home/user/other/malicious";

		const result = validatePathBoundary(base, escaped);
		expect(result.ok).toBe(false);
		if (!result.ok) {
			expect(result.error.type).toBe("path_escape");
		}
	});

	test("rejects paths with traversal that escape", () => {
		const base = "/home/user/worktrees";
		const traversal = path.resolve(base, "../../../etc/passwd");

		const result = validatePathBoundary(base, traversal);
		expect(result.ok).toBe(false);
	});

	test("handles base path without trailing separator", () => {
		const base = "/home/user/worktrees";
		const valid = "/home/user/worktrees/project";

		const result = validatePathBoundary(base, valid);
		expect(result.ok).toBe(true);
	});

	test("prevents prefix attacks", () => {
		const base = "/home/user/worktrees";
		const prefixAttack = "/home/user/worktrees-evil/malicious";

		const result = validatePathBoundary(base, prefixAttack);
		expect(result.ok).toBe(false);
	});
});
