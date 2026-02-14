/**
 * Tests for BeadsIssueStorageBackend
 *
 * These tests verify that the backend correctly implements the
 * IssueStorageBackend interface.
 */

import { test, expect, describe, beforeEach } from "bun:test";
import { createBeadsBackend, BeadsIssueStorageBackend } from "../src/backends/beads-backend.js";
import type { IssueStorageBackend } from "../src/storage-backend.js";

describe("BeadsIssueStorageBackend", () => {
  let backend: BeadsIssueStorageBackend;

  beforeEach(() => {
    backend = createBeadsBackend();
  });

  test("implements IssueStorageBackend interface", () => {
    const storageBackend: IssueStorageBackend = backend;

    expect(typeof storageBackend.query).toBe("function");
    expect(typeof storageBackend.getIssue).toBe("function");
    expect(typeof storageBackend.createIssue).toBe("function");
    expect(typeof storageBackend.updateIssue).toBe("function");
    expect(typeof storageBackend.createDependency).toBe("function");
  });

  test("createBeadsBackend factory returns a backend instance", () => {
    const instance = createBeadsBackend();
    expect(instance).toBeInstanceOf(BeadsIssueStorageBackend);
  });

  test("createIssue creates an issue with BEADS- prefix", async () => {
    const result = await backend.createIssue({
      type: "task",
      title: "Test Task",
      priority: 1,
    });

    expect(result.id).toBeDefined();
    expect(result.id.startsWith("BEADS-")).toBe(true);
  });

  test("createIssue throws when type is missing", async () => {
    await expect(
      backend.createIssue({
        type: "",
        title: "Test Task",
      })
    ).rejects.toThrow("type and title are required");
  });

  test("createIssue throws when title is missing", async () => {
    await expect(
      backend.createIssue({
        type: "task",
        title: "",
      })
    ).rejects.toThrow("type and title are required");
  });

  test("getIssue returns created issue", async () => {
    const created = await backend.createIssue({
      type: "task",
      title: "Test Task",
      description: "A test description",
      priority: 2,
      labels: ["test", "backend"],
    });

    const issue = await backend.getIssue(created.id);

    expect(issue).not.toBeNull();
    expect(issue?.id).toBe(created.id);
    expect(issue?.type).toBe("task");
    expect(issue?.title).toBe("Test Task");
    expect(issue?.description).toBe("A test description");
    expect(issue?.priority).toBe(2);
    expect(issue?.labels).toEqual(["test", "backend"]);
    expect(issue?.status).toBe("todo");
  });

  test("getIssue returns null for non-existent issue", async () => {
    const issue = await backend.getIssue("non-existent-id");
    expect(issue).toBeNull();
  });

  test("updateIssue updates issue fields", async () => {
    const created = await backend.createIssue({
      type: "task",
      title: "Original Title",
    });

    await backend.updateIssue(created.id, {
      title: "Updated Title",
      status: "in_progress",
      priority: 1,
      assignee: "agent:test",
      labels: ["updated"],
    });

    const updated = await backend.getIssue(created.id);

    expect(updated?.title).toBe("Updated Title");
    expect(updated?.status).toBe("in_progress");
    expect(updated?.priority).toBe(1);
    expect(updated?.assignee).toBe("agent:test");
    expect(updated?.labels).toEqual(["updated"]);
  });

  test("updateIssue throws for non-existent issue", async () => {
    await expect(
      backend.updateIssue("non-existent-id", { title: "New Title" })
    ).rejects.toThrow("Issue not found: non-existent-id");
  });

  test("createDependency adds dependency to issue", async () => {
    const issue1 = await backend.createIssue({
      type: "task",
      title: "Task 1",
    });

    const issue2 = await backend.createIssue({
      type: "task",
      title: "Task 2",
    });

    await backend.createDependency(issue1.id, issue2.id, "blocks");

    const updated = await backend.getIssue(issue1.id);
    expect(updated?.dependencies).toContain(issue2.id);
  });

  test("createDependency does not duplicate dependencies", async () => {
    const issue1 = await backend.createIssue({
      type: "task",
      title: "Task 1",
    });

    const issue2 = await backend.createIssue({
      type: "task",
      title: "Task 2",
    });

    await backend.createDependency(issue1.id, issue2.id);
    await backend.createDependency(issue1.id, issue2.id);

    const updated = await backend.getIssue(issue1.id);
    expect(updated?.dependencies?.filter((d) => d === issue2.id).length).toBe(1);
  });

  test("createDependency throws for non-existent inward issue", async () => {
    const issue2 = await backend.createIssue({
      type: "task",
      title: "Task 2",
    });

    await expect(
      backend.createDependency("non-existent-id", issue2.id)
    ).rejects.toThrow("Issue not found: non-existent-id");
  });

  test("query returns all issues when no filters", async () => {
    await backend.createIssue({ type: "task", title: "Task 1" });
    await backend.createIssue({ type: "bug", title: "Bug 1" });
    await backend.createIssue({ type: "epic", title: "Epic 1" });

    const results = await backend.query({});
    expect(results.length).toBe(3);
  });

  test("query filters by type", async () => {
    await backend.createIssue({ type: "task", title: "Task 1" });
    await backend.createIssue({ type: "bug", title: "Bug 1" });
    await backend.createIssue({ type: "task", title: "Task 2" });

    const results = await backend.query({ type: ["task"] });
    expect(results.length).toBe(2);
    expect(results.every((r) => r.type === "task")).toBe(true);
  });

  test("query filters by labels", async () => {
    await backend.createIssue({
      type: "task",
      title: "Task 1",
      labels: ["frontend", "urgent"],
    });
    await backend.createIssue({
      type: "task",
      title: "Task 2",
      labels: ["backend"],
    });
    await backend.createIssue({
      type: "task",
      title: "Task 3",
      labels: ["frontend"],
    });

    const results = await backend.query({ labels: ["frontend"] });
    expect(results.length).toBe(2);
  });

  test("query filters by status", async () => {
    const issue1 = await backend.createIssue({ type: "task", title: "Task 1" });
    await backend.createIssue({ type: "task", title: "Task 2" });

    await backend.updateIssue(issue1.id, { status: "done" });

    const todoResults = await backend.query({ status: ["todo"] });
    expect(todoResults.length).toBe(1);

    const doneResults = await backend.query({ status: ["done"] });
    expect(doneResults.length).toBe(1);
  });

  test("query filters by priority", async () => {
    await backend.createIssue({ type: "task", title: "Task 1", priority: 1 });
    await backend.createIssue({ type: "task", title: "Task 2", priority: 2 });
    await backend.createIssue({ type: "task", title: "Task 3", priority: 1 });

    const results = await backend.query({ priority: [1] });
    expect(results.length).toBe(2);
  });

  test("query filters by parent", async () => {
    const parent = await backend.createIssue({ type: "epic", title: "Epic 1" });
    await backend.createIssue({
      type: "task",
      title: "Task 1",
      parent: parent.id,
    });
    await backend.createIssue({
      type: "task",
      title: "Task 2",
      parent: parent.id,
    });
    await backend.createIssue({ type: "task", title: "Task 3" });

    const results = await backend.query({ parent: parent.id });
    expect(results.length).toBe(2);
  });

  test("query filters by assignee", async () => {
    await backend.createIssue({
      type: "task",
      title: "Task 1",
      assignee: "agent:executor",
    });
    await backend.createIssue({
      type: "task",
      title: "Task 2",
      assignee: "agent:planner",
    });

    const results = await backend.query({ assignee: "agent:executor" });
    expect(results.length).toBe(1);
    expect(results[0].assignee).toBe("agent:executor");
  });

  test("query combines multiple filters", async () => {
    await backend.createIssue({
      type: "task",
      title: "Task 1",
      priority: 1,
      labels: ["urgent"],
    });
    await backend.createIssue({
      type: "task",
      title: "Task 2",
      priority: 2,
      labels: ["urgent"],
    });
    await backend.createIssue({
      type: "bug",
      title: "Bug 1",
      priority: 1,
      labels: ["urgent"],
    });

    const results = await backend.query({
      type: ["task"],
      priority: [1],
      labels: ["urgent"],
    });
    expect(results.length).toBe(1);
    expect(results[0].title).toBe("Task 1");
  });

  test("can be initialized with initial issues", () => {
    const initialIssues = [
      { id: "INIT-1", type: "task", title: "Initial Task 1" },
      { id: "INIT-2", type: "bug", title: "Initial Bug 1" },
    ];

    const backendWithInitial = createBeadsBackend({ initialIssues });
    expect(backendWithInitial.size).toBe(2);
  });

  test("clearCache removes all issues", async () => {
    await backend.createIssue({ type: "task", title: "Task 1" });
    await backend.createIssue({ type: "task", title: "Task 2" });

    expect(backend.size).toBe(2);

    backend.clearCache();

    expect(backend.size).toBe(0);
    const results = await backend.query({});
    expect(results.length).toBe(0);
  });
});
