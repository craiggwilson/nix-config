/**
 * Tests for ProjectPlannerOrchestrator getProjectFocus
 */

import { test } from "bun:test";
import { ProjectPlannerOrchestrator } from "../src/orchestrator.js";
import { ConfigManager, IssueStorage } from "../../core/src/index.ts";

function createOrchestrator() {
  const storage = new IssueStorage();
  const configManager = new ConfigManager("/tmp/opencode-test-config");
  return { storage, orchestrator: new ProjectPlannerOrchestrator(storage, configManager) };
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
