import { execFileSync } from "child_process";
import { readFileSync } from "fs";
import { homedir } from "os";
import type { Plugin } from "@opencode-ai/plugin";

const ENGRAM = "engram";

// ─── Configuration types ──────────────────────────────────────────────────────

/**
 * Engram plugin configuration, loaded from a JSON config file.
 *
 * The plugin looks for config in:
 * 1. File path specified by `OPENCODE_ENGRAM_CONFIG` environment variable
 * 2. Default: `$HOME/.config/opencode/engram.json`
 *
 * Example engram.json:
 * {
 *   "config_file": "/path/to/engram.toml",
 *   "auto_classify": {
 *     "model": "anthropic/claude-haiku-4-5",
 *     "enabled": true,
 *     "min_messages": 10,
 *     "max_memories": 3,
 *     "temperature": 0.2,
 *     "search_limit": 8
 *   }
 * }
 */
interface EngramPluginConfig {
  /** Path to the engram TOML config file. Defaults to engram's built-in default. */
  config_file?: string;
  /** Auto-classification settings. */
  auto_classify?: AutoClassifyConfig;
}

/**
 * Auto-classification settings, all optional.
 */
interface AutoClassifyConfig {
  /**
   * Master switch for automatic classification.
   * When false, no classification runs on idle or compaction — the
   * engram-add tool remains available for manual storage.
   * Default: true
   */
  enabled?: boolean;
  /**
   * Minimum number of buffered messages required before idle classification
   * will run. Prevents low-context classifications that produce noisy memories.
   * Does not apply to compaction, which always has full context.
   * Default: 10
   */
  min_messages?: number;
  /**
   * Maximum number of memories to store per classification run.
   * Also controls the "at most N" instruction in the classifier prompt.
   * Default: 3
   */
  max_memories?: number;
  /**
   * Temperature passed to the classifier model.
   * Lower values produce more deterministic, conservative classifications.
   * Default: 0.2
   */
  temperature?: number;
  /**
   * Number of memories to fetch from engram when injecting into the system
   * prompt or compaction context.
   * Default: 8
   */
  search_limit?: number;
  /**
   * Model to use for classification, in "provider/model" format.
   * Resolution order: this value → opencode's small_model → classification disabled.
   * Example: "anthropic/claude-haiku-4-5"
   */
  model?: string;
}

/** Resolved auto-classify settings with all defaults applied. */
interface ResolvedAutoClassify {
  enabled: boolean;
  minMessages: number;
  maxMemories: number;
  temperature: number;
  searchLimit: number;
  /** Resolved model, or null if classification is disabled. */
  model: ParsedModel | null;
}

const AUTO_CLASSIFY_DEFAULTS = {
  enabled: true,
  minMessages: 10,
  maxMemories: 3,
  temperature: 0.2,
  searchLimit: 8,
} as const;

// ─── Internal types ───────────────────────────────────────────────────────────

interface BufferEntry {
  role: string;
  text: string;
  isSummary: boolean;
}

type ClassifierResult = { store: false } | { store: true; type: string; content: string };

interface EngramMemoryType {
  name: string;
  description: string;
}

interface ParsedModel {
  providerID: string;
  modelID: string;
}

// ─── Configuration loading ────────────────────────────────────────────────────

/**
 * Load engram plugin configuration from file.
 *
 * Checks OPENCODE_ENGRAM_CONFIG env var first, then defaults to
 * $HOME/.config/opencode/engram.json. Returns empty config if file
 * is missing or unparseable.
 */
function loadPluginConfig(): EngramPluginConfig {
  const configPath = process.env.OPENCODE_ENGRAM_CONFIG ||
    `${homedir()}/.config/opencode/engram.json`;

  try {
    const content = readFileSync(configPath, "utf8");
    return JSON.parse(content) as EngramPluginConfig;
  } catch {
    // File missing, unparseable, or unreadable — return empty config.
    // The plugin will work with engram's defaults.
    return {};
  }
}

// ─── Pure helpers (no engram config dependency) ───────────────────────────────

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

/** Build the classifier system prompt from the configured memory types and limits. */
function buildClassifierPrompt(types: EngramMemoryType[], maxMemories: number): string {
  const typeNames = types.map((t) => `"${t.name}"`).join(" | ");
  const typeList = types.map((t) => `- ${t.name}: ${t.description}`).join("\n");

  return `You are a memory classifier for a personal knowledge base assistant.
Given a conversation excerpt, identify up to ${maxMemories} distinct pieces of information worth storing as long-term memories.

Respond with a JSON array only — no prose, no markdown fences.

Each element must be one of:
{ "store": false }
OR
{ "store": true, "type": ${typeNames}, "content": "<concise memory to store>" }

Type definitions:
${typeList}

Rules:
- Return at most ${maxMemories} elements total.
- Only include { "store": true } entries for information genuinely useful to recall in a future session.
- Do NOT store: questions, greetings, trivial exchanges, tool outputs, file contents, or anything session-specific that won't matter later.
- Summary messages (marked [SUMMARY]) are higher-signal — prefer extracting memories from them.
- Each memory must be self-contained and concise (one or two sentences max).
- Each memory MUST include enough context to be useful in isolation — include the project name, repository, or topic so the memory is not ambiguous when recalled in a different session.`;
}

// ─── Plugin factory ───────────────────────────────────────────────────────────

export default async ({ client }: { client: any }): Promise<Plugin> => {
  // Load plugin config from file at module initialization.
  const pluginConfig = loadPluginConfig();

  /**
   * Load memory types from engram once config is available.
   */
  function loadMemoryTypes(): EngramMemoryType[] {
    const raw = engram(["types", "--json"]);
    const parsed = JSON.parse(raw) as EngramMemoryType[];
    if (!Array.isArray(parsed) || parsed.length === 0) {
      throw new Error("engram types returned no memory types — check engram config");
    }
    return parsed;
  }

  // Load memory types at module init.
  let memoryTypes: EngramMemoryType[] = [];
  try {
    memoryTypes = loadMemoryTypes();
  } catch (err) {
    // Will be caught again in config() and re-thrown with context.
  }

  // Mutable config state — populated in config() before any hooks fire.
  let autoClassify: ResolvedAutoClassify = { ...AUTO_CLASSIFY_DEFAULTS, model: null };

  function clog(level: "debug" | "info" | "warn" | "error", message: string, extra?: Record<string, unknown>) {
    client.app.log({ body: { service: "engram-plugin", level, message, extra: extra ?? {} } }).catch(() => {});
  }

  /**
   * Run engram with the configured db and config_file flags prepended.
   */
  function engram(args: string[]): string {
    const engramArgs: string[] = [];
    if (pluginConfig.config_file) engramArgs.push("--config", pluginConfig.config_file);
    engramArgs.push(...args);

    return execFileSync(ENGRAM, engramArgs, {
      encoding: "utf8",
      timeout: 15_000,
    }).trim();
  }

  // Per-session message buffer: sessionID -> array of { role, text, isSummary }
  // Accumulates across turns; drained on each session idle.
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

  /** Search engram with a query and return formatted memory lines. */
  async function searchMemories(query: string): Promise<string[]> {
    const raw = engram(["search", "--json", "--limit", String(autoClassify.searchLimit), query]);
    const memories = JSON.parse(raw) as Array<{ Classification?: string; Snippet?: string; Title?: string }>;
    return memories.map((m) => {
      const tag = m.Classification ? ` [${m.Classification}]` : "";
      return `- ${m.Snippet || m.Title}${tag}`;
    });
  }

  /** Search engram and return formatted memory lines, or [] if nothing useful. */
  async function prefetchMemories(
    sessionID: string,
    buffer: BufferEntry[],
  ): Promise<string[]> {
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
    return searchMemories(query);
  }

  /**
   * Classify the session buffer and store memorable facts via engram.
   *
   * When `compactionContext` is provided (from `experimental.session.compacting`),
   * it is used directly as the excerpt — this is the highest-signal path because
   * the context contains the full conversation that is about to be summarised,
   * including any existing summary messages. The buffer is cleared but not used.
   *
   * When called without `compactionContext` (e.g. from `session.status` idle),
   * the buffer is drained and used to build the excerpt instead. Classification
   * is skipped if fewer than `min_messages` are buffered.
   */
  async function classifyAndStore(sessionID: string, compactionContext?: string[]): Promise<void> {
    clog("info", "classifyAndStore called", { sessionID, fromCompaction: !!compactionContext });

    if (!autoClassify.enabled) {
      clog("info", "auto-classification disabled, skipping");
      return;
    }
    if (!autoClassify.model) {
      clog("warn", "no model configured for classification, skipping");
      return;
    }
    if (classifierSessions.has(sessionID)) {
      clog("debug", "classifier session, skipping", { sessionID });
      return;
    }

    let excerpt: string;

    if (compactionContext) {
      // Compaction path: use the context provided by opencode directly.
      // This is the full conversation being compacted — the richest possible signal.
      // Compaction always has full context, so it bypasses min_messages constraints.
      // Clear the buffer so the idle path doesn't re-classify the same content.
      const buffer = sessionBuffers.get(sessionID);
      if (buffer) buffer.splice(0);
      excerpt = compactionContext.join("\n\n");
    } else {
      // Idle path: drain the message buffer accumulated since last classification.
      const buffer = sessionBuffers.get(sessionID);
      const count = buffer?.length ?? 0;
      clog("info", "buffer state", { sessionID, entries: count });

      if (!buffer || count === 0) {
        clog("info", "buffer empty, skipping classification", { sessionID });
        return;
      }
      if (count < autoClassify.minMessages) {
        clog("info", "buffer below min_messages threshold, skipping classification", {
          sessionID,
          count,
          minMessages: autoClassify.minMessages,
        });
        return;
      }

      const entries = buffer.splice(0);
      clog("info", "drained buffer", { sessionID, entries: entries.length });

      // Summaries first — they are higher signal than raw exchanges.
      const summaries = entries.filter((e) => e.isSummary);
      const rest = entries.filter((e) => !e.isSummary);
      const ordered = [...summaries, ...rest];

      excerpt = ordered
        .map((e) => {
          const label = e.isSummary ? `${e.role} [SUMMARY]` : e.role;
          return `${label}: ${e.text}`;
        })
        .join("\n\n");
    }

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
      clog("info", "prompting classifier", { classifierSessionID, model: `${autoClassify.model.providerID}/${autoClassify.model.modelID}` });
      const promptRes = await client.session.prompt({
        path: { id: classifierSessionID },
        body: {
          model: {
            modelID: autoClassify.model.modelID,
            providerID: autoClassify.model.providerID,
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
        if (stored >= autoClassify.maxMemories) break;
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

       clog("info", "engram config", {
         config_file: pluginConfig.config_file,
       });

      // Reload memory types in case engram state changed.
      try {
        memoryTypes = loadMemoryTypes();
        clog("info", "loaded memory types", { count: memoryTypes.length, types: memoryTypes.map((t) => t.name) });
      } catch (err) {
        throw new Error(`failed to load engram memory types: ${err}`);
      }

      // Resolve classification model: engram config > small_model > null (disabled).
      const ac = pluginConfig.auto_classify ?? {};
      const resolvedModel =
        parseModel(ac.model ?? "") ??
        parseModel(cfg.small_model ?? "") ??
        null;

      if (!resolvedModel) {
        clog("warn", "no model configured for classification — auto-classification will not run");
      } else {
        clog("info", "classification model resolved", {
          providerID: resolvedModel.providerID,
          modelID: resolvedModel.modelID,
          source: ac.model ? "engram config" : "small_model",
        });
      }

      // Merge user-supplied auto_classify settings over defaults.
      autoClassify = {
        enabled:     ac.enabled      ?? AUTO_CLASSIFY_DEFAULTS.enabled,
        minMessages: ac.min_messages ?? AUTO_CLASSIFY_DEFAULTS.minMessages,
        maxMemories: ac.max_memories ?? AUTO_CLASSIFY_DEFAULTS.maxMemories,
        temperature: ac.temperature  ?? AUTO_CLASSIFY_DEFAULTS.temperature,
        searchLimit: ac.search_limit ?? AUTO_CLASSIFY_DEFAULTS.searchLimit,
        model:       resolvedModel,
      };
      clog("info", "auto_classify config", {
        enabled: autoClassify.enabled,
        minMessages: autoClassify.minMessages,
        maxMemories: autoClassify.maxMemories,
        temperature: autoClassify.temperature,
        searchLimit: autoClassify.searchLimit,
        model: resolvedModel ? `${resolvedModel.providerID}/${resolvedModel.modelID}` : null,
      });

      // Inject the engram-classifier agent.
      if (!cfg.agent) cfg.agent = {};
      Object.assign(cfg.agent, {
        "engram-classifier": {
          description: "Internal: classifies conversation excerpts into memories for engram. Outputs JSON only.",
          mode: "subagent",
          prompt: buildClassifierPrompt(memoryTypes, autoClassify.maxMemories),
          temperature: autoClassify.temperature,
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
        prefetchMemories(sessionID, buffer).catch(() => []),
      );
    },

    async event({ event }: { event: { type: string; properties?: { sessionID: string; status?: { type: string } } } }) {
      const { sessionID } = event.properties || {};
      if (!sessionID) return;
      if (classifierSessions.has(sessionID)) {
        clog("debug", "event for classifier session, ignoring", { type: event.type, sessionID });
        return;
      }

      clog("debug", "event received", { type: event.type, sessionID });

      // session.idle is deprecated as of opencode Nov 2025; the replacement is
      // session.status with properties.status.type === "idle".
      const isIdle =
        event.type === "session.status" && event.properties?.status?.type === "idle";

      if (isIdle) {
        clog("info", "session idle — triggering classification", { sessionID });
        classifyAndStore(sessionID).catch((err) => {
          clog("error", "classifyAndStore failed", { sessionID, error: String(err) });
        });
        memoryCache.delete(sessionID);
      } else if (event.type === "session.compacted") {
        // Classification was already kicked off in experimental.session.compacting
        // using the full context. Just invalidate the memory cache so the next
        // system transform picks up any newly stored memories.
        clog("info", "session.compacted — invalidating memory cache", { sessionID });
        memoryCache.delete(sessionID);
      }
    },

    async "experimental.session.compacting"({ sessionID }: { sessionID: string }, output: { context: string[] }) {
      clog("info", "experimental.session.compacting called", { sessionID });
      try {
        // Inject relevant existing memories so they survive the compaction summary.
        const cached = memoryCache.get(sessionID);
        const buffer = sessionBuffers.get(sessionID) ?? [];
        const lines = cached
          ? await cached
          : await prefetchMemories(sessionID, buffer).catch(() => []);

        clog("info", "compacting memory lines", { sessionID, count: lines.length });
        if (lines.length > 0) {
          output.context.push(
            `## Relevant memories from your knowledge base\n\n${lines.join("\n")}`
          );
        }

        // Classify the full compaction context while we have it. This is the
        // highest-signal moment — the context contains everything about to be
        // summarised, so we don't have to guess at ordering with session.compacted.
        classifyAndStore(sessionID, output.context).catch((e) => {
          clog("error", "background classification failed", { sessionID, error: String(e) });
        });
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
          : await prefetchMemories(sessionID, buffer).catch(() => []);

        clog("debug", "system.transform memory lines", { sessionID, count: lines.length });
        if (lines.length === 0) return;

        output.system.push(
          `## Relevant memories from your knowledge base\n\n${lines.join("\n")}`
        );
      } catch (e) {
        clog("error", "system.transform hook failed", { sessionID, error: String(e) });
      }
    },

    async "tool.execute.after"(
      input: { tool: string; sessionID: string; callID: string; args: any },
      output: { title: string; output: string; metadata: any }
    ) {
      const { sessionID, tool } = input;
      if (classifierSessions.has(sessionID)) return;
      if (tool === "engram-search" || tool === "engram-add") return;

      const toolKeyArgs = ["filePath", "command", "path", "query"]
        .map((key) => input.args[key])
        .filter((v) => v !== undefined)
        .join(" ");

      const toolName = tool || "";
      const resultPreview = (output.output ?? "").toString().trim().substring(0, 200);

      const queryParts = [toolName, toolKeyArgs, resultPreview].filter(Boolean);
      const query = queryParts.join(" ");

      try {
        const results = await searchMemories(query);
        memoryCache.set(sessionID, Promise.resolve(results));
        clog("debug", "tool.execute.after memory update", { tool, sessionID, queryLength: query.length, resultCount: results.length });
      } catch (e) {
        clog("debug", "tool.execute.after search failed (non-fatal)", { tool, error: String(e) });
      }
    },

    tool: {
      "engram-search": {
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

      "engram-add": {
        description:
          "Save a memory to the knowledge base. " +
          memoryTypes.map((t) => `Use '${t.name}' for ${t.description.toLowerCase().replace(/\.$/, "")}.`).join(" "),
        parameters: {
          type: "object",
          properties: {
            content: {
              type: "string",
              description: "The memory content to save",
            },
            type: {
              type: "string",
              enum: memoryTypes.map((t) => t.name),
              description: memoryTypes.map((t) => `${t.name} = ${t.description}`).join("; "),
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


  };
};
