# Container onBuild hooks

> Added onBuild callback support to TypeSafeContainer and updated all five modules to wire hooks via container.onBuild(). Added 8 new tests covering callback ordering, async support, and error propagati

## Metadata

| Field | Value |
|-------|-------|
| ID | del-mmcme5k5-f10295bd |
| Project | opencode-projects-plugin-hooks-0d2eb5 |
| Issue | opencode-projects-plugin-hooks-0d2eb5-944.13 |
| Status | completed |
| Started | 2026-03-04T22:40:27.557Z |
| Completed | 2026-03-04T22:45:40.660Z |
| Agent | coder |
| Worktree | /home/craig/Projects/hdwlinux/nix-config-worktrees/opencode-projects-plugin-hooks-0d2eb5-944.13 |

## Prompt

# Task: opencode-projects-plugin-hooks-0d2eb5-944.13

You are the PRIMARY agent for this task. Your role: coder

## Issue

Add onBuild callback to TypeSafeContainer for post-build wiring

The current `ContainerModule.register()` implementations resolve `Tokens.HookRegistry` (a pre-registered instance) and then register hook handlers that lazily call `container.resolve()` inside the handler closure. This works today but is fragile — it relies on the handler running after `build()` and captures the container reference rather than resolved dependencies.

The cleaner model is for modules to declare post-build work via a callback registered during the registration phase. After `container.build()` completes, all callbacks are invoked in registration order with the fully-built container.

**Proposed API:**
```typescript
container.onBuild((container) => {
  const hookRegistry = container.resolve(Tokens.HookRegistry)
  const projectManager = container.resolve(Tokens.ProjectManager)
  hookRegistry.register({ name: "...", handler: async (...) => { ... } })
})
```

**Changes required:**
- Add `onBuild(callback: (container: TypeSafeContainer) => void | Promise<void>)` to `TypeSafeContainer`
- `build()` invokes all registered callbacks after resolving all services
- Update `ContainerModule` interface: `register()` uses `container.onBuild()` for hook wiring instead of resolving inside handler closures
- Update all module implementations (`config`, `vcs`, `projects`, `execution`, `sessions`) to use `onBuild` for their hook registrations
- Update `src/index.ts` — the explicit `container.resolve(Tokens.HookRegistry)` after `build()` can be moved into an `onBuild` callback or kept as-is
- Add tests for `onBuild` in `container.test.ts`

**Acceptance criteria:**
- `TypeSafeContainer.onBuild()` exists and callbacks are called after `build()` in registration order
- All module hook registrations use `onBuild` — no `container.resolve()` calls inside handler closures
- `container.test.ts` covers: callbacks run after build, async callbacks, callback order, errors in callbacks propagate
- All existing tests continue to pass

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

You are working in an isolated worktree at: /home/craig/Projects/hdwlinux/nix-config-worktrees/opencode-projects-plugin-hooks-0d2eb5-944.13
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

All 1348 tests pass. Here's a summary of what was implemented:

## Summary

### `TypeSafeContainer` changes (`container.ts`)

- Added `buildCallbacks` array field to store registered callbacks
- Added `onBuild(callback)` method — registers a post-build callback, throws if called after `build()`
- Updated `build()` to invoke all registered callbacks in registration order after freezing the container

### Module updates

All five modules now use `container.onBuild()` for hook wiring instead of resolving services inside handler closures:

- **`config/module.ts`** — resolves `HookRegistry`, `ConfigManager`, `Logger`, `PluginDir` in `onBuild`; handler uses closed-over resolved values
- **`vcs/module.ts`** — resolves `HookRegistry`, `WorktreeManager` in `onBuild`; handler uses closed-over `worktreeManager`
- **`projects/module.ts`** — resolves `HookRegistry`, `ProjectManager` in `onBuild`; all three handlers use closed-over `projectManager`
- **`execution/module.ts`** — resolves all needed services in `onBuild`; `orchestratorSessionId` closure is now inside `onBuild` (still shared between the two event handlers as before)
- **`sessions/module.ts`** — resolves all needed services in `onBuild`; all four compaction handlers use closed-over resolved values

### Tests (`container.test.ts`)

Added 8 new tests covering:
- Callback receives the fully-built container
- Callbacks run in registration order
- Async callbacks are awaited
- Callbacks can resolve factory-based services
- Sync errors propagate from `build()`
- Async errors propagate from `build()`
- Throws when registering after `build()`
- Idempotent `build()` doesn't re-invoke callbacks

---

*Generated: 2026-03-04T22:45:40.660Z*