# TypeSafeContainer impl

> Implemented TypeSafeContainer with two-phase DI, token system, cycle detection, and topological resolution. Created 24 tests covering registration, async factories, cycles, and frozen state.

## Metadata

| Field | Value |
|-------|-------|
| ID | del-mmci7lft-ada096c0 |
| Project | opencode-projects-plugin-hooks-0d2eb5 |
| Issue | opencode-projects-plugin-hooks-0d2eb5-944.6 |
| Status | completed |
| Started | 2026-03-04T20:43:23.081Z |
| Completed | 2026-03-04T20:46:55.553Z |
| Agent | coder |
| Worktree | /home/craig/Projects/hdwlinux/nix-config-worktrees/opencode-projects-plugin-hooks-0d2eb5-944.6 |

## Prompt

# Task: opencode-projects-plugin-hooks-0d2eb5-944.6

You are the PRIMARY agent for this task. Your role: coder

## Issue

Implement TypeSafeContainer

Implement the hand-rolled two-phase DI container in `src/container/`.

## Files to create

- `src/container/token.ts` — `Token<T>` class
- `src/container/container.ts` — `TypeSafeContainer` class
- `src/container/index.ts` — barrel export

## API

```typescript
// Token carries its resolved type
class Token<T> {
  constructor(public readonly name: string) {}
}

class TypeSafeContainer {
  // Register a factory with typed dependency injection
  register<Deps extends Token<unknown>[], T>(
    token: Token<T>,
    deps: [...Deps],
    factory: (...args: ResolveTokens<Deps>) => T | Promise<T>
  ): void

  // Register a pre-built instance
  registerInstance<T>(token: Token<T>, value: T): void

  // Resolve a registered service (only valid after build())
  resolve<T>(token: Token<T>): T

  // Two-phase build: topological sort, cycle detection, eager resolution, freeze
  build(): Promise<void>

  // Check if a token is registered
  has<T>(token: Token<T>): boolean

  // Return the dependency graph (for debugging)
  getDependencyGraph(): Map<string, string[]>
}

// Variadic tuple type mapping: [Token<A>, Token<B>] → (a: A, b: B) => T
type ResolveTokens<T extends Token<unknown>[]> = {
  [K in keyof T]: T[K] extends Token<infer V> ? V : never
}
```

## Behaviour

- `register()` and `registerInstance()` throw if called after `build()`
- `resolve()` throws if called before `build()` or for an unregistered token
- `build()` runs DFS cycle detection, then resolves all services in topological order, then freezes the container
- If a factory throws during `build()`, the error propagates with context (which token failed)
- Async and sync factories both supported; `build()` is always async

## Tests

Write unit tests covering:
- Basic registration and resolution
- Async factory support
- Topological ordering (register in any order, resolve correctly)
- Cycle detection (clear error message with cycle path)
- Frozen container (register after build throws)
- `getDependencyGraph()` returns correct structure

## Reference

- Research: `.projects/opencode-projects-plugin-hooks-0d2eb5/research/type-safe-factory-signatures.md`
- Research: `.projects/opencode-projects-plugin-hooks-0d2eb5/research/type-safe-factory-implementation-guide.md`
- Research: `.projects/opencode-projects-plugin-hooks-0d2eb5/research/lazy-resolution-di.md`

## Commit

This should be its own commit: `feat(container): add TypeSafeContainer with two-phase DI`

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

You are working in an isolated worktree at: /home/craig/Projects/hdwlinux/nix-config-worktrees/opencode-projects-plugin-hooks-0d2eb5-944.6
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

The implementation is complete. Here's a summary of what was built:

## Summary

### Files created

**`src/container/token.ts`** — Core type definitions:
- `Token<T>` class — carries type information via the generic parameter; identity is by reference
- `Resolve<T>` — extracts the resolved type from a token
- `ResolveTokens<T>` — maps a tuple of tokens to a tuple of resolved types (the variadic tuple magic)
- `Factory<Deps, T>` — factory function type with inferred argument types
- `ServiceDescriptor` — internal storage type

**`src/container/container.ts`** — `TypeSafeContainer` class:
- `register()` — type-safe factory registration; TypeScript infers argument types from the dep array
- `registerInstance()` — pre-built value registration
- `resolve()` — post-build resolution
- `has()` — token presence check
- `getDependencyGraph()` — debug utility
- `build()` — two-phase: validate deps → DFS cycle detection → topological resolution → freeze

**`src/container/index.ts`** — barrel export

**`src/container/container.test.ts`** — 24 tests covering:
- Basic registration and resolution (instances, sync factories, multi-dep)
- Async factory support (including error propagation)
- Topological ordering (reverse registration order, diamond dependency)
- Cycle detection (self-cycle, two-node cycle, error message includes token names)
- Frozen container (register after build, resolve before build, idempotent build)
- `getDependencyGraph()` correctness

---

*Generated: 2026-03-04T20:46:55.553Z*