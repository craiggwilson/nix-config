# DI Research Review

> Reviewed primary agent's DI container research. Identified 3 issues: fragile cycle detection path tracking, invalid TypeScript global augmentation pattern, and a forward-reference bug.

## Metadata

| Field | Value |
|-------|-------|
| ID | del-mmch28ow-c1be9e4d |
| Project | opencode-projects-plugin-hooks-0d2eb5 |
| Issue | opencode-projects-plugin-hooks-0d2eb5-944.3 |
| Status | completed |
| Started | 2026-03-04T20:11:13.664Z |
| Completed | 2026-03-04T20:12:13.901Z |
| Agent | technical-writer |

## Prompt

# Review Task: opencode-projects-plugin-hooks-0d2eb5-944.3

You are a REVIEWER for this task. Your role: technical-writer

## Issue

Research: lazy resolution to eliminate registration order dependency

The current DI container design requires modules to be registered in strict dependency order (config → vcs → projects → execution → sessions). This is fragile — if someone adds a module and registers it in the wrong order, it silently fails at runtime.

Explore how lazy resolution could eliminate this constraint. The core idea: instead of resolving dependencies eagerly at registration time, defer resolution until after all modules have registered (i.e., the container is "frozen" or "built"). This way, registration order doesn't matter — everything is wired up at the end.

## Questions to Answer

1. **Lazy factory pattern** — Instead of `container.resolve(Tokens.X)` inside `register()`, could factories capture a reference to the container and resolve lazily when first called? What does this look like in practice?

2. **Two-phase initialization** — Could we split into a "register" phase (declare what you provide and what you need) and a "build" phase (resolve everything, detect cycles, validate completeness)? What's the API?

3. **Cycle detection** — With lazy resolution, circular dependencies become detectable at build time rather than causing infinite loops at runtime. How do we detect and report them clearly?

4. **Async initialization** — Some services need async setup (e.g., `worktreeManager.detectVCS()`). How does lazy resolution interact with async factories? Can we support `async` factory functions?

5. **Frozen container** — After the build phase, the container should be immutable (no new registrations). What does this look like? Is it worth enforcing?

6. **Concrete example** — Show what the `register()` functions from the current design would look like under lazy resolution. Does the API get simpler or more complex for module authors?

## Context

- Current design: `.projects/opencode-projects-plugin-hooks-0d2eb5/research/composable-hook-registry-di.md` (Section 3-4)
- The hand-rolled container is preferred (no external deps) — this research is about improving that design, not replacing it with a framework
- Must still support async initialization
- Must remain simple and explicit — no magic

## Primary Agent's Work

The primary agent (researcher) is implementing this. Your job is to:
1. Review their approach and implementation
2. Identify BLOCKING issues and non-blocking concerns separately
3. Provide constructive feedback

## What Constitutes a Blocker

**BLOCKERS** (request changes for these):
- Bugs or incorrect logic in the implementation
- Missing critical functionality the issue explicitly requires
- Approach that will break integration with existing systems
- Security or data loss risk

**NOT BLOCKERS** (note as concerns, not blockers):
- Stylistic preferences
- Minor ambiguities a developer can resolve
- Suboptimal approach (if it works and isn't harmful)
- Nice-to-have improvements

## Output Format

Structure your response with:

#### Blockers (if any)
- [Specific blocker + what needs to change]

#### Concerns (non-blocking)
- [Specific concerns that don't block work]

#### Verdict
**APPROVE** or **REQUEST CHANGES** (only if blockers exist)

## Project Context

**Project directory:** /home/craig/Projects/hdwlinux/nix-config/.projects/opencode-projects-plugin-hooks-0d2eb5

You can read artifacts from the project directory:
- Research documents: `/home/craig/Projects/hdwlinux/nix-config/.projects/opencode-projects-plugin-hooks-0d2eb5/research/`
- Decisions: `/home/craig/Projects/hdwlinux/nix-config/.projects/opencode-projects-plugin-hooks-0d2eb5/decisions/`

## Hard Blocks (NEVER violate)

- **Never commit** without being explicitly asked to
- **Never push to remote** under any circumstances
- **Never leave code in a broken state** — if you can't complete something, restore the previous working state and say so explicitly
- **Never deliver a final answer** before collecting all reviewer feedback

## Constraints

You are running as a background delegation. The following tools are disabled:
- project-create, project-close, project-create-issue, project-update-issue, project-work-on-issue
- question, task, delegate (no recursive delegation)

Focus on completing your assigned role.

## Result

I now have a thorough understanding of the primary agent's research. Let me review the key aspects against the issue requirements.

---

#### Blockers (if any)

**1. Circular dependency detection has a bug in the path tracking**

In `lazy-resolution-implementation.md` (Step 1.1, `detectCycles`), the `path` array is shared across all DFS branches via closure, but `path.pop()` is called after visiting children — this is correct for a single-threaded DFS. However, the `path.indexOf(token)` call in the cycle error message is unreliable: `indexOf` finds the *first* occurrence of `token` in the path, but `token` is a `Symbol`. Since Symbols are unique, this works — but the logic is subtly fragile. More critically, the `path` variable is declared *outside* the `visit` function and mutated via push/pop. If `visit` throws mid-traversal (e.g., on a cycle), the `path` array is left in a dirty state. This doesn't matter for the cycle case (we throw immediately), but it's a latent bug if the code is ever extended.

This is a minor implementation concern, not a blocker on its own.

**2. The `ServiceTypes` interface uses a `declare global` augmentation that won't work**

In `lazy-resolution-implementation.md` Step 1.2 (`tokens.ts`):

```typescript
declare global {
  interface AsyncHybridContainer {
    resolve<K extends keyof ServiceTypes>(token: K): ServiceTypes[K]
  }
}
```

This is a **blocker**. `AsyncHybridContainer` is a class, not a global interface. You cannot augment a class via `declare global` — that pattern only works for interfaces in the global scope (like `Window` or `Array`). This code will not compile. The typed `resolve` method needs to be defined directly on the class, or a typed wrapper/subclass needs to be created. The research presents this as production-ready code, but it contains a TypeScript error that would prevent compilation.

**3. The concrete example in `lazy-resolution-di.md` Section 7 has a forward-reference bug**

In the "Proposed Pattern" example (Section 7, `lazy-resolution-di.md`), `ProjectManager` is registered with `Tokens.TeamManager` as a dependency:

```typescript
container.register(
  Tokens.ProjectManager,
  [Tokens.Config, Tokens.WorktreeManager, Tokens.Logger],
  (c) => new ProjectManager(
    c.resolve(Tokens.Config),
    c.resolve(Tokens.WorktreeManager),
    log,
    c.resolve(Tokens.TeamManager)  // Will be resolved after registration
  )
)
```

But `Tokens.TeamManager` is **not listed in the dependencies array** — it's only referenced inside the factory. The two-phase container validates dependencies from the declared array, not from what the factory actually calls. This means the validation step would pass (no error), but `TeamManager` might not be resolved before `ProjectManager`'s factory runs, causing a runtime error. The comment "Will be resolved after registration" suggests the author noticed this but didn't fix it. This is a **blocker** because it demonstrates a fundamental misunderstanding of the pattern being recommended: the dependency array and the factory's `resolve` calls must be kept in sync, and the research doesn't address this maintenance burden or provide a mechanism to enforce it.

---

#### Concerns (non-blocking)

**1. The "Async Hybrid" recommendation is actually eager, not lazy**

The document title and executive summary promise "lazy resolution," but the recommended `AsyncHybridContainer` resolves all services eagerly during `build()` (see `resolveAll()`). The `HybridContainer` (Section 4) is the truly lazy variant. The research conflates these two approaches throughout. This is a terminology inconsistency that could confuse implementers, but the chosen approach (eager resolution at build time) is actually the better choice for this use case — it just shouldn't be called "lazy."

**2. Dependency declaration duplication is a real maintenance burden, not just a "limitation"**

The research notes this as a limitation but doesn't propose a mitigation. In practice, every time a factory's dependencies change, the developer must update both the dependency array and the factory body. The research should recommend a convention or linting rule to catch mismatches (e.g., a comment pattern, or a helper that extracts tokens from the factory signature). This is a non-trivial ergonomic issue for module authors.

**3. The `has()` method behavior changes between build phases**

Before `build()`, `has()` checks `this.descriptors`. After `build()`, services are in `this.services`, but `has()` still only checks `this.descriptors`. This is consistent but could surprise callers who call `has()` after build to check if a service is available. The research doesn't document this behavior.

**4. The `WorktreeManager` async factory in the concrete example calls `detectVCS()` without `await`**

In `lazy-resolution-di.md` Section 7:

```typescript
container.register(
  Tokens.WorktreeManager,
  [Tokens.Config],
  (c) => {
    const manager = new WorktreeManager(repoRoot, $, log)
    manager.detectVCS()  // ← Missing await!
    return manager
  }
)
```

The factory is not declared `async` and `detectVCS()` is not awaited. This is inconsistent with the stated goal of supporting async initialization. The `lazy-resolution-implementation.md` version correctly uses `async (c) => { await manager.detectVCS() }`, so this is an error in the concrete example only.

**5. The `isFrozen` / `isBuilt` flags are redundant**

In `lazy-resolution-implementation.md`, the container has both `isBuilt` and `isFrozen` flags, but they're always set together (`isFrozen = true` at the end of `build()`). The `isBuilt` flag is never checked independently. One flag is sufficient.

**6. No guidance on registering pre-built instances (values)**

The original container design supported `register(token, value)` for pre-built instances (e.g., `container.register(Tokens.Client, typedClient)`). The new design requires all registrations to go through the factory pattern with a dependency array. The research doesn't address how to register values that are already constructed (like `client`, `$`, `repoRoot`). The implementation example uses `() => typedClient` (a factory that ignores the container), which works but is awkward. A `registerValue(token, value)` convenience method would improve ergonomics.

---

#### Verdict

**REQUEST CHANGES**

The `declare global` augmentation for `AsyncHybridContainer` (blocker #2) is a TypeScript compilation error that would prevent the implementation from working. The forward-reference bug in the concrete example (blocker #3) demonstrates a gap in the research's treatment of the dependency-declaration-vs-factory-body synchronization problem — this is the core ergonomic challenge of the two-phase pattern and needs explicit guidance. These two issues need to be addressed before the research can be used as an implementation guide.

---

*Generated: 2026-03-04T20:12:13.901Z*