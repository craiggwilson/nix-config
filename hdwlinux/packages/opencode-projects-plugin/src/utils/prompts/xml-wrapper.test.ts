/**
 * Tests for xml-wrapper utilities
 */

import { describe, it, expect } from "bun:test";

import {
	xmlWrap,
	lines,
	section,
	bulletList,
	numberedList,
} from "./xml-wrapper.js";

describe("xmlWrap", () => {
	describe("simple signature", () => {
		it("wraps string content in XML tags", () => {
			const result = xmlWrap("context", "Some content");
			expect(result).toBe("<context>\nSome content\n</context>");
		});

		it("wraps array content joined with newlines", () => {
			const result = xmlWrap("list", ["item 1", "item 2", "item 3"]);
			expect(result).toBe("<list>\nitem 1\nitem 2\nitem 3\n</list>");
		});

		it("handles empty string content", () => {
			const result = xmlWrap("empty", "");
			expect(result).toBe("<empty>\n\n</empty>");
		});

		it("handles empty array content", () => {
			const result = xmlWrap("empty", []);
			expect(result).toBe("<empty>\n\n</empty>");
		});
	});

	describe("options signature", () => {
		it("wraps content with options object", () => {
			const result = xmlWrap({ tag: "data", content: "value" });
			expect(result).toBe("<data>\nvalue\n</data>");
		});

		it("adds attributes to opening tag", () => {
			const result = xmlWrap({
				tag: "data",
				content: "value",
				attributes: { type: "json" },
			});
			expect(result).toBe('<data type="json">\nvalue\n</data>');
		});

		it("adds multiple attributes", () => {
			const result = xmlWrap({
				tag: "element",
				content: "content",
				attributes: { id: "123", class: "test" },
			});
			expect(result).toContain('id="123"');
			expect(result).toContain('class="test"');
			expect(result).toContain("<element");
			expect(result).toContain("</element>");
		});

		it("handles array content with attributes", () => {
			const result = xmlWrap({
				tag: "list",
				content: ["a", "b"],
				attributes: { format: "simple" },
			});
			expect(result).toBe('<list format="simple">\na\nb\n</list>');
		});
	});
});

describe("lines", () => {
	it("joins strings with newlines", () => {
		const result = lines("line 1", "line 2", "line 3");
		expect(result).toBe("line 1\nline 2\nline 3");
	});

	it("flattens nested arrays", () => {
		const result = lines("header", ["item 1", "item 2"], "footer");
		expect(result).toBe("header\nitem 1\nitem 2\nfooter");
	});

	it("filters out null values", () => {
		const result = lines("line 1", null, "line 2");
		expect(result).toBe("line 1\nline 2");
	});

	it("filters out undefined values", () => {
		const result = lines("line 1", undefined, "line 2");
		expect(result).toBe("line 1\nline 2");
	});

	it("handles conditional content", () => {
		const condition = false;
		const result = lines(
			"always",
			condition ? "sometimes" : null,
			"always too",
		);
		expect(result).toBe("always\nalways too");
	});

	it("handles empty input", () => {
		const result = lines();
		expect(result).toBe("");
	});

	it("handles all null/undefined input", () => {
		const result = lines(null, undefined, null);
		expect(result).toBe("");
	});
});

describe("section", () => {
	it("creates h1 section", () => {
		const result = section("#", "Title", "Content here");
		expect(result).toBe("# Title\n\nContent here");
	});

	it("creates h2 section", () => {
		const result = section("##", "Subtitle", "More content");
		expect(result).toBe("## Subtitle\n\nMore content");
	});

	it("creates h3 section", () => {
		const result = section("###", "Heading", "Details");
		expect(result).toBe("### Heading\n\nDetails");
	});

	it("creates h4 section", () => {
		const result = section("####", "Small Heading", "Info");
		expect(result).toBe("#### Small Heading\n\nInfo");
	});

	it("joins array content with newlines", () => {
		const result = section("##", "List", ["item 1", "item 2"]);
		expect(result).toBe("## List\n\nitem 1\nitem 2");
	});
});

describe("bulletList", () => {
	it("creates bullet list from items", () => {
		const result = bulletList(["First", "Second", "Third"]);
		expect(result).toBe("- First\n- Second\n- Third");
	});

	it("handles single item", () => {
		const result = bulletList(["Only item"]);
		expect(result).toBe("- Only item");
	});

	it("handles empty array", () => {
		const result = bulletList([]);
		expect(result).toBe("");
	});
});

describe("numberedList", () => {
	it("creates numbered list from items", () => {
		const result = numberedList(["First", "Second", "Third"]);
		expect(result).toBe("1. First\n2. Second\n3. Third");
	});

	it("handles single item", () => {
		const result = numberedList(["Only item"]);
		expect(result).toBe("1. Only item");
	});

	it("handles empty array", () => {
		const result = numberedList([]);
		expect(result).toBe("");
	});
});
