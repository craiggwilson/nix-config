/**
 * Tests for constraint sections
 */

import { describe, it, expect } from "bun:test";

import {
	DISABLED_TOOLS,
	disabledToolsList,
	delegationConstraints,
	readOnlyConstraints,
} from "./constraints.js";

describe("DISABLED_TOOLS", () => {
	it("contains expected tools", () => {
		expect(DISABLED_TOOLS).toContain("project-create");
		expect(DISABLED_TOOLS).toContain("project-close");
		expect(DISABLED_TOOLS).toContain("project-create-issue");
		expect(DISABLED_TOOLS).toContain("project-update-issue");
		expect(DISABLED_TOOLS).toContain("project-work-on-issue");
		expect(DISABLED_TOOLS).toContain("question");
		expect(DISABLED_TOOLS).toContain("task");
		expect(DISABLED_TOOLS).toContain("delegate");
	});

	it("is readonly array", () => {
		expect(Array.isArray(DISABLED_TOOLS)).toBe(true);
		expect(DISABLED_TOOLS.length).toBe(8);
	});
});

describe("disabledToolsList", () => {
	it("formats tools as bullet list", () => {
		const list = disabledToolsList();

		expect(list).toContain("project-create");
		expect(list).toContain("project-close");
		expect(list).toContain("delegate");
		expect(list).toContain("no recursive delegation");
	});

	it("splits tools across two lines", () => {
		const list = disabledToolsList();
		const lines = list.split("\n");

		expect(lines.length).toBe(2);
		expect(lines[0]).toContain("-");
		expect(lines[1]).toContain("-");
	});
});

describe("delegationConstraints", () => {
	it("returns constraints section", () => {
		const constraints = delegationConstraints({});

		expect(constraints).toContain("## Constraints");
		expect(constraints).toContain("background delegation");
		expect(constraints).toContain("disabled");
	});

	it("includes disabled tools list", () => {
		const constraints = delegationConstraints({});

		expect(constraints).toContain("project-create");
		expect(constraints).toContain("delegate");
	});

	it("includes focus instruction", () => {
		const constraints = delegationConstraints({});

		expect(constraints).toContain("Focus on completing your assigned role");
	});
});

describe("readOnlyConstraints", () => {
	it("returns read-only instruction", () => {
		const constraints = readOnlyConstraints({});

		expect(constraints).toContain("Do NOT modify files");
		expect(constraints).toContain("read-only");
	});
});
