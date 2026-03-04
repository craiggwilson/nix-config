# Research Summary: Hooks Abstraction Patterns

**Date:** 2026-03-04  
**Status:** Complete  
**Researcher:** Augment Agent  
**Issue:** opencode-projects-plugin-hooks-0d2eb5-944.1

---

## Overview

This research investigates how to best abstract hook registration in the opencode-projects-plugin. Currently, all hooks are registered inline in `src/index.ts`, which will become unwieldy as more hooks are added.

**Recommendation:** Adopt the **HookRegistry class pattern** with explicit dependency injection.

---

## Key Findings

### 1. Current Hook Inventory

The plugin currently registers **5 hooks** in src/index.ts:

| Hook | Type | Complexity | Dependencies |
|------|------|-----------|--------------|
| `experimental.chat.system.transform` | System prompt | Low | projectManager, worktreeManager |
| `experimental.session.compacting` | Session compaction | High | projectManager, delegationManager, teamManager, typedClient, config, log |
| `shell.env` | Environment | Minimal | projectManager |
| `event` | Event handler | Medium | delegationManager, projectManager, typedClient, log |
| `config` | Configuration | Medium | config, log |

**Key Observation:** The `event` hook maintains mutable state (`orchestratorSessionId`), which is problematic for testing and reusability.

### 2. Reference Implementation Analysis

The oh-my-opencode-slim project uses a **factory pattern** with hooks in separate directories:

```
src/hooks/
├── auto-update-checker/
│   ├── index.ts          # createAutoUpdateCheckerHook()
│   ├── checker.ts        # Implementation details
│   └── ...
├── delegate-task-retry/
├── json-error-recovery/
└── index.ts              # Re-exports all createXxxHook()
```

**Strengths:**
- ✅ Modular - each hook is self-contained
- ✅ Easy to add new hooks
- ✅ Clear module boundaries

**Weaknesses:**
- ❌ Dependencies hidden in factory signature
- ❌ Difficult to test (requires full PluginInput mock)
- ❌ Weak type safety for hook registration

### 3. Design Options Evaluated

Four alternatives were analyzed:

| Option | Score | Recommendation |
|--------|-------|-----------------|
| **A: HookRegistry Class** | 8.7/10 | ⭐ **RECOMMENDED** |
| B: Modular Factories | 8.6/10 | Alternative |
| C: Decorator Pattern | 7.4/10 | Not recommended |
| D: Composition Module | 8.6/10 | Alternative |

### 4. Why HookRegistry?

**HookRegistry** is the best choice because it:

1. **Provides explicit dependency injection**
   - All dependencies visible in constructor
   - Clear what each hook needs
   - Follows existing ProjectManager pattern

2. **Improves testability**
   - Easy to inject mock managers
   - Each hook method testable independently
   - No need to mock entire PluginInput

3. **Handles stateful hooks cleanly**
   - Encapsulates state as instance variables
   - No global variables or closures
   - Testable and reusable

4. **Aligns with existing patterns**
   - Consistent with ProjectManager, DelegationManager
   - Uses constructor injection like other core components
   - Follows established codebase conventions

5. **Scales well**
   - Easy to add new hooks
   - No need to modify src/index.ts beyond initial setup
   - Can organize related hooks into sub-registries

---

## Recommended Design

### HookRegistry Class

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

  getHooks() {
    return {
      ...this.getSystemTransformHook(),
      ...this.getSessionCompactingHook(),
      ...this.getShellEnvHook(),
      ...this.getEventHook(),
      ...this.getConfigHook(),
    }
  }

  private getSystemTransformHook() { /* ... */ }
  private getSessionCompactingHook() { /* ... */ }
  private getShellEnvHook() { /* ... */ }
  private getEventHook() { /* ... */ }
  private getConfigHook() { /* ... */ }
}
```

### Usage in src/index.ts

```typescript
const hookRegistry = new HookRegistry(
  projectManager,
  delegationManager,
  teamManager,
  worktreeManager,
  typedClient,
  config,
  log,
)

return {
  tool: { /* ... */ },
  ...hookRegistry.getHooks(),
}
```

---

## Implementation Roadmap

### Phase 1: Create HookRegistry (1-2 hours)
- Create `src/hooks/hook-registry.ts`
- Implement HookRegistry class with all hook methods
- Add comprehensive unit tests

### Phase 2: Update Plugin Entry Point (30 minutes)
- Update `src/index.ts` to use HookRegistry
- Verify all hooks work correctly
- Run integration tests

### Phase 3: Cleanup (30 minutes)
- Remove inline hook implementations from src/index.ts
- Update documentation
- Commit changes

**Total Effort:** ~2-3 hours

---

## Key Design Decisions

1. **Single Registry Class**
   - All hooks managed by one class
   - Clear lifecycle and initialization
   - Easy to understand at a glance

2. **Method Per Hook**
   - Each hook is a method that returns the hook object
   - Methods are private (not needed externally)
   - Clear naming: `getXxxHook()`

3. **Inline Implementations**
   - Keep hook implementations in HookRegistry (not separate files)
   - Simpler to understand and maintain
   - Can extract to separate files later if needed

4. **Encapsulated State**
   - Stateful hooks store state as instance variables
   - No global variables or closures
   - Testable and reusable

---

## Testing Strategy

### Unit Tests
- Test each hook method independently
- Mock all dependencies
- Verify hook behavior and side effects

### Integration Tests
- Verify all hooks work together
- Test with real managers (or realistic mocks)
- Verify no regressions

### Coverage Goals
- 100% coverage of hook methods
- All error paths tested
- All state transitions tested

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
    ...this.getNewHook(),  // Add here
    // ...
  }
}

// 3. Add tests
```

### Organizing Related Hooks

If hooks grow significantly:

```typescript
export class HookRegistry {
  private systemHooks = new SystemHookRegistry(...)
  private executionHooks = new ExecutionHookRegistry(...)

  getHooks() {
    return {
      ...this.systemHooks.getHooks(),
      ...this.executionHooks.getHooks(),
    }
  }
}
```

---

## Risks and Mitigations

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| Hooks don't work after refactoring | Low | High | Comprehensive unit tests, integration tests |
| Performance regression | Very Low | Medium | Profile before/after, benchmark tests |
| Difficulty understanding new pattern | Low | Low | Clear documentation, code comments |
| Circular dependencies | Very Low | High | Careful dependency analysis, linting |

---

## Success Criteria

- ✅ All hooks work correctly after refactoring
- ✅ Unit tests pass (100% coverage)
- ✅ Integration tests pass
- ✅ No performance regression
- ✅ Code is easier to understand and maintain
- ✅ Adding a new hook is straightforward

---

## Deliverables

This research includes:

1. **hooks-abstraction-research.md** - Comprehensive research document
   - Current hook inventory and dependencies
   - Reference implementation analysis
   - Four design alternatives with tradeoffs
   - Detailed comparison and scoring

2. **design-recommendation.md** - Design recommendation
   - Summary of findings
   - Why HookRegistry is recommended
   - Key design decisions
   - Future extensibility

3. **implementation-guide.md** - Step-by-step implementation guide
   - Complete code examples
   - Unit test templates
   - Testing checklist
   - Rollback plan

4. **hook-abstraction-decision.md** - Decision record
   - Context and problem statement
   - Decision and rationale
   - Alternatives considered
   - Risks and mitigations

---

## Conclusion

The **HookRegistry class pattern** is the recommended approach for abstracting hook registration in opencode-projects-plugin. This pattern:

- ✅ Provides explicit dependency injection
- ✅ Improves testability
- ✅ Aligns with existing codebase patterns
- ✅ Handles stateful hooks cleanly
- ✅ Scales well for future hooks
- ✅ Maintains type safety

The implementation is straightforward and can be completed in 2-3 hours with minimal risk. All necessary documentation and code examples are provided in the accompanying research documents.

---

## Next Steps

1. **Review** this research and the design recommendation
2. **Implement** HookRegistry following the implementation guide
3. **Test** thoroughly with unit and integration tests
4. **Verify** all hooks work correctly
5. **Commit** changes with clear commit message
6. **Document** the pattern for future hook additions

---

## References

- **Current Code:** `hdwlinux/packages/opencode-projects-plugin/src/index.ts`
- **Reference Implementation:** https://github.com/alvinunreal/oh-my-opencode-slim/tree/master/src/hooks
- **Codebase Patterns:** ProjectManager, DelegationManager, TeamManager
- **Testing Framework:** Bun test

---

**Research completed:** 2026-03-04  
**Status:** Ready for implementation  
**Confidence:** High (8.7/10)
