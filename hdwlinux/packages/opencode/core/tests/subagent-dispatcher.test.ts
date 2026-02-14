/**
 * Tests for SubagentDispatcher
 */

import { test, expect } from "bun:test";
import { SubagentDispatcher } from "../src/orchestration/subagent-dispatcher.js";
import type { SubagentTask, SubagentResult } from "../src/orchestration/subagent-dispatcher.js";
import type { IssueRecord } from "../src/beads.js";

test("selectAgents returns kafka-expert for kafka label", () => {
  const dispatcher = new SubagentDispatcher();

  const issue: IssueRecord = {
    id: "TASK-001",
    type: "task",
    title: "Implement Kafka consumer",
    labels: ["kafka", "implementation"],
  };

  const agents = dispatcher.selectAgents(issue);

  expect(agents).toContain("kafka-expert");
});

test("selectAgents returns security-architect for security label", () => {
  const dispatcher = new SubagentDispatcher();

  const issue: IssueRecord = {
    id: "TASK-002",
    type: "task",
    title: "Security audit",
    labels: ["security"],
  };

  const agents = dispatcher.selectAgents(issue);

  expect(agents).toContain("security-architect");
  expect(agents).toContain("security-reviewer-agent");
});

test("selectAgents returns multiple agents for multiple labels", () => {
  const dispatcher = new SubagentDispatcher();

  const issue: IssueRecord = {
    id: "TASK-003",
    type: "task",
    title: "Distributed Kafka service",
    labels: ["kafka", "distributed-systems", "go"],
  };

  const agents = dispatcher.selectAgents(issue);

  expect(agents).toContain("kafka-expert");
  expect(agents).toContain("distributed-systems-architect");
  expect(agents).toContain("go-expert");
});

test("selectAgents returns default agents for unknown labels", () => {
  const dispatcher = new SubagentDispatcher();

  const issue: IssueRecord = {
    id: "TASK-004",
    type: "task",
    title: "Unknown task",
    labels: ["unknown-label"],
  };

  const agents = dispatcher.selectAgents(issue);

  // Default work type is "implementation" which adds code-reviewer-agent
  expect(agents).toContain("code-reviewer-agent");
  expect(agents.length).toBeGreaterThan(0);
});

test("selectAgents returns code-reviewer-agent for review label", () => {
  const dispatcher = new SubagentDispatcher();

  const issue: IssueRecord = {
    id: "TASK-005",
    type: "task",
    title: "Code review task",
    labels: ["review"],
  };

  const agents = dispatcher.selectAgents(issue);

  expect(agents).toContain("code-reviewer-agent");
});

test("selectAgents handles issue type for research", () => {
  const dispatcher = new SubagentDispatcher();

  const issue: IssueRecord = {
    id: "TASK-006",
    type: "task",
    title: "Research task",
    labels: ["research"],
  };

  const agents = dispatcher.selectAgents(issue);

  expect(agents).toContain("codebase-analyst");
  expect(agents).toContain("explore");
});

test("dispatchParallel returns results from all agents", async () => {
  const executionResults: string[] = [];

  const dispatcher = new SubagentDispatcher({
    executionHandler: async (agentName: string, task: SubagentTask): Promise<SubagentResult> => {
      executionResults.push(agentName);
      return {
        agentName,
        status: "success",
        output: { executed: true },
      };
    },
  });

  const task: SubagentTask = {
    issueId: "TASK-001",
    taskType: "implement",
    context: {
      title: "Test task",
      labels: ["kafka"],
    },
  };

  const agents = ["kafka-expert", "go-expert", "codebase-analyst"];
  const results = await dispatcher.dispatchParallel(agents, task);

  expect(results.length).toBe(3);
  expect(executionResults).toContain("kafka-expert");
  expect(executionResults).toContain("go-expert");
  expect(executionResults).toContain("codebase-analyst");

  for (const result of results) {
    expect(result.status).toBe("success");
  }
});

test("dispatchSequential returns results in order", async () => {
  const executionOrder: string[] = [];

  const dispatcher = new SubagentDispatcher({
    executionHandler: async (agentName: string, task: SubagentTask): Promise<SubagentResult> => {
      executionOrder.push(agentName);
      return {
        agentName,
        status: "success",
        output: { order: executionOrder.length },
      };
    },
  });

  const task: SubagentTask = {
    issueId: "TASK-002",
    taskType: "review",
    context: {
      title: "Review task",
    },
  };

  const agents = ["codebase-analyst", "code-reviewer-agent", "security-reviewer-agent"];
  const results = await dispatcher.dispatchSequential(agents, task);

  expect(results.length).toBe(3);
  expect(executionOrder).toEqual(["codebase-analyst", "code-reviewer-agent", "security-reviewer-agent"]);

  expect((results[0].output as any).order).toBe(1);
  expect((results[1].output as any).order).toBe(2);
  expect((results[2].output as any).order).toBe(3);
});

test("dispatchSequential stops on failure", async () => {
  const executionOrder: string[] = [];

  const dispatcher = new SubagentDispatcher({
    executionHandler: async (agentName: string, task: SubagentTask): Promise<SubagentResult> => {
      executionOrder.push(agentName);
      if (agentName === "code-reviewer-agent") {
        return {
          agentName,
          status: "failed",
          error: "Review failed",
        };
      }
      return {
        agentName,
        status: "success",
      };
    },
  });

  const task: SubagentTask = {
    issueId: "TASK-003",
    taskType: "review",
    context: {
      title: "Failing review task",
    },
  };

  const agents = ["codebase-analyst", "code-reviewer-agent", "security-reviewer-agent"];
  const results = await dispatcher.dispatchSequential(agents, task);

  expect(results.length).toBe(2);
  expect(executionOrder).toEqual(["codebase-analyst", "code-reviewer-agent"]);
  expect(results[1].status).toBe("failed");
});

test("dispatchParallel handles empty agent list", async () => {
  const dispatcher = new SubagentDispatcher();

  const task: SubagentTask = {
    issueId: "TASK-004",
    taskType: "analyze",
    context: {
      title: "Empty agent list",
    },
  };

  const results = await dispatcher.dispatchParallel([], task);

  expect(results.length).toBe(0);
});

test("validateAgents identifies valid and invalid agents", () => {
  const dispatcher = new SubagentDispatcher();

  const agents = ["kafka-expert", "invalid-agent", "go-expert", "nonexistent"];
  const { valid, invalid } = dispatcher.validateAgents(agents);

  expect(valid).toContain("kafka-expert");
  expect(valid).toContain("go-expert");
  expect(invalid).toContain("invalid-agent");
  expect(invalid).toContain("nonexistent");
});

test("selectAgentsByCategory returns correct agents", () => {
  const dispatcher = new SubagentDispatcher();

  const securityAgents = dispatcher.selectAgentsByCategory("security");
  expect(securityAgents).toContain("security-architect");

  const reviewAgents = dispatcher.selectAgentsByCategory("review");
  expect(reviewAgents).toContain("code-reviewer-agent");
  expect(reviewAgents).toContain("security-reviewer-agent");
});

test("selectAgentsByCapability returns correct agents", () => {
  const dispatcher = new SubagentDispatcher();

  const codeReviewAgents = dispatcher.selectAgentsByCapability("code-review");
  expect(codeReviewAgents).toContain("go-expert");
  expect(codeReviewAgents).toContain("code-reviewer-agent");

  const threatModelingAgents = dispatcher.selectAgentsByCapability("threat-modeling");
  expect(threatModelingAgents).toContain("security-architect");
});

test("getAvailableAgents returns all agent names", () => {
  const dispatcher = new SubagentDispatcher();

  const agents = dispatcher.getAvailableAgents();

  expect(agents).toContain("kafka-expert");
  expect(agents).toContain("go-expert");
  expect(agents).toContain("security-architect");
  expect(agents).toContain("codebase-analyst");
  expect(agents.length).toBeGreaterThan(10);
});

test("dispatchParallel includes duration in results", async () => {
  const dispatcher = new SubagentDispatcher({
    executionHandler: async (agentName: string, task: SubagentTask): Promise<SubagentResult> => {
      await new Promise((resolve) => setTimeout(resolve, 10));
      return {
        agentName,
        status: "success",
      };
    },
  });

  const task: SubagentTask = {
    issueId: "TASK-005",
    taskType: "analyze",
    context: {
      title: "Duration test",
    },
  };

  const results = await dispatcher.dispatchParallel(["kafka-expert"], task);

  expect(results[0].durationMs).toBeDefined();
  expect(results[0].durationMs).toBeGreaterThanOrEqual(10);
});

test("selectAgents handles nix and nixos labels", () => {
  const dispatcher = new SubagentDispatcher();

  const nixIssue: IssueRecord = {
    id: "TASK-007",
    type: "task",
    title: "Nix configuration",
    labels: ["nix"],
  };

  const nixosIssue: IssueRecord = {
    id: "TASK-008",
    type: "task",
    title: "NixOS module",
    labels: ["nixos"],
  };

  expect(dispatcher.selectAgents(nixIssue)).toContain("nix-expert");
  expect(dispatcher.selectAgents(nixosIssue)).toContain("nix-expert");
});

test("selectAgents handles aws and cloud labels", () => {
  const dispatcher = new SubagentDispatcher();

  const awsIssue: IssueRecord = {
    id: "TASK-009",
    type: "task",
    title: "AWS deployment",
    labels: ["aws"],
  };

  const cloudIssue: IssueRecord = {
    id: "TASK-010",
    type: "task",
    title: "Cloud infrastructure",
    labels: ["cloud"],
  };

  expect(dispatcher.selectAgents(awsIssue)).toContain("aws-expert");
  expect(dispatcher.selectAgents(cloudIssue)).toContain("aws-expert");
});
