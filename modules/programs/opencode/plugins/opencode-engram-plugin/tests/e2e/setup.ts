/**
 * E2E test setup helpers.
 *
 * Starts a real OpenCode server with the engram plugin loaded. All temporary
 * data (engram database, memory files, TOML config) is written under the
 * system's temp directory and passed to the plugin via the `OPENCODE_ENGRAM_CONFIG`
 * environment variable — no home-directory files needed.
 *
 * Requirements:
 * - `opencode` binary must be on PATH
 * - `engram` binary must be on PATH (plugin calls it during config())
 *
 * Usage:
 *   const srv = await startOpencodeWithPlugin();
 *   try {
 *     // ... assertions ...
 *   } finally {
 *     srv.server.close();
 *   }
 */

import { mkdtempSync, mkdirSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { resolve, join } from "node:path";
import { createOpencodeClient, createOpencodeServer } from "@opencode-ai/sdk";

// ─── Constants ────────────────────────────────────────────────────────────────

/** Plugin path passed to OpenCode — must be a file:// URI pointing at the
 *  package directory (the one containing package.json), matching how the Nix
 *  module configures it in production. */
const PLUGIN_PATH = `file://${resolve(import.meta.dir, "../..")}`;

/** Timeout for the OpenCode server to start (ms). */
const SERVER_START_TIMEOUT_MS = 30_000;

// ─── Types ────────────────────────────────────────────────────────────────────

/** Result of starting an OpenCode server with the plugin loaded. */
export interface OpencodeTestServer {
  /** SDK client connected to the running server. */
  client: ReturnType<typeof createOpencodeClient>;
  /** Handle to the running server process. */
  server: { url: string; close: () => void };
  /** Path to the temporary engram database used by this server. */
  engramDb: string;
}

// ─── Public ───────────────────────────────────────────────────────────────────

/**
 * Starts a real OpenCode server with the engram plugin configured.
 *
 * Each call gets isolated temp paths under the system's tmpdir:
 *   /tmp/opencode-engram-e2e-XXXXX/
 *     engram.toml   ← db + memory_path isolated here
 *     engram.db     ← isolated SQLite database
 *     memories/     ← isolated memory markdown files
 *
 * Isolation is achieved by passing `engram.config_file` and `engram.db`
 * directly in the opencode config block — no environment variables or
 * home-directory files are written.
 *
 * @param extraConfig  Additional fields merged into the opencode config (e.g.
 *                     `{ small_model: "anthropic/claude-haiku-4-5" }` to enable
 *                     the classifier in memory-classification tests).
 *
 * Always call `server.close()` in a `finally` block.
 */
export async function startOpencodeWithPlugin(
  extraConfig: Record<string, unknown> = {},
): Promise<OpencodeTestServer> {
  const { server, engramDb } = await startServer(extraConfig);
  const client = createOpencodeClient({ baseUrl: server.url });
  return { client, server, engramDb };
}

// ─── Private ──────────────────────────────────────────────────────────────────

async function startServer(
  extraConfig: Record<string, unknown> = {},
): Promise<{ server: { url: string; close: () => void }; engramDb: string }> {
  const tmpDir = mkdtempSync(join(tmpdir(), "opencode-engram-e2e-"));

  const engramDb = join(tmpDir, "engram.db");
  const engramToml = join(tmpDir, "engram.toml");
  const engramMemoryDir = join(tmpDir, "memories");
  const engramConfigJson = join(tmpDir, "engram.json");

  mkdirSync(engramMemoryDir, { recursive: true });
  writeFileSync(
    engramToml,
    `db = "${engramDb}"\nmemory_path = "${engramMemoryDir}"\n`,
    "utf8",
  );
  writeFileSync(
    engramConfigJson,
    JSON.stringify({ config_file: engramToml }),
    "utf8",
  );

  // Save and restore OPENCODE_ENGRAM_CONFIG for test isolation.
  const originalEngramConfig = process.env.OPENCODE_ENGRAM_CONFIG;
  process.env.OPENCODE_ENGRAM_CONFIG = engramConfigJson;

  try {
    const server = await createOpencodeServer({
      hostname: "127.0.0.1",
      port: 0,
      timeout: SERVER_START_TIMEOUT_MS,
      config: {
        logLevel: "WARN",
        plugin: [PLUGIN_PATH],
        ...extraConfig,
      },
    });

    // Wrap server.close() to restore the env var.
    const originalClose = server.close;
    server.close = () => {
      process.env.OPENCODE_ENGRAM_CONFIG = originalEngramConfig;
      return originalClose.call(server);
    };

    return { server, engramDb };
  } catch (err) {
    process.env.OPENCODE_ENGRAM_CONFIG = originalEngramConfig;
    throw err;
  }
}
