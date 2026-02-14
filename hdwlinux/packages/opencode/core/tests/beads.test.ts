/**
 * Tests for IssueStorage
 */

import { test } from "bun:test";
import { IssueStorage } from "../src/beads.js";

test("IssueStorage creates issues", async () => {
  const storage = new IssueStorage();

  const result = await storage.createIssue({
    type: "task",
    title: "Test Task",
    priority: 1,
  });

  if (!result.id || !result.id.startsWith("ISSUE-")) {
    throw new Error("Issue creation failed");
  }
});

test("IssueStorage updates issues", async () => {
  const storage = new IssueStorage();

  // Create an issue first
  const created = await storage.createIssue({
    type: "task",
    title: "Test Task",
  });

  // Update it
  await storage.updateIssue(created.id, {
    title: "Updated Task",
    status: "in_progress",
  });

  const updated = await storage.getIssue(created.id);
  if (updated?.title !== "Updated Task") {
    throw new Error("Issue update failed");
  }
});

test("IssueStorage creates dependencies", async () => {
  const storage = new IssueStorage();

  const issue1 = await storage.createIssue({
    type: "task",
    title: "Task 1",
  });

  const issue2 = await storage.createIssue({
    type: "task",
    title: "Task 2",
  });

  await storage.createDependency(issue1.id, issue2.id, "needs");

  const deps = await storage.getDependencies(issue1.id);
  if (!deps.includes(issue2.id)) {
    throw new Error("Dependency creation failed");
  }
});

test("IssueStorage searches issues", async () => {
  const storage = new IssueStorage();

  // Create some issues
  await storage.createIssue({
    type: "task",
    title: "Search Test Task",
    description: "This is a test",
  });

  const results = await storage.search("Search Test");
  if (results.length === 0) {
    throw new Error("Search failed");
  }
});
