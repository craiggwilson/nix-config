/**
 * Tests for ProgramPlannerOrchestrator
 */

import { test } from "bun:test";
import { ProgramPlannerOrchestrator } from "../src/orchestrator.js";
import type { ProjectPlannerDelegate } from "../src/orchestrator.js";
import { ConfigManager, IssueStorage } from "../../core/src/index.ts";
import { SubagentDispatcher } from "../../core/src/orchestration/subagent-dispatcher.js";
import type { SubagentTask, SubagentResult } from "../../core/src/orchestration/subagent-dispatcher.js";

function createOrchestrator() {
  const storage = new IssueStorage();
  const configManager = new ConfigManager("/tmp/opencode-test-config");
  return { storage, orchestrator: new ProgramPlannerOrchestrator(storage, configManager) };
}

function createOrchestratorWithDispatcher(
  executionHandler: (agentName: string, task: SubagentTask) => Promise<SubagentResult>,
) {
  const storage = new IssueStorage();
  const configManager = new ConfigManager("/tmp/opencode-test-config");
  const dispatcher = new SubagentDispatcher({ executionHandler });
  return {
    storage,
    orchestrator: new ProgramPlannerOrchestrator(storage, configManager, { dispatcher }),
  };
}

test("planProgram creates project epics for repos and wires them as children", async () => {
  const { storage, orchestrator } = createOrchestrator();

  const program = await storage.createIssue({
    type: "epic",
    title: "Platform Modernization",
    labels: ["program", "program:platform-modernization"],
    priority: 1,
  });

  const repos = ["service-a", "service-b"];

  const result = await orchestrator.planProgram({
    programId: program.id,
    repos,
  });

  if (result.createdEpics.length !== repos.length) {
    throw new Error(`Expected ${repos.length} project epics, got ${result.createdEpics.length}`);
  }

  for (const epicId of result.createdEpics) {
    const epic = await storage.getIssue(epicId);
    if (!epic) {
      throw new Error(`Created epic not found: ${epicId}`);
    }
    if (epic.parent !== program.id) {
      throw new Error(`Epic ${epicId} is not a child of program ${program.id}`);
    }
    if (!epic.labels?.includes("project")) {
      throw new Error(`Epic ${epicId} missing project label`);
    }
  }
});

test("getProgramStatus aggregates child epic statuses", async () => {
  const { storage, orchestrator } = createOrchestrator();

  const program = await storage.createIssue({
    type: "epic",
    title: "Refactor Program",
    labels: ["program", "program:refactor"],
    priority: 1,
  });

  const doneEpic = await storage.createIssue({
    type: "epic",
    title: "Done epic",
    parent: program.id,
  });
  const inProgressEpic = await storage.createIssue({
    type: "epic",
    title: "In progress epic",
    parent: program.id,
  });

  await storage.updateIssue(doneEpic.id, { status: "done" });
  await storage.updateIssue(inProgressEpic.id, { status: "in_progress" });

  const status = await orchestrator.getProgramStatus(program.id);

  if (status.projectCount !== 2) {
    throw new Error(`Expected 2 child epics, got ${status.projectCount}`);
  }
  if (status.projectStatuses.done !== 1 || status.projectStatuses.inProgress !== 1) {
    throw new Error("Child epic status aggregation incorrect");
  }
  if (status.progressPercentage <= 0 || status.progressPercentage > 100) {
    throw new Error("Progress percentage should be between 0 and 100");
  }
});

test("createProgram uses dispatcher to enrich description with agent analysis", async () => {
  const calls: Array<{ agentName: string; task: SubagentTask }> = [];
  const { storage, orchestrator } = createOrchestratorWithDispatcher(
    async (agentName, task) => {
      calls.push({ agentName, task });
      return {
        agentName,
        status: "success",
        findings: ["Found existing patterns"],
        recommendations: ["Use modular approach"],
      };
    },
  );

  const result = await orchestrator.createProgram({
    name: "Kafka Migration",
    summary: "Migrate to Kafka",
    horizon: "Q1 2026",
    goals: ["Migrate all services to Kafka"],
    nonGoals: ["Rewrite services"],
    metrics: ["Latency < 100ms"],
    constraints: ["No downtime"],
    repos: ["service-a"],
  });

  const issue = await storage.getIssue(result.programId);
  if (!issue) throw new Error("Program issue not found");

  // Dispatcher should have been called (default agents selected for analysis)
  if (calls.length === 0) throw new Error("Dispatcher was not called");

  // Description should be enriched with agent analysis
  if (!issue.description?.includes("Agent Analysis")) {
    throw new Error("Description should contain agent analysis section");
  }
  if (!issue.description?.includes("Use modular approach")) {
    throw new Error("Description should contain agent recommendations");
  }
});

test("planProgram uses dispatcher and enriches epic descriptions", async () => {
  const dispatchCalls: SubagentTask[] = [];
  const { storage, orchestrator } = createOrchestratorWithDispatcher(
    async (agentName, task) => {
      dispatchCalls.push(task);
      return {
        agentName,
        status: "success",
        findings: ["Needs careful migration"],
        recommendations: ["Start with read path"],
      };
    },
  );

  const program = await storage.createIssue({
    type: "epic",
    title: "Kafka Migration",
    labels: ["program", "kafka"],
    priority: 1,
  });

  const result = await orchestrator.planProgram({
    programId: program.id,
    repos: ["service-a"],
  });

  if (result.createdEpics.length !== 1) {
    throw new Error("Expected 1 epic");
  }

  // Dispatcher should have been called for analysis
  if (dispatchCalls.length === 0) {
    throw new Error("Dispatcher was not called during planProgram");
  }

  // Epic description should be enriched
  const epic = await storage.getIssue(result.createdEpics[0]);
  if (!epic) throw new Error("Epic not found");
  if (!epic.description?.includes("Agent Recommendations")) {
    throw new Error("Epic description should contain agent recommendations");
  }
});

test("planProgram delegates to project planner when delegate is set", async () => {
  const { storage, orchestrator } = createOrchestrator();

  const delegateCalls: Array<{ projectId: string; programId?: string }> = [];
  const mockDelegate: ProjectPlannerDelegate = {
    async planProject(input) {
      delegateCalls.push(input);
      return {
        createdItems: [`item-for-${input.projectId}`],
        dependencies: [[input.projectId, `item-for-${input.projectId}`]],
      };
    },
  };

  orchestrator.setProjectPlannerDelegate(mockDelegate);

  const program = await storage.createIssue({
    type: "epic",
    title: "Cross-Plugin Test",
    labels: ["program"],
    priority: 1,
  });

  const result = await orchestrator.planProgram({
    programId: program.id,
    repos: ["repo-a", "repo-b"],
  });

  // Should have created 2 epics
  if (result.createdEpics.length !== 2) {
    throw new Error(`Expected 2 epics, got ${result.createdEpics.length}`);
  }

  // Delegate should have been called for each epic
  if (delegateCalls.length !== 2) {
    throw new Error(`Expected 2 delegate calls, got ${delegateCalls.length}`);
  }

  // Each delegate call should reference the program
  for (const call of delegateCalls) {
    if (call.programId !== program.id) {
      throw new Error("Delegate call should reference the program");
    }
  }

  // Dependencies should include both program→epic and downstream delegate dependencies
  // 2 program→epic deps + 2 delegate deps = 4 total
  if (result.dependencies.length < 4) {
    throw new Error(`Expected at least 4 dependencies (2 program→epic + 2 delegate), got ${result.dependencies.length}`);
  }
});

test("planProgram works without delegate (standalone mode)", async () => {
  const { storage, orchestrator } = createOrchestrator();

  const program = await storage.createIssue({
    type: "epic",
    title: "Standalone Test",
    labels: ["program"],
    priority: 1,
  });

  const result = await orchestrator.planProgram({
    programId: program.id,
    repos: ["repo-a"],
  });

  // Should work fine without delegate
  if (result.createdEpics.length !== 1) {
    throw new Error("Should create epics even without delegate");
  }
});

test("planProgram handles delegate errors gracefully", async () => {
  const { storage, orchestrator } = createOrchestrator();

  const failingDelegate: ProjectPlannerDelegate = {
    async planProject() {
      throw new Error("Delegate failed");
    },
  };

  orchestrator.setProjectPlannerDelegate(failingDelegate);

  const program = await storage.createIssue({
    type: "epic",
    title: "Error Handling Test",
    labels: ["program"],
    priority: 1,
  });

  // Should not throw even if delegate fails
  const result = await orchestrator.planProgram({
    programId: program.id,
    repos: ["repo-a"],
  });

  if (result.createdEpics.length !== 1) {
    throw new Error("Should still create epics even if delegate fails");
  }
});
