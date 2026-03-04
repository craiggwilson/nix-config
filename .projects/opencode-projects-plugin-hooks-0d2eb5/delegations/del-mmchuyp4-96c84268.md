# Factory Sig Research Review

> Reviewed type-safe factory signature research. Found a critical bug in concrete examples where c.resolve() calls were used despite being the anti-pattern being eliminated. Inconsistency identified bet

## Metadata

| Field | Value |
|-------|-------|
| ID | del-mmchuyp4-96c84268 |
| Project | opencode-projects-plugin-hooks-0d2eb5 |
| Issue | opencode-projects-plugin-hooks-0d2eb5-944.5 |
| Status | completed |
| Started | 2026-03-04T20:33:33.736Z |
| Completed | 2026-03-04T20:34:43.797Z |
| Agent | coder |

## Prompt

# Review Task: opencode-projects-plugin-hooks-0d2eb5-944.5

You are a REVIEWER for this task. Your role: coder

## Issue

Research: type-safe factory signature that eliminates dual dependency declaration

The current two-phase container design requires declaring dependencies twice:

```typescript
// Current design — fragile, must stay in sync manually
container.register(
  Tokens.ProjectManager,
  [Tokens.Config, Tokens.Shell],          // declared here
  (c) => new ProjectManager(
    c.resolve(Tokens.Config),             // and resolved here
    c.resolve(Tokens.Shell),
  )
)
```

The desired API eliminates this duplication. The token array IS the factory's argument list:

```typescript
// Desired API — single source of truth
container.register(
  Tokens.ProjectManager,
  [Tokens.Config, Tokens.Shell],
  (cfg, shell) => new ProjectManager(cfg, shell)
)
```

The container resolves each token in the array and passes the resolved values as positional arguments to the factory. The factory never calls `c.resolve()` — it just receives its dependencies as typed arguments.

## Research Questions

1. **Type-safe token array** — Can TypeScript infer the factory argument types from the token array? The tokens need to carry their resolved type (e.g., `Token<Config>`, `Token<Shell>`). When you pass `[Tokens.Config, Tokens.Shell]`, TypeScript should infer the factory signature as `(cfg: Config, shell: Shell) => T`. Explore how to make this work with mapped/conditional types.

2. **Token type design** — What should a typed token look like? Options:
   - `const Tokens = { Config: Symbol("Config") as Token<Config> }` — branded symbol
   - `const Tokens = { Config: new Token<Config>("Config") }` — class instance
   - Something else?
   How does the choice affect type inference in the register call?

3. **Variadic tuple types** — TypeScript 4.0+ supports variadic tuple types. Can we use these to map `[Token<A>, Token<B>, Token<C>]` → `(a: A, b: B, c: C) => T`? Show the concrete type definitions.

4. **Async factories** — Does the type-safe approach extend cleanly to async factories? `(cfg: Config, shell: Shell) => Promise<ProjectManager>` should be accepted alongside sync factories.

5. **`registerInstance` shorthand** — Alongside `register`, there should be a `registerInstance(token, value)` for pre-built values (e.g., `registerInstance(Tokens.Client, typedClient)`). How does this fit into the typed token design?

6. **Cycle detection compatibility** — The two-phase container needs the dependency list to build the graph and detect cycles. With this API, the token array is still explicit, so cycle detection still works. Confirm this and show how `build()` extracts the dependency graph from registrations.

7. **Concrete example** — Show all 5 existing plugin services registered with this API. The result should read naturally and have no `c.resolve()` calls inside factories.

## Constraints

- Must work without decorators or `reflect-metadata`
- TypeScript inference must work — no `as any` casts required at call sites
- Should degrade gracefully if inference hits TypeScript limits (e.g., >8 dependencies)
- Keep the container implementation simple — complexity should be in the types, not the runtime

## Context

- Prior container design: `.projects/opencode-projects-plugin-hooks-0d2eb5/research/lazy-resolution-di.md`
- Prior container design: `.projects/opencode-projects-plugin-hooks-0d2eb5/research/lazy-resolution-implementation.md`
- Plugin source: `hdwlinux/packages/opencode-projects-plugin/src/`

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

I now have sufficient context to provide a thorough review. Let me analyze the research documents carefully.

---

## Review: Type-Safe Factory Signature Research

The research is thorough and well-structured. It correctly addresses all 7 research questions from the issue. Here is my assessment:

---

#### Blockers (if any)

**1. Concrete example has a bug: `c.resolve()` calls sneak back in for zero-dependency services**

In the "Concrete Example" section (Section 8 of `type-safe-factory-signatures.md`, lines 616–631), the researcher registers `IssueStorage` and `Logger` with empty dependency arrays but then calls `container.resolve()` inside the factory:

```typescript
// Service 2: Register IssueStorage (no dependencies)
container.register(
  Tokens.IssueStorage,
  [],
  () => new BeadsIssueStorage(container.resolve(Tokens.Logger))  // ← c.resolve() snuck back in!
)

// Service 4: Register Logger (no dependencies)
container.register(
  Tokens.Logger,
  [],
  () => createLogger(container.resolve(Tokens.Client))  // ← same problem
)
```

This directly contradicts the stated goal ("The factory never calls `c.resolve()`") and reintroduces the fragility the design is meant to eliminate. The correct registrations should declare the actual dependencies in the token array:

```typescript
container.register(Tokens.Logger, [Tokens.Client], (client) => createLogger(client))
container.register(Tokens.IssueStorage, [Tokens.Logger], (logger) => new BeadsIssueStorage(logger))
```

The later "Concrete Example" in `type-safe-factory-detailed-analysis.md` (Question 7) gets this right — `Logger` and `IssueStorage` are registered with proper dependency arrays. The inconsistency between the two documents is a blocker because the implementation guide (`type-safe-factory-implementation-guide.md`, Phase 3, Step 3.1) repeats the correct version, but the primary research document (`type-safe-factory-signatures.md`) has the buggy version. This needs to be corrected before implementation to avoid confusion.

**2. `resolveAll()` has a redundant cycle check that can give misleading errors**

In the `resolveAll()` implementation (implementation guide, lines 353–388), there is a `visiting` set that re-implements cycle detection:

```typescript
if (visiting.has(token)) {
  throw new Error(`Circular dependency detected: ${token.name}`)
}
```

But `detectCycles()` already runs before `resolveAll()` and provides a much better error message with the full cycle path. The redundant check in `resolveAll()` will fire with a less informative message (just the token name, not the full path) if somehow a cycle slips through. This is a minor correctness issue — the `visiting` set in `resolveAll()` is actually serving a different purpose (preventing double-resolution), but the error message is misleading. The guard should be removed or the error message should be changed to something like `"Internal error: unexpected re-entry resolving ${token.name}"` since cycles are already caught by `detectCycles()`.

---

#### Concerns (non-blocking)

**1. `ResolveTokens` mapped type may not preserve tuple structure in all TypeScript versions**

The mapped type `{ [K in keyof T]: ... }` over a tuple type works correctly in TypeScript 4.1+ but the behavior of `keyof` on tuples (preserving positional indices vs. including array methods) can be subtle. The research correctly notes TS 4.0+ is required, but doesn't mention that `as const` on the dependency array at the call site is important for TypeScript to infer a tuple type rather than `Token<any>[]`. The implementation guide should note that inline arrays (without `as const`) will work because TypeScript infers tuple types for inline array literals in generic positions — but this is worth a brief note.

**2. `ServiceDescriptor.factory` type is `(...args: any[]) => any | Promise<any>`**

The internal `ServiceDescriptor` interface uses `any[]` for the factory, which is correct (the type safety is enforced at the `register()` call site, not in storage). However, the return type `any | Promise<any>` simplifies to just `any` (since `any` absorbs the union). This is a minor type imprecision in the internal interface — not a problem in practice, but worth noting for clarity.

**3. `build()` idempotency: frozen check returns early but doesn't re-validate**

The `build()` method returns early if already frozen. This is correct for the happy path, but if someone calls `build()` twice and the second call is expected to pick up new registrations (which it shouldn't, since the container is frozen), the silent return could be confusing. The current behavior is correct — just worth documenting clearly that `build()` is a one-way door.

**4. The "graceful degradation" example for >8 dependencies has a bug**

In Section 9 of `type-safe-factory-signatures.md`:

```typescript
((a, b, c, d, e, f, g, h, i): ComplexService => {
  return new ComplexService(a, b, c, d, e, f, g, h, i)
}) as Factory<typeof dependencies, ComplexService>
```

The variable `dependencies` is referenced but not defined in that snippet. This is just a documentation issue in the research, not a code issue.

**5. The `has()` method checks `descriptors` but not `services`**

After `build()`, `has()` still works correctly (descriptors are never cleared), but it might be more intuitive to also check `services` after build. This is a minor API design concern.

---

#### Verdict

**REQUEST CHANGES**

The blocker is the inconsistency in the primary research document (`type-safe-factory-signatures.md`) where `IssueStorage` and `Logger` are registered with empty dependency arrays but call `container.resolve()` inside their factories. This directly contradicts the design goal and would confuse implementers. The correct pattern is shown in the detailed analysis document, so the fix is straightforward: update Section 8 of `type-safe-factory-signatures.md` to match the correct registrations in `type-safe-factory-detailed-analysis.md` Question 7.

The redundant cycle detection in `resolveAll()` should also be addressed — either remove the misleading error or change the message to reflect it's an internal invariant violation.

---

*Generated: 2026-03-04T20:34:43.797Z*