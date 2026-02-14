/**
 * Tests for IssueStorage
 */

import { expect, test, describe } from "bun:test";
import { IssueStorage } from "../src/beads.js";
import type { IssueStorageBackend } from "../src/storage-backend.js";
import type { IssueQuery, IssueRecord } from "../src/beads.js";

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

// ---------------------------------------------------------------------------
// Backend delegation tests
// ---------------------------------------------------------------------------

/**
 * Minimal mock backend that stores issues in a plain Map.
 */
function createMockBackend(): IssueStorageBackend & {
  store: Map<string, IssueRecord>;
  calls: { method: string; args: unknown[] }[];
} {
  const store = new Map<string, IssueRecord>();
  const calls: { method: string; args: unknown[] }[] = [];
  let seq = 0;

  return {
    store,
    calls,

    async query(filters: IssueQuery): Promise<IssueRecord[]> {
      calls.push({ method: "query", args: [filters] });
      const results: IssueRecord[] = [];
      for (const issue of store.values()) {
        if (filters.type && filters.type.length > 0) {
          if (!filters.type.includes(issue.type)) continue;
        }
        if (filters.status && filters.status.length > 0) {
          const status = issue.status || "todo";
          if (!filters.status.includes(status)) continue;
        }
        if (filters.parent && issue.parent !== filters.parent) continue;
        results.push(issue);
      }
      return results;
    },

    async getIssue(issueId: string): Promise<IssueRecord | null> {
      calls.push({ method: "getIssue", args: [issueId] });
      return store.get(issueId) ?? null;
    },

    async createIssue(input: {
      type: string;
      title: string;
      description?: string;
      labels?: string[];
      priority?: number;
      parent?: string;
      assignee?: string;
    }): Promise<{ id: string }> {
      calls.push({ method: "createIssue", args: [input] });
      const id = `BACKEND-${++seq}`;
      store.set(id, {
        id,
        type: input.type,
        title: input.title,
        description: input.description,
        labels: input.labels,
        priority: input.priority,
        parent: input.parent,
        assignee: input.assignee,
      });
      return { id };
    },

    async updateIssue(
      issueId: string,
      updates: {
        title?: string;
        description?: string;
        status?: string;
        priority?: number;
        assignee?: string;
        labels?: string[];
      }
    ): Promise<void> {
      calls.push({ method: "updateIssue", args: [issueId, updates] });
      const issue = store.get(issueId);
      if (issue) {
        if (updates.title) issue.title = updates.title;
        if (updates.description) issue.description = updates.description;
        if (updates.status) issue.status = updates.status;
        if (updates.priority !== undefined) issue.priority = updates.priority;
        if (updates.assignee) issue.assignee = updates.assignee;
        if (updates.labels) issue.labels = updates.labels;
      }
    },

    async createDependency(
      inwardId: string,
      outwardId: string,
      reason?: string
    ): Promise<void> {
      calls.push({ method: "createDependency", args: [inwardId, outwardId, reason] });
      const issue = store.get(inwardId);
      if (issue) {
        if (!issue.dependencies) issue.dependencies = [];
        if (!issue.dependencies.includes(outwardId)) {
          issue.dependencies.push(outwardId);
        }
      }
    },
  };
}

describe("IssueStorage without backend (backward compat)", () => {
  test("works exactly as before", async () => {
    const storage = new IssueStorage();

    const created = await storage.createIssue({
      type: "task",
      title: "No Backend Task",
      priority: 2,
    });

    expect(created.id).toStartWith("ISSUE-");

    const fetched = await storage.getIssue(created.id);
    expect(fetched).not.toBeNull();
    expect(fetched!.title).toBe("No Backend Task");

    await storage.updateIssue(created.id, { status: "done" });
    const updated = await storage.getIssue(created.id);
    expect(updated!.status).toBe("done");
  });

  test("getIssue returns null for unknown id without backend", async () => {
    const storage = new IssueStorage();
    const result = await storage.getIssue("nonexistent");
    expect(result).toBeNull();
  });
});

describe("IssueStorage with backend delegation", () => {
  test("createIssue delegates to backend and uses backend ID", async () => {
    const backend = createMockBackend();
    const storage = new IssueStorage(backend);

    const result = await storage.createIssue({
      type: "task",
      title: "Backend Task",
    });

    expect(result.id).toBe("BACKEND-1");
    expect(backend.calls.some((c) => c.method === "createIssue")).toBe(true);

    // Also in local cache
    const cached = await storage.getIssue("BACKEND-1");
    expect(cached).not.toBeNull();
    expect(cached!.title).toBe("Backend Task");
  });

  test("getIssue fetches from backend on cache miss", async () => {
    const backend = createMockBackend();
    // Pre-populate backend store directly (simulating data that exists remotely)
    backend.store.set("REMOTE-1", {
      id: "REMOTE-1",
      type: "bug",
      title: "Remote Bug",
    });

    const storage = new IssueStorage(backend);

    const issue = await storage.getIssue("REMOTE-1");
    expect(issue).not.toBeNull();
    expect(issue!.title).toBe("Remote Bug");
    expect(backend.calls.some((c) => c.method === "getIssue")).toBe(true);

    // Second call should hit cache, not backend again
    backend.calls.length = 0;
    const cached = await storage.getIssue("REMOTE-1");
    expect(cached!.title).toBe("Remote Bug");
    expect(backend.calls.length).toBe(0);
  });

  test("getIssue returns null when backend also has no match", async () => {
    const backend = createMockBackend();
    const storage = new IssueStorage(backend);

    const result = await storage.getIssue("NOPE");
    expect(result).toBeNull();
    expect(backend.calls.some((c) => c.method === "getIssue")).toBe(true);
  });

  test("query delegates to backend and populates cache", async () => {
    const backend = createMockBackend();
    backend.store.set("R-1", { id: "R-1", type: "task", title: "Task A" });
    backend.store.set("R-2", { id: "R-2", type: "task", title: "Task B" });
    backend.store.set("R-3", { id: "R-3", type: "bug", title: "Bug C" });

    const storage = new IssueStorage(backend);

    const tasks = await storage.query({ type: ["task"] });
    expect(tasks.length).toBe(2);
    expect(backend.calls.some((c) => c.method === "query")).toBe(true);

    // Cache should now contain the results
    const fromCache = await storage.search("Task A");
    expect(fromCache.length).toBe(1);
    expect(fromCache[0].id).toBe("R-1");
  });

  test("updateIssue delegates to backend then updates cache", async () => {
    const backend = createMockBackend();
    const storage = new IssueStorage(backend);

    // Create via backend
    const created = await storage.createIssue({
      type: "task",
      title: "Original",
    });

    await storage.updateIssue(created.id, { title: "Updated", status: "in_progress" });

    expect(backend.calls.filter((c) => c.method === "updateIssue").length).toBe(1);

    // Cache reflects the update
    const issue = await storage.getIssue(created.id);
    expect(issue!.title).toBe("Updated");
    expect(issue!.status).toBe("in_progress");
  });

  test("createDependency delegates to backend then updates cache", async () => {
    const backend = createMockBackend();
    const storage = new IssueStorage(backend);

    const a = await storage.createIssue({ type: "task", title: "A" });
    const b = await storage.createIssue({ type: "task", title: "B" });

    await storage.createDependency(a.id, b.id, "blocks");

    expect(backend.calls.filter((c) => c.method === "createDependency").length).toBe(1);

    const deps = await storage.getDependencies(a.id);
    expect(deps).toContain(b.id);
  });

  test("search uses cache populated by prior backend calls", async () => {
    const backend = createMockBackend();
    backend.store.set("S-1", { id: "S-1", type: "task", title: "Searchable Item" });

    const storage = new IssueStorage(backend);

    // Cache is empty, search finds nothing
    const before = await storage.search("Searchable");
    expect(before.length).toBe(0);

    // Populate cache via query
    await storage.query({});
    const after = await storage.search("Searchable");
    expect(after.length).toBe(1);
    expect(after[0].id).toBe("S-1");
  });

  test("findReady works with backend-populated cache", async () => {
    const backend = createMockBackend();
    const storage = new IssueStorage(backend);

    // Create two tasks, one depends on the other
    const t1 = await storage.createIssue({ type: "task", title: "First", priority: 1 });
    const t2 = await storage.createIssue({ type: "task", title: "Second", priority: 2 });

    // t2 depends on t1
    await storage.createDependency(t2.id, t1.id);

    // Both are "todo" by default (no status set).
    // t1 has no deps so it's ready; t2 depends on t1 which isn't done, so blocked.
    const ready = await storage.findReady();
    expect(ready.length).toBe(1);
    expect(ready[0].id).toBe(t1.id);

    // Mark t1 done — now t2 should become ready
    await storage.updateIssue(t1.id, { status: "done" });
    const readyAfter = await storage.findReady();
    expect(readyAfter.length).toBe(1);
    expect(readyAfter[0].id).toBe(t2.id);
  });

  test("clearCache works with backend", async () => {
    const backend = createMockBackend();
    const storage = new IssueStorage(backend);

    await storage.createIssue({ type: "task", title: "Temp" });
    storage.clearCache();

    // Cache is empty, but backend still has the issue
    const fromSearch = await storage.search("Temp");
    expect(fromSearch.length).toBe(0);
  });
});
