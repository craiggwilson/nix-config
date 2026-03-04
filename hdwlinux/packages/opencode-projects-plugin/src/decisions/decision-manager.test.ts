/**
 * Tests for DecisionManager
 */

import { describe, test, expect, beforeEach, afterEach } from "bun:test";
import * as fs from "node:fs/promises";
import * as path from "node:path";
import * as os from "node:os";

import {
	DecisionManager,
	type DecisionIndex,
	type DecisionRecord,
} from "./decision-manager.js";
import { ArtifactRegistry } from "../artifacts/index.js";
import { createMockLogger } from "../utils/testing/index.js";

describe("DecisionManager", () => {
	let testDir: string;
	let artifactRegistry: ArtifactRegistry;
	let manager: DecisionManager;

	beforeEach(async () => {
		testDir = await fs.mkdtemp(
			path.join(os.tmpdir(), "decision-manager-test-"),
		);
		artifactRegistry = new ArtifactRegistry(testDir, createMockLogger());
		await artifactRegistry.load();
		manager = new DecisionManager(
			testDir,
			artifactRegistry,
			createMockLogger(),
		);
	});

	afterEach(async () => {
		await fs.rm(testDir, { recursive: true, force: true });
	});

	describe("load", () => {
		test("creates empty index if directory doesn't exist", async () => {
			const index = await manager.load();

			expect(index.pending).toEqual([]);
			expect(index.decided).toEqual([]);
			expect(index.superseded).toEqual([]);
		});

		test("loads existing index from file", async () => {
			const decisionsDir = path.join(testDir, "decisions");
			await fs.mkdir(decisionsDir, { recursive: true });

			const existingIndex = `# Decision Log

## Pending Decisions

### Choose authentication protocol
**Question:** Which authentication protocol should we use?
**Context:** Need to support mobile and web clients
**Blocking:** auth-implementation, mobile-app

---

## Decided

### OAuth2 with PKCE
**Status:** Decided
**Date:** 2026-03-01
**Decision:** Use OAuth2 with PKCE for all authentication
**Link:** [Full record](./2026-03-01-oauth2-with-pkce.md)

---

## Superseded

### Basic Auth
**Date:** 2026-02-15
**Superseded By:** decision-oauth2-abc123
**Link:** [Full record](./2026-02-15-basic-auth.md)

`;
			await fs.writeFile(path.join(decisionsDir, "index.md"), existingIndex);

			const index = await manager.load();

			expect(index.pending).toHaveLength(1);
			expect(index.pending[0].question).toBe(
				"Which authentication protocol should we use?",
			);
			expect(index.pending[0].context).toBe(
				"Need to support mobile and web clients",
			);
			expect(index.pending[0].blocking).toEqual([
				"auth-implementation",
				"mobile-app",
			]);

			expect(index.decided).toHaveLength(1);
			expect(index.decided[0].title).toBe("OAuth2 with PKCE");
			expect(index.decided[0].status).toBe("decided");
			expect(index.decided[0].filename).toBe("2026-03-01-oauth2-with-pkce.md");

			expect(index.superseded).toHaveLength(1);
			expect(index.superseded[0].title).toBe("Basic Auth");
			expect(index.superseded[0].supersededBy).toBe("decision-oauth2-abc123");
		});

		test("creates decisions directory on first use", async () => {
			await manager.load();

			await manager.recordDecision({
				title: "Test Decision",
				decision: "Test decision content",
				rationale: "Test rationale",
			});

			const decisionsDir = path.join(testDir, "decisions");
			const stat = await fs.stat(decisionsDir);
			expect(stat.isDirectory()).toBe(true);
		});
	});

	describe("recordDecision", () => {
		beforeEach(async () => {
			await manager.load();
		});

		test("records decision with all fields", async () => {
			const result = await manager.recordDecision({
				title: "OAuth2 over SAML",
				decision: "Use OAuth2 with PKCE instead of SAML for authentication",
				rationale: "Better mobile support and simpler implementation",
				status: "decided",
				alternatives: [
					{
						name: "SAML",
						description: "Enterprise SSO standard",
						whyRejected: "Poor mobile support",
					},
					{
						name: "Basic Auth",
						description: "Simple username/password",
						whyRejected: "Not secure enough",
					},
				],
				sourceSession: "ses_abc123",
				sourceResearch: ["research-auth-patterns-abc123"],
				relatedIssues: ["proj-123.1", "proj-123.2"],
			});

			expect(result.ok).toBe(true);
			if (result.ok) {
				expect(result.value.title).toBe("OAuth2 over SAML");
				expect(result.value.decision).toBe(
					"Use OAuth2 with PKCE instead of SAML for authentication",
				);
				expect(result.value.rationale).toBe(
					"Better mobile support and simpler implementation",
				);
				expect(result.value.status).toBe("decided");
				expect(result.value.alternatives).toHaveLength(2);
				expect(result.value.alternatives?.[0].name).toBe("SAML");
				expect(result.value.sourceSession).toBe("ses_abc123");
				expect(result.value.sourceResearch).toEqual([
					"research-auth-patterns-abc123",
				]);
				expect(result.value.relatedIssues).toEqual([
					"proj-123.1",
					"proj-123.2",
				]);
				expect(result.value.id).toMatch(/^decision-/);
				expect(result.value.createdAt).toBeDefined();
				expect(result.value.updatedAt).toBeDefined();
			}
		});

		test("generates correct filename format {date}-{slug}.md", async () => {
			const result = await manager.recordDecision({
				title: "OAuth2 with PKCE",
				decision: "Use OAuth2 with PKCE",
				rationale: "Better security",
			});

			expect(result.ok).toBe(true);
			if (result.ok) {
				const today = new Date().toISOString().split("T")[0];
				expect(result.value.filename).toBe(`${today}-oauth2-with-pkce.md`);
				expect(result.value.slug).toBe("oauth2-with-pkce");
			}
		});

		test("writes decision file with correct format", async () => {
			const result = await manager.recordDecision({
				title: "Test Decision",
				decision: "This is the decision content.",
				rationale: "This is the rationale.",
				alternatives: [
					{
						name: "Alternative A",
						description: "Description of A",
						whyRejected: "Reason A was rejected",
					},
				],
				sourceSession: "ses_test123",
				sourceResearch: ["research-test-abc"],
				relatedIssues: ["issue-1"],
			});

			expect(result.ok).toBe(true);
			if (!result.ok) return;

			const decisionPath = path.join(
				testDir,
				"decisions",
				result.value.filename,
			);
			const content = await fs.readFile(decisionPath, "utf-8");

			expect(content).toContain("# Decision: Test Decision");
			expect(content).toContain("**Status:** Decided");
			expect(content).toContain("## Decision");
			expect(content).toContain("This is the decision content.");
			expect(content).toContain("## Rationale");
			expect(content).toContain("This is the rationale.");
			expect(content).toContain("## Alternatives Considered");
			expect(content).toContain("### Alternative A");
			expect(content).toContain("Description of A");
			expect(content).toContain("**Why rejected:** Reason A was rejected");
			expect(content).toContain("## Sources");
			expect(content).toContain("**Session:** [ses_test123]");
			expect(content).toContain("**Research:** [research-test-abc]");
			expect(content).toContain("## Related Issues");
			expect(content).toContain("- issue-1");
		});

		test("registers artifact in registry", async () => {
			const result = await manager.recordDecision({
				title: "Artifact Test Decision",
				decision: "Test decision",
				rationale: "Test rationale",
			});

			expect(result.ok).toBe(true);
			if (!result.ok) return;

			const artifact = artifactRegistry.getById(result.value.id);
			expect(artifact).not.toBeNull();
			expect(artifact?.type).toBe("decision");
			expect(artifact?.title).toBe("Artifact Test Decision");
		});

		test("defaults status to decided", async () => {
			const result = await manager.recordDecision({
				title: "Default Status Decision",
				decision: "Test decision",
				rationale: "Test rationale",
			});

			expect(result.ok).toBe(true);
			if (result.ok) {
				expect(result.value.status).toBe("decided");
			}
		});

		test("handles proposed status", async () => {
			const result = await manager.recordDecision({
				title: "Proposed Decision",
				decision: "Proposed decision content",
				rationale: "Proposed rationale",
				status: "proposed",
			});

			expect(result.ok).toBe(true);
			if (result.ok) {
				expect(result.value.status).toBe("proposed");
			}
		});

		test("handles rejected status", async () => {
			const result = await manager.recordDecision({
				title: "Rejected Decision",
				decision: "Rejected decision content",
				rationale: "Rejected rationale",
				status: "rejected",
			});

			expect(result.ok).toBe(true);
			if (result.ok) {
				expect(result.value.status).toBe("rejected");
			}
		});

		test("handles deferred status", async () => {
			const result = await manager.recordDecision({
				title: "Deferred Decision",
				decision: "Deferred decision content",
				rationale: "Deferred rationale",
				status: "deferred",
			});

			expect(result.ok).toBe(true);
			if (result.ok) {
				expect(result.value.status).toBe("deferred");
			}
		});

		test("handles superseded status", async () => {
			const result = await manager.recordDecision({
				title: "Superseded Decision",
				decision: "Superseded decision content",
				rationale: "Superseded rationale",
				status: "superseded",
			});

			expect(result.ok).toBe(true);
			if (result.ok) {
				expect(result.value.status).toBe("superseded");
				// Should be in superseded list, not decided
				const decisions = manager.list({ status: "superseded" });
				expect(decisions.some((d) => d.id === result.value.id)).toBe(true);
			}
		});

		test("returns error for duplicate title", async () => {
			await manager.recordDecision({
				title: "Duplicate Title",
				decision: "First decision",
				rationale: "First rationale",
			});

			const result = await manager.recordDecision({
				title: "Duplicate Title",
				decision: "Second decision",
				rationale: "Second rationale",
			});

			expect(result.ok).toBe(false);
			if (!result.ok && result.error.type === "already_exists") {
				expect(result.error.title).toBe("Duplicate Title");
			}
		});

		test("returns error for duplicate title case-insensitive", async () => {
			await manager.recordDecision({
				title: "Case Test",
				decision: "First decision",
				rationale: "First rationale",
			});

			const result = await manager.recordDecision({
				title: "CASE TEST",
				decision: "Second decision",
				rationale: "Second rationale",
			});

			expect(result.ok).toBe(false);
			if (!result.ok) {
				expect(result.error.type).toBe("already_exists");
			}
		});

		test("sorts decisions alphabetically by title", async () => {
			await manager.recordDecision({
				title: "Zebra Decision",
				decision: "Z decision",
				rationale: "Z rationale",
			});

			await manager.recordDecision({
				title: "Alpha Decision",
				decision: "A decision",
				rationale: "A rationale",
			});

			await manager.recordDecision({
				title: "Middle Decision",
				decision: "M decision",
				rationale: "M rationale",
			});

			const decisions = manager.list();
			expect(decisions[0].title).toBe("Alpha Decision");
			expect(decisions[1].title).toBe("Middle Decision");
			expect(decisions[2].title).toBe("Zebra Decision");
		});
	});

	describe("updateStatus", () => {
		let decisionId: string;

		beforeEach(async () => {
			await manager.load();
			const result = await manager.recordDecision({
				title: "Status Test Decision",
				decision: "Test decision",
				rationale: "Test rationale",
				status: "proposed",
			});
			if (result.ok) {
				decisionId = result.value.id;
			}
		});

		test("updates status from proposed to decided", async () => {
			const result = await manager.updateStatus(decisionId, "decided");

			expect(result.ok).toBe(true);
			if (result.ok) {
				expect(result.value.status).toBe("decided");
			}
		});

		test("updates status from proposed to rejected", async () => {
			const result = await manager.updateStatus(decisionId, "rejected");

			expect(result.ok).toBe(true);
			if (result.ok) {
				expect(result.value.status).toBe("rejected");
			}
		});

		test("updates status from proposed to deferred", async () => {
			const result = await manager.updateStatus(decisionId, "deferred");

			expect(result.ok).toBe(true);
			if (result.ok) {
				expect(result.value.status).toBe("deferred");
			}
		});

		test("updates status to superseded with supersededBy", async () => {
			// First create a decided decision
			const decidedResult = await manager.recordDecision({
				title: "Original Decision",
				decision: "Original",
				rationale: "Original rationale",
				status: "decided",
			});
			expect(decidedResult.ok).toBe(true);
			if (!decidedResult.ok) return;

			const newDecisionResult = await manager.recordDecision({
				title: "New Decision",
				decision: "New",
				rationale: "New rationale",
				status: "decided",
			});
			expect(newDecisionResult.ok).toBe(true);
			if (!newDecisionResult.ok) return;

			const result = await manager.updateStatus(
				decidedResult.value.id,
				"superseded",
				newDecisionResult.value.id,
			);

			expect(result.ok).toBe(true);
			if (result.ok) {
				expect(result.value.status).toBe("superseded");
				expect(result.value.supersededBy).toBe(newDecisionResult.value.id);
			}
		});

		test("returns error for invalid transition from decided to proposed", async () => {
			// Create a decided decision
			const decidedResult = await manager.recordDecision({
				title: "Decided Decision",
				decision: "Decided",
				rationale: "Decided rationale",
				status: "decided",
			});
			expect(decidedResult.ok).toBe(true);
			if (!decidedResult.ok) return;

			const result = await manager.updateStatus(
				decidedResult.value.id,
				"proposed",
			);

			expect(result.ok).toBe(false);
			if (!result.ok && result.error.type === "invalid_transition") {
				expect(result.error.from).toBe("decided");
				expect(result.error.to).toBe("proposed");
			}
		});

		test("returns error for invalid transition from superseded", async () => {
			// Create and supersede a decision
			const decidedResult = await manager.recordDecision({
				title: "To Be Superseded",
				decision: "Original",
				rationale: "Original rationale",
				status: "decided",
			});
			expect(decidedResult.ok).toBe(true);
			if (!decidedResult.ok) return;

			await manager.updateStatus(
				decidedResult.value.id,
				"superseded",
				"some-other-id",
			);

			const result = await manager.updateStatus(
				decidedResult.value.id,
				"decided",
			);

			expect(result.ok).toBe(false);
			if (!result.ok && result.error.type === "invalid_transition") {
				expect(result.error.from).toBe("superseded");
			}
		});

		test("updates updatedAt timestamp", async () => {
			const originalDecision = manager.getById(decisionId);
			expect(originalDecision).not.toBeNull();
			const originalUpdatedAt = originalDecision?.updatedAt;

			// Small delay to ensure timestamp difference
			await new Promise((resolve) => setTimeout(resolve, 10));

			const result = await manager.updateStatus(decisionId, "decided");

			expect(result.ok).toBe(true);
			if (result.ok) {
				expect(result.value.updatedAt).not.toBe(originalUpdatedAt);
				expect(new Date(result.value.updatedAt).getTime()).toBeGreaterThan(
					new Date(originalUpdatedAt).getTime(),
				);
			}
		});

		test("returns error for non-existent decision", async () => {
			const result = await manager.updateStatus("non-existent-id", "decided");

			expect(result.ok).toBe(false);
			if (!result.ok && result.error.type === "not_found") {
				expect(result.error.id).toBe("non-existent-id");
			}
		});

		test("moves decision from decided to superseded list", async () => {
			const decidedResult = await manager.recordDecision({
				title: "Move Test Decision",
				decision: "Test",
				rationale: "Test rationale",
				status: "decided",
			});
			expect(decidedResult.ok).toBe(true);
			if (!decidedResult.ok) return;

			// Verify it's in decided list
			let decidedList = manager.list({ status: "decided" });
			expect(decidedList.some((d) => d.id === decidedResult.value.id)).toBe(
				true,
			);

			// Supersede it
			await manager.updateStatus(
				decidedResult.value.id,
				"superseded",
				"new-decision-id",
			);

			// Verify it moved to superseded list
			decidedList = manager.list({ status: "decided" });
			const supersededList = manager.list({ status: "superseded" });

			expect(decidedList.some((d) => d.id === decidedResult.value.id)).toBe(
				false,
			);
			expect(supersededList.some((d) => d.id === decidedResult.value.id)).toBe(
				true,
			);
		});
	});

	describe("pending decisions", () => {
		beforeEach(async () => {
			await manager.load();
		});

		test("adds pending decision", async () => {
			await manager.addPendingDecision({
				question: "Which database should we use?",
				context: "Need to support high write throughput",
				blocking: ["data-layer-implementation"],
				relatedResearch: ["research-databases-abc123"],
			});

			const pending = manager.getPending();
			expect(pending).toHaveLength(1);
			expect(pending[0].question).toBe("Which database should we use?");
			expect(pending[0].context).toBe("Need to support high write throughput");
			expect(pending[0].blocking).toEqual(["data-layer-implementation"]);
			expect(pending[0].relatedResearch).toEqual(["research-databases-abc123"]);
		});

		test("removes pending decision", async () => {
			await manager.addPendingDecision({
				question: "Question to remove?",
			});

			expect(manager.getPending()).toHaveLength(1);

			await manager.removePendingDecision("Question to remove?");

			expect(manager.getPending()).toHaveLength(0);
		});

		test("removes pending decision case-insensitive", async () => {
			await manager.addPendingDecision({
				question: "Case Sensitive Question?",
			});

			await manager.removePendingDecision("case sensitive question?");

			expect(manager.getPending()).toHaveLength(0);
		});

		test("does not add duplicate pending decisions", async () => {
			await manager.addPendingDecision({
				question: "Duplicate question?",
			});

			await manager.addPendingDecision({
				question: "Duplicate question?",
			});

			expect(manager.getPending()).toHaveLength(1);
		});

		test("does not add duplicate pending decisions case-insensitive", async () => {
			await manager.addPendingDecision({
				question: "Case Question?",
			});

			await manager.addPendingDecision({
				question: "CASE QUESTION?",
			});

			expect(manager.getPending()).toHaveLength(1);
		});

		test("lists pending decisions", async () => {
			await manager.addPendingDecision({ question: "Question 1?" });
			await manager.addPendingDecision({ question: "Question 2?" });
			await manager.addPendingDecision({ question: "Question 3?" });

			const pending = manager.getPending();
			expect(pending).toHaveLength(3);
			expect(pending.map((p) => p.question)).toContain("Question 1?");
			expect(pending.map((p) => p.question)).toContain("Question 2?");
			expect(pending.map((p) => p.question)).toContain("Question 3?");
		});

		test("persists pending decisions across instances", async () => {
			await manager.addPendingDecision({
				question: "Persistent question?",
				context: "Some context",
			});

			const newManager = new DecisionManager(
				testDir,
				artifactRegistry,
				createMockLogger(),
			);
			const index = await newManager.load();

			expect(index.pending).toHaveLength(1);
			expect(index.pending[0].question).toBe("Persistent question?");
		});
	});

	describe("querying", () => {
		beforeEach(async () => {
			await manager.load();

			await manager.recordDecision({
				title: "Decided One",
				decision: "Decision 1",
				rationale: "Rationale 1",
				status: "decided",
			});

			await manager.recordDecision({
				title: "Decided Two",
				decision: "Decision 2",
				rationale: "Rationale 2",
				status: "decided",
			});

			await manager.recordDecision({
				title: "Proposed One",
				decision: "Proposed decision",
				rationale: "Proposed rationale",
				status: "proposed",
			});

			await manager.recordDecision({
				title: "Rejected One",
				decision: "Rejected decision",
				rationale: "Rejected rationale",
				status: "rejected",
			});

			await manager.recordDecision({
				title: "Deferred One",
				decision: "Deferred decision",
				rationale: "Deferred rationale",
				status: "deferred",
			});
		});

		test("list() returns all decisions", () => {
			const decisions = manager.list();
			expect(decisions).toHaveLength(5);
		});

		test("list({ status: 'decided' }) filters by decided status", () => {
			const decisions = manager.list({ status: "decided" });
			expect(decisions).toHaveLength(2);
			expect(decisions.every((d) => d.status === "decided")).toBe(true);
		});

		test("list({ status: 'proposed' }) filters by proposed status", () => {
			const decisions = manager.list({ status: "proposed" });
			expect(decisions).toHaveLength(1);
			expect(decisions[0].status).toBe("proposed");
		});

		test("list({ status: 'rejected' }) filters by rejected status", () => {
			const decisions = manager.list({ status: "rejected" });
			expect(decisions).toHaveLength(1);
			expect(decisions[0].status).toBe("rejected");
		});

		test("list({ status: 'deferred' }) filters by deferred status", () => {
			const decisions = manager.list({ status: "deferred" });
			expect(decisions).toHaveLength(1);
			expect(decisions[0].status).toBe("deferred");
		});

		test("list({ status: 'superseded' }) returns superseded decisions", async () => {
			// First get a decided decision and supersede it
			const decidedDecisions = manager.list({ status: "decided" });
			expect(decidedDecisions.length).toBeGreaterThan(0);

			await manager.updateStatus(
				decidedDecisions[0].id,
				"superseded",
				"new-id",
			);

			const superseded = manager.list({ status: "superseded" });
			expect(superseded).toHaveLength(1);
			expect(superseded[0].status).toBe("superseded");
		});

		test("getById() returns decision or null", async () => {
			const decisions = manager.list();
			const firstDecision = decisions[0];

			const found = manager.getById(firstDecision.id);
			expect(found).not.toBeNull();
			expect(found?.id).toBe(firstDecision.id);

			const notFound = manager.getById("non-existent-id");
			expect(notFound).toBeNull();
		});

		test("getById() finds decisions in superseded list", async () => {
			const decidedDecisions = manager.list({ status: "decided" });
			const decisionId = decidedDecisions[0].id;

			await manager.updateStatus(decisionId, "superseded", "new-id");

			const found = manager.getById(decisionId);
			expect(found).not.toBeNull();
			expect(found?.status).toBe("superseded");
		});

		test("getPending() returns pending decisions", async () => {
			await manager.addPendingDecision({ question: "Pending 1?" });
			await manager.addPendingDecision({ question: "Pending 2?" });

			const pending = manager.getPending();
			expect(pending).toHaveLength(2);
		});
	});

	describe("formatDecisionFile", () => {
		beforeEach(async () => {
			await manager.load();
		});

		test("produces valid markdown with all sections", () => {
			const record: DecisionRecord = {
				id: "decision-test-abc123",
				slug: "test-decision",
				filename: "2026-03-02-test-decision.md",
				title: "Test Decision",
				status: "decided",
				decision: "This is the decision content.",
				rationale: "This is the rationale.",
				alternatives: [
					{
						name: "Alternative A",
						description: "Description of A",
						whyRejected: "Reason A was rejected",
					},
					{
						name: "Alternative B",
						description: "Description of B",
					},
				],
				sourceSession: "ses_test123",
				sourceResearch: ["research-auth-abc", "research-db-def"],
				relatedIssues: ["issue-1", "issue-2"],
				createdAt: "2026-03-02T10:30:00.000Z",
				updatedAt: "2026-03-02T11:00:00.000Z",
			};

			const content = manager.formatDecisionFile(record);

			expect(content).toContain("# Decision: Test Decision");
			expect(content).toContain("**Date:** 2026-03-02");
			expect(content).toContain("**Status:** Decided");
			expect(content).toContain("**Updated:** 2026-03-02T11:00:00.000Z");
			expect(content).toContain("## Decision");
			expect(content).toContain("This is the decision content.");
			expect(content).toContain("## Rationale");
			expect(content).toContain("This is the rationale.");
			expect(content).toContain("## Alternatives Considered");
			expect(content).toContain("### Alternative A");
			expect(content).toContain("Description of A");
			expect(content).toContain("**Why rejected:** Reason A was rejected");
			expect(content).toContain("### Alternative B");
			expect(content).toContain("Description of B");
			expect(content).toContain("## Sources");
			expect(content).toContain(
				"**Session:** [ses_test123](../sessions/ses_test123.md)",
			);
			expect(content).toContain(
				"**Research:** [research-auth-abc](../research/research-auth-abc.md)",
			);
			expect(content).toContain(
				"**Research:** [research-db-def](../research/research-db-def.md)",
			);
			expect(content).toContain("## Related Issues");
			expect(content).toContain("- issue-1");
			expect(content).toContain("- issue-2");
		});

		test("omits empty optional sections", () => {
			const record: DecisionRecord = {
				id: "decision-minimal-abc123",
				slug: "minimal-decision",
				filename: "2026-03-02-minimal-decision.md",
				title: "Minimal Decision",
				status: "decided",
				decision: "Minimal decision content.",
				rationale: "Minimal rationale.",
				createdAt: "2026-03-02T10:30:00.000Z",
				updatedAt: "2026-03-02T10:30:00.000Z",
			};

			const content = manager.formatDecisionFile(record);

			expect(content).toContain("## Decision");
			expect(content).toContain("## Rationale");
			expect(content).not.toContain("## Alternatives Considered");
			expect(content).not.toContain("## Sources");
			expect(content).not.toContain("## Related Issues");
			expect(content).not.toContain("## Superseded By");
		});

		test("includes supersededBy section when present", () => {
			const record: DecisionRecord = {
				id: "decision-old-abc123",
				slug: "old-decision",
				filename: "2026-03-01-old-decision.md",
				title: "Old Decision",
				status: "superseded",
				decision: "Old decision content.",
				rationale: "Old rationale.",
				createdAt: "2026-03-01T10:30:00.000Z",
				updatedAt: "2026-03-02T10:30:00.000Z",
				supersededBy: "decision-new-def456",
			};

			const content = manager.formatDecisionFile(record);

			expect(content).toContain("## Superseded By");
			expect(content).toContain(
				"This decision has been superseded by: decision-new-def456",
			);
		});

		test("formats all status types correctly", () => {
			const statuses = [
				"proposed",
				"decided",
				"rejected",
				"deferred",
				"superseded",
			] as const;

			for (const status of statuses) {
				const record: DecisionRecord = {
					id: `decision-${status}-abc123`,
					slug: `${status}-decision`,
					filename: `2026-03-02-${status}-decision.md`,
					title: `${status.charAt(0).toUpperCase() + status.slice(1)} Decision`,
					status,
					decision: "Decision content.",
					rationale: "Rationale.",
					createdAt: "2026-03-02T10:30:00.000Z",
					updatedAt: "2026-03-02T10:30:00.000Z",
				};

				const content = manager.formatDecisionFile(record);
				const expectedStatus = status.charAt(0).toUpperCase() + status.slice(1);
				expect(content).toContain(`**Status:** ${expectedStatus}`);
			}
		});
	});

	describe("formatIndexFile", () => {
		beforeEach(async () => {
			await manager.load();
		});

		test("produces valid markdown with all sections", () => {
			const index: DecisionIndex = {
				pending: [
					{
						question: "Which database should we use?",
						context: "Need high write throughput",
						blocking: ["data-layer"],
						relatedResearch: ["research-db-abc"],
					},
				],
				decided: [
					{
						id: "decision-oauth2-abc123",
						slug: "oauth2-with-pkce",
						filename: "2026-03-02-oauth2-with-pkce.md",
						title: "OAuth2 with PKCE",
						status: "decided",
						decision: "Use OAuth2 with PKCE for authentication",
						rationale: "Better mobile support",
						createdAt: "2026-03-02T10:00:00.000Z",
						updatedAt: "2026-03-02T10:00:00.000Z",
					},
				],
				superseded: [
					{
						id: "decision-basic-auth-def456",
						slug: "basic-auth",
						filename: "2026-02-15-basic-auth.md",
						title: "Basic Auth",
						status: "superseded",
						decision: "Use basic authentication",
						rationale: "Simple to implement",
						createdAt: "2026-02-15T10:00:00.000Z",
						updatedAt: "2026-03-02T10:00:00.000Z",
						supersededBy: "decision-oauth2-abc123",
					},
				],
			};

			const content = manager.formatIndexFile(index);

			expect(content).toContain("# Decision Log");
			expect(content).toContain("## Pending Decisions");
			expect(content).toContain("**Question:** Which database should we use?");
			expect(content).toContain("**Context:** Need high write throughput");
			expect(content).toContain("**Blocking:** data-layer");
			expect(content).toContain("**Related Research:**");
			expect(content).toContain("[research-db-abc]");
			expect(content).toContain("## Decided");
			expect(content).toContain("### OAuth2 with PKCE");
			expect(content).toContain("**Status:** Decided");
			expect(content).toContain("**Date:** 2026-03-02");
			expect(content).toContain(
				"**Decision:** Use OAuth2 with PKCE for authentication",
			);
			expect(content).toContain(
				"**Link:** [Full record](./2026-03-02-oauth2-with-pkce.md)",
			);
			expect(content).toContain("## Superseded");
			expect(content).toContain("### Basic Auth");
			expect(content).toContain("**Superseded By:** decision-oauth2-abc123");
		});

		test("shows placeholder text for empty sections", () => {
			const index: DecisionIndex = {
				pending: [],
				decided: [],
				superseded: [],
			};

			const content = manager.formatIndexFile(index);

			expect(content).toContain("*No pending decisions*");
			expect(content).toContain("*No decisions recorded yet*");
			expect(content).toContain("*(None yet)*");
		});

		test("formats multiple pending decisions correctly", () => {
			const index: DecisionIndex = {
				pending: [
					{ question: "Question 1?" },
					{ question: "Question 2?", context: "Context 2" },
				],
				decided: [],
				superseded: [],
			};

			const content = manager.formatIndexFile(index);

			expect(content).toContain("**Question:** Question 1?");
			expect(content).toContain("**Question:** Question 2?");
			expect(content).toContain("**Context:** Context 2");
		});

		test("formats multiple decided entries correctly", () => {
			const index: DecisionIndex = {
				pending: [],
				decided: [
					{
						id: "decision-1",
						slug: "decision-one",
						filename: "2026-03-02-decision-one.md",
						title: "Decision One",
						status: "decided",
						decision: "First decision",
						rationale: "First rationale",
						createdAt: "2026-03-02T10:00:00.000Z",
						updatedAt: "2026-03-02T10:00:00.000Z",
					},
					{
						id: "decision-2",
						slug: "decision-two",
						filename: "2026-03-02-decision-two.md",
						title: "Decision Two",
						status: "decided",
						decision: "Second decision",
						rationale: "Second rationale",
						createdAt: "2026-03-02T11:00:00.000Z",
						updatedAt: "2026-03-02T11:00:00.000Z",
					},
				],
				superseded: [],
			};

			const content = manager.formatIndexFile(index);

			expect(content).toContain("### Decision One");
			expect(content).toContain("### Decision Two");
			expect(content).toContain("**Decision:** First decision");
			expect(content).toContain("**Decision:** Second decision");
		});
	});

	describe("persistence across instances", () => {
		test("new manager instance loads previously saved decisions", async () => {
			await manager.load();
			await manager.recordDecision({
				title: "Persistent Decision",
				decision: "Persistent content",
				rationale: "Persistent rationale",
			});

			const newArtifactRegistry = new ArtifactRegistry(
				testDir,
				createMockLogger(),
			);
			await newArtifactRegistry.load();
			const newManager = new DecisionManager(
				testDir,
				newArtifactRegistry,
				createMockLogger(),
			);
			const index = await newManager.load();

			expect(index.decided).toHaveLength(1);
			expect(index.decided[0].title).toBe("Persistent Decision");
		});

		test("pending decisions persist across instances", async () => {
			await manager.load();
			await manager.addPendingDecision({
				question: "Persistent pending question?",
				context: "Some context",
			});

			const newArtifactRegistry = new ArtifactRegistry(
				testDir,
				createMockLogger(),
			);
			await newArtifactRegistry.load();
			const newManager = new DecisionManager(
				testDir,
				newArtifactRegistry,
				createMockLogger(),
			);
			const index = await newManager.load();

			expect(index.pending).toHaveLength(1);
			expect(index.pending[0].question).toBe("Persistent pending question?");
		});

		test("status updates persist across instances", async () => {
			await manager.load();
			const result = await manager.recordDecision({
				title: "Status Persist Test",
				decision: "Test",
				rationale: "Test",
				status: "proposed",
			});
			expect(result.ok).toBe(true);
			if (!result.ok) return;

			await manager.updateStatus(result.value.id, "decided");

			const newArtifactRegistry = new ArtifactRegistry(
				testDir,
				createMockLogger(),
			);
			await newArtifactRegistry.load();
			const newManager = new DecisionManager(
				testDir,
				newArtifactRegistry,
				createMockLogger(),
			);
			const index = await newManager.load();

			// The index parser reconstructs decisions from markdown, so IDs may differ.
			// Verify by title instead.
			const decision = index.decided.find(
				(d) => d.title === "Status Persist Test",
			);
			expect(decision).not.toBeUndefined();
			expect(decision?.status).toBe("decided");
		});
	});

	describe("slug generation", () => {
		beforeEach(async () => {
			await manager.load();
		});

		test("generates lowercase hyphenated slug", async () => {
			const result = await manager.recordDecision({
				title: "Use OAuth2 With PKCE",
				decision: "Test",
				rationale: "Test",
			});

			expect(result.ok).toBe(true);
			if (result.ok) {
				expect(result.value.slug).toBe("use-oauth2-with-pkce");
			}
		});

		test("removes special characters from slug", async () => {
			const result = await manager.recordDecision({
				title: "OAuth2 (with PKCE!) for Auth",
				decision: "Test",
				rationale: "Test",
			});

			expect(result.ok).toBe(true);
			if (result.ok) {
				expect(result.value.slug).toBe("oauth2-with-pkce-for-auth");
			}
		});

		test("truncates long slugs to 50 characters", async () => {
			const result = await manager.recordDecision({
				title:
					"This Is A Very Long Decision Title That Should Be Truncated To Fifty Characters Maximum",
				decision: "Test",
				rationale: "Test",
			});

			expect(result.ok).toBe(true);
			if (result.ok) {
				expect(result.value.slug.length).toBeLessThanOrEqual(50);
			}
		});

		test("removes leading and trailing hyphens from slug", async () => {
			const result = await manager.recordDecision({
				title: "---Test Decision---",
				decision: "Test",
				rationale: "Test",
			});

			expect(result.ok).toBe(true);
			if (result.ok) {
				expect(result.value.slug).not.toMatch(/^-/);
				expect(result.value.slug).not.toMatch(/-$/);
			}
		});
	});
});
