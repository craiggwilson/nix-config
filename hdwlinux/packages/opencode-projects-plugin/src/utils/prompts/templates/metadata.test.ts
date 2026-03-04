/**
 * Tests for metadata generation prompt template
 */

import { describe, it, expect } from "bun:test";

import { metadataGenerationTemplate } from "./metadata.js";

describe("metadataGenerationTemplate", () => {
	it("has correct name and description", () => {
		expect(metadataGenerationTemplate.name).toBe("metadata-generation");
		expect(metadataGenerationTemplate.description).toContain(
			"title and description",
		);
	});

	it("includes result in prompt", () => {
		const prompt = metadataGenerationTemplate.render({
			result: "Successfully implemented the feature",
		});

		expect(prompt).toContain("Successfully implemented the feature");
	});

	it("includes rules for title and description", () => {
		const prompt = metadataGenerationTemplate.render({
			result: "Test result",
		});

		expect(prompt).toContain("Title:");
		expect(prompt).toContain("Description:");
		expect(prompt).toContain("2-5 words");
		expect(prompt).toContain("max 30 characters");
		expect(prompt).toContain("2-3 sentences");
		expect(prompt).toContain("max 200 characters");
	});

	it("includes JSON format instructions", () => {
		const prompt = metadataGenerationTemplate.render({
			result: "Test result",
		});

		expect(prompt).toContain('"title"');
		expect(prompt).toContain('"description"');
		expect(prompt).toContain("valid JSON");
	});

	it("truncates long results to default max length", () => {
		const longResult = "x".repeat(3000);
		const prompt = metadataGenerationTemplate.render({
			result: longResult,
		});

		expect(prompt.length).toBeLessThan(longResult.length + 500);
		expect(prompt).toContain("x".repeat(100));
	});

	it("uses custom max length when provided", () => {
		const longResult = "x".repeat(500);
		const prompt = metadataGenerationTemplate.render({
			result: longResult,
			maxResultLength: 100,
		});

		expect(prompt).toContain("x".repeat(100));
		expect(prompt).not.toContain("x".repeat(200));
	});
});
