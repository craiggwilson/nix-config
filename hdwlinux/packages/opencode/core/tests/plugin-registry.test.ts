/**
 * Tests for PluginRegistry
 *
 * Verifies shared storage, delegate wiring, singleton behavior,
 * and end-to-end cross-plugin delegation through the registry.
 */

import { describe, test, expect, beforeEach } from "bun:test";
import {
  createRegistry,
  getRegistry,
  resetRegistry,
} from "../src/plugin-registry.js";
import { SubagentDispatcher } from "../src/orchestration/subagent-dispatcher.js";

beforeEach(() => {
  resetRegistry();
});

describe("createRegistry", () => {
  test("returns all expected fields", () => {
    const reg = createRegistry({ configDir: "/tmp/opencode-reg-test" });

    expect(reg.storage).toBeDefined();
    expect(reg.configManager).toBeDefined();
    expect(reg.dispatcher).toBeDefined();
    expect(reg.programPlanner).toBeDefined();
    expect(reg.projectPlanner).toBeDefined();
    expect(reg.workExecutor).toBeDefined();
  });

  test("all orchestrators share the same storage instance", async () => {
    const reg = createRegistry({ configDir: "/tmp/opencode-reg-test" });

    // Create an issue via programPlanner, read it via workExecutor's storage
    const program = await reg.programPlanner.createProgram({
      name: "Shared Storage Test",
      summary: "Verify shared storage",
      horizon: "quarter",
      goals: ["test"],
      nonGoals: [],
      metrics: [],
      constraints: [],
    });

    // The issue should be visible through the shared storage
    const issue = await reg.storage.getIssue(program.programId);
    expect(issue).toBeTruthy();
    expect(issue?.title).toBe("Shared Storage Test");

    // Project planner should also see it (same storage)
    const programs = await reg.storage.query({ labels: ["program"] });
    expect(programs.length).toBe(1);
  });

  test("accepts a custom dispatcher", () => {
    const customDispatcher = new SubagentDispatcher();
    const reg = createRegistry({
      configDir: "/tmp/opencode-reg-test",
      dispatcher: customDispatcher,
    });

    expect(reg.dispatcher).toBe(customDispatcher);
  });

  test("creates independent registries on each call", () => {
    const reg1 = createRegistry({ configDir: "/tmp/opencode-reg-test-1" });
    const reg2 = createRegistry({ configDir: "/tmp/opencode-reg-test-2" });

    expect(reg1.storage).not.toBe(reg2.storage);
    expect(reg1.programPlanner).not.toBe(reg2.programPlanner);
  });
});

describe("getRegistry / resetRegistry (singleton)", () => {
  test("returns the same instance on repeated calls", () => {
    const a = getRegistry({ configDir: "/tmp/opencode-reg-test" });
    const b = getRegistry();

    expect(a).toBe(b);
    expect(a.storage).toBe(b.storage);
  });

  test("resetRegistry causes a fresh instance", () => {
    const a = getRegistry({ configDir: "/tmp/opencode-reg-test" });
    resetRegistry();
    const b = getRegistry({ configDir: "/tmp/opencode-reg-test" });

    expect(a).not.toBe(b);
    expect(a.storage).not.toBe(b.storage);
  });
});

describe("delegate wiring", () => {
  test("program planner delegates to project planner on planProgram", async () => {
    const reg = createRegistry({ configDir: "/tmp/opencode-reg-test" });

    // Create a program
    const { programId } = await reg.programPlanner.createProgram({
      name: "Delegation Test",
      summary: "Test delegate wiring",
      horizon: "quarter",
      goals: ["verify delegation"],
      nonGoals: [],
      metrics: [],
      constraints: [],
    });

    // Plan the program with repos — this should trigger the
    // ProjectPlannerDelegate, which calls projectPlanner.planProject()
    const result = await reg.programPlanner.planProgram({
      programId,
      repos: ["svc-alpha"],
    });

    expect(result.createdEpics.length).toBe(1);

    const epicId = result.createdEpics[0];

    // The delegate should have created backlog items under the epic
    const children = await reg.storage.getChildren(epicId);
    expect(children.length).toBeGreaterThan(0);

    // Dependencies should include both program→epic AND epic→backlog
    // (the delegate adds its own dependencies)
    expect(result.dependencies.length).toBeGreaterThan(1);
  });

  test("project planner delegates to work executor on executeSprint", async () => {
    const reg = createRegistry({ configDir: "/tmp/opencode-reg-test" });

    // Set up a project with ready tasks
    const { projectId } = await reg.projectPlanner.initProject({
      repoName: "exec-test-repo",
      projectName: "Exec Test",
    });

    // Create a ready task under the project
    const task = await reg.storage.createIssue({
      type: "task",
      title: "Ready task",
      labels: ["implementation"],
      priority: 1,
      parent: projectId,
    });
    await reg.storage.updateIssue(task.id, { status: "todo" });

    // executeSprint should delegate to work executor
    const result = await reg.projectPlanner.executeSprint({
      projectId,
    });

    expect(result.executedCount).toBeGreaterThan(0);
    expect(result.results.length).toBeGreaterThan(0);
    expect(result.results[0].status).toBe("completed");
  });

  test("full chain: program → project → work via delegates", async () => {
    const reg = createRegistry({ configDir: "/tmp/opencode-reg-test" });

    // 1. Create program
    const { programId } = await reg.programPlanner.createProgram({
      name: "Full Chain",
      summary: "End-to-end delegation",
      horizon: "quarter",
      goals: ["chain test"],
      nonGoals: [],
      metrics: [],
      constraints: [],
    });

    // 2. Plan program → creates project epics → delegate creates backlog items
    const planResult = await reg.programPlanner.planProgram({
      programId,
      repos: ["chain-repo"],
    });

    expect(planResult.createdEpics.length).toBe(1);
    const epicId = planResult.createdEpics[0];

    // 3. Backlog items should exist (created by delegate)
    const backlogItems = await reg.storage.getChildren(epicId);
    expect(backlogItems.length).toBeGreaterThan(0);

    // 4. Execute sprint on the project → delegates to work executor
    const sprintResult = await reg.projectPlanner.executeSprint({
      projectId: epicId,
    });

    expect(sprintResult.executedCount).toBeGreaterThan(0);

    // 5. Verify program status reflects the work
    const status = await reg.programPlanner.getProgramStatus(programId);
    expect(status.projectCount).toBe(1);
  });
});

describe("storage isolation between registries", () => {
  test("separate registries do not share data", async () => {
    const reg1 = createRegistry({ configDir: "/tmp/opencode-reg-test-1" });
    const reg2 = createRegistry({ configDir: "/tmp/opencode-reg-test-2" });

    await reg1.programPlanner.createProgram({
      name: "Registry 1 Program",
      summary: "Only in reg1",
      horizon: "quarter",
      goals: [],
      nonGoals: [],
      metrics: [],
      constraints: [],
    });

    const reg1Programs = await reg1.storage.query({ labels: ["program"] });
    const reg2Programs = await reg2.storage.query({ labels: ["program"] });

    expect(reg1Programs.length).toBe(1);
    expect(reg2Programs.length).toBe(0);
  });
});
