# Type-Safe Factory Signatures: Implementation Guide

**Date:** 2026-03-04  
**Status:** Implementation Ready  
**Scope:** Step-by-step guide to implement type-safe factory signatures

---

## Quick Start

This guide provides complete, production-ready code for implementing type-safe factory signatures in the DI container.

### What You'll Build

A DI container that:
- ✅ Eliminates dual dependency declaration
- ✅ Provides full type safety without `as any` casts
- ✅ Supports both sync and async factories
- ✅ Maintains cycle detection
- ✅ Requires ~400 lines of code

### Time Estimate

- **Phase 1 (Type Definitions):** 1-2 hours
- **Phase 2 (Container Implementation):** 2-3 hours
- **Phase 3 (Migration):** 2-3 hours
- **Phase 4 (Verification):** 1-2 hours
- **Total:** 6-10 hours

---

## Phase 1: Type Definitions

### Step 1.1: Create Token Class

**File:** `src/container/token.ts`

```typescript
/**
 * Token class that carries type information.
 * 
 * Each token represents a service in the container.
 * The type parameter T indicates what type the token resolves to.
 * 
 * @example
 *   const ConfigToken = new Token<Config>("Config")
 *   const ShellToken = new Token<Shell>("Shell")
 */
export class Token<T = unknown> {
  /**
   * Create a new token.
   * 
   * @param name - Human-readable name for debugging and error messages
   */
  constructor(readonly name: string) {}

  /**
   * String representation for debugging.
   */
  toString(): string {
    return `Token(${this.name})`
  }
}
```

### Step 1.2: Create Type Utilities

**File:** `src/container/types.ts`

```typescript
import { Token } from "./token.js"

/**
 * Extract the resolved type from a token.
 * 
 * If T is Token<X>, returns X.
 * Otherwise returns never.
 * 
 * @example
 *   type ConfigType = Resolve<Token<Config>>  // Config
 *   type InvalidType = Resolve<string>        // never
 */
export type Resolve<T> = T extends Token<infer U> ? U : never

/**
 * Map a tuple of tokens to a tuple of resolved types.
 * 
 * Transforms [Token<A>, Token<B>, Token<C>] to [A, B, C].
 * 
 * @example
 *   type Args = ResolveTokens<[Token<Config>, Token<Shell>]>
 *   // Args = [Config, Shell]
 */
export type ResolveTokens<T extends readonly Token<any>[]> = {
  [K in keyof T]: T[K] extends Token<infer U> ? U : never
}

/**
 * Factory function type that takes resolved dependencies as arguments.
 * 
 * The factory receives each dependency from the token array as a positional argument.
 * It can return either a synchronous value or a Promise.
 * 
 * @example
 *   type PM_Factory = Factory<[Token<Config>, Token<Shell>], ProjectManager>
 *   // PM_Factory = (config: Config, shell: Shell) => ProjectManager | Promise<ProjectManager>
 */
export type Factory<
  Tokens extends readonly Token<any>[],
  T
> = (...args: ResolveTokens<Tokens>) => T | Promise<T>

/**
 * Service descriptor stored in the container.
 * 
 * Tracks the token, its dependencies, and the factory function.
 * Used internally by the container for dependency resolution and cycle detection.
 */
export interface ServiceDescriptor {
  token: Token<any>
  dependencies: Token<any>[]
  factory: (...args: any[]) => any | Promise<any>
}
```

### Step 1.3: Update Index

**File:** `src/container/index.ts`

```typescript
export { Token } from "./token.js"
export type { Resolve, ResolveTokens, Factory, ServiceDescriptor } from "./types.js"
export { TypeSafeContainer } from "./type-safe-container.js"
```

---

## Phase 2: Container Implementation

### Step 2.1: Create TypeSafeContainer Class

**File:** `src/container/type-safe-container.ts`

```typescript
import { Token, type Factory, type ServiceDescriptor } from "./index.js"

/**
 * Type-safe DI container with explicit dependencies and lazy resolution.
 * 
 * Usage:
 * 1. Register phase: declare services and dependencies (order doesn't matter)
 * 2. Build phase: validate dependency graph, detect cycles
 * 3. Resolve phase: access services (factories called during build)
 * 
 * @example
 *   const container = new TypeSafeContainer()
 *   
 *   container.register(
 *     Tokens.ProjectManager,
 *     [Tokens.Config, Tokens.Shell],
 *     (config, shell) => new ProjectManager(config, shell)
 *   )
 *   
 *   await container.build()
 *   const pm = container.resolve(Tokens.ProjectManager)
 */
export class TypeSafeContainer {
  private descriptors = new Map<Token<any>, ServiceDescriptor>()
  private services = new Map<Token<any>, unknown>()
  private isFrozen = false

  /**
   * Register a service with type-safe factory.
   * Can only be called before build().
   * 
   * The factory receives resolved dependencies as positional arguments.
   * No need to call c.resolve() — the container handles it.
   * 
   * @param token - Service identifier (usually a Symbol)
   * @param dependencies - Array of tokens this service depends on
   * @param factory - Function that creates the service (can be async)
   * 
   * @example
   *   container.register(
   *     Tokens.ProjectManager,
   *     [Tokens.Config, Tokens.Shell],
   *     (config, shell) => new ProjectManager(config, shell)
   *   )
   */
  register<T, Deps extends readonly Token<any>[]>(
    token: Token<T>,
    dependencies: Deps,
    factory: Factory<Deps, T>
  ): void {
    if (this.isFrozen) {
      throw new Error(
        `Cannot register service ${token.name}: container is frozen (build() already called)`
      )
    }

    this.descriptors.set(token, {
      token,
      dependencies: Array.from(dependencies),
      factory,
    })
  }

  /**
   * Register a pre-built service instance (convenience method).
   * Use this for values that are already constructed (e.g., client, shell, repoRoot).
   * 
   * @param token - Service identifier
   * @param value - The service instance
   * 
   * @example
   *   const client = new OpencodeClient(...)
   *   container.registerInstance(Tokens.Client, client)
   */
  registerInstance<T>(token: Token<T>, value: T): void {
    if (this.isFrozen) {
      throw new Error(
        `Cannot register service ${token.name}: container is frozen (build() already called)`
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
   * Build phase: validate dependency graph and resolve all services.
   * After build(), the container is frozen (no new registrations).
   * 
   * This is async because factories may be async.
   * All services are resolved eagerly during build.
   * 
   * @throws If dependencies are missing or circular dependencies are detected
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
  resolve<T>(token: Token<T>): T {
    if (!this.isFrozen) {
      throw new Error(
        `Cannot resolve service ${token.name}: container must be built first. Call await container.build()`
      )
    }

    if (!this.services.has(token)) {
      throw new Error(`Service not found: ${token.name}`)
    }

    return this.services.get(token) as T
  }

  /**
   * Check if a service is registered (before or after build).
   */
  has(token: Token<any>): boolean {
    return this.descriptors.has(token)
  }

  /**
   * Validate that all dependencies are registered.
   * 
   * @throws If a dependency is not registered
   */
  private validateDependencies(): void {
    for (const [token, descriptor] of this.descriptors) {
      for (const dep of descriptor.dependencies) {
        if (!this.descriptors.has(dep)) {
          throw new Error(
            `Service ${token.name} depends on ${dep.name}, which is not registered`
          )
        }
      }
    }
  }

  /**
   * Detect circular dependencies using depth-first search.
   * 
   * @throws If a circular dependency is detected
   */
  private detectCycles(): void {
    const visited = new Set<Token<any>>()
    const recursionStack = new Set<Token<any>>()

    const visit = (token: Token<any>, path: Token<any>[]): void => {
      if (visited.has(token)) return
      if (recursionStack.has(token)) {
        const cycle = [...path, token]
          .map((t) => t.name)
          .join(" → ")
        throw new Error(`Circular dependency detected: ${cycle}`)
      }

      recursionStack.add(token)

      const descriptor = this.descriptors.get(token)
      if (descriptor) {
        for (const dep of descriptor.dependencies) {
          visit(dep, [...path, token])
        }
      }

      recursionStack.delete(token)
      visited.add(token)
    }

    for (const token of this.descriptors.keys()) {
      visit(token, [])
    }
  }

  /**
   * Resolve all services in dependency order.
   * 
   * This is where the magic happens: we resolve each dependency
   * and pass the resolved values to the factory.
   */
  private async resolveAll(): Promise<void> {
    const resolved = new Set<Token<any>>()
    const visiting = new Set<Token<any>>()

    const resolveService = async (token: Token<any>): Promise<void> => {
      if (resolved.has(token)) return
      if (visiting.has(token)) {
        // This should never happen because detectCycles() runs before resolveAll()
        throw new Error(`Internal error: circular dependency detected during resolution (${token.name}). This indicates a bug in the cycle detection algorithm.`)
      }

      visiting.add(token)

      const descriptor = this.descriptors.get(token)
      if (!descriptor) {
        throw new Error(`Service not registered: ${token.name}`)
      }

      // Recursively resolve dependencies
      for (const dep of descriptor.dependencies) {
        await resolveService(dep)
      }

      // Resolve dependencies and call factory with resolved values
      const resolvedDeps = descriptor.dependencies.map((dep) =>
        this.services.get(dep)
      )

      // Call the factory with resolved dependencies as positional arguments
      const service = await descriptor.factory(...resolvedDeps)
      this.services.set(token, service)

      visiting.delete(token)
      resolved.add(token)
    }

    // Resolve all registered services
    for (const token of this.descriptors.keys()) {
      await resolveService(token)
    }
  }
}
```

### Step 2.2: Write Tests

**File:** `src/container/type-safe-container.test.ts`

```typescript
import { describe, it, expect, beforeEach } from "bun:test"
import { Token, TypeSafeContainer } from "./index.js"

describe("TypeSafeContainer", () => {
  let container: TypeSafeContainer

  beforeEach(() => {
    container = new TypeSafeContainer()
  })

  describe("register", () => {
    it("should register a service with no dependencies", async () => {
      const ConfigToken = new Token<{ value: string }>("Config")
      
      container.register(
        ConfigToken,
        [],
        () => ({ value: "test" })
      )

      await container.build()
      const config = container.resolve(ConfigToken)
      
      expect(config.value).toBe("test")
    })

    it("should register a service with dependencies", async () => {
      const ConfigToken = new Token<{ value: string }>("Config")
      const ServiceToken = new Token<{ config: { value: string } }>("Service")

      container.register(
        ConfigToken,
        [],
        () => ({ value: "test" })
      )

      container.register(
        ServiceToken,
        [ConfigToken],
        (config) => ({ config })
      )

      await container.build()
      const service = container.resolve(ServiceToken)
      
      expect(service.config.value).toBe("test")
    })

    it("should support async factories", async () => {
      const ServiceToken = new Token<{ initialized: boolean }>("Service")

      container.register(
        ServiceToken,
        [],
        async () => {
          await new Promise((resolve) => setTimeout(resolve, 10))
          return { initialized: true }
        }
      )

      await container.build()
      const service = container.resolve(ServiceToken)
      
      expect(service.initialized).toBe(true)
    })

    it("should throw if registering after build", async () => {
      const Token1 = new Token<string>("Token1")
      
      container.register(Token1, [], () => "value")
      await container.build()

      const Token2 = new Token<string>("Token2")
      expect(() => {
        container.register(Token2, [], () => "value")
      }).toThrow("container is frozen")
    })
  })

  describe("registerInstance", () => {
    it("should register a pre-built instance", async () => {
      const ClientToken = new Token<{ id: string }>("Client")
      const client = { id: "test-client" }

      container.registerInstance(ClientToken, client)

      await container.build()
      const resolved = container.resolve(ClientToken)
      
      expect(resolved).toBe(client)
    })

    it("should allow instances to be dependencies", async () => {
      const ClientToken = new Token<{ id: string }>("Client")
      const ServiceToken = new Token<{ client: { id: string } }>("Service")

      const client = { id: "test-client" }
      container.registerInstance(ClientToken, client)

      container.register(
        ServiceToken,
        [ClientToken],
        (client) => ({ client })
      )

      await container.build()
      const service = container.resolve(ServiceToken)
      
      expect(service.client.id).toBe("test-client")
    })
  })

  describe("build", () => {
    it("should be idempotent", async () => {
      const Token1 = new Token<string>("Token1")
      container.register(Token1, [], () => "value")

      await container.build()
      await container.build()  // Should not throw

      expect(container.resolve(Token1)).toBe("value")
    })

    it("should throw if dependency is not registered", async () => {
      const Token1 = new Token<string>("Token1")
      const Token2 = new Token<string>("Token2")

      container.register(
        Token1,
        [Token2],
        (t2) => t2
      )

      expect(async () => {
        await container.build()
      }).toThrow("not registered")
    })

    it("should detect circular dependencies", async () => {
      const Token1 = new Token<string>("Token1")
      const Token2 = new Token<string>("Token2")
      const Token3 = new Token<string>("Token3")

      container.register(Token1, [Token2], (t2) => t2)
      container.register(Token2, [Token3], (t3) => t3)
      container.register(Token3, [Token1], (t1) => t1)

      expect(async () => {
        await container.build()
      }).toThrow("Circular dependency detected")
    })
  })

  describe("resolve", () => {
    it("should throw if container not built", () => {
      const Token1 = new Token<string>("Token1")
      container.register(Token1, [], () => "value")

      expect(() => {
        container.resolve(Token1)
      }).toThrow("must be built first")
    })

    it("should throw if service not found", async () => {
      const Token1 = new Token<string>("Token1")
      const Token2 = new Token<string>("Token2")

      container.register(Token1, [], () => "value")
      await container.build()

      expect(() => {
        container.resolve(Token2)
      }).toThrow("Service not found")
    })
  })

  describe("has", () => {
    it("should return true if service is registered", () => {
      const Token1 = new Token<string>("Token1")
      container.register(Token1, [], () => "value")

      expect(container.has(Token1)).toBe(true)
    })

    it("should return false if service is not registered", () => {
      const Token1 = new Token<string>("Token1")

      expect(container.has(Token1)).toBe(false)
    })
  })
})
```

---

## Phase 3: Migration

### Step 3.1: Update Plugin Entry Point

**File:** `src/index.ts`

Replace the manual service construction with container-based registration:

```typescript
import { Token, TypeSafeContainer } from "./container/index.js"

// Define tokens
const Tokens = {
  Client: new Token<OpencodeClient>("Client"),
  Shell: new Token<Shell>("Shell"),
  RepoRoot: new Token<string>("RepoRoot"),
  Config: new Token<ConfigManager>("Config"),
  IssueStorage: new Token<BeadsIssueStorage>("IssueStorage"),
  FocusManager: new Token<FocusManager>("FocusManager"),
  Logger: new Token<Logger>("Logger"),
  WorktreeManager: new Token<WorktreeManager>("WorktreeManager"),
  DelegationManager: new Token<DelegationManager>("DelegationManager"),
  TeamManager: new Token<TeamManager>("TeamManager"),
  ProjectManager: new Token<ProjectManager>("ProjectManager"),
}

export const ProjectsPlugin: Plugin = async (ctx) => {
  const { client, directory, worktree, $ } = ctx
  
  const typedClient = validateClientOrThrow(client)
  const log = createLogger(typedClient)
  await log.info("opencode-projects plugin initializing")

  const repoRoot = worktree || directory

  // Initialize container
  const container = new TypeSafeContainer()

  // Register services
  container.registerInstance(Tokens.Client, typedClient)
  container.registerInstance(Tokens.Shell, $)
  container.registerInstance(Tokens.RepoRoot, repoRoot)

  container.register(
    Tokens.Config,
    [],
    () => ConfigManager.loadOrThrow()
  )

  container.register(
    Tokens.Logger,
    [Tokens.Client],
    (client) => createLogger(client)
  )

  container.register(
    Tokens.IssueStorage,
    [Tokens.Logger],
    (logger) => new BeadsIssueStorage(logger)
  )

  container.register(
    Tokens.FocusManager,
    [],
    () => new FocusManager()
  )

  container.register(
    Tokens.WorktreeManager,
    [Tokens.RepoRoot, Tokens.Shell, Tokens.Logger],
    async (repoRoot, shell, logger) => {
      const manager = new WorktreeManager(repoRoot, shell, logger)
      await manager.detectVCS()
      return manager
    }
  )

  container.register(
    Tokens.DelegationManager,
    [Tokens.Logger, Tokens.Client, Tokens.Config],
    (logger, client, config) => {
      return new DelegationManager(logger, client, {
        timeoutMs: config.getDelegationTimeoutMs(),
        smallModelTimeoutMs: config.getSmallModelTimeoutMs(),
      })
    }
  )

  container.register(
    Tokens.TeamManager,
    [Tokens.Logger, Tokens.Client, Tokens.DelegationManager, Tokens.WorktreeManager, Tokens.Config],
    (logger, client, delegationManager, worktreeManager, config) => {
      return new TeamManager(logger, client, delegationManager, worktreeManager, {
        maxTeamSize: config.getTeamMaxSize(),
        retryFailedMembers: config.getTeamRetryFailedMembers(),
        smallModelTimeoutMs: config.getSmallModelTimeoutMs(),
        delegationTimeoutMs: config.getDelegationTimeoutMs(),
      })
    }
  )

  container.register(
    Tokens.ProjectManager,
    [Tokens.Config, Tokens.IssueStorage, Tokens.FocusManager, Tokens.Logger, Tokens.RepoRoot, Tokens.Client, Tokens.Shell, Tokens.TeamManager],
    (config, issueStorage, focus, logger, repoRoot, client, shell, teamManager) => {
      return new ProjectManager(
        config,
        issueStorage,
        focus,
        logger,
        repoRoot,
        client,
        shell,
        teamManager
      )
    }
  )

  // Build container
  await container.build()

  // Resolve services
  const projectManager = container.resolve(Tokens.ProjectManager)
  const delegationManager = container.resolve(Tokens.DelegationManager)
  const teamManager = container.resolve(Tokens.TeamManager)
  const logger = container.resolve(Tokens.Logger)
  const worktreeManager = container.resolve(Tokens.WorktreeManager)

  // Rest of plugin implementation...
  return {
    tool: { /* ... */ },
    // ... other hooks
  }
}
```

### Step 3.2: Update Tests

Update existing tests to use the new container:

```typescript
// In test files, create a test container
const createTestContainer = async () => {
  const container = new TypeSafeContainer()
  
  // Register test doubles
  container.registerInstance(Tokens.Client, mockClient)
  container.registerInstance(Tokens.Shell, mockShell)
  container.registerInstance(Tokens.RepoRoot, "/tmp/test")
  
  // Register services
  container.register(Tokens.Config, [], () => testConfig)
  container.register(Tokens.Logger, [Tokens.Client], (client) => createMockLogger())
  // ... etc
  
  await container.build()
  return container
}

// In tests
it("should create project manager", async () => {
  const container = await createTestContainer()
  const pm = container.resolve(Tokens.ProjectManager)
  
  expect(pm).toBeDefined()
})
```

---

## Phase 4: Verification

### Step 4.1: Run Tests

```bash
# Run container tests
bun test src/container/type-safe-container.test.ts

# Run all tests
bun test

# Run with coverage
bun test --coverage
```

### Step 4.2: Type Check

```bash
# Run TypeScript type checker
bun run typecheck
```

### Step 4.3: Integration Testing

```bash
# Test with live OpenCode instance
mkdir -p /tmp/opencode-test
cd /tmp/opencode-test
jj git init
echo "# Test" > README.md

# Test plugin initialization
opencode run "Use project-list to list all projects"

# Test project creation
opencode run "Create a project called 'test-proj' with storage='local'"

# Test issue creation
opencode run "Focus on project test-proj-XXXXX and create an issue titled 'Test issue'"
```

### Step 4.4: Verify No Regressions

- ✅ All hooks work correctly
- ✅ Type inference works as expected
- ✅ Error messages are clear
- ✅ No performance regression
- ✅ Documentation is complete

---

## Common Patterns

### Pattern 1: Service with Multiple Dependencies

```typescript
container.register(
  Tokens.ComplexService,
  [Tokens.A, Tokens.B, Tokens.C, Tokens.D],
  (a, b, c, d) => {
    return new ComplexService(a, b, c, d)
  }
)
```

### Pattern 2: Async Initialization

```typescript
container.register(
  Tokens.AsyncService,
  [Tokens.Config],
  async (config) => {
    const service = new AsyncService(config)
    await service.initialize()
    return service
  }
)
```

### Pattern 3: Conditional Registration

```typescript
if (config.isProduction()) {
  container.register(
    Tokens.Logger,
    [Tokens.Config],
    (config) => new ProductionLogger(config)
  )
} else {
  container.register(
    Tokens.Logger,
    [Tokens.Config],
    (config) => new DebugLogger(config)
  )
}
```

### Pattern 4: Pre-Built Instances

```typescript
const client = new OpencodeClient(apiKey)
container.registerInstance(Tokens.Client, client)

const shell = new Shell()
container.registerInstance(Tokens.Shell, shell)
```

---

## Troubleshooting

### Issue: "Cannot resolve service X: container must be built first"

**Cause:** You called `resolve()` before `build()`

**Solution:** Always call `await container.build()` before resolving services

```typescript
const container = new TypeSafeContainer()
container.register(/* ... */)
await container.build()  // ← Don't forget this
const service = container.resolve(Tokens.Service)
```

### Issue: "Service X depends on Y, which is not registered"

**Cause:** You declared a dependency but didn't register it

**Solution:** Register all dependencies before calling `build()`

```typescript
container.register(Tokens.A, [Tokens.B], (b) => new A(b))
// ❌ Missing: container.register(Tokens.B, [], () => new B())
await container.build()  // ❌ Error: B not registered
```

### Issue: "Circular dependency detected: A → B → A"

**Cause:** Services have circular dependencies

**Solution:** Refactor to break the cycle

```typescript
// ❌ Circular
container.register(Tokens.A, [Tokens.B], (b) => new A(b))
container.register(Tokens.B, [Tokens.A], (a) => new B(a))

// ✅ Fixed: B doesn't depend on A
container.register(Tokens.A, [Tokens.B], (b) => new A(b))
container.register(Tokens.B, [], () => new B())
```

### Issue: TypeScript error "Expected 2 arguments, got 1"

**Cause:** Factory signature doesn't match token array

**Solution:** Add missing parameters

```typescript
// ❌ Error: missing shell parameter
container.register(
  Tokens.Service,
  [Tokens.Config, Tokens.Shell],
  (config) => new Service(config)  // ❌ Missing shell
)

// ✅ Fixed
container.register(
  Tokens.Service,
  [Tokens.Config, Tokens.Shell],
  (config, shell) => new Service(config, shell)
)
```

---

## Success Checklist

- ✅ Type definitions compile without errors
- ✅ Container implementation passes all tests
- ✅ Plugin entry point uses new container
- ✅ All services register cleanly
- ✅ No `c.resolve()` calls in factories
- ✅ Async factories work correctly
- ✅ Cycle detection works
- ✅ Error messages are clear
- ✅ All existing tests pass
- ✅ Integration tests pass
- ✅ No performance regression
- ✅ Documentation is complete

---

## Next Steps

1. **Implement Phase 1** — Create type definitions
2. **Write tests** — Ensure type inference works
3. **Implement Phase 2** — Create container
4. **Run tests** — Verify container works
5. **Implement Phase 3** — Migrate plugin
6. **Run integration tests** — Verify all hooks work
7. **Implement Phase 4** — Verify and document
8. **Commit changes** — Push to repository

---

**Implementation Status:** Ready  
**Estimated Time:** 6-10 hours  
**Complexity:** Medium  
**Risk Level:** Low

---

*Last updated: 2026-03-04*
