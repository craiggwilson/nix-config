/**
 * Project Planner Orchestrator
 *
 * Central dispatcher for project planning commands.
 * Reads/writes beads and coordinates subagents.
 */

import { BeadsClient } from "opencode-beads";
import { ConfigManager } from "opencode-planner-core";
import type {
  ProjectEpic,
  BacklogItem,
  Sprint,
  ProjectStatus,
  SprintPlan,
  ProjectPlannerConfig,
} from "./types.js";

const DEFAULT_CONFIG: ProjectPlannerConfig = {
  sprintStyle: "labels",
  defaultSprintLength: 2,
  defaultSprintLengthUnit: "weeks",
  autoAssignTasks: false,
  charterDocLocation: "external",
};

export class ProjectPlannerOrchestrator {
  private beads: BeadsClient;
  private config: ProjectPlannerConfig;
  private configManager: ConfigManager;

  constructor(beads: BeadsClient, configManager: ConfigManager) {
    this.beads = beads;
    this.configManager = configManager;
    this.config = configManager.load("project-planner", DEFAULT_CONFIG);
  }

  /**
   * Initialize the orchestrator
   */
  async initialize(): Promise<void> {
    // Validate beads is available
    try {
      await this.beads.show("test");
    } catch {
      // Beads might not have any issues yet, that's ok
    }
  }

  /**
   * Initialize project planning for a repo/service
   */
  async initProject(input: {
    repoName: string;
    projectName?: string;
    programId?: string;
  }): Promise<{ projectId: string; charterDocUrl?: string }> {
    const projectName = input.projectName || input.repoName;

    const description = `
## Project
${projectName}

## Repository
${input.repoName}

## Status
Initialized
`.trim();

    // Create beads epic for the project
    const projectIssue = await this.beads.create({
      type: "epic",
      title: projectName,
      description,
      labels: [
        "project",
        `project:${this.slugify(projectName)}`,
        `repo:${input.repoName}`,
        ...(input.programId ? [`program:${input.programId}`] : []),
      ],
      priority: 1,
    });

    // TODO: Create project charter doc if configured
    // TODO: Store charter doc link in issue description

    return {
      projectId: projectIssue.id,
      charterDocUrl: undefined, // TODO: implement
    };
  }

  /**
   * Plan a project by decomposing it into backlog items
   */
  async planProject(input: {
    projectId: string;
    programId?: string;
  }): Promise<{ createdItems: string[]; dependencies: Array<[string, string]> }> {
    // Fetch project issue
    const project = await this.beads.show(input.projectId);
    if (!project) {
      throw new Error(`Project ${input.projectId} not found`);
    }

    const createdItems: string[] = [];
    const dependencies: Array<[string, string]> = [];

    // TODO: Spawn backlog-decomposer-agent to propose features/tasks/chores
    // For now, create placeholder backlog items
    const backlogItems = [
      { title: "Setup and initialization", type: "task", priority: 1 },
      { title: "Core implementation", type: "feature", priority: 1 },
      { title: "Testing and validation", type: "task", priority: 2 },
      { title: "Documentation", type: "chore", priority: 3 },
    ];

    for (const item of backlogItems) {
      const issue = await this.beads.create({
        type: item.type,
        title: item.title,
        description: `Backlog item for ${project.title}`,
        labels: [`project:${this.slugify(project.title)}`],
        priority: item.priority,
        parent: input.projectId,
      });

      createdItems.push(issue.id);
      dependencies.push([input.projectId, issue.id]);
    }

    return {
      createdItems,
      dependencies,
    };
  }

  /**
   * Plan a sprint
   */
  async planSprint(input: {
    projectId: string;
    sprintName: string;
    startDate: string;
    endDate: string;
    capacity?: number;
    autoAssign?: boolean;
  }): Promise<SprintPlan> {
    // Fetch project issue
    const project = await this.beads.show(input.projectId);
    if (!project) {
      throw new Error(`Project ${input.projectId} not found`);
    }

    // TODO: Spawn sprint-planner-agent to select tasks
    // For now, create a sprint epic or apply labels
    const sprintEpic = await this.beads.create({
      type: "epic",
      title: input.sprintName,
      description: `Sprint from ${input.startDate} to ${input.endDate}`,
      labels: ["sprint", `sprint:${this.slugify(input.sprintName)}`],
      priority: 1,
      parent: input.projectId,
    });

    // TODO: Select tasks based on priority and capacity
    // For now, return empty plan
    const selectedItems: Array<{
      id: string;
      title: string;
      estimatedEffort?: string;
      priority: number;
    }> = [];

    const capacity = input.capacity || 10;
    const capacityUtilization = selectedItems.length > 0 ? (selectedItems.length / capacity) * 100 : 0;

    return {
      sprintName: input.sprintName,
      startDate: input.startDate,
      endDate: input.endDate,
      capacity,
      selectedItems,
      capacityUtilization,
      risks: [],
    };
  }

  /**
   * Get status of a project
   */
  async getProjectStatus(projectId: string): Promise<ProjectStatus> {
    const project = await this.beads.show(projectId);
    if (!project) {
      throw new Error(`Project ${projectId} not found`);
    }

    // Extract repo name from labels
    const repoLabel = (project.labels || []).find((l: string) => l.startsWith("repo:"));
    const repoName = repoLabel ? repoLabel.substring(5) : "";

    // Fetch all backlog items
    const children = await this.beads.show(projectId, { includeChildren: true });
    const backlogItems = children?.children || [];

    // Aggregate statuses
    const backlogStatuses = {
      done: 0,
      inProgress: 0,
      blocked: 0,
      todo: 0,
    };

    for (const itemId of backlogItems) {
      const item = await this.beads.show(itemId);
      if (item) {
        const status = item.status || "todo";
        if (status === "done") backlogStatuses.done++;
        else if (status === "in_progress") backlogStatuses.inProgress++;
        else if (status === "blocked") backlogStatuses.blocked++;
        else backlogStatuses.todo++;
      }
    }

    // Calculate progress percentage
    const total = backlogItems.length;
    const progressPercentage = total > 0 ? (backlogStatuses.done / total) * 100 : 0;

    return {
      projectId,
      title: project.title,
      repoName,
      status: project.status || "todo",
      backlogCount: backlogItems.length,
      backlogStatuses,
      blockedItems: [], // TODO: Identify blocked items
      staleItems: [], // TODO: Identify stale items
      progressPercentage,
    };
  }

  /**
   * Get focus/ready items for a project
   */
  async getProjectFocus(projectId: string): Promise<{
    readyItems: Array<{
      id: string;
      title: string;
      priority: number;
      estimatedEffort?: string;
    }>;
    suggestedNext?: string;
  }> {
    // TODO: Query beads for ready items (no blocking dependencies)
    // TODO: Filter by project
    // TODO: Sort by priority
    // TODO: Suggest next item to start

    // For now, return empty list
    const readyItems: Array<{
      id: string;
      title: string;
      priority: number;
      estimatedEffort?: string;
    }> = [];

    return {
      readyItems,
      suggestedNext: readyItems.length > 0 ? readyItems[0].id : undefined,
    };
  }

  /**
   * List all projects
   */
  async listProjects(): Promise<ProjectEpic[]> {
    // Query beads for all issues with label "project"
    const issues = await this.beads.query({ labels: ["project"] });

    const projects: ProjectEpic[] = issues.map((issue: any) => {
      const repoLabel = (issue.labels || []).find((l: string) => l.startsWith("repo:"));
      const repoName = repoLabel ? repoLabel.substring(5) : "";

      return {
        id: issue.id,
        title: issue.title,
        repoName,
        description: issue.description || "",
        backlogItems: [], // TODO: Fetch children
        dependencies: [], // TODO: Fetch dependencies
        status: issue.status || "todo",
        priority: issue.priority || 1,
        createdAt: issue.createdAt || new Date().toISOString(),
        updatedAt: issue.updatedAt || new Date().toISOString(),
      };
    });

    return projects.sort((a, b) => a.priority - b.priority);
  }

  /**
   * Handle /project-init command
   */
  async handleProjectInit(args: string[]): Promise<void> {
    if (args.length === 0) {
      console.log("Usage: /project-init <repo-name> [project-name] [program-id]");
      return;
    }

    const repoName = args[0];
    const projectName = args[1];
    const programId = args[2];

    try {
      const result = await this.initProject({ repoName, projectName, programId });
      console.log(`Created project: ${result.projectId}`);
    } catch (error) {
      console.error("Error initializing project:", error);
    }
  }

  /**
   * Handle /project-plan command
   */
  async handleProjectPlan(args: string[]): Promise<void> {
    if (args.length === 0) {
      console.log("Usage: /project-plan <project-id> [program-id]");
      return;
    }

    const projectId = args[0];
    const programId = args[1];

    try {
      const result = await this.planProject({ projectId, programId });
      console.log(`Created ${result.createdItems.length} backlog items`);
      console.log("Created items:", result.createdItems);
    } catch (error) {
      console.error("Error planning project:", error);
    }
  }

  /**
   * Handle /project-sprint command
   */
  async handleProjectSprint(args: string[]): Promise<void> {
    if (args.length < 4) {
      console.log("Usage: /project-sprint <project-id> <sprint-name> <start-date> <end-date> [capacity]");
      return;
    }

    const projectId = args[0];
    const sprintName = args[1];
    const startDate = args[2];
    const endDate = args[3];
    const capacity = args[4] ? parseInt(args[4]) : undefined;

    try {
      const result = await this.planSprint({
        projectId,
        sprintName,
        startDate,
        endDate,
        capacity,
      });
      console.log(`Created sprint: ${result.sprintName}`);
      console.log(`Capacity: ${result.capacityUtilization.toFixed(0)}% utilized`);
    } catch (error) {
      console.error("Error planning sprint:", error);
    }
  }

  /**
   * Handle /project-status command
   */
  async handleProjectStatus(args: string[]): Promise<void> {
    try {
      if (args.length > 0) {
        // Get status for specific project
        const projectId = args[0];
        const status = await this.getProjectStatus(projectId);
        console.log(`Project: ${status.title}`);
        console.log(`Repository: ${status.repoName}`);
        console.log(`Status: ${status.status}`);
        console.log(`Progress: ${status.progressPercentage.toFixed(0)}%`);
        console.log(`Backlog: ${status.backlogStatuses.done}/${status.backlogCount} done`);
      } else {
        // List all projects with status
        const projects = await this.listProjects();
        console.log(`Found ${projects.length} projects:`);
        for (const project of projects) {
          const status = await this.getProjectStatus(project.id);
          console.log(`  - ${project.title} (${project.repoName}): ${status.progressPercentage.toFixed(0)}% complete`);
        }
      }
    } catch (error) {
      console.error("Error getting project status:", error);
    }
  }

  /**
   * Handle /project-focus command
   */
  async handleProjectFocus(args: string[]): Promise<void> {
    if (args.length === 0) {
      console.log("Usage: /project-focus <project-id>");
      return;
    }

    const projectId = args[0];

    try {
      const result = await this.getProjectFocus(projectId);
      console.log(`Found ${result.readyItems.length} ready items`);
      for (const item of result.readyItems) {
        console.log(`  - ${item.title} (${item.id})`);
      }
      if (result.suggestedNext) {
        console.log(`\nSuggested next: ${result.suggestedNext}`);
      }
    } catch (error) {
      console.error("Error getting project focus:", error);
    }
  }

  /**
   * Handle /project-list command
   */
  async handleProjectList(args: string[]): Promise<void> {
    try {
      const projects = await this.listProjects();
      console.log(`Found ${projects.length} projects:`);
      for (const project of projects) {
        console.log(`  - ${project.title} (${project.id})`);
        console.log(`    Repository: ${project.repoName}, Status: ${project.status}, Priority: ${project.priority}`);
      }
    } catch (error) {
      console.error("Error listing projects:", error);
    }
  }

  /**
   * Helper: convert string to slug
   */
  private slugify(str: string): string {
    return str
      .toLowerCase()
      .replace(/[^\w\s-]/g, "")
      .replace(/\s+/g, "-")
      .replace(/-+/g, "-");
  }
}
