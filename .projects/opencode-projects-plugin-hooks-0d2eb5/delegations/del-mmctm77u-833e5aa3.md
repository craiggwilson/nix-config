# Delegation: opencode-projects-plugin-hooks-0d2eb5-944.20

## Metadata

| Field | Value |
|-------|-------|
| ID | del-mmctm77u-833e5aa3 |
| Project | opencode-projects-plugin-hooks-0d2eb5 |
| Issue | opencode-projects-plugin-hooks-0d2eb5-944.20 |
| Status | timeout |
| Started | 2026-03-05T02:02:40.266Z |
| Completed | 2026-03-05T02:17:40.422Z |
| Agent | coder |

## Prompt

# Task: opencode-projects-plugin-hooks-0d2eb5-944.20

You are the PRIMARY agent for this task. Your role: coder

## Issue

Apply .18 changes to main: convert PermissionManager to functions, fix non-null assertions, simplify ProjectManager constructor

The .18 worktree changes need to be applied to the current main branch (which already has .19's structural changes). The .18 worktree is at: /home/craig/Projects/hdwlinux/nix-config-worktrees/opencode-projects-plugin-hooks-0d2eb5-944.18

Key changes to apply from .18 (adapting imports to current main's module structure where needed):

1. **`teams/permission-manager.ts`** — Convert `PermissionManager` static class to plain exported functions (`resolvePermissions`, `getAlwaysDisabledTools`, `getWriteTools`, `hasWriteAccess`, `isReadOnly`). Import `TeamMemberRole` from `../agents/index.js` (not `./team-manager.js` as in .18 — .19 moved it).

2. **All callers of `PermissionManager.resolvePermissions()`** — Update to call `resolvePermissions()` directly (imported from `../teams/index.js` or `../../teams/index.js`). Files: `delegation/delegation-manager.ts`, `discussions/fixed-round/fixed-round-discussion-strategy.ts`, `discussions/dynamic-round/dynamic-round-discussion-strategy.ts`, `discussions/realtime/realtime-discussion-strategy.ts`.

3. **`teams/index.ts`** — Export the new functions instead of the class.

4. **`container/container.ts`** — Already applied. Replace `this.descriptors.get(token)!` with a null check that throws.

5. **`delegation/delegation-manager.ts`** — Capture `this.client` into a local `const client` before async closures to allow TypeScript narrowing. Remove `this.client!?.` patterns.

6. **`discussions/fixed-round/fixed-round-discussion-strategy.ts`** — Add `if (!member.sessionId) throw new Error(...)` guard before using `member.sessionId`.

7. **`discussions/dynamic-round/dynamic-round-discussion-strategy.ts`** — Same guard pattern.

8. **`discussions/realtime/realtime-discussion-strategy.ts`** — Same guard pattern in both `promptAgentForDiscussion` and `promptAgentToContinue`.

9. **`planning/planning-manager.ts`** — Add null check for `updatedState` after `getState()` call.

10. **`projects/project-manager.ts`** — Remove unused constructor params (`client`, `$`, `teamManager`) and dead `setTeamManager` method.

11. **`projects/module.ts`** — Update `ProjectManager` registration to match new constructor signature.

12. **`teams/team-manager.ts`** — Remove unused `private client` field.

13. **`utils/prompts/xml-wrapper.ts`** — Replace `content!` with `content ?? ""`.

14. **Test files** — Update `ProjectManager` constructor calls in `tools/project-create.test.ts`, `project-focus.test.ts`, `project-list.test.ts`, `project-record-decision.test.ts`, `project-save-artifact.test.ts` to match new signature. Fix non-null assertions in test files with proper null checks.

After all changes: run `bun run lint`, `bun run format:fix`, `bun test` — all must pass with zero errors.

**Acceptance criteria:**
- `bun run lint` → zero errors, zero warnings
- `bun run format` → zero violations  
- `bun test` → 1348 pass, 0 fail
- No `PermissionManager` class anywhere — only plain functions
- No `!` non-null assertions in production code

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

Now run the tests:

[TIMEOUT REACHED - PARTIAL RESULT]

## Error

```
Timed out after 900s
```

---

*Generated: 2026-03-05T02:17:40.423Z*