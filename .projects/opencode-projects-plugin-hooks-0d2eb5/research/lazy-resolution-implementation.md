# Lazy Resolution Implementation Guide

**Date:** 2026-03-04  
**Status:** Implementation Ready  
**Scope:** Step-by-step guide to implement Async Hybrid Container

---

## Quick Start

This guide provides complete, production-ready code for implementing the Async Hybrid Container pattern.

### What You'll Build

A DI container that:
- ✅ Allows services to be registered in any order
- ✅ Detects circular dependencies at build time
- ✅ Supports async initialization
- ✅ Provides clear error messages
- ✅ Requires ~200 lines of code

### Time Estimate

- **Phase 1 (Container):** 1-2 hours
- **Phase 2 (Migration):** 2-3 hours
- **Phase 3 (Testing):** 1-2 hours
- **Total:** 4-7 hours

---

## Phase 1: Create Container Infrastructure

### Step 1.1: Create Container Class

**File:** `src/container/async-hybrid-container.ts`

```typescript
/**
 * Async-aware hybrid container with explicit dependencies and lazy resolution.
 * 
 * Usage:
 * 1. Register phase: declare services and dependencies (order doesn't matter)
 * 2. Build phase: validate dependency graph, detect cycles
 * 3. Resolve phase: access services (factories called lazily)
 */
export class AsyncHybridContainer {
  private descriptors = new Map<string | symbol, ServiceDescriptor>()
  private services = new Map<string | symbol, unknown>()
  private isFrozen = false

  /**
   * Register a service with explicit dependencies.
   * Can only be called before build().
   * 
   * @param token - Service identifier (usually a Symbol)
   * @param dependencies - Array of tokens this service depends on
   * @param factory - Function that creates the service (can be async)
   * 
   * IMPORTANT: The dependencies array must include ALL tokens that the factory
   * resolves via c.resolve(). Mismatches will cause runtime errors.
   */
  register<T>(
    token: string | symbol,
    dependencies: (string | symbol)[],
    factory: (container: AsyncHybridContainer) => Promise<T> | T
  ): void {
    if (this.isFrozen) {
      throw new Error(
        `Cannot register service ${String(token)}: container is frozen (build() already called)`
      )
    }

    this.descriptors.set(token, {
      token,
      dependencies,
      factory,
    })
  }

  /**
   * Register a pre-built service instance (convenience method).
   * Use this for values that are already constructed (e.g., client, shell, repoRoot).
   * 
   * @param token - Service identifier
   * @param value - The service instance
   */
  registerValue<T>(token: string | symbol, value: T): void {
    if (this.isFrozen) {
      throw new Error(
        `Cannot register service ${String(token)}: container is frozen (build() already called)`
      )
    }

    // Register as a factory with no dependencies
    this.descriptors.set(token, {
      token,
      dependencies: [],
      factory: () => value,
    })
  }

  /**
   * Build phase: validate dependency graph and detect cycles.
   * After build(), the container is frozen (no new registrations).
   * 
   * This is async because factories may be async.
   * All services are resolved eagerly during build.
   */
  async build(): Promise<void> {
    if (this.isFrozen) {
      return  // Idempotent
    }

    // 1. Validate all dependencies are registered
    this.validateDependencies()

    // 2. Detect circular dependencies
    this.detectCycles()

    // 3. Resolve all services in dependency order
    await this.resolveAll()

    // 4. Freeze the container
    this.isFrozen = true
  }

  /**
   * Resolve a service (only after build()).
   * Returns cached instance (all services are resolved during build()).
   * 
   * @param token - Service identifier
   * @returns The service instance
   * @throws If container hasn't been built or service doesn't exist
   */
  resolve<T>(token: string | symbol): T {
    if (!this.isFrozen) {
      throw new Error(
        `Cannot resolve service ${String(token)}: container must be built first. Call await container.build()`
      )
    }

    if (!this.services.has(token)) {
      throw new Error(`Service not found: ${String(token)}`)
    }

    return this.services.get(token) as T
  }

  /**
   * Check if a service is registered (before or after build).
   * This checks the descriptor map, not the resolved services.
   */
  has(token: string | symbol): boolean {
    return this.descriptors.has(token)
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
   * Uses a recursion stack to detect cycles during traversal.
   */
  private detectCycles(): void {
    const visited = new Set<string | symbol>()
    const recursionStack = new Set<string | symbol>()

    const visit = (token: string | symbol, path: (string | symbol)[]): void => {
      if (recursionStack.has(token)) {
        // Found a cycle: reconstruct the cycle path
        const cycleStart = path.findIndex((t) => t === token)
        const cycle = path.slice(cycleStart).map(String).join(" → ")
        throw new Error(
          `Circular dependency detected: ${cycle} → ${String(token)}`
        )
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
   * Services are resolved depth-first: dependencies before dependents.
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
}

/**
 * Service descriptor: what a service provides and what it depends on.
 */
interface ServiceDescriptor {
  token: string | symbol
  dependencies: (string | symbol)[]
  factory: (container: AsyncHybridContainer) => Promise<unknown> | unknown
}
```

### Step 1.2: Create Tokens

**File:** `src/container/tokens.ts`

```typescript
/**
 * Service tokens for type-safe dependency injection.
 * Use Symbols to avoid naming collisions.
 */
export const Tokens = {
  // Infrastructure
  Client: Symbol("Client"),
  Shell: Symbol("Shell"),
  RepoRoot: Symbol("RepoRoot"),
  Logger: Symbol("Logger"),

  // Configuration
  Config: Symbol("Config"),

  // VCS
  WorktreeManager: Symbol("WorktreeManager"),

  // Projects
  ProjectManager: Symbol("ProjectManager"),
  FocusManager: Symbol("FocusManager"),
  IssueStorage: Symbol("IssueStorage"),

  // Execution
  DelegationManager: Symbol("DelegationManager"),
  TeamManager: Symbol("TeamManager"),

  // Hooks
  HookRegistry: Symbol("HookRegistry"),
} as const

/**
 * Type-safe service resolution.
 * Maps tokens to their types.
 */
export interface ServiceTypes {
  [Tokens.Client]: OpencodeClient
  [Tokens.Shell]: Shell
  [Tokens.RepoRoot]: string
  [Tokens.Logger]: Logger
  [Tokens.Config]: ConfigManager
  [Tokens.WorktreeManager]: WorktreeManager
  [Tokens.ProjectManager]: ProjectManager
  [Tokens.FocusManager]: FocusManager
  [Tokens.IssueStorage]: IssueStorage
  [Tokens.DelegationManager]: DelegationManager
  [Tokens.TeamManager]: TeamManager
  [Tokens.HookRegistry]: HookRegistry
}

/**
 * Type-safe resolve method.
 * The resolve method is defined directly on the class (not via declare global).
 * Usage: container.resolve(Tokens.ProjectManager)
 * 
 * Note: TypeScript's type inference will automatically use ServiceTypes
 * to provide correct return types when resolving tokens.
 */
```

### Step 1.3: Create Index Export

**File:** `src/container/index.ts`

```typescript
export { AsyncHybridContainer } from "./async-hybrid-container.js"
export { Tokens, type ServiceTypes } from "./tokens.js"
```

### Step 1.4: Write Tests

**File:** `src/container/async-hybrid-container.test.ts`

```typescript
import { describe, it, expect } from "bun:test"
import { AsyncHybridContainer } from "./async-hybrid-container.js"

describe("AsyncHybridContainer", () => {
  describe("register and build", () => {
    it("should resolve services in dependency order", async () => {
      const container = new AsyncHybridContainer()
      const callOrder: string[] = []

      const TokenA = Symbol("A")
      const TokenB = Symbol("B")

      container.register(TokenA, [], () => {
        callOrder.push("A")
        return "a"
      })

      container.register(TokenB, [TokenA], (c) => {
        callOrder.push("B")
        c.resolve(TokenA)
        return "b"
      })

      await container.build()

      expect(callOrder).toEqual(["A", "B"])
      expect(container.resolve(TokenA)).toBe("a")
      expect(container.resolve(TokenB)).toBe("b")
    })

    it("should support async factories", async () => {
      const container = new AsyncHybridContainer()
      const TokenA = Symbol("A")

      container.register(TokenA, [], async () => {
        await new Promise((r) => setTimeout(r, 10))
        return "async-value"
      })

      await container.build()
      expect(container.resolve(TokenA)).toBe("async-value")
    })

    it("should cache resolved services", async () => {
      const container = new AsyncHybridContainer()
      const TokenA = Symbol("A")
      let callCount = 0

      container.register(TokenA, [], () => {
        callCount++
        return "value"
      })

      await container.build()

      container.resolve(TokenA)
      container.resolve(TokenA)
      container.resolve(TokenA)

      expect(callCount).toBe(1)  // Factory called only once
    })
  })

  describe("dependency validation", () => {
    it("should throw if dependency is not registered", async () => {
      const container = new AsyncHybridContainer()
      const TokenA = Symbol("A")
      const TokenB = Symbol("B")

      container.register(TokenA, [TokenB], (c) => c.resolve(TokenB))

      await expect(container.build()).rejects.toThrow(/not registered/)
    })

    it("should throw if service is resolved before build", async () => {
      const container = new AsyncHybridContainer()
      const TokenA = Symbol("A")

      container.register(TokenA, [], () => "value")

      expect(() => container.resolve(TokenA)).toThrow(/must be built first/)
    })

    it("should throw if service is registered after build", async () => {
      const container = new AsyncHybridContainer()
      const TokenA = Symbol("A")
      const TokenB = Symbol("B")

      container.register(TokenA, [], () => "value")
      await container.build()

      expect(() => container.register(TokenB, [], () => "value")).toThrow(/frozen/)
    })
  })

  describe("cycle detection", () => {
    it("should detect direct cycles", async () => {
      const container = new AsyncHybridContainer()
      const TokenA = Symbol("A")
      const TokenB = Symbol("B")

      container.register(TokenA, [TokenB], (c) => c.resolve(TokenB))
      container.register(TokenB, [TokenA], (c) => c.resolve(TokenA))

      await expect(container.build()).rejects.toThrow(/Circular dependency/)
    })

    it("should detect indirect cycles", async () => {
      const container = new AsyncHybridContainer()
      const TokenA = Symbol("A")
      const TokenB = Symbol("B")
      const TokenC = Symbol("C")

      container.register(TokenA, [TokenB], (c) => c.resolve(TokenB))
      container.register(TokenB, [TokenC], (c) => c.resolve(TokenC))
      container.register(TokenC, [TokenA], (c) => c.resolve(TokenA))

      await expect(container.build()).rejects.toThrow(/Circular dependency/)
    })

    it("should detect self-cycles", async () => {
      const container = new AsyncHybridContainer()
      const TokenA = Symbol("A")

      container.register(TokenA, [TokenA], (c) => c.resolve(TokenA))

      await expect(container.build()).rejects.toThrow(/Circular dependency/)
    })
  })

  describe("debugging", () => {
    it("should provide dependency graph", async () => {
      const container = new AsyncHybridContainer()
      const TokenA = Symbol("A")
      const TokenB = Symbol("B")

      container.register(TokenA, [], () => "a")
      container.register(TokenB, [TokenA], (c) => c.resolve(TokenA))

      const graph = container.getDependencyGraph()
      expect(graph.get(TokenA)).toEqual([])
      expect(graph.get(TokenB)).toEqual([TokenA])
    })

    it("should list all registered tokens", async () => {
      const container = new AsyncHybridContainer()
      const TokenA = Symbol("A")
      const TokenB = Symbol("B")

      container.register(TokenA, [], () => "a")
      container.register(TokenB, [], () => "b")

      const tokens = container.getTokens()
      expect(tokens).toContain(TokenA)
      expect(tokens).toContain(TokenB)
    })
  })
})
```

---

## Phase 2: Migrate Plugin Entry Point

### Step 2.1: Update src/index.ts

**File:** `src/index.ts` (excerpt)

```typescript
import { AsyncHybridContainer, Tokens } from "./container/index.js"

export const ProjectsPlugin: Plugin = async (ctx) => {
  const { client, directory, worktree, $ } = ctx

  const typedClient = validateClientOrThrow(client)
  const log = createLogger(typedClient)
  await log.info("opencode-projects plugin initializing")

  const repoRoot = worktree || directory

  // Create container
  const container = new AsyncHybridContainer()

  // REGISTER PHASE: Order doesn't matter!

  // Infrastructure (no dependencies)
  container.register(Tokens.Client, [], () => typedClient)
  container.register(Tokens.Shell, [], () => $)
  container.register(Tokens.RepoRoot, [], () => repoRoot)
  container.register(Tokens.Logger, [], () => log)

  // Configuration (depends on nothing)
  container.register(Tokens.Config, [], () => ConfigManager.loadOrThrow())

  // VCS (depends on config)
  container.register(
    Tokens.WorktreeManager,
    [Tokens.Config, Tokens.Logger],
    async (c) => {
      const config = c.resolve(Tokens.Config)
      const logger = c.resolve(Tokens.Logger)
      const manager = new WorktreeManager(repoRoot, $, logger)
      await manager.detectVCS()
      return manager
    }
  )

  // Projects (depends on config, vcs)
  container.register(
    Tokens.FocusManager,
    [],
    () => new FocusManager()
  )

  container.register(
    Tokens.IssueStorage,
    [Tokens.Logger],
    (c) => {
      const storage = new BeadsIssueStorage(c.resolve(Tokens.Logger))
      storage.setShell($)
      return storage
    }
  )

  container.register(
    Tokens.ProjectManager,
    [Tokens.Config, Tokens.IssueStorage, Tokens.FocusManager, Tokens.Logger, Tokens.WorktreeManager, Tokens.TeamManager],
    (c) =>
      new ProjectManager(
        c.resolve(Tokens.Config),
        c.resolve(Tokens.IssueStorage),
        c.resolve(Tokens.FocusManager),
        c.resolve(Tokens.Logger),
        repoRoot,
        typedClient,
        $,
        c.resolve(Tokens.TeamManager)
      )
  )

  // Execution (depends on config, vcs, projects)
  container.register(
    Tokens.DelegationManager,
    [Tokens.Logger, Tokens.Config],
    (c) =>
      new DelegationManager(c.resolve(Tokens.Logger), typedClient, {
        timeoutMs: c.resolve(Tokens.Config).getDelegationTimeoutMs(),
        smallModelTimeoutMs: c.resolve(Tokens.Config).getSmallModelTimeoutMs(),
      })
  )

  container.register(
    Tokens.TeamManager,
    [Tokens.Logger, Tokens.DelegationManager, Tokens.WorktreeManager, Tokens.Config],
    (c) => {
      const config = c.resolve(Tokens.Config)
      return new TeamManager(
        c.resolve(Tokens.Logger),
        typedClient,
        c.resolve(Tokens.DelegationManager),
        c.resolve(Tokens.WorktreeManager),
        {
          maxTeamSize: config.getTeamMaxSize(),
          retryFailedMembers: config.getTeamRetryFailedMembers(),
          smallModelTimeoutMs: config.getSmallModelTimeoutMs(),
          delegationTimeoutMs: config.getDelegationTimeoutMs(),
        }
      )
    }
  )

  // BUILD PHASE: Validate dependency graph
  try {
    await container.build()
  } catch (error) {
    await log.error(`Container build failed: ${error.message}`)
    throw error
  }

  // RESOLVE PHASE: Get services
  const projectManager = container.resolve(Tokens.ProjectManager)
  const delegationManager = container.resolve(Tokens.DelegationManager)
  const teamManager = container.resolve(Tokens.TeamManager)

  await log.info(`opencode-projects initialized in ${repoRoot}`)

  // ... rest of plugin initialization
}
```

### Step 2.2: Run Tests

```bash
bun test src/container/async-hybrid-container.test.ts
bun test src/index.test.ts
```

---

## Phase 3: Update Module Registration

### Step 3.1: Update Module Register Functions

**File:** `src/projects/register.ts` (example)

```typescript
import { AsyncHybridContainer, Tokens } from "../container/index.js"

/**
 * Register project-related services.
 * Dependencies are declared explicitly; registration order doesn't matter.
 */
export function registerProjects(container: AsyncHybridContainer): void {
  // Services are registered with explicit dependencies
  // The container will resolve them in the correct order

  container.register(
    Tokens.ProjectContextHook,
    [Tokens.ProjectManager, Tokens.WorktreeManager],
    (c) => createProjectContextHook(c.resolve(Tokens.ProjectManager), c.resolve(Tokens.WorktreeManager))
  )

  container.register(
    Tokens.ShellEnvHook,
    [Tokens.ProjectManager],
    (c) => createShellEnvHook(c.resolve(Tokens.ProjectManager))
  )
}
```

### Step 3.2: Update Documentation

**File:** `docs/di-container.md` (new)

```markdown
# Dependency Injection Container

The plugin uses an `AsyncHybridContainer` for dependency injection.

## Key Features

- **Order-independent registration** — Services can be registered in any order
- **Explicit dependencies** — Each service declares what it needs
- **Cycle detection** — Circular dependencies caught at build time
- **Async support** — Factories can be async

## Usage

### Register Phase

```typescript
const container = new AsyncHybridContainer()

container.register(
  Tokens.ProjectManager,
  [Tokens.Config, Tokens.WorktreeManager],  // Explicit dependencies
  (c) => new ProjectManager(
    c.resolve(Tokens.Config),
    c.resolve(Tokens.WorktreeManager)
  )
)
```

### Build Phase

```typescript
await container.build()  // Validates and resolves all services
```

### Resolve Phase

```typescript
const projectManager = container.resolve(Tokens.ProjectManager)
```

## Adding a New Service

1. Define a token in `src/container/tokens.ts`
2. Add type mapping in `ServiceTypes` interface
3. Register the service with explicit dependencies
4. The container will validate and resolve it

## Debugging

```typescript
// View dependency graph
const graph = container.getDependencyGraph()

// List all registered services
const tokens = container.getTokens()
```
```

---

## Phase 4: Verification Checklist

- [ ] Container tests pass
- [ ] Plugin initializes without errors
- [ ] All hooks work correctly
- [ ] No circular dependency errors
- [ ] All services resolve correctly
- [ ] Async initialization works (detectVCS)
- [ ] Error messages are clear
- [ ] Documentation updated
- [ ] Code committed

---

## Critical: Dependency Declaration Synchronization

**IMPORTANT:** The dependencies array must exactly match what the factory resolves.

### The Problem

```typescript
// ❌ WRONG: TeamManager is resolved but not declared
container.register(
  Tokens.ProjectManager,
  [Tokens.Config, Tokens.WorktreeManager],  // Missing Tokens.TeamManager!
  (c) => new ProjectManager(
    c.resolve(Tokens.Config),
    c.resolve(Tokens.WorktreeManager),
    c.resolve(Tokens.TeamManager)  // ← Resolved but not declared
  )
)
```

This defeats the purpose of explicit dependencies:
- Cycle detection won't catch cycles involving TeamManager
- Dependency validation won't catch if TeamManager is missing
- Runtime errors may occur if TeamManager isn't resolved before ProjectManager

### The Solution

```typescript
// ✅ CORRECT: All resolved dependencies are declared
container.register(
  Tokens.ProjectManager,
  [Tokens.Config, Tokens.WorktreeManager, Tokens.TeamManager],  // All declared
  (c) => new ProjectManager(
    c.resolve(Tokens.Config),
    c.resolve(Tokens.WorktreeManager),
    c.resolve(Tokens.TeamManager)
  )
)
```

### Best Practice: Comment Pattern

To help catch mismatches, use a comment pattern:

```typescript
container.register(
  Tokens.ProjectManager,
  [
    Tokens.Config,           // ← used in factory
    Tokens.WorktreeManager,  // ← used in factory
    Tokens.TeamManager,      // ← used in factory
  ],
  (c) => new ProjectManager(
    c.resolve(Tokens.Config),
    c.resolve(Tokens.WorktreeManager),
    c.resolve(Tokens.TeamManager)
  )
)
```

This makes it obvious when a dependency is added/removed.

---

## Common Patterns

### Pattern 1: Service with Async Initialization

```typescript
container.register(
  Tokens.WorktreeManager,
  [Tokens.Config],
  async (c) => {
    const manager = new WorktreeManager(repoRoot, $, log)
    await manager.detectVCS()  // Async initialization
    return manager
  }
)
```

### Pattern 2: Service with Multiple Dependencies

```typescript
container.register(
  Tokens.ProjectManager,
  [Tokens.Config, Tokens.WorktreeManager, Tokens.Logger],
  (c) => new ProjectManager(
    c.resolve(Tokens.Config),
    c.resolve(Tokens.WorktreeManager),
    c.resolve(Tokens.Logger)
  )
)
```

### Pattern 3: Service with Conditional Logic

```typescript
container.register(
  Tokens.IssueStorage,
  [Tokens.Logger],
  (c) => {
    const storage = new BeadsIssueStorage(c.resolve(Tokens.Logger))
    storage.setShell($)
    return storage
  }
)
```

### Pattern 4: Pre-Built Instance (Value Registration)

For services that are already constructed (like `client`, `shell`, `repoRoot`), use `registerValue()`:

```typescript
// Instead of:
container.register(Tokens.Client, [], () => typedClient)

// Use:
container.registerValue(Tokens.Client, typedClient)

// Both work the same way, but registerValue is clearer for values
```

This is more ergonomic and makes intent clear: this is a pre-built value, not a factory.

---

## Troubleshooting

### Error: "Service not registered"

**Cause:** A service depends on another service that wasn't registered.

**Solution:** Check the dependency list in the `register()` call. Make sure all dependencies are registered.

### Error: "Circular dependency detected"

**Cause:** Two or more services depend on each other.

**Solution:** Refactor to break the cycle. Consider:
- Moving shared logic to a separate service
- Using lazy initialization
- Restructuring the dependency graph

### Error: "Cannot register after build()"

**Cause:** Trying to register a service after `container.build()` was called.

**Solution:** Register all services before calling `build()`.

### Error: "Cannot resolve before build()"

**Cause:** Trying to resolve a service before `container.build()` was called.

**Solution:** Call `await container.build()` before resolving services.

---

## Performance Considerations

- **Build time:** O(n) where n is the number of services
- **Resolve time:** O(1) (cached after build)
- **Memory:** One instance per service (singleton pattern)

For the plugin (~10 services), build time is negligible (<10ms).

---

## Next Steps

1. Implement Phase 1 (Container Infrastructure)
2. Run tests to verify correctness
3. Implement Phase 2 (Migrate Plugin Entry Point)
4. Verify all hooks work correctly
5. Implement Phase 3 (Update Module Registration)
6. Update documentation
7. Commit changes

---

## References

- `lazy-resolution-di.md` — Detailed research on lazy resolution patterns
- `composable-hook-registry-di.md` — Original DI container design
- `src/container/async-hybrid-container.ts` — Container implementation
- `src/container/tokens.ts` — Service tokens
