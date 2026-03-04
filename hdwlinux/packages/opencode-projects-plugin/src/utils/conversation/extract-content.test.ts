import { describe, expect, it } from "bun:test";

import { extractConversationContent } from "./extract-content.js";

describe("extractConversationContent", () => {
	describe("null/undefined/primitive guards", () => {
		it("should return null for null input", () => {
			expect(extractConversationContent(null)).toBeNull();
		});

		it("should return null for undefined input", () => {
			expect(extractConversationContent(undefined)).toBeNull();
		});

		it("should return null for string primitive", () => {
			expect(extractConversationContent("hello")).toBeNull();
		});

		it("should return null for number primitive", () => {
			expect(extractConversationContent(42)).toBeNull();
		});

		it("should return null for boolean primitive", () => {
			expect(extractConversationContent(true)).toBeNull();
		});
	});

	describe("content extraction", () => {
		it("should extract content field when present", () => {
			const input = { content: "Hello, world!" };
			expect(extractConversationContent(input)).toBe("Hello, world!");
		});

		it("should extract conversation field when present", () => {
			const input = { conversation: "A conversation" };
			expect(extractConversationContent(input)).toBe("A conversation");
		});

		it("should prefer content over conversation", () => {
			const input = {
				content: "content value",
				conversation: "conversation value",
			};
			expect(extractConversationContent(input)).toBe("content value");
		});

		it("should format messages array", () => {
			const input = {
				messages: [
					{ role: "user", content: "Hello" },
					{ role: "assistant", content: "Hi there" },
				],
			};
			expect(extractConversationContent(input)).toBe(
				"user: Hello\n\nassistant: Hi there",
			);
		});

		it("should handle messages with missing role", () => {
			const input = {
				messages: [{ content: "No role here" }],
			};
			expect(extractConversationContent(input)).toBe("unknown: No role here");
		});

		it("should handle messages with missing content", () => {
			const input = {
				messages: [{ role: "user" }],
			};
			expect(extractConversationContent(input)).toBe("user: ");
		});

		it("should return null for empty object", () => {
			expect(extractConversationContent({})).toBeNull();
		});

		it("should return null for object without recognized fields", () => {
			const input = { foo: "bar", baz: 123 };
			expect(extractConversationContent(input)).toBeNull();
		});
	});
});
