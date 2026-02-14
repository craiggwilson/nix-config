/**
 * Issue query and manipulation helpers.
 *
 * This module defines a storage abstraction for planning issues.
 * The underlying implementation can be backed by beads (via tools
 * exposed by the opencode-beads plugin) or by another system.
 */
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
 * In-memory issue storage and helper utilities.
 *
 * Optionally delegates to an IssueStorageBackend when one is provided.
 * Without a backend, uses only an in-memory cache.
 */
export declare class IssueStorage {
    private cache;
    private backend?;
    constructor(backend?: import("./storage-backend.js").IssueStorageBackend);
    /**
     * Query issues with filters.
     */
    query(filters: IssueQuery): Promise<IssueRecord[]>;
    /**
     * Find ready tasks (no blocking dependencies)
     */
    findReady(projectId?: string): Promise<IssueRecord[]>;
    /**
     * Analyze dependency graph
     */
    analyzeDependencies(issueId: string): Promise<{
        cycles: string[][];
        criticalPath: string[];
        blockers: string[];
    }>;
    /**
     * Get all children of an issue.
     */
    getChildren(parentId: string): Promise<IssueRecord[]>;
    /**
     * Get all dependencies of an issue
     */
    getDependencies(issueId: string): Promise<string[]>;
    /**
     * Create a new issue with proper structure.
     */
    createIssue(input: {
        type: string;
        title: string;
        description?: string;
        labels?: string[];
        priority?: number;
        parent?: string;
        assignee?: string;
    }): Promise<{
        id: string;
    }>;
    /**
     * Update an issue in the in-memory cache.
     */
    updateIssue(issueId: string, updates: {
        title?: string;
        description?: string;
        status?: string;
        priority?: number;
        assignee?: string;
        labels?: string[];
    }): Promise<void>;
    /**
     * Create a dependency between two issues.
     */
    createDependency(inwardId: string, outwardId: string, reason?: string): Promise<void>;
    /**
     * Search issues by title/description in the in-memory cache.
     */
    search(query: string): Promise<IssueRecord[]>;
    /**
     * Clear cache.
     */
    clearCache(): void;
    /**
     * Get issue from cache or storage backend.
     */
    getIssue(issueId: string): Promise<IssueRecord | null>;
}
//# sourceMappingURL=beads.d.ts.map