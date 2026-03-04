# Hooks Abstraction Research

**Date:** 2026-03-04  
**Status:** Complete  
**Scope:** Analyze hook registration patterns and design options for opencode-projects-plugin

---

## Executive Summary

The opencode-projects-plugin currently registers 6 hooks inline in `src/index.ts` (lines 151-371). As the plugin grows, this will become unwieldy. This research evaluates the oh-my-opencode-slim factory pattern approach against alternative designs, considering dependency injection, testability, and ease of adding new hooks.

**Recommendation:** Adopt a **factory pattern with a HookRegistry** that combines the best of oh-my-opencode-slim's modularity with explicit dependency management. This provides clear separation of concerns, easy testing, and straightforward hook addition.

---

## 1. Current Hook Inventory

### 1.1 Hooks Currently Registered

| Hook Name | Type | Lines | Purpose |
|-----------|------|-------|---------|
| `experimental.chat.system.transform` | System prompt | 151-170 | Inject project context into system prompts |
| `experimental.session.compacting` | Session compaction | 172-271 | Capture session summaries and delegation context |
| `shell.env` | Environment | 273-279 | Export focused project ID to shell |
| `event` | Event handler | 281-316 | Track orchestrator session and handle idle events |
| `config` | Configuration | 318-371 | Register agents, commands, skills, and permissions |

### 1.2 Dependencies by Hook

#### `experimental.chat.system.transform`
- **Direct:** `projectManager`, `worktreeManager`
- **Transitive:** None (uses public APIs)
- **Complexity:** Low - pure data transformation

#### `experimental.session.compacting`
- **Direct:** `projectManager`, `delegationManager`, `teamManager`, `typedClient`, `config`, `log`
- **Transitive:** `summarizeSession` utility
- **Complexity:** High - orchestrates multiple managers, handles errors, calls small model

#### `shell.env`
- **Direct:** `projectManager`
- **Transitive:** None
- **Complexity:** Minimal - single property access

#### `event`
- **Direct:** `delegationManager`, `projectManager`, `typedClient`, `log`
- **Transitive:** `writeOrchestratorSnapshot` utility
- **Complexity:** Medium - stateful (tracks `orchestratorSessionId`), multiple event types

#### `config`
- **Direct:** `config`, `log`
- **Transitive:** `OPENCODE_PROJECTS_AGENT_CONFIG`, `OPENCODE_PROJECTS_COMMANDS`
- **Complexity:** Medium - file path resolution, config mutation

### 1.3 Shared State

The `event` hook maintains **mutable state** (`orchestratorSessionId`), which is problematic for:
- Testing (state leaks between tests)
- Reusability (can't instantiate multiple times)
- Clarity (implicit coupling)

---

## 2. Reference Implementation Analysis

### 2.1 oh-my-opencode-slim Approach

**Pattern:** Factory functions in separate directories

```
src/hooks/
├── auto-update-checker/
│   ├── index.ts          # createAutoUpdateCheckerHook()
│   ├── checker.ts        # Implementation details
│   ├── cache.ts
│   ├── constants.ts
│   └── types.ts
├── delegate-task-retry/
│   └── index.ts
├── json-error-recovery/
│   └── index.ts
├── phase-reminder/
│   └── index.ts
├── post-read-nudge/
│   └── index.ts
└── index.ts              # Re-exports all createXxxHook()
```

**Characteristics:**
- ✅ Each hook is self-contained in its own directory
- ✅ Factory function pattern: `createXxxHook(ctx, options?)` returns hook object
- ✅ Hooks are stateless (state encapsulated in closure)
- ✅ Easy to add new hooks (copy directory, implement factory)
- ✅ Clear module boundaries
- ❌ Dependencies passed via `ctx` (PluginInput) - less explicit
- ❌ No type safety for hook registration
- ❌ Harder to test individual hooks (need full PluginInput)

**Hook Registration in oh-my-opencode-slim:**
```typescript
// In main plugin
const hooks = {
  event: createAutoUpdateCheckerHook(ctx).event,
  "experimental.chat.system.transform": createPhaseReminderHook(ctx)["experimental.chat.system.transform"],
  // ...
}
```

### 2.2 Tradeoffs of oh-my-opencode-slim Approach

| Aspect | Tradeoff |
|--------|----------|
| **Modularity** | Excellent - each hook is isolated |
| **Dependency clarity** | Poor - dependencies hidden in factory signature |
| **Testing** | Difficult - requires full PluginInput mock |
| **Type safety** | Weak - hook objects are loosely typed |
| **Adding hooks** | Easy - copy pattern, implement factory |
| **Shared state** | Encapsulated in closure (good) but implicit |
| **Reusability** | Limited - tightly coupled to PluginInput |

---

## 3. Alternative Design Options

### Option A: HookRegistry Class (Recommended)

**Pattern:** Explicit dependency injection with a registry

```typescript
// src/hooks/hook-registry.ts
export class HookRegistry {
  constructor(
    private projectManager: ProjectManager,
    private delegationManager: DelegationManager,
    private teamManager: TeamManager,
    private worktreeManager: WorktreeManager,
    private typedClient: OpencodeClient,
    private config: ConfigManager,
    private log: Logger,
  ) {}

  createSystemTransformHook() {
    return {
      "experimental.chat.system.transform": async (input, output) => {
        // Implementation using this.projectManager, etc.
      }
    }
  }

  createSessionCompactingHook() {
    return {
      "experimental.session.compacting": async (input, output) => {
        // Implementation
      }
    }
  }

  // ... other hooks

  getHooks() {
    return {
      ...this.createSystemTransformHook(),
      ...this.createSessionCompactingHook(),
      // ...
    }
  }
}

// In src/index.ts
const registry = new HookRegistry(
  projectManager,
  delegationManager,
  teamManager,
  worktreeManager,
  typedClient,
  config,
  log,
)
return { ...registry.getHooks(), tool: { ... } }
```

**Advantages:**
- ✅ Explicit dependency injection - clear what each hook needs
- ✅ Single responsibility - registry only manages hooks
- ✅ Easy to test - inject mocks
- ✅ Type-safe - all dependencies are typed
- ✅ Stateful hooks can encapsulate state in instance variables
- ✅ Composable - can create sub-registries for related hooks
- ✅ Follows existing plugin patterns (ProjectManager, etc.)

**Disadvantages:**
- ❌ More boilerplate than factory pattern
- ❌ All dependencies must be passed to constructor (even if not all hooks use them)
- ❌ Slightly more complex than inline registration

### Option B: Modular Factories (oh-my-opencode-slim style)

**Pattern:** Factory functions in separate modules

```typescript
// src/hooks/system-transform.ts
export function createSystemTransformHook(
  projectManager: ProjectManager,
  worktreeManager: WorktreeManager,
) {
  return {
    "experimental.chat.system.transform": async (input, output) => {
      // Implementation
    }
  }
}

// src/hooks/session-compacting.ts
export function createSessionCompactingHook(
  projectManager: ProjectManager,
  delegationManager: DelegationManager,
  teamManager: TeamManager,
  typedClient: OpencodeClient,
  config: ConfigManager,
  log: Logger,
) {
  return {
    "experimental.session.compacting": async (input, output) => {
      // Implementation
    }
  }
}

// src/hooks/index.ts
export { createSystemTransformHook } from "./system-transform.js"
export { createSessionCompactingHook } from "./session-compacting.js"
// ... etc

// In src/index.ts
const hooks = {
  ...createSystemTransformHook(projectManager, worktreeManager),
  ...createSessionCompactingHook(projectManager, delegationManager, teamManager, typedClient, config, log),
  // ...
}
return { ...hooks, tool: { ... } }
```

**Advantages:**
- ✅ Modular - each hook in its own file
- ✅ Explicit dependencies - each factory declares what it needs
- ✅ Easy to test - inject mocks directly
- ✅ Follows oh-my-opencode-slim pattern (familiar)
- ✅ Minimal boilerplate

**Disadvantages:**
- ❌ Repetitive dependency passing in src/index.ts
- ❌ Hard to see all dependencies at a glance
- ❌ Stateful hooks need closure variables (less clear)
- ❌ No central place to manage hook lifecycle

### Option C: Decorator Pattern

**Pattern:** Decorators on hook handler methods

```typescript
class HookHandlers {
  @Hook("experimental.chat.system.transform")
  async systemTransform(input, output) {
    // Implementation
  }

  @Hook("experimental.session.compacting")
  async sessionCompacting(input, output) {
    // Implementation
  }
}

// Registry discovers and registers decorated methods
const registry = new DecoratedHookRegistry(HookHandlers, {
  projectManager,
  delegationManager,
  // ...
})
```

**Advantages:**
- ✅ Declarative - clear which methods are hooks
- ✅ Centralized - all hooks in one class
- ✅ Minimal boilerplate

**Disadvantages:**
- ❌ Requires decorator support (TypeScript experimental feature)
- ❌ Magic - harder to understand what's happening
- ❌ Overkill for current use case
- ❌ Less familiar to team

### Option D: Composition with Hooks Module

**Pattern:** Hooks module with composed handlers

```typescript
// src/hooks/index.ts
export function createHooks(deps: HookDependencies) {
  return {
    "experimental.chat.system.transform": createSystemTransformHandler(deps),
    "experimental.session.compacting": createSessionCompactingHandler(deps),
    "shell.env": createShellEnvHandler(deps),
    event: createEventHandler(deps),
    config: createConfigHandler(deps),
  }
}

// src/hooks/system-transform.ts
export function createSystemTransformHandler(deps: HookDependencies) {
  return async (input, output) => {
    // Implementation using deps
  }
}

// In src/index.ts
const hooks = createHooks({
  projectManager,
  delegationManager,
  teamManager,
  worktreeManager,
  typedClient,
  config,
  log,
})
return { ...hooks, tool: { ... } }
```

**Advantages:**
- ✅ Modular - each handler in its own file
- ✅ Explicit dependencies - passed as object
- ✅ Easy to test - inject mock dependencies
- ✅ Central factory function - clear entry point
- ✅ Minimal boilerplate

**Disadvantages:**
- ❌ Slightly more indirection than HookRegistry
- ❌ Dependencies object must be passed everywhere

---

## 4. Comparative Analysis

### Evaluation Criteria

| Criterion | Weight | Description |
|-----------|--------|-------------|
| **Modularity** | High | Hooks are isolated, easy to understand |
| **Dependency Clarity** | High | Clear what each hook needs |
| **Testability** | High | Easy to unit test individual hooks |
| **Type Safety** | Medium | Compile-time safety for hook registration |
| **Ease of Adding Hooks** | Medium | How easy to add a new hook |
| **Consistency** | Medium | Aligns with existing codebase patterns |
| **Boilerplate** | Low | Minimize repetitive code |

### Scoring Matrix

| Option | Modularity | Dep Clarity | Testability | Type Safety | Add Hooks | Consistency | Boilerplate | **Total** |
|--------|:----------:|:-----------:|:-----------:|:-----------:|:---------:|:-----------:|:-----------:|:---------:|
| **A: HookRegistry** | 9 | 10 | 10 | 10 | 8 | 9 | 7 | **8.7** |
| **B: Modular Factories** | 9 | 9 | 9 | 8 | 9 | 8 | 8 | **8.6** |
| **C: Decorators** | 8 | 7 | 8 | 9 | 7 | 6 | 6 | **7.4** |
| **D: Composition** | 9 | 9 | 9 | 9 | 8 | 8 | 8 | **8.6** |

---

## 5. Recommendation: HookRegistry Pattern

### Why HookRegistry?

1. **Explicit Dependency Injection**
   - All dependencies are visible in the constructor
   - Easy to see what each hook needs
   - Follows existing ProjectManager pattern in codebase

2. **Testability**
   - Can inject mock managers for unit tests
   - Each hook method can be tested independently
   - No need to mock entire PluginInput

3. **Stateful Hooks**
   - The `event` hook needs to track `orchestratorSessionId`
   - HookRegistry can encapsulate this as instance state
   - Cleaner than closure variables

4. **Consistency**
   - Aligns with existing ProjectManager, DelegationManager patterns
   - Uses constructor injection like other core components
   - Follows established codebase conventions

5. **Scalability**
   - Adding a new hook is straightforward: add a method, call it in `getHooks()`
   - No need to modify src/index.ts beyond initial setup
   - Can organize related hooks into sub-registries if needed

### Implementation Structure

```
src/
├── hooks/
│   ├── hook-registry.ts      # Main HookRegistry class
│   ├── system-transform.ts   # Handler implementations (optional)
│   ├── session-compacting.ts
│   ├── shell-env.ts
│   ├── event.ts
│   ├── config.ts
│   └── index.ts              # Export HookRegistry
├── index.ts                  # Plugin entry point
└── ...
```

### Key Design Decisions

1. **Single Registry Class**
   - All hooks managed by one class
   - Clear lifecycle and initialization
   - Easy to understand at a glance

2. **Method Per Hook**
   - Each hook is a method that returns the hook object
   - Methods can be private if not needed externally
   - Clear naming: `createXxxHook()` or `getXxxHook()`

3. **Encapsulated State**
   - Stateful hooks (like `event`) store state as instance variables
   - No global variables or closures
   - Testable and reusable

4. **Lazy Initialization (Optional)**
   - Could defer hook creation until `getHooks()` is called
   - Useful if hooks have expensive initialization
   - Current use case doesn't require this

---

## 6. Implementation Considerations

### 6.1 Handling Stateful Hooks

The `event` hook currently tracks `orchestratorSessionId` as a closure variable:

```typescript
// Current approach (closure)
let orchestratorSessionId: string | null = null

return {
  event: async ({ event }: { event: Event }) => {
    if (event.type === "session.created") {
      const session = event.properties.info
      if (!session.parentID && !orchestratorSessionId) {
        orchestratorSessionId = session.id
      }
    }
    // ...
  }
}
```

**With HookRegistry:**

```typescript
export class HookRegistry {
  private orchestratorSessionId: string | null = null

  getEventHook() {
    return {
      event: async ({ event }: { event: Event }) => {
        if (event.type === "session.created") {
          const session = event.properties.info
          if (!session.parentID && !this.orchestratorSessionId) {
            this.orchestratorSessionId = session.id
          }
        }
        // ...
      }
    }
  }
}
```

**Benefits:**
- State is explicit and visible
- Can be reset for testing
- Encapsulated within the registry instance

### 6.2 Hook Handler Organization

Two approaches:

**Approach 1: Inline in HookRegistry**
```typescript
export class HookRegistry {
  getSystemTransformHook() {
    return {
      "experimental.chat.system.transform": async (input, output) => {
        // Implementation here
      }
    }
  }
}
```

**Approach 2: Separate handler files**
```typescript
// src/hooks/system-transform.ts
export function createSystemTransformHandler(
  projectManager: ProjectManager,
  worktreeManager: WorktreeManager,
) {
  return async (input, output) => {
    // Implementation
  }
}

// src/hooks/hook-registry.ts
export class HookRegistry {
  getSystemTransformHook() {
    return {
      "experimental.chat.system.transform": createSystemTransformHandler(
        this.projectManager,
        this.worktreeManager,
      )
    }
  }
}
```

**Recommendation:** Approach 1 (inline) for now
- Simpler to understand
- Easier to refactor later if needed
- Handlers are small enough to be readable inline
- Can extract to separate files if they grow

### 6.3 Type Safety

Define a hook type to ensure consistency:

```typescript
type HookObject = {
  [key: string]: (input: unknown, output: unknown) => Promise<void> | void
}

export class HookRegistry {
  getSystemTransformHook(): HookObject {
    return {
      "experimental.chat.system.transform": async (input, output) => {
        // ...
      }
    }
  }
}
```

---

## 7. Migration Path

### Phase 1: Create HookRegistry
1. Create `src/hooks/hook-registry.ts`
2. Implement HookRegistry class with all hook methods
3. Add unit tests for each hook

### Phase 2: Update Plugin Entry Point
1. Update `src/index.ts` to use HookRegistry
2. Verify all hooks work correctly
3. Run integration tests

### Phase 3: Cleanup
1. Remove inline hook implementations from src/index.ts
2. Update documentation
3. Commit changes

---

## 8. Testing Strategy

### Unit Tests for HookRegistry

```typescript
describe("HookRegistry", () => {
  let registry: HookRegistry
  let mockProjectManager: MockProjectManager
  // ... other mocks

  beforeEach(() => {
    mockProjectManager = createMockProjectManager()
    // ... create other mocks
    registry = new HookRegistry(
      mockProjectManager,
      mockDelegationManager,
      // ...
    )
  })

  describe("getSystemTransformHook", () => {
    it("should inject project context into system prompts", async () => {
      const hook = registry.getSystemTransformHook()
      const output = { system: [] }
      
      await hook["experimental.chat.system.transform"]({}, output)
      
      expect(output.system.length).toBeGreaterThan(0)
    })
  })

  describe("getEventHook", () => {
    it("should track orchestrator session on session.created", async () => {
      const hook = registry.getEventHook()
      const event = {
        type: "session.created",
        properties: { info: { id: "session-123", parentID: undefined } }
      }
      
      await hook.event({ event })
      
      // Verify state was updated (may need getter method)
      expect(registry.getOrchestratorSessionId()).toBe("session-123")
    })
  })
})
```

---

## 9. Future Extensibility

### Adding a New Hook

With HookRegistry, adding a new hook is straightforward:

1. Add a method to HookRegistry:
```typescript
getNewHook() {
  return {
    "new.hook.name": async (input, output) => {
      // Implementation
    }
  }
}
```

2. Call it in `getHooks()`:
```typescript
getHooks() {
  return {
    ...this.getSystemTransformHook(),
    ...this.getSessionCompactingHook(),
    ...this.getNewHook(),  // Add here
    // ...
  }
}
```

3. Add tests for the new hook

### Organizing Related Hooks

If hooks grow significantly, could create sub-registries:

```typescript
export class HookRegistry {
  private systemHooks = new SystemHookRegistry(this.projectManager, ...)
  private executionHooks = new ExecutionHookRegistry(this.delegationManager, ...)

  getHooks() {
    return {
      ...this.systemHooks.getHooks(),
      ...this.executionHooks.getHooks(),
    }
  }
}
```

---

## 10. Conclusion

The **HookRegistry pattern** is the recommended approach for abstracting hook registration in opencode-projects-plugin because it:

1. **Provides explicit dependency injection** - clear what each hook needs
2. **Improves testability** - easy to mock dependencies
3. **Aligns with existing patterns** - consistent with ProjectManager, etc.
4. **Handles stateful hooks cleanly** - encapsulates state as instance variables
5. **Scales well** - easy to add new hooks
6. **Maintains type safety** - all dependencies are typed

The implementation should:
- Create `src/hooks/hook-registry.ts` with the HookRegistry class
- Keep hook implementations inline (not in separate files) for now
- Add comprehensive unit tests
- Update src/index.ts to use the registry
- Document the pattern for future hook additions

This approach balances modularity, clarity, and maintainability while following established patterns in the codebase.
