/**
 * Cross-Plugin Status Integration Tests
 *
 * Tests status aggregation across plugins and verifies that status
 * updates propagate correctly through the hierarchy.
 */

import { describe, test, expect, beforeEach } from "bun:test";
import { IssueStorage, ConfigManager } from "../../core/src/index.ts";
import { ProgramPlannerOrchestrator } from "../../program-planner/src/orchestrator.ts";
import { ProjectPlannerOrchestrator } from "../../project-planner/src/orchestrator.ts";
import { WorkExecutorOrchestrator } from "../../work-executor/src/orchestrator.ts";

describe("Cross-Plugin Status Aggregation", () => {
  let storage: IssueStorage;
  let configManager: ConfigManager;
  let programPlanner: ProgramPlannerOrchestrator;
  let projectPlanner: ProjectPlannerOrchestrator;
  let workExecutor: WorkExecutorOrchestrator;

  beforeEach(() => {
    storage = new IssueStorage();
    configManager = new ConfigManager("/tmp/opencode-status-test-config");
    programPlanner = new ProgramPlannerOrchestrator(storage, configManager);
    projectPlanner = new ProjectPlannerOrchestrator(storage, configManager);
    workExecutor = new WorkExecutorOrchestrator(storage, configManager);
  });

  test("completing work items updates project status", async () => {
    // Setup: Create project with backlog items
    const projectResult = await projectPlanner.initProject({
      repoName: "status-test-repo",
      projectName: "Status Test Project",
    });

    const planResult = await projectPlanner.planProject({
      projectId: projectResult.projectId,
    });

    // Initial status should show all items as todo
    let status = await projectPlanner.getProjectStatus(projectResult.projectId);
    expect(status.backlogCount).toBe(4);
    expect(status.progressPercentage).toBe(0);

    // Mark items as todo first (they start without status)
    for (const itemId of planResult.createdItems) {
      await storage.updateIssue(itemId, { status: "todo" });
    }

    // Claim and execute first work item
    const claim1 = await workExecutor.claimWork({ project: projectResult.projectId });
    expect(claim1.workItemId).toBeTruthy();

    // Simulate work completion by marking as done
    await storage.updateIssue(claim1.workItemId, { status: "done" });

    // Check status after first completion
    status = await projectPlanner.getProjectStatus(projectResult.projectId);
    expect(status.backlogStatuses.done).toBe(1);
    expect(status.progressPercentage).toBe(25);

    // Complete another item
    const claim2 = await workExecutor.claimWork({ project: projectResult.projectId });
    await storage.updateIssue(claim2.workItemId, { status: "done" });

    status = await projectPlanner.getProjectStatus(projectResult.projectId);
    expect(status.backlogStatuses.done).toBe(2);
    expect(status.progressPercentage).toBe(50);

    // Complete all remaining items
    const claim3 = await workExecutor.claimWork({ project: projectResult.projectId });
    await storage.updateIssue(claim3.workItemId, { status: "done" });

    const claim4 = await workExecutor.claimWork({ project: projectResult.projectId });
    await storage.updateIssue(claim4.workItemId, { status: "done" });

    status = await projectPlanner.getProjectStatus(projectResult.projectId);
    expect(status.backlogStatuses.done).toBe(4);
    expect(status.progressPercentage).toBe(100);
  });

  test("completing projects updates program status", async () => {
    // Setup: Create program with project epics
    const programResult = await programPlanner.createProgram({
      name: "Program Status Test",
      summary: "Testing program status aggregation",
      horizon: "quarter",
      goals: ["Test status"],
      nonGoals: [],
      metrics: [],
      constraints: [],
    });

    const planResult = await programPlanner.planProgram({
      programId: programResult.programId,
      repos: ["project-a", "project-b", "project-c", "project-d"],
    });

    expect(planResult.createdEpics.length).toBe(4);

    // Initial status
    let status = await programPlanner.getProgramStatus(programResult.programId);
    expect(status.projectCount).toBe(4);
    expect(status.progressPercentage).toBe(0);

    // Complete first project
    await storage.updateIssue(planResult.createdEpics[0], { status: "done" });

    status = await programPlanner.getProgramStatus(programResult.programId);
    expect(status.projectStatuses.done).toBe(1);
    expect(status.progressPercentage).toBe(25);

    // Set second project to in_progress
    await storage.updateIssue(planResult.createdEpics[1], { status: "in_progress" });

    status = await programPlanner.getProgramStatus(programResult.programId);
    expect(status.projectStatuses.done).toBe(1);
    expect(status.projectStatuses.inProgress).toBe(1);
    expect(status.progressPercentage).toBe(25);

    // Complete all projects
    await storage.updateIssue(planResult.createdEpics[1], { status: "done" });
    await storage.updateIssue(planResult.createdEpics[2], { status: "done" });
    await storage.updateIssue(planResult.createdEpics[3], { status: "done" });

    status = await programPlanner.getProgramStatus(programResult.programId);
    expect(status.projectStatuses.done).toBe(4);
    expect(status.progressPercentage).toBe(100);
  });

  test("blocked items are tracked correctly", async () => {
    // Create project
    const projectResult = await projectPlanner.initProject({
      repoName: "blocked-test-repo",
      projectName: "Blocked Test Project",
    });

    // Create tasks manually to control dependencies
    const blocker = await storage.createIssue({
      type: "task",
      title: "Blocker task",
      parent: projectResult.projectId,
      priority: 1,
    });
    await storage.updateIssue(blocker.id, { status: "todo" });

    const blocked = await storage.createIssue({
      type: "task",
      title: "Blocked task",
      parent: projectResult.projectId,
      priority: 1,
    });
    await storage.updateIssue(blocked.id, { status: "blocked" });

    const inProgress = await storage.createIssue({
      type: "task",
      title: "In progress task",
      parent: projectResult.projectId,
      priority: 1,
    });
    await storage.updateIssue(inProgress.id, { status: "in_progress" });

    // Check status
    const status = await projectPlanner.getProjectStatus(projectResult.projectId);
    expect(status.backlogStatuses.todo).toBe(1);
    expect(status.backlogStatuses.blocked).toBe(1);
    expect(status.backlogStatuses.inProgress).toBe(1);
    expect(status.backlogStatuses.done).toBe(0);
  });

  test("status aggregation works across full hierarchy", async () => {
    // Create full hierarchy: program → projects → backlog items
    const programResult = await programPlanner.createProgram({
      name: "Full Hierarchy Test",
      summary: "Testing full hierarchy status",
      horizon: "quarter",
      goals: ["Test hierarchy"],
      nonGoals: [],
      metrics: [],
      constraints: [],
    });

    const programPlan = await programPlanner.planProgram({
      programId: programResult.programId,
      repos: ["service-1", "service-2"],
    });

    // Plan each project
    const projectBacklogs: Map<string, string[]> = new Map();
    for (const projectId of programPlan.createdEpics) {
      const projectPlan = await projectPlanner.planProject({ projectId });
      projectBacklogs.set(projectId, projectPlan.createdItems);

      // Mark all items as todo
      for (const itemId of projectPlan.createdItems) {
        await storage.updateIssue(itemId, { status: "todo" });
      }
    }

    // Initial program status
    let programStatus = await programPlanner.getProgramStatus(programResult.programId);
    expect(programStatus.projectCount).toBe(2);
    expect(programStatus.progressPercentage).toBe(0);

    // Complete all items in first project
    const project1Id = programPlan.createdEpics[0];
    const project1Items = projectBacklogs.get(project1Id)!;
    for (const itemId of project1Items) {
      await storage.updateIssue(itemId, { status: "done" });
    }

    // Mark first project as done
    await storage.updateIssue(project1Id, { status: "done" });

    // Check project status
    const project1Status = await projectPlanner.getProjectStatus(project1Id);
    expect(project1Status.progressPercentage).toBe(100);

    // Check program status
    programStatus = await programPlanner.getProgramStatus(programResult.programId);
    expect(programStatus.projectStatuses.done).toBe(1);
    expect(programStatus.progressPercentage).toBe(50);

    // Complete second project
    const project2Id = programPlan.createdEpics[1];
    const project2Items = projectBacklogs.get(project2Id)!;
    for (const itemId of project2Items) {
      await storage.updateIssue(itemId, { status: "done" });
    }
    await storage.updateIssue(project2Id, { status: "done" });

    // Final program status
    programStatus = await programPlanner.getProgramStatus(programResult.programId);
    expect(programStatus.projectStatuses.done).toBe(2);
    expect(programStatus.progressPercentage).toBe(100);
  });

  test("work executor filters by project correctly", async () => {
    // Create two projects
    const project1 = await projectPlanner.initProject({
      repoName: "filter-repo-1",
      projectName: "Filter Project 1",
    });

    const project2 = await projectPlanner.initProject({
      repoName: "filter-repo-2",
      projectName: "Filter Project 2",
    });

    // Create tasks in each project
    const task1 = await storage.createIssue({
      type: "task",
      title: "Task in Project 1",
      parent: project1.projectId,
      priority: 1,
    });
    await storage.updateIssue(task1.id, { status: "todo" });

    const task2 = await storage.createIssue({
      type: "task",
      title: "Task in Project 2",
      parent: project2.projectId,
      priority: 1,
    });
    await storage.updateIssue(task2.id, { status: "todo" });

    // Claim work for project 1 only
    const claim1 = await workExecutor.claimWork({ project: project1.projectId });
    expect(claim1.workItemId).toBe(task1.id);

    // Claim work for project 2 only
    const claim2 = await workExecutor.claimWork({ project: project2.projectId });
    expect(claim2.workItemId).toBe(task2.id);
  });

  test("priority ordering is respected when claiming work", async () => {
    const projectResult = await projectPlanner.initProject({
      repoName: "priority-test-repo",
      projectName: "Priority Test Project",
    });

    // Create tasks with different priorities
    const lowPriority = await storage.createIssue({
      type: "task",
      title: "Low priority task",
      parent: projectResult.projectId,
      priority: 3,
    });
    await storage.updateIssue(lowPriority.id, { status: "todo" });

    const highPriority = await storage.createIssue({
      type: "task",
      title: "High priority task",
      parent: projectResult.projectId,
      priority: 1,
    });
    await storage.updateIssue(highPriority.id, { status: "todo" });

    const mediumPriority = await storage.createIssue({
      type: "task",
      title: "Medium priority task",
      parent: projectResult.projectId,
      priority: 2,
    });
    await storage.updateIssue(mediumPriority.id, { status: "todo" });

    // Should claim high priority first
    const claim1 = await workExecutor.claimWork({ project: projectResult.projectId });
    expect(claim1.workItemId).toBe(highPriority.id);

    // Mark as done and claim next
    await storage.updateIssue(highPriority.id, { status: "done" });
    const claim2 = await workExecutor.claimWork({ project: projectResult.projectId });
    expect(claim2.workItemId).toBe(mediumPriority.id);

    // Mark as done and claim next
    await storage.updateIssue(mediumPriority.id, { status: "done" });
    const claim3 = await workExecutor.claimWork({ project: projectResult.projectId });
    expect(claim3.workItemId).toBe(lowPriority.id);
  });
});
