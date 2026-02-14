/**
 * Issue query and manipulation helpers.
 *
 * This module defines a storage abstraction for planning issues.
 * The underlying implementation can be backed by beads (via tools
 * exposed by the opencode-beads plugin) or by another system.
 */

import type { IssueStorageBackend } from "./storage-backend.js";

export interface IssueQuery {
  labels?: string[];
  status?: string[];
  priority?: number[];
  parent?: string;
  type?: string[];
  assignee?: string;
}

export interface DependencyNode {
  id: string;
  title: string;
  status: string;
  priority: number;
  dependencies: string[];
}

export interface IssueRecord {
  id: string;
  type: string;
  title: string;
  description?: string;
  status?: string;
  priority?: number;
  labels?: string[];
  parent?: string;
  assignee?: string;
  dependencies?: string[];
}

/**
 * Issue storage with optional backend delegation.
 *
 * When constructed without a backend, all data lives in an in-memory
 * cache (original behavior). When a backend is provided, mutating
 * operations delegate to it first, then update the local cache so
 * that cache-only helpers (search, findReady, analyzeDependencies,
 * etc.) continue to work.
 */
export class IssueStorage {
  private cache: Map<string, IssueRecord> = new Map();
  private seq = 0;
  private backend?: IssueStorageBackend;

  constructor(backend?: IssueStorageBackend) {
    this.backend = backend;
  }

  /**
   * Query issues with filters.
   *
   * When a backend is present, delegates to it and populates the
   * cache with the results so that cache-only helpers work.
   */
  async query(filters: IssueQuery): Promise<IssueRecord[]> {
    if (this.backend) {
      const results = await this.backend.query(filters);
      for (const issue of results) {
        this.cache.set(issue.id, issue);
      }
      return results;
    }

    const results: IssueRecord[] = [];

    for (const issue of this.cache.values()) {
      if (filters.labels && filters.labels.length > 0) {
        const labels = issue.labels || [];
        if (!filters.labels.some((l) => labels.includes(l))) {
          continue;
        }
      }

      if (filters.status && filters.status.length > 0) {
        const status = issue.status || "todo";
        if (!filters.status.includes(status)) {
          continue;
        }
      }

      if (filters.priority && filters.priority.length > 0) {
        const priority = issue.priority;
        if (priority === undefined || !filters.priority.includes(priority)) {
          continue;
        }
      }

      if (filters.parent && issue.parent !== filters.parent) {
        continue;
      }

      if (filters.type && filters.type.length > 0) {
        if (!filters.type.includes(issue.type)) {
          continue;
        }
      }

      if (filters.assignee && issue.assignee !== filters.assignee) {
        continue;
      }

      results.push(issue);
    }

    return results;
  }

  /**
   * Find ready tasks (no blocking dependencies)
   */
  async findReady(projectId?: string): Promise<IssueRecord[]> {
    const filters: IssueQuery = {
      status: ["todo"],
    };

    if (projectId) {
      filters.parent = projectId;
    }

    const items = await this.query(filters);

    // Filter out items with blocking dependencies
    const ready: IssueRecord[] = [];
    for (const item of items) {
      const deps = await this.getDependencies(item.id);
      const hasBlockingDeps = deps.some((depId) => {
        const dep = this.cache.get(depId);
        return dep && dep.status !== "done";
      });

      if (!hasBlockingDeps) {
        ready.push(item);
      }
    }

    // Sort by ascending priority (1 = highest) and then by id for stability.
    return ready.sort((a, b) => {
      const pa = a.priority ?? Number.MAX_SAFE_INTEGER;
      const pb = b.priority ?? Number.MAX_SAFE_INTEGER;
      if (pa !== pb) return pa - pb;
      return a.id.localeCompare(b.id);
    });
  }

  /**
   * Analyze dependency graph
   */
  async analyzeDependencies(issueId: string): Promise<{
    cycles: string[][];
    criticalPath: string[];
    blockers: string[];
  }> {
    const visited = new Set<string>();
    const cycles: string[][] = [];
    const blockers: string[] = [];

    // Detect cycles using DFS
    const detectCycles = async (nodeId: string, path: string[]): Promise<void> => {
      if (path.includes(nodeId)) {
        const cycleStart = path.indexOf(nodeId);
        cycles.push(path.slice(cycleStart).concat(nodeId));
        return;
      }

      if (visited.has(nodeId)) {
        return;
      }

      visited.add(nodeId);
      const deps = await this.getDependencies(nodeId);

      for (const depId of deps) {
        await detectCycles(depId, [...path, nodeId]);
      }
    };

    await detectCycles(issueId, []);

    // Find blockers (dependencies not done)
    const allDeps = await this.getDependencies(issueId);
    for (const depId of allDeps) {
      const dep = this.cache.get(depId);
      if (dep && dep.status !== "done") {
        blockers.push(depId);
      }
    }

    // Calculate critical path (longest dependency chain)
    const criticalPath: string[] = [];
    const calculatePath = async (nodeId: string, path: string[]): Promise<string[]> => {
      const deps = await this.getDependencies(nodeId);
      if (deps.length === 0) {
        return path;
      }

      let longestPath = path;
      for (const depId of deps) {
        const newPath = await calculatePath(depId, [...path, depId]);
        if (newPath.length > longestPath.length) {
          longestPath = newPath;
        }
      }
      return longestPath;
    };

    const path = await calculatePath(issueId, [issueId]);
    criticalPath.push(...path);

    return {
      cycles,
      criticalPath,
      blockers,
    };
  }

  /**
   * Get all children of an issue.
   */
  async getChildren(parentId: string): Promise<IssueRecord[]> {
    return this.query({ parent: parentId });
  }

  /**
   * Get all dependencies of an issue.
   *
   * Uses getIssue (which can fetch from backend on cache miss).
   */
  async getDependencies(issueId: string): Promise<string[]> {
    const issue = await this.getIssue(issueId);
    if (issue && issue.dependencies) {
      return issue.dependencies;
    }

    return [];
  }

  /**
   * Create a new issue with proper structure.
   *
   * When a backend is present, delegates creation to it and uses the
   * returned ID. The issue is always stored in the local cache.
   */
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

    let id: string;

    if (this.backend) {
      const result = await this.backend.createIssue(input);
      id = result.id;
    } else {
      id = `ISSUE-${Date.now()}-${++this.seq}`;
    }

    const issue: IssueRecord = {
      id,
      type: input.type,
      title: input.title,
      description: input.description,
      labels: input.labels,
      priority: input.priority,
      parent: input.parent,
      assignee: input.assignee,
    };

    this.cache.set(id, issue);
    return { id };
  }

  /**
   * Update an issue.
   *
   * When a backend is present, delegates the update to it first,
   * then applies the same changes to the local cache.
   */
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
    if (this.backend) {
      await this.backend.updateIssue(issueId, updates);
    }

    const issue = this.cache.get(issueId);
    if (!issue) {
      throw new Error(`Issue not found: ${issueId}`);
    }

    if (updates.title) issue.title = updates.title;
    if (updates.description) issue.description = updates.description;
    if (updates.status) issue.status = updates.status;
    if (updates.priority !== undefined) issue.priority = updates.priority;
    if (updates.assignee) issue.assignee = updates.assignee;
    if (updates.labels) issue.labels = updates.labels;
  }

  /**
   * Create a dependency between two issues.
   *
   * When a backend is present, delegates to it first, then updates
   * the local cache.
   */
  async createDependency(
    inwardId: string,
    outwardId: string,
    reason?: string
  ): Promise<void> {
    if (this.backend) {
      await this.backend.createDependency(inwardId, outwardId, reason);
    }

    const inward = this.cache.get(inwardId);
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

  /**
   * Search issues by title/description in the local cache.
   *
   * This method always operates on the cache. Populate the cache
   * first via query() or getIssue() when using a backend.
   */
  async search(query: string): Promise<IssueRecord[]> {
    const results: IssueRecord[] = [];
    const lowerQuery = query.toLowerCase();

    for (const issue of this.cache.values()) {
      if (
        issue.title.toLowerCase().includes(lowerQuery) ||
        (issue.description && issue.description.toLowerCase().includes(lowerQuery))
      ) {
        results.push(issue);
      }
    }

    return results;
  }

  /**
   * Clear cache.
   */
  clearCache(): void {
    this.cache.clear();
  }

  /**
   * Get issue from cache or storage backend.
   */
  async getIssue(issueId: string): Promise<IssueRecord | null> {
    if (this.cache.has(issueId)) {
      return this.cache.get(issueId) || null;
    }

    if (this.backend) {
      const issue = await this.backend.getIssue(issueId);
      if (issue) {
        this.cache.set(issue.id, issue);
      }
      return issue;
    }

    return null;
  }
}
