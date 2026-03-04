/**
 * Tests for BeadsResponseParser
 */

import { describe, test, expect, beforeEach } from "bun:test";
import { BeadsResponseParser } from "./response-parser.js";

describe("BeadsResponseParser", () => {
	let parser: BeadsResponseParser;

	beforeEach(() => {
		parser = new BeadsResponseParser();
	});

	describe("parseJSON", () => {
		test("parses valid JSON", () => {
			const result = parser.parseJSON('{"key": "value"}');
			expect(result.ok).toBe(true);
			if (result.ok) {
				expect(result.value).toEqual({ key: "value" });
			}
		});

		test("returns error for invalid JSON", () => {
			const result = parser.parseJSON("not json");
			expect(result.ok).toBe(false);
			if (!result.ok) {
				expect(result.error.name).toBe("BeadsParseError");
			}
		});
	});

	describe("parseIssue", () => {
		test("parses valid issue data", () => {
			const issueData = {
				id: "test-123",
				title: "Test Issue",
				status: "open",
				priority: 2,
				blocked_by: [],
				labels: [],
			};

			const result = parser.parseIssue(issueData);
			expect(result.ok).toBe(true);
			if (result.ok) {
				expect(result.value.id).toBe("test-123");
				expect(result.value.title).toBe("Test Issue");
				expect(result.value.status).toBe("open");
			}
		});

		test("returns error for invalid issue data", () => {
			const result = parser.parseIssue({ invalid: "data" });
			expect(result.ok).toBe(false);
			if (!result.ok) {
				expect(result.error.name).toBe("BeadsParseError");
			}
		});
	});

	describe("parseIssueArray", () => {
		test("parses valid issue array", () => {
			const issuesData = [
				{
					id: "test-1",
					title: "Issue 1",
					status: "open",
					priority: 2,
					blocked_by: [],
					labels: [],
				},
				{
					id: "test-2",
					title: "Issue 2",
					status: "closed",
					priority: 1,
					blocked_by: [],
					labels: [],
				},
			];

			const result = parser.parseIssueArray(issuesData);
			expect(result.ok).toBe(true);
			if (result.ok) {
				expect(result.value).toHaveLength(2);
				expect(result.value[0].id).toBe("test-1");
				expect(result.value[1].id).toBe("test-2");
			}
		});

		test("returns error for invalid array data", () => {
			const result = parser.parseIssueArray("not an array");
			expect(result.ok).toBe(false);
			if (!result.ok) {
				expect(result.error.name).toBe("BeadsParseError");
			}
		});
	});
});
