# Composable Hook Registry with DI Container

**Date:** 2026-03-04  
**Status:** Complete  
**Scope:** Design a composable hook system with lightweight DI for opencode-projects-plugin

---

## Executive Summary

This research explores a design where hooks are compartmentalized units that self-register with a lightweight DI container, rather than methods on a central HookRegistry class. The design supports multiple handlers per hook name, keeps hooks close to their consumers, and minimizes the role of `src/index.ts`.

**Recommendation:** Adopt a **hand-rolled container with typed hook composition** that:
1. Uses a generic `Hook<TInput, TOutput>` interface with per-hook-name type definitions
2. Composes multiple handlers via sequential mutation (pipeline pattern)
3. Employs a simple service locator pattern for DI (no decorators, no magic)
4. Has modules export `register(container)` functions for self-registration
5. Keeps hook implementations in the modules that need them

---

## 1. Hook Interface Design

### 1.1 Options Considered

#### Option A: Typed Interface Per Hook Name

```typescript
// Each hook has its own interface
interface ChatSystemTransformHook {
  (input: ChatSystemInput, output: ChatSystemOutput): Promise<void>
}

interface SessionCompactingHook {
  (input: CompactingInput, output: CompactingOutput): Promise<void>
}
```

**Pros:**
- Maximum type safety
- Clear contracts per hook
- IDE autocomplete for each hook's parameters

**Cons:**
- Boilerplate for each new hook
- No unified way to compose hooks
- Hard to build generic composition utilities

#### Option B: Generic `Hook<TInput, TOutput>` Interface (Recommended)

```typescript
/**
 * A hook handler that transforms output based on input.
 * Hooks are called sequentially; each handler mutates the output.
 */
type HookHandler<TInput, TOutput> = (input: TInput, output: TOutput) => Promise<void> | void

/**
 * Registry of hook handlers by name.
 * Multiple handlers can be registered for the same hook name.
 */
interface HookRegistry {
  register<TInput, TOutput>(
    name: string,
    handler: HookHandler<TInput, TOutput>,
    options?: HookOptions
  ): void
  
  getHandlers<TInput, TOutput>(name: string): HookHandler<TInput, TOutput>[]
}

interface HookOptions {
  priority?: number  // Lower runs first (default: 100)
}
```

**Pros:**
- Single generic interface for all hooks
- Easy to build composition utilities
- Flexible for new hook types

**Cons:**
- Less type safety at registration time (name is a string)
- Need separate type definitions for input/output per hook

#### Option C: Typed Hook Names with Mapped Types

```typescript
// Define all hook signatures in one place
interface HookSignatures {
  "experimental.chat.system.transform": {
    input: ChatSystemInput
    output: ChatSystemOutput
  }
  "experimental.session.compacting": {
    input: CompactingInput
    output: CompactingOutput
  }
  "shell.env": {
    input: ShellEnvInput
    output: ShellEnvOutput
  }
  "event": {
    input: EventInput
    output: void
  }
  "config": {
    input: ConfigInput
    output: void
  }
}

type HookName = keyof HookSignatures

type HookHandler<K extends HookName> = (
  input: HookSignatures[K]["input"],
  output: HookSignatures[K]["output"]
) => Promise<void> | void

interface HookRegistry {
  register<K extends HookName>(
    name: K,
    handler: HookHandler<K>,
    options?: HookOptions
  ): void
  
  getHandlers<K extends HookName>(name: K): HookHandler<K>[]
}
```

**Pros:**
- Full type safety for hook names and signatures
- Single source of truth for hook types
- Compile-time errors for invalid hook names

**Cons:**
- More complex type definitions
- All hook types must be defined upfront
- Slightly harder to add new hooks (must update HookSignatures)

### 1.2 Recommendation: Option C (Typed Hook Names)

Option C provides the best balance of type safety and flexibility. The `HookSignatures` interface serves as documentation and ensures compile-time safety. Adding a new hook requires:

1. Add entry to `HookSignatures`
2. Define input/output types
3. Register handlers in relevant modules

---

## 2. Composition Semantics

### 2.1 Options Considered

#### Option A: Sequential Mutation (Pipeline)

Each handler receives the same input and output objects. Handlers mutate the output in sequence.

```typescript
async function executeHook<K extends HookName>(
  registry: HookRegistry,
  name: K,
  input: HookSignatures[K]["input"],
  output: HookSignatures[K]["output"]
): Promise<void> {
  const handlers = registry.getHandlers(name)
  for (const handler of handlers) {
    await handler(input, output)
  }
}
```

**Pros:**
- Simple mental model
- Matches current OpenCode hook semantics
- Each handler can see previous handlers' mutations
- Easy to implement

**Cons:**
- Order matters (need priority system)
- Handlers can interfere with each other

#### Option B: Parallel Execution with Merge

All handlers run concurrently; results are merged.

```typescript
async function executeHook<K extends HookName>(
  registry: HookRegistry,
  name: K,
  input: HookSignatures[K]["input"]
): Promise<HookSignatures[K]["output"][]> {
  const handlers = registry.getHandlers(name)
  return Promise.all(handlers.map(h => h(input)))
}
```

**Pros:**
- Faster for independent handlers
- No ordering concerns

**Cons:**
- Doesn't match OpenCode's mutation-based API
- Complex merge logic needed
- Not suitable for all hook types

#### Option C: Reduce Pattern

Each handler returns a new output; outputs are chained.

```typescript
async function executeHook<K extends HookName>(
  registry: HookRegistry,
  name: K,
  input: HookSignatures[K]["input"],
  initialOutput: HookSignatures[K]["output"]
): Promise<HookSignatures[K]["output"]> {
  const handlers = registry.getHandlers(name)
  return handlers.reduce(
    async (accPromise, handler) => handler(input, await accPromise),
    Promise.resolve(initialOutput)
  )
}
```

**Pros:**
- Immutable-friendly
- Clear data flow

**Cons:**
- Requires handlers to return output
- Doesn't match OpenCode's void-returning API

### 2.2 Recommendation: Option A (Sequential Mutation)

Sequential mutation matches OpenCode's existing hook semantics where handlers mutate an output object. Priority ordering handles the "who runs first" question.

```typescript
interface HookOptions {
  priority?: number  // Lower runs first. Default: 100
}
```

Priority guidelines:
- **0-49**: Framework/infrastructure hooks (run first)
- **50-99**: Core business logic
- **100**: Default priority
- **101-199**: Extensions/enhancements
- **200+**: Cleanup/finalization hooks

**Priority conflict resolution:** When two handlers have the same priority, they execute in registration order (stable sort).

**Error handling:** If a handler throws an error, the error is logged and execution continues with the next handler. This ensures partial hook execution even if one handler fails:

```typescript
async function executeHook<K extends HookName>(
  registry: HookRegistry,
  name: K,
  input: HookSignatures[K]["input"],
  output: HookSignatures[K]["output"],
  log: Logger
): Promise<void> {
  const handlers = registry.getHandlers(name)
  for (const handler of handlers) {
    try {
      await handler(input, output)
    } catch (error) {
      await log.warn(`Hook handler for ${name} failed: ${error}`)
      // Continue with next handler
    }
  }
}
```

---

## 3. DI Container Design

### 3.1 Options Considered

#### Option A: tsyringe

**Pattern:** Decorator-based DI with reflect-metadata

```typescript
import { injectable, inject, container } from "tsyringe"

@injectable()
class SessionCompactingHook {
  constructor(
    @inject("ProjectManager") private projectManager: ProjectManager,
    @inject("DelegationManager") private delegationManager: DelegationManager,
  ) {}
  
  async handle(input: CompactingInput, output: CompactingOutput): Promise<void> {
    // ...
  }
}

// Registration
container.register("ProjectManager", { useValue: projectManager })
container.register("SessionCompactingHook", { useClass: SessionCompactingHook })
```

**Pros:**
- Mature, well-documented
- Automatic dependency resolution
- Supports async factories

**Cons:**
- Requires decorators (experimental TypeScript feature)
- Requires reflect-metadata polyfill
- Magic behavior (harder to debug)
- Heavier than needed for this use case

#### Option B: awilix

**Pattern:** Explicit registration with cradle proxy

```typescript
import { createContainer, asClass, asValue, asFunction } from "awilix"

const container = createContainer()

container.register({
  projectManager: asValue(projectManager),
  delegationManager: asValue(delegationManager),
  sessionCompactingHook: asClass(SessionCompactingHook),
})

// Resolution via cradle
const hook = container.cradle.sessionCompactingHook
```

**Pros:**
- No decorators required
- Explicit registration
- Good TypeScript support
- Supports scopes

**Cons:**
- External dependency
- Cradle proxy can be confusing
- More features than needed

#### Option C: Hand-Rolled Service Locator (Recommended)

**Pattern:** Simple typed container with explicit registration

```typescript
/**
 * Lightweight service container for dependency injection.
 * Services are registered by token and resolved on demand.
 */
class Container {
  private services = new Map<string | symbol, unknown>()
  private factories = new Map<string | symbol, () => unknown>()
  
  register<T>(token: string | symbol, value: T): void {
    this.services.set(token, value)
  }
  
  registerFactory<T>(token: string | symbol, factory: () => T): void {
    this.factories.set(token, factory)
  }
  
  resolve<T>(token: string | symbol): T {
    if (this.services.has(token)) {
      return this.services.get(token) as T
    }
    if (this.factories.has(token)) {
      const factory = this.factories.get(token) as () => T
      const instance = factory()
      this.services.set(token, instance)  // Cache singleton
      return instance
    }
    throw new Error(`Service not registered: ${String(token)}`)
  }
  
  has(token: string | symbol): boolean {
    return this.services.has(token) || this.factories.has(token)
  }
}
```

**Pros:**
- No external dependencies
- Explicit and debuggable
- Full TypeScript support
- Minimal code (~50 lines)
- Easy to understand

**Cons:**
- No automatic dependency resolution
- Must manually wire dependencies
- No scope support (not needed for this use case)

### 3.2 Recommendation: Option C (Hand-Rolled)

A hand-rolled container is sufficient for this use case. The plugin has ~10 services and ~5 hooks. The overhead of tsyringe or awilix isn't justified. The hand-rolled approach:

- Keeps dependencies explicit
- Avoids decorator magic
- Is easy to test
- Has zero external dependencies

### 3.3 Container Validation

Before returning from plugin initialization, validate that all required services are registered:

```typescript
// src/container/validation.ts
export function validateContainer(container: Container): void {
  const requiredServices = [
    Tokens.ProjectManager,
    Tokens.DelegationManager,
    Tokens.TeamManager,
    Tokens.WorktreeManager,
    Tokens.Logger,
    Tokens.Config,
    Tokens.Client,
    Tokens.HookRegistry,
  ]
  
  for (const token of requiredServices) {
    if (!container.has(token)) {
      throw new Error(`Required service not registered: ${String(token)}`)
    }
  }
}
```

This catches registration errors at startup rather than at first use.

### 3.4 Typed Service Tokens

Use symbols for type-safe service resolution:

```typescript
// src/container/tokens.ts
export const Tokens = {
  // Managers
  ProjectManager: Symbol("ProjectManager"),
  DelegationManager: Symbol("DelegationManager"),
  TeamManager: Symbol("TeamManager"),
  WorktreeManager: Symbol("WorktreeManager"),
  
  // Infrastructure
  Logger: Symbol("Logger"),
  Config: Symbol("Config"),
  Client: Symbol("Client"),
  Shell: Symbol("Shell"),
  
  // Hooks
  HookRegistry: Symbol("HookRegistry"),
} as const

// Type-safe resolution
interface ServiceTypes {
  [Tokens.ProjectManager]: ProjectManager
  [Tokens.DelegationManager]: DelegationManager
  [Tokens.TeamManager]: TeamManager
  [Tokens.WorktreeManager]: WorktreeManager
  [Tokens.Logger]: Logger
  [Tokens.Config]: ConfigManager
  [Tokens.Client]: OpencodeClient
  [Tokens.Shell]: Shell
  [Tokens.HookRegistry]: HookRegistry
}

// Typed resolve method
resolve<K extends keyof ServiceTypes>(token: K): ServiceTypes[K]
```

---

## 4. Module Self-Registration

### 4.1 Options Considered

#### Option A: Export `register(container)` Function

Each module exports a function that registers its contributions:

```typescript
// src/execution/register.ts
export function register(container: Container): void {
  // Register services
  container.registerFactory(Tokens.DelegationManager, () => 
    new DelegationManager(
      container.resolve(Tokens.Logger),
      container.resolve(Tokens.Client),
      container.resolve(Tokens.Config),
    )
  )
  
  // Register hooks
  const hookRegistry = container.resolve(Tokens.HookRegistry)
  hookRegistry.register("event", createEventHook(container))
}
```

**Pros:**
- Explicit and clear
- Easy to test (call register with mock container)
- Module controls its own registration
- No magic discovery

**Cons:**
- Must import and call each module's register function
- Order of registration matters

#### Option B: Export Hook Descriptors

Each module exports a list of hook descriptors:

```typescript
// src/execution/hooks.ts
export const hooks: HookDescriptor[] = [
  {
    name: "event",
    handler: createEventHook,
    dependencies: [Tokens.DelegationManager, Tokens.ProjectManager],
    priority: 100,
  },
]
```

**Pros:**
- Declarative
- Easy to introspect
- Container can auto-wire dependencies

**Cons:**
- More complex infrastructure
- Dependencies must be declared separately from usage
- Harder to handle complex initialization

#### Option C: Auto-Discovery with Glob

Container discovers modules via file system:

```typescript
// src/container/bootstrap.ts
const modules = await glob("src/**/register.ts")
for (const mod of modules) {
  const { register } = await import(mod)
  register(container)
}
```

**Pros:**
- Zero manual wiring
- Adding a module is automatic

**Cons:**
- Magic behavior
- Harder to control order
- Doesn't work with bundlers
- Harder to test

### 4.2 Recommendation: Option A (Export `register` Function)

The `register(container)` pattern is explicit, testable, and doesn't require magic. Each module is responsible for:

1. Registering its services (managers, utilities)
2. Registering its hooks with the HookRegistry

The bootstrap code in `src/index.ts` calls each module's register function in dependency order.

---

## 5. Concrete Hook Mapping

### 5.1 Current Hooks and Their Owners

| Hook Name | Current Location | Recommended Owner | Dependencies |
|-----------|------------------|-------------------|--------------|
| `experimental.chat.system.transform` | index.ts | `projects/` | ProjectManager, WorktreeManager |
| `experimental.session.compacting` | index.ts | `sessions/` | ProjectManager, DelegationManager, TeamManager, Client, Config, Logger |
| `shell.env` | index.ts | `projects/` | ProjectManager |
| `event` | index.ts | `execution/` | DelegationManager, ProjectManager, Client, Logger |
| `config` | index.ts | `config/` | Config, Logger |

### 5.2 Rationale for Ownership

**`projects/` owns system transform and shell.env:**
- Both hooks inject project context
- ProjectManager is the primary dependency
- These hooks are about "what project are we working on"

**`sessions/` owns session compacting:**
- Session capture is the core responsibility
- SessionManager lives in this module
- summarizeSession utility is here

**`execution/` owns event hook:**
- Tracks delegation lifecycle
- DelegationManager is the primary dependency
- Handles session.idle for delegations

**`config/` owns config hook:**
- Registers agents, commands, skills
- ConfigManager provides paths and settings
- Natural home for plugin configuration

### 5.3 Example Implementation

#### sessions/hooks/session-compacting.ts

```typescript
import type { Container } from "../../container/index.js"
import type { HookHandler } from "../../hooks/index.js"
import type { CompactingInput, CompactingOutput } from "../../hooks/types.js"
import { Tokens } from "../../container/tokens.js"
import { summarizeSession } from "../session-summarizer.js"
import { extractConversationContent } from "../../utils/conversation/index.js"
import {
  buildCompactionContext,
  buildDelegationCompactionContext,
  buildTeamCompactionContext,
} from "../../projects/index.js"

export function createSessionCompactingHook(
  container: Container
): HookHandler<CompactingInput, CompactingOutput> {
  const projectManager = container.resolve(Tokens.ProjectManager)
  const delegationManager = container.resolve(Tokens.DelegationManager)
  const teamManager = container.resolve(Tokens.TeamManager)
  const client = container.resolve(Tokens.Client)
  const config = container.resolve(Tokens.Config)
  const log = container.resolve(Tokens.Logger)

  return async (input, output) => {
    const projectId = projectManager.getFocusedProjectId()
    if (!projectId) return

    const contextBlock = await buildCompactionContext(projectManager)
    if (contextBlock) {
      output.context.push(contextBlock)
    }

    const sessionId = input.sessionID

    // Add delegation context
    const allRunning = await delegationManager.list({ status: "running" })
    const allCompleted = await delegationManager.getRecentCompletedDelegations(10)

    const runningDelegations = sessionId
      ? allRunning.filter((d) => d.parentSessionId === sessionId)
      : allRunning
    const completedDelegations = sessionId
      ? allCompleted.filter((d) => d.parentSessionId === sessionId)
      : allCompleted

    if (runningDelegations.length > 0 || completedDelegations.length > 0) {
      const delegationContext = buildDelegationCompactionContext(
        runningDelegations,
        completedDelegations
      )
      output.context.push(delegationContext)
    }

    // Add team context
    const runningTeams = await teamManager.getRunningTeams()
    const sessionTeams = sessionId
      ? runningTeams.filter((t) => t.parentSessionId === sessionId)
      : runningTeams

    if (sessionTeams.length > 0) {
      const teamContext = buildTeamCompactionContext(sessionTeams)
      output.context.push(teamContext)
    }

    // Capture session summary
    if (sessionId) {
      try {
        const sessionManager = await projectManager.getSessionManager(projectId)
        if (sessionManager) {
          const conversationContent = extractConversationContent(input)

          if (conversationContent) {
            const metadata = await projectManager.getProjectMetadata(projectId)
            const planningManager = await projectManager.getPlanningManager(projectId)
            const planningState = await planningManager?.getState()
            const planningPhase = planningState?.phase

            const summaryResult = await summarizeSession(client, log, {
              conversationContent,
              projectName: metadata?.name,
              planningPhase,
              timeoutMs: config.getSmallModelTimeoutMs(),
            })

            if (summaryResult.ok) {
              const captureResult = await sessionManager.captureSession({
                sessionId,
                summary: summaryResult.value.summary,
                keyPoints: summaryResult.value.keyPoints,
                openQuestionsAdded: summaryResult.value.openQuestionsAdded,
                decisionsMade: summaryResult.value.decisionsMade,
              })

              if (captureResult.ok) {
                if (summaryResult.value.whatsNext.length > 0) {
                  await sessionManager.updateIndex({
                    whatsNext: summaryResult.value.whatsNext,
                  })
                }
                await log.debug(`Session ${sessionId} captured for project ${projectId}`)
              }
            }
          }
        }
      } catch (error) {
        await log.warn(`Failed to capture session: ${error}`)
      }
    }
  }
}
```

#### sessions/register.ts

```typescript
import type { Container } from "../container/index.js"
import { Tokens } from "../container/tokens.js"
import { SessionManager } from "./session-manager.js"
import { createSessionCompactingHook } from "./hooks/session-compacting.js"

export function register(container: Container): void {
  // Register services (if any module-specific services)
  // SessionManager is created per-project, so no global registration needed
  
  // Register hooks
  const hookRegistry = container.resolve(Tokens.HookRegistry)
  hookRegistry.register(
    "experimental.session.compacting",
    createSessionCompactingHook(container),
    { priority: 100 }
  )
}
```

---

## 6. src/index.ts Role

### 6.1 Current Responsibilities

The current `src/index.ts` (~478 lines) does:
1. Creates all managers (ProjectManager, DelegationManager, etc.)
2. Wires dependencies manually
3. Defines all hook implementations inline
4. Returns the plugin object with tools and hooks

### 6.2 Proposed Responsibilities

Under the new design, `src/index.ts` becomes thin (~50-80 lines):

```typescript
import type { Plugin } from "@opencode-ai/plugin"
import { createContainer } from "./container/index.js"
import { Tokens } from "./container/tokens.js"
import { createTools } from "./tools/index.js"

// Module registrations
import { register as registerConfig } from "./config/register.js"
import { register as registerProjects } from "./projects/register.js"
import { register as registerExecution } from "./execution/register.js"
import { register as registerSessions } from "./sessions/register.js"
import { register as registerVcs } from "./vcs/register.js"

export const ProjectsPlugin: Plugin = async (ctx) => {
  const { client, directory, worktree, $ } = ctx
  
  // Create container and register infrastructure
  const container = createContainer()
  container.register(Tokens.Client, validateClientOrThrow(client))
  container.register(Tokens.Shell, $)
  container.register(Tokens.RepoRoot, worktree || directory)
  
  // Register modules in dependency order
  await registerConfig(container)
  await registerVcs(container)
  await registerProjects(container)
  await registerExecution(container)
  await registerSessions(container)
  
  // Get hook registry and build plugin hooks
  const hookRegistry = container.resolve(Tokens.HookRegistry)
  const hooks = hookRegistry.buildPluginHooks()
  
  // Create tools
  const tools = createTools(container)
  
  const log = container.resolve(Tokens.Logger)
  await log.info("opencode-projects plugin initialized")
  
  return {
    tool: tools,
    ...hooks,
  }
}

export default ProjectsPlugin
```

### 6.3 Benefits

1. **Thin entry point** - Easy to understand at a glance
2. **Module isolation** - Each module manages its own registration
3. **Testable** - Can test modules in isolation with mock containers
4. **Extensible** - Adding a new module is one import + one register call
5. **Clear dependencies** - Registration order documents dependency graph

---

## 7. Complete Architecture

### 7.1 Directory Structure

```
src/
├── container/
│   ├── container.ts       # Container implementation
│   ├── tokens.ts          # Service tokens
│   └── index.ts           # Exports
├── hooks/
│   ├── hook-registry.ts   # HookRegistry implementation
│   ├── types.ts           # HookSignatures, HookHandler types
│   └── index.ts           # Exports
├── config/
│   ├── config-manager.ts  # Existing
│   ├── hooks/
│   │   └── config-hook.ts # Config hook implementation
│   ├── register.ts        # Module registration
│   └── index.ts
├── projects/
│   ├── project-manager.ts # Existing
│   ├── hooks/
│   │   ├── system-transform.ts
│   │   └── shell-env.ts
│   ├── register.ts
│   └── index.ts
├── execution/
│   ├── delegation-manager.ts # Existing
│   ├── team-manager.ts       # Existing
│   ├── hooks/
│   │   └── event-hook.ts
│   ├── register.ts
│   └── index.ts
├── sessions/
│   ├── session-manager.ts    # Existing
│   ├── hooks/
│   │   └── session-compacting.ts
│   ├── register.ts
│   └── index.ts
├── vcs/
│   ├── worktree-manager.ts   # Existing
│   ├── register.ts
│   └── index.ts
├── tools/
│   ├── *.ts                  # Existing tools
│   ├── create-tools.ts       # Tool factory
│   └── index.ts
└── index.ts                  # Thin plugin entry point
```

### 7.2 Registration Order

Modules must be registered in dependency order:

1. **config** - No dependencies on other modules
2. **vcs** - Depends on config, shell
3. **projects** - Depends on config, vcs
4. **execution** - Depends on config, vcs, projects
5. **sessions** - Depends on config, projects, execution

### 7.3 Hook Composition Flow

```
Plugin Init
    │
    ▼
Container Created
    │
    ▼
Modules Register (in order)
    │
    ├── config/register.ts
    │   └── registers config hook
    │
    ├── projects/register.ts
    │   ├── registers ProjectManager
    │   ├── registers system-transform hook
    │   └── registers shell-env hook
    │
    ├── execution/register.ts
    │   ├── registers DelegationManager
    │   ├── registers TeamManager
    │   └── registers event hook
    │
    └── sessions/register.ts
        └── registers session-compacting hook
    │
    ▼
HookRegistry.buildPluginHooks()
    │
    ▼
Returns composed hooks to OpenCode
```

---

## 8. Implementation Considerations

### 8.1 Async Initialization

Some managers need async setup (e.g., `worktreeManager.detectVCS()`). The register functions are async to support this:

```typescript
// vcs/register.ts
export async function register(container: Container): Promise<void> {
  const repoRoot = container.resolve(Tokens.RepoRoot)
  const shell = container.resolve(Tokens.Shell)
  const log = container.resolve(Tokens.Logger)
  
  const worktreeManager = new WorktreeManager(repoRoot, shell, log)
  await worktreeManager.detectVCS()
  
  container.register(Tokens.WorktreeManager, worktreeManager)
}
```

### 8.2 Stateful Hooks

The `event` hook tracks `orchestratorSessionId`. Encapsulate this in a class:

```typescript
// execution/hooks/event-hook.ts
export class EventHookHandler {
  private orchestratorSessionId: string | null = null
  
  constructor(
    private delegationManager: DelegationManager,
    private projectManager: ProjectManager,
    private client: OpencodeClient,
    private log: Logger,
  ) {}
  
  async handle(input: EventInput): Promise<void> {
    const { event } = input
    
    if (event.type === "session.created") {
      const session = event.properties.info
      if (!session.parentID && !this.orchestratorSessionId) {
        this.orchestratorSessionId = session.id
        await this.log.debug(`Orchestrator session identified: ${this.orchestratorSessionId}`)
      }
    }
    
    if (event.type === "session.idle") {
      // ... handle idle
    }
  }
  
  // For testing
  getOrchestratorSessionId(): string | null {
    return this.orchestratorSessionId
  }
  
  resetState(): void {
    this.orchestratorSessionId = null
  }
}
```

### 8.3 Testing Hooks

Each hook can be tested in isolation:

```typescript
describe("SessionCompactingHook", () => {
  let container: Container
  let mockProjectManager: MockProjectManager
  let mockDelegationManager: MockDelegationManager
  
  beforeEach(() => {
    container = createContainer()
    mockProjectManager = createMockProjectManager()
    mockDelegationManager = createMockDelegationManager()
    
    container.register(Tokens.ProjectManager, mockProjectManager)
    container.register(Tokens.DelegationManager, mockDelegationManager)
    container.register(Tokens.TeamManager, createMockTeamManager())
    container.register(Tokens.Client, createMockClient())
    container.register(Tokens.Config, createMockConfig())
    container.register(Tokens.Logger, createMockLogger())
  })
  
  it("should add project context to output", async () => {
    mockProjectManager.getFocusedProjectId.mockReturnValue("proj-123")
    
    const hook = createSessionCompactingHook(container)
    const output = { context: [] }
    
    await hook({ sessionID: "session-1" }, output)
    
    expect(output.context.length).toBeGreaterThan(0)
  })
})
```

### 8.4 Testing Multiple Handlers Together

Integration test for hook composition:

```typescript
describe("System Transform Hook Composition", () => {
  let container: Container
  let hookRegistry: HookRegistry
  
  beforeEach(() => {
    container = createContainer()
    hookRegistry = new HookRegistry()
    container.register(Tokens.HookRegistry, hookRegistry)
    
    // Register mocks
    container.register(Tokens.ProjectManager, createMockProjectManager())
    container.register(Tokens.WorktreeManager, createMockWorktreeManager())
    container.register(Tokens.Logger, createMockLogger())
  })
  
  it("should compose multiple handlers in priority order", async () => {
    const callOrder: string[] = []
    
    // Register handlers with different priorities
    hookRegistry.register(
      "experimental.chat.system.transform",
      async (_input, output) => {
        callOrder.push("vcs")
        output.system.push("VCS context")
      },
      { priority: 60 }
    )
    
    hookRegistry.register(
      "experimental.chat.system.transform",
      async (_input, output) => {
        callOrder.push("project")
        output.system.push("Project context")
      },
      { priority: 50 }  // Lower priority runs first
    )
    
    const output = { system: [] }
    await hookRegistry.executeHook(
      "experimental.chat.system.transform",
      {},
      output
    )
    
    expect(callOrder).toEqual(["project", "vcs"])
    expect(output.system).toEqual(["Project context", "VCS context"])
  })
  
  it("should continue execution if a handler throws", async () => {
    hookRegistry.register(
      "experimental.chat.system.transform",
      async () => { throw new Error("Handler failed") },
      { priority: 50 }
    )
    
    hookRegistry.register(
      "experimental.chat.system.transform",
      async (_input, output) => { output.system.push("Second handler") },
      { priority: 60 }
    )
    
    const output = { system: [] }
    await hookRegistry.executeHook(
      "experimental.chat.system.transform",
      {},
      output
    )
    
    // Second handler still ran despite first throwing
    expect(output.system).toEqual(["Second handler"])
  })
})
```

### 8.5 Multiple Handlers Per Hook

The HookRegistry supports multiple handlers:

```typescript
// projects/register.ts
hookRegistry.register(
  "experimental.chat.system.transform",
  createProjectContextHook(container),
  { priority: 50 }  // Run early
)

hookRegistry.register(
  "experimental.chat.system.transform",
  createVcsContextHook(container),
  { priority: 60 }  // Run after project context
)

hookRegistry.register(
  "experimental.chat.system.transform",
  createPlanningContextHook(container),
  { priority: 70 }  // Run after VCS context
)
```

---

## 9. Migration Path

### Phase 1: Create Infrastructure (Non-Breaking)

1. Create `src/container/` with Container and Tokens
2. Create `src/hooks/` with HookRegistry and types
3. Add tests for container and hook registry

### Phase 2: Migrate One Hook (Proof of Concept)

1. Move `shell.env` hook to `projects/hooks/shell-env.ts`
2. Create `projects/register.ts`
3. Update `src/index.ts` to use both old and new patterns
4. Verify functionality

### Phase 3: Migrate Remaining Hooks

1. Move each hook to its owning module
2. Create register.ts for each module
3. Update src/index.ts incrementally

### Phase 4: Cleanup

1. Remove inline hook implementations from src/index.ts
2. Simplify src/index.ts to thin bootstrap
3. Update documentation

---

## 10. Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Registration order bugs | Medium | High | Document order, add validation |
| Circular dependencies | Low | High | Container detects cycles, clear module boundaries |
| Performance overhead | Low | Low | Container is simple Map lookup |
| Testing complexity | Low | Medium | Each module testable in isolation |
| Migration breaks functionality | Medium | High | Incremental migration, extensive testing |

---

## 11. Conclusion

The recommended design uses:

1. **Typed hook names** via `HookSignatures` interface for compile-time safety
2. **Sequential mutation** for hook composition (matches OpenCode semantics)
3. **Hand-rolled container** for simplicity and zero dependencies
4. **Module self-registration** via `register(container)` functions
5. **Hooks close to consumers** in their owning modules

This design:
- Keeps `src/index.ts` thin (~50-80 lines)
- Makes hooks testable in isolation
- Supports multiple handlers per hook name
- Requires no decorators or magic
- Is explicit and debuggable

The migration can be done incrementally, one hook at a time, with no breaking changes until the final cleanup phase.
