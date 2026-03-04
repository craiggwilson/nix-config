# Hook refactor complete

> Split multi-concern hook handlers into single-responsibility hooks across 4 modules. All 1091 tests pass with preserved behavior and output order.

## Metadata

| Field | Value |
|-------|-------|
| ID | del-mmclfwuf-bae1a446 |
| Project | opencode-projects-plugin-hooks-0d2eb5 |
| Issue | opencode-projects-plugin-hooks-0d2eb5-944.11 |
| Status | completed |
| Started | 2026-03-04T22:13:49.959Z |
| Completed | 2026-03-04T22:18:14.096Z |
| Agent | coder |
| Worktree | /home/craig/Projects/hdwlinux/nix-config-worktrees/opencode-projects-plugin-hooks-0d2eb5-944.11 |

## Prompt

# Task: opencode-projects-plugin-hooks-0d2eb5-944.11

You are the PRIMARY agent for this task. Your role: coder

## Issue

Split monolithic hook handlers into single-responsibility hooks

The current `experimental.chat.system.transform` handler in `src/projects/hooks.ts` does three distinct things in one function. Each concern should become its own named hook registered separately so they can be prioritised, tested, and reasoned about independently. Apply the same decomposition to any other hook handlers that bundle multiple concerns.

**Specific splits required for `experimental.chat.system.transform`:**
- **VCS context hook** — appends the VCS context block (owned by the vcs/worktree module)
- **Project context hook** — appends the focused-project context block (owned by the projects module)
- **Planning context hook** — appends the planning manager context block (owned by the projects module)

**Review all other hook handlers** (session, execution, config) and split any that handle more than one concern.

**Acceptance criteria:**
- `experimental.chat.system.transform` is registered as (at least) three separate `Hook` objects
- Each hook has a clear, single responsibility
- Priorities are set so the combined output order is preserved
- All other multi-concern handlers are similarly decomposed
- No functional change to the injected system prompt content

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

You are working in an isolated worktree at: /home/craig/Projects/hdwlinux/nix-config-worktrees/opencode-projects-plugin-hooks-0d2eb5-944.11
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

All 1091 tests pass. Here's a summary of what was done:

## Summary

Split all multi-concern hook handlers into single-responsibility hooks across 4 files:

### `src/vcs/module.ts` (new hook added)
- **VCS context hook** (priority 10): Appends VCS context to system prompts. Moved here from `projects/module.ts` since the `WorktreeManager` is owned by the VCS module.

### `src/projects/module.ts` (1 hook → 2 hooks)
- **Project context hook** (priority 20): Appends `PROJECT_RULES` + focused-project context block
- **Planning context hook** (priority 30): Appends planning manager context block

### `src/sessions/module.ts` (1 hook → 4 hooks)
- **Project compaction hook** (priority 10): Appends project state context
- **Delegation compaction hook** (priority 20): Appends delegation context (running + completed)
- **Team compaction hook** (priority 30): Appends team context
- **Session capture hook** (priority 40): Summarizes and captures the session

### `src/execution/module.ts` (1 hook → 2 hooks)
- **Session tracking hook** (priority 10): Identifies and records the orchestrator session ID on `session.created`
- **Session idle hook** (priority 20): Handles delegation completion and orchestrator snapshot writing on `session.idle`

The `orchestratorSessionId` closure variable is shared between both event hooks (they're registered in the same `register()` call scope), preserving the original behavior. The combined output order for all hooks is preserved by the priority assignments.

---

*Generated: 2026-03-04T22:18:14.096Z*