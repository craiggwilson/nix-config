/**
 * Tests for session-summary prompt template
 */

import { describe, it, expect } from "bun:test";

import { buildSessionSummaryPrompt } from "./session-summary.js";

describe("buildSessionSummaryPrompt", () => {
	it("includes conversation content", () => {
		const prompt = buildSessionSummaryPrompt({
			conversationContent: "Human: Hello\nAssistant: Hi there!",
		});

		expect(prompt).toContain("Human: Hello");
		expect(prompt).toContain("Assistant: Hi there!");
	});

	it("includes project name when provided", () => {
		const prompt = buildSessionSummaryPrompt({
			conversationContent: "Test content",
			projectName: "my-project",
		});

		expect(prompt).toContain("Project: my-project");
		expect(prompt).toContain("## Context");
	});

	it("includes planning phase when provided", () => {
		const prompt = buildSessionSummaryPrompt({
			conversationContent: "Test content",
			planningPhase: "discovery",
		});

		expect(prompt).toContain("Planning Phase: discovery");
		expect(prompt).toContain("## Context");
	});

	it("includes both project and phase when provided", () => {
		const prompt = buildSessionSummaryPrompt({
			conversationContent: "Test content",
			projectName: "my-project",
			planningPhase: "synthesis",
		});

		expect(prompt).toContain("Project: my-project");
		expect(prompt).toContain("Planning Phase: synthesis");
	});

	it("omits context section when no context provided", () => {
		const prompt = buildSessionSummaryPrompt({
			conversationContent: "Test content",
		});

		expect(prompt).not.toContain("## Context");
		expect(prompt).not.toContain("Project:");
		expect(prompt).not.toContain("Planning Phase:");
	});

	it("includes JSON format instructions", () => {
		const prompt = buildSessionSummaryPrompt({
			conversationContent: "Test content",
		});

		expect(prompt).toContain('"summary"');
		expect(prompt).toContain('"keyPoints"');
		expect(prompt).toContain('"openQuestionsAdded"');
		expect(prompt).toContain('"decisionsMade"');
		expect(prompt).toContain('"whatsNext"');
	});

	it("includes task instructions", () => {
		const prompt = buildSessionSummaryPrompt({
			conversationContent: "Test content",
		});

		expect(prompt).toContain("## Task");
		expect(prompt).toContain("Analyze the conversation");
		expect(prompt).toContain("2-3 sentence summary");
		expect(prompt).toContain("key points");
		expect(prompt).toContain("open questions");
		expect(prompt).toContain("decisions");
	});

	it("includes rules section", () => {
		const prompt = buildSessionSummaryPrompt({
			conversationContent: "Test content",
		});

		expect(prompt).toContain("Rules:");
		expect(prompt).toContain("max 300 characters");
		expect(prompt).toContain("can be empty array");
	});
});
