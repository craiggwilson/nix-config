/**
 * Beads-backed IssueStorageBackend
 *
 * When constructed with a ShellExecutor, delegates to the `bd` CLI
 * (the beads issue tracker). When constructed without one, falls back
 * to an in-memory mock for unit tests.
 */

import type { IssueStorageBackend } from "../storage-backend.js";
import type { IssueQuery, IssueRecord } from "../beads.js";

// ── Shell executor ──────────────────────────────────────────────

/**
 * Runs a shell command and returns stdout.
 * In production this wraps Bun's `$` API; in tests it can be mocked.
 */
export type ShellExecutor = (command: string) => Promise<string>;

// ── Status mapping ──────────────────────────────────────────────

/** beads status → our canonical status */
const BEADS_TO_INTERNAL_STATUS: Record<string, string> = {
  open: "todo",
  in_progress: "in_progress",
  blocked: "blocked",
  deferred: "todo",
  closed: "done",
  tombstone: "done",
  pinned: "todo",
};

/** our canonical status → beads status */
const INTERNAL_TO_BEADS_STATUS: Record<string, string> = {
  todo: "open",
  in_progress: "in_progress",
  blocked: "blocked",
  done: "closed",
};

function toInternalStatus(beadsStatus: string): string {
  return BEADS_TO_INTERNAL_STATUS[beadsStatus] ?? beadsStatus;
}

function toBeadsStatus(internalStatus: string): string {
  return INTERNAL_TO_BEADS_STATUS[internalStatus] ?? internalStatus;
}

// ── Type mapping ────────────────────────────────────────────────

const VALID_BEADS_TYPES = new Set([
  "bug",
  "feature",
  "task",
  "epic",
  "chore",
]);

function toBeadsType(type: string): string {
  if (VALID_BEADS_TYPES.has(type)) return type;
  return "task";
}

// ── JSON parsing helpers ────────────────────────────────────────

/** Shape of a beads issue as returned by `bd show --json` / `bd list --json` */
interface BeadsIssueJson {
  id: string;
  title: string;
  description?: string;
  status: string;
  priority: number;
  /** beads uses `issue_type` in JSON output */
  issue_type: string;
  labels?: string[];
  assignee?: string;
  parent?: string;
  dependencies?: string[];
  dependency_count?: number;
  dependent_count?: number;
  created_at?: string;
  created_by?: string;
  updated_at?: string;
  closed_at?: string;
  close_reason?: string;
}

function beadsJsonToIssueRecord(raw: BeadsIssueJson): IssueRecord {
  return {
    id: raw.id,
    type: raw.issue_type,
    title: raw.title,
    description: raw.description,
    status: toInternalStatus(raw.status),
    priority: raw.priority,
    labels: raw.labels ?? [],
    parent: raw.parent,
    assignee: raw.assignee,
    dependencies: raw.dependencies ?? [],
  };
}

/** Safely parse JSON from bd CLI output, stripping any leading non-JSON text */
function parseBeadsJson<T>(output: string): T {
  const trimmed = output.trim();
  const jsonStart = trimmed.search(/[\[{]/);
  if (jsonStart === -1) {
    throw new Error(`No JSON found in bd output: ${trimmed.slice(0, 200)}`);
  }
  return JSON.parse(trimmed.slice(jsonStart));
}

/** Escape a string for safe use in single-quoted shell arguments */
function shellEscape(s: string): string {
  return s.replace(/'/g, "'\\''");
}

// Exported for tests
export {
  toInternalStatus,
  toBeadsStatus,
  toBeadsType,
  beadsJsonToIssueRecord,
  parseBeadsJson,
  shellEscape,
};
export type { BeadsIssueJson };

// ── Backend implementation ──────────────────────────────────────

export class BeadsIssueStorageBackend implements IssueStorageBackend {
  private executor?: ShellExecutor;

  // In-memory fallback (used when no executor is provided)
  private mockStore: Map<string, IssueRecord> = new Map();
  private mockSeq = 0;

  constructor(options?: {
    executor?: ShellExecutor;
    initialIssues?: Partial<IssueRecord>[];
  }) {
    this.executor = options?.executor;

    if (options?.initialIssues) {
      for (const issue of options.initialIssues) {
        if (issue.id && issue.type && issue.title) {
          this.mockStore.set(issue.id, {
            id: issue.id,
            type: issue.type,
            title: issue.title,
            description: issue.description,
            status: issue.status ?? "todo",
            priority: issue.priority ?? 3,
            labels: issue.labels ?? [],
            parent: issue.parent,
            assignee: issue.assignee,
            dependencies: issue.dependencies ?? [],
          });
        }
      }
    }
  }

  /** Whether this backend is using the real bd CLI */
  get isLive(): boolean {
    return !!this.executor;
  }

  /** Number of issues in the mock store (for tests) */
  get size(): number {
    return this.mockStore.size;
  }

  /** Clear the mock store (for tests) */
  clearCache(): void {
    this.mockStore.clear();
    this.mockSeq = 0;
  }

  // ── query ───────────────────────────────────────────────────

  async query(filters: IssueQuery): Promise<IssueRecord[]> {
    if (this.executor) {
      return this.queryViaCli(filters);
    }
    return this.queryMock(filters);
  }

  private async queryViaCli(filters: IssueQuery): Promise<IssueRecord[]> {
    const args: string[] = ["bd", "list", "--json"];

    if (filters.status?.length) {
      for (const s of filters.status) {
        args.push("--status", toBeadsStatus(s));
      }
    }
    if (filters.type?.length) {
      for (const t of filters.type) {
        args.push("--type", toBeadsType(t));
      }
    }
    if (filters.labels?.length) {
      for (const l of filters.labels) {
        args.push("--label", l);
      }
    }
    if (filters.priority?.length) {
      for (const p of filters.priority) {
        args.push("--priority", String(p));
      }
    }
    if (filters.parent) {
      args.push("--parent", filters.parent);
    }
    if (filters.assignee) {
      args.push("--assignee", filters.assignee);
    }

    const output = await this.executor!(args.join(" "));
    const raw = parseBeadsJson<BeadsIssueJson[]>(output);
    return raw.map(beadsJsonToIssueRecord);
  }

  private queryMock(filters: IssueQuery): IssueRecord[] {
    let results = Array.from(this.mockStore.values());

    if (filters.labels?.length) {
      results = results.filter((r) =>
        filters.labels!.some((l) => r.labels?.includes(l))
      );
    }
    if (filters.status?.length) {
      results = results.filter((r) =>
        filters.status!.includes(r.status ?? "todo")
      );
    }
    if (filters.priority?.length) {
      results = results.filter((r) =>
        filters.priority!.includes(r.priority ?? 3)
      );
    }
    if (filters.parent) {
      results = results.filter((r) => r.parent === filters.parent);
    }
    if (filters.type?.length) {
      results = results.filter((r) => filters.type!.includes(r.type));
    }
    if (filters.assignee) {
      results = results.filter((r) => r.assignee === filters.assignee);
    }

    return results;
  }

  // ── getIssue ────────────────────────────────────────────────

  async getIssue(issueId: string): Promise<IssueRecord | null> {
    if (this.executor) {
      return this.getIssueViaCli(issueId);
    }
    return this.mockStore.get(issueId) ?? null;
  }

  private async getIssueViaCli(issueId: string): Promise<IssueRecord | null> {
    try {
      const output = await this.executor!(
        `bd show '${shellEscape(issueId)}' --json`
      );
      // bd show returns an array with one element
      const raw = parseBeadsJson<BeadsIssueJson | BeadsIssueJson[]>(output);
      const issue = Array.isArray(raw) ? raw[0] : raw;
      if (!issue) return null;
      return beadsJsonToIssueRecord(issue);
    } catch {
      return null;
    }
  }

  // ── createIssue ─────────────────────────────────────────────

  async createIssue(input: {
    type: string;
    title: string;
    description?: string;
    labels?: string[];
    priority?: number;
    parent?: string;
    assignee?: string;
  }): Promise<{ id: string }> {
    if (!input.type || !input.title) {
      throw new Error("type and title are required");
    }

    if (this.executor) {
      return this.createIssueViaCli(input);
    }
    return this.createIssueMock(input);
  }

  private async createIssueViaCli(input: {
    type: string;
    title: string;
    description?: string;
    labels?: string[];
    priority?: number;
    parent?: string;
    assignee?: string;
  }): Promise<{ id: string }> {
    const args: string[] = [
      "bd",
      "create",
      `'${shellEscape(input.title)}'`,
      "-t",
      toBeadsType(input.type),
    ];

    if (input.priority !== undefined) {
      args.push("-p", String(input.priority));
    }
    if (input.description) {
      args.push("-d", `'${shellEscape(input.description)}'`);
    }
    if (input.parent) {
      args.push("--parent", input.parent);
    }
    if (input.labels?.length) {
      args.push("-l", `'${input.labels.join(",")}'`);
    }
    args.push("--json");

    const output = await this.executor!(args.join(" "));
    const raw = parseBeadsJson<BeadsIssueJson | BeadsIssueJson[]>(output);
    const issue = Array.isArray(raw) ? raw[0] : raw;
    return { id: issue.id };
  }

  private createIssueMock(input: {
    type: string;
    title: string;
    description?: string;
    labels?: string[];
    priority?: number;
    parent?: string;
    assignee?: string;
  }): { id: string } {
    this.mockSeq++;
    const id = `BEADS-${Date.now()}-${this.mockSeq}`;
    const record: IssueRecord = {
      id,
      type: input.type,
      title: input.title,
      description: input.description,
      status: "todo",
      priority: input.priority ?? 3,
      labels: input.labels ?? [],
      parent: input.parent,
      assignee: input.assignee,
      dependencies: [],
    };
    this.mockStore.set(id, record);
    return { id };
  }

  // ── updateIssue ─────────────────────────────────────────────

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
    if (this.executor) {
      return this.updateIssueViaCli(issueId, updates);
    }
    return this.updateIssueMock(issueId, updates);
  }

  private async updateIssueViaCli(
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
    const args: string[] = ["bd", "update", `'${shellEscape(issueId)}'`];
    let hasUpdateArgs = false;

    if (updates.status) {
      args.push("--status", toBeadsStatus(updates.status));
      hasUpdateArgs = true;
    }
    if (updates.priority !== undefined) {
      args.push("--priority", String(updates.priority));
      hasUpdateArgs = true;
    }
    if (updates.title) {
      args.push("--title", `'${shellEscape(updates.title)}'`);
      hasUpdateArgs = true;
    }
    if (updates.description) {
      args.push("--description", `'${shellEscape(updates.description)}'`);
      hasUpdateArgs = true;
    }

    if (hasUpdateArgs) {
      args.push("--json");
      await this.executor!(args.join(" "));
    }

    // Labels are managed separately via bd label add/remove
    if (updates.labels) {
      const current = await this.getIssueViaCli(issueId);
      const currentLabels = new Set(current?.labels ?? []);
      const newLabels = new Set(updates.labels);

      for (const label of newLabels) {
        if (!currentLabels.has(label)) {
          await this.executor!(
            `bd label add '${shellEscape(issueId)}' '${shellEscape(label)}'`
          );
        }
      }

      for (const label of currentLabels) {
        if (!newLabels.has(label)) {
          await this.executor!(
            `bd label remove '${shellEscape(issueId)}' '${shellEscape(label)}'`
          );
        }
      }
    }
  }

  private updateIssueMock(
    issueId: string,
    updates: {
      title?: string;
      description?: string;
      status?: string;
      priority?: number;
      assignee?: string;
      labels?: string[];
    }
  ): void {
    const existing = this.mockStore.get(issueId);
    if (!existing) {
      throw new Error(`Issue not found: ${issueId}`);
    }

    if (updates.title !== undefined) existing.title = updates.title;
    if (updates.description !== undefined) existing.description = updates.description;
    if (updates.status !== undefined) existing.status = updates.status;
    if (updates.priority !== undefined) existing.priority = updates.priority;
    if (updates.assignee !== undefined) existing.assignee = updates.assignee;
    if (updates.labels !== undefined) existing.labels = updates.labels;
  }

  // ── createDependency ────────────────────────────────────────

  async createDependency(
    inwardId: string,
    outwardId: string,
    reason?: string
  ): Promise<void> {
    if (this.executor) {
      return this.createDependencyViaCli(inwardId, outwardId, reason);
    }
    return this.createDependencyMock(inwardId, outwardId);
  }

  private async createDependencyViaCli(
    inwardId: string,
    outwardId: string,
    reason?: string
  ): Promise<void> {
    const depType = reason ?? "blocks";
    await this.executor!(
      `bd dep add '${shellEscape(inwardId)}' '${shellEscape(outwardId)}' --type '${shellEscape(depType)}'`
    );
  }

  private createDependencyMock(inwardId: string, outwardId: string): void {
    const inward = this.mockStore.get(inwardId);
    if (!inward) {
      throw new Error(`Issue not found: ${inwardId}`);
    }

    if (!inward.dependencies) {
      inward.dependencies = [];
    }

    if (!inward.dependencies.includes(outwardId)) {
      inward.dependencies.push(outwardId);
    }
  }
}

// ── Factory functions ─────────────────────────────────────────

/**
 * Create a mock (in-memory) beads backend for tests.
 */
export function createBeadsBackend(options?: {
  initialIssues?: Partial<IssueRecord>[];
}): BeadsIssueStorageBackend {
  return new BeadsIssueStorageBackend(options);
}

/**
 * Create a real beads backend that delegates to the `bd` CLI.
 */
export function createBeadsCliBackend(
  executor: ShellExecutor
): BeadsIssueStorageBackend {
  return new BeadsIssueStorageBackend({ executor });
}
