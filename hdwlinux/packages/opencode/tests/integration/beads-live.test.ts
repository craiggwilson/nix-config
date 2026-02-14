/**
 * Live integration test for BeadsIssueStorageBackend with real `bd` CLI.
 *
 * These tests actually run `bd` commands against the local beads database.
 * They create, query, update, and clean up real issues.
 *
 * Requires: `bd` on PATH and an initialized beads database.
 * Skip with: BD_SKIP_LIVE=1 bun test
 */

import { describe, test, expect, beforeAll, afterAll } from "bun:test";
import { createBeadsCliBackend } from "../../core/src/backends/beads-backend.js";
import type { ShellExecutor } from "../../core/src/backends/beads-backend.js";
import { IssueStorage } from "../../core/src/beads.js";

// Skip if BD_SKIP_LIVE=1 or if bd is not available / no database
let SKIP = process.env.BD_SKIP_LIVE === "1";
if (!SKIP) {
  try {
    const proc = Bun.spawn(["bd", "info", "--json"], {
      stdout: "pipe",
      stderr: "pipe",
    });
    const exitCode = await proc.exited;
    if (exitCode !== 0) SKIP = true;
  } catch {
    SKIP = true;
  }
}

// Real shell executor using Bun's $ API
const realExecutor: ShellExecutor = async (command: string): Promise<string> => {
  const proc = Bun.spawn(["sh", "-c", command], {
    stdout: "pipe",
    stderr: "pipe",
  });
  const stdout = await new Response(proc.stdout).text();
  const exitCode = await proc.exited;
  if (exitCode !== 0) {
    const stderr = await new Response(proc.stderr).text();
    throw new Error(`Command failed (exit ${exitCode}): ${command}\n${stderr}`);
  }
  return stdout;
};

// Track created issue IDs for cleanup
const createdIds: string[] = [];

async function cleanup() {
  for (const id of createdIds) {
    try {
      await realExecutor(`bd close '${id}' --reason 'test cleanup' 2>/dev/null || true`);
    } catch {
      // ignore cleanup errors
    }
  }
  createdIds.length = 0;
}

describe.skipIf(SKIP)("BeadsIssueStorageBackend (live bd CLI)", () => {
  const backend = createBeadsCliBackend(realExecutor);

  afterAll(async () => {
    await cleanup();
  });

  test("createIssue creates a real beads issue", async () => {
    const result = await backend.createIssue({
      type: "task",
      title: "Live test: create",
      description: "Created by integration test",
      priority: 2,
      labels: ["test", "integration"],
    });

    expect(result.id).toBeTruthy();
    expect(typeof result.id).toBe("string");
    createdIds.push(result.id);
  });

  test("getIssue retrieves the created issue", async () => {
    const { id } = await backend.createIssue({
      type: "bug",
      title: "Live test: get",
      priority: 1,
    });
    createdIds.push(id);

    const issue = await backend.getIssue(id);

    expect(issue).toBeTruthy();
    expect(issue!.id).toBe(id);
    expect(issue!.title).toBe("Live test: get");
    expect(issue!.type).toBe("bug");
    expect(issue!.status).toBe("todo"); // open → todo
    expect(issue!.priority).toBe(1);
  });

  test("query returns issues matching filters", async () => {
    const { id } = await backend.createIssue({
      type: "task",
      title: "Live test: query",
      labels: ["live-query-test"],
      priority: 3,
    });
    createdIds.push(id);

    const results = await backend.query({ labels: ["live-query-test"] });

    expect(results.length).toBeGreaterThanOrEqual(1);
    expect(results.some((r) => r.id === id)).toBe(true);
  });

  test("updateIssue changes status", async () => {
    const { id } = await backend.createIssue({
      type: "task",
      title: "Live test: update status",
      priority: 2,
    });
    createdIds.push(id);

    await backend.updateIssue(id, { status: "in_progress" });

    const updated = await backend.getIssue(id);
    expect(updated!.status).toBe("in_progress");
  });

  test("createDependency links two issues", async () => {
    const { id: parentId } = await backend.createIssue({
      type: "epic",
      title: "Live test: dep parent",
      priority: 1,
    });
    createdIds.push(parentId);

    const { id: childId } = await backend.createIssue({
      type: "task",
      title: "Live test: dep child",
      priority: 2,
    });
    createdIds.push(childId);

    // Should not throw
    await backend.createDependency(childId, parentId, "blocks");
  });

  test("IssueStorage works with live backend", async () => {
    const storage = new IssueStorage(backend);

    const { id } = await storage.createIssue({
      type: "task",
      title: "Live test: IssueStorage",
      labels: ["live-storage-test"],
      priority: 2,
    });
    createdIds.push(id);

    const issue = await storage.getIssue(id);
    expect(issue).toBeTruthy();
    expect(issue!.title).toBe("Live test: IssueStorage");

    const results = await storage.query({ labels: ["live-storage-test"] });
    expect(results.length).toBeGreaterThanOrEqual(1);
  });

  test("createIssue with parent creates child issue", async () => {
    const { id: parentId } = await backend.createIssue({
      type: "epic",
      title: "Live test: parent",
      priority: 1,
    });
    createdIds.push(parentId);

    const { id: childId } = await backend.createIssue({
      type: "task",
      title: "Live test: child",
      priority: 2,
      parent: parentId,
    });
    createdIds.push(childId);

    const children = await backend.query({ parent: parentId });
    expect(children.some((c) => c.id === childId)).toBe(true);
  });
});
