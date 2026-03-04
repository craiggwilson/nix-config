# Hook registry impl

> Implemented HookRegistry with type-safe hook composition, priority ordering, error resilience, and 13 tests covering all hook behaviors.

## Metadata

| Field | Value |
|-------|-------|
| ID | del-mmcihbrz-f0c24cfd |
| Project | opencode-projects-plugin-hooks-0d2eb5 |
| Issue | opencode-projects-plugin-hooks-0d2eb5-944.7 |
| Status | completed |
| Started | 2026-03-04T20:50:57.119Z |
| Completed | 2026-03-04T21:03:19.900Z |
| Agent | coder |
| Worktree | /home/craig/Projects/hdwlinux/nix-config-worktrees/opencode-projects-plugin-hooks-0d2eb5-944.7 |

## Prompt

# Task: opencode-projects-plugin-hooks-0d2eb5-944.7

You are the PRIMARY agent for this task. Your role: coder

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

## Your Responsibilities

1. Complete the main work for this issue
2. Write code, make changes, implement the solution
3. Commit your changes with clear messages

## Quality Expectations

- Follow existing patterns in the codebase — don't introduce new conventions without reason
- Write tests if the codebase has them
- Leave code in a better state than you found it
- If you can't complete something, say so explicitly rather than delivering partial work silently

## On Reviewer Feedback

When a reviewer raises concerns:
- Understand what they're actually saying before responding
- Defend your approach if you believe it's sound — you have context the reviewer may lack
- Only change course for true blockers (bugs, broken logic, missing critical pieces)
- Do not concede to stylistic preferences, "could be better" suggestions, or reviewer uncertainty
- If you change your approach, explain why the reviewer's point was valid

## Project Context

**Project directory:** /home/craig/Projects/hdwlinux/nix-config/.projects/opencode-projects-plugin-hooks-0d2eb5

Store artifacts in the project directory:
- Research documents: `/home/craig/Projects/hdwlinux/nix-config/.projects/opencode-projects-plugin-hooks-0d2eb5/research/`
- Decisions: `/home/craig/Projects/hdwlinux/nix-config/.projects/opencode-projects-plugin-hooks-0d2eb5/decisions/`

After creating an artifact file, register it with `project-save-artifact`.

## Worktree

You are working in an isolated worktree at: /home/craig/Projects/hdwlinux/nix-config-worktrees/opencode-projects-plugin-hooks-0d2eb5-944.7
Make all your changes there.

## Note

Other agents will review your work. Focus on quality implementation.

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

The implementation is complete. Here's a summary of what was implemented:

## Summary

### Files Created

**`src/hooks/types.ts`**
- `HookSignatures` interface — maps all 5 hook names to their input/output types, derived from the opencode SDK's `Hooks` interface
- `HookName` type — union of all supported hook names
- `Hook<K>` interface — a single handler unit with `name`, optional `priority`, and `handler`

**`src/hooks/registry.ts`**
- `HookRegistry` class with:
  - `register<K>(hook: Hook<K>)` — registers a handler, storing insertion index for stable sort
  - `buildHooks(log?)` — composes all registered handlers into the opencode plugin hooks shape, sorted by ascending priority with registration order as tiebreaker
  - Error resilience: catching handler errors, logging warnings, and continuing to the next handler
  - Handles both two-argument hooks (`shell.env`, `experimental.*`) and single-argument hooks (`event`, `config`)

**`src/hooks/index.ts`**
- Barrel export for the module

**`src/hooks/registry.test.ts`**
- 13 tests covering:
  - Single handler registration and invocation
  - Single-argument hooks (`event`, `config`)
  - Priority ordering (ascending)
  - Registration order as tiebreaker for equal priorities
  - Default priority (100) behavior
  - Sequential mutation (each handler sees prior mutations)
  - Error resilience (throwing handler doesn't stop subsequent handlers)
  - Warning logging on handler failure
  - `buildHooks()` shape (omits unregistered hooks, returns functions)

---

*Generated: 2026-03-04T21:03:19.900Z*