/**
 * Discovered Work Integration Tests
 *
 * Tests that work execution can create discovered work issues and that
 * they are properly linked to their parent via dependencies.
 */

import { describe, test, expect, beforeEach } from "bun:test";
import { IssueStorage, ConfigManager } from "../../core/src/index.ts";
import { ProgramPlannerOrchestrator } from "../../program-planner/src/orchestrator.ts";
import { ProjectPlannerOrchestrator } from "../../project-planner/src/orchestrator.ts";
import { WorkExecutorOrchestrator } from "../../work-executor/src/orchestrator.ts";

describe("Discovered Work Integration", () => {
  let storage: IssueStorage;
  let configManager: ConfigManager;
  let programPlanner: ProgramPlannerOrchestrator;
  let projectPlanner: ProjectPlannerOrchestrator;
  let workExecutor: WorkExecutorOrchestrator;

  beforeEach(() => {
    storage = new IssueStorage();
    configManager = new ConfigManager("/tmp/opencode-discovered-test-config");
    programPlanner = new ProgramPlannerOrchestrator(storage, configManager);
    projectPlanner = new ProjectPlannerOrchestrator(storage, configManager);
    workExecutor = new WorkExecutorOrchestrator(storage, configManager);
  });

  test("discovered work can be created and linked to parent task", async () => {
    // Setup: Create project with a task
    const projectResult = await projectPlanner.initProject({
      repoName: "discovered-work-repo",
      projectName: "Discovered Work Project",
    });

    const parentTask = await storage.createIssue({
      type: "task",
      title: "Parent implementation task",
      parent: projectResult.projectId,
      priority: 1,
      labels: ["implementation"],
    });
    await storage.updateIssue(parentTask.id, { status: "in_progress" });

    // Simulate discovering work during execution
    const discoveredBug = await storage.createIssue({
      type: "bug",
      title: "Race condition discovered during implementation",
      parent: projectResult.projectId,
      priority: 2,
      labels: [`discovered-from:${parentTask.id}`],
    });

    // Create dependency: discovered work was found from parent
    await storage.createDependency(discoveredBug.id, parentTask.id, "discovered-from");

    // Verify the discovered work exists
    const bug = await storage.getIssue(discoveredBug.id);
    expect(bug).toBeTruthy();
    expect(bug?.type).toBe("bug");
    expect(bug?.labels).toContain(`discovered-from:${parentTask.id}`);

    // Verify dependency was created
    const deps = await storage.getDependencies(discoveredBug.id);
    expect(deps).toContain(parentTask.id);
  });

  test("discovered work appears in project backlog", async () => {
    // Setup: Create project
    const projectResult = await projectPlanner.initProject({
      repoName: "backlog-discovered-repo",
      projectName: "Backlog Discovered Project",
    });

    // Create original task
    const originalTask = await storage.createIssue({
      type: "task",
      title: "Original task",
      parent: projectResult.projectId,
      priority: 1,
    });
    await storage.updateIssue(originalTask.id, { status: "todo" });

    // Create discovered work
    const discoveredChore = await storage.createIssue({
      type: "chore",
      title: "Technical debt discovered",
      parent: projectResult.projectId,
      priority: 3,
      labels: [`discovered-from:${originalTask.id}`],
    });
    await storage.updateIssue(discoveredChore.id, { status: "todo" });

    // Get project children (backlog)
    const children = await storage.getChildren(projectResult.projectId);

    expect(children.length).toBe(2);
    expect(children.map((c) => c.id)).toContain(originalTask.id);
    expect(children.map((c) => c.id)).toContain(discoveredChore.id);

    // Verify project status includes discovered work
    const status = await projectPlanner.getProjectStatus(projectResult.projectId);
    expect(status.backlogCount).toBe(2);
  });

  test("discovered work with dependencies blocks correctly", async () => {
    // Setup: Create project
    const projectResult = await projectPlanner.initProject({
      repoName: "blocking-discovered-repo",
      projectName: "Blocking Discovered Project",
    });

    // Create original task
    const originalTask = await storage.createIssue({
      type: "task",
      title: "Original task",
      parent: projectResult.projectId,
      priority: 1,
    });
    await storage.updateIssue(originalTask.id, { status: "todo" });

    // Create discovered work that blocks original task completion
    const blockingDiscovery = await storage.createIssue({
      type: "bug",
      title: "Critical bug that must be fixed first",
      parent: projectResult.projectId,
      priority: 1,
      labels: [`discovered-from:${originalTask.id}`, "blocker"],
    });
    await storage.updateIssue(blockingDiscovery.id, { status: "todo" });

    // Create dependency: original task now depends on discovered bug
    await storage.createDependency(originalTask.id, blockingDiscovery.id, "blocks");

    // Try to claim work - should get the blocking discovery first
    const claim = await workExecutor.claimWork({ project: projectResult.projectId });

    // The blocking discovery should be claimable (no deps)
    // The original task should be blocked
    expect(claim.workItemId).toBe(blockingDiscovery.id);

    // Verify original task is blocked
    const analysis = await storage.analyzeDependencies(originalTask.id);
    expect(analysis.blockers).toContain(blockingDiscovery.id);
  });

  test("multiple discovered work items from single parent", async () => {
    // Setup: Create project
    const projectResult = await projectPlanner.initProject({
      repoName: "multi-discovered-repo",
      projectName: "Multi Discovered Project",
    });

    // Create parent task
    const parentTask = await storage.createIssue({
      type: "feature",
      title: "Complex feature implementation",
      parent: projectResult.projectId,
      priority: 1,
    });
    await storage.updateIssue(parentTask.id, { status: "in_progress" });

    // Create multiple discovered work items
    const discoveries = [];
    for (let i = 1; i <= 3; i++) {
      const discovery = await storage.createIssue({
        type: i === 1 ? "bug" : "chore",
        title: `Discovered item ${i}`,
        parent: projectResult.projectId,
        priority: i + 1,
        labels: [`discovered-from:${parentTask.id}`],
      });
      await storage.updateIssue(discovery.id, { status: "todo" });
      discoveries.push(discovery);
    }

    // Verify all discoveries are in the backlog
    const children = await storage.getChildren(projectResult.projectId);
    expect(children.length).toBe(4); // parent + 3 discoveries

    // Query by discovered-from label
    const discoveredItems = await storage.query({
      labels: [`discovered-from:${parentTask.id}`],
    });
    expect(discoveredItems.length).toBe(3);
  });

  test("discovered work inherits project context", async () => {
    // Create program and project
    const programResult = await programPlanner.createProgram({
      name: "Discovery Context Program",
      summary: "Testing discovered work context",
      horizon: "quarter",
      goals: ["Test context"],
      nonGoals: [],
      metrics: [],
      constraints: [],
    });

    const programPlan = await programPlanner.planProgram({
      programId: programResult.programId,
      repos: ["context-repo"],
    });

    const projectId = programPlan.createdEpics[0];

    // Create task in project
    const task = await storage.createIssue({
      type: "task",
      title: "Task with context",
      parent: projectId,
      priority: 1,
      labels: ["implementation", "kafka"],
    });
    await storage.updateIssue(task.id, { status: "in_progress" });

    // Create discovered work with inherited context
    const discovery = await storage.createIssue({
      type: "bug",
      title: "Kafka consumer bug",
      parent: projectId,
      priority: 2,
      labels: [`discovered-from:${task.id}`, "kafka", "bug"],
    });
    await storage.updateIssue(discovery.id, { status: "todo" });

    // Verify discovery is part of the same project
    const discoveryIssue = await storage.getIssue(discovery.id);
    expect(discoveryIssue?.parent).toBe(projectId);

    // Verify project status includes discovery
    const projectStatus = await projectPlanner.getProjectStatus(projectId);
    expect(projectStatus.backlogCount).toBe(2);
  });

  test("discovered work can be queried by label patterns", async () => {
    // Setup: Create project with multiple tasks and discoveries
    const projectResult = await projectPlanner.initProject({
      repoName: "query-discovered-repo",
      projectName: "Query Discovered Project",
    });

    // Create tasks
    const task1 = await storage.createIssue({
      type: "task",
      title: "Task 1",
      parent: projectResult.projectId,
      priority: 1,
    });

    const task2 = await storage.createIssue({
      type: "task",
      title: "Task 2",
      parent: projectResult.projectId,
      priority: 1,
    });

    // Create discoveries from different tasks
    await storage.createIssue({
      type: "bug",
      title: "Bug from task 1",
      parent: projectResult.projectId,
      priority: 2,
      labels: [`discovered-from:${task1.id}`],
    });

    await storage.createIssue({
      type: "chore",
      title: "Chore from task 1",
      parent: projectResult.projectId,
      priority: 3,
      labels: [`discovered-from:${task1.id}`],
    });

    await storage.createIssue({
      type: "bug",
      title: "Bug from task 2",
      parent: projectResult.projectId,
      priority: 2,
      labels: [`discovered-from:${task2.id}`],
    });

    // Query discoveries from task 1
    const task1Discoveries = await storage.query({
      labels: [`discovered-from:${task1.id}`],
    });
    expect(task1Discoveries.length).toBe(2);

    // Query discoveries from task 2
    const task2Discoveries = await storage.query({
      labels: [`discovered-from:${task2.id}`],
    });
    expect(task2Discoveries.length).toBe(1);
  });

  test("completing discovered work updates project progress", async () => {
    // Setup: Create project
    const projectResult = await projectPlanner.initProject({
      repoName: "progress-discovered-repo",
      projectName: "Progress Discovered Project",
    });

    // Create original task
    const originalTask = await storage.createIssue({
      type: "task",
      title: "Original task",
      parent: projectResult.projectId,
      priority: 1,
    });
    await storage.updateIssue(originalTask.id, { status: "todo" });

    // Initial status
    let status = await projectPlanner.getProjectStatus(projectResult.projectId);
    expect(status.backlogCount).toBe(1);
    expect(status.progressPercentage).toBe(0);

    // Create discovered work
    const discovery = await storage.createIssue({
      type: "bug",
      title: "Discovered bug",
      parent: projectResult.projectId,
      priority: 2,
    });
    await storage.updateIssue(discovery.id, { status: "todo" });

    // Status now includes discovery
    status = await projectPlanner.getProjectStatus(projectResult.projectId);
    expect(status.backlogCount).toBe(2);
    expect(status.progressPercentage).toBe(0);

    // Complete discovery
    await storage.updateIssue(discovery.id, { status: "done" });

    status = await projectPlanner.getProjectStatus(projectResult.projectId);
    expect(status.backlogStatuses.done).toBe(1);
    expect(status.progressPercentage).toBe(50);

    // Complete original task
    await storage.updateIssue(originalTask.id, { status: "done" });

    status = await projectPlanner.getProjectStatus(projectResult.projectId);
    expect(status.backlogStatuses.done).toBe(2);
    expect(status.progressPercentage).toBe(100);
  });
});
