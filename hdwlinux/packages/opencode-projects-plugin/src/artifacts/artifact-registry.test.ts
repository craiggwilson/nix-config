/**
 * Tests for ArtifactRegistry
 */

import { describe, test, expect, beforeEach, afterEach } from "bun:test";
import * as fs from "node:fs/promises";
import * as path from "node:path";
import * as os from "node:os";

import {
	ArtifactRegistry,
	type ArtifactRegistryData,
} from "./artifact-registry.js";
import { createMockLogger } from "../utils/testing/index.js";

describe("ArtifactRegistry", () => {
	let testDir: string;
	let registry: ArtifactRegistry;

	beforeEach(async () => {
		testDir = await fs.mkdtemp(
			path.join(os.tmpdir(), "artifact-registry-test-"),
		);
		registry = new ArtifactRegistry(testDir, createMockLogger());
	});

	afterEach(async () => {
		await fs.rm(testDir, { recursive: true, force: true });
	});

	describe("load", () => {
		test("creates empty registry if file doesn't exist", async () => {
			await registry.load();

			const artifacts = registry.list();

			expect(artifacts).toEqual([]);
		});

		test("loads existing registry from file", async () => {
			const existingData: ArtifactRegistryData = {
				artifacts: [
					{
						id: "research-test-abc123",
						type: "research",
						title: "Test Artifact",
						path: "research/test.md",
						absolutePath: path.join(testDir, "research/test.md"),
						external: false,
						createdAt: "2026-01-15T10:00:00.000Z",
						sourceIssue: "proj-123.1",
					},
				],
			};
			await fs.writeFile(
				path.join(testDir, "artifacts.json"),
				JSON.stringify(existingData, null, 2),
			);

			await registry.load();

			const artifacts = registry.list();
			expect(artifacts).toHaveLength(1);
			expect(artifacts[0].id).toBe("research-test-abc123");
			expect(artifacts[0].title).toBe("Test Artifact");
		});

		test("throws on malformed JSON", async () => {
			await fs.writeFile(
				path.join(testDir, "artifacts.json"),
				"{ invalid json }",
			);

			await expect(registry.load()).rejects.toThrow();
		});
	});

	describe("save", () => {
		test("saves registry to file", async () => {
			await registry.load();
			await registry.register({
				type: "research",
				title: "Save Test",
				path: "research/save-test.md",
				absolutePath: path.join(testDir, "research/save-test.md"),
				external: false,
			});

			const content = await fs.readFile(
				path.join(testDir, "artifacts.json"),
				"utf-8",
			);
			const data = JSON.parse(content) as ArtifactRegistryData;

			expect(data.artifacts).toHaveLength(1);
			expect(data.artifacts[0].title).toBe("Save Test");
		});

		test("persists multiple artifacts", async () => {
			await registry.load();
			await registry.register({
				type: "research",
				title: "First",
				path: "first.md",
				absolutePath: path.join(testDir, "first.md"),
				external: false,
			});
			await registry.register({
				type: "decision",
				title: "Second",
				path: "second.md",
				absolutePath: path.join(testDir, "second.md"),
				external: false,
			});

			const content = await fs.readFile(
				path.join(testDir, "artifacts.json"),
				"utf-8",
			);
			const data = JSON.parse(content) as ArtifactRegistryData;

			expect(data.artifacts).toHaveLength(2);
		});
	});

	describe("generateId", () => {
		test("generates IDs in format {type}-{slug}-{random}", async () => {
			await registry.load();

			const id = registry.generateId("research", "Authentication Patterns");

			expect(id).toMatch(/^research-authentication-patterns-[a-f0-9]{6}$/);
		});

		test("slugifies titles to lowercase with hyphens", async () => {
			await registry.load();

			const id = registry.generateId("decision", "Use OAuth2 For SSO");

			expect(id).toMatch(/^decision-use-oauth2-for-sso-[a-f0-9]{6}$/);
		});

		test("handles special characters in titles", async () => {
			await registry.load();

			const id = registry.generateId(
				"research",
				"API Design: REST vs GraphQL!",
			);

			expect(id).toMatch(/^research-api-design-rest-vs-graphql-[a-f0-9]{6}$/);
		});

		test("handles leading/trailing special characters", async () => {
			await registry.load();

			const id = registry.generateId("research", "---Test Title---");

			expect(id).toMatch(/^research-test-title-[a-f0-9]{6}$/);
		});

		test("truncates long titles to 30 characters", async () => {
			await registry.load();

			const longTitle =
				"This Is A Very Long Title That Should Be Truncated To Thirty Characters";
			const id = registry.generateId("research", longTitle);

			// Extract the slug portion (between first hyphen after type and last hyphen before random)
			const parts = id.split("-");
			const slug = parts.slice(1, -1).join("-");

			expect(slug.length).toBeLessThanOrEqual(30);
		});

		test("handles numeric titles", async () => {
			await registry.load();

			const id = registry.generateId("deliverable", "2026 Q1 Report");

			expect(id).toMatch(/^deliverable-2026-q1-report-[a-f0-9]{6}$/);
		});

		test("handles empty title gracefully", async () => {
			await registry.load();

			const id = registry.generateId("research", "");

			// Empty title results in just type and random
			expect(id).toMatch(/^research--[a-f0-9]{6}$/);
		});

		test("generates unique IDs for same input", async () => {
			await registry.load();

			const id1 = registry.generateId("research", "Same Title");
			const id2 = registry.generateId("research", "Same Title");

			expect(id1).not.toBe(id2);
		});
	});

	describe("register", () => {
		test("registers new artifacts successfully", async () => {
			await registry.load();

			const result = await registry.register({
				type: "research",
				title: "Authentication Patterns",
				path: "research/auth-patterns.md",
				absolutePath: path.join(testDir, "research/auth-patterns.md"),
				external: false,
				sourceIssue: "proj-abc123.1",
				summary: "Analysis of OAuth2 vs SAML",
			});

			expect(result.ok).toBe(true);
			if (result.ok) {
				expect(result.value.id).toMatch(
					/^research-authentication-patterns-[a-f0-9]{6}$/,
				);
				expect(result.value.type).toBe("research");
				expect(result.value.title).toBe("Authentication Patterns");
				expect(result.value.sourceIssue).toBe("proj-abc123.1");
				expect(result.value.summary).toBe("Analysis of OAuth2 vs SAML");
			}
		});

		test("sets createdAt timestamp", async () => {
			await registry.load();
			const before = new Date().toISOString();

			const result = await registry.register({
				type: "research",
				title: "Timestamp Test",
				path: "test.md",
				absolutePath: path.join(testDir, "test.md"),
				external: false,
			});

			const after = new Date().toISOString();

			expect(result.ok).toBe(true);
			if (result.ok) {
				expect(result.value.createdAt).toBeDefined();
				expect(result.value.createdAt >= before).toBe(true);
				expect(result.value.createdAt <= after).toBe(true);
			}
		});

		test("returns error for duplicate absolute path", async () => {
			await registry.load();
			const absolutePath = path.join(testDir, "duplicate.md");

			await registry.register({
				type: "research",
				title: "First",
				path: "duplicate.md",
				absolutePath,
				external: false,
			});

			const result = await registry.register({
				type: "decision",
				title: "Second",
				path: "duplicate.md",
				absolutePath,
				external: false,
			});

			expect(result.ok).toBe(false);
			if (!result.ok && result.error.type === "already_exists") {
				expect(result.error.id).toMatch(/^research-first-[a-f0-9]{6}$/);
			}
		});

		test("allows same relative path with different absolute paths", async () => {
			await registry.load();

			const result1 = await registry.register({
				type: "research",
				title: "First",
				path: "same-relative.md",
				absolutePath: path.join(testDir, "dir1/same-relative.md"),
				external: false,
			});

			const result2 = await registry.register({
				type: "research",
				title: "Second",
				path: "same-relative.md",
				absolutePath: path.join(testDir, "dir2/same-relative.md"),
				external: false,
			});

			expect(result1.ok).toBe(true);
			expect(result2.ok).toBe(true);
		});

		test("handles external artifacts", async () => {
			await registry.load();

			const result = await registry.register({
				type: "deliverable",
				title: "External Doc",
				path: "/workspace/docs/external.md",
				absolutePath: "/workspace/docs/external.md",
				external: true,
			});

			expect(result.ok).toBe(true);
			if (result.ok) {
				expect(result.value.external).toBe(true);
			}
		});

		test("handles optional fields", async () => {
			await registry.load();

			const result = await registry.register({
				type: "research",
				title: "Minimal",
				path: "minimal.md",
				absolutePath: path.join(testDir, "minimal.md"),
				external: false,
			});

			expect(result.ok).toBe(true);
			if (result.ok) {
				expect(result.value.sourceIssue).toBeUndefined();
				expect(result.value.sourceSession).toBeUndefined();
				expect(result.value.summary).toBeUndefined();
			}
		});

		test("includes sourceSession when provided", async () => {
			await registry.load();

			const result = await registry.register({
				type: "research",
				title: "Session Test",
				path: "session.md",
				absolutePath: path.join(testDir, "session.md"),
				external: false,
				sourceSession: "1-abc123-2026-01-15",
			});

			expect(result.ok).toBe(true);
			if (result.ok) {
				expect(result.value.sourceSession).toBe("1-abc123-2026-01-15");
			}
		});
	});

	describe("list", () => {
		beforeEach(async () => {
			await registry.load();
			await registry.register({
				type: "research",
				title: "Research One",
				path: "research/one.md",
				absolutePath: path.join(testDir, "research/one.md"),
				external: false,
				sourceIssue: "proj-123.1",
				sourceSession: "session-1",
			});
			await registry.register({
				type: "research",
				title: "Research Two",
				path: "research/two.md",
				absolutePath: path.join(testDir, "research/two.md"),
				external: false,
				sourceIssue: "proj-123.2",
				sourceSession: "session-1",
			});
			await registry.register({
				type: "decision",
				title: "Decision One",
				path: "decisions/one.md",
				absolutePath: path.join(testDir, "decisions/one.md"),
				external: false,
				sourceIssue: "proj-123.1",
				sourceSession: "session-2",
			});
		});

		test("returns all artifacts without filters", () => {
			const artifacts = registry.list();

			expect(artifacts).toHaveLength(3);
		});

		test("filters by type", () => {
			const artifacts = registry.list({ type: "research" });

			expect(artifacts).toHaveLength(2);
			expect(artifacts.every((a) => a.type === "research")).toBe(true);
		});

		test("filters by sourceIssue", () => {
			const artifacts = registry.list({ sourceIssue: "proj-123.1" });

			expect(artifacts).toHaveLength(2);
			expect(artifacts.every((a) => a.sourceIssue === "proj-123.1")).toBe(true);
		});

		test("filters by sourceSession", () => {
			const artifacts = registry.list({ sourceSession: "session-1" });

			expect(artifacts).toHaveLength(2);
			expect(artifacts.every((a) => a.sourceSession === "session-1")).toBe(
				true,
			);
		});

		test("combines multiple filters with AND logic", () => {
			const artifacts = registry.list({
				type: "research",
				sourceIssue: "proj-123.1",
			});

			expect(artifacts).toHaveLength(1);
			expect(artifacts[0].title).toBe("Research One");
		});

		test("returns empty array when no matches", () => {
			const artifacts = registry.list({ type: "nonexistent" });

			expect(artifacts).toEqual([]);
		});
	});

	describe("getById", () => {
		test("returns artifact when found", async () => {
			await registry.load();
			const registerResult = await registry.register({
				type: "research",
				title: "Find Me",
				path: "find.md",
				absolutePath: path.join(testDir, "find.md"),
				external: false,
			});

			expect(registerResult.ok).toBe(true);
			if (!registerResult.ok) return;

			const artifact = registry.getById(registerResult.value.id);

			expect(artifact).not.toBeNull();
			expect(artifact?.title).toBe("Find Me");
		});

		test("returns null when not found", async () => {
			await registry.load();

			const artifact = registry.getById("nonexistent-id");

			expect(artifact).toBeNull();
		});
	});

	describe("getByIssue", () => {
		test("returns artifacts for an issue", async () => {
			await registry.load();
			await registry.register({
				type: "research",
				title: "Issue Artifact 1",
				path: "issue1.md",
				absolutePath: path.join(testDir, "issue1.md"),
				external: false,
				sourceIssue: "proj-abc.1",
			});
			await registry.register({
				type: "decision",
				title: "Issue Artifact 2",
				path: "issue2.md",
				absolutePath: path.join(testDir, "issue2.md"),
				external: false,
				sourceIssue: "proj-abc.1",
			});
			await registry.register({
				type: "research",
				title: "Other Issue",
				path: "other.md",
				absolutePath: path.join(testDir, "other.md"),
				external: false,
				sourceIssue: "proj-abc.2",
			});

			const artifacts = registry.getByIssue("proj-abc.1");

			expect(artifacts).toHaveLength(2);
			expect(artifacts.every((a) => a.sourceIssue === "proj-abc.1")).toBe(true);
		});

		test("returns empty array when no artifacts for issue", async () => {
			await registry.load();

			const artifacts = registry.getByIssue("nonexistent-issue");

			expect(artifacts).toEqual([]);
		});
	});

	describe("getBySession", () => {
		test("returns artifacts for a session", async () => {
			await registry.load();
			await registry.register({
				type: "research",
				title: "Session Artifact 1",
				path: "session1.md",
				absolutePath: path.join(testDir, "session1.md"),
				external: false,
				sourceSession: "1-abc123-2026-01-15",
			});
			await registry.register({
				type: "research",
				title: "Session Artifact 2",
				path: "session2.md",
				absolutePath: path.join(testDir, "session2.md"),
				external: false,
				sourceSession: "1-abc123-2026-01-15",
			});
			await registry.register({
				type: "research",
				title: "Other Session",
				path: "other.md",
				absolutePath: path.join(testDir, "other.md"),
				external: false,
				sourceSession: "2-def456-2026-01-16",
			});

			const artifacts = registry.getBySession("1-abc123-2026-01-15");

			expect(artifacts).toHaveLength(2);
			expect(
				artifacts.every((a) => a.sourceSession === "1-abc123-2026-01-15"),
			).toBe(true);
		});

		test("returns empty array when no artifacts for session", async () => {
			await registry.load();

			const artifacts = registry.getBySession("nonexistent-session");

			expect(artifacts).toEqual([]);
		});
	});

	describe("getByType", () => {
		test("returns artifacts of a type", async () => {
			await registry.load();
			await registry.register({
				type: "research",
				title: "Research 1",
				path: "r1.md",
				absolutePath: path.join(testDir, "r1.md"),
				external: false,
			});
			await registry.register({
				type: "research",
				title: "Research 2",
				path: "r2.md",
				absolutePath: path.join(testDir, "r2.md"),
				external: false,
			});
			await registry.register({
				type: "decision",
				title: "Decision 1",
				path: "d1.md",
				absolutePath: path.join(testDir, "d1.md"),
				external: false,
			});

			const artifacts = registry.getByType("research");

			expect(artifacts).toHaveLength(2);
			expect(artifacts.every((a) => a.type === "research")).toBe(true);
		});

		test("returns empty array when no artifacts of type", async () => {
			await registry.load();

			const artifacts = registry.getByType("nonexistent-type");

			expect(artifacts).toEqual([]);
		});
	});

	describe("persistence across instances", () => {
		test("new registry instance loads previously saved artifacts", async () => {
			await registry.load();
			const result = await registry.register({
				type: "research",
				title: "Persistent",
				path: "persistent.md",
				absolutePath: path.join(testDir, "persistent.md"),
				external: false,
			});

			expect(result.ok).toBe(true);
			if (!result.ok) return;

			const newRegistry = new ArtifactRegistry(testDir, createMockLogger());
			await newRegistry.load();

			const artifacts = newRegistry.list();
			expect(artifacts).toHaveLength(1);
			expect(artifacts[0].id).toBe(result.value.id);
		});
	});
});
