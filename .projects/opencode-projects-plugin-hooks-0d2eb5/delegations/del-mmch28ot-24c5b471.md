# Lazy DI Research Review

> Devil's Advocate review of lazy resolution research. Found documentation contradiction: claimed lazy init is actually eager resolution at build time. Requires fix before implementation.

## Metadata

| Field | Value |
|-------|-------|
| ID | del-mmch28ot-24c5b471 |
| Project | opencode-projects-plugin-hooks-0d2eb5 |
| Issue | opencode-projects-plugin-hooks-0d2eb5-944.3 |
| Status | completed |
| Started | 2026-03-04T20:11:13.661Z |
| Completed | 2026-03-04T20:12:27.633Z |
| Agent | architect |

## Prompt

# Review Task: opencode-projects-plugin-hooks-0d2eb5-944.3

You are a REVIEWER for this task. Your role: architect

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

Now I have a comprehensive understanding of the research. Let me provide my review as the Devil's Advocate architect.

---

## Review: Lazy Resolution Research (opencode-projects-plugin-hooks-0d2eb5-944.3)

### Summary

The researcher has produced thorough documentation exploring lazy resolution patterns to eliminate registration order dependency. The research covers all six questions from the issue and recommends an "Async Hybrid Container" pattern.

---

#### Blockers (if any)

**1. Contradiction between "lazy initialization" claim and actual implementation**

The research repeatedly claims the Async Hybrid Container provides "lazy initialization" (e.g., line 655-656 in `lazy-resolution-di.md`: "✅ Lazy initialization — Services only created when accessed"), but the actual implementation in `AsyncHybridContainer.build()` calls `resolveAll()` which **eagerly resolves all services at build time**.

Looking at `lazy-resolution-implementation.md` lines 209-236:
```typescript
private async resolveAll(): Promise<void> {
  const resolved = new Set<string | symbol>()
  const resolve = async (token: string | symbol): Promise<void> {
    // ...
    const instance = await descriptor.factory(this)
    this.services.set(token, instance)
    // ...
  }
  for (const token of this.descriptors.keys()) {
    await resolve(token)
  }
}
```

This is **eager resolution**, not lazy. The comparison table (line 1048-1054) incorrectly marks "Async Hybrid" as having "Lazy Init: ✅" when it actually has eager initialization.

**Impact:** This is a documentation/design inconsistency that could mislead implementers. The actual behavior (eager resolution at build time) is fine and arguably better for startup validation, but the documentation is incorrect.

**Fix required:** Either:
- (a) Update documentation to accurately describe eager resolution at build time, OR
- (b) Implement true lazy resolution in `resolve()` instead of `resolveAll()` in `build()`

---

**2. Missing type safety for dependency declarations**

The research acknowledges (line 661-662) that dependencies must be declared twice: once in the `dependencies` array and again in the factory. However, there's no mechanism to ensure these stay in sync.

Example from `lazy-resolution-implementation.md` lines 554-565:
```typescript
container.register(
  Tokens.ProjectManager,
  [Tokens.Config, Tokens.IssueStorage, Tokens.FocusManager, Tokens.Logger, Tokens.WorktreeManager],
  (c) =>
    new ProjectManager(
      c.resolve(Tokens.Config),
      c.resolve(Tokens.IssueStorage),
      c.resolve(Tokens.FocusManager),
      c.resolve(Tokens.Logger),
      repoRoot,
      typedClient,
      $,
      c.resolve(Tokens.TeamManager)  // ❌ TeamManager NOT in dependencies array!
    )
)
```

The factory resolves `Tokens.TeamManager` but it's **not declared in the dependencies array**. This means:
- Cycle detection won't catch cycles involving TeamManager
- Dependency validation won't catch if TeamManager is missing
- The whole point of explicit dependencies is defeated

**Impact:** This is a critical bug in the example code that demonstrates the exact failure mode the research is trying to prevent.

**Fix required:** Either:
- (a) Fix the example to include `Tokens.TeamManager` in the dependencies array, OR
- (b) Add runtime validation that factories only resolve declared dependencies (more complex)

---

#### Concerns (non-blocking)

**1. Eager resolution may have performance implications**

The `resolveAll()` approach creates all services at startup, even if some are never used. For a plugin with ~10 services this is negligible, but the research should acknowledge this trade-off more explicitly. The current documentation claims "lazy initialization" which is misleading.

**2. No consideration of optional dependencies**

The research doesn't address optional dependencies (services that may or may not be registered). The current design throws if any declared dependency is missing. This is probably fine for this use case, but worth noting.

**3. The `resolve()` call inside factories during `resolveAll()` is redundant**

In the implementation, `resolveAll()` resolves dependencies in order, then calls the factory. But the factory also calls `c.resolve()` for its dependencies. This works because resolved services are cached, but it's conceptually redundant. The factory could receive its dependencies directly instead of resolving them again.

**4. Missing consideration of service disposal/cleanup**

The research doesn't address how services would be cleaned up (e.g., closing connections, stopping timers). This may not be needed for this plugin, but is worth noting for completeness.

**5. Test coverage for async factory errors**

The test suite in `lazy-resolution-implementation.md` doesn't include tests for what happens when an async factory throws an error during `build()`. This is an important edge case.

---

#### Verdict

**REQUEST CHANGES**

The research is thorough and the overall direction is sound, but there are two blockers:

1. **Documentation inconsistency:** The research claims "lazy initialization" but implements eager resolution. This must be corrected to avoid misleading implementers.

2. **Example code bug:** The concrete example shows a factory resolving a dependency (`TeamManager`) that isn't declared in the dependencies array, which defeats the purpose of explicit dependency declaration.

Both issues are straightforward to fix:
- For #1: Update the comparison table and benefits lists to say "eager resolution at build time" instead of "lazy initialization"
- For #2: Add `Tokens.TeamManager` to the dependencies array in the example

Once these are addressed, the research is ready for implementation.

---

*Generated: 2026-03-04T20:12:27.634Z*