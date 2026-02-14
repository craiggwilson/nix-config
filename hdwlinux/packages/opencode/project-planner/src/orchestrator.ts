/**
 * Project Planner Orchestrator
 *
 * Central dispatcher for project planning commands.
 * Reads/writes planning issues and coordinates subagents.
  */

import { ConfigManager, IssueStorage } from "opencode-planner-core";
import { SubagentDispatcher } from "../../core/src/orchestration/subagent-dispatcher.js";
import type { SubagentResult } from "../../core/src/orchestration/subagent-dispatcher.js";
import type {
  ProjectEpic,
  BacklogItem,
  Sprint,
  ProjectStatus,
  SprintPlan,
  ProjectPlannerConfig,
} from "./types.js";

/**
 * Delegate interface for cross-plugin delegation to work executor.
 * When provided, executeSprint() will delegate execution of ready tasks.
 */
export interface WorkExecutorDelegate {
  executeWork(input: {
    issueIds: string[];
    mode?: string;
  }): Promise<{
    results: Array<{
      issueId: string;
      status: string;
      result?: unknown;
      error?: string;
    }>;
  }>;
}

const DEFAULT_CONFIG: ProjectPlannerConfig = {
  sprintStyle: "labels",
  defaultSprintLength: 2,
  defaultSprintLengthUnit: "weeks",
  autoAssignTasks: false,
  charterDocLocation: "external",
};

export class ProjectPlannerOrchestrator {
  private storage: IssueStorage;
  private config: ProjectPlannerConfig;
  private configManager: ConfigManager;
  private dispatcher: SubagentDispatcher;
  private workExecutorDelegate?: WorkExecutorDelegate;

  constructor(
    storage: IssueStorage,
    configManager: ConfigManager,
    options?: { dispatcher?: SubagentDispatcher },
  ) {
    this.storage = storage;
    this.configManager = configManager;
    this.config = configManager.load("project-planner", DEFAULT_CONFIG);
    this.dispatcher = options?.dispatcher || new SubagentDispatcher();
  }

  /**
   * Set a delegate for cross-plugin delegation to work executor.
   */
  setWorkExecutorDelegate(delegate: WorkExecutorDelegate): void {
    this.workExecutorDelegate = delegate;
  }

  /**
   * Initialize the orchestrator
   */
  async initialize(): Promise<void> {
    // No-op for now; a future implementation can validate
    // connectivity to the underlying storage backend.
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

    // Create project epic in storage
    const projectIssue = await this.storage.createIssue({
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
    const project = await this.storage.getIssue(input.projectId);
    if (!project) {
      throw new Error(`Project ${input.projectId} not found`);
    }

    const createdItems: string[] = [];
    const dependencies: Array<[string, string]> = [];

    // Use dispatcher to analyze the project and get decomposition recommendations
    const agents = this.dispatcher.selectAgents(project);
    let agentRecommendations = "";
    if (agents.length > 0) {
      const results = await this.dispatcher.dispatchSmart(agents, {
        issueId: input.projectId,
        taskType: "analyze",
        context: {
          title: project.title,
          description: project.description,
          labels: project.labels,
          parent: project.parent,
        },
        instructions: "Analyze project and recommend decomposition into backlog items.",
      });
      agentRecommendations = this.summarizeAgentResults(results);
    }

    // Create placeholder backlog items (enriched with agent recommendations)
    const backlogItems = [
      { title: "Setup and initialization", type: "task", priority: 1 },
      { title: "Core implementation", type: "feature", priority: 1 },
      { title: "Testing and validation", type: "task", priority: 2 },
      { title: "Documentation", type: "chore", priority: 3 },
    ];

    for (const item of backlogItems) {
      const itemDescription = agentRecommendations
        ? `Backlog item for ${project.title}\n\n## Agent Recommendations\n${agentRecommendations}`
        : `Backlog item for ${project.title}`;

      const issue = await this.storage.createIssue({
        type: item.type,
        title: item.title,
        description: itemDescription,
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
    const project = await this.storage.getIssue(input.projectId);
    if (!project) {
      throw new Error(`Project ${input.projectId} not found`);
    }

    // Use dispatcher for sprint planning analysis
    const agents = this.dispatcher.selectAgents(project);
    let sprintAnalysis = "";
    if (agents.length > 0) {
      const results = await this.dispatcher.dispatchSmart(agents, {
        issueId: input.projectId,
        taskType: "analyze",
        context: {
          title: `Sprint planning: ${input.sprintName}`,
          description: `Sprint from ${input.startDate} to ${input.endDate}, capacity: ${input.capacity || "unset"}`,
          labels: project.labels,
          parent: project.parent,
        },
        instructions: "Analyze project backlog and recommend tasks for the sprint.",
      });
      sprintAnalysis = this.summarizeAgentResults(results);
    }

    const sprintDescription = sprintAnalysis
      ? `Sprint from ${input.startDate} to ${input.endDate}\n\n## Agent Analysis\n${sprintAnalysis}`
      : `Sprint from ${input.startDate} to ${input.endDate}`;

    const sprintEpic = await this.storage.createIssue({
      type: "epic",
      title: input.sprintName,
      description: sprintDescription,
      labels: ["sprint", `sprint:${this.slugify(input.sprintName)}`],
      priority: 1,
      parent: input.projectId,
    });

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
    const project = await this.storage.getIssue(projectId);
    if (!project) {
      throw new Error(`Project ${projectId} not found`);
    }

    // Extract repo name from labels
    const repoLabel = (project.labels || []).find((l: string) => l.startsWith("repo:"));
    const repoName = repoLabel ? repoLabel.substring(5) : "";

    // Fetch all backlog items
    const children = await this.storage.getChildren(projectId);
    const backlogItems = children.map((child) => child.id);

    // Aggregate statuses
    const backlogStatuses = {
      done: 0,
      inProgress: 0,
      blocked: 0,
      todo: 0,
    };

    for (const itemId of backlogItems) {
      const item = await this.storage.getIssue(itemId);
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
    const project = await this.storage.getIssue(projectId);
    if (!project) {
      throw new Error(`Project ${projectId} not found`);
    }

    // Manually compute "ready" items for this project based on
    // children and their dependencies.
    const children = await this.storage.getChildren(projectId);

    // Debug logging was used during development; keep this minimal and
    // easy to remove once focus logic stabilises.
    const ready: typeof children = [];

    for (const child of children) {
      const status = child.status || "todo";
      if (status !== "todo") {
        continue;
      }

      const deps = await this.storage.getDependencies(child.id);
      const hasBlockingDeps = deps.some((depId) => {
        const dep = children.find((c) => c.id === depId) || null;
        return dep && dep.status !== "done";
      });

      if (!hasBlockingDeps) {
        ready.push(child);
      }
    }

    ready.sort((a, b) => {
      const pa = a.priority ?? Number.MAX_SAFE_INTEGER;
      const pb = b.priority ?? Number.MAX_SAFE_INTEGER;
      if (pa !== pb) return pa - pb;
      return a.id.localeCompare(b.id);
    });

    const readyItems = ready.map((item) => ({
      id: item.id,
      title: item.title,
      priority: item.priority || 0,
      estimatedEffort: undefined,
    }));

    return {
      readyItems,
      suggestedNext: readyItems.length > 0 ? readyItems[0].id : undefined,
    };
  }

  /**
   * List all projects
   */
  async listProjects(): Promise<ProjectEpic[]> {
    // Query storage for all issues with label "project"
    const issues = await this.storage.query({ labels: ["project"] });

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
   * Execute ready tasks in a sprint by delegating to work executor.
   * Requires a work executor delegate to be set.
   */
  async executeSprint(input: {
    projectId: string;
    mode?: string;
  }): Promise<{
    executedCount: number;
    results: Array<{ issueId: string; status: string; error?: string }>;
  }> {
    if (!this.workExecutorDelegate) {
      return { executedCount: 0, results: [] };
    }

    const focus = await this.getProjectFocus(input.projectId);
    if (focus.readyItems.length === 0) {
      return { executedCount: 0, results: [] };
    }

    const issueIds = focus.readyItems.map((item) => item.id);
    const delegateResult = await this.workExecutorDelegate.executeWork({
      issueIds,
      mode: input.mode,
    });

    return {
      executedCount: delegateResult.results.length,
      results: delegateResult.results.map((r) => ({
        issueId: r.issueId,
        status: r.status,
        error: r.error,
      })),
    };
  }

  /**
   * Summarize results from dispatched agents into a readable string.
   */
  private summarizeAgentResults(results: SubagentResult[]): string {
    const parts: string[] = [];
    for (const result of results) {
      if (result.status === "failed") continue;
      const header = `### ${result.agentName}`;
      const findings = (result.findings || []).map((f) => `- ${f}`).join("\n");
      const recommendations = (result.recommendations || []).map((r) => `- ${r}`).join("\n");
      const sections: string[] = [header];
      if (findings) sections.push(`**Findings:**\n${findings}`);
      if (recommendations) sections.push(`**Recommendations:**\n${recommendations}`);
      parts.push(sections.join("\n"));
    }
    return parts.join("\n\n");
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
