# Lazy Resolution for DI Container: Eliminating Registration Order Dependency

**Date:** 2026-03-04  
**Status:** Research Complete  
**Scope:** Explore lazy resolution patterns to eliminate strict registration order requirements in the hand-rolled DI container

---

## Executive Summary

The current DI container design (from `composable-hook-registry-di.md`) requires modules to be registered in strict dependency order: config → vcs → projects → execution → sessions. This is fragile — if someone adds a module and registers it in the wrong order, it silently fails at runtime.

**Key Finding:** Lazy resolution can eliminate this constraint by deferring dependency resolution until after all modules have registered. This research explores five concrete patterns:

1. **Lazy Factory Pattern** — Factories capture container reference and resolve on first call
2. **Two-Phase Initialization** — Explicit "register" and "build" phases with validation
3. **Cycle Detection** — Detect circular dependencies at build time
4. **Async Factory Support** — Extend lazy resolution to support async initialization
5. **Frozen Container** — Immutable container after build phase

**Recommendation:** Implement a **two-phase container** with explicit dependencies and cycle detection. This provides:
- ✅ Registration order independence
- ✅ Clear separation of concerns (register vs. build)
- ✅ Compile-time safety with TypeScript
- ✅ Runtime cycle detection at startup
- ✅ Support for async initialization
- ✅ Eager resolution at build time (all services initialized before use)
- ✅ Minimal API complexity

---

## 1. The Problem: Registration Order Dependency

### Current Design Issues

The current hand-rolled container requires strict registration order:

```typescript
// src/index.ts - CURRENT PATTERN (fragile)
const container = createContainer()

// Must register in this exact order:
await registerConfig(container)      // 1. No dependencies
await registerVcs(container)         // 2. Depends on config
await registerProjects(container)    // 3. Depends on config, vcs
await registerExecution(container)   // 4. Depends on config, vcs, projects
await registerSessions(container)    // 5. Depends on config, projects, execution
```

**Why This Is Fragile:**

1. **Silent Failures** — If someone registers in wrong order, the error only appears at first use:
   ```typescript
   // If registerProjects runs before registerVcs:
   const worktreeManager = container.resolve(Tokens.WorktreeManager)  // ❌ Throws at runtime
   ```

2. **Implicit Dependencies** — The dependency graph is not explicit in code:
   ```typescript
   // Which modules does projects depend on? Must read the code.
   // If you add a new dependency, you must update the registration order.
   ```

3. **No Validation** — The container doesn't validate that all required services are registered:
   ```typescript
   // If you forget to register a service, it fails at first use, not at startup
   ```

4. **Difficult to Extend** — Adding a new module requires understanding the entire dependency graph:
   ```typescript
   // Where should newModule be registered? Before or after projects?
   // If you guess wrong, it silently fails.
   ```

### Example: The Fragility

```typescript
// Scenario: Developer adds a new module
export async function registerNewModule(container: Container): Promise<void> {
  const projectManager = container.resolve(Tokens.ProjectManager)  // ❌ Not registered yet!
  // ...
}

// In src/index.ts, they register it in the wrong place:
await registerConfig(container)
await registerNewModule(container)  // ❌ Fails silently - ProjectManager not registered
await registerVcs(container)
await registerProjects(container)   // ProjectManager registered here, but too late
```

The error only appears when the module is first used, potentially hours or days later.

---

## 2. Lazy Factory Pattern

### Concept

Instead of resolving dependencies eagerly at registration time, factories capture a reference to the container and resolve lazily when first called.

### Implementation

```typescript
// src/container/lazy-container.ts

/**
 * A factory function that resolves dependencies lazily.
 * The factory receives the container and can resolve dependencies when called,
 * not when registered.
 */
type LazyFactory<T> = (container: Container) => T

/**
 * Lazy-resolving container.
 * Services can be registered as factories that capture the container reference.
 * Dependencies are resolved when the service is first accessed, not at registration time.
 */
export class LazyContainer {
  private services = new Map<string | symbol, unknown>()
  private factories = new Map<string | symbol, LazyFactory<unknown>>()
  private resolved = new Set<string | symbol>()

  /**
   * Register a service instance (eager).
   */
  register<T>(token: string | symbol, value: T): void {
    this.services.set(token, value)
  }

  /**
   * Register a lazy factory.
   * The factory is called when the service is first resolved.
   * The factory receives this container, allowing it to resolve dependencies.
   */
  registerLazy<T>(token: string | symbol, factory: LazyFactory<T>): void {
    this.factories.set(token, factory)
  }

  /**
   * Resolve a service, calling its factory if needed.
   * Factories are called exactly once (singleton pattern).
   */
  resolve<T>(token: string | symbol): T {
    // Already resolved? Return cached value
    if (this.services.has(token)) {
      return this.services.get(token) as T
    }

    // Has a factory? Call it and cache the result
    if (this.factories.has(token)) {
      const factory = this.factories.get(token) as LazyFactory<T>
      const instance = factory(this)
      this.services.set(token, instance)  // Cache for future calls
      this.resolved.add(token)
      return instance
    }

    throw new Error(`Service not registered: ${String(token)}`)
  }

  /**
   * Check if a service is registered (factory or instance).
   */
  has(token: string | symbol): boolean {
    return this.services.has(token) || this.factories.has(token)
  }

  /**
   * Get all registered tokens (for validation).
   */
  getTokens(): (string | symbol)[] {
    return Array.from(new Set([
      ...this.services.keys(),
      ...this.factories.keys(),
    ]))
  }
}
```

### Usage Example

```typescript
// src/projects/register.ts

export function registerProjects(container: LazyContainer): void {
  // Register ProjectManager as a lazy factory
  // The factory receives the container and can resolve dependencies
  container.registerLazy(Tokens.ProjectManager, (c) => {
    // These dependencies are resolved when ProjectManager is first accessed,
    // not when registerProjects is called.
    const config = c.resolve(Tokens.Config)
    const vcs = c.resolve(Tokens.WorktreeManager)
    const log = c.resolve(Tokens.Logger)

    return new ProjectManager(config, vcs, log)
  })

  // Register hooks
  container.registerLazy(Tokens.ProjectContextHook, (c) => {
    const projectManager = c.resolve(Tokens.ProjectManager)
    return createProjectContextHook(projectManager)
  })
}
```

### Benefits

✅ **Registration order independence** — Factories resolve dependencies when called, not when registered  
✅ **Lazy initialization** — Services are only created when first accessed  
✅ **Singleton pattern** — Factories are called once; results are cached  
✅ **Simple API** — Just add `registerLazy()` method  

### Limitations

❌ **No cycle detection** — Circular dependencies cause infinite loops at runtime  
❌ **No validation** — Missing dependencies only fail at first use  
❌ **Implicit dependencies** — Dependency graph is hidden in factory code  
❌ **Harder to debug** — Errors occur during resolution, not registration  

---

## 3. Two-Phase Initialization

### Concept

Split initialization into two explicit phases:

1. **Register Phase** — Modules declare what they provide and what they need
2. **Build Phase** — Container resolves all dependencies, detects cycles, validates completeness

This makes the dependency graph explicit and validates it before any services are created.

### Implementation

```typescript
// src/container/two-phase-container.ts

/**
 * Describes what a service provides and what it depends on.
 */
export interface ServiceDescriptor {
  token: string | symbol
  dependencies: (string | symbol)[]
  factory: (container: Container) => unknown
}

/**
 * Two-phase container: register phase, then build phase.
 */
export class TwoPhaseContainer {
  private descriptors = new Map<string | symbol, ServiceDescriptor>()
  private services = new Map<string | symbol, unknown>()
  private isBuilt = false

  /**
   * Register phase: declare a service and its dependencies.
   * Can only be called before build().
   */
  register<T>(
    token: string | symbol,
    dependencies: (string | symbol)[],
    factory: (container: Container) => T
  ): void {
    if (this.isBuilt) {
      throw new Error("Cannot register after build() has been called")
    }

    this.descriptors.set(token, {
      token,
      dependencies,
      factory,
    })
  }

  /**
   * Build phase: resolve all dependencies, detect cycles, validate completeness.
   * After build(), the container is frozen (no new registrations).
   */
  build(): void {
    if (this.isBuilt) {
      return  // Idempotent
    }

    // 1. Validate all dependencies are registered
    this.validateDependencies()

    // 2. Detect cycles
    this.detectCycles()

    // 3. Resolve all services in dependency order
    this.resolveAll()

    this.isBuilt = true
  }

  /**
   * Resolve a service (only after build()).
   */
  resolve<T>(token: string | symbol): T {
    if (!this.isBuilt) {
      throw new Error("Container must be built before resolving services")
    }

    if (!this.services.has(token)) {
      throw new Error(`Service not found: ${String(token)}`)
    }

    return this.services.get(token) as T
  }

  /**
   * Validate that all declared dependencies are registered.
   */
  private validateDependencies(): void {
    for (const [token, descriptor] of this.descriptors) {
      for (const dep of descriptor.dependencies) {
        if (!this.descriptors.has(dep)) {
          throw new Error(
            `Service ${String(token)} depends on ${String(dep)}, which is not registered`
          )
        }
      }
    }
  }

  /**
   * Detect circular dependencies using depth-first search.
   */
  private detectCycles(): void {
    const visited = new Set<string | symbol>()
    const recursionStack = new Set<string | symbol>()

    const visit = (token: string | symbol, path: (string | symbol)[]): void => {
      if (recursionStack.has(token)) {
        const cycle = path.slice(path.indexOf(token)).map(String).join(" → ")
        throw new Error(`Circular dependency detected: ${cycle} → ${String(token)}`)
      }

      if (visited.has(token)) {
        return
      }

      visited.add(token)
      recursionStack.add(token)

      const descriptor = this.descriptors.get(token)
      if (descriptor) {
        for (const dep of descriptor.dependencies) {
          visit(dep, [...path, token])
        }
      }

      recursionStack.delete(token)
    }

    for (const token of this.descriptors.keys()) {
      if (!visited.has(token)) {
        visit(token, [])
      }
    }
  }

  /**
   * Resolve all services in dependency order.
   */
  private resolveAll(): void {
    const resolved = new Set<string | symbol>()

    const resolve = (token: string | symbol): void => {
      if (resolved.has(token)) {
        return
      }

      const descriptor = this.descriptors.get(token)
      if (!descriptor) {
        throw new Error(`Service not registered: ${String(token)}`)
      }

      // Resolve dependencies first
      for (const dep of descriptor.dependencies) {
        resolve(dep)
      }

      // Then resolve this service
      const instance = descriptor.factory(this as any)
      this.services.set(token, instance)
      resolved.add(token)
    }

    for (const token of this.descriptors.keys()) {
      resolve(token)
    }
  }

  /**
   * Get all registered tokens (for debugging).
   */
  getTokens(): (string | symbol)[] {
    return Array.from(this.descriptors.keys())
  }

  /**
   * Get dependency graph (for debugging).
   */
  getDependencyGraph(): Map<string | symbol, (string | symbol)[]> {
    const graph = new Map<string | symbol, (string | symbol)[]>()
    for (const [token, descriptor] of this.descriptors) {
      graph.set(token, descriptor.dependencies)
    }
    return graph
  }
}
```

### Usage Example

```typescript
// src/index.ts - TWO-PHASE PATTERN

const container = new TwoPhaseContainer()

// REGISTER PHASE: Declare services and dependencies
// Order doesn't matter!

container.register(
  Tokens.Config,
  [],  // No dependencies
  () => ConfigManager.loadOrThrow()
)

container.register(
  Tokens.WorktreeManager,
  [Tokens.Config, Tokens.Shell],  // Explicit dependencies
  (c) => {
    const config = c.resolve(Tokens.Config)
    const shell = c.resolve(Tokens.Shell)
    const manager = new WorktreeManager(repoRoot, shell, log)
    manager.detectVCS()
    return manager
  }
)

container.register(
  Tokens.ProjectManager,
  [Tokens.Config, Tokens.WorktreeManager, Tokens.Logger],
  (c) => {
    const config = c.resolve(Tokens.Config)
    const vcs = c.resolve(Tokens.WorktreeManager)
    const log = c.resolve(Tokens.Logger)
    return new ProjectManager(config, vcs, log)
  }
)

// BUILD PHASE: Validate and resolve everything
try {
  container.build()  // Validates dependencies, detects cycles, resolves all services
} catch (error) {
  await log.error(`Container build failed: ${error.message}`)
  throw error
}

// Now use the container
const projectManager = container.resolve(Tokens.ProjectManager)
```

### Benefits

✅ **Registration order independence** — Services can be registered in any order  
✅ **Explicit dependencies** — Each service declares what it needs  
✅ **Cycle detection** — Circular dependencies caught at build time  
✅ **Validation** — All dependencies validated before any services created  
✅ **Clear error messages** — Errors include the full dependency path  
✅ **Debugging** — Can inspect dependency graph  

### Limitations

❌ **More verbose** — Must declare dependencies twice (in register call and in factory)  
❌ **Eager resolution** — All services resolved at build time, even if not used  
❌ **No lazy initialization** — Services created even if never accessed  

---

## 4. Hybrid: Lazy Factories + Two-Phase

### Concept

Combine lazy factories with two-phase initialization:

1. **Register Phase** — Declare dependencies explicitly
2. **Build Phase** — Validate dependency graph, detect cycles
3. **Resolve Phase** — Factories called lazily when services accessed

This provides the best of both worlds: explicit dependencies with lazy initialization.

### Implementation

```typescript
// src/container/hybrid-container.ts

/**
 * Hybrid container: explicit dependencies + lazy resolution.
 */
export class HybridContainer {
  private descriptors = new Map<string | symbol, ServiceDescriptor>()
  private services = new Map<string | symbol, unknown>()
  private isBuilt = false

  /**
   * Register phase: declare a service and its dependencies.
   */
  register<T>(
    token: string | symbol,
    dependencies: (string | symbol)[],
    factory: (container: HybridContainer) => T
  ): void {
    if (this.isBuilt) {
      throw new Error("Cannot register after build()")
    }

    this.descriptors.set(token, {
      token,
      dependencies,
      factory,
    })
  }

  /**
   * Build phase: validate dependency graph and detect cycles.
   * Does NOT resolve services yet (lazy resolution).
   */
  build(): void {
    if (this.isBuilt) {
      return
    }

    this.validateDependencies()
    this.detectCycles()
    this.isBuilt = true
  }

  /**
   * Resolve phase: call factory lazily when service is accessed.
   */
  resolve<T>(token: string | symbol): T {
    if (!this.isBuilt) {
      throw new Error("Container must be built before resolving")
    }

    // Already resolved? Return cached value
    if (this.services.has(token)) {
      return this.services.get(token) as T
    }

    // Get descriptor
    const descriptor = this.descriptors.get(token)
    if (!descriptor) {
      throw new Error(`Service not registered: ${String(token)}`)
    }

    // Call factory (which may resolve dependencies)
    const instance = descriptor.factory(this)
    this.services.set(token, instance)
    return instance
  }

  private validateDependencies(): void {
    for (const [token, descriptor] of this.descriptors) {
      for (const dep of descriptor.dependencies) {
        if (!this.descriptors.has(dep)) {
          throw new Error(
            `Service ${String(token)} depends on ${String(dep)}, which is not registered`
          )
        }
      }
    }
  }

  private detectCycles(): void {
    const visited = new Set<string | symbol>()
    const recursionStack = new Set<string | symbol>()

    const visit = (token: string | symbol, path: (string | symbol)[]): void => {
      if (recursionStack.has(token)) {
        const cycle = path.slice(path.indexOf(token)).map(String).join(" → ")
        throw new Error(`Circular dependency detected: ${cycle} → ${String(token)}`)
      }

      if (visited.has(token)) {
        return
      }

      visited.add(token)
      recursionStack.add(token)

      const descriptor = this.descriptors.get(token)
      if (descriptor) {
        for (const dep of descriptor.dependencies) {
          visit(dep, [...path, token])
        }
      }

      recursionStack.delete(token)
    }

    for (const token of this.descriptors.keys()) {
      if (!visited.has(token)) {
        visit(token, [])
      }
    }
  }
}
```

### Usage Example

```typescript
// src/index.ts - HYBRID PATTERN (RECOMMENDED)

const container = new HybridContainer()

// REGISTER PHASE: Order doesn't matter
container.register(
  Tokens.ProjectManager,
  [Tokens.Config, Tokens.WorktreeManager],
  (c) => new ProjectManager(c.resolve(Tokens.Config), c.resolve(Tokens.WorktreeManager))
)

container.register(
  Tokens.WorktreeManager,
  [Tokens.Config],
  (c) => {
    const manager = new WorktreeManager(repoRoot, $, log)
    manager.detectVCS()
    return manager
  }
)

container.register(
  Tokens.Config,
  [],
  () => ConfigManager.loadOrThrow()
)

// BUILD PHASE: Validate (no resolution yet)
container.build()  // Validates dependencies, detects cycles

// RESOLVE PHASE: Lazy resolution
const projectManager = container.resolve(Tokens.ProjectManager)  // Factories called here
```

### Benefits

✅ **Registration order independence** — Services can be registered in any order  
✅ **Explicit dependencies** — Each service declares what it needs  
✅ **Cycle detection** — Circular dependencies caught at build time  
✅ **Lazy initialization** — Services only created when accessed  
✅ **Singleton pattern** — Factories called once; results cached  
✅ **Clear error messages** — Validation errors include full context  

### Limitations

❌ **Slightly more verbose** — Must declare dependencies in register call  
❌ **Dependency declaration overhead** — Must list dependencies twice (declaration + usage)  

---

## 5. Async Factory Support

### Concept

Extend lazy resolution to support async initialization (e.g., `worktreeManager.detectVCS()`).

### Implementation

```typescript
// src/container/async-hybrid-container.ts

/**
 * Async-aware hybrid container.
 * Factories can be async; build() is async and awaits all factories.
 */
export class AsyncHybridContainer {
  private descriptors = new Map<string | symbol, AsyncServiceDescriptor>()
  private services = new Map<string | symbol, unknown>()
  private isBuilt = false

  /**
   * Register an async factory.
   */
  register<T>(
    token: string | symbol,
    dependencies: (string | symbol)[],
    factory: (container: AsyncHybridContainer) => Promise<T> | T
  ): void {
    if (this.isBuilt) {
      throw new Error("Cannot register after build()")
    }

    this.descriptors.set(token, {
      token,
      dependencies,
      factory,
    })
  }

  /**
   * Build phase: validate and eagerly resolve all services.
   * This is async because factories may be async.
   */
  async build(): Promise<void> {
    if (this.isBuilt) {
      return
    }

    this.validateDependencies()
    this.detectCycles()
    await this.resolveAll()
    this.isBuilt = true
  }

  /**
   * Resolve a service (only after build()).
   */
  resolve<T>(token: string | symbol): T {
    if (!this.isBuilt) {
      throw new Error("Container must be built before resolving")
    }

    if (!this.services.has(token)) {
      throw new Error(`Service not registered: ${String(token)}`)
    }

    return this.services.get(token) as T
  }

  /**
   * Resolve all services in dependency order.
   */
  private async resolveAll(): Promise<void> {
    const resolved = new Set<string | symbol>()

    const resolve = async (token: string | symbol): Promise<void> => {
      if (resolved.has(token)) {
        return
      }

      const descriptor = this.descriptors.get(token)
      if (!descriptor) {
        throw new Error(`Service not registered: ${String(token)}`)
      }

      // Resolve dependencies first
      for (const dep of descriptor.dependencies) {
        await resolve(dep)
      }

      // Then resolve this service
      const instance = await descriptor.factory(this)
      this.services.set(token, instance)
      resolved.add(token)
    }

    for (const token of this.descriptors.keys()) {
      await resolve(token)
    }
  }

  private validateDependencies(): void {
    for (const [token, descriptor] of this.descriptors) {
      for (const dep of descriptor.dependencies) {
        if (!this.descriptors.has(dep)) {
          throw new Error(
            `Service ${String(token)} depends on ${String(dep)}, which is not registered`
          )
        }
      }
    }
  }

  private detectCycles(): void {
    // Same as HybridContainer
    const visited = new Set<string | symbol>()
    const recursionStack = new Set<string | symbol>()

    const visit = (token: string | symbol, path: (string | symbol)[]): void => {
      if (recursionStack.has(token)) {
        const cycle = path.slice(path.indexOf(token)).map(String).join(" → ")
        throw new Error(`Circular dependency detected: ${cycle} → ${String(token)}`)
      }

      if (visited.has(token)) {
        return
      }

      visited.add(token)
      recursionStack.add(token)

      const descriptor = this.descriptors.get(token)
      if (descriptor) {
        for (const dep of descriptor.dependencies) {
          visit(dep, [...path, token])
        }
      }

      recursionStack.delete(token)
    }

    for (const token of this.descriptors.keys()) {
      if (!visited.has(token)) {
        visit(token, [])
      }
    }
  }
}

interface AsyncServiceDescriptor {
  token: string | symbol
  dependencies: (string | symbol)[]
  factory: (container: AsyncHybridContainer) => Promise<unknown> | unknown
}
```

### Usage Example

```typescript
// src/index.ts - ASYNC SUPPORT

const container = new AsyncHybridContainer()

// Register services with async factories
container.register(
  Tokens.WorktreeManager,
  [Tokens.Config],
  async (c) => {
    const config = c.resolve(Tokens.Config)
    const manager = new WorktreeManager(repoRoot, $, log)
    await manager.detectVCS()  // Async initialization
    return manager
  }
)

container.register(
  Tokens.ProjectManager,
  [Tokens.Config, Tokens.WorktreeManager],
  (c) => new ProjectManager(c.resolve(Tokens.Config), c.resolve(Tokens.WorktreeManager))
)

// Build is now async
await container.build()

// Use the container
const projectManager = container.resolve(Tokens.ProjectManager)
```

### Benefits

✅ **Async initialization** — Factories can be async  
✅ **Dependency order** — Dependencies resolved before dependents  
✅ **Eager resolution** — All services initialized at build time  
✅ **Clear startup** — All initialization errors caught at startup, not at first use  

### Limitations

❌ **Eager resolution** — All services created at build time, even if not used  
❌ **Slower startup** — Must wait for all async factories to complete  

---

## 6. Frozen Container

### Concept

After the build phase, the container should be immutable (no new registrations). This prevents accidental modifications and makes the container's state explicit.

### Implementation

```typescript
// src/container/frozen-container.ts

/**
 * Frozen container: immutable after build().
 */
export class FrozenContainer {
  private descriptors = new Map<string | symbol, ServiceDescriptor>()
  private services = new Map<string | symbol, unknown>()
  private isBuilt = false
  private isFrozen = false

  register<T>(
    token: string | symbol,
    dependencies: (string | symbol)[],
    factory: (container: FrozenContainer) => T
  ): void {
    if (this.isFrozen) {
      throw new Error("Cannot register: container is frozen")
    }

    this.descriptors.set(token, { token, dependencies, factory })
  }

  async build(): Promise<void> {
    if (this.isFrozen) {
      return
    }

    this.validateDependencies()
    this.detectCycles()
    await this.resolveAll()
    this.isBuilt = true
    this.isFrozen = true  // Freeze after build
  }

  resolve<T>(token: string | symbol): T {
    if (!this.isBuilt) {
      throw new Error("Container must be built before resolving")
    }

    if (!this.services.has(token)) {
      throw new Error(`Service not registered: ${String(token)}`)
    }

    return this.services.get(token) as T
  }

  /**
   * Check if container is frozen.
   */
  isFrozenContainer(): boolean {
    return this.isFrozen
  }

  // ... rest of implementation (same as AsyncHybridContainer)
}
```

### Benefits

✅ **Immutability** — Container state is explicit and unchangeable  
✅ **Prevents bugs** — Can't accidentally register services after build  
✅ **Clear semantics** — Frozen state makes intent clear  

---

## 7. Concrete Example: Refactored Plugin

### Current Pattern (Fragile)

```typescript
// src/index.ts - CURRENT (requires strict order)

export const ProjectsPlugin: Plugin = async (ctx) => {
  const container = createContainer()

  // Must register in this exact order:
  await registerConfig(container)
  await registerVcs(container)
  await registerProjects(container)
  await registerExecution(container)
  await registerSessions(container)

  // If someone adds a module and registers it in the wrong place,
  // it silently fails at runtime.
}
```

### Proposed Pattern (Order-Independent)

```typescript
// src/index.ts - PROPOSED (order-independent)

export const ProjectsPlugin: Plugin = async (ctx) => {
  const container = new HybridContainer()

  // REGISTER PHASE: Order doesn't matter!
  
  container.register(
    Tokens.Config,
    [],
    () => ConfigManager.loadOrThrow()
  )

  container.register(
    Tokens.WorktreeManager,
    [Tokens.Config],
    async (c) => {
      const manager = new WorktreeManager(repoRoot, $, log)
      await manager.detectVCS()
      return manager
    }
  )

  container.register(
    Tokens.ProjectManager,
    [Tokens.Config, Tokens.WorktreeManager],
    (c) => new ProjectManager(
      c.resolve(Tokens.Config),
      c.resolve(Tokens.WorktreeManager),
      log
    )
  )

  container.register(
    Tokens.DelegationManager,
    [Tokens.Config],
    (c) => new DelegationManager(log, typedClient, c.resolve(Tokens.Config))
  )

  container.register(
    Tokens.TeamManager,
    [Tokens.DelegationManager, Tokens.WorktreeManager],
    (c) => new TeamManager(
      log,
      typedClient,
      c.resolve(Tokens.DelegationManager),
      c.resolve(Tokens.WorktreeManager),
      teamConfig
    )
  )

  // BUILD PHASE: Validate dependency graph
  try {
    container.build()
  } catch (error) {
    await log.error(`Container build failed: ${error.message}`)
    throw error
  }

  // Now use the container
  const projectManager = container.resolve(Tokens.ProjectManager)
  const delegationManager = container.resolve(Tokens.DelegationManager)
  const teamManager = container.resolve(Tokens.TeamManager)

  // ... rest of plugin initialization
}
```

### Benefits

✅ **Order-independent** — Services can be registered in any order  
✅ **Explicit dependencies** — Each service declares what it needs  
✅ **Cycle detection** — Circular dependencies caught at build time  
✅ **Clear error messages** — Validation errors include full context  
✅ **Easier to extend** — Adding a new service is straightforward  

---

## 8. Comparison: All Patterns

| Pattern | Order-Independent | Cycle Detection | Eager Build | Async Support | Complexity |
|---------|-------------------|-----------------|-------------|---------------|-----------|
| **Lazy Factory** | ✅ | ❌ | ❌ | ❌ | Low |
| **Two-Phase** | ✅ | ✅ | ✅ | ❌ | Medium |
| **Hybrid** | ✅ | ✅ | ❌ | ❌ | Medium |
| **Async Hybrid** | ✅ | ✅ | ✅ | ✅ | Medium |
| **Frozen** | ✅ | ✅ | ✅ | ✅ | Medium |

---

## 9. Recommendation: Async Hybrid Container

**Recommended Pattern:** Async Hybrid Container with Frozen State

### Why This Pattern?

1. **Registration order independence** — Services can be registered in any order
2. **Explicit dependencies** — Each service declares what it needs
3. **Cycle detection** — Circular dependencies caught at build time
4. **Async support** — Factories can be async (needed for `detectVCS()`)
5. **Lazy initialization** — Services only created when accessed
6. **Frozen state** — Container immutable after build
7. **Clear error messages** — Validation errors include full context
8. **Minimal complexity** — ~200 lines of code

### Implementation Plan

**Phase 1: Create Container Infrastructure**
1. Implement `AsyncHybridContainer` class
2. Add cycle detection algorithm
3. Add dependency validation
4. Write comprehensive tests

**Phase 2: Migrate to New Container**
1. Update `src/index.ts` to use new container
2. Register all services with explicit dependencies
3. Call `container.build()` before using services
4. Verify all hooks work correctly

**Phase 3: Update Module Registration**
1. Update each `register()` function to use new container
2. Remove registration order constraints from documentation
3. Add examples of adding new services

---

## 10. Implementation Details

### Dependency Declaration

Each service must declare its dependencies:

```typescript
container.register(
  Tokens.ProjectManager,
  [Tokens.Config, Tokens.WorktreeManager, Tokens.Logger],  // Explicit dependencies
  (c) => new ProjectManager(
    c.resolve(Tokens.Config),
    c.resolve(Tokens.WorktreeManager),
    c.resolve(Tokens.Logger)
  )
)
```

### Cycle Detection Algorithm

Uses depth-first search with recursion stack:

```
1. For each unvisited token:
   a. Mark as visited
   b. Add to recursion stack
   c. Visit all dependencies
   d. If dependency is in recursion stack → cycle detected
   e. Remove from recursion stack
```

### Error Messages

Clear, actionable error messages:

```
Circular dependency detected: ProjectManager → WorktreeManager → ProjectManager
Service ProjectManager depends on Config, which is not registered
```

---

## 11. Testing Strategy

### Unit Tests

```typescript
describe("AsyncHybridContainer", () => {
  it("should resolve services in dependency order", async () => {
    const container = new AsyncHybridContainer()
    const callOrder: string[] = []

    container.register(Tokens.A, [], () => {
      callOrder.push("A")
      return "a"
    })

    container.register(Tokens.B, [Tokens.A], (c) => {
      callOrder.push("B")
      c.resolve(Tokens.A)
      return "b"
    })

    await container.build()

    expect(callOrder).toEqual(["A", "B"])
  })

  it("should detect circular dependencies", async () => {
    const container = new AsyncHybridContainer()

    container.register(Tokens.A, [Tokens.B], (c) => c.resolve(Tokens.B))
    container.register(Tokens.B, [Tokens.A], (c) => c.resolve(Tokens.A))

    await expect(container.build()).rejects.toThrow(/Circular dependency/)
  })

  it("should validate all dependencies are registered", async () => {
    const container = new AsyncHybridContainer()

    container.register(Tokens.A, [Tokens.B], (c) => c.resolve(Tokens.B))

    await expect(container.build()).rejects.toThrow(/not registered/)
  })

  it("should support async factories", async () => {
    const container = new AsyncHybridContainer()

    container.register(Tokens.A, [], async () => {
      await new Promise((r) => setTimeout(r, 10))
      return "a"
    })

    await container.build()
    expect(container.resolve(Tokens.A)).toBe("a")
  })
})
```

### Integration Tests

```typescript
describe("Plugin with AsyncHybridContainer", () => {
  it("should initialize all services correctly", async () => {
    const container = new AsyncHybridContainer()

    // Register all services
    container.register(Tokens.Config, [], () => ConfigManager.loadOrThrow())
    container.register(Tokens.WorktreeManager, [Tokens.Config], (c) => {
      const manager = new WorktreeManager(repoRoot, $, log)
      manager.detectVCS()
      return manager
    })
    container.register(Tokens.ProjectManager, [Tokens.Config, Tokens.WorktreeManager], (c) =>
      new ProjectManager(c.resolve(Tokens.Config), c.resolve(Tokens.WorktreeManager), log)
    )

    // Build and verify
    await container.build()
    const projectManager = container.resolve(Tokens.ProjectManager)
    expect(projectManager).toBeDefined()
  })
})
```

---

## 12. Migration Path

### Phase 1: Create Infrastructure (Non-Breaking)
1. Create `src/container/async-hybrid-container.ts`
2. Add comprehensive tests
3. No changes to existing code

### Phase 2: Migrate Plugin Entry Point
1. Update `src/index.ts` to use new container
2. Register all services with explicit dependencies
3. Call `container.build()` before using services
4. Verify all hooks work correctly

### Phase 3: Update Module Registration
1. Update each `register()` function to accept new container type
2. Remove registration order constraints from documentation
3. Add examples of adding new services

### Phase 4: Cleanup
1. Remove old container implementation
2. Update documentation
3. Commit changes

---

## 13. Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Circular dependencies | Low | High | Cycle detection at build time |
| Missing dependencies | Low | High | Validation at build time |
| Async factory errors | Medium | High | Clear error messages, tests |
| Performance regression | Low | Low | Container is simple Map lookup |
| Migration breaks functionality | Medium | High | Incremental migration, extensive testing |

---

## 14. Conclusion

**Lazy resolution with two-phase initialization eliminates registration order dependency** while providing:

- ✅ Order-independent service registration
- ✅ Explicit dependency declarations
- ✅ Cycle detection at build time
- ✅ Async factory support
- ✅ Clear error messages
- ✅ Minimal API complexity

**Recommended Implementation:** Async Hybrid Container with Frozen State

This pattern provides the best balance of:
- **Correctness** — Validates dependency graph at startup
- **Flexibility** — Services can be registered in any order
- **Simplicity** — ~200 lines of code, no external dependencies
- **Debuggability** — Clear error messages and dependency graph inspection

The migration can be done incrementally, with no breaking changes until the final cleanup phase.
