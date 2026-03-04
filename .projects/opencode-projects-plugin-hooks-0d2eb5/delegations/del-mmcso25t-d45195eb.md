# Fix null safety issues

> Replaced non-null assertions with proper null checks across 12 production files and test files. Refactored PermissionManager from static class to exported functions and cleaned up unused constructor p

## Metadata

| Field | Value |
|-------|-------|
| ID | del-mmcso25t-d45195eb |
| Project | opencode-projects-plugin-hooks-0d2eb5 |
| Issue | opencode-projects-plugin-hooks-0d2eb5-944.18 |
| Status | completed |
| Started | 2026-03-05T01:36:07.409Z |
| Completed | 2026-03-05T01:48:06.419Z |
| Agent | coder |
| Worktree | /home/craig/Projects/hdwlinux/nix-config-worktrees/opencode-projects-plugin-hooks-0d2eb5-944.18 |

## Prompt

# Task: opencode-projects-plugin-hooks-0d2eb5-944.18

You are the PRIMARY agent for this task. Your role: coder

## Issue

Address noNonNullAssertion and noStaticOnlyClass Biome warnings

There are 31 warnings from Biome's recommended ruleset that should be resolved:

**`noNonNullAssertion`** — non-null assertions (`!`) in production code indicate places where the type system isn't being used to its full potential. Each instance should be replaced with proper null checks, optional chaining, or type narrowing. Test file instances may be suppressed with `biome-ignore` if truly necessary.

**`noStaticOnlyClass`** — classes with only static members should be refactored to plain exported functions/constants (see issue for PermissionManager specifically).

**Acceptance criteria:**
- `bun run lint` reports zero warnings (or all remaining warnings are explicitly `biome-ignore`d with a justification comment)
- No `!` non-null assertions in production code unless genuinely unavoidable
- All tests pass

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

You are working in an isolated worktree at: /home/craig/Projects/hdwlinux/nix-config-worktrees/opencode-projects-plugin-hooks-0d2eb5-944.18
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

All done. Here's a summary of what was fixed:

## Summary of Changes

### Production code fixes

1. **`container/container.ts`** — Replaced `this.descriptors.get(token)!` with a proper null check that throws a descriptive error if the token isn't registered.

2. **`delegation/delegation-manager.ts`** — Removed redundant `!` from `this.client!?.` (already guarded by `if (!this.client) return`). Updated import to use `resolvePermissions` directly.

3. **`discussions/fixed-round/fixed-round-discussion-strategy.ts`** — Added `if (!member.sessionId) throw new Error(...)` guard before using `member.sessionId`.

4. **`discussions/dynamic-round/dynamic-round-discussion-strategy.ts`** — Same guard pattern for `member.sessionId`.

5. **`discussions/realtime/realtime-discussion-strategy.ts`** — Same guard pattern in both `promptAgentForDiscussion` and `promptAgentToContinue`.

6. **`planning/planning-manager.ts`** — Added null check for `updatedState` after `getState()` call.

7. **`teams/permission-manager.ts`** — Refactored from static-only class to plain exported functions (`resolvePermissions`, `getAlwaysDisabledTools`, `getWriteTools`, `hasWriteAccess`, `isReadOnly`).

8. **`teams/index.ts`** — Updated exports to reflect the new function-based API.

9. **`projects/project-manager.ts`** — Removed unused constructor params (`client`, `$`, `teamManager`) and the dead `setTeamManager` method. Removed unused imports.

10. **`projects/module.ts`** — Updated `ProjectManager` registration to match the new constructor signature.

11. **`teams/team-manager.ts`** — Removed unused `private client` field (the constructor param is still used to pass to `TeamComposer` and `TeamNotifier`).

12. **`utils/prompts/xml-wrapper.ts`** — Replaced `content!` with `content ?? ""` (the overload guarantees content is provided, but this is safer).

### Test file fixes

All test files were updated with proper null checks instead of `!` assertions, using the pattern of early returns or `throw new Error(...)` to make the intent explicit.

---

*Generated: 2026-03-05T01:48:06.419Z*