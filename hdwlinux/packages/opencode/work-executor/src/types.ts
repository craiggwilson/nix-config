/**
 * Work Executor Plugin Types
 */

export type WorkType = "research" | "poc" | "implementation" | "review";
export type ReviewMode = "code-review" | "security-review" | "both";
export type ExecutionMode = "full" | "research-only" | "poc-only";

export interface WorkExecutorConfig {
  riskPosture: "low" | "medium" | "high";
  alwaysRunSecurityReview: boolean;
  autonomousEditLimits: {
    maxFilesPerCommit: number;
    requiresApprovalForPublicAPIs: boolean;
    requiresApprovalForDependencyChanges: boolean;
  };
  techStackPreferences: {
    defaultLanguage?: string;
    preferredFrameworks?: string[];
  };
}

export interface WorkItem {
  id: string;
  title: string;
  type: "task" | "feature" | "chore" | "bug";
  workType: WorkType;
  projectId?: string;
  programId?: string;
  description: string;
  status: "todo" | "in_progress" | "blocked" | "done";
  assignee?: string;
  priority: 0 | 1 | 2 | 3 | 4;
  labels: string[];
  dependencies: string[]; // beads issue IDs
  discoveredFrom?: string; // parent issue ID
  createdAt: string;
  updatedAt: string;
}

export interface DiscoveredWorkItem {
  id: string;
  parentId: string;
  title: string;
  type: "bug" | "chore" | "task" | "feature";
  description: string;
  priority: 0 | 1 | 2 | 3 | 4;
  createdAt: string;
}

export interface ResearchResult {
  issueId: string;
  question: string;
  summary: string;
  options: Array<{
    name: string;
    pros: string[];
    cons: string[];
  }>;
  recommendation: string;
  reasoning: string;
  followUpTasks?: string[];
  reportUrl?: string;
}

export interface POCResult {
  issueId: string;
  hypothesis: string;
  outcome: "keep" | "refine" | "discard";
  findings: string;
  recommendation: string;
  discoveredWork: DiscoveredWorkItem[];
  notesUrl?: string;
}

export interface ImplementationResult {
  issueId: string;
  status: "completed" | "partial" | "failed";
  changes: {
    filesModified: number;
    linesAdded: number;
    linesRemoved: number;
  };
  testsRun: number;
  testsPassed: number;
  testsFailed: number;
  codeReviewFindings: ReviewFinding[];
  securityReviewFindings: ReviewFinding[];
  discoveredWork: DiscoveredWorkItem[];
  prUrl?: string;
}

export interface ReviewFinding {
  severity: "info" | "warning" | "error";
  category: string;
  description: string;
  location?: string;
  suggestion?: string;
}

export interface ReviewResult {
  issueId: string;
  mode: ReviewMode;
  findings: ReviewFinding[];
  summary: string;
  followUpIssues: DiscoveredWorkItem[];
}

export interface ExecutionPipeline {
  workItemId: string;
  workType: WorkType;
  executionMode: ExecutionMode;
  steps: Array<{
    name: string;
    status: "pending" | "in_progress" | "completed" | "failed";
    result?: unknown;
    error?: string;
  }>;
  startedAt: string;
  completedAt?: string;
}

export interface SubagentSelection {
  language?: string;
  domains: string[];
  requiresDistributedSystems: boolean;
  requiresSecurity: boolean;
  requiresCodeReview: boolean;
  requiresSecurityReview: boolean;
}
