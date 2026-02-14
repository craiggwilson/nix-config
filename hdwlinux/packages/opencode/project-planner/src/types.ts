/**
 * Project Planner Plugin Types
 */

export interface ProjectPlannerConfig {
  sprintStyle: "labels" | "epics";
  defaultSprintLength: number;
  defaultSprintLengthUnit: "days" | "weeks";
  autoAssignTasks: boolean;
  charterDocLocation: "external" | "local";
}

export interface ProjectEpic {
  id: string;
  title: string;
  repoName: string;
  serviceName?: string;
  programId?: string;
  description: string;
  charterDocUrl?: string;
  backlogItems: string[]; // beads issue IDs
  dependencies: string[]; // beads issue IDs
  status: "todo" | "in_progress" | "blocked" | "done";
  priority: 0 | 1 | 2 | 3 | 4;
  createdAt: string;
  updatedAt: string;
}

export interface BacklogItem {
  id: string;
  title: string;
  type: "feature" | "task" | "chore" | "bug";
  projectId: string;
  description: string;
  priority: 0 | 1 | 2 | 3 | 4;
  status: "todo" | "in_progress" | "blocked" | "done";
  assignee?: string;
  estimatedEffort?: string;
  dependencies: string[]; // beads issue IDs
  discoveredFrom?: string; // parent issue ID
  createdAt: string;
  updatedAt: string;
}

export interface Sprint {
  id: string;
  name: string;
  projectId: string;
  startDate: string;
  endDate: string;
  capacity?: number;
  items: string[]; // beads issue IDs
  status: "planned" | "active" | "completed";
  createdAt: string;
  updatedAt: string;
}

export interface ProjectStatus {
  projectId: string;
  title: string;
  repoName: string;
  status: "todo" | "in_progress" | "blocked" | "done";
  backlogCount: number;
  backlogStatuses: {
    done: number;
    inProgress: number;
    blocked: number;
    todo: number;
  };
  currentSprint?: {
    name: string;
    itemCount: number;
    completedCount: number;
    blockedCount: number;
  };
  blockedItems: string[];
  staleItems: string[];
  progressPercentage: number;
}

export interface SprintPlan {
  sprintName: string;
  startDate: string;
  endDate: string;
  capacity: number;
  selectedItems: Array<{
    id: string;
    title: string;
    estimatedEffort?: string;
    priority: number;
  }>;
  capacityUtilization: number;
  risks: string[];
}

export interface BacklogDecomposition {
  features: Array<{
    title: string;
    description: string;
    priority: 0 | 1 | 2 | 3 | 4;
    estimatedEffort?: string;
    dependencies: string[];
  }>;
  tasks: Array<{
    title: string;
    description: string;
    priority: 0 | 1 | 2 | 3 | 4;
    estimatedEffort?: string;
    dependencies: string[];
  }>;
  chores: Array<{
    title: string;
    description: string;
    priority: 0 | 1 | 2 | 3 | 4;
    estimatedEffort?: string;
    dependencies: string[];
  }>;
}
