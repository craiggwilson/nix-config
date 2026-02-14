/**
 * Tests for BeadsHelper
 */

import { test } from "bun:test";
import { BeadsHelper } from "../src/beads.js";

// Mock BeadsClient for testing
class MockBeadsClient {
  async show(id: string, options?: any) {
    return {
      id,
      title: `Issue ${id}`,
      type: "task",
      status: "todo",
      priority: 1,
      labels: ["test"],
    };
  }

  async query(filters: any) {
    return [];
  }

  async create(input: any) {
    return {
      id: `ISSUE-${Date.now()}`,
      ...input,
    };
  }
}

test("BeadsHelper creates issues", async () => {
  const beads = new MockBeadsClient() as any;
  const helper = new BeadsHelper(beads);

  const result = await helper.createIssue({
    type: "task",
    title: "Test Task",
    priority: 1,
  });

  if (!result.id || !result.id.startsWith("ISSUE-")) {
    throw new Error("Issue creation failed");
  }
});

test("BeadsHelper updates issues", async () => {
  const beads = new MockBeadsClient() as any;
  const helper = new BeadsHelper(beads);

  // Create an issue first
  const created = await helper.createIssue({
    type: "task",
    title: "Test Task",
  });

  // Update it
  await helper.updateIssue(created.id, {
    title: "Updated Task",
    status: "in_progress",
  });

  const updated = await helper.getIssue(created.id);
  if (updated?.title !== "Updated Task") {
    throw new Error("Issue update failed");
  }
});

test("BeadsHelper creates dependencies", async () => {
  const beads = new MockBeadsClient() as any;
  const helper = new BeadsHelper(beads);

  const issue1 = await helper.createIssue({
    type: "task",
    title: "Task 1",
  });

  const issue2 = await helper.createIssue({
    type: "task",
    title: "Task 2",
  });

  await helper.createDependency(issue1.id, issue2.id, "needs");

  const deps = await helper.getDependencies(issue1.id);
  if (!deps.includes(issue2.id)) {
    throw new Error("Dependency creation failed");
  }
});

test("BeadsHelper searches issues", async () => {
  const beads = new MockBeadsClient() as any;
  const helper = new BeadsHelper(beads);

  // Create some issues
  await helper.createIssue({
    type: "task",
    title: "Search Test Task",
    description: "This is a test",
  });

  const results = await helper.search("Search Test");
  if (results.length === 0) {
    throw new Error("Search failed");
  }
});
