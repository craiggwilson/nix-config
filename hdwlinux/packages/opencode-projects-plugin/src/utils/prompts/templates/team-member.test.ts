/**
 * Tests for team member prompt templates
 */

import { describe, it, expect } from "bun:test";

import { teamMemberTemplate } from "./team-member.js";
import type { PrimaryMemberData, ReviewerMemberData } from "./team-member.js";

describe("teamMemberTemplate", () => {
	it("has correct name and description", () => {
		expect(teamMemberTemplate.name).toBe("team-member");
		expect(teamMemberTemplate.description).toContain("team member");
	});

	describe("primary role", () => {
		const basePrimaryData: PrimaryMemberData = {
			role: "primary",
			agent: "coder",
			hasReviewers: false,
			issueContext: "Implement user authentication",
			issueId: "proj-123.1",
			projectDir: "/tmp/test-project",
		};

		it("renders primary agent prompt", () => {
			const prompt = teamMemberTemplate.render(basePrimaryData);

			expect(prompt).toContain("# Task: proj-123.1");
			expect(prompt).toContain("PRIMARY agent");
			expect(prompt).toContain("coder");
			expect(prompt).toContain("Implement user authentication");
		});

		it("includes responsibilities for primary", () => {
			const prompt = teamMemberTemplate.render(basePrimaryData);

			expect(prompt).toContain("Your Responsibilities");
			expect(prompt).toContain("Complete the main work");
			expect(prompt).toContain("Write code");
			expect(prompt).toContain("Commit your changes");
		});

		it("includes worktree info when provided", () => {
			const prompt = teamMemberTemplate.render({
				...basePrimaryData,
				worktreePath: "/tmp/worktree-123",
			});

			expect(prompt).toContain("## Worktree");
			expect(prompt).toContain("/tmp/worktree-123");
			expect(prompt).toContain("isolated worktree");
		});

		it("includes reviewer note when hasReviewers is true", () => {
			const prompt = teamMemberTemplate.render({
				...basePrimaryData,
				hasReviewers: true,
			});

			expect(prompt).toContain("## Note");
			expect(prompt).toContain("Other agents will review");
			expect(prompt).toContain("quality implementation");
		});

		it("excludes reviewer note when hasReviewers is false", () => {
			const prompt = teamMemberTemplate.render({
				...basePrimaryData,
				hasReviewers: false,
			});

			expect(prompt).not.toContain("Other agents will review");
		});

		it("includes project context section", () => {
			const prompt = teamMemberTemplate.render(basePrimaryData);

			expect(prompt).toContain("## Project Context");
			expect(prompt).toContain("/tmp/test-project");
			expect(prompt).toContain("/tmp/test-project/research/");
			expect(prompt).toContain("/tmp/test-project/decisions/");
			expect(prompt).toContain("project-save-artifact");
		});

		it("includes delegation constraints", () => {
			const prompt = teamMemberTemplate.render(basePrimaryData);

			expect(prompt).toContain("## Constraints");
			expect(prompt).toContain("background delegation");
			expect(prompt).toContain("disabled");
		});
	});

	describe("reviewer role", () => {
		const baseReviewerData: ReviewerMemberData = {
			role: "reviewer",
			agent: "reviewer",
			issueContext: "Implement user authentication",
			issueId: "proj-123.1",
			primaryAgent: "coder",
			projectDir: "/tmp/test-project",
		};

		it("renders reviewer prompt", () => {
			const prompt = teamMemberTemplate.render(baseReviewerData);

			expect(prompt).toContain("# Review Task: proj-123.1");
			expect(prompt).toContain("REVIEWER");
			expect(prompt).toContain("reviewer");
			expect(prompt).toContain("Implement user authentication");
		});

		it("includes primary agent reference", () => {
			const prompt = teamMemberTemplate.render(baseReviewerData);

			expect(prompt).toContain("Primary Agent's Work");
			expect(prompt).toContain("coder");
			expect(prompt).toContain("implementing this");
		});

		it("includes reviewer responsibilities", () => {
			const prompt = teamMemberTemplate.render(baseReviewerData);

			expect(prompt).toContain("Review their approach");
			expect(prompt).toContain("Identify BLOCKING issues");
			expect(prompt).toContain("constructive feedback");
		});

		it("includes worktree info with read-only constraint", () => {
			const prompt = teamMemberTemplate.render({
				...baseReviewerData,
				worktreePath: "/tmp/worktree-123",
			});

			expect(prompt).toContain("## Worktree");
			expect(prompt).toContain("/tmp/worktree-123");
			expect(prompt).toContain("read files");
			expect(prompt).toContain("read-only");
		});

		it("includes project context section", () => {
			const prompt = teamMemberTemplate.render(baseReviewerData);

			expect(prompt).toContain("## Project Context");
			expect(prompt).toContain("/tmp/test-project");
			expect(prompt).toContain("/tmp/test-project/research/");
			expect(prompt).toContain("/tmp/test-project/decisions/");
		});

		it("includes delegation constraints", () => {
			const prompt = teamMemberTemplate.render(baseReviewerData);

			expect(prompt).toContain("## Constraints");
			expect(prompt).toContain("background delegation");
		});
	});

	describe("devilsAdvocate role", () => {
		const devilsAdvocateData: ReviewerMemberData = {
			role: "devilsAdvocate",
			agent: "critic",
			issueContext: "Implement user authentication",
			issueId: "proj-123.1",
			primaryAgent: "coder",
			projectDir: "/tmp/test-project",
		};

		it("renders devils advocate prompt", () => {
			const prompt = teamMemberTemplate.render(devilsAdvocateData);

			expect(prompt).toContain("# Review Task: proj-123.1");
			expect(prompt).toContain("REVIEWER");
			expect(prompt).toContain("critic");
		});

		it("includes devils advocate guidance", () => {
			const prompt = teamMemberTemplate.render(devilsAdvocateData);

			expect(prompt).toContain("Devil's Advocate");
		});

		it("includes standard reviewer responsibilities", () => {
			const prompt = teamMemberTemplate.render(devilsAdvocateData);

			expect(prompt).toContain("Review their approach");
			expect(prompt).toContain("Identify BLOCKING issues");
		});

		it("includes critical analysis responsibilities", () => {
			const prompt = teamMemberTemplate.render(devilsAdvocateData);

			// Verify devil's advocate specific guidance is injected
			expect(prompt).toContain("Your Mandate");
			expect(prompt).toContain("What Constitutes a Blocker");
			expect(prompt).toContain("Do NOT rubber-stamp");
		});

		it("includes output format guidance", () => {
			const prompt = teamMemberTemplate.render(devilsAdvocateData);

			// Verify expected output sections are mentioned
			expect(prompt).toContain("Blockers (if any)");
			expect(prompt).toContain("Concerns (non-blocking)");
			expect(prompt).toContain("Verdict");
		});

		it("includes guidelines for thorough review", () => {
			const prompt = teamMemberTemplate.render(devilsAdvocateData);

			// Verify guidelines are present
			expect(prompt).toContain("find problems others missed");
			expect(prompt).toContain("Anti-Patterns");
			expect(prompt).toContain(
				"Maintain your position if you believe you're right",
			);
		});

		it("devil's advocate prompt is different from regular reviewer", () => {
			const reviewerData: ReviewerMemberData = {
				role: "reviewer",
				agent: "reviewer",
				issueId: "proj-123.1",
				issueContext: "Implement user authentication",
				primaryAgent: "coder",
				projectDir: "/tmp/test-project",
			};

			const reviewerPrompt = teamMemberTemplate.render(reviewerData);
			const daPrompt = teamMemberTemplate.render(devilsAdvocateData);

			// Devil's advocate should have additional content
			expect(daPrompt.length).toBeGreaterThan(reviewerPrompt.length);
			// Devil's advocate should have specific sections not in reviewer
			expect(daPrompt).toContain("Devil's Advocate Role");
			expect(reviewerPrompt).not.toContain("Devil's Advocate Role");
		});

		it("includes worktree info with read-only constraint for devil's advocate", () => {
			const prompt = teamMemberTemplate.render({
				...devilsAdvocateData,
				worktreePath: "/tmp/worktree-123",
			});

			expect(prompt).toContain("## Worktree");
			expect(prompt).toContain("/tmp/worktree-123");
			expect(prompt).toContain("read files");
			expect(prompt).toContain("read-only");
		});
	});
});
