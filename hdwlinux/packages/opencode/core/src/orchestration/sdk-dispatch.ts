/**
 * OpenCode SDK-based subagent dispatch
 *
 * Creates an executionHandler for SubagentDispatcher that dispatches
 * work to subagents via the OpenCode SDK session API:
 *
 *   1. Create a child session
 *   2. Send a prompt with the agent name and task instructions
 *   3. Read the assistant's response from the session messages
 *   4. Return structured SubagentResult
 *
 * This mirrors the pattern used by opencode-background-agents.
 */

import type { SubagentTask, SubagentResult } from "./subagent-dispatcher.js";
import { getAgent } from "../agents.js";

// ── Types ───────────────────────────────────────────────────────

/**
 * Minimal subset of the OpenCode SDK client needed for dispatch.
 * Using a narrow interface so we can mock it in tests without
 * pulling in the full SDK.
 */
export interface OpenCodeClient {
  session: {
    create(opts: {
      body: { title: string; parentID?: string };
    }): Promise<{ data?: { id?: string } }>;

    prompt(opts: {
      path: { id: string };
      body: {
        agent?: string;
        parts: Array<{ type: "text"; text: string }>;
        tools?: Record<string, boolean>;
      };
    }): Promise<{ data?: { parts?: Array<{ type: string; text?: string }> } }>;

    messages(opts: {
      path: { id: string };
    }): Promise<{
      data?: Array<{
        info: { role: string };
        parts: Array<{ type: string; text?: string }>;
      }>;
    }>;
  };
}

export interface SdkDispatchOptions {
  /** OpenCode SDK client instance */
  client: OpenCodeClient;
  /** Parent session ID for child session creation */
  parentSessionId?: string;
  /** Timeout in ms for each agent invocation (default: 120_000) */
  timeoutMs?: number;
}

// ── Prompt builder ──────────────────────────────────────────────

function buildPrompt(agentName: string, task: SubagentTask): string {
  const agent = getAgent(agentName);
  const agentDesc = agent
    ? `You are the ${agent.name} (${agent.description}).`
    : `You are the ${agentName} agent.`;

  const sections: string[] = [
    agentDesc,
    "",
    `## Task: ${task.taskType}`,
    "",
    `**Issue:** ${task.context.title}`,
  ];

  if (task.context.description) {
    sections.push(`**Description:** ${task.context.description}`);
  }
  if (task.context.labels?.length) {
    sections.push(`**Labels:** ${task.context.labels.join(", ")}`);
  }
  if (task.instructions) {
    sections.push("", "## Instructions", "", task.instructions);
  }

  sections.push(
    "",
    "## Expected Output",
    "",
    "Provide your analysis, findings, and recommendations.",
    "Be specific and actionable.",
  );

  return sections.join("\n");
}

// ── Execution handler factory ───────────────────────────────────

/**
 * Create an executionHandler for SubagentDispatcher that uses the
 * OpenCode SDK to dispatch work to subagent sessions.
 */
export function createSdkExecutionHandler(
  options: SdkDispatchOptions
): (agentName: string, task: SubagentTask) => Promise<SubagentResult> {
  const { client, parentSessionId, timeoutMs = 120_000 } = options;

  return async (agentName: string, task: SubagentTask): Promise<SubagentResult> => {
    const startTime = Date.now();

    try {
      // 1. Create a child session
      const sessionResult = await client.session.create({
        body: {
          title: `${agentName}: ${task.context.title}`.slice(0, 100),
          ...(parentSessionId ? { parentID: parentSessionId } : {}),
        },
      });

      const sessionId = sessionResult.data?.id;
      if (!sessionId) {
        return {
          agentName,
          status: "failed",
          error: "Failed to create child session",
          durationMs: Date.now() - startTime,
        };
      }

      // 2. Send prompt to the agent
      const prompt = buildPrompt(agentName, task);

      const promptResult = await Promise.race([
        client.session.prompt({
          path: { id: sessionId },
          body: {
            agent: agentName,
            parts: [{ type: "text", text: prompt }],
            // Prevent recursive delegation
            tools: {
              task: false,
              delegate: false,
            },
          },
        }),
        new Promise<never>((_, reject) =>
          setTimeout(
            () => reject(new Error(`Agent ${agentName} timed out after ${timeoutMs}ms`)),
            timeoutMs
          )
        ),
      ]);

      // 3. Extract text from the response
      const responseParts = promptResult.data?.parts ?? [];
      const textParts = responseParts.filter(
        (p): p is { type: "text"; text: string } =>
          p.type === "text" && typeof p.text === "string"
      );

      if (textParts.length === 0) {
        return {
          agentName,
          status: "partial",
          output: { sessionId },
          findings: [],
          recommendations: ["Agent produced no text output"],
          durationMs: Date.now() - startTime,
        };
      }

      const fullText = textParts.map((p) => p.text).join("\n");

      // 4. Parse findings and recommendations from the response
      const { findings, recommendations } = extractInsights(fullText);

      return {
        agentName,
        status: "success",
        output: {
          sessionId,
          text: fullText,
        },
        findings,
        recommendations,
        durationMs: Date.now() - startTime,
      };
    } catch (error: any) {
      return {
        agentName,
        status: "failed",
        error: error?.message || String(error),
        durationMs: Date.now() - startTime,
      };
    }
  };
}

// ── Helpers ─────────────────────────────────────────────────────

/**
 * Extract structured findings and recommendations from agent text output.
 * Looks for markdown headers and bullet points.
 */
function extractInsights(text: string): {
  findings: string[];
  recommendations: string[];
} {
  const findings: string[] = [];
  const recommendations: string[] = [];

  let currentSection: "findings" | "recommendations" | null = null;

  for (const line of text.split("\n")) {
    const trimmed = line.trim();
    const lower = trimmed.toLowerCase();

    // Only detect section headers on header-like lines (## or standalone text),
    // not on bullet points or numbered items
    const isBullet = trimmed.startsWith("- ") || trimmed.startsWith("* ") || /^\d+\.\s/.test(trimmed);

    if (!isBullet) {
      if (lower.includes("finding") || lower.includes("analysis") || lower.includes("observation")) {
        currentSection = "findings";
        continue;
      }
      if (lower.includes("recommendation") || lower.includes("suggestion") || lower.includes("next step")) {
        currentSection = "recommendations";
        continue;
      }
    }

    // Extract bullet points
    if (isBullet) {
      const content = trimmed.replace(/^[-*]\s+/, "").replace(/^\d+\.\s+/, "");
      if (content.length > 5) {
        if (currentSection === "recommendations") {
          recommendations.push(content);
        } else {
          findings.push(content);
        }
      }
    }
  }

  return { findings, recommendations };
}

// Exported for tests
export { buildPrompt, extractInsights };
