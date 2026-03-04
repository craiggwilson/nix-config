# Hook Registry Review

> Code review completed for HookRegistry and Hook type definitions. Implementation is correct with no blockers. Minor concerns noted about HookSignatures type alignment with SDK and type casting pattern

## Metadata

| Field | Value |
|-------|-------|
| ID | del-mmcix8wt-be2ae698 |
| Project | opencode-projects-plugin-hooks-0d2eb5 |
| Issue | opencode-projects-plugin-hooks-0d2eb5-944.7 |
| Status | completed |
| Started | 2026-03-04T21:03:19.901Z |
| Completed | 2026-03-04T21:05:15.102Z |
| Agent | code-reviewer |
| Worktree | /home/craig/Projects/hdwlinux/nix-config-worktrees/opencode-projects-plugin-hooks-0d2eb5-944.7 |

## Prompt

# Review Task: opencode-projects-plugin-hooks-0d2eb5-944.7

You are a REVIEWER for this task. Your role: code-reviewer

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

Now I have a complete picture of the implementation. Let me provide my review:

---

## Code Review: HookRegistry and Hook Type Definitions

### Overall Assessment

The implementation is well-structured and follows the design decisions documented in the research. The code is clean, properly typed, and the tests are comprehensive. The implementation correctly handles the key requirements: priority ordering, error resilience, and composition semantics.

---

### Blockers

**None.** The implementation is correct and complete.

---

### Concerns (non-blocking)

#### 1. `types.ts` — HookSignatures may not match SDK exactly

**Location:** `src/hooks/types.ts` lines 18-39

The `HookSignatures` interface defines types manually rather than deriving them from the SDK's `Hooks` interface. Comparing with the SDK (`@opencode-ai/plugin/dist/index.d.ts`):

- **`shell.env`**: SDK has `sessionID?: string` and `callID?: string` in input, but `types.ts` only has `cwd: string`. This is a minor discrepancy — the implementation will still work because handlers receive whatever opencode passes, but the types won't catch if a handler tries to access `sessionID`.

- **`event`**: SDK signature is `(input: { event: Event }) => Promise<void>`, but `types.ts` defines `input: { event: Event }` and `output: void`. The registry handles this correctly by passing `undefined` as output, so it works.

- **`config`**: SDK signature is `(input: Config) => Promise<void>`, but `types.ts` defines `input: Config` and `output: void`. Same as above — works correctly.

**suggestion:** Consider adding a comment in `types.ts` noting that these types are intentionally simplified and may not include all SDK fields. Alternatively, derive types from the SDK's `Hooks` interface using `Parameters<>` utility types as the issue description suggested.

#### 2. `registry.ts` — Type casting in handler invocation

**Location:** `src/hooks/registry.ts` lines 61-64, 78-83

The handler invocations use `as unknown as` casts to work around TypeScript's type narrowing limitations. This is a pragmatic solution but loses some type safety.

**nit:** The casts are necessary given the current design, but a comment explaining why would help future maintainers understand this isn't a code smell.

#### 3. `registry.ts` — Missing JSDoc on `HandlerEntry` interface

**Location:** `src/hooks/registry.ts` lines 12-15

Per the project's AGENTS.md, all exported types should have JSDoc. `HandlerEntry` is not exported, so this is technically fine, but the interface could benefit from a brief comment explaining its purpose.

**nit:** Consider adding a brief comment for internal documentation.

#### 4. `index.ts` — Types exported correctly

**Location:** `src/hooks/index.ts`

praise: The barrel export correctly uses `export type` for type-only exports, which is good practice for TypeScript.

#### 5. Tests — Comprehensive coverage

**Location:** `src/hooks/registry.test.ts`

praise: The tests cover all the requirements from the issue:
- Single handler registration and invocation ✅
- Multiple handlers with priority ordering ✅
- Registration order as tiebreaker ✅
- Error resilience (throwing handlers don't stop execution) ✅
- `buildHooks()` returns correct shape ✅
- Both single-argument hooks (`event`, `config`) and two-argument hooks ✅

The tests are well-organized with clear Arrange/Act/Assert structure.

#### 6. Missing hooks in `HookSignatures`

**Location:** `src/hooks/types.ts`

The SDK defines additional hooks that aren't in `HookSignatures`:
- `chat.message`
- `chat.params`
- `chat.headers`
- `permission.ask`
- `command.execute.before`
- `tool.execute.before`
- `tool.execute.after`
- `experimental.chat.messages.transform`
- `experimental.text.complete`
- `tool.definition`

**suggestion:** This is fine for now since the plugin only uses the 5 hooks defined. The comment in `types.ts` (line 17) correctly notes "Add new entries when the SDK gains new hooks." Consider adding a note that this is intentionally a subset of available hooks.

---

### Verdict

**APPROVE**

The implementation is correct, well-tested, and follows the design decisions from the research document. The concerns noted above are minor and don't block the work. The code is ready to be committed.

---

*Generated: 2026-03-04T21:05:15.103Z*