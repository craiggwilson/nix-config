/**
 * Tests for ProjectPlannerOrchestrator getProjectFocus
 */

import { test } from "bun:test";
import { ProjectPlannerOrchestrator } from "../src/orchestrator.js";
import type { WorkExecutorDelegate } from "../src/orchestrator.js";
import { ConfigManager, IssueStorage } from "../../core/src/index.ts";
import { SubagentDispatcher } from "../../core/src/orchestration/subagent-dispatcher.js";
import type { SubagentTask, SubagentResult } from "../../core/src/orchestration/subagent-dispatcher.js";

function createOrchestrator() {
  const storage = new IssueStorage();
  const configManager = new ConfigManager("/tmp/opencode-test-config");
  return { storage, orchestrator: new ProjectPlannerOrchestrator(storage, configManager) };
}

function createOrchestratorWithDispatcher(
  executionHandler: (agentName: string, task: SubagentTask) => Promise<SubagentResult>,
) {
  const storage = new IssueStorage();
  const configManager = new ConfigManager("/tmp/opencode-test-config");
  const dispatcher = new SubagentDispatcher({ executionHandler });
  return {
    storage,
    orchestrator: new ProjectPlannerOrchestrator(storage, configManager, { dispatcher }),
  };
}

test("getProjectFocus returns ready children sorted by priority", async () => {
  const { storage, orchestrator } = createOrchestrator();

  // Create a project epic
  const project = await storage.createIssue({
    type: "epic",
    title: "Test Project",
    labels: ["project", "project:test"],
    priority: 1,
  });

  // Child items: two ready, one blocked by dependency
  const high = await storage.createIssue({
    type: "task",
    title: "High priority task",
    parent: project.id,
    priority: 1,
  });

  const low = await storage.createIssue({
    type: "task",
    title: "Low priority task",
    parent: project.id,
    priority: 3,
  });

  const blocked = await storage.createIssue({
    type: "task",
    title: "Blocked task",
    parent: project.id,
    priority: 1,
  });

  // Mark all as todo
  await storage.updateIssue(high.id, { status: "todo" });
  await storage.updateIssue(low.id, { status: "todo" });
  await storage.updateIssue(blocked.id, { status: "todo" });

  // Block the blocked task on the high task
  await storage.createDependency(blocked.id, high.id, "needs");

  const focus = await orchestrator.getProjectFocus(project.id);

  if (focus.readyItems.length !== 2) {
    throw new Error(`Expected 2 ready items, got ${focus.readyItems.length}`);
  }

  const [first, second] = focus.readyItems;
  if (first.id !== high.id || second.id !== low.id) {
    throw new Error("Ready items not sorted by priority as expected");
  }

  if (focus.suggestedNext !== high.id) {
    throw new Error("suggestedNext should point at highest-priority ready item");
  }
});

test("planProject uses dispatcher to enrich backlog item descriptions", async () => {
  const dispatchCalls: SubagentTask[] = [];
  const { storage, orchestrator } = createOrchestratorWithDispatcher(
    async (agentName, task) => {
      dispatchCalls.push(task);
      return {
        agentName,
        status: "success",
        findings: ["Existing patterns found"],
        recommendations: ["Use event-driven approach"],
      };
    },
  );

  const project = await storage.createIssue({
    type: "epic",
    title: "Kafka Service",
    labels: ["project", "kafka"],
    priority: 1,
  });

  const result = await orchestrator.planProject({ projectId: project.id });

  // Should have created backlog items
  if (result.createdItems.length !== 4) {
    throw new Error(`Expected 4 backlog items, got ${result.createdItems.length}`);
  }

  // Dispatcher should have been called
  if (dispatchCalls.length === 0) {
    throw new Error("Dispatcher was not called during planProject");
  }

  // Backlog items should be enriched with agent recommendations
  const firstItem = await storage.getIssue(result.createdItems[0]);
  if (!firstItem) throw new Error("First backlog item not found");
  if (!firstItem.description?.includes("Agent Recommendations")) {
    throw new Error("Backlog item description should contain agent recommendations");
  }
});

test("planSprint uses dispatcher for sprint analysis", async () => {
  const dispatchCalls: SubagentTask[] = [];
  const { storage, orchestrator } = createOrchestratorWithDispatcher(
    async (agentName, task) => {
      dispatchCalls.push(task);
      return {
        agentName,
        status: "success",
        findings: ["Sprint capacity analysis"],
        recommendations: ["Focus on core tasks first"],
      };
    },
  );

  const project = await storage.createIssue({
    type: "epic",
    title: "Kafka Service",
    labels: ["project", "kafka"],
    priority: 1,
  });

  const result = await orchestrator.planSprint({
    projectId: project.id,
    sprintName: "Sprint 1",
    startDate: "2026-02-14",
    endDate: "2026-02-28",
    capacity: 40,
  });

  // Dispatcher should have been called for sprint analysis
  if (dispatchCalls.length === 0) {
    throw new Error("Dispatcher was not called during planSprint");
  }

  // Verify the sprint was created by searching for it in storage
  const sprintIssues = await storage.search("Sprint 1");
  const sprintIssue = sprintIssues.find((i) => i.title === "Sprint 1");
  if (!sprintIssue) throw new Error("Sprint issue not found in storage");
  if (!sprintIssue.description?.includes("Agent Analysis")) {
    throw new Error("Sprint description should contain agent analysis");
  }
});

test("executeSprint delegates to work executor when delegate is set", async () => {
  const { storage, orchestrator } = createOrchestrator();

  const project = await storage.createIssue({
    type: "epic",
    title: "Test Project",
    labels: ["project"],
    priority: 1,
  });

  // Create ready tasks
  const task1 = await storage.createIssue({
    type: "task",
    title: "Task 1",
    parent: project.id,
    priority: 1,
  });
  await storage.updateIssue(task1.id, { status: "todo" });

  const executedIds: string[] = [];
  const mockDelegate: WorkExecutorDelegate = {
    async executeWork(input) {
      executedIds.push(...input.issueIds);
      return {
        results: input.issueIds.map((id) => ({
          issueId: id,
          status: "completed",
        })),
      };
    },
  };

  orchestrator.setWorkExecutorDelegate(mockDelegate);

  const result = await orchestrator.executeSprint({ projectId: project.id });

  if (result.executedCount === 0) {
    throw new Error("Should have executed at least one task");
  }
  if (executedIds.length === 0) {
    throw new Error("Delegate should have been called with task IDs");
  }
});

test("executeSprint returns empty when no delegate is set", async () => {
  const { storage, orchestrator } = createOrchestrator();

  const project = await storage.createIssue({
    type: "epic",
    title: "Test Project",
    labels: ["project"],
    priority: 1,
  });

  const result = await orchestrator.executeSprint({ projectId: project.id });

  if (result.executedCount !== 0) {
    throw new Error("Should return 0 executed when no delegate");
  }
});

test("planProject works without dispatcher (default behavior)", async () => {
  const { storage, orchestrator } = createOrchestrator();

  const project = await storage.createIssue({
    type: "epic",
    title: "Simple Project",
    labels: ["project"],
    priority: 1,
  });

  const result = await orchestrator.planProject({ projectId: project.id });

  // Should still create backlog items
  if (result.createdItems.length !== 4) {
    throw new Error(`Expected 4 backlog items, got ${result.createdItems.length}`);
  }
});
