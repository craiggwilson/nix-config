/**
 * Program Planner Plugin Types
 */

export interface ProgramPlannerConfig {
  defaultHorizon: "week" | "month" | "quarter" | "half-year" | "year";
  autoCreateProjectEpics: boolean;
  defaultLabels: string[];
  charterDocLocation: "external" | "local";
}

export interface Program {
  id: string;
  title: string;
  summary: string;
  horizon: string;
  goals: string[];
  nonGoals: string[];
  metrics: string[];
  constraints: string[];
  charterDocUrl?: string;
  projectEpics: string[]; // beads issue IDs
  dependencies: string[]; // beads issue IDs
  status: "todo" | "in_progress" | "blocked" | "done";
  priority: 0 | 1 | 2 | 3 | 4;
  createdAt: string;
  updatedAt: string;
}

export interface ProjectEpic {
  id: string;
  title: string;
  programId: string;
  repoName?: string;
  serviceName?: string;
  description: string;
  charterDocUrl?: string;
  features: string[]; // beads issue IDs
  dependencies: string[]; // beads issue IDs
  status: "todo" | "in_progress" | "blocked" | "done";
  priority: 0 | 1 | 2 | 3 | 4;
  createdAt: string;
  updatedAt: string;
}

export interface RiskItem {
  id: string;
  programId: string;
  description: string;
  likelihood: "low" | "medium" | "high";
  impact: "low" | "medium" | "high";
  mitigationStrategy: string;
  status: "identified" | "mitigating" | "resolved";
  createdAt: string;
  updatedAt: string;
}

export interface ProgramStatus {
  programId: string;
  title: string;
  status: "todo" | "in_progress" | "blocked" | "done";
  projectCount: number;
  projectStatuses: {
    done: number;
    inProgress: number;
    blocked: number;
    todo: number;
  };
  risks: RiskItem[];
  blockedItems: string[];
  upcomingMilestones: string[];
  progressPercentage: number;
}

export interface DecompositionProposal {
  projectEpics: Array<{
    title: string;
    description: string;
    repoName?: string;
    priority: 0 | 1 | 2 | 3 | 4;
    estimatedEffort?: string;
    dependencies: string[];
  }>;
  crossCuttingEpics: Array<{
    title: string;
    description: string;
    category: "infra" | "security" | "platform" | "other";
    priority: 0 | 1 | 2 | 3 | 4;
    estimatedEffort?: string;
    dependencies: string[];
  }>;
  dependencyGraph: {
    nodes: string[];
    edges: Array<{ from: string; to: string; reason: string }>;
  };
}

export interface SubagentRequest {
  type: "requirements" | "decomposer" | "risk";
  programId?: string;
  programDescription?: string;
  existingProjectEpics?: ProjectEpic[];
  codebaseSummaries?: Record<string, string>;
}

export interface SubagentResponse {
  type: "requirements" | "decomposer" | "risk";
  success: boolean;
  data: unknown;
  error?: string;
}
