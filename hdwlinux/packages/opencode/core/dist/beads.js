/**
 * Issue query and manipulation helpers.
 *
 * This module defines a storage abstraction for planning issues.
 * The underlying implementation can be backed by beads (via tools
 * exposed by the opencode-beads plugin) or by another system.
 */
/**
 * In-memory issue storage and helper utilities.
 *
 * NOTE: The current implementation uses only an in-memory cache.
 * A future backend can call opencode-beads tools via the OpenCode SDK.
 */
export class IssueStorage {
    constructor() {
        this.cache = new Map();
    }
    /**
     * Query issues with filters.
     */
    async query(filters) {
        // TODO: In a real backend, translate filters into a query and
        // execute it via tools (for example, opencode-beads).
        // For now, filter the in-memory cache.
        const results = [];
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
    async findReady(projectId) {
        const filters = {
            status: ["todo"],
        };
        if (projectId) {
            filters.parent = projectId;
        }
        const items = await this.query(filters);
        // Filter out items with blocking dependencies
        const ready = [];
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
            if (pa !== pb)
                return pa - pb;
            return a.id.localeCompare(b.id);
        });
    }
    /**
     * Analyze dependency graph
     */
    async analyzeDependencies(issueId) {
        const visited = new Set();
        const cycles = [];
        const blockers = [];
        // Detect cycles using DFS
        const detectCycles = async (nodeId, path) => {
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
        const criticalPath = [];
        const calculatePath = async (nodeId, path) => {
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
    async getChildren(parentId) {
        return this.query({ parent: parentId });
    }
    /**
     * Get all dependencies of an issue
     */
    async getDependencies(issueId) {
        const issue = this.cache.get(issueId);
        if (issue && issue.dependencies) {
            return issue.dependencies;
        }
        // TODO: Fetch from storage backend if not in cache
        return [];
    }
    /**
     * Create a new issue with proper structure.
     */
    async createIssue(input) {
        if (!input.type || !input.title) {
            throw new Error("type and title are required");
        }
        // TODO: Create issue via storage backend.
        // For now, generate a mock ID and store only in the in-memory cache.
        // Use a neutral ISSUE- prefix so IDs are clearly stubbed and not
        // mistaken for real beads IDs.
        const id = `ISSUE-${Date.now()}`;
        const issue = {
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
     * Update an issue in the in-memory cache.
     */
    async updateIssue(issueId, updates) {
        const issue = this.cache.get(issueId);
        if (!issue) {
            throw new Error(`Issue not found: ${issueId}`);
        }
        if (updates.title)
            issue.title = updates.title;
        if (updates.description)
            issue.description = updates.description;
        if (updates.status)
            issue.status = updates.status;
        if (updates.priority !== undefined)
            issue.priority = updates.priority;
        if (updates.assignee)
            issue.assignee = updates.assignee;
        if (updates.labels)
            issue.labels = updates.labels;
        // TODO: Update via storage backend.
    }
    /**
     * Create a dependency between two issues.
     */
    async createDependency(inwardId, outwardId, reason) {
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
        // TODO: Create dependency via storage backend.
    }
    /**
     * Search issues by title/description in the in-memory cache.
     */
    async search(query) {
        // TODO: Execute search via storage backend.
        // For now, search cache only.
        const results = [];
        const lowerQuery = query.toLowerCase();
        for (const issue of this.cache.values()) {
            if (issue.title.toLowerCase().includes(lowerQuery) ||
                (issue.description && issue.description.toLowerCase().includes(lowerQuery))) {
                results.push(issue);
            }
        }
        return results;
    }
    /**
     * Clear cache.
     */
    clearCache() {
        this.cache.clear();
    }
    /**
     * Get issue from cache or storage backend.
     */
    async getIssue(issueId) {
        if (this.cache.has(issueId)) {
            return this.cache.get(issueId) || null;
        }
        // TODO: Fetch from storage backend if not in cache.
        return null;
    }
}
//# sourceMappingURL=beads.js.map