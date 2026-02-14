/**
 * Tests for BeadsIssueStorageBackend
 *
 * These tests verify that the backend correctly implements the
 * IssueStorageBackend interface, both in mock mode and CLI-backed mode.
 */

import { test, expect, describe, beforeEach } from "bun:test";
import {
  createBeadsBackend,
  createBeadsCliBackend,
  BeadsIssueStorageBackend,
  toInternalStatus,
  toBeadsStatus,
  toBeadsType,
  beadsJsonToIssueRecord,
  parseBeadsJson,
  shellEscape,
} from "../src/backends/beads-backend.js";
import type { ShellExecutor, BeadsIssueJson } from "../src/backends/beads-backend.js";
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

// ── Helper function tests ─────────────────────────────────────

describe("Status mapping", () => {
  test("toInternalStatus maps beads statuses correctly", () => {
    expect(toInternalStatus("open")).toBe("todo");
    expect(toInternalStatus("in_progress")).toBe("in_progress");
    expect(toInternalStatus("blocked")).toBe("blocked");
    expect(toInternalStatus("closed")).toBe("done");
    expect(toInternalStatus("deferred")).toBe("todo");
    expect(toInternalStatus("tombstone")).toBe("done");
    expect(toInternalStatus("pinned")).toBe("todo");
  });

  test("toInternalStatus passes through unknown statuses", () => {
    expect(toInternalStatus("custom_status")).toBe("custom_status");
  });

  test("toBeadsStatus maps internal statuses correctly", () => {
    expect(toBeadsStatus("todo")).toBe("open");
    expect(toBeadsStatus("in_progress")).toBe("in_progress");
    expect(toBeadsStatus("blocked")).toBe("blocked");
    expect(toBeadsStatus("done")).toBe("closed");
  });

  test("toBeadsStatus passes through unknown statuses", () => {
    expect(toBeadsStatus("custom")).toBe("custom");
  });
});

describe("Type mapping", () => {
  test("toBeadsType maps valid types", () => {
    expect(toBeadsType("bug")).toBe("bug");
    expect(toBeadsType("feature")).toBe("feature");
    expect(toBeadsType("task")).toBe("task");
    expect(toBeadsType("epic")).toBe("epic");
    expect(toBeadsType("chore")).toBe("chore");
  });

  test("toBeadsType defaults unknown types to task", () => {
    expect(toBeadsType("story")).toBe("task");
    expect(toBeadsType("spike")).toBe("task");
  });
});

describe("JSON parsing", () => {
  test("beadsJsonToIssueRecord converts correctly", () => {
    const raw: BeadsIssueJson = {
      id: "nix-config-abc",
      title: "Test Issue",
      description: "A description",
      status: "open",
      priority: 2,
      issue_type: "task",
      labels: ["frontend", "urgent"],
      assignee: "agent:executor",
      parent: "nix-config-parent",
      dependencies: ["nix-config-dep1"],
    };

    const record = beadsJsonToIssueRecord(raw);

    expect(record.id).toBe("nix-config-abc");
    expect(record.title).toBe("Test Issue");
    expect(record.status).toBe("todo"); // open → todo
    expect(record.priority).toBe(2);
    expect(record.type).toBe("task");
    expect(record.labels).toEqual(["frontend", "urgent"]);
    expect(record.parent).toBe("nix-config-parent");
    expect(record.dependencies).toEqual(["nix-config-dep1"]);
  });

  test("beadsJsonToIssueRecord handles missing optional fields", () => {
    const raw: BeadsIssueJson = {
      id: "nix-config-abc",
      title: "Minimal",
      status: "in_progress",
      priority: 1,
      issue_type: "bug",
    };

    const record = beadsJsonToIssueRecord(raw);

    expect(record.labels).toEqual([]);
    expect(record.dependencies).toEqual([]);
    expect(record.parent).toBeUndefined();
    expect(record.assignee).toBeUndefined();
  });

  test("parseBeadsJson parses clean JSON", () => {
    const result = parseBeadsJson<{ id: string }>('{"id": "test-123"}');
    expect(result.id).toBe("test-123");
  });

  test("parseBeadsJson strips leading non-JSON text", () => {
    const result = parseBeadsJson<{ id: string }>(
      'Created issue successfully\n{"id": "test-123"}'
    );
    expect(result.id).toBe("test-123");
  });

  test("parseBeadsJson parses arrays", () => {
    const result = parseBeadsJson<Array<{ id: string }>>(
      '[{"id": "a"}, {"id": "b"}]'
    );
    expect(result.length).toBe(2);
  });

  test("parseBeadsJson throws on non-JSON output", () => {
    expect(() => parseBeadsJson("no json here")).toThrow("No JSON found");
  });
});

describe("shellEscape", () => {
  test("escapes single quotes", () => {
    expect(shellEscape("it's a test")).toBe("it'\\''s a test");
  });

  test("passes through safe strings", () => {
    expect(shellEscape("hello world")).toBe("hello world");
  });
});

// ── CLI-backed backend tests (mock executor) ──────────────────

describe("BeadsIssueStorageBackend (CLI-backed)", () => {
  let commands: string[];
  let mockResponses: Map<string, string>;
  let cliBackend: BeadsIssueStorageBackend;

  function mockExecutor(command: string): Promise<string> {
    commands.push(command);
    // Find a matching response by checking if the command starts with a key
    for (const [pattern, response] of mockResponses) {
      if (command.includes(pattern)) {
        return Promise.resolve(response);
      }
    }
    return Promise.resolve("[]");
  }

  beforeEach(() => {
    commands = [];
    mockResponses = new Map();
    cliBackend = createBeadsCliBackend(mockExecutor);
  });

  test("isLive returns true for CLI-backed backend", () => {
    expect(cliBackend.isLive).toBe(true);
  });

  test("isLive returns false for mock backend", () => {
    const mock = createBeadsBackend();
    expect(mock.isLive).toBe(false);
  });

  test("query calls bd list --json", async () => {
    mockResponses.set("bd list", "[]");

    await cliBackend.query({});

    expect(commands.length).toBe(1);
    expect(commands[0]).toContain("bd list --json");
  });

  test("query passes status filter", async () => {
    mockResponses.set("bd list", "[]");

    await cliBackend.query({ status: ["todo"] });

    expect(commands[0]).toContain("--status open");
  });

  test("query passes type filter", async () => {
    mockResponses.set("bd list", "[]");

    await cliBackend.query({ type: ["bug"] });

    expect(commands[0]).toContain("--type bug");
  });

  test("query passes label filter", async () => {
    mockResponses.set("bd list", "[]");

    await cliBackend.query({ labels: ["frontend"] });

    expect(commands[0]).toContain("--label frontend");
  });

  test("query passes parent filter", async () => {
    mockResponses.set("bd list", "[]");

    await cliBackend.query({ parent: "epic-123" });

    expect(commands[0]).toContain("--parent epic-123");
  });

  test("query parses JSON response into IssueRecords", async () => {
    mockResponses.set("bd list", JSON.stringify([
      {
        id: "nix-config-abc",
        title: "Test Task",
        status: "open",
        priority: 2,
        issue_type: "task",
        labels: ["test"],
      },
    ]));

    const results = await cliBackend.query({});

    expect(results.length).toBe(1);
    expect(results[0].id).toBe("nix-config-abc");
    expect(results[0].status).toBe("todo");
  });

  test("getIssue calls bd show --json", async () => {
    mockResponses.set("bd show", JSON.stringify([{
      id: "nix-config-abc",
      title: "Test",
      status: "in_progress",
      priority: 1,
      issue_type: "task",
    }]));

    const issue = await cliBackend.getIssue("nix-config-abc");

    expect(commands[0]).toContain("bd show");
    expect(commands[0]).toContain("nix-config-abc");
    expect(issue?.status).toBe("in_progress");
  });

  test("getIssue returns null on error", async () => {
    // Override executor to throw for this test
    const failingBackend = createBeadsCliBackend(async () => {
      throw new Error("bd: issue not found");
    });
    const issue = await failingBackend.getIssue("nonexistent");
    expect(issue).toBeNull();
  });

  test("createIssue calls bd create --json", async () => {
    mockResponses.set("bd create", JSON.stringify({
      id: "nix-config-new",
      title: "New Task",
      status: "open",
      priority: 2,
      issue_type: "task",
    }));

    const result = await cliBackend.createIssue({
      type: "task",
      title: "New Task",
      priority: 2,
    });

    expect(result.id).toBe("nix-config-new");
    expect(commands[0]).toContain("bd create");
    expect(commands[0]).toContain("-t task");
    expect(commands[0]).toContain("-p 2");
  });

  test("createIssue passes labels", async () => {
    mockResponses.set("bd create", JSON.stringify({
      id: "nix-config-new",
      title: "Labeled",
      status: "open",
      priority: 1,
      issue_type: "task",
    }));

    await cliBackend.createIssue({
      type: "task",
      title: "Labeled",
      labels: ["frontend", "urgent"],
    });

    expect(commands[0]).toContain("-l 'frontend,urgent'");
  });

  test("createIssue passes parent", async () => {
    mockResponses.set("bd create", JSON.stringify({
      id: "nix-config-child",
      title: "Child",
      status: "open",
      priority: 1,
      issue_type: "task",
    }));

    await cliBackend.createIssue({
      type: "task",
      title: "Child",
      parent: "nix-config-parent",
    });

    expect(commands[0]).toContain("--parent nix-config-parent");
  });

  test("createIssue still validates type and title", async () => {
    await expect(
      cliBackend.createIssue({ type: "", title: "Test" })
    ).rejects.toThrow("type and title are required");
  });

  test("updateIssue calls bd update --json", async () => {
    mockResponses.set("bd update", JSON.stringify([{
      id: "nix-config-abc",
      title: "Updated",
      status: "in_progress",
      priority: 1,
      issue_type: "task",
    }]));

    await cliBackend.updateIssue("nix-config-abc", {
      status: "in_progress",
      priority: 1,
    });

    expect(commands[0]).toContain("bd update");
    expect(commands[0]).toContain("--status in_progress");
    expect(commands[0]).toContain("--priority 1");
  });

  test("updateIssue maps internal status to beads status", async () => {
    mockResponses.set("bd update", "{}");

    await cliBackend.updateIssue("nix-config-abc", { status: "done" });

    expect(commands[0]).toContain("--status closed");
  });

  test("createDependency calls bd dep add", async () => {
    mockResponses.set("bd dep add", "");

    await cliBackend.createDependency("issue-a", "issue-b", "blocks");

    expect(commands[0]).toContain("bd dep add");
    expect(commands[0]).toContain("issue-a");
    expect(commands[0]).toContain("issue-b");
    expect(commands[0]).toContain("--type 'blocks'");
  });

  test("createDependency defaults to blocks type", async () => {
    mockResponses.set("bd dep add", "");

    await cliBackend.createDependency("issue-a", "issue-b");

    expect(commands[0]).toContain("--type 'blocks'");
  });
});
