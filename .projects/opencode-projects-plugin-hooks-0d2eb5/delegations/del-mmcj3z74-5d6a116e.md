# Hooks migrated to modules

> Migrated all 5 hooks from src/index.ts into owning modules and wired up TypeSafeContainer. All 1339 tests pass with no new type errors.

## Metadata

| Field | Value |
|-------|-------|
| ID | del-mmcj3z74-5d6a116e |
| Project | opencode-projects-plugin-hooks-0d2eb5 |
| Issue | opencode-projects-plugin-hooks-0d2eb5-944.8 |
| Status | completed |
| Started | 2026-03-04T21:08:33.904Z |
| Completed | 2026-03-04T21:15:55.519Z |
| Agent | coder |
| Worktree | /home/craig/Projects/hdwlinux/nix-config-worktrees/opencode-projects-plugin-hooks-0d2eb5-944.8 |

## Prompt

# Task: opencode-projects-plugin-hooks-0d2eb5-944.8

You are the PRIMARY agent for this task. Your role: coder

## Issue

Migrate hooks to modules and wire up DI container in src/index.ts

Migrate all 5 existing hooks out of `src/index.ts` into their owning modules, wire up the TypeSafeContainer, and slim down `src/index.ts` to a thin bootstrap.

## Hook ownership

| Hook | Move to |
|------|---------|
| `experimental.chat.system.transform` | `src/projects/hooks.ts` |
| `shell.env` | `src/projects/hooks.ts` |
| `experimental.session.compacting` | `src/sessions/hooks.ts` |
| `event` | `src/execution/hooks.ts` |
| `config` | `src/config/hooks.ts` (or nearest equivalent) |

Each module's hooks file exports a `registerHooks(container: TypeSafeContainer, hookRegistry: HookRegistry): void` function that registers its hooks using dependencies resolved from the container.

## Container tokens

Define all tokens in `src/container/tokens.ts`:

```typescript
export const Tokens = {
  Config:            new Token<PluginConfig>("Config"),
  Log:               new Token<Logger>("Log"),
  TypedClient:       new Token<TypedClient>("TypedClient"),
  Shell:             new Token<Shell>("Shell"),
  ProjectManager:    new Token<ProjectManager>("ProjectManager"),
  DelegationManager: new Token<DelegationManager>("DelegationManager"),
  TeamManager:       new Token<TeamManager>("TeamManager"),
  WorktreeManager:   new Token<WorktreeManager>("WorktreeManager"),
  HookRegistry:      new Token<HookRegistry>("HookRegistry"),
  // add others as needed
}
```

## Target src/index.ts shape

```typescript
export default async function Plugin(app: App): Promise<PluginOutput> {
  const container = new TypeSafeContainer()

  // Pre-built instances
  container.registerInstance(Tokens.TypedClient, createTypedClient(app))
  container.registerInstance(Tokens.Log, app.log)
  container.registerInstance(Tokens.Shell, app.$)
  container.registerInstance(Tokens.HookRegistry, new HookRegistry(app.log))

  // Factories — order doesn't matter
  container.register(Tokens.Config, [], () => loadConfig())
  container.register(Tokens.WorktreeManager, [Tokens.Shell, Tokens.Log], (shell, log) => new WorktreeManager(shell, log))
  container.register(Tokens.ProjectManager, [Tokens.Config, Tokens.Log, ...], (cfg, log, ...) => new ProjectManager(...))
  // ... etc

  await container.build()

  // Register hooks from each module
  const hooks = container.resolve(Tokens.HookRegistry)
  registerProjectHooks(container, hooks)
  registerSessionHooks(container, hooks)
  registerExecutionHooks(container, hooks)
  registerConfigHooks(container, hooks)

  return {
    tool: { /* existing tools unchanged */ },
    ...hooks.buildHooks(),
  }
}
```

## Important notes

- Preserve all existing behaviour exactly — this is a refactor, not a feature change
- The `event` hook has mutable state (`orchestratorSessionId`) — encapsulate it as a module-level variable in `src/execution/hooks.ts`
- The `config` hook uses `import.meta.url` to resolve the plugin directory — pass `pluginDir` as a `registerInstance` value computed in `src/index.ts` before the container is built
- Run `bun run typecheck` and `bun test` before committing — both must pass

## Commit

This should be its own commit: `refactor(hooks): migrate hooks to modules, wire DI container`

## Reference

- Current implementation: `hdwlinux/packages/opencode-projects-plugin/src/index.ts`
- Research: `.projects/opencode-projects-plugin-hooks-0d2eb5/research/composable-hook-registry-di.md`
- Research: `.projects/opencode-projects-plugin-hooks-0d2eb5/research/type-safe-factory-implementation-guide.md`

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

You are working in an isolated worktree at: /home/craig/Projects/hdwlinux/nix-config-worktrees/opencode-projects-plugin-hooks-0d2eb5-944.8
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

The work is complete. Here's a summary of what was done:

## Summary

Migrated all 5 hooks from `src/index.ts` into their owning modules and wired up the `TypeSafeContainer`.

### Files created

1. **`src/container/token.ts`** — Token class for type-safe DI (copied from main branch)
2. **`src/container/container.ts`** — Two-phase DI container (copied from main branch)
3. **`src/container/index.ts`** — Container barrel export (copied from main branch)
4. **`src/container/container.test.ts`** — Container tests (copied from main branch)
5. **`src/container/tokens.ts`** — All canonical DI tokens (`Config`, `Log`, `TypedClient`, `Shell`, `ProjectManager`, `DelegationManager`, `TeamManager`, `WorktreeManager`, `HookRegistry`, `PluginDir`, `RepoRoot`)
6. **`src/hooks/registry.ts`** — HookRegistry implementation (copied from main branch)
7. **`src/hooks/index.ts`** — Hooks barrel export (copied from main branch)
8. **`src/hooks/registry.test.ts`** — HookRegistry tests (copied from main branch)
9. **`src/projects/hooks.ts`** — `registerProjectHooks()` for `experimental.chat.system.transform` and `shell.env`
10. **`src/sessions/hooks.ts`** — `registerSessionHooks()` for `experimental.session.compacting`
11. **`src/execution/hooks.ts`** — `registerExecutionHooks()` for `event` (with module-level `orchestratorSessionId` state)
12. **`src/config/hooks.ts`** — `registerConfigHooks()` for `config`

### Files modified

- **`src/index.ts`** — Slimmed to a thin bootstrap: builds the container, calls `registerXxxHooks()`, spreads `hookRegistry.buildHooks(log)` into the return value

### Quality gates
- `bun run typecheck`: only the pre-existing `fixed-round-discussion-strategy.test.ts` error (present in main branch too)
- `bun test`: **1339 pass, 0 fail**

---

*Generated: 2026-03-04T21:15:55.519Z*