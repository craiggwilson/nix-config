/**
 * Tests for ConfigManager
 */

import { test } from "bun:test";
import { ConfigManager } from "../src/config.js";
import { tmpdir } from "os";
import { join } from "path";
import { mkdirSync, rmSync } from "fs";

test("ConfigManager loads default config", async () => {
  const tempDir = join(tmpdir(), `opencode-test-${Date.now()}`);
  mkdirSync(tempDir, { recursive: true });

  try {
    const manager = new ConfigManager(tempDir);
    const config = manager.load("test-plugin", { defaultValue: "test" });

    if (config.defaultValue !== "test") {
      throw new Error("Default config not loaded");
    }
  } finally {
    rmSync(tempDir, { recursive: true });
  }
});

test("ConfigManager saves and loads config", async () => {
  const tempDir = join(tmpdir(), `opencode-test-${Date.now()}`);
  mkdirSync(tempDir, { recursive: true });

  try {
    const manager = new ConfigManager(tempDir);
    const testConfig = { setting1: "value1", setting2: 42 };

    manager.save("test-plugin", testConfig);
    const loaded = manager.load("test-plugin");

    if (loaded.setting1 !== "value1" || loaded.setting2 !== 42) {
      throw new Error("Config not saved/loaded correctly");
    }
  } finally {
    rmSync(tempDir, { recursive: true });
  }
});

test("ConfigManager merges repo config with global config", async () => {
  const tempDir = join(tmpdir(), `opencode-test-${Date.now()}`);
  mkdirSync(tempDir, { recursive: true });

  try {
    const manager = new ConfigManager(tempDir);
    const globalConfig = { setting1: "global", setting2: "global" };

    manager.save("test-plugin", globalConfig);

    const repoConfigPath = join(tempDir, "repo-config.json");
    const repoConfig = { setting1: "repo" };

    // Write repo config
    const fs = await import("fs");
    fs.writeFileSync(repoConfigPath, JSON.stringify(repoConfig));

    const merged = manager.mergeWithRepoConfig("test-plugin", repoConfigPath);

    if (merged.setting1 !== "repo" || merged.setting2 !== "global") {
      throw new Error("Config merge failed");
    }
  } finally {
    rmSync(tempDir, { recursive: true });
  }
});
