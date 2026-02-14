/**
 * Program Planner Orchestrator
 *
 * Central dispatcher for program planning commands.
 * Reads/writes planning issues and coordinates subagents.
  */

import { ConfigManager, IssueStorage } from "opencode-planner-core";
import type {
  Program,
  ProjectEpic,
  ProgramStatus,
  DecompositionProposal,
  ProgramPlannerConfig,
} from "./types.js";

const DEFAULT_CONFIG: ProgramPlannerConfig = {
  defaultHorizon: "quarter",
  autoCreateProjectEpics: true,
  defaultLabels: ["program"],
  charterDocLocation: "external",
};

export class ProgramPlannerOrchestrator {
  private storage: IssueStorage;
  private config: ProgramPlannerConfig;
  private configManager: ConfigManager;

  constructor(storage: IssueStorage, configManager: ConfigManager) {
    this.storage = storage;
    this.configManager = configManager;
    this.config = configManager.load("program-planner", DEFAULT_CONFIG);
  }

  /**
   * Initialize the orchestrator
   */
  async initialize(): Promise<void> {
    // No-op for now; a future implementation can validate
    // connectivity to the underlying storage backend.
  }

  /**
   * Create a new program
   */
  async createProgram(input: {
    name: string;
    summary: string;
    horizon: string;
    goals: string[];
    nonGoals: string[];
    metrics: string[];
    constraints: string[];
    repos?: string[];
  }): Promise<{ programId: string; charterDocUrl?: string }> {
    // Build description with structured data
    const description = `
## Summary
${input.summary}

## Horizon
${input.horizon}

## Goals
${input.goals.map((g) => `- ${g}`).join("\n")}

## Non-Goals
${input.nonGoals.map((ng) => `- ${ng}`).join("\n")}

## Metrics
${input.metrics.map((m) => `- ${m}`).join("\n")}

## Constraints
${input.constraints.map((c) => `- ${c}`).join("\n")}
`.trim();

    // Create program issue in storage
    const programIssue = await this.storage.createIssue({
      type: "epic",
      title: input.name,
      description,
      labels: ["program", `program:${this.slugify(input.name)}`],
      priority: 1,
    });

    // TODO: Spawn program-requirements-agent to structure charter
    // TODO: Create charter doc if configured
    // TODO: Store charter doc link in issue description

    return {
      programId: programIssue.id,
      charterDocUrl: undefined, // TODO: implement
    };
  }

  /**
   * Plan a program by decomposing it into project epics
   */
  async planProgram(input: {
    programId: string;
    repos?: string[];
  }): Promise<{ createdEpics: string[]; dependencies: Array<[string, string]> }> {
    // Fetch program issue
    const program = await this.storage.getIssue(input.programId);
    if (!program) {
      throw new Error(`Program ${input.programId} not found`);
    }

    const createdEpics: string[] = [];
    const dependencies: Array<[string, string]> = [];

    // TODO: Spawn program-decomposer-agent to propose project epics
    // For now, create placeholder project epics for each repo
    if (input.repos && input.repos.length > 0) {
      for (const repo of input.repos) {
        const projectEpic = await this.storage.createIssue({
          type: "epic",
          title: `${repo} - ${program.title}`,
          description: `Project epic for ${repo} as part of ${program.title}`,
          labels: [
            "project",
            `project:${this.slugify(repo)}`,
            `repo:${repo}`,
            `program:${this.slugify(program.title)}`,
          ],
          priority: program.priority || 1,
          parent: input.programId,
        });

        createdEpics.push(projectEpic.id);
        dependencies.push([input.programId, projectEpic.id]);
      }
    }

    return {
      createdEpics,
      dependencies,
    };
  }

  /**
   * Get status of a program
   */
  async getProgramStatus(programId: string): Promise<ProgramStatus> {
    const program = await this.storage.getIssue(programId);
    if (!program) {
      throw new Error(`Program ${programId} not found`);
    }

    // Fetch all child project epics
    const children = await this.storage.getChildren(programId);
    const projectEpics = children.map((child) => child.id);

    // Aggregate statuses
    const projectStatuses = {
      done: 0,
      inProgress: 0,
      blocked: 0,
      todo: 0,
    };

    for (const epicId of projectEpics) {
       const epic = await this.storage.getIssue(epicId);
      if (epic) {
        const status = epic.status || "todo";
        if (status === "done") projectStatuses.done++;
        else if (status === "in_progress") projectStatuses.inProgress++;
        else if (status === "blocked") projectStatuses.blocked++;
        else projectStatuses.todo++;
      }
    }

    // Calculate progress percentage
    const total = projectEpics.length;
    const progressPercentage = total > 0 ? (projectStatuses.done / total) * 100 : 0;

    return {
      programId,
      title: program.title,
      status: program.status || "todo",
      projectCount: projectEpics.length,
      projectStatuses,
      risks: [], // TODO: Fetch risk issues
      blockedItems: [], // TODO: Identify blocked items
      upcomingMilestones: [], // TODO: Extract from descriptions
      progressPercentage,
    };
  }

  /**
   * Rebalance program priorities
   */
  async rebalancePrograms(): Promise<{
    suggestions: Array<{
      issueId: string;
      currentPriority: number;
      suggestedPriority: number;
      reason: string;
    }>;
  }> {
    // Fetch all programs
    const programs = await this.listPrograms();

    const suggestions: Array<{
      issueId: string;
      currentPriority: number;
      suggestedPriority: number;
      reason: string;
    }> = [];

    // Analyze each program
    for (const program of programs) {
      const status = await this.getProgramStatus(program.id);

      // Suggest priority adjustments based on progress and blockers
      let suggestedPriority = program.priority || 1;

      if (status.blockedItems.length > 0) {
        // Increase priority if blocked to unblock faster
        suggestedPriority = Math.max(1, suggestedPriority - 1);
      }

      if (status.progressPercentage > 80) {
        // Decrease priority if nearly done
        suggestedPriority = Math.max(4, suggestedPriority + 1);
      }

      if (suggestedPriority !== program.priority) {
        suggestions.push({
          issueId: program.id,
          currentPriority: program.priority || 1,
          suggestedPriority,
          reason:
            status.blockedItems.length > 0
              ? `${status.blockedItems.length} blocked items`
              : `${status.progressPercentage.toFixed(0)}% complete`,
        });
      }
    }

    return { suggestions };
  }

  /**
   * List all programs
   */
  async listPrograms(): Promise<Program[]> {
    // Query beads for all issues with label "program"
    const issues = await this.storage.query({ labels: ["program"] });

    const programs: Program[] = issues.map((issue: any) => ({
      id: issue.id,
      title: issue.title,
      summary: issue.description || "",
      horizon: "quarter", // TODO: Extract from description
      goals: [], // TODO: Extract from description
      nonGoals: [], // TODO: Extract from description
      metrics: [], // TODO: Extract from description
      constraints: [], // TODO: Extract from description
      projectEpics: [], // TODO: Fetch children
      dependencies: [], // TODO: Fetch dependencies
      status: issue.status || "todo",
      priority: issue.priority || 1,
      createdAt: issue.createdAt || new Date().toISOString(),
      updatedAt: issue.updatedAt || new Date().toISOString(),
    }));

    return programs.sort((a, b) => a.priority - b.priority);
  }

  /**
   * Handle /program-new command
   */
  async handleProgramNew(args: string[]): Promise<void> {
    // For now, just log that the command was received
    // TODO: Implement interactive prompts or arg parsing
    console.log("Creating new program...");
    console.log("Args:", args);
  }

  /**
   * Handle /program-plan command
   */
  async handleProgramPlan(args: string[]): Promise<void> {
    if (args.length === 0) {
      console.log("Usage: /program-plan <program-id> [repo1] [repo2] ...");
      return;
    }

    const programId = args[0];
    const repos = args.slice(1);

    try {
      const result = await this.planProgram({ programId, repos });
      console.log(`Created ${result.createdEpics.length} project epics`);
      console.log("Created epics:", result.createdEpics);
    } catch (error) {
      console.error("Error planning program:", error);
    }
  }

  /**
   * Handle /program-status command
   */
  async handleProgramStatus(args: string[]): Promise<void> {
    try {
      if (args.length > 0) {
        // Get status for specific program
        const programId = args[0];
        const status = await this.getProgramStatus(programId);
        console.log(`Program: ${status.title}`);
        console.log(`Status: ${status.status}`);
        console.log(`Progress: ${status.progressPercentage.toFixed(0)}%`);
        console.log(`Projects: ${status.projectStatuses.done}/${status.projectCount} done`);
      } else {
        // List all programs with status
        const programs = await this.listPrograms();
        console.log(`Found ${programs.length} programs:`);
        for (const program of programs) {
          const status = await this.getProgramStatus(program.id);
          console.log(`  - ${program.title}: ${status.progressPercentage.toFixed(0)}% complete`);
        }
      }
    } catch (error) {
      console.error("Error getting program status:", error);
    }
  }

  /**
   * Handle /program-rebalance command
   */
  async handleProgramRebalance(args: string[]): Promise<void> {
    try {
      const result = await this.rebalancePrograms();
      if (result.suggestions.length === 0) {
        console.log("No priority adjustments suggested");
      } else {
        console.log(`Suggested ${result.suggestions.length} priority adjustments:`);
        for (const suggestion of result.suggestions) {
          console.log(
            `  - ${suggestion.issueId}: ${suggestion.currentPriority} → ${suggestion.suggestedPriority} (${suggestion.reason})`
          );
        }
      }
    } catch (error) {
      console.error("Error rebalancing programs:", error);
    }
  }

  /**
   * Handle /program-list command
   */
  async handleProgramList(args: string[]): Promise<void> {
    try {
      const programs = await this.listPrograms();
      console.log(`Found ${programs.length} programs:`);
      for (const program of programs) {
        console.log(`  - ${program.title} (${program.id})`);
        console.log(`    Status: ${program.status}, Priority: ${program.priority}`);
      }
    } catch (error) {
      console.error("Error listing programs:", error);
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
