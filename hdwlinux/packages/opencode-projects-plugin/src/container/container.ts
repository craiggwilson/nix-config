import type { Factory, ServiceDescriptor } from "./token.js";
import type { Token } from "./token.js";

/**
 * Two-phase dependency injection container with topological resolution and cycle detection.
 *
 * Phase 1 (registration): Call register() and registerInstance() to declare services.
 * Phase 2 (build): Call build() to validate, sort, resolve all services, then freeze.
 *
 * After build(), the container is immutable — registration throws, resolve() is safe.
 *
 * @example
 *   const container = new TypeSafeContainer()
 *   container.registerInstance(Tokens.Shell, $)
 *   container.register(Tokens.Logger, [Tokens.Shell], (shell) => createLogger(shell))
 *   await container.build()
 *   const logger = container.resolve(Tokens.Logger)
 */
export class TypeSafeContainer {
	private readonly descriptors = new Map<Token<unknown>, ServiceDescriptor>();
	private readonly services = new Map<Token<unknown>, unknown>();
	/** Instances registered via registerInstance(), available before build(). */
	private readonly instances = new Map<Token<unknown>, unknown>();
	private readonly buildCallbacks: Array<
		(container: TypeSafeContainer) => void | Promise<void>
	> = [];
	private frozen = false;

	/**
	 * Registers a service factory with typed dependency injection.
	 *
	 * The factory receives each resolved dependency as a positional argument in
	 * the same order as the deps array. TypeScript infers argument types from
	 * the token array, so no manual type annotations are needed.
	 *
	 * Throws if called after build().
	 */
	register<Deps extends Token<unknown>[], T>(
		token: Token<T>,
		deps: [...Deps],
		factory: Factory<Deps, T>,
	): void {
		this.assertNotFrozen(token.name);
		// The casts are safe: TypeScript enforces the factory signature matches deps at the
		// call site via ResolveTokens<Deps>. The internal map stores everything as unknown
		// because ServiceDescriptor must be homogeneous across all registered types.
		this.descriptors.set(token, {
			token,
			dependencies: deps as Token<unknown>[],
			factory: factory as (...args: unknown[]) => unknown | Promise<unknown>,
		});
	}

	/**
	 * Registers a pre-built instance, bypassing factory resolution.
	 *
	 * Useful for values that are already constructed before the container is
	 * created (e.g., client, shell, repoRoot).
	 *
	 * Throws if called after build().
	 */
	registerInstance<T>(token: Token<T>, value: T): void {
		this.assertNotFrozen(token.name);
		this.instances.set(token, value);
		this.descriptors.set(token, {
			token,
			dependencies: [],
			factory: () => value,
		});
	}

	/**
	 * Resolves a registered service.
	 *
	 * Before build(), only instances registered via registerInstance() can be
	 * resolved — this allows ContainerModule.register() implementations to
	 * access pre-built infrastructure (e.g. HookRegistry) while still
	 * registering factory-based services. After build(), all services are
	 * available.
	 *
	 * Throws for unregistered tokens or for factory-based services before build().
	 */
	resolve<T>(token: Token<T>): T {
		if (!this.frozen) {
			if (this.instances.has(token)) {
				return this.instances.get(token) as T;
			}
			throw new Error(
				`Cannot resolve "${token.name}": container must be built first`,
			);
		}
		if (!this.services.has(token)) {
			throw new Error(`Service not registered: "${token.name}"`);
		}
		return this.services.get(token) as T;
	}

	/**
	 * Registers a callback to be invoked after build() completes, in registration order.
	 *
	 * Use this for post-build wiring that requires fully-resolved services — for example,
	 * registering hook handlers that depend on factory-based services. Callbacks receive
	 * the fully-built container and may be async.
	 *
	 * Throws if called after build().
	 */
	onBuild(
		callback: (container: TypeSafeContainer) => void | Promise<void>,
	): void {
		if (this.frozen) {
			throw new Error(
				"Cannot register onBuild callback: container is already built",
			);
		}
		this.buildCallbacks.push(callback);
	}

	/**
	 * Returns true if the token has been registered.
	 */
	has<T>(token: Token<T>): boolean {
		return this.descriptors.has(token);
	}

	/**
	 * Returns the dependency graph as a map of token names to their dependency names.
	 *
	 * Intended for debugging and visualisation — not for production logic.
	 */
	getDependencyGraph(): Map<string, string[]> {
		const graph = new Map<string, string[]>();
		for (const [token, descriptor] of this.descriptors) {
			graph.set(
				token.name,
				descriptor.dependencies.map((d) => d.name),
			);
		}
		return graph;
	}

	/**
	 * Builds the container: validates dependencies, detects cycles, resolves all
	 * services in topological order, then freezes the container.
	 *
	 * Idempotent — calling build() on an already-built container is a no-op.
	 *
	 * If a factory throws, the error is re-thrown with context identifying which
	 * token failed.
	 */
	async build(): Promise<void> {
		if (this.frozen) return;

		this.validateDependencies();
		this.detectCycles();
		await this.resolveAll();

		this.frozen = true;

		for (const callback of this.buildCallbacks) {
			await callback(this);
		}
	}

	// ---------------------------------------------------------------------------
	// Private helpers
	// ---------------------------------------------------------------------------

	private assertNotFrozen(name: string): void {
		if (this.frozen) {
			throw new Error(`Cannot register "${name}": container is already built`);
		}
	}

	private validateDependencies(): void {
		for (const [token, descriptor] of this.descriptors) {
			for (const dep of descriptor.dependencies) {
				if (!this.descriptors.has(dep)) {
					throw new Error(
						`Service "${token.name}" depends on unregistered token "${dep.name}"`,
					);
				}
			}
		}
	}

	private detectCycles(): void {
		const visited = new Set<Token<unknown>>();
		const stack = new Set<Token<unknown>>();

		const visit = (token: Token<unknown>, path: Token<unknown>[]): void => {
			if (visited.has(token)) return;
			if (stack.has(token)) {
				// Build the cycle path starting from the repeated token.
				const cycleStart = path.indexOf(token);
				const cycle = [...path.slice(cycleStart), token]
					.map((t) => t.name)
					.join(" → ");
				throw new Error(`Circular dependency detected: ${cycle}`);
			}

			stack.add(token);

			const descriptor = this.descriptors.get(token);
			if (descriptor) {
				for (const dep of descriptor.dependencies) {
					visit(dep, [...path, token]);
				}
			}

			stack.delete(token);
			visited.add(token);
		};

		for (const token of this.descriptors.keys()) {
			visit(token, []);
		}
	}

	private async resolveAll(): Promise<void> {
		const resolved = new Set<Token<unknown>>();

		const resolveOne = async (token: Token<unknown>): Promise<void> => {
			if (resolved.has(token)) return;

			const descriptor = this.descriptors.get(token);
			if (!descriptor)
				throw new Error(`No descriptor registered for token "${token.name}"`);

			// Resolve dependencies first (cycle detection already ran, so no infinite loops).
			for (const dep of descriptor.dependencies) {
				await resolveOne(dep);
			}

			const args = descriptor.dependencies.map((dep) => this.services.get(dep));

			let value: unknown;
			try {
				value = await descriptor.factory(...args);
			} catch (cause) {
				throw new Error(
					`Failed to build service "${token.name}": ${String(cause)}`,
					{
						cause,
					},
				);
			}

			this.services.set(token, value);
			resolved.add(token);
		};

		for (const token of this.descriptors.keys()) {
			await resolveOne(token);
		}
	}
}
