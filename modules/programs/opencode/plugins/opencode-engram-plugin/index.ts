import { execFileSync } from "child_process";
import { readFileSync } from "fs";
import { homedir } from "os";
import type { Plugin } from "@opencode-ai/plugin";

const ENGRAM = "engram";

/** Maximum memories to store per idle cycle. */
const MAX_MEMORIES_PER_IDLE = 3;

interface EngramConfig {
  /** Path to the engram SQLite database. If not specified, defaults to $XDG_DATA_HOME/engram/engram.db */
  db?: string;
  /** Path to the engram config file (TOML). If not specified, engram defaults to $XDG_CONFIG_HOME/engram/engram.toml */
  configFile?: string;
}

interface BufferEntry {
  role: string;
  text: string;
  isSummary: boolean;
}

type ClassifierResult = { store: false } | { store: true; type: "episodic" | "preference" | "fact"; content: string };

interface ParsedModel {
  providerID: string;
  modelID: string;
}

/**
 * Load engram plugin configuration from ~/.config/opencode/engram.json.
 * This JSON file can specify:
 *   - db: path to the SQLite database (optional, engram has a default)
 *   - configFile: path to the engram TOML config file (optional, engram has a default)
 * If the file doesn't exist or can't be parsed, returns empty config and engram uses its defaults.
 */
function loadConfig(): EngramConfig {
  const configPath = `${homedir()}/.config/opencode/engram.json`;
  try {
    const content = readFileSync(configPath, "utf8");
    return JSON.parse(content) as EngramConfig;
  } catch {
    return {};
  }
}

const engramConfig = loadConfig();

/** Run engram and return stdout as a string. */
function engram(args: string[]): string {
  const engramArgs: string[] = [];
  if (engramConfig.db) engramArgs.push("--db", engramConfig.db);
  if (engramConfig.configFile) engramArgs.push("--config", engramConfig.configFile);
  engramArgs.push(...args);

  return execFileSync(ENGRAM, engramArgs, {
    encoding: "utf8",
    timeout: 15_000,
  }).trim();
}

/** Parse "provider/model" string into { providerID, modelID }. */
function parseModel(modelStr: string): ParsedModel | null {
  const slash = modelStr.indexOf("/");
  if (slash === -1) return null;
  return {
    providerID: modelStr.slice(0, slash),
    modelID: modelStr.slice(slash + 1),
  };
}

/** Extract plain text from a list of message parts. */
function partsToText(parts: Array<{ type: string; synthetic?: boolean; ignored?: boolean; text?: string }>): string {
  return parts
    .filter((p) => p.type === "text" && !p.synthetic && !p.ignored)
    .map((p) => p.text)
    .join("\n")
    .trim();
}

/** Search engram and return formatted memory lines, or [] if nothing useful. */
async function prefetchMemories(sessionID: string, client: any, buffer: BufferEntry[]): Promise<string[]> {
  const queryParts: string[] = [];

  // Session title is the highest-signal context.
  try {
    const sessionRes = await client.session.info({ path: { id: sessionID } });
    const title = sessionRes.data?.title;
    if (title) queryParts.push(title);
  } catch {
    // Non-fatal — proceed without title.
  }

  // Last 2 user messages from the buffer (most recent context).
  const recentUser = buffer.filter((e) => e.role === "User").slice(-2).map((e) => e.text);
  queryParts.push(...recentUser);

  if (queryParts.length === 0) return [];

  const query = queryParts.join(" ");
  const raw = engram(["search", "--json", "--limit", "8", query]);
  const memories = JSON.parse(raw) as Array<{ Classification?: string; Snippet?: string; Title?: string }>;

  return memories.map((m) => {
    const tag = m.Classification ? ` [${m.Classification}]` : "";
    return `- ${m.Snippet || m.Title}${tag}`;
  });
}

export default async ({ client }: { client: any }): Promise<Plugin> => {
  let smallModel: ParsedModel | null = null;

  function clog(level: "debug" | "info" | "warn" | "error", message: string, extra?: Record<string, unknown>) {
    client.app.log({ body: { service: "engram-plugin", level, message, extra: extra ?? {} } }).catch(() => {});
  }

  // Per-session message buffer: sessionID -> array of { role, text, isSummary }
  // Accumulates across turns; drained on each session.idle.
  const sessionBuffers = new Map<string, BufferEntry[]>();

  // Per-session prefetch cache: sessionID -> Promise<string[]> of formatted memory lines.
  // Kicked off in the background after each chat.message so that transform
  // can await an already-resolved promise rather than doing I/O on the critical path.
  const memoryCache = new Map<string, Promise<string[]>>();

  // Classifier session IDs — excluded from buffering and classification.
  // Never removed: classifier sessions should be permanently ignored even after deletion,
  // since their session.idle event fires after the finally block removes them.
  const classifierSessions = new Set<string>();

  function getBuffer(sessionID: string): BufferEntry[] {
    if (!sessionBuffers.has(sessionID)) sessionBuffers.set(sessionID, []);
    return sessionBuffers.get(sessionID)!;
  }

  async function classifyAndStore(sessionID: string): Promise<void> {
    clog("info", "classifyAndStore called", { sessionID });

    if (!smallModel) {
      clog("warn", "smallModel not set, skipping classification");
      return;
    }
    if (classifierSessions.has(sessionID)) {
      clog("debug", "classifier session, skipping", { sessionID });
      return;
    }

    const buffer = sessionBuffers.get(sessionID);
    clog("info", "buffer state", { sessionID, entries: buffer?.length ?? 0 });
    if (!buffer || buffer.length === 0) {
      clog("info", "buffer empty, skipping classification", { sessionID });
      return;
    }

    // Drain the buffer — take everything accumulated since last idle.
    const entries = buffer.splice(0);
    clog("info", "drained buffer", { sessionID, entries: entries.length });

    // Build excerpt: summary entries first (higher signal), then the rest.
    const summaries = entries.filter((e) => e.isSummary);
    const rest = entries.filter((e) => !e.isSummary);
    const ordered = [...summaries, ...rest];

    const excerpt = ordered
      .map((e) => {
        const label = e.isSummary ? `${e.role} [SUMMARY]` : e.role;
        return `${label}: ${e.text}`;
      })
      .join("\n\n");

    if (!excerpt.trim()) {
      clog("info", "excerpt empty, skipping", { sessionID });
      return;
    }

    clog("info", "built excerpt", { sessionID, chars: excerpt.length });

    // Fetch session title to give the classifier project context.
    let sessionTitle = "";
    try {
      const sessionRes = await client.session.info({ path: { id: sessionID } });
      sessionTitle = sessionRes.data?.title ?? "";
    } catch {
      // Non-fatal — proceed without title.
    }

    // Create a throwaway classifier session.
    const sessionRes = await client.session.create({});
    if (!sessionRes.data) {
      clog("error", "failed to create classifier session", { sessionID });
      return;
    }
    const classifierSessionID = sessionRes.data.id;
    classifierSessions.add(classifierSessionID);
    clog("info", "created classifier session", { sessionID, classifierSessionID });

    try {
      clog("info", "prompting classifier", { classifierSessionID, model: `${smallModel.providerID}/${smallModel.modelID}` });
      // Use the "engram-classifier" agent defined in opencode.json — its prompt
      // is the classifier system prompt, so we send just the excerpt as the user message.
      const promptRes = await client.session.prompt({
        path: { id: classifierSessionID },
        body: {
          model: {
            modelID: smallModel.modelID,
            providerID: smallModel.providerID,
          },
          agent: "engram-classifier",
          tools: {},
          parts: [{ type: "text", text: sessionTitle ? `Session: ${sessionTitle}\n\n${excerpt}` : excerpt }],
        },
      });

      if (!promptRes.data) {
        clog("error", "classifier returned no data", { classifierSessionID });
        return;
      }

      const responseText = partsToText(promptRes.data.parts);
      clog("info", "classifier response", { classifierSessionID, response: responseText.substring(0, 200) });
      if (!responseText) {
        clog("warn", "classifier response text empty", { classifierSessionID });
        return;
      }

      // Strip markdown fences if the model wrapped the JSON despite instructions.
      const jsonText = responseText.replace(/^```(?:json)?\s*/i, "").replace(/\s*```\s*$/, "").trim();

      let results: ClassifierResult[];
      try {
        results = JSON.parse(jsonText);
        if (!Array.isArray(results)) {
          clog("warn", "classifier response not an array", { classifierSessionID });
          return;
        }
      } catch (e) {
        clog("error", "failed to parse classifier response", { classifierSessionID, error: String(e) });
        return;
      }

      clog("info", "parsed classification results", { classifierSessionID, count: results.length });

      let stored = 0;
      for (const result of results) {
        if (stored >= MAX_MEMORIES_PER_IDLE) break;
        if (result.store && result.type && result.content) {
          try {
            clog("info", "storing memory", { type: result.type, preview: result.content.substring(0, 80) });
            engram(["add", "--type", result.type, "--correlation-id", sessionID, result.content]);
            stored++;
          } catch (e) {
            clog("error", "failed to store memory", { error: String(e) });
          }
        }
      }
      clog("info", "classification complete", { sessionID, stored });
    } finally {
      try {
        await client.session.delete({ path: { id: classifierSessionID } });
      } catch {}
      // Intentionally NOT removing from classifierSessions — the session.idle event
      // for the deleted session fires after this finally block, and we need the guard
      // to still be in place to prevent recursive classification.
    }
  }

  return {
    async config(cfg: { small_model?: string; agent?: Record<string, unknown> }) {
      clog("info", "config called", { small_model: cfg.small_model });
      if (cfg.small_model) {
        smallModel = parseModel(cfg.small_model);
        clog("info", "smallModel set", { providerID: smallModel?.providerID, modelID: smallModel?.modelID });
      } else {
        clog("warn", "no small_model in config");
      }

      // Inject the engram-classifier agent directly into config so Agent.state
      // picks it up when lazily initialized — no need to define it in opencode.json.
      // Must mutate cfg.agent in-place (Object.assign on the nested object),
      // not replace the top-level key — same pattern as opencode-projects-plugin.
      if (!cfg.agent) cfg.agent = {};
      Object.assign(cfg.agent, {
        "engram-classifier": {
          description: "Internal: classifies conversation excerpts into memories for engram. Outputs JSON only.",
          mode: "subagent",
          prompt: `You are a memory classifier for a personal knowledge base assistant.
Given a conversation excerpt, identify up to 3 distinct pieces of information worth storing as long-term memories.

Respond with a JSON array only — no prose, no markdown fences.

Each element must be one of:
{ "store": false }
OR
{ "store": true, "type": "episodic" | "preference" | "fact", "content": "<concise memory to store>" }

Type definitions:
- episodic: what happened in this exchange — decisions made, tasks completed, context established. Decays after ~3 days.
- preference: standing user preferences, constraints, workflow rules, coding style. Permanent.
- fact: stable knowledge — decisions about architecture, things learned, project-specific facts. Permanent.

Rules:
- Return at most 3 elements total.
- Only include { "store": true } entries for information genuinely useful to recall in a future session.
- Do NOT store: questions, greetings, trivial exchanges, tool outputs, file contents, or anything session-specific that won't matter later.
- Summary messages (marked [SUMMARY]) are higher-signal — prefer extracting memories from them.
- Each memory must be self-contained and concise (one or two sentences max).
- Each memory MUST include enough context to be useful in isolation — include the project name, repository, or topic so the memory is not ambiguous when recalled in a different session.`,
          temperature: 0.1,
        },
      });
      clog("info", "injected engram-classifier agent into config");
    },

    async "chat.message"(input: { sessionID: string }, output: { parts: any[]; message: { role: string; summary?: boolean } }) {
      const { sessionID } = input;
      if (classifierSessions.has(sessionID)) {
        clog("info", "chat.message from classifier session, skipping", { sessionID });
        return;
      }

      const text = partsToText(output.parts);
      if (!text) return;

      const role = output.message.role === "user" ? "User" : "Assistant";
      const isSummary = output.message.role === "assistant" && !!output.message.summary;

      const buffer = getBuffer(sessionID);
      buffer.push({ role, text, isSummary });
      clog("info", "buffered message", { sessionID, role, isSummary, bufferSize: buffer.length });

      // Kick off a background prefetch so the next transform call is near-instant.
      // We replace any in-flight prefetch — only the latest context matters.
      memoryCache.set(
        sessionID,
        prefetchMemories(sessionID, client, buffer).catch(() => []),
      );
    },

    async event({ event }: { event: { type: string; properties?: { sessionID: string } } }) {
      const { sessionID } = event.properties || {};
      if (!sessionID) return;
      if (classifierSessions.has(sessionID)) {
        clog("debug", "event for classifier session, ignoring", { type: event.type, sessionID });
        return;
      }

      clog("debug", "event received", { type: event.type, sessionID });

      if (event.type === "session.idle") {
        clog("info", "session.idle — triggering classification", { sessionID });
        classifyAndStore(sessionID).catch((err) => {
          clog("error", "classifyAndStore failed", { sessionID, error: String(err) });
        });
        memoryCache.delete(sessionID);
      } else if (event.type === "session.compacted") {
        clog("info", "session.compacted — triggering classification", { sessionID });
        classifyAndStore(sessionID).catch((err) => {
          clog("error", "classifyAndStore failed", { sessionID, error: String(err) });
        });
        memoryCache.delete(sessionID);
      }
    },

    async "experimental.session.compacting"({ sessionID }: { sessionID: string }, output: { context: string[] }) {
      clog("info", "experimental.session.compacting called", { sessionID });
      try {
        const cached = memoryCache.get(sessionID);
        const buffer = sessionBuffers.get(sessionID) ?? [];
        const lines = cached
          ? await cached
          : await prefetchMemories(sessionID, client, buffer).catch(() => []);

        clog("info", "compacting memory lines", { sessionID, count: lines.length });
        if (lines.length === 0) return;

        output.context.push(
          `## Relevant memories from your knowledge base\n\n${lines.join("\n")}`
        );
      } catch (e) {
        clog("error", "compacting hook failed", { sessionID, error: String(e) });
      }
    },

    async "experimental.chat.system.transform"({ sessionID }: { sessionID?: string }, output: { system: string[] }) {
      if (!sessionID) return;

      try {
        const cached = memoryCache.get(sessionID);
        const buffer = sessionBuffers.get(sessionID) ?? [];
        const lines = cached
          ? await cached
          : await prefetchMemories(sessionID, client, buffer).catch(() => []);

        clog("debug", "system.transform memory lines", { sessionID, count: lines.length });
        if (lines.length === 0) return;

        output.system.push(
          `## Relevant memories from your knowledge base\n\n${lines.join("\n")}`
        );
      } catch (e) {
        clog("error", "system.transform hook failed", { sessionID, error: String(e) });
      }
    },

    tool: {
      "memory-search": {
        description:
          "Search the knowledge base and memory for relevant context. " +
          "Use this at the start of tasks to recall relevant past decisions, " +
          "preferences, and notes. Results are ranked by a combined score of " +
          "semantic similarity and memory strength — stronger/more-accessed memories " +
          "surface first. Returns file paths, classification, strength, and snippets.",
        parameters: {
          type: "object",
          properties: {
            query: {
              type: "string",
              description: "Natural language search query",
            },
            limit: {
              type: "number",
              description: "Maximum number of results to return (default 5)",
            },
          },
          required: ["query"],
        },
        execute({ query, limit = 5 }: { query: string; limit?: number }) {
          try {
            return engram(["search", "--json", "--limit", String(limit), query]);
          } catch (err) {
            return JSON.stringify({ error: (err as Error).message });
          }
        },
      },

      "memory-add": {
        description:
          "Save a memory to the knowledge base. " +
          "Use 'episodic' for session observations and what happened today. " +
          "Use 'preference' for standing user preferences, constraints, and workflow rules. " +
          "Use 'fact' for decisions made, things learned, and stable factual knowledge.",
        parameters: {
          type: "object",
          properties: {
            content: {
              type: "string",
              description: "The memory content to save",
            },
            type: {
              type: "string",
              enum: ["episodic", "preference", "fact"],
              description:
                "episodic = temporal/session memory (decays after ~3 days); " +
                "preference = standing rules and user preferences (permanent); " +
                "fact = decisions, learnings, stable knowledge (permanent)",
            },
          },
          required: ["content", "type"],
        },
        execute({ content, type }: { content: string; type: string }) {
          try {
            const path = engram(["add", "--type", type, content]);
            return JSON.stringify({ saved: path });
          } catch (err) {
            return JSON.stringify({ error: (err as Error).message });
          }
        },
      },
    },

    // Re-index the vault and apply memory decay at the end of each session.
    async afterSession() {
      clog("info", "afterSession: running ingest and decay");
      try {
        engram(["ingest"]);
      } catch (e) {
        clog("error", "ingest failed", { error: String(e) });
      }
      try {
        engram(["decay"]);
      } catch (e) {
        clog("error", "decay failed", { error: String(e) });
      }
    },
  };
};
