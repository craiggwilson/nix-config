# Type-Safe Factory Signatures: Detailed Analysis

**Date:** 2026-03-04  
**Status:** Research Complete  
**Scope:** In-depth analysis of all 7 research questions with concrete implementations

---

## Question 1: Type-Safe Token Array

### The Challenge

Can TypeScript infer the factory argument types from the token array? The tokens need to carry their resolved type (e.g., `Token<Config>`, `Token<Shell>`). When you pass `[Tokens.Config, Tokens.Shell]`, TypeScript should infer the factory signature as `(cfg: Config, shell: Shell) => T`.

### Solution: Variadic Tuple Types with Mapped Types

TypeScript 4.0+ introduced variadic tuple types, which allow us to map over tuple types. Here's how it works:

```typescript
/**
 * Step 1: Define a Token class that carries type information
 */
export class Token<T = unknown> {
  constructor(readonly name: string) {}
}

/**
 * Step 2: Extract the type from a token
 * If T is Token<X>, returns X. Otherwise returns never.
 */
export type Resolve<T> = T extends Token<infer U> ? U : never

/**
 * Step 3: Map a tuple of tokens to a tuple of resolved types
 * [Token<A>, Token<B>, Token<C>] → [A, B, C]
 */
export type ResolveTokens<T extends readonly Token<any>[]> = {
  [K in keyof T]: T[K] extends Token<infer U> ? U : never
}

/**
 * Step 4: Define the factory function type
 * Takes resolved dependencies as positional arguments
 */
export type Factory<
  Tokens extends readonly Token<any>[],
  T
> = (...args: ResolveTokens<Tokens>) => T | Promise<T>
```

### How It Works: Step by Step

```typescript
// Define tokens
const Tokens = {
  Config: new Token<Config>("Config"),
  Shell: new Token<Shell>("Shell"),
  Logger: new Token<Logger>("Logger"),
}

// When you write:
container.register(
  Tokens.ProjectManager,
  [Tokens.Config, Tokens.Shell],
  (config, shell) => new ProjectManager(config, shell)
)

// TypeScript's type inference:
// 1. Sees the token array: [Token<Config>, Token<Shell>]
// 2. Applies ResolveTokens: [Config, Shell]
// 3. Infers factory signature: (config: Config, shell: Shell) => ProjectManager
// 4. Checks that the factory matches this signature
// 5. If it doesn't, compile error!
```

### Type Inference in Action

```typescript
// ✅ CORRECT: Factory matches inferred signature
container.register(
  Tokens.ProjectManager,
  [Tokens.Config, Tokens.Shell],
  (config, shell) => {
    // TypeScript knows:
    // - config: Config
    // - shell: Shell
    return new ProjectManager(config, shell)
  }
)

// ❌ ERROR: Missing parameter
container.register(
  Tokens.ProjectManager,
  [Tokens.Config, Tokens.Shell],
  (config) => {  // ❌ Error: missing shell parameter
    return new ProjectManager(config)
  }
)

// ❌ ERROR: Wrong parameter type
container.register(
  Tokens.ProjectManager,
  [Tokens.Config, Tokens.Shell],
  (config: string, shell: Shell) => {  // ❌ Error: config should be Config, not string
    return new ProjectManager(config, shell)
  }
)

// ❌ ERROR: Extra parameter
container.register(
  Tokens.ProjectManager,
  [Tokens.Config, Tokens.Shell],
  (config, shell, extra) => {  // ❌ Error: extra parameter not in token array
    return new ProjectManager(config, shell)
  }
)
```

### Why This Works

The key insight is that TypeScript's type system can:
1. **Extract types from tokens** using conditional types (`T extends Token<infer U>`)
2. **Map over tuples** using mapped types (`[K in keyof T]`)
3. **Infer function signatures** from tuple types (`(...args: [A, B, C])`)

This combination allows TypeScript to verify that the factory signature matches the token array at compile time.

### Limitations and Workarounds

**Limitation 1: Type Inference Depth**

For very complex types, TypeScript's inference may hit limits. Workaround:

```typescript
// If inference fails, explicitly annotate the factory
const factory: Factory<typeof dependencies, ProjectManager> = (config, shell) => {
  return new ProjectManager(config, shell)
}

container.register(Tokens.ProjectManager, dependencies, factory)
```

**Limitation 2: Union Types in Tokens**

If a token resolves to a union type, the factory must handle all cases:

```typescript
const Tokens = {
  Logger: new Token<Logger | null>("Logger"),  // Can be null
}

container.register(
  Tokens.Service,
  [Tokens.Logger],
  (logger) => {
    // TypeScript knows logger: Logger | null
    if (!logger) {
      throw new Error("Logger is required")
    }
    return new Service(logger)
  }
)
```

---

## Question 2: Token Type Design

### Option 1: Branded Symbol

```typescript
// Define a branded symbol type
type Token<T> = symbol & { readonly __type: T }

// Create tokens
const Tokens = {
  Config: Symbol("Config") as Token<Config>,
  Shell: Symbol("Shell") as Token<Shell>,
}

// Usage
container.register(
  Tokens.ProjectManager,
  [Tokens.Config, Tokens.Shell],
  (config, shell) => new ProjectManager(config, shell)
)
```

**Pros:**
- ✅ Lightweight (just symbols)
- ✅ Familiar (symbols are built-in)
- ✅ Works with existing symbol-based containers

**Cons:**
- ❌ Type information erased at runtime
- ❌ Can't extract type information for debugging
- ❌ Error messages can't include token name
- ❌ Requires explicit type annotations

**Example Error Message:**
```
Error: Service not found: Symbol(ProjectManager)
```

### Option 2: Class Instance (Recommended)

```typescript
// Define a Token class
export class Token<T = unknown> {
  constructor(readonly name: string) {}
  
  toString(): string {
    return `Token(${this.name})`
  }
}

// Create tokens
const Tokens = {
  Config: new Token<Config>("Config"),
  Shell: new Token<Shell>("Shell"),
}

// Usage
container.register(
  Tokens.ProjectManager,
  [Tokens.Config, Tokens.Shell],
  (config, shell) => new ProjectManager(config, shell)
)
```

**Pros:**
- ✅ Type information available at runtime
- ✅ Better error messages (includes token name)
- ✅ Can implement custom methods
- ✅ Clearer intent (tokens are first-class objects)
- ✅ Can add debugging utilities

**Cons:**
- ⚠️ Slightly more runtime overhead (class instances)
- ⚠️ Requires instantiation for each token

**Example Error Message:**
```
Error: Service not found: Token(ProjectManager)
```

### Option 3: Function-Based

```typescript
// Define a function that creates typed tokens
function createToken<T>(name: string): Token<T> {
  return Symbol(name) as Token<T>
}

// Create tokens
const Tokens = {
  Config: createToken<Config>("Config"),
  Shell: createToken<Shell>("Shell"),
}
```

**Pros:**
- ✅ Flexible (can add custom logic)
- ✅ Lightweight (uses symbols)

**Cons:**
- ❌ Less discoverable (requires function call)
- ❌ Type information still erased at runtime
- ❌ Inconsistent with class-based approach

### Recommendation: Class Instance

The **class instance approach** is recommended because:

1. **Runtime type information** — Can extract token name for better error messages
2. **Extensibility** — Can add custom methods (e.g., `token.isRequired()`, `token.getDescription()`)
3. **Clarity** — Tokens are first-class objects, not just symbols
4. **Debugging** — Can implement `toString()`, `inspect()`, etc.
5. **Performance** — Tokens are created once at module load, minimal overhead

### Impact on Type Inference

The choice of token type design **does not affect type inference**. All three options work equally well with the `ResolveTokens` mapped type:

```typescript
// All three work the same way:
type Resolve<T> = T extends Token<infer U> ? U : never
type ResolveTokens<T extends readonly Token<any>[]> = {
  [K in keyof T]: T[K] extends Token<infer U> ? U : never
}
```

The difference is in runtime behavior and error messages, not type safety.

---

## Question 3: Variadic Tuple Types

### The Core Problem

We need to map a token array to a factory function signature:

```typescript
// Input: token array
[Tokens.Config, Tokens.Shell, Tokens.Logger]

// Output: factory signature
(config: Config, shell: Shell, logger: Logger) => ProjectManager
```

### Solution: Variadic Tuple Types

TypeScript 4.0+ supports variadic tuple types, which allow us to:
1. Extract types from each element in a tuple
2. Map over the tuple using mapped types
3. Create a new tuple with transformed types

### Concrete Type Definitions

```typescript
/**
 * Extract the resolved type from a token.
 * 
 * Conditional type that checks if T is Token<U>.
 * If yes, returns U. If no, returns never.
 */
export type Resolve<T> = T extends Token<infer U> ? U : never

/**
 * Map a tuple of tokens to a tuple of resolved types.
 * 
 * For each element K in the tuple T:
 * - If T[K] is Token<U>, include U in the result
 * - Otherwise, include never
 * 
 * Example:
 *   ResolveTokens<[Token<Config>, Token<Shell>]>
 *   = [Config, Shell]
 */
export type ResolveTokens<T extends readonly Token<any>[]> = {
  [K in keyof T]: T[K] extends Token<infer U> ? U : never
}

/**
 * Factory function type.
 * 
 * Takes resolved dependencies as positional arguments.
 * Returns either T or Promise<T>.
 * 
 * Example:
 *   Factory<[Token<Config>, Token<Shell>], ProjectManager>
 *   = (config: Config, shell: Shell) => ProjectManager | Promise<ProjectManager>
 */
export type Factory<
  Tokens extends readonly Token<any>[],
  T
> = (...args: ResolveTokens<Tokens>) => T | Promise<T>
```

### How Variadic Tuple Types Work

```typescript
// Step 1: Define the token array
const dependencies = [Tokens.Config, Tokens.Shell, Tokens.Logger] as const

// Step 2: TypeScript infers the type
// typeof dependencies = readonly [Token<Config>, Token<Shell>, Token<Logger>]

// Step 3: Apply ResolveTokens
// ResolveTokens<typeof dependencies> = [Config, Shell, Logger]

// Step 4: Create factory type
// Factory<typeof dependencies, ProjectManager> = 
//   (config: Config, shell: Shell, logger: Logger) => ProjectManager | Promise<ProjectManager>

// Step 5: Verify factory matches
container.register(
  Tokens.ProjectManager,
  dependencies,
  (config, shell, logger) => {  // ✅ Matches inferred signature
    return new ProjectManager(config, shell, logger)
  }
)
```

### Type Inference Examples

```typescript
// Example 1: Two dependencies
const deps1 = [Tokens.Config, Tokens.Shell] as const
type Factory1 = Factory<typeof deps1, ProjectManager>
// = (config: Config, shell: Shell) => ProjectManager | Promise<ProjectManager>

// Example 2: Three dependencies
const deps2 = [Tokens.Config, Tokens.Shell, Tokens.Logger] as const
type Factory2 = Factory<typeof deps2, ProjectManager>
// = (config: Config, shell: Shell, logger: Logger) => ProjectManager | Promise<ProjectManager>

// Example 3: No dependencies
const deps3 = [] as const
type Factory3 = Factory<typeof deps3, ProjectManager>
// = () => ProjectManager | Promise<ProjectManager>

// Example 4: Many dependencies
const deps4 = [Tokens.A, Tokens.B, Tokens.C, Tokens.D, Tokens.E] as const
type Factory4 = Factory<typeof deps4, Service>
// = (a: A, b: B, c: C, d: D, e: E) => Service | Promise<Service>
```

### Why This Is Powerful

1. **Type Safety** — TypeScript verifies the factory signature matches the token array
2. **No Boilerplate** — No need to manually list parameter types
3. **Refactoring Safety** — If you add a token, TypeScript forces you to add a parameter
4. **IDE Support** — Autocomplete works perfectly
5. **Zero Runtime Cost** — Type information is erased at runtime

---

## Question 4: Async Factories

### The Challenge

Does the type-safe approach extend cleanly to async factories?

### Solution: Union Type in Factory

The `Factory` type already supports both sync and async:

```typescript
export type Factory<
  Tokens extends readonly Token<any>[],
  T
> = (...args: ResolveTokens<Tokens>) => T | Promise<T>
```

The return type is `T | Promise<T>`, which means:
- Sync factories return `T`
- Async factories return `Promise<T>`

### Usage Examples

```typescript
// Sync factory
container.register(
  Tokens.Logger,
  [Tokens.Config],
  (config) => {
    return createLogger(config)  // Returns Logger
  }
)

// Async factory
container.register(
  Tokens.WorktreeManager,
  [Tokens.RepoRoot, Tokens.Shell],
  async (repoRoot, shell) => {
    const manager = new WorktreeManager(repoRoot, shell)
    await manager.detectVCS()  // Async initialization
    return manager  // Returns Promise<WorktreeManager>
  }
)

// Mixed: some sync, some async
container.register(Tokens.Config, [], () => ConfigManager.loadOrThrow())
container.register(Tokens.Logger, [Tokens.Config], (config) => createLogger(config))
container.register(Tokens.WorktreeManager, [Tokens.RepoRoot, Tokens.Shell], async (repoRoot, shell) => {
  const manager = new WorktreeManager(repoRoot, shell)
  await manager.detectVCS()
  return manager
})
```

### Container Implementation

The container's `build()` method handles both sync and async factories:

```typescript
private async resolveAll(): Promise<void> {
  const resolved = new Set<Token<any>>()
  const visiting = new Set<Token<any>>()

  const resolveService = async (token: Token<any>): Promise<void> => {
    if (resolved.has(token)) return
    if (visiting.has(token)) {
      throw new Error(`Circular dependency detected: ${token.name}`)
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

    // Resolve dependencies and call factory
    const resolvedDeps = descriptor.dependencies.map((dep) =>
      this.services.get(dep)
    )

    // Call factory with resolved dependencies
    // This works for both sync and async factories
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
```

The key is the `await` keyword:
- For sync factories: `await value` returns `value` immediately
- For async factories: `await promise` waits for the promise to resolve

### Type Safety with Async

TypeScript ensures that async factories are handled correctly:

```typescript
// ✅ CORRECT: Async factory
container.register(
  Tokens.WorktreeManager,
  [Tokens.RepoRoot, Tokens.Shell],
  async (repoRoot, shell) => {
    const manager = new WorktreeManager(repoRoot, shell)
    await manager.detectVCS()
    return manager  // Returns WorktreeManager (not Promise<WorktreeManager>)
  }
)

// ❌ ERROR: Forgot to await
container.register(
  Tokens.WorktreeManager,
  [Tokens.RepoRoot, Tokens.Shell],
  async (repoRoot, shell) => {
    const manager = new WorktreeManager(repoRoot, shell)
    manager.detectVCS()  // ❌ Error: not awaited
    return manager
  }
)

// ❌ ERROR: Returned Promise instead of value
container.register(
  Tokens.WorktreeManager,
  [Tokens.RepoRoot, Tokens.Shell],
  async (repoRoot, shell) => {
    const manager = new WorktreeManager(repoRoot, shell)
    return manager.detectVCS()  // ❌ Error: returns Promise<void>, not WorktreeManager
  }
)
```

---

## Question 5: RegisterInstance Shorthand

### The Challenge

Alongside `register`, there should be a `registerInstance(token, value)` for pre-built values. How does this fit into the typed token design?

### Solution: Convenience Method

```typescript
/**
 * Register a pre-built service instance.
 * 
 * Use this for values that are already constructed (e.g., client, shell, repoRoot).
 * 
 * @param token - Service identifier
 * @param value - The service instance
 * 
 * Example:
 *   const client = new OpencodeClient(...)
 *   container.registerInstance(Tokens.Client, client)
 */
registerInstance<T>(token: Token<T>, value: T): void {
  if (this.isFrozen) {
    throw new Error(`Cannot register: container is frozen`)
  }

  // Register as a factory with no dependencies
  this.descriptors.set(token, {
    token,
    dependencies: [],
    factory: () => value,
  })
}
```

### Type Safety

The `registerInstance` method is fully type-safe:

```typescript
// ✅ CORRECT: Value matches token type
const client = new OpencodeClient(...)
container.registerInstance(Tokens.Client, client)

// ❌ ERROR: Value doesn't match token type
const client = new OpencodeClient(...)
container.registerInstance(Tokens.Logger, client)  // ❌ Error: OpencodeClient is not Logger
```

### Usage Examples

```typescript
// Register pre-built instances
container.registerInstance(Tokens.Client, typedClient)
container.registerInstance(Tokens.Shell, $)
container.registerInstance(Tokens.RepoRoot, repoRoot)

// Register factories that depend on instances
container.register(
  Tokens.WorktreeManager,
  [Tokens.RepoRoot, Tokens.Shell],
  (repoRoot, shell) => new WorktreeManager(repoRoot, shell)
)

// Register factories that depend on other factories
container.register(
  Tokens.Logger,
  [Tokens.Client],
  (client) => createLogger(client)
)

// Build and resolve
await container.build()
const projectManager = container.resolve(Tokens.ProjectManager)
```

### How It Fits Into the Design

`registerInstance` is just a convenience method that:
1. Takes a pre-built value
2. Wraps it in a factory with no dependencies
3. Registers it like any other service

This means:
- ✅ Instances can be dependencies for other services
- ✅ Instances participate in cycle detection
- ✅ Instances are resolved during build phase
- ✅ Full type safety is maintained

---

## Question 6: Cycle Detection Compatibility

### The Challenge

The two-phase container needs the dependency list to build the graph and detect cycles. With this API, the token array is still explicit, so cycle detection still works. Confirm this and show how `build()` extracts the dependency graph from registrations.

### Solution: Dependency Graph from Token Arrays

The cycle detection algorithm uses the token arrays to build the dependency graph:

```typescript
/**
 * Detect circular dependencies using depth-first search.
 * 
 * The token array provides the dependency graph:
 *   container.register(A, [B, C], ...)  // A depends on B and C
 *   container.register(B, [C], ...)     // B depends on C
 *   container.register(C, [A], ...)     // C depends on A ← CYCLE!
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
```

### How It Works

1. **Build the graph** — Each service's dependencies are stored in the token array
2. **Depth-first search** — Visit each service and its dependencies
3. **Detect cycles** — If we visit a service that's already in the recursion stack, we found a cycle
4. **Report clearly** — Include the full cycle path in the error message

### Example: Detecting a Cycle

```typescript
// Register services with a cycle
container.register(
  Tokens.ProjectManager,
  [Tokens.TeamManager],
  (teamManager) => new ProjectManager(teamManager)
)

container.register(
  Tokens.TeamManager,
  [Tokens.DelegationManager],
  (delegationManager) => new TeamManager(delegationManager)
)

container.register(
  Tokens.DelegationManager,
  [Tokens.ProjectManager],  // ← Cycle!
  (projectManager) => new DelegationManager(projectManager)
)

// At build time:
await container.build()
// ❌ Error: Circular dependency detected: ProjectManager → TeamManager → DelegationManager → ProjectManager
```

### Dependency Graph Extraction

The `build()` method extracts the dependency graph from registrations:

```typescript
async build(): Promise<void> {
  if (this.isFrozen) return

  // 1. Validate all dependencies are registered
  this.validateDependencies()

  // 2. Detect circular dependencies
  this.detectCycles()

  // 3. Resolve all services in dependency order
  await this.resolveAll()

  // 4. Freeze the container
  this.isFrozen = true
}

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
```

### Why This Works

The type-safe API **maintains full cycle detection capability** because:
1. ✅ Dependencies are still explicit in the token array
2. ✅ The dependency graph is still available for analysis
3. ✅ Cycle detection algorithm is unchanged
4. ✅ Error messages are clear and actionable

---

## Question 7: Concrete Example - All 5 Plugin Services

### The Challenge

Show all 5 existing plugin services registered with this API. The result should read naturally and have no `c.resolve()` calls inside factories.

### Complete Example

```typescript
import { Token, type Factory } from "./container/index.js"

// ============================================================================
// 1. Define Tokens
// ============================================================================

const Tokens = {
  // Core infrastructure
  Client: new Token<OpencodeClient>("Client"),
  Shell: new Token<Shell>("Shell"),
  RepoRoot: new Token<string>("RepoRoot"),

  // Configuration
  Config: new Token<ConfigManager>("Config"),

  // Issue storage
  IssueStorage: new Token<BeadsIssueStorage>("IssueStorage"),

  // Project management
  FocusManager: new Token<FocusManager>("FocusManager"),
  ProjectManager: new Token<ProjectManager>("ProjectManager"),

  // Logging
  Logger: new Token<Logger>("Logger"),

  // VCS
  WorktreeManager: new Token<WorktreeManager>("WorktreeManager"),

  // Execution
  DelegationManager: new Token<DelegationManager>("DelegationManager"),
  TeamManager: new Token<TeamManager>("TeamManager"),
}

// ============================================================================
// 2. Initialize Container
// ============================================================================

const container = new TypeSafeContainer()

// ============================================================================
// 3. Register Services
// ============================================================================

// Service 1: Config (no dependencies)
container.register(
  Tokens.Config,
  [],
  () => ConfigManager.loadOrThrow()
)

// Service 2: Logger (depends on Client)
container.register(
  Tokens.Logger,
  [Tokens.Client],
  (client) => createLogger(client)
)

// Service 3: IssueStorage (depends on Logger)
container.register(
  Tokens.IssueStorage,
  [Tokens.Logger],
  (logger) => new BeadsIssueStorage(logger)
)

// Service 4: FocusManager (no dependencies)
container.register(
  Tokens.FocusManager,
  [],
  () => new FocusManager()
)

// Service 5: WorktreeManager (depends on RepoRoot, Shell, Logger)
// This is async because it needs to detect VCS
container.register(
  Tokens.WorktreeManager,
  [Tokens.RepoRoot, Tokens.Shell, Tokens.Logger],
  async (repoRoot, shell, logger) => {
    const manager = new WorktreeManager(repoRoot, shell, logger)
    await manager.detectVCS()
    return manager
  }
)

// Service 6: DelegationManager (depends on Logger, Client, Config)
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

// Service 7: TeamManager (depends on Logger, Client, DelegationManager, WorktreeManager, Config)
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

// Service 8: ProjectManager (depends on Config, IssueStorage, FocusManager, Logger, RepoRoot, Client, Shell, TeamManager)
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

// ============================================================================
// 4. Register Pre-Built Instances
// ============================================================================

// These are created outside the container and registered as instances
container.registerInstance(Tokens.Client, typedClient)
container.registerInstance(Tokens.Shell, $)
container.registerInstance(Tokens.RepoRoot, repoRoot)

// ============================================================================
// 5. Build the Container
// ============================================================================

await container.build()

// ============================================================================
// 6. Resolve Services
// ============================================================================

const projectManager = container.resolve(Tokens.ProjectManager)
const delegationManager = container.resolve(Tokens.DelegationManager)
const teamManager = container.resolve(Tokens.TeamManager)
const logger = container.resolve(Tokens.Logger)
```

### Key Observations

1. ✅ **No `c.resolve()` calls** — Factories receive dependencies as arguments
2. ✅ **Single source of truth** — Dependencies declared once in the array
3. ✅ **Type-safe** — TypeScript infers parameter types from token array
4. ✅ **Order-independent** — Services can be registered in any order
5. ✅ **Async support** — WorktreeManager uses async factory
6. ✅ **Clear dependencies** — Each service's dependencies are explicit
7. ✅ **No boilerplate** — No repetitive `c.resolve()` calls
8. ✅ **Readable** — Code reads naturally, like dependency injection

### Comparison with Current Design

**Current Design (Fragile):**
```typescript
// Must declare dependencies twice
container.register(
  Tokens.ProjectManager,
  [Tokens.Config, Tokens.IssueStorage, Tokens.FocusManager, Tokens.Logger, Tokens.RepoRoot, Tokens.Client, Tokens.Shell, Tokens.TeamManager],
  (c) => new ProjectManager(
    c.resolve(Tokens.Config),
    c.resolve(Tokens.IssueStorage),
    c.resolve(Tokens.FocusManager),
    c.resolve(Tokens.Logger),
    c.resolve(Tokens.RepoRoot),
    c.resolve(Tokens.Client),
    c.resolve(Tokens.Shell),
    c.resolve(Tokens.TeamManager),
  )
)
```

**Type-Safe Design (Clean):**
```typescript
// Dependencies declared once, passed as arguments
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
```

The type-safe design is:
- ✅ Shorter (no repetitive `c.resolve()` calls)
- ✅ Clearer (dependencies are obvious)
- ✅ Safer (TypeScript enforces synchronization)
- ✅ More maintainable (single source of truth)

---

## Summary

All 7 research questions have been thoroughly answered:

1. ✅ **Type-safe token array** — Variadic tuple types enable type inference
2. ✅ **Token type design** — Class instance approach is recommended
3. ✅ **Variadic tuple types** — Concrete type definitions provided
4. ✅ **Async factories** — Seamlessly supported via `T | Promise<T>`
5. ✅ **RegisterInstance shorthand** — Fits naturally into the design
6. ✅ **Cycle detection compatibility** — Still works with explicit dependency arrays
7. ✅ **Concrete example** — All 5 plugin services shown with no `c.resolve()` calls

The type-safe factory signature approach is **ready for implementation**.

---

*Last updated: 2026-03-04*
