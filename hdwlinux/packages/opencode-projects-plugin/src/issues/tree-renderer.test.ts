/**
 * Tests for tree-renderer
 */

import { describe, it, expect } from "bun:test";

import {
	buildIssueTree,
	renderTree,
	renderIssueTree,
} from "./tree-renderer.js";
import type { Issue } from "./issue-storage.js";

function createIssue(
	overrides: Partial<Issue> & { id: string; title: string },
): Issue {
	return {
		status: "open",
		createdAt: "2026-01-01T00:00:00Z",
		updatedAt: "2026-01-01T00:00:00Z",
		...overrides,
	};
}

describe("buildIssueTree", () => {
	it("returns empty array for empty input", () => {
		const tree = buildIssueTree([]);
		expect(tree).toEqual([]);
	});

	it("creates root nodes for issues without parents", () => {
		const issues: Issue[] = [
			createIssue({ id: "issue-1", title: "First issue" }),
			createIssue({ id: "issue-2", title: "Second issue" }),
		];

		const tree = buildIssueTree(issues);

		expect(tree.length).toBe(2);
		expect(tree[0].issue.id).toBe("issue-1");
		expect(tree[1].issue.id).toBe("issue-2");
		expect(tree[0].children).toEqual([]);
		expect(tree[1].children).toEqual([]);
	});

	it("nests children under their parents", () => {
		const issues: Issue[] = [
			createIssue({ id: "parent", title: "Parent issue" }),
			createIssue({ id: "child-1", title: "Child 1", parent: "parent" }),
			createIssue({ id: "child-2", title: "Child 2", parent: "parent" }),
		];

		const tree = buildIssueTree(issues);

		expect(tree.length).toBe(1);
		expect(tree[0].issue.id).toBe("parent");
		expect(tree[0].children.length).toBe(2);
		expect(tree[0].children[0].issue.id).toBe("child-1");
		expect(tree[0].children[1].issue.id).toBe("child-2");
	});

	it("handles deeply nested hierarchies", () => {
		const issues: Issue[] = [
			createIssue({ id: "root", title: "Root" }),
			createIssue({ id: "level-1", title: "Level 1", parent: "root" }),
			createIssue({ id: "level-2", title: "Level 2", parent: "level-1" }),
			createIssue({ id: "level-3", title: "Level 3", parent: "level-2" }),
		];

		const tree = buildIssueTree(issues);

		expect(tree.length).toBe(1);
		expect(tree[0].children[0].children[0].children[0].issue.id).toBe(
			"level-3",
		);
	});

	it("treats issues with missing parents as roots", () => {
		const issues: Issue[] = [
			createIssue({ id: "orphan", title: "Orphan", parent: "nonexistent" }),
		];

		const tree = buildIssueTree(issues);

		expect(tree.length).toBe(1);
		expect(tree[0].issue.id).toBe("orphan");
	});

	it("sorts children alphabetically by id", () => {
		const issues: Issue[] = [
			createIssue({ id: "parent", title: "Parent" }),
			createIssue({ id: "child-c", title: "Child C", parent: "parent" }),
			createIssue({ id: "child-a", title: "Child A", parent: "parent" }),
			createIssue({ id: "child-b", title: "Child B", parent: "parent" }),
		];

		const tree = buildIssueTree(issues);

		expect(tree[0].children[0].issue.id).toBe("child-a");
		expect(tree[0].children[1].issue.id).toBe("child-b");
		expect(tree[0].children[2].issue.id).toBe("child-c");
	});
});

describe("renderTree", () => {
	it("renders single node", () => {
		const tree = buildIssueTree([
			createIssue({ id: "issue-1", title: "Test issue" }),
		]);

		const output = renderTree(tree);

		expect(output).toContain("issue-1: Test issue");
		expect(output).toContain("└──");
	});

	it("renders multiple root nodes", () => {
		const tree = buildIssueTree([
			createIssue({ id: "issue-1", title: "First" }),
			createIssue({ id: "issue-2", title: "Second" }),
		]);

		const output = renderTree(tree);

		expect(output).toContain("├──");
		expect(output).toContain("└──");
		expect(output).toContain("issue-1: First");
		expect(output).toContain("issue-2: Second");
	});

	it("renders nested children with proper indentation", () => {
		const tree = buildIssueTree([
			createIssue({ id: "parent", title: "Parent" }),
			createIssue({ id: "child", title: "Child", parent: "parent" }),
		]);

		const output = renderTree(tree);

		expect(output).toContain("parent: Parent");
		expect(output).toContain("child: Child");
		expect(output.split("\n").length).toBe(2);
	});

	it("shows status icons by default", () => {
		const tree = buildIssueTree([
			createIssue({ id: "open-issue", title: "Open", status: "open" }),
			createIssue({ id: "closed-issue", title: "Closed", status: "closed" }),
			createIssue({
				id: "in-progress",
				title: "In Progress",
				status: "in_progress",
			}),
		]);

		const output = renderTree(tree);

		expect(output).toContain("⬜");
		expect(output).toContain("✅");
		expect(output).toContain("🔄");
	});

	it("hides status icons when showStatus is false", () => {
		const tree = buildIssueTree([
			createIssue({ id: "issue-1", title: "Test", status: "closed" }),
		]);

		const output = renderTree(tree, { showStatus: false });

		expect(output).not.toContain("✅");
		expect(output).not.toContain("⬜");
	});

	it("shows blocked icon for issues with blockers", () => {
		const tree = buildIssueTree([
			createIssue({
				id: "blocked",
				title: "Blocked",
				blockedBy: ["other-issue"],
			}),
		]);

		const output = renderTree(tree);

		expect(output).toContain("⏳");
	});

	it("shows priority badge when priority is set", () => {
		const tree = buildIssueTree([
			createIssue({ id: "high-priority", title: "Urgent", priority: 1 }),
		]);

		const output = renderTree(tree);

		expect(output).toContain("[P1]");
	});

	it("does not show priority badge when priority is undefined", () => {
		const tree = buildIssueTree([
			createIssue({ id: "no-priority", title: "Normal" }),
		]);

		const output = renderTree(tree);

		expect(output).not.toContain("[P");
	});
});

describe("renderIssueTree", () => {
	it("returns placeholder for empty list", () => {
		const output = renderIssueTree([]);
		expect(output).toBe("(no issues)");
	});

	it("renders issues as tree", () => {
		const issues: Issue[] = [
			createIssue({ id: "issue-1", title: "First" }),
			createIssue({ id: "issue-2", title: "Second" }),
		];

		const output = renderIssueTree(issues);

		expect(output).toContain("issue-1: First");
		expect(output).toContain("issue-2: Second");
	});

	it("passes options through to renderTree", () => {
		const issues: Issue[] = [
			createIssue({ id: "issue-1", title: "Test", status: "closed" }),
		];

		const output = renderIssueTree(issues, { showStatus: false });

		expect(output).not.toContain("✅");
	});
});
