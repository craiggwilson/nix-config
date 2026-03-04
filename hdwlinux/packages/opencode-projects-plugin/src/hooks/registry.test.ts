import { describe, it, expect, beforeEach, mock } from "bun:test";
import { HookRegistry } from "./registry.js";
import { createMockLogger } from "../utils/testing/index.js";

describe("HookRegistry", () => {
	let registry: HookRegistry;

	beforeEach(() => {
		registry = new HookRegistry();
	});

	describe("register / buildHooks — single handler", () => {
		it("calls the registered handler with input and output", async () => {
			const called: unknown[] = [];

			registry.register<"shell.env">({
				name: "shell.env",
				handler: (input, output) => {
					called.push(input);
					output.env.MY_VAR = "hello";
				},
			});

			const hooks = registry.buildHooks();
			const output = { env: {} as Record<string, string> };
			await (hooks["shell.env"] as (i: unknown, o: unknown) => Promise<void>)(
				{ cwd: "/tmp" },
				output,
			);

			expect(called).toEqual([{ cwd: "/tmp" }]);
			expect(output.env.MY_VAR).toBe("hello");
		});

		it("calls a single-argument hook (event) with only input", async () => {
			const received: unknown[] = [];

			registry.register<"event">({
				name: "event",
				handler: (input) => {
					received.push(input);
				},
			});

			const hooks = registry.buildHooks();
			const fakeEvent = {
				event: { type: "session.idle", properties: { sessionID: "s1" } },
			};
			await (hooks.event as (i: unknown) => Promise<void>)(fakeEvent);

			expect(received).toEqual([fakeEvent]);
		});

		it("calls a single-argument hook (config) with only input", async () => {
			const received: unknown[] = [];

			registry.register<"config">({
				name: "config",
				handler: (input) => {
					received.push(input);
				},
			});

			const hooks = registry.buildHooks();
			const fakeConfig = { theme: "dark" };
			await (hooks.config as (i: unknown) => Promise<void>)(fakeConfig);

			expect(received).toEqual([fakeConfig]);
		});
	});

	describe("register / buildHooks — multiple handlers, priority ordering", () => {
		it("runs handlers in ascending priority order", async () => {
			const callOrder: string[] = [];

			registry.register<"shell.env">({
				name: "shell.env",
				priority: 200,
				handler: () => {
					callOrder.push("low-priority");
				},
			});

			registry.register<"shell.env">({
				name: "shell.env",
				priority: 50,
				handler: () => {
					callOrder.push("high-priority");
				},
			});

			registry.register<"shell.env">({
				name: "shell.env",
				priority: 100,
				handler: () => {
					callOrder.push("default-priority");
				},
			});

			const hooks = registry.buildHooks();
			await (hooks["shell.env"] as (i: unknown, o: unknown) => Promise<void>)(
				{ cwd: "/" },
				{ env: {} },
			);

			expect(callOrder).toEqual([
				"high-priority",
				"default-priority",
				"low-priority",
			]);
		});

		it("uses registration order as tiebreaker for equal priorities", async () => {
			const callOrder: string[] = [];

			registry.register<"shell.env">({
				name: "shell.env",
				priority: 100,
				handler: () => {
					callOrder.push("first");
				},
			});

			registry.register<"shell.env">({
				name: "shell.env",
				priority: 100,
				handler: () => {
					callOrder.push("second");
				},
			});

			registry.register<"shell.env">({
				name: "shell.env",
				priority: 100,
				handler: () => {
					callOrder.push("third");
				},
			});

			const hooks = registry.buildHooks();
			await (hooks["shell.env"] as (i: unknown, o: unknown) => Promise<void>)(
				{ cwd: "/" },
				{ env: {} },
			);

			expect(callOrder).toEqual(["first", "second", "third"]);
		});

		it("treats missing priority as 100", async () => {
			const callOrder: string[] = [];

			registry.register<"shell.env">({
				name: "shell.env",
				handler: () => {
					callOrder.push("no-priority");
				},
			});

			registry.register<"shell.env">({
				name: "shell.env",
				priority: 50,
				handler: () => {
					callOrder.push("priority-50");
				},
			});

			const hooks = registry.buildHooks();
			await (hooks["shell.env"] as (i: unknown, o: unknown) => Promise<void>)(
				{ cwd: "/" },
				{ env: {} },
			);

			expect(callOrder).toEqual(["priority-50", "no-priority"]);
		});

		it("each handler sees mutations made by earlier handlers", async () => {
			registry.register<"experimental.chat.system.transform">({
				name: "experimental.chat.system.transform",
				priority: 10,
				handler: (_input, output) => {
					output.system.push("first");
				},
			});

			registry.register<"experimental.chat.system.transform">({
				name: "experimental.chat.system.transform",
				priority: 20,
				handler: (_input, output) => {
					output.system.push("second");
				},
			});

			const hooks = registry.buildHooks();
			const output = { system: [] as string[] };
			await (
				hooks["experimental.chat.system.transform"] as (
					i: unknown,
					o: unknown,
				) => Promise<void>
			)({}, output);

			expect(output.system).toEqual(["first", "second"]);
		});
	});

	describe("error resilience", () => {
		it("continues to the next handler when one throws", async () => {
			const log = createMockLogger();
			const callOrder: string[] = [];

			registry.register<"shell.env">({
				name: "shell.env",
				priority: 10,
				handler: () => {
					throw new Error("handler failed");
				},
			});

			registry.register<"shell.env">({
				name: "shell.env",
				priority: 20,
				handler: () => {
					callOrder.push("second");
				},
			});

			const hooks = registry.buildHooks(log);
			await (hooks["shell.env"] as (i: unknown, o: unknown) => Promise<void>)(
				{ cwd: "/" },
				{ env: {} },
			);

			expect(callOrder).toEqual(["second"]);
		});

		it("logs a warning when a handler throws", async () => {
			const log = createMockLogger();
			const warnSpy = mock(log.warn);
			log.warn = warnSpy;

			registry.register<"shell.env">({
				name: "shell.env",
				handler: () => {
					throw new Error("boom");
				},
			});

			const hooks = registry.buildHooks(log);
			await (hooks["shell.env"] as (i: unknown, o: unknown) => Promise<void>)(
				{ cwd: "/" },
				{ env: {} },
			);

			expect(warnSpy).toHaveBeenCalledTimes(1);
		});

		it("does not throw when all handlers succeed", async () => {
			registry.register<"shell.env">({
				name: "shell.env",
				handler: (_input, output) => {
					output.env.X = "1";
				},
			});

			const hooks = registry.buildHooks();
			const output = { env: {} as Record<string, string> };

			await expect(
				(hooks["shell.env"] as (i: unknown, o: unknown) => Promise<void>)(
					{ cwd: "/" },
					output,
				),
			).resolves.toBeUndefined();

			expect(output.env.X).toBe("1");
		});
	});

	describe("buildHooks — shape", () => {
		it("omits hook names with no registered handlers", () => {
			registry.register<"shell.env">({
				name: "shell.env",
				handler: () => {},
			});

			const hooks = registry.buildHooks();

			expect(Object.keys(hooks)).toEqual(["shell.env"]);
			expect(hooks.event).toBeUndefined();
			expect(hooks.config).toBeUndefined();
		});

		it("returns an empty object when no handlers are registered", () => {
			const hooks = registry.buildHooks();
			expect(hooks).toEqual({});
		});

		it("returns functions for all registered hook names", () => {
			registry.register<"shell.env">({ name: "shell.env", handler: () => {} });
			registry.register<"event">({ name: "event", handler: () => {} });
			registry.register<"config">({ name: "config", handler: () => {} });

			const hooks = registry.buildHooks();

			expect(typeof hooks["shell.env"]).toBe("function");
			expect(typeof hooks.event).toBe("function");
			expect(typeof hooks.config).toBe("function");
		});
	});
});
