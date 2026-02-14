/**
 * Tests for Execution Pipelines
 */

import { test, expect } from "bun:test";
import { IssueStorage } from "../../core/src/index.ts";
import {
  ResearchPipeline,
  POCPipeline,
  ImplementationPipeline,
  ReviewPipeline,
} from "../src/pipelines/index.ts";

function createStorage(): IssueStorage {
  return new IssueStorage();
}

// ============================================================================
// ResearchPipeline Tests
// ============================================================================

test("ResearchPipeline can be instantiated", () => {
  const storage = createStorage();
  const pipeline = new ResearchPipeline(storage);
  expect(pipeline).toBeDefined();
  expect(pipeline.getState()).toBeNull();
});

test("ResearchPipeline executes all stages", async () => {
  const storage = createStorage();
  const pipeline = new ResearchPipeline(storage);

  const issue = await storage.createIssue({
    type: "task",
    title: "Research: Best approach for caching",
    description: `Question: What caching strategy should we use?
Scope: performance, scalability
Constraints:
- Must support distributed systems
- Must be cost-effective
Outcome: Provide a recommendation with pros/cons`,
    labels: ["research"],
  });
  await storage.updateIssue(issue.id, { status: "todo" });

  const result = await pipeline.execute(issue.id);

  expect(result.issueId).toBe(issue.id);
  expect(result.question).toBeTruthy();

  const state = pipeline.getState();
  expect(state).not.toBeNull();
  expect(state!.stages.length).toBe(5);
  expect(state!.stages.every((s) => s.status === "completed")).toBe(true);
});

test("ResearchPipeline creates follow-up issues via IssueStorage", async () => {
  const storage = createStorage();
  const pipeline = new ResearchPipeline(storage);

  const issue = await storage.createIssue({
    type: "task",
    title: "Research: API design patterns",
    description: "Question: What API design pattern should we use?",
    labels: ["research"],
    priority: 2,
  });
  await storage.updateIssue(issue.id, { status: "todo" });

  const result = await pipeline.execute(issue.id);

  const state = pipeline.getState();
  expect(state).not.toBeNull();

  if (state!.followUpTasks && state!.followUpTasks.length > 0) {
    for (const followUp of state!.followUpTasks) {
      const followUpIssue = await storage.getIssue(followUp.id);
      expect(followUpIssue).not.toBeNull();
      expect(followUpIssue!.labels).toContain(`discovered-from:${issue.id}`);
    }
  }
});

test("ResearchPipeline throws for non-existent issue", async () => {
  const storage = createStorage();
  const pipeline = new ResearchPipeline(storage);

  await expect(pipeline.execute("non-existent-id")).rejects.toThrow("not found");
});

// ============================================================================
// POCPipeline Tests
// ============================================================================

test("POCPipeline can be instantiated", () => {
  const storage = createStorage();
  const pipeline = new POCPipeline(storage);
  expect(pipeline).toBeDefined();
  expect(pipeline.getState()).toBeNull();
});

test("POCPipeline executes all stages", async () => {
  const storage = createStorage();
  const pipeline = new POCPipeline(storage);

  const issue = await storage.createIssue({
    type: "task",
    title: "POC: Redis caching layer",
    description: `Hypothesis: Redis can reduce API latency by 50%
Success criteria:
- Latency reduced by at least 50%
- Cache hit rate above 80%
- No data consistency issues
Timebox: 4 hours`,
    labels: ["poc"],
  });
  await storage.updateIssue(issue.id, { status: "todo" });

  const result = await pipeline.execute(issue.id);

  expect(result.issueId).toBe(issue.id);
  expect(result.hypothesis).toBeTruthy();
  expect(["keep", "refine", "discard"]).toContain(result.outcome);

  const state = pipeline.getState();
  expect(state).not.toBeNull();
  expect(state!.stages.length).toBe(6);
  expect(state!.stages.every((s) => s.status === "completed")).toBe(true);
});

test("POCPipeline creates discovered work via IssueStorage", async () => {
  const storage = createStorage();
  const pipeline = new POCPipeline(storage);

  const issue = await storage.createIssue({
    type: "task",
    title: "POC: New authentication flow",
    description: "Hypothesis: OAuth2 will simplify our auth",
    labels: ["poc"],
    priority: 1,
  });
  await storage.updateIssue(issue.id, { status: "todo" });

  const result = await pipeline.execute(issue.id);

  expect(result.discoveredWork).toBeDefined();
  expect(Array.isArray(result.discoveredWork)).toBe(true);

  for (const work of result.discoveredWork) {
    const workIssue = await storage.getIssue(work.id);
    expect(workIssue).not.toBeNull();
    expect(workIssue!.labels).toContain(`discovered-from:${issue.id}`);
  }
});

test("POCPipeline throws for non-existent issue", async () => {
  const storage = createStorage();
  const pipeline = new POCPipeline(storage);

  await expect(pipeline.execute("non-existent-id")).rejects.toThrow("not found");
});

// ============================================================================
// ImplementationPipeline Tests
// ============================================================================

test("ImplementationPipeline can be instantiated", () => {
  const storage = createStorage();
  const pipeline = new ImplementationPipeline(storage);
  expect(pipeline).toBeDefined();
  expect(pipeline.getState()).toBeNull();
});

test("ImplementationPipeline can be instantiated with config", () => {
  const storage = createStorage();
  const pipeline = new ImplementationPipeline(storage, {
    alwaysRunSecurityReview: false,
    maxFilesPerCommit: 5,
  });
  expect(pipeline).toBeDefined();
});

test("ImplementationPipeline executes all stages", async () => {
  const storage = createStorage();
  const pipeline = new ImplementationPipeline(storage);

  const issue = await storage.createIssue({
    type: "feature",
    title: "Add user profile page",
    description: `Requirements:
- Display user information
- Allow editing profile
- Show activity history
Acceptance criteria:
- Profile page loads in under 2 seconds
- All fields are editable
- Changes are persisted`,
    labels: ["implementation", "frontend"],
  });
  await storage.updateIssue(issue.id, { status: "todo" });

  const result = await pipeline.execute(issue.id);

  expect(result.issueId).toBe(issue.id);
  expect(result.status).toBe("completed");
  expect(result.changes).toBeDefined();
  expect(typeof result.testsRun).toBe("number");
  expect(typeof result.testsPassed).toBe("number");
  expect(typeof result.testsFailed).toBe("number");

  const state = pipeline.getState();
  expect(state).not.toBeNull();
  expect(state!.stages.length).toBe(7);
  expect(state!.stages.every((s) => s.status === "completed")).toBe(true);
});

test("ImplementationPipeline skips security review when configured", async () => {
  const storage = createStorage();
  const pipeline = new ImplementationPipeline(storage, {
    alwaysRunSecurityReview: false,
  });

  const issue = await storage.createIssue({
    type: "task",
    title: "Update documentation",
    description: "Update README with new instructions",
    labels: ["implementation", "docs"],
  });
  await storage.updateIssue(issue.id, { status: "todo" });

  const result = await pipeline.execute(issue.id);

  expect(result.status).toBe("completed");

  const state = pipeline.getState();
  expect(state).not.toBeNull();
  expect(state!.stages.length).toBe(6);
});

test("ImplementationPipeline creates follow-up issues for findings", async () => {
  const storage = createStorage();
  const pipeline = new ImplementationPipeline(storage);

  const issue = await storage.createIssue({
    type: "feature",
    title: "Implement payment processing",
    description: "Add payment processing capability",
    labels: ["implementation", "payments"],
  });
  await storage.updateIssue(issue.id, { status: "todo" });

  const result = await pipeline.execute(issue.id);

  expect(result.discoveredWork).toBeDefined();
  expect(Array.isArray(result.discoveredWork)).toBe(true);
});

test("ImplementationPipeline throws for non-existent issue", async () => {
  const storage = createStorage();
  const pipeline = new ImplementationPipeline(storage);

  await expect(pipeline.execute("non-existent-id")).rejects.toThrow("not found");
});

// ============================================================================
// ReviewPipeline Tests
// ============================================================================

test("ReviewPipeline can be instantiated", () => {
  const storage = createStorage();
  const pipeline = new ReviewPipeline(storage);
  expect(pipeline).toBeDefined();
  expect(pipeline.getState()).toBeNull();
});

test("ReviewPipeline executes all stages for code-review", async () => {
  const storage = createStorage();
  const pipeline = new ReviewPipeline(storage);

  const issue = await storage.createIssue({
    type: "task",
    title: "Review: PR #123",
    description: `PR: 123
Files: src/api/users.ts, src/api/auth.ts`,
    labels: ["review"],
  });
  await storage.updateIssue(issue.id, { status: "todo" });

  const result = await pipeline.execute(issue.id, "code-review");

  expect(result.issueId).toBe(issue.id);
  expect(result.mode).toBe("code-review");
  expect(result.findings).toBeDefined();
  expect(Array.isArray(result.findings)).toBe(true);

  const state = pipeline.getState();
  expect(state).not.toBeNull();
  expect(state!.stages.length).toBe(4);
  expect(state!.stages.every((s) => s.status === "completed")).toBe(true);
});

test("ReviewPipeline executes all stages for security-review", async () => {
  const storage = createStorage();
  const pipeline = new ReviewPipeline(storage);

  const issue = await storage.createIssue({
    type: "task",
    title: "Security Review: Authentication module",
    description: `Commit: abc123
Files: src/auth/login.ts`,
    labels: ["security-review"],
  });
  await storage.updateIssue(issue.id, { status: "todo" });

  const result = await pipeline.execute(issue.id, "security-review");

  expect(result.issueId).toBe(issue.id);
  expect(result.mode).toBe("security-review");

  const state = pipeline.getState();
  expect(state).not.toBeNull();
  expect(state!.stages.length).toBe(4);
});

test("ReviewPipeline executes all stages for both modes", async () => {
  const storage = createStorage();
  const pipeline = new ReviewPipeline(storage);

  const issue = await storage.createIssue({
    type: "task",
    title: "Full Review: Payment module",
    description: "Review payment processing code",
    labels: ["review", "security-review"],
  });
  await storage.updateIssue(issue.id, { status: "todo" });

  const result = await pipeline.execute(issue.id, "both");

  expect(result.issueId).toBe(issue.id);
  expect(result.mode).toBe("both");

  const state = pipeline.getState();
  expect(state).not.toBeNull();
  expect(state!.stages.length).toBe(4);
});

test("ReviewPipeline creates follow-up issues for critical findings", async () => {
  const storage = createStorage();
  const pipeline = new ReviewPipeline(storage);

  const issue = await storage.createIssue({
    type: "task",
    title: "Review: API endpoints",
    description: "Review all API endpoints",
    labels: ["review"],
  });
  await storage.updateIssue(issue.id, { status: "todo" });

  const result = await pipeline.execute(issue.id, "code-review");

  expect(result.followUpIssues).toBeDefined();
  expect(Array.isArray(result.followUpIssues)).toBe(true);
});

test("ReviewPipeline throws for non-existent issue", async () => {
  const storage = createStorage();
  const pipeline = new ReviewPipeline(storage);

  await expect(pipeline.execute("non-existent-id", "code-review")).rejects.toThrow("not found");
});

// ============================================================================
// Integration Tests
// ============================================================================

test("Pipelines update issue status to done on completion", async () => {
  const storage = createStorage();

  const researchIssue = await storage.createIssue({
    type: "task",
    title: "Research task",
    labels: ["research"],
  });
  await storage.updateIssue(researchIssue.id, { status: "todo" });

  const researchPipeline = new ResearchPipeline(storage);
  await researchPipeline.execute(researchIssue.id);

  const updatedIssue = await storage.getIssue(researchIssue.id);
  expect(updatedIssue!.status).toBe("done");
});

test("Pipelines append results to issue description", async () => {
  const storage = createStorage();

  const pocIssue = await storage.createIssue({
    type: "task",
    title: "POC task",
    description: "Original description",
    labels: ["poc"],
  });
  await storage.updateIssue(pocIssue.id, { status: "todo" });

  const pocPipeline = new POCPipeline(storage);
  await pocPipeline.execute(pocIssue.id);

  const updatedIssue = await storage.getIssue(pocIssue.id);
  expect(updatedIssue!.description).toContain("Original description");
  expect(updatedIssue!.description).toContain("POC Results");
});
