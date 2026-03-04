/**
 * Tests for ConfigManager
 */

import { describe, it, expect, beforeEach, afterEach } from "bun:test";
import * as fs from "node:fs/promises";
import * as path from "node:path";
import * as os from "node:os";

import {
	ConfigManager,
	getDataDir,
	ConfigLoadError,
} from "./config-manager.js";
import {
	PROJECTS_PATH,
	BEADS_PATH,
	DEFAULT_DELEGATION_TIMEOUT_MS,
	DEFAULT_SMALL_MODEL_TIMEOUT_MS,
	DEFAULT_TEAM_MAX_SIZE,
	DEFAULT_TEAM_RETRY_FAILED_MEMBERS,
} from "./config-schema.js";

describe("ConfigManager", () => {
	let tempDir: string;
	let originalXdgConfig: string | undefined;
	let originalXdgData: string | undefined;

	beforeEach(async () => {
		tempDir = await fs.mkdtemp(path.join(os.tmpdir(), "config-test-"));
		originalXdgConfig = process.env.XDG_CONFIG_HOME;
		originalXdgData = process.env.XDG_DATA_HOME;
		process.env.XDG_CONFIG_HOME = path.join(tempDir, "config");
		process.env.XDG_DATA_HOME = path.join(tempDir, "data");
	});

	afterEach(async () => {
		if (originalXdgConfig !== undefined) {
			process.env.XDG_CONFIG_HOME = originalXdgConfig;
		} else {
			delete process.env.XDG_CONFIG_HOME;
		}
		if (originalXdgData !== undefined) {
			process.env.XDG_DATA_HOME = originalXdgData;
		} else {
			delete process.env.XDG_DATA_HOME;
		}
		await fs.rm(tempDir, { recursive: true, force: true });
	});

	describe("load", () => {
		it("returns default config when no config file exists", async () => {
			const result = await ConfigManager.load();

			expect(result.ok).toBe(true);
			if (result.ok) {
				expect(result.value.getDefaultStorage()).toBe("local");
				expect(result.value.getDefaultVCS()).toBe("auto");
				expect(result.value.getDelegationTimeoutMs()).toBe(
					DEFAULT_DELEGATION_TIMEOUT_MS,
				);
				expect(result.value.getSmallModelTimeoutMs()).toBe(
					DEFAULT_SMALL_MODEL_TIMEOUT_MS,
				);
				expect(result.value.getDefaultDiscussionStrategy()).toBe("fixedRound");
				const fixedRoundSettings =
					result.value.getTeamDiscussionSettings("fixedRound");
				expect(fixedRoundSettings.type).toBe("fixedRound");
				if (fixedRoundSettings.type === "fixedRound") {
					expect(fixedRoundSettings.roundTimeoutMs).toBeGreaterThan(0);
				}
				expect(result.value.getTeamMaxSize()).toBe(DEFAULT_TEAM_MAX_SIZE);
				expect(result.value.getTeamRetryFailedMembers()).toBe(
					DEFAULT_TEAM_RETRY_FAILED_MEMBERS,
				);
				expect(result.value.getWorktreeSettings().autoCleanup).toBe(true);
			}
		});

		it("loads config from file", async () => {
			const configDir = path.join(tempDir, "config", "opencode");
			await fs.mkdir(configDir, { recursive: true });
			await fs.writeFile(
				path.join(configDir, "opencode-projects.json"),
				JSON.stringify({
					version: "0.9.0",
					defaults: { storage: "local", vcs: "jj" },
				}),
			);

			const result = await ConfigManager.load();

			expect(result.ok).toBe(true);
			if (result.ok) {
				expect(result.value.getDefaultStorage()).toBe("local");
				expect(result.value.getDefaultVCS()).toBe("jj");
			}
		});

		it("returns default config for invalid JSON", async () => {
			const configDir = path.join(tempDir, "config", "opencode");
			await fs.mkdir(configDir, { recursive: true });
			await fs.writeFile(
				path.join(configDir, "opencode-projects.json"),
				"not valid json",
			);

			const result = await ConfigManager.load();

			expect(result.ok).toBe(false);
		});

		it("returns default config for invalid schema", async () => {
			const configDir = path.join(tempDir, "config", "opencode");
			await fs.mkdir(configDir, { recursive: true });
			await fs.writeFile(
				path.join(configDir, "opencode-projects.json"),
				JSON.stringify({
					version: "0.9.0",
					defaults: { storage: "invalid" },
				}),
			);

			const result = await ConfigManager.load();

			expect(result.ok).toBe(true);
			if (result.ok) {
				expect(result.value.getDefaultStorage()).toBe("local");
			}
		});
	});

	describe("loadOrThrow", () => {
		it("returns config manager on success", async () => {
			const config = await ConfigManager.loadOrThrow();
			expect(config).toBeDefined();
			expect(config.getDefaultStorage()).toBeDefined();
		});

		it("throws on load error", async () => {
			const configDir = path.join(tempDir, "config", "opencode");
			await fs.mkdir(configDir, { recursive: true });
			await fs.writeFile(
				path.join(configDir, "opencode-projects.json"),
				"invalid json",
			);

			await expect(ConfigManager.loadOrThrow()).rejects.toThrow(
				ConfigLoadError,
			);
		});
	});

	describe("save", () => {
		it("saves config to file", async () => {
			const config = await ConfigManager.loadOrThrow();
			config.setProjectOverrides("test-project", { storage: "local" });

			await config.save();

			const configPath = path.join(
				tempDir,
				"config",
				"opencode",
				"opencode-projects.json",
			);
			const content = await fs.readFile(configPath, "utf8");
			const parsed = JSON.parse(content);
			expect(parsed.projects["test-project"].storage).toBe("local");
		});
	});

	describe("getter methods", () => {
		it("getDefaultStorage returns storage setting", async () => {
			const config = await ConfigManager.loadOrThrow();
			expect(["local", "global"]).toContain(config.getDefaultStorage());
		});

		it("getDefaultVCS returns vcs setting", async () => {
			const config = await ConfigManager.loadOrThrow();
			expect(["auto", "git", "jj"]).toContain(config.getDefaultVCS());
		});

		it("getProjectOverrides returns undefined for unknown project", async () => {
			const config = await ConfigManager.loadOrThrow();
			expect(config.getProjectOverrides("nonexistent")).toBeUndefined();
		});

		it("getProjectOverrides returns overrides for known project", async () => {
			const configDir = path.join(tempDir, "config", "opencode");
			await fs.mkdir(configDir, { recursive: true });
			await fs.writeFile(
				path.join(configDir, "opencode-projects.json"),
				JSON.stringify({
					version: "0.9.0",
					projects: { "my-project": { storage: "local" } },
				}),
			);

			const config = await ConfigManager.loadOrThrow();
			const overrides = config.getProjectOverrides("my-project");

			expect(overrides).toBeDefined();
			expect(overrides?.storage).toBe("local");
		});

		it("setProjectOverrides updates project config", async () => {
			const config = await ConfigManager.loadOrThrow();

			config.setProjectOverrides("new-project", { storage: "global" });

			expect(config.getProjectOverrides("new-project")?.storage).toBe("global");
		});

		it("getWorktreeSettings returns worktree config", async () => {
			const config = await ConfigManager.loadOrThrow();
			const settings = config.getWorktreeSettings();

			expect(typeof settings.autoCleanup).toBe("boolean");
		});

		it("getDelegationTimeoutMs returns timeout", async () => {
			const config = await ConfigManager.loadOrThrow();
			const timeout = config.getDelegationTimeoutMs();

			expect(typeof timeout).toBe("number");
			expect(timeout).toBeGreaterThan(0);
		});

		it("getSmallModelTimeoutMs returns timeout", async () => {
			const config = await ConfigManager.loadOrThrow();
			const timeout = config.getSmallModelTimeoutMs();

			expect(typeof timeout).toBe("number");
			expect(timeout).toBeGreaterThan(0);
		});

		it("getDefaultDiscussionStrategy returns strategy type", async () => {
			const config = await ConfigManager.loadOrThrow();
			const strategy = config.getDefaultDiscussionStrategy();

			expect(["fixedRound", "dynamicRound", "realtime"]).toContain(strategy);
		});

		it("getTeamDiscussionSettings returns settings for each strategy type", async () => {
			const config = await ConfigManager.loadOrThrow();

			const fixedRound = config.getTeamDiscussionSettings("fixedRound");
			expect(fixedRound.type).toBe("fixedRound");
			if (fixedRound.type === "fixedRound") {
				expect(fixedRound.roundTimeoutMs).toBeGreaterThan(0);
			}

			const convergence = config.getTeamDiscussionSettings("dynamicRound");
			expect(convergence.type).toBe("dynamicRound");
			if (convergence.type === "dynamicRound") {
				expect(convergence.roundTimeoutMs).toBeGreaterThan(0);
			}

			const realtime = config.getTeamDiscussionSettings("realtime");
			expect(realtime.type).toBe("realtime");
			if (realtime.type === "realtime") {
				expect(realtime.promptTimeoutMs).toBeGreaterThan(0);
				expect(realtime.pollIntervalMs).toBeGreaterThan(0);
				expect(realtime.maxWaitTimeMs).toBeGreaterThan(0);
			}
		});

		it("getTeamMaxSize returns max size", async () => {
			const config = await ConfigManager.loadOrThrow();
			const maxSize = config.getTeamMaxSize();

			expect(typeof maxSize).toBe("number");
			expect(maxSize).toBeGreaterThan(0);
		});

		it("getTeamRetryFailedMembers returns boolean", async () => {
			const config = await ConfigManager.loadOrThrow();
			const retry = config.getTeamRetryFailedMembers();

			expect(typeof retry).toBe("boolean");
		});
	});

	describe("directory resolution", () => {
		it("getGlobalProjectsDir returns data directory path", async () => {
			const config = await ConfigManager.loadOrThrow();
			const dir = config.getGlobalProjectsDir();

			expect(dir).toContain("data");
			expect(dir).toContain("opencode");
			expect(dir).toContain("projects");
		});

		it("getLocalProjectsDir returns repo-relative path", async () => {
			const config = await ConfigManager.loadOrThrow();
			const dir = config.getLocalProjectsDir("/my/repo");

			expect(dir).toBe(`/my/repo/${PROJECTS_PATH}`);
		});

		it("resolveProjectDir uses local storage by default", async () => {
			const config = await ConfigManager.loadOrThrow();
			const dir = config.resolveProjectDir("my-project", "/my/repo");

			expect(dir).toBe(`/my/repo/${PROJECTS_PATH}/my-project`);
		});

		it("resolveProjectDir uses global storage when specified", async () => {
			const config = await ConfigManager.loadOrThrow();
			const dir = config.resolveProjectDir("my-project", "/my/repo", "global");

			expect(dir).toContain("data");
			expect(dir).toContain("my-project");
		});

		it("resolveProjectDir uses local storage when specified", async () => {
			const config = await ConfigManager.loadOrThrow();
			const dir = config.resolveProjectDir("my-project", "/my/repo", "local");

			expect(dir).toBe(`/my/repo/${PROJECTS_PATH}/my-project`);
		});

		it("resolveProjectDir uses project overrides", async () => {
			const config = await ConfigManager.loadOrThrow();
			config.setProjectOverrides("override-project", { storage: "local" });

			const dir = config.resolveProjectDir("override-project", "/my/repo");

			expect(dir).toBe(`/my/repo/${PROJECTS_PATH}/override-project`);
		});

		it("resolveBeadsDir returns beads subdirectory", async () => {
			const config = await ConfigManager.loadOrThrow();
			const dir = config.resolveBeadsDir("my-project", "/my/repo", "local");

			expect(dir).toBe(`/my/repo/${PROJECTS_PATH}/my-project/${BEADS_PATH}`);
		});
	});
});

describe("getDataDir", () => {
	it("uses XDG_DATA_HOME when set", () => {
		const original = process.env.XDG_DATA_HOME;
		process.env.XDG_DATA_HOME = "/custom/data";

		const dir = getDataDir();

		expect(dir).toBe("/custom/data/opencode");

		if (original !== undefined) {
			process.env.XDG_DATA_HOME = original;
		} else {
			delete process.env.XDG_DATA_HOME;
		}
	});

	it("falls back to ~/.local/share when XDG_DATA_HOME not set", () => {
		const original = process.env.XDG_DATA_HOME;
		delete process.env.XDG_DATA_HOME;

		const dir = getDataDir();

		expect(dir).toContain(".local/share/opencode");

		if (original !== undefined) {
			process.env.XDG_DATA_HOME = original;
		}
	});
});
