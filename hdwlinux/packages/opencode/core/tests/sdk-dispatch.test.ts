/**
 * Tests for SDK-based subagent dispatch
 *
 * Verifies that createSdkExecutionHandler correctly creates sessions,
 * sends prompts, and parses responses using a mock OpenCode client.
 */

import { describe, test, expect, beforeEach } from "bun:test";
import {
  createSdkExecutionHandler,
  buildPrompt,
  extractInsights,
} from "../src/orchestration/sdk-dispatch.js";
import type { OpenCodeClient } from "../src/orchestration/sdk-dispatch.js";
import type { SubagentTask } from "../src/orchestration/subagent-dispatcher.js";

// ── Mock client ─────────────────────────────────────────────────

function createMockClient(overrides?: {
  sessionId?: string;
  responseText?: string;
  createFails?: boolean;
  promptFails?: boolean;
}): { client: OpenCodeClient; calls: { method: string; args: any }[] } {
  const calls: { method: string; args: any }[] = [];
  const sessionId = overrides?.sessionId ?? "mock-session-123";
  const responseText = overrides?.responseText ?? "Analysis complete. No issues found.";

  const client: OpenCodeClient = {
    session: {
      create: async (opts) => {
        calls.push({ method: "session.create", args: opts });
        if (overrides?.createFails) {
          return { data: {} };
        }
        return { data: { id: sessionId } };
      },
      prompt: async (opts) => {
        calls.push({ method: "session.prompt", args: opts });
        if (overrides?.promptFails) {
          throw new Error("Prompt failed");
        }
        return {
          data: {
            parts: [{ type: "text", text: responseText }],
          },
        };
      },
      messages: async (opts) => {
        calls.push({ method: "session.messages", args: opts });
        return {
          data: [
            {
              info: { role: "assistant" },
              parts: [{ type: "text", text: responseText }],
            },
          ],
        };
      },
    },
  };

  return { client, calls };
}

function createTask(overrides?: Partial<SubagentTask>): SubagentTask {
  return {
    issueId: "ISSUE-123",
    taskType: "analyze",
    context: {
      title: "Test Task",
      description: "A test task for analysis",
      labels: ["nix", "security"],
    },
    instructions: "Analyze the codebase for security issues",
    ...overrides,
  };
}

// ── Tests ───────────────────────────────────────────────────────

describe("createSdkExecutionHandler", () => {
  test("creates a child session and sends prompt", async () => {
    const { client, calls } = createMockClient();
    const handler = createSdkExecutionHandler({ client });
    const task = createTask();

    const result = await handler("nix-expert", task);

    expect(result.status).toBe("success");
    expect(result.agentName).toBe("nix-expert");
    expect(result.durationMs).toBeGreaterThanOrEqual(0);

    // Verify session.create was called
    const createCall = calls.find((c) => c.method === "session.create");
    expect(createCall).toBeTruthy();
    expect(createCall!.args.body.title).toContain("nix-expert");

    // Verify session.prompt was called with agent name
    const promptCall = calls.find((c) => c.method === "session.prompt");
    expect(promptCall).toBeTruthy();
    expect(promptCall!.args.body.agent).toBe("nix-expert");
    expect(promptCall!.args.body.parts[0].type).toBe("text");
  });

  test("passes parentSessionId to child session", async () => {
    const { client, calls } = createMockClient();
    const handler = createSdkExecutionHandler({
      client,
      parentSessionId: "parent-session-456",
    });

    await handler("nix-expert", createTask());

    const createCall = calls.find((c) => c.method === "session.create");
    expect(createCall!.args.body.parentID).toBe("parent-session-456");
  });

  test("disables task and delegate tools to prevent recursion", async () => {
    const { client, calls } = createMockClient();
    const handler = createSdkExecutionHandler({ client });

    await handler("nix-expert", createTask());

    const promptCall = calls.find((c) => c.method === "session.prompt");
    expect(promptCall!.args.body.tools).toEqual({
      task: false,
      delegate: false,
    });
  });

  test("returns failed when session creation fails", async () => {
    const { client } = createMockClient({ createFails: true });
    const handler = createSdkExecutionHandler({ client });

    const result = await handler("nix-expert", createTask());

    expect(result.status).toBe("failed");
    expect(result.error).toContain("Failed to create child session");
  });

  test("returns failed when prompt throws", async () => {
    const { client } = createMockClient({ promptFails: true });
    const handler = createSdkExecutionHandler({ client });

    const result = await handler("nix-expert", createTask());

    expect(result.status).toBe("failed");
    expect(result.error).toContain("Prompt failed");
  });

  test("returns partial when response has no text parts", async () => {
    const { client } = createMockClient({ responseText: "" });

    // Override prompt to return non-text parts
    const originalPrompt = client.session.prompt;
    client.session.prompt = async (opts) => {
      return { data: { parts: [{ type: "tool_use", text: undefined }] } };
    };

    const handler = createSdkExecutionHandler({ client });
    const result = await handler("nix-expert", createTask());

    expect(result.status).toBe("partial");
    expect(result.recommendations).toContain("Agent produced no text output");
  });

  test("extracts findings and recommendations from response", async () => {
    const responseText = `## Analysis

### Findings
- The NixOS configuration has a potential security issue in the firewall rules
- The home-manager module is missing proper type annotations

### Recommendations
- Add explicit firewall rules for port 443
- Use lib.mkOption with proper types for all options
`;

    const { client } = createMockClient({ responseText });
    const handler = createSdkExecutionHandler({ client });

    const result = await handler("security-architect", createTask());

    expect(result.status).toBe("success");
    expect(result.findings!.length).toBeGreaterThan(0);
    expect(result.recommendations!.length).toBeGreaterThan(0);
  });

  test("includes session ID in output", async () => {
    const { client } = createMockClient({ sessionId: "child-session-789" });
    const handler = createSdkExecutionHandler({ client });

    const result = await handler("nix-expert", createTask());

    expect(result.status).toBe("success");
    const output = result.output as { sessionId: string; text: string };
    expect(output.sessionId).toBe("child-session-789");
    expect(output.text).toBeDefined();
  });
});

describe("buildPrompt", () => {
  test("includes agent description for known agents", () => {
    const task = createTask();
    const prompt = buildPrompt("nix-expert", task);

    expect(prompt).toContain("Nix Expert");
    expect(prompt).toContain("Test Task");
    expect(prompt).toContain("analyze");
  });

  test("includes task instructions when provided", () => {
    const task = createTask({ instructions: "Focus on security" });
    const prompt = buildPrompt("nix-expert", task);

    expect(prompt).toContain("Focus on security");
  });

  test("includes labels when provided", () => {
    const task = createTask({
      context: { title: "Test", labels: ["kafka", "streaming"] },
    });
    const prompt = buildPrompt("kafka-expert", task);

    expect(prompt).toContain("kafka");
    expect(prompt).toContain("streaming");
  });

  test("handles unknown agent gracefully", () => {
    const task = createTask();
    const prompt = buildPrompt("unknown-agent", task);

    expect(prompt).toContain("unknown-agent");
    expect(prompt).toContain("Test Task");
  });
});

describe("extractInsights", () => {
  test("extracts findings from bullet points under findings header", () => {
    const text = `## Findings
- Issue one is important
- Issue two needs attention

## Recommendations
- Not a finding but a recommendation`;

    const { findings, recommendations } = extractInsights(text);
    expect(findings.length).toBe(2);
    expect(findings[0]).toContain("Issue one");
    expect(recommendations.length).toBe(1);
  });

  test("extracts recommendations from bullet points under recommendations header", () => {
    const text = `## Recommendations
- Fix the configuration
- Update the dependencies`;

    const { recommendations } = extractInsights(text);
    expect(recommendations.length).toBe(2);
  });

  test("handles numbered lists", () => {
    const text = `## Findings
1. First finding
2. Second finding`;

    const { findings } = extractInsights(text);
    expect(findings.length).toBe(2);
  });

  test("returns empty arrays for text without structured sections", () => {
    const text = "Just some plain text without any structure.";
    const { findings, recommendations } = extractInsights(text);
    expect(findings.length).toBe(0);
    expect(recommendations.length).toBe(0);
  });

  test("handles mixed sections", () => {
    const text = `## Analysis
- Found a potential issue

## Next Steps
- Implement the fix
- Run the tests`;

    const { findings, recommendations } = extractInsights(text);
    expect(findings.length).toBeGreaterThan(0);
    expect(recommendations.length).toBeGreaterThan(0);
  });
});
