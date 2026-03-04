# Design Recommendation: HookRegistry Pattern

**Date:** 2026-03-04  
**Status:** Final Recommendation  
**Confidence:** High

---

## Summary

After analyzing the current hook registration in opencode-projects-plugin and evaluating four design alternatives, we recommend adopting the **HookRegistry class pattern** for abstracting hook registration.

This pattern provides:
- **Explicit dependency injection** - all dependencies visible in constructor
- **Improved testability** - easy to mock dependencies for unit tests
- **Consistency** - aligns with existing ProjectManager pattern
- **Scalability** - straightforward to add new hooks
- **Stateful hook support** - clean encapsulation of mutable state

---

## Current State

### Hooks in src/index.ts

| Hook | Lines | Dependencies | Complexity |
|------|-------|--------------|-----------|
| `experimental.chat.system.transform` | 151-170 | projectManager, worktreeManager | Low |
| `experimental.session.compacting` | 172-271 | projectManager, delegationManager, teamManager, typedClient, config, log | High |
| `shell.env` | 273-279 | projectManager | Minimal |
| `event` | 281-316 | delegationManager, projectManager, typedClient, log | Medium (stateful) |
| `config` | 318-371 | config, log | Medium |

**Problem:** All hooks are registered inline, making the plugin entry point large and difficult to maintain. Adding new hooks requires modifying src/index.ts directly.

---

## Design Options Evaluated

### 1. HookRegistry Class (Recommended) ⭐
**Score: 8.7/10**

Single class managing all hooks with explicit dependency injection.

```typescript
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

  getSystemTransformHook() { /* ... */ }
  getSessionCompactingHook() { /* ... */ }
  getShellEnvHook() { /* ... */ }
  getEventHook() { /* ... */ }
  getConfigHook() { /* ... */ }

  getHooks() {
    return {
      ...this.getSystemTransformHook(),
      ...this.getSessionCompactingHook(),
      // ...
    }
  }
}
```

**Pros:**
- ✅ Explicit dependencies - clear what each hook needs
- ✅ Testable - inject mocks easily
- ✅ Consistent with ProjectManager pattern
- ✅ Stateful hooks encapsulated as instance variables
- ✅ Single responsibility - registry only manages hooks

**Cons:**
- ❌ More boilerplate than inline registration
- ❌ All dependencies passed to constructor (even if not all hooks use them)

### 2. Modular Factories (oh-my-opencode-slim style)
**Score: 8.6/10**

Factory functions in separate files, each declaring its dependencies.

```typescript
// src/hooks/system-transform.ts
export function createSystemTransformHook(
  projectManager: ProjectManager,
  worktreeManager: WorktreeManager,
) { /* ... */ }

// src/hooks/session-compacting.ts
export function createSessionCompactingHook(
  projectManager: ProjectManager,
  delegationManager: DelegationManager,
  // ...
) { /* ... */ }
```

**Pros:**
- ✅ Modular - each hook in its own file
- ✅ Explicit dependencies per hook
- ✅ Familiar pattern (used in oh-my-opencode-slim)

**Cons:**
- ❌ Repetitive dependency passing in src/index.ts
- ❌ No central place to manage hook lifecycle
- ❌ Harder to see all dependencies at once

### 3. Decorator Pattern
**Score: 7.4/10**

Decorators on hook handler methods.

**Pros:**
- ✅ Declarative
- ✅ Centralized

**Cons:**
- ❌ Requires experimental TypeScript features
- ❌ Magic - harder to understand
- ❌ Overkill for current use case

### 4. Composition with Hooks Module
**Score: 8.6/10**

Central factory function with composed handlers.

```typescript
export function createHooks(deps: HookDependencies) {
  return {
    "experimental.chat.system.transform": createSystemTransformHandler(deps),
    // ...
  }
}
```

**Pros:**
- ✅ Modular
- ✅ Explicit dependencies
- ✅ Central entry point

**Cons:**
- ❌ Slightly more indirection
- ❌ Dependencies object must be passed everywhere

---

## Why HookRegistry?

### 1. Explicit Dependency Injection
All dependencies are visible in the constructor, making it clear what each hook needs:

```typescript
const registry = new HookRegistry(
  projectManager,      // Used by: system-transform, session-compacting, shell-env, event
  delegationManager,   // Used by: session-compacting, event
  teamManager,         // Used by: session-compacting
  worktreeManager,     // Used by: system-transform
  typedClient,         // Used by: session-compacting, event
  config,              // Used by: session-compacting, config
  log,                 // Used by: session-compacting, event, config
)
```

### 2. Testability
Easy to unit test individual hooks by injecting mocks:

```typescript
const mockProjectManager = createMockProjectManager()
const registry = new HookRegistry(
  mockProjectManager,
  createMockDelegationManager(),
  // ...
)

const hook = registry.getSystemTransformHook()
// Test the hook with mocks
```

### 3. Consistency with Codebase
Aligns with existing patterns:
- ProjectManager uses constructor injection
- DelegationManager uses constructor injection
- TeamManager uses constructor injection

HookRegistry follows the same pattern.

### 4. Stateful Hooks
The `event` hook needs to track `orchestratorSessionId`. HookRegistry encapsulates this cleanly:

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

State is explicit, testable, and encapsulated.

### 5. Scalability
Adding a new hook is straightforward:

1. Add a method to HookRegistry
2. Call it in `getHooks()`
3. Add tests

No need to modify src/index.ts beyond initial setup.

---

## Implementation Plan

### Phase 1: Create HookRegistry
1. Create `src/hooks/hook-registry.ts`
2. Implement HookRegistry class with all hook methods
3. Keep implementations inline (not in separate files)
4. Add comprehensive unit tests

### Phase 2: Update Plugin Entry Point
1. Update `src/index.ts` to instantiate and use HookRegistry
2. Verify all hooks work correctly
3. Run integration tests

### Phase 3: Cleanup
1. Remove inline hook implementations from src/index.ts
2. Update documentation
3. Commit changes

---

## Key Design Decisions

### 1. Single Registry Class
- All hooks managed by one class
- Clear lifecycle and initialization
- Easy to understand at a glance

### 2. Method Per Hook
- Each hook is a method that returns the hook object
- Methods can be private if not needed externally
- Clear naming: `getXxxHook()`

### 3. Inline Implementations
- Keep hook implementations in HookRegistry (not separate files)
- Simpler to understand and maintain
- Can extract to separate files later if needed

### 4. Encapsulated State
- Stateful hooks store state as instance variables
- No global variables or closures
- Testable and reusable

---

## Future Extensibility

### Adding a New Hook

```typescript
// 1. Add method to HookRegistry
getNewHook() {
  return {
    "new.hook.name": async (input, output) => {
      // Implementation
    }
  }
}

// 2. Call it in getHooks()
getHooks() {
  return {
    ...this.getSystemTransformHook(),
    ...this.getSessionCompactingHook(),
    ...this.getNewHook(),  // Add here
    // ...
  }
}

// 3. Add tests
describe("HookRegistry", () => {
  describe("getNewHook", () => {
    it("should do expected behavior", async () => {
      // Test implementation
    })
  })
})
```

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

## Conclusion

The **HookRegistry pattern** is the best choice for opencode-projects-plugin because it:

1. **Provides explicit dependency injection** - clear what each hook needs
2. **Improves testability** - easy to mock dependencies
3. **Aligns with existing patterns** - consistent with ProjectManager, etc.
4. **Handles stateful hooks cleanly** - encapsulates state as instance variables
5. **Scales well** - easy to add new hooks
6. **Maintains type safety** - all dependencies are typed

This recommendation is based on:
- Analysis of current hook inventory and dependencies
- Evaluation of four design alternatives
- Comparison with reference implementations (oh-my-opencode-slim)
- Consideration of testability, maintainability, and scalability
- Alignment with existing codebase patterns

**Next Step:** Implement HookRegistry class and update src/index.ts to use it.
