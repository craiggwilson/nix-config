# Type-Safe Factory Review

> Devil's advocate review of DI container type-safe factory research. Identified a bug in concrete examples and a missing constraint validation concern.

## Metadata

| Field | Value |
|-------|-------|
| ID | del-mmchuyp1-805ac968 |
| Project | opencode-projects-plugin-hooks-0d2eb5 |
| Issue | opencode-projects-plugin-hooks-0d2eb5-944.5 |
| Status | completed |
| Started | 2026-03-04T20:33:33.733Z |
| Completed | 2026-03-04T20:34:49.503Z |
| Agent | architect |

## Prompt

# Review Task: opencode-projects-plugin-hooks-0d2eb5-944.5

You are a REVIEWER for this task. Your role: architect

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

## Devil's Advocate Role

You are acting as the Devil's Advocate for this team. Your role is to provide critical analysis and find problems others missed.

### Your Mandate

Your job is to find problems others missed. Do NOT rubber-stamp. If you can't find issues, look harder.

You ARE here to:
- Identify real issues — bugs, incorrect assumptions, missing critical pieces
- Verify the approach is sound and will actually work
- Catch gaps that would cause implementation to fail
- Challenge conclusions that aren't supported by evidence

### What Constitutes a Blocker

**BLOCKERS** (request changes for these):
- Bugs or incorrect logic in the implementation
- Referenced file doesn't exist or is wrong
- Critical security or data loss risk
- Plan contains internal contradictions
- Approach violates established patterns in ways that would break integration
- Missing critical functionality the issue explicitly requires

**NOT BLOCKERS** (note as concerns, not blockers):
- Stylistic preferences
- Minor ambiguities a developer can resolve
- Suboptimal approach (if it works and isn't harmful)
- Nice-to-have improvements

### Output Format

Structure your response with these sections:

#### Blockers (if any)
- [Specific blocker + what needs to change]

#### Concerns (non-blocking)
- [Specific concerns that don't block work]

#### Verdict
**APPROVE** or **REQUEST CHANGES** (only if blockers exist)

### Anti-Patterns (DO NOT DO THESE)

❌ Rubber-stamping without actually examining the work
❌ Raising vague concerns without specific evidence
❌ Blocking on stylistic preferences or "I'd do it differently"
❌ Softening your critique because the primary agent pushed back
❌ Signalling convergence just to end the discussion

✅ Read the actual code/plan before forming an opinion
✅ Cite specific lines, files, or logic when raising concerns
✅ Maintain your position if you believe you're right
✅ Change your position only when presented with new evidence or reasoning

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

Now I have a complete picture of the primary agent's research. Let me provide my review as the Devil's Advocate architect.

---

## Review: Type-Safe Factory Signatures Research

### Summary

The primary agent has produced comprehensive research on eliminating dual dependency declaration in the DI container. The research covers all 7 research questions with detailed analysis, concrete type definitions, and implementation guides.

---

#### Blockers

1. **Bug in concrete example (lines 612-631 of `type-safe-factory-signatures.md`)**: The example shows `IssueStorage` and `Logger` registrations that still call `container.resolve()` inside the factory, which contradicts the entire purpose of the research:

   ```typescript
   // Service 2: IssueStorage (no dependencies)
   container.register(
     Tokens.IssueStorage,
     [],  // ← Claims no dependencies
     () => new BeadsIssueStorage(container.resolve(Tokens.Logger))  // ← But resolves Logger!
   )
   ```

   This is a **bug** — if `IssueStorage` depends on `Logger`, it must be declared in the dependency array and received as a parameter. The correct version appears later in the detailed analysis (line 854-857), but the initial example is wrong and could mislead implementers.

2. **Missing constraint validation**: The research doesn't address what happens when the factory receives dependencies but doesn't use them all. For example:

   ```typescript
   container.register(
     Tokens.Service,
     [Tokens.A, Tokens.B, Tokens.C],
     (a, b) => new Service(a, b)  // ← C is declared but not used
   )
   ```

   TypeScript will **not** catch this because function parameters can be ignored. This is a silent failure mode that defeats the "single source of truth" goal. The research should acknowledge this limitation and recommend a lint rule or runtime check.

---

#### Concerns (non-blocking)

1. **Redundant cycle detection**: The `resolveAll()` method (line 399-438 of `type-safe-factory-signatures.md`) includes its own cycle detection via the `visiting` set, but `detectCycles()` already runs before `resolveAll()`. This is defensive but redundant — the second check can never trigger if the first works correctly. Consider removing the redundant check or documenting why it exists.

2. **Token identity semantics**: The research recommends class instances for tokens, but doesn't address token identity. Two `new Token<Config>("Config")` calls create different tokens that won't match in the Map. This is correct behavior but could surprise developers. Consider adding a note about token identity or providing a `Tokens` object pattern as the canonical approach.

3. **Type inference limits understated**: The research mentions "8-10 dependencies" as the limit but doesn't provide evidence. TypeScript's tuple inference typically works well beyond this. The actual limit is more likely related to recursive type depth (50 by default) or instantiation depth (500). Consider testing with realistic dependency counts and documenting actual limits.

4. **Missing `getDependencyGraph()` method**: The implementation guide's `TypeSafeContainer` class doesn't include the `getDependencyGraph()` method that was present in the prior `AsyncHybridContainer` design. This debugging utility should be preserved.

5. **Inconsistent naming**: The research uses both `TypeSafeContainer` and `AsyncHybridContainer` names. The implementation guide settles on `TypeSafeContainer`, but this should be explicitly stated as the final name.

6. **No discussion of optional dependencies**: The research assumes all dependencies are required. What if a service has an optional dependency (e.g., `Logger | undefined`)? The current design doesn't support this pattern. Consider documenting this limitation or proposing a solution.

---

#### Verdict

**REQUEST CHANGES**

The research is thorough and the approach is sound, but the bug in the concrete example (using `container.resolve()` inside factories that claim no dependencies) is a blocker. This directly contradicts the research's core goal and could mislead implementers.

**Required fixes:**
1. Correct the `IssueStorage` and `Logger` examples in section 8 of `type-safe-factory-signatures.md` to properly declare dependencies and receive them as parameters
2. Add a note about the limitation that unused parameters in factories are not caught by TypeScript

---

*Generated: 2026-03-04T20:34:49.503Z*