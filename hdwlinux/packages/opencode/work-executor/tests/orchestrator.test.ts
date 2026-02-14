/**
 * Tests for WorkExecutorOrchestrator
 */

import { test } from "bun:test";
import { WorkExecutorOrchestrator } from "../src/orchestrator.js";
import { ConfigManager, IssueStorage } from "../../core/src/index.ts";
import { SubagentDispatcher } from "../../core/src/orchestration/subagent-dispatcher.js";
import type { SubagentTask, SubagentResult } from "../../core/src/orchestration/subagent-dispatcher.js";

function createOrchestrator() {
  const storage = new IssueStorage();
  const configManager = new ConfigManager("/tmp/opencode-test-config");
  return { storage, orchestrator: new WorkExecutorOrchestrator(storage, configManager) };
}

function createOrchestratorWithDispatcher(
  executionHandler: (agentName: string, task: SubagentTask) => Promise<SubagentResult>,
) {
  const storage = new IssueStorage();
  const configManager = new ConfigManager("/tmp/opencode-test-config");
  const dispatcher = new SubagentDispatcher({ executionHandler });
  return {
    storage,
    orchestrator: new WorkExecutorOrchestrator(storage, configManager, { dispatcher }),
  };
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

test("executeWork uses dispatcher to select agents before pipeline dispatch", async () => {
  const agentSelections: string[][] = [];
  const { storage, orchestrator } = createOrchestratorWithDispatcher(
    async (agentName, task) => {
      return {
        agentName,
        status: "success",
        findings: ["Agent finding"],
        recommendations: ["Agent recommendation"],
      };
    },
  );

  const task = await storage.createIssue({
    type: "task",
    title: "Kafka implementation",
    labels: ["kafka", "implementation"],
  });
  await storage.updateIssue(task.id, { status: "todo" });

  const result = await orchestrator.executeWork({
    issueIds: [task.id],
    mode: "full",
  });

  if (result.results.length !== 1) {
    throw new Error("Expected 1 result");
  }
  if (result.results[0].status !== "completed") {
    throw new Error("Task should be completed");
  }
});

test("dispatcher is passed to pipelines during execution", async () => {
  const dispatchedAgents: string[] = [];
  const { storage, orchestrator } = createOrchestratorWithDispatcher(
    async (agentName, task) => {
      dispatchedAgents.push(agentName);
      return {
        agentName,
        status: "success",
        findings: ["Pipeline agent finding"],
        recommendations: ["Pipeline agent recommendation"],
      };
    },
  );

  // Research task - pipeline should use dispatcher in gatherContext and analyzeOptions
  const research = await storage.createIssue({
    type: "task",
    title: "Research Kafka patterns",
    labels: ["research", "kafka"],
  });
  await storage.updateIssue(research.id, { status: "todo" });

  await orchestrator.executeResearch(research.id);

  // Dispatcher should have been called by the pipeline
  if (dispatchedAgents.length === 0) {
    throw new Error("Dispatcher should have been called by the research pipeline");
  }
});

test("orchestrator works without custom dispatcher (default behavior)", async () => {
  const { storage, orchestrator } = createOrchestrator();

  const task = await storage.createIssue({
    type: "task",
    title: "Simple task",
    labels: ["implementation"],
  });
  await storage.updateIssue(task.id, { status: "todo" });

  const result = await orchestrator.executeWork({
    issueIds: [task.id],
    mode: "full",
  });

  if (result.results.length !== 1) {
    throw new Error("Expected 1 result");
  }
  if (result.results[0].status !== "completed") {
    throw new Error("Task should be completed with default dispatcher");
  }
});
