# Review: Hook Registry

> Build succeeds. Review identifies a blocker: types.ts violates AGENTS.md co-location rules and must be merged into registry.ts.

## Metadata

| Field | Value |
|-------|-------|
| ID | del-mmcix8ww-6f49e041 |
| Project | opencode-projects-plugin-hooks-0d2eb5 |
| Issue | opencode-projects-plugin-hooks-0d2eb5-944.7 |
| Status | completed |
| Started | 2026-03-04T21:03:19.904Z |
| Completed | 2026-03-04T21:05:15.863Z |
| Agent | debugger |
| Worktree | /home/craig/Projects/hdwlinux/nix-config-worktrees/opencode-projects-plugin-hooks-0d2eb5-944.7 |

## Prompt

# Review Task: opencode-projects-plugin-hooks-0d2eb5-944.7

You are a REVIEWER for this task. Your role: debugger

## Issue

Implement HookRegistry and hook type definitions

Implement the composable hook registry and all hook type definitions in `src/hooks/`.

## Files to create

- `src/hooks/types.ts` — `HookSignatures` map, `Hook<K>` interface, `HookName` type
- `src/hooks/registry.ts` — `HookRegistry` class
- `src/hooks/index.ts` — barrel export

## Hook type design

```typescript
// All hook names and their input/output types — single source of truth
interface HookSignatures {
  "experimental.chat.system.transform": {
    input: Parameters<ChatHook>[0]
    output: Parameters<ChatHook>[1]
  }
  "experimental.session.compacting": {
    input: Parameters<SessionCompactingHook>[0]
    output: Parameters<SessionCompactingHook>[1]
  }
  "shell.env": {
    input: Parameters<ShellEnvHook>[0]
    output: Parameters<ShellEnvHook>[1]
  }
  "event": {
    input: Parameters<EventHook>[0]
    output: Parameters<EventHook>[1]
  }
  "config": {
    input: Parameters<ConfigHook>[0]
    output: Parameters<ConfigHook>[1]
  }
}

type HookName = keyof HookSignatures

// A single hook handler unit
interface Hook<K extends HookName> {
  name: K
  priority?: number  // lower runs first, default 100
  handler: (
    input: HookSignatures[K]["input"],
    output: HookSignatures[K]["output"]
  ) => Promise<void> | void
}
```

Look at the actual opencode SDK types in `src/index.ts` to get the correct input/output types for each hook — use the existing hook registrations as the source of truth for the signatures.

## HookRegistry

```typescript
class HookRegistry {
  register<K extends HookName>(hook: Hook<K>): void

  // Build the plugin hooks object from all registered handlers
  // Multiple handlers for the same hook name are composed sequentially by priority
  // If a handler throws, the error is logged and execution continues
  buildHooks(): Record<string, unknown>  // returns the opencode plugin hooks shape
}
```

## Composition semantics

- Handlers for the same hook name run in ascending priority order (lower = first)
- If two handlers have the same priority, registration order is the tiebreaker
- If a handler throws, catch and log the error, then continue to the next handler
- The composed hook must match the exact calling convention opencode expects

## Tests

Write unit tests covering:
- Registering a single handler and verifying it's called
- Multiple handlers for the same hook name run in priority order
- A throwing handler doesn't prevent subsequent handlers from running
- `buildHooks()` returns the correct shape for opencode

## Reference

- Current hook registrations in: `hdwlinux/packages/opencode-projects-plugin/src/index.ts`
- Research: `.projects/opencode-projects-plugin-hooks-0d2eb5/research/composable-hook-registry-di.md`

## Commit

This should be its own commit: `feat(hooks): add HookRegistry and hook type definitions`

## Primary Agent's Work

The primary agent (coder) is implementing this. Your job is to:
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

## Worktree

The code is in an isolated worktree at: /home/craig/Projects/hdwlinux/nix-config-worktrees/opencode-projects-plugin-hooks-0d2eb5-944.7
You can read files there to review the implementation.
Do NOT modify files - you are read-only.

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

The build succeeds. Now let me provide my review:

---

## Review: HookRegistry and Hook Type Definitions

I've examined the implementation in the worktree. Here's my assessment:

### Files Reviewed

1. `src/hooks/types.ts` — Hook type definitions
2. `src/hooks/registry.ts` — HookRegistry class
3. `src/hooks/index.ts` — Barrel export
4. `src/hooks/registry.test.ts` — Unit tests

---

#### Blockers

**1. AGENTS.md violation: Separate `types.ts` file created**

The project's AGENTS.md explicitly states:

> **Type Organization**
> Do not create separate `types.ts` files. Types should be co-located with their implementation or exported from the module's `index.ts`.

The implementation creates `src/hooks/types.ts` as a separate file. According to the project's coding standards, these types should be co-located in `registry.ts` or exported directly from `index.ts`.

**What needs to change:** Move the type definitions from `types.ts` into `registry.ts` (co-located with the implementation) and delete `types.ts`. Update the barrel export in `index.ts` accordingly.

---

#### Concerns (non-blocking)

**1. Hook signature types may not match SDK exactly**

The `HookSignatures` interface defines types manually:

```typescript
"experimental.chat.system.transform": {
  input: { sessionID?: string; model: Model }
  output: { system: string[] }
}
```

Looking at the actual usage in `src/index.ts` (lines 151-170), the hook receives `_input` and `output` where `output.system` is an array that gets `.push()` called on it. The types appear correct, but they're manually derived rather than using the SDK's actual hook types. This is acceptable since the SDK doesn't export these types directly, but it creates a maintenance burden if the SDK changes.

**2. Test coverage is good but could verify async handler behavior**

The tests cover sync handlers well, but the implementation supports `Promise<void> | void` return types. While the tests do use `async` handlers, there's no explicit test verifying that a handler returning a Promise is properly awaited before the next handler runs.

**3. The `buildHooks` method has special-casing for `event` and `config` hooks**

Lines 56-69 in `registry.ts` special-case `event` and `config` hooks as "single-argument hooks" that pass `undefined` as the output. This works but is a bit fragile — if a new single-argument hook is added, the code needs to be updated. Consider deriving this from the type system (e.g., checking if `output` type is `void`).

---

#### Verdict

**REQUEST CHANGES**

The implementation is functionally correct and well-tested, but it violates the project's explicit coding standard about not creating separate `types.ts` files. This is a documented project convention that should be followed.

---

*Generated: 2026-03-04T21:05:15.863Z*