/**
 * E2E tests: plugin loads successfully in a live OpenCode instance.
 *
 * Verifies that:
 * - The OpenCode server starts without errors when the plugin is loaded
 * - The `engram-search` and `engram-add` tools are registered
 * - The `engram-classifier` agent is injected into the agent registry
 *
 * Requirements:
 * - `opencode` binary must be on PATH
 * - `engram` binary must be on PATH
 * - No LLM API keys required (no prompts are sent)
 *
 * Skip with: SKIP_E2E=1 bun test
 */

import { afterAll, beforeAll, describe, expect, it } from "bun:test";
import type { OpencodeTestServer } from "./setup.ts";
import { startOpencodeWithPlugin } from "./setup.ts";

// ─── Constants ────────────────────────────────────────────────────────────────

const SKIP_E2E = process.env.SKIP_E2E === "1";

const EXPECTED_TOOLS = ["engram-search", "engram-add"] as const;

// ─── Tests ────────────────────────────────────────────────────────────────────

describe.skipIf(SKIP_E2E)("E2E: plugin loads in OpenCode", () => {
  let srv: OpencodeTestServer;

  beforeAll(async () => {
    srv = await startOpencodeWithPlugin();
  }, 60_000);

  afterAll(() => {
    srv?.server.close();
  });

  it("server starts and exposes an HTTP URL", () => {
    // Arrange + Act: server started in beforeAll

    // Assert
    expect(srv.server.url).toBeDefined();
    expect(srv.server.url).toMatch(/^http/);
  });

  it("client can list sessions (server is responsive)", async () => {
    // Act
    const res = await srv.client.session.list();

    // Assert
    expect(res.error).toBeUndefined();
    expect(Array.isArray(res.data)).toBe(true);
  });

  it("tool IDs endpoint responds", async () => {
    // Act
    const res = await srv.client.tool.ids();

    // Assert
    expect(res.error).toBeUndefined();
    expect(Array.isArray(res.data)).toBe(true);
  });

  it.each(EXPECTED_TOOLS)('"%s" tool is registered', async (toolId) => {
    // Act
    const res = await srv.client.tool.ids();

    // Assert
    expect(res.error).toBeUndefined();
    expect(res.data).toContain(toolId);
  });

  it("agents endpoint responds", async () => {
    // Act
    const res = await srv.client.app.agents();

    // Assert
    expect(res.error).toBeUndefined();
    expect(Array.isArray(res.data)).toBe(true);
  });

  it("engram-classifier agent is registered", async () => {
    // Act
    const res = await srv.client.app.agents();

    // Assert
    expect(res.error).toBeUndefined();

    const agents = res.data as Array<{ id?: string; name?: string }>;
    const hasClassifier = agents.some(
      (a) => a.id === "engram-classifier" || a.name === "engram-classifier",
    );
    expect(hasClassifier).toBe(true);
  });
});
