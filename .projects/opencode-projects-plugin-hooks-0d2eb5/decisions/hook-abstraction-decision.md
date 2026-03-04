# Decision Record: Hook Abstraction Pattern

**Date:** 2026-03-04  
**Status:** Decided  
**Decision:** Adopt HookRegistry class pattern for hook registration  
**Confidence:** High (8.7/10 score)

---

## Context

The opencode-projects-plugin currently registers 6 hooks inline in `src/index.ts` (lines 151-371). As the plugin grows and more hooks are added, this approach becomes unwieldy and difficult to maintain.

**Problem Statement:**
- Hooks are scattered throughout src/index.ts
- Adding a new hook requires modifying the main plugin file
- No clear separation of concerns
- Difficult to test individual hooks
- Stateful hooks (event) use closure variables
- Dependencies are implicit and hard to track

---

## Decision

**Adopt the HookRegistry class pattern** for managing all plugin hooks.

### What This Means

1. Create a new `HookRegistry` class in `src/hooks/hook-registry.ts`
2. Move all hook implementations from `src/index.ts` to HookRegistry methods
3. Use explicit constructor injection for all dependencies
4. Encapsulate stateful hooks as instance variables
5. Update `src/index.ts` to instantiate and use HookRegistry

### Key Characteristics

- **Explicit dependency injection** - all dependencies visible in constructor
- **Single responsibility** - registry only manages hooks
- **Testable** - easy to inject mocks for unit tests
- **Consistent** - aligns with ProjectManager pattern
- **Scalable** - straightforward to add new hooks

---

## Alternatives Considered

### 1. Modular Factories (oh-my-opencode-slim style)
**Score: 8.6/10**

Factory functions in separate files, each declaring its dependencies.

**Rejected because:**
- Repetitive dependency passing in src/index.ts
- No central place to manage hook lifecycle
- Harder to see all dependencies at once

### 2. Decorator Pattern
**Score: 7.4/10**

Decorators on hook handler methods.

**Rejected because:**
- Requires experimental TypeScript features
- Magic - harder to understand
- Overkill for current use case

### 3. Composition with Hooks Module
**Score: 8.6/10**

Central factory function with composed handlers.

**Rejected because:**
- Slightly more indirection than HookRegistry
- Dependencies object must be passed everywhere

---

## Rationale

### Why HookRegistry?

1. **Explicit Dependency Injection**
   - All dependencies visible in constructor
   - Clear what each hook needs
   - Follows existing ProjectManager pattern

2. **Improved Testability**
   - Can inject mock managers for unit tests
   - Each hook method can be tested independently
   - No need to mock entire PluginInput

3. **Stateful Hook Support**
   - The `event` hook needs to track `orchestratorSessionId`
   - HookRegistry encapsulates this as instance state
   - Cleaner than closure variables

4. **Consistency**
   - Aligns with existing ProjectManager, DelegationManager patterns
   - Uses constructor injection like other core components
   - Follows established codebase conventions

5. **Scalability**
   - Adding a new hook is straightforward
   - No need to modify src/index.ts beyond initial setup
   - Can organize related hooks into sub-registries if needed

---

## Implementation Plan

### Phase 1: Create HookRegistry
- Create `src/hooks/hook-registry.ts` with HookRegistry class
- Implement all hook methods
- Add comprehensive unit tests

### Phase 2: Update Plugin Entry Point
- Update `src/index.ts` to use HookRegistry
- Verify all hooks work correctly
- Run integration tests

### Phase 3: Cleanup
- Remove inline hook implementations from src/index.ts
- Update documentation
- Commit changes

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
- ✅ Unit tests pass (100% coverage of hook methods)
- ✅ Integration tests pass
- ✅ No performance regression
- ✅ Code is easier to understand and maintain
- ✅ Adding a new hook is straightforward

---

## Consequences

### Positive
- ✅ Improved modularity and separation of concerns
- ✅ Better testability with explicit dependency injection
- ✅ Easier to add new hooks
- ✅ Clearer code organization
- ✅ Aligns with existing codebase patterns
- ✅ Encapsulates stateful hooks cleanly

### Negative
- ❌ Slightly more boilerplate than inline registration
- ❌ All dependencies passed to constructor (even if not all hooks use them)
- ❌ Requires refactoring existing code

### Neutral
- ➖ No change to external API or behavior
- ➖ No change to hook signatures or functionality

---

## Related Decisions

- **ProjectManager Pattern**: HookRegistry follows the same constructor injection pattern
- **Error Handling**: Hooks continue to use existing error handling patterns
- **Testing Strategy**: Unit tests follow existing test patterns in the codebase

---

## Future Considerations

### Sub-Registries
If hooks grow significantly, could organize them into sub-registries:
```typescript
export class HookRegistry {
  private systemHooks = new SystemHookRegistry(...)
  private executionHooks = new ExecutionHookRegistry(...)
}
```

### Hook Lifecycle Management
Could add lifecycle methods for initialization and cleanup:
```typescript
async initialize(): Promise<void>
async shutdown(): Promise<void>
```

### Hook Validation
Could add validation to ensure hooks are properly registered:
```typescript
validateHooks(): ValidationResult
```

---

## Approval

**Decided by:** Research phase (automated analysis)  
**Reviewed by:** (Pending implementation review)  
**Approved by:** (Pending implementation approval)

---

## References

- **Research Document:** `research/hooks-abstraction-research.md`
- **Implementation Guide:** `research/implementation-guide.md`
- **Current Code:** `src/index.ts` (lines 151-371)
- **Reference Implementation:** https://github.com/alvinunreal/oh-my-opencode-slim/tree/master/src/hooks

---

## Change Log

| Date | Status | Notes |
|------|--------|-------|
| 2026-03-04 | Decided | Initial decision record created |
| TBD | Implemented | HookRegistry implementation completed |
| TBD | Verified | Integration tests passed |
| TBD | Deployed | Changes merged to main |
