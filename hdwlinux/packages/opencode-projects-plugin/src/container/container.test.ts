import { describe, it, expect, beforeEach } from "bun:test";
import { Token, TypeSafeContainer } from "./index.js";

// ---------------------------------------------------------------------------
// Shared tokens used across tests
// ---------------------------------------------------------------------------

const T = {
	A: new Token<string>("A"),
	B: new Token<number>("B"),
	C: new Token<boolean>("C"),
	D: new Token<string[]>("D"),
	Async: new Token<{ value: string }>("Async"),
};

describe("TypeSafeContainer", () => {
	let container: TypeSafeContainer;

	beforeEach(() => {
		container = new TypeSafeContainer();
	});

	// -------------------------------------------------------------------------
	// Basic registration and resolution
	// -------------------------------------------------------------------------

	describe("basic registration and resolution", () => {
		it("resolves a registered instance", async () => {
			container.registerInstance(T.A, "hello");
			await container.build();

			expect(container.resolve(T.A)).toBe("hello");
		});

		it("resolves a factory with no dependencies", async () => {
			container.register(T.B, [], () => 42);
			await container.build();

			expect(container.resolve(T.B)).toBe(42);
		});

		it("resolves a factory with one dependency", async () => {
			container.registerInstance(T.A, "world");
			container.register(T.B, [T.A], (a) => a.length);
			await container.build();

			expect(container.resolve(T.B)).toBe(5);
		});

		it("resolves a factory with multiple dependencies", async () => {
			container.registerInstance(T.A, "hello");
			container.register(T.B, [], () => 3);
			container.register(T.C, [T.A, T.B], (a, b) => a.length === b);
			await container.build();

			// "hello".length === 3 → false (5 !== 3)
			expect(container.resolve(T.C)).toBe(false);
		});

		it("has() returns true for registered tokens", async () => {
			container.registerInstance(T.A, "x");
			expect(container.has(T.A)).toBe(true);
		});

		it("has() returns false for unregistered tokens", () => {
			expect(container.has(T.A)).toBe(false);
		});
	});

	// -------------------------------------------------------------------------
	// Async factory support
	// -------------------------------------------------------------------------

	describe("async factory support", () => {
		it("resolves an async factory", async () => {
			container.register(T.Async, [], async () => {
				await Promise.resolve();
				return { value: "async-result" };
			});
			await container.build();

			expect(container.resolve(T.Async)).toEqual({ value: "async-result" });
		});

		it("resolves async factory that depends on sync factory", async () => {
			container.registerInstance(T.A, "base");
			container.register(T.Async, [T.A], async (a) => {
				await Promise.resolve();
				return { value: `${a}-async` };
			});
			await container.build();

			expect(container.resolve(T.Async)).toEqual({ value: "base-async" });
		});

		it("propagates async factory errors with context", async () => {
			container.register(T.A, [], async () => {
				throw new Error("factory boom");
			});

			await expect(container.build()).rejects.toThrow(
				'Failed to build service "A"',
			);
		});
	});

	// -------------------------------------------------------------------------
	// Topological ordering
	// -------------------------------------------------------------------------

	describe("topological ordering", () => {
		it("resolves correctly regardless of registration order", async () => {
			// Register in reverse dependency order: D depends on C, C depends on B, B depends on A
			container.register(T.D, [T.C], (c) => [String(c)]);
			container.register(T.C, [T.B], (b) => b > 0);
			container.register(T.B, [T.A], (a) => a.length);
			container.registerInstance(T.A, "hello");

			await container.build();

			expect(container.resolve(T.A)).toBe("hello");
			expect(container.resolve(T.B)).toBe(5);
			expect(container.resolve(T.C)).toBe(true);
			expect(container.resolve(T.D)).toEqual(["true"]);
		});

		it("resolves diamond dependency correctly (shared dep resolved once)", async () => {
			let callCount = 0;
			const CountToken = new Token<number>("Count");
			const LeftToken = new Token<string>("Left");
			const RightToken = new Token<string>("Right");
			const TopToken = new Token<string>("Top");

			container.register(CountToken, [], () => {
				callCount++;
				return callCount;
			});
			container.register(LeftToken, [CountToken], (n) => `left-${n}`);
			container.register(RightToken, [CountToken], (n) => `right-${n}`);
			container.register(
				TopToken,
				[LeftToken, RightToken],
				(l, r) => `${l}+${r}`,
			);

			await container.build();

			// CountToken factory should only be called once
			expect(callCount).toBe(1);
			expect(container.resolve(TopToken)).toBe("left-1+right-1");
		});
	});

	// -------------------------------------------------------------------------
	// Cycle detection
	// -------------------------------------------------------------------------

	describe("cycle detection", () => {
		it("throws on direct self-cycle", async () => {
			container.register(T.A, [T.A], (a) => a);

			await expect(container.build()).rejects.toThrow(
				"Circular dependency detected",
			);
		});

		it("throws on two-node cycle with cycle path in message", async () => {
			container.register(T.A, [T.B], (b) => String(b));
			container.register(T.B, [T.A], (a) => a.length);

			await expect(container.build()).rejects.toThrow(
				"Circular dependency detected",
			);
		});

		it("cycle error message includes token names", async () => {
			const X = new Token<string>("X");
			const Y = new Token<string>("Y");
			const Z = new Token<string>("Z");

			container.register(X, [Y], (y) => y);
			container.register(Y, [Z], (z) => z);
			container.register(Z, [X], (x) => x);

			let message = "";
			try {
				await container.build();
			} catch (e) {
				message = String(e);
			}

			expect(message).toContain("X");
			expect(message).toContain("Y");
			expect(message).toContain("Z");
		});
	});

	// -------------------------------------------------------------------------
	// Frozen container
	// -------------------------------------------------------------------------

	describe("frozen container", () => {
		it("throws when registering after build", async () => {
			container.registerInstance(T.A, "x");
			await container.build();

			expect(() => container.registerInstance(T.A, "y")).toThrow(
				'Cannot register "A": container is already built',
			);
		});

		it("throws when calling register() after build", async () => {
			await container.build();

			expect(() => container.register(T.B, [], () => 1)).toThrow(
				'Cannot register "B": container is already built',
			);
		});

		it("resolves instances before build", () => {
			container.registerInstance(T.A, "x");

			expect(container.resolve(T.A)).toBe("x");
		});

		it("throws when resolving factory-based service before build", () => {
			container.register(T.B, [], () => 42);

			expect(() => container.resolve(T.B)).toThrow(
				'Cannot resolve "B": container must be built first',
			);
		});

		it("throws when resolving unregistered token after build", async () => {
			await container.build();

			expect(() => container.resolve(T.A)).toThrow(
				'Service not registered: "A"',
			);
		});

		it("build() is idempotent", async () => {
			container.registerInstance(T.A, "x");
			await container.build();
			await container.build(); // should not throw

			expect(container.resolve(T.A)).toBe("x");
		});
	});

	// -------------------------------------------------------------------------
	// getDependencyGraph
	// -------------------------------------------------------------------------

	describe("getDependencyGraph", () => {
		it("returns empty map when nothing is registered", () => {
			const graph = container.getDependencyGraph();
			expect(graph.size).toBe(0);
		});

		it("returns correct graph for registered services", () => {
			container.registerInstance(T.A, "x");
			container.register(T.B, [T.A], (a) => a.length);
			container.register(T.C, [T.A, T.B], (a, b) => a.length === b);

			const graph = container.getDependencyGraph();

			expect(graph.get("A")).toEqual([]);
			expect(graph.get("B")).toEqual(["A"]);
			expect(graph.get("C")).toEqual(["A", "B"]);
		});

		it("returns graph before build is called", () => {
			container.register(T.B, [T.A], (a) => a.length);

			const graph = container.getDependencyGraph();
			expect(graph.get("B")).toEqual(["A"]);
		});
	});

	// -------------------------------------------------------------------------
	// onBuild callbacks
	// -------------------------------------------------------------------------

	describe("onBuild", () => {
		it("invokes callback after build with the built container", async () => {
			container.registerInstance(T.A, "hello");

			let receivedValue: string | undefined;
			container.onBuild((c) => {
				receivedValue = c.resolve(T.A);
			});

			await container.build();

			expect(receivedValue).toBe("hello");
		});

		it("invokes callbacks in registration order", async () => {
			container.registerInstance(T.A, "x");

			const order: number[] = [];
			container.onBuild(() => {
				order.push(1);
			});
			container.onBuild(() => {
				order.push(2);
			});
			container.onBuild(() => {
				order.push(3);
			});

			await container.build();

			expect(order).toEqual([1, 2, 3]);
		});

		it("supports async callbacks", async () => {
			container.registerInstance(T.A, "x");

			let called = false;
			container.onBuild(async () => {
				await Promise.resolve();
				called = true;
			});

			await container.build();

			expect(called).toBe(true);
		});

		it("callbacks can resolve factory-based services", async () => {
			container.register(T.B, [], () => 42);

			let resolvedValue: number | undefined;
			container.onBuild((c) => {
				resolvedValue = c.resolve(T.B);
			});

			await container.build();

			expect(resolvedValue).toBe(42);
		});

		it("errors in callbacks propagate from build()", async () => {
			container.onBuild(() => {
				throw new Error("callback boom");
			});

			await expect(container.build()).rejects.toThrow("callback boom");
		});

		it("errors in async callbacks propagate from build()", async () => {
			container.onBuild(async () => {
				await Promise.resolve();
				throw new Error("async callback boom");
			});

			await expect(container.build()).rejects.toThrow("async callback boom");
		});

		it("throws when registering onBuild callback after build", async () => {
			await container.build();

			expect(() => container.onBuild(() => {})).toThrow(
				"Cannot register onBuild callback: container is already built",
			);
		});

		it("does not invoke callbacks on idempotent build() calls", async () => {
			container.registerInstance(T.A, "x");

			let callCount = 0;
			container.onBuild(() => {
				callCount++;
			});

			await container.build();
			await container.build();

			expect(callCount).toBe(1);
		});
	});

	// -------------------------------------------------------------------------
	// Error propagation
	// -------------------------------------------------------------------------

	describe("error propagation", () => {
		it("propagates sync factory errors with context", async () => {
			container.register(T.A, [], () => {
				throw new Error("sync boom");
			});

			await expect(container.build()).rejects.toThrow(
				'Failed to build service "A"',
			);
		});

		it("throws when a dependency is not registered", async () => {
			container.register(T.B, [T.A], (a) => a.length);

			await expect(container.build()).rejects.toThrow(
				'Service "B" depends on unregistered token "A"',
			);
		});
	});
});
