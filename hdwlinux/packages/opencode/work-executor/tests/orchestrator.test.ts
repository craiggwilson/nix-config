/**
 * Tests for WorkExecutorOrchestrator
 */

import { test } from "bun:test";
import { WorkExecutorOrchestrator } from "../src/orchestrator.js";
import { ConfigManager, IssueStorage } from "../../core/src/index.ts";

function createOrchestrator() {
  const storage = new IssueStorage();
  const configManager = new ConfigManager("/tmp/opencode-test-config");
  return { storage, orchestrator: new WorkExecutorOrchestrator(storage, configManager) };
}

test("claimWork selects a ready task and marks it in_progress", async () => {
  const { storage, orchestrator } = createOrchestrator();

  const todoLow = await storage.createIssue({
    type: "task",
    title: "Low priority",
    priority: 3,
    labels: ["implementation"],
  });

  const todoHigh = await storage.createIssue({
    type: "task",
    title: "High priority",
    priority: 1,
    labels: ["implementation"],
  });

  await storage.updateIssue(todoLow.id, { status: "todo" });
  await storage.updateIssue(todoHigh.id, { status: "todo" });

  const result = await orchestrator.claimWork();

  if (result.workItemId !== todoHigh.id) {
    throw new Error(`Expected ${todoHigh.id} but got ${result.workItemId}`);
  }

  const claimed = await storage.getIssue(result.workItemId);
  if (!claimed || claimed.status !== "in_progress" || claimed.assignee !== "agent:work-executor") {
    throw new Error("Claimed item was not updated correctly");
  }
});

test("executeWork routes by label and honors mode filters", async () => {
  const { storage, orchestrator } = createOrchestrator();

  const research = await storage.createIssue({
    type: "task",
    title: "Research task",
    labels: ["research"],
  });

  const poc = await storage.createIssue({
    type: "task",
    title: "POC task",
    labels: ["poc"],
  });

  const impl = await storage.createIssue({
    type: "task",
    title: "Implementation task",
  });

  await storage.updateIssue(research.id, { status: "todo" });
  await storage.updateIssue(poc.id, { status: "todo" });
  await storage.updateIssue(impl.id, { status: "todo" });

  const researchOnly = await orchestrator.executeWork({
    issueIds: [research.id, poc.id],
    mode: "research-only",
  });

  const researchResult = researchOnly.results.find((r) => r.issueId === research.id);
  const pocResult = researchOnly.results.find((r) => r.issueId === poc.id);

  if (!researchResult || researchResult.status !== "completed") {
    throw new Error("Research item should complete in research-only mode");
  }

  if (!pocResult || pocResult.status !== "partial") {
    throw new Error("POC item should be marked partial/skipped in research-only mode");
  }

  const full = await orchestrator.executeWork({
    issueIds: [research.id, poc.id, impl.id],
    mode: "full",
  });

  if (full.results.length !== 3) {
    throw new Error("Expected 3 results in full mode");
  }
});
