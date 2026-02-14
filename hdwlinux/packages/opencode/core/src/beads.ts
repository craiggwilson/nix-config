/**
 * Beads Query and Manipulation Helpers
 */

import { BeadsClient } from "opencode-beads";

export interface BeadsQuery {
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

export interface BeadsIssue {
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

export class BeadsHelper {
  private cache: Map<string, BeadsIssue> = new Map();

  constructor(private beads: BeadsClient) {}

  /**
   * Query beads with filters
   */
  async query(filters: BeadsQuery): Promise<BeadsIssue[]> {
    const conditions: string[] = [];

    if (filters.labels && filters.labels.length > 0) {
      const labelConditions = filters.labels.map((label) => `label:"${label}"`).join(" OR ");
      conditions.push(`(${labelConditions})`);
    }

    if (filters.status && filters.status.length > 0) {
      const statusConditions = filters.status.map((status) => `status:"${status}"`).join(" OR ");
      conditions.push(`(${statusConditions})`);
    }

    if (filters.priority && filters.priority.length > 0) {
      const priorityConditions = filters.priority.map((p) => `priority:${p}`).join(" OR ");
      conditions.push(`(${priorityConditions})`);
    }

    if (filters.parent) {
      conditions.push(`parent:"${filters.parent}"`);
    }

    if (filters.type && filters.type.length > 0) {
      const typeConditions = filters.type.map((t) => `type:"${t}"`).join(" OR ");
      conditions.push(`(${typeConditions})`);
    }

    if (filters.assignee) {
      conditions.push(`assignee:"${filters.assignee}"`);
    }

    const jql = conditions.length > 0 ? conditions.join(" AND ") : "";

    // TODO: Execute JQL query via beads CLI
    // For now, return empty array
    return [];
  }

  /**
   * Find ready tasks (no blocking dependencies)
   */
  async findReady(projectId?: string): Promise<BeadsIssue[]> {
    const filters: BeadsQuery = {
      status: ["todo"],
    };

    if (projectId) {
      filters.parent = projectId;
    }

    const items = await this.query(filters);

    // Filter out items with blocking dependencies
    const ready: BeadsIssue[] = [];
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

    return ready.sort((a, b) => (b.priority || 0) - (a.priority || 0));
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
   * Get all children of an issue
   */
  async getChildren(parentId: string): Promise<BeadsIssue[]> {
    return this.query({ parent: parentId });
  }

  /**
   * Get all dependencies of an issue
   */
  async getDependencies(issueId: string): Promise<string[]> {
    const issue = this.cache.get(issueId);
    if (issue && issue.dependencies) {
      return issue.dependencies;
    }

    // TODO: Fetch from beads if not in cache
    return [];
  }

  /**
   * Create a new issue with proper structure
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
    // Validate input
    if (!input.type || !input.title) {
      throw new Error("type and title are required");
    }

    // TODO: Create issue via beads CLI
    // For now, generate a mock ID
    const id = `${input.type.toUpperCase()}-${Date.now()}`;

    const issue: BeadsIssue = {
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
   * Update an issue
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
    const issue = this.cache.get(issueId);
    if (!issue) {
      throw new Error(`Issue not found: ${issueId}`);
    }

    // Update cache
    if (updates.title) issue.title = updates.title;
    if (updates.description) issue.description = updates.description;
    if (updates.status) issue.status = updates.status;
    if (updates.priority !== undefined) issue.priority = updates.priority;
    if (updates.assignee) issue.assignee = updates.assignee;
    if (updates.labels) issue.labels = updates.labels;

    // TODO: Update via beads CLI
  }

  /**
   * Create a dependency between two issues
   */
  async createDependency(
    inwardId: string,
    outwardId: string,
    reason?: string
  ): Promise<void> {
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

    // TODO: Create dependency via beads CLI
  }

  /**
   * Search issues by title/description
   */
  async search(query: string): Promise<BeadsIssue[]> {
    // TODO: Execute search via beads CLI
    // For now, search cache
    const results: BeadsIssue[] = [];
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
   * Clear cache
   */
  clearCache(): void {
    this.cache.clear();
  }

  /**
   * Get issue from cache or beads
   */
  async getIssue(issueId: string): Promise<BeadsIssue | null> {
    if (this.cache.has(issueId)) {
      return this.cache.get(issueId) || null;
    }

    // TODO: Fetch from beads if not in cache
    return null;
  }
}
