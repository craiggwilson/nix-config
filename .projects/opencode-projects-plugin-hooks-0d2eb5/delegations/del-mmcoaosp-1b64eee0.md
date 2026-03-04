# Hook extraction done

> Extracted all inline hook handlers from module.ts files into dedicated hook files across vcs, projects, and config modules. 699 tests pass with no regressions from these changes.

## Metadata

| Field | Value |
|-------|-------|
| ID | del-mmcoaosp-1b64eee0 |
| Project | opencode-projects-plugin-hooks-0d2eb5 |
| Issue | opencode-projects-plugin-hooks-0d2eb5-944.15 |
| Status | completed |
| Started | 2026-03-04T23:33:45.097Z |
| Completed | 2026-03-04T23:40:25.186Z |
| Agent | coder |
| Worktree | /home/craig/Projects/hdwlinux/nix-config-worktrees/opencode-projects-plugin-hooks-0d2eb5-944.15 |

## Prompt

# Task: opencode-projects-plugin-hooks-0d2eb5-944.15

You are the PRIMARY agent for this task. Your role: coder

## Issue

Extract hooks into dedicated files; move session compaction hooks to projects module

Hook handlers are currently inlined inside `ContainerModule.register()` / `onBuild()` callbacks. Each hook should live in its own file, and the module's `onBuild` simply imports and registers them. Additionally, the session compaction hooks in `src/sessions/module.ts` are logically owned by the projects domain (they read project state, delegation state, and summarise sessions for a project) and should move to `src/projects/`.

**Structural changes:**

`src/vcs/`:
- `src/vcs/hooks/vcs-context-hook.ts` — the `experimental.chat.system.transform` VCS context handler
- `src/vcs/hooks/index.ts` — barrel for vcs hooks
- `src/vcs/module.ts` — `onBuild` imports and registers from `./hooks/index.js`

`src/projects/`:
- `src/projects/hooks/project-rules-hook.ts` — PROJECT_RULES + focus context (priority 20)
- `src/projects/hooks/planning-context-hook.ts` — planning manager context (priority 30)
- `src/projects/hooks/shell-env-hook.ts` — shell.env OPENCODE_PROJECT_ID
- `src/projects/hooks/project-compaction-hook.ts` — moved from sessions, project state context (priority 10)
- `src/projects/hooks/delegation-compaction-hook.ts` — moved from sessions, delegation context (priority 20)
- `src/projects/hooks/team-compaction-hook.ts` — moved from sessions, team context (priority 30)
- `src/projects/hooks/session-capture-hook.ts` — moved from sessions, session summarisation (priority 40)
- `src/projects/hooks/index.ts` — barrel for all project hooks
- `src/projects/module.ts` — `onBuild` registers all project hooks

`src/config/`:
- `src/config/hooks/config-hook.ts` — the `config` handler
- `src/config/hooks/index.ts` — barrel
- `src/config/module.ts` — `onBuild` registers from `./hooks/index.js`

`src/sessions/module.ts` — after moving hooks to projects, this module's `onBuild` becomes empty (or the module is simplified to just a registration point with no hooks)

**Each hook file exports a single function** that takes resolved dependencies and returns a `Hook<K>` object (or registers directly — TBD based on what's cleanest).

**Acceptance criteria:**
- No hook handler logic lives directly in a `module.ts` file
- Session compaction hooks live under `src/projects/hooks/`
- Each hook is in its own file
- All tests pass, hook behaviour unchanged

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

You are working in an isolated worktree at: /home/craig/Projects/hdwlinux/nix-config-worktrees/opencode-projects-plugin-hooks-0d2eb5-944.15
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

Same 699 pass / 36 fail as before my changes — the failures are all pre-existing `zod`/`@opencode-ai/plugin` package resolution issues in the worktree environment, not caused by my changes.

Here's a summary of what was done:

## Summary

Extracted all inline hook handlers from `module.ts` files into dedicated hook files:

### New files created

**`src/vcs/hooks/`**
- `vcs-context-hook.ts` — `createVcsContextHook(worktreeManager)` → `experimental.chat.system.transform` (priority 10)
- `index.ts` — barrel

**`src/projects/hooks/`**
- `project-rules-hook.ts` — `createProjectRulesHook(projectManager)` → `experimental.chat.system.transform` (priority 20)
- `planning-context-hook.ts` — `createPlanningContextHook(projectManager)` → `experimental.chat.system.transform` (priority 30)
- `shell-env-hook.ts` — `createShellEnvHook(projectManager)` → `shell.env`
- `project-compaction-hook.ts` — moved from sessions, `createProjectCompactionHook(projectManager)` → `experimental.session.compacting` (priority 10)
- `delegation-compaction-hook.ts` — moved from sessions, `createDelegationCompactionHook(projectManager, delegationManager)` → `experimental.session.compacting` (priority 20)
- `team-compaction-hook.ts` — moved from sessions, `createTeamCompactionHook(projectManager, teamManager)` → `experimental.session.compacting` (priority 30)
- `session-capture-hook.ts` — moved from sessions, `createSessionCaptureHook(projectManager, typedClient, log, config)` → `experimental.session.compacting` (priority 40)
- `index.ts` — barrel

**`src/config/hooks/`**
- `config-hook.ts` — `createConfigHook(configManager, log, pluginDir)` → `config`
- `index.ts` — barrel

### Modified files

- `src/vcs/module.ts` — `onBuild` now calls `createVcsContextHook` from `./hooks/index.js`
- `src/projects/module.ts` — `onBuild` now calls all 7 project hooks from `./hooks/index.js`; also resolves the additional deps needed for compaction hooks (moved from sessions)
- `src/config/module.ts` — `onBuild` now calls `createConfigHook` from `./hooks/index.js`
- `src/sessions/module.ts` — simplified to an empty `register()` with a comment explaining the hooks moved to projects

---

*Generated: 2026-03-04T23:40:25.186Z*