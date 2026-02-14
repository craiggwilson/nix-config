/**
 * Tests for ProgramPlannerOrchestrator
 */

import { test } from "bun:test";
import { ProgramPlannerOrchestrator } from "../src/orchestrator.js";
import { ConfigManager, IssueStorage } from "../../core/src/index.ts";

function createOrchestrator() {
  const storage = new IssueStorage();
  const configManager = new ConfigManager("/tmp/opencode-test-config");
  return { storage, orchestrator: new ProgramPlannerOrchestrator(storage, configManager) };
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
