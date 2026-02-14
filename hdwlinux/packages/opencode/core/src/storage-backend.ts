/**
 * Storage backend interface for IssueStorage.
 *
 * This allows us to plug in different implementations (for example, a
 * beads-backed backend that calls opencode-beads tools via the
 * OpenCode SDK) without changing orchestrator code.
 */

import type { IssueQuery, IssueRecord } from "./beads.js";

export interface IssueStorageBackend {
  query(filters: IssueQuery): Promise<IssueRecord[]>;
  getIssue(issueId: string): Promise<IssueRecord | null>;
  createIssue(input: {
    type: string;
    title: string;
    description?: string;
    labels?: string[];
    priority?: number;
    parent?: string;
    assignee?: string;
  }): Promise<{ id: string }>;
  updateIssue(
    issueId: string,
    updates: {
      title?: string;
      description?: string;
      status?: string;
      priority?: number;
      assignee?: string;
      labels?: string[];
    }
  ): Promise<void>;
  createDependency(
    inwardId: string,
    outwardId: string,
    reason?: string
  ): Promise<void>;
}
