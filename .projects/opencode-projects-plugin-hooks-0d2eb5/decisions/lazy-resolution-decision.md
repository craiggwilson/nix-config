# Decision: Implement Async Hybrid Container with Lazy Resolution

**Date:** 2026-03-04  
**Status:** Proposed  
**Decision Maker:** Research Team  
**Scope:** DI Container Design for opencode-projects-plugin

---

## Context

The current DI container design (from `composable-hook-registry-di.md`) requires modules to be registered in strict dependency order:

```
config → vcs → projects → execution → sessions
```

This is fragile because:
1. **Silent failures** — Wrong registration order only fails at runtime
2. **Implicit dependencies** — Dependency graph not explicit in code
3. **No validation** — Missing dependencies only caught at first use
4. **Difficult to extend** — Adding new modules requires understanding entire graph

### Problem Statement

How can we eliminate registration order dependency while maintaining:
- Explicit dependency declarations
- Cycle detection
- Async initialization support
- Clear error messages
- Minimal API complexity

---

## Decision

**Implement an Async Hybrid Container with the following characteristics:**

1. **Two-phase initialization:**
   - Register phase: Declare services and dependencies (order-independent)
   - Build phase: Validate dependency graph, detect cycles, resolve services

2. **Explicit dependencies:**
   - Each service declares what it depends on
   - Dependencies validated at build time

3. **Cycle detection:**
   - Circular dependencies detected at build time
   - Clear error messages showing the cycle

4. **Async factory support:**
   - Factories can be async (needed for `detectVCS()`)
   - All services resolved during build phase

5. **Frozen container:**
   - Container immutable after build
   - Prevents accidental modifications

### Implementation Details

**Container Class:** `AsyncHybridContainer`

```typescript
export class AsyncHybridContainer {
  register<T>(
    token: string | symbol,
    dependencies: (string | symbol)[],
    factory: (container: AsyncHybridContainer) => Promise<T> | T
  ): void

  async build(): Promise<void>

  resolve<T>(token: string | symbol): T
}
```

**Key Methods:**
- `register()` — Register a service with explicit dependencies
- `build()` — Validate and resolve all services
- `resolve()` — Get a service (only after build)

**Features:**
- ✅ Order-independent registration
- ✅ Explicit dependency declarations
- ✅ Cycle detection at build time
- ✅ Async factory support
- ✅ Clear error messages
- ✅ Frozen container after build
- ✅ ~200 lines of code
- ✅ No external dependencies

---

## Rationale

### Why Async Hybrid Container?

**Compared to Lazy Factory Pattern:**
- ✅ Cycle detection (lazy factories don't detect cycles)
- ✅ Dependency validation (lazy factories don't validate)
- ✅ Clear error messages (lazy factories fail at runtime)
- ❌ Slightly more verbose (must declare dependencies)

**Compared to Two-Phase Container:**
- ✅ Lazy initialization (two-phase resolves all services eagerly)
- ✅ Better performance (services only created when accessed)
- ❌ Slightly more complex (adds lazy resolution logic)

**Compared to External DI Frameworks (tsyringe, awilix):**
- ✅ No external dependencies
- ✅ Explicit and debuggable
- ✅ Full control over behavior
- ✅ Minimal code (~200 lines)
- ❌ No automatic dependency resolution
- ❌ Must manually wire dependencies

### Why This Solves the Problem

1. **Registration order independence**
   - Services can be registered in any order
   - Dependencies resolved during build phase
   - No silent failures

2. **Explicit dependencies**
   - Each service declares what it needs
   - Dependency graph visible in code
   - Easy to understand and maintain

3. **Cycle detection**
   - Circular dependencies caught at build time
   - Clear error messages showing the cycle
   - Prevents runtime infinite loops

4. **Async support**
   - Factories can be async
   - Supports `detectVCS()` and other async initialization
   - All services initialized before use

5. **Clear error messages**
   - "Service X depends on Y, which is not registered"
   - "Circular dependency detected: A → B → A"
   - Errors at startup, not at first use

---

## Alternatives Considered

### Alternative 1: Lazy Factory Pattern

**Concept:** Factories capture container reference and resolve lazily.

**Pros:**
- ✅ Order-independent registration
- ✅ Lazy initialization
- ✅ Simple API

**Cons:**
- ❌ No cycle detection (infinite loops at runtime)
- ❌ No dependency validation (missing deps fail at first use)
- ❌ Implicit dependencies (hidden in factory code)
- ❌ Harder to debug

**Decision:** Rejected — No cycle detection or validation

### Alternative 2: Two-Phase Container

**Concept:** Register phase declares dependencies; build phase validates and resolves all services.

**Pros:**
- ✅ Order-independent registration
- ✅ Explicit dependencies
- ✅ Cycle detection
- ✅ Dependency validation

**Cons:**
- ❌ Eager resolution (all services created at build time)
- ❌ Slower startup (must wait for all services)
- ❌ Wastes resources (services created even if not used)

**Decision:** Rejected — Eager resolution is inefficient

### Alternative 3: External DI Framework (tsyringe)

**Concept:** Use mature DI framework with decorators.

**Pros:**
- ✅ Mature and well-tested
- ✅ Automatic dependency resolution
- ✅ Supports scopes and lifetimes

**Cons:**
- ❌ External dependency
- ❌ Requires decorators (experimental TypeScript feature)
- ❌ Requires reflect-metadata polyfill
- ❌ Magic behavior (harder to debug)
- ❌ Overkill for ~10 services

**Decision:** Rejected — Too heavy for this use case

### Alternative 4: Composition Module

**Concept:** Single module that composes all services.

**Pros:**
- ✅ Simple and explicit
- ✅ All dependencies visible in one place

**Cons:**
- ❌ Doesn't scale (becomes unwieldy with many services)
- ❌ Tight coupling (all services in one file)
- ❌ Hard to extend (must modify central module)

**Decision:** Rejected — Doesn't scale

---

## Implementation Plan

### Phase 1: Create Container Infrastructure (1-2 hours)
1. Implement `AsyncHybridContainer` class
2. Add cycle detection algorithm
3. Add dependency validation
4. Write comprehensive tests

### Phase 2: Migrate Plugin Entry Point (2-3 hours)
1. Update `src/index.ts` to use new container
2. Register all services with explicit dependencies
3. Call `container.build()` before using services
4. Verify all hooks work correctly

### Phase 3: Update Module Registration (1-2 hours)
1. Update each `register()` function to use new container
2. Remove registration order constraints from documentation
3. Add examples of adding new services

### Phase 4: Cleanup (30 minutes)
1. Remove old container implementation
2. Update documentation
3. Commit changes

**Total Effort:** 4-7 hours

---

## Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Circular dependencies | Low | High | Cycle detection at build time |
| Missing dependencies | Low | High | Validation at build time |
| Async factory errors | Medium | High | Clear error messages, comprehensive tests |
| Performance regression | Low | Low | Container is simple Map lookup |
| Migration breaks functionality | Medium | High | Incremental migration, extensive testing |
| Dependency declaration overhead | Low | Low | Clear patterns and documentation |

---

## Success Criteria

- ✅ All hooks work correctly after migration
- ✅ Unit tests pass (100% coverage of container)
- ✅ Integration tests pass
- ✅ No performance regression
- ✅ Circular dependencies detected at build time
- ✅ Missing dependencies detected at build time
- ✅ Clear error messages for all failure cases
- ✅ Documentation updated
- ✅ Code is easier to understand and maintain
- ✅ Adding a new service is straightforward

---

## Consequences

### Positive

1. **Eliminates registration order dependency**
   - Services can be registered in any order
   - No more silent failures from wrong order

2. **Explicit dependency graph**
   - Each service declares what it needs
   - Dependency graph visible in code
   - Easy to understand and maintain

3. **Early error detection**
   - Circular dependencies caught at build time
   - Missing dependencies caught at build time
   - Errors at startup, not at first use

4. **Supports async initialization**
   - Factories can be async
   - Supports `detectVCS()` and other async operations
   - All services initialized before use

5. **Easier to extend**
   - Adding a new service is straightforward
   - No need to understand entire dependency graph
   - Clear patterns for new services

### Negative

1. **Slightly more verbose**
   - Must declare dependencies in register call
   - Dependency declaration overhead

2. **Eager resolution**
   - All services resolved at build time
   - Slightly slower startup (but negligible for ~10 services)

3. **Learning curve**
   - New pattern for developers
   - Must understand two-phase initialization

### Neutral

1. **No external dependencies**
   - Container is hand-rolled (~200 lines)
   - Adds to codebase maintenance burden

---

## Related Decisions

- **Decision:** Adopt HookRegistry class pattern (from `hook-abstraction-decision.md`)
  - **Relationship:** This DI container supports the HookRegistry pattern
  - **Impact:** HookRegistry can be registered as a service in the container

---

## Future Considerations

### Potential Enhancements

1. **Service scopes**
   - Support request-scoped services
   - Support transient services (new instance each time)

2. **Lazy initialization**
   - Defer service creation until first access
   - Reduce startup time for large service graphs

3. **Service factories**
   - Support factory functions that create multiple services
   - Support conditional service registration

4. **Debugging tools**
   - Visualize dependency graph
   - Trace service resolution
   - Performance profiling

### Migration Path

If external DI framework becomes necessary in the future:
1. Container interface is well-defined
2. Can implement adapter for external framework
3. No changes needed to service registration code

---

## Approval

**Status:** Proposed  
**Approved By:** [Pending Review]  
**Date Approved:** [Pending]

---

## References

- `lazy-resolution-di.md` — Detailed research on lazy resolution patterns
- `lazy-resolution-implementation.md` — Step-by-step implementation guide
- `composable-hook-registry-di.md` — Original DI container design
- `hook-abstraction-decision.md` — HookRegistry pattern decision

---

## Document History

| Date | Author | Change |
|------|--------|--------|
| 2026-03-04 | Research Team | Initial proposal |

---

**Decision Status:** ⏳ Proposed (Awaiting Review)  
**Confidence Level:** High (8.8/10)  
**Ready for Implementation:** Yes
