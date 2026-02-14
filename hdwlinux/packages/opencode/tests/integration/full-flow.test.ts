/**
 * Full Flow Integration Tests
 *
 * Tests the complete flow from program creation through project planning
 * to work execution using a shared IssueStorage instance.
 */

import { describe, test, expect, beforeEach } from "bun:test";
import { IssueStorage, ConfigManager } from "../../core/src/index.ts";
import { ProgramPlannerOrchestrator } from "../../program-planner/src/orchestrator.ts";
import { ProjectPlannerOrchestrator } from "../../project-planner/src/orchestrator.ts";
import { WorkExecutorOrchestrator } from "../../work-executor/src/orchestrator.ts";

describe("Full Flow Integration", () => {
  let storage: IssueStorage;
  let configManager: ConfigManager;
  let programPlanner: ProgramPlannerOrchestrator;
  let projectPlanner: ProjectPlannerOrchestrator;
  let workExecutor: WorkExecutorOrchestrator;

  beforeEach(() => {
    storage = new IssueStorage();
    configManager = new ConfigManager("/tmp/opencode-integration-test-config");
    programPlanner = new ProgramPlannerOrchestrator(storage, configManager);
    projectPlanner = new ProjectPlannerOrchestrator(storage, configManager);
    workExecutor = new WorkExecutorOrchestrator(storage, configManager);
  });

  test("complete flow: program → project epics → backlog items → work execution", async () => {
    // Step 1: Create a program
    const programResult = await programPlanner.createProgram({
      name: "Platform Modernization",
      summary: "Modernize the platform infrastructure",
      horizon: "quarter",
      goals: ["Improve performance", "Reduce technical debt"],
      nonGoals: ["Complete rewrite"],
      metrics: ["Response time < 100ms", "Test coverage > 80%"],
      constraints: ["No downtime during migration"],
      repos: ["service-a", "service-b"],
    });

    expect(programResult.programId).toBeTruthy();

    // Verify program was created in storage
    const program = await storage.getIssue(programResult.programId);
    expect(program).toBeTruthy();
    expect(program?.title).toBe("Platform Modernization");
    expect(program?.labels).toContain("program");

    // Step 2: Plan the program to create project epics
    const planResult = await programPlanner.planProgram({
      programId: programResult.programId,
      repos: ["service-a", "service-b"],
    });

    expect(planResult.createdEpics.length).toBe(2);
    expect(planResult.dependencies.length).toBe(2);

    // Verify project epics were created
    for (const epicId of planResult.createdEpics) {
      const epic = await storage.getIssue(epicId);
      expect(epic).toBeTruthy();
      expect(epic?.labels).toContain("project");
      expect(epic?.parent).toBe(programResult.programId);
    }

    // Step 3: Plan a project to create backlog items
    const projectId = planResult.createdEpics[0];
    const projectPlanResult = await projectPlanner.planProject({
      projectId,
      programId: programResult.programId,
    });

    expect(projectPlanResult.createdItems.length).toBeGreaterThan(0);

    // Verify backlog items were created
    for (const itemId of projectPlanResult.createdItems) {
      const item = await storage.getIssue(itemId);
      expect(item).toBeTruthy();
      expect(item?.parent).toBe(projectId);
    }

    // Step 4: Get project focus to find ready items
    const focusResult = await projectPlanner.getProjectFocus(projectId);
    // Note: getProjectFocus currently returns empty list (TODO in implementation)
    // but we can verify the structure
    expect(focusResult).toHaveProperty("readyItems");

    // Step 5: Mark a backlog item as ready for work
    const workItemId = projectPlanResult.createdItems[0];
    await storage.updateIssue(workItemId, { status: "todo" });

    // Step 6: Claim work via WorkExecutorOrchestrator
    const claimResult = await workExecutor.claimWork({ project: projectId });

    expect(claimResult.workItemId).toBeTruthy();
    expect(claimResult.title).toBeTruthy();

    // Verify the item was claimed
    const claimedItem = await storage.getIssue(claimResult.workItemId);
    expect(claimedItem?.status).toBe("in_progress");
    expect(claimedItem?.assignee).toBe("agent:work-executor");

    // Step 7: Execute the claimed work
    const executeResult = await workExecutor.executeWork({
      issueIds: [claimResult.workItemId],
      mode: "full",
    });

    expect(executeResult.results.length).toBe(1);
    expect(executeResult.results[0].status).toBe("completed");
  });

  test("program status reflects project epic statuses", async () => {
    // Create a program
    const programResult = await programPlanner.createProgram({
      name: "Test Program",
      summary: "Test program for status aggregation",
      horizon: "quarter",
      goals: ["Test goal"],
      nonGoals: [],
      metrics: [],
      constraints: [],
    });

    // Plan the program with repos
    const planResult = await programPlanner.planProgram({
      programId: programResult.programId,
      repos: ["repo-1", "repo-2", "repo-3"],
    });

    expect(planResult.createdEpics.length).toBe(3);

    // Update some project epic statuses
    await storage.updateIssue(planResult.createdEpics[0], { status: "done" });
    await storage.updateIssue(planResult.createdEpics[1], { status: "in_progress" });
    await storage.updateIssue(planResult.createdEpics[2], { status: "todo" });

    // Get program status
    const status = await programPlanner.getProgramStatus(programResult.programId);

    expect(status.projectCount).toBe(3);
    expect(status.projectStatuses.done).toBe(1);
    expect(status.projectStatuses.inProgress).toBe(1);
    expect(status.projectStatuses.todo).toBe(1);
    expect(status.progressPercentage).toBeCloseTo(33.33, 1);
  });

  test("project status reflects backlog item statuses", async () => {
    // Create a project directly
    const projectResult = await projectPlanner.initProject({
      repoName: "test-repo",
      projectName: "Test Project",
    });

    // Plan the project to create backlog items
    const planResult = await projectPlanner.planProject({
      projectId: projectResult.projectId,
    });

    expect(planResult.createdItems.length).toBe(4); // Default creates 4 items

    // Update some backlog item statuses
    await storage.updateIssue(planResult.createdItems[0], { status: "done" });
    await storage.updateIssue(planResult.createdItems[1], { status: "done" });
    await storage.updateIssue(planResult.createdItems[2], { status: "in_progress" });
    await storage.updateIssue(planResult.createdItems[3], { status: "todo" });

    // Get project status
    const status = await projectPlanner.getProjectStatus(projectResult.projectId);

    expect(status.backlogCount).toBe(4);
    expect(status.backlogStatuses.done).toBe(2);
    expect(status.backlogStatuses.inProgress).toBe(1);
    expect(status.backlogStatuses.todo).toBe(1);
    expect(status.progressPercentage).toBe(50);
  });

  test("work executor respects dependencies when claiming work", async () => {
    // Create a project
    const projectResult = await projectPlanner.initProject({
      repoName: "dep-test-repo",
      projectName: "Dependency Test Project",
    });

    // Create two tasks with a dependency
    const task1 = await storage.createIssue({
      type: "task",
      title: "First task (blocker)",
      parent: projectResult.projectId,
      priority: 1,
    });
    await storage.updateIssue(task1.id, { status: "todo" });

    const task2 = await storage.createIssue({
      type: "task",
      title: "Second task (blocked)",
      parent: projectResult.projectId,
      priority: 1,
    });
    await storage.updateIssue(task2.id, { status: "todo" });

    // Create dependency: task2 depends on task1
    await storage.createDependency(task2.id, task1.id, "blocks");

    // Claim work - should get task1 (not blocked)
    const claimResult = await workExecutor.claimWork({ project: projectResult.projectId });

    expect(claimResult.workItemId).toBe(task1.id);

    // Mark task1 as done
    await storage.updateIssue(task1.id, { status: "done" });

    // Now task2 should be claimable
    const claimResult2 = await workExecutor.claimWork({ project: projectResult.projectId });

    expect(claimResult2.workItemId).toBe(task2.id);
  });

  test("multiple projects under one program share storage correctly", async () => {
    // Create a program
    const programResult = await programPlanner.createProgram({
      name: "Multi-Project Program",
      summary: "Program with multiple projects",
      horizon: "quarter",
      goals: ["Test multi-project"],
      nonGoals: [],
      metrics: [],
      constraints: [],
    });

    // Plan the program with multiple repos
    const planResult = await programPlanner.planProgram({
      programId: programResult.programId,
      repos: ["frontend", "backend", "shared-lib"],
    });

    expect(planResult.createdEpics.length).toBe(3);

    // Plan each project
    for (const projectId of planResult.createdEpics) {
      await projectPlanner.planProject({ projectId });
    }

    // Verify all projects have backlog items
    for (const projectId of planResult.createdEpics) {
      const children = await storage.getChildren(projectId);
      expect(children.length).toBeGreaterThan(0);
    }

    // List all programs and projects
    const programs = await programPlanner.listPrograms();
    expect(programs.length).toBe(1);

    const projects = await projectPlanner.listProjects();
    expect(projects.length).toBe(3);
  });
});
