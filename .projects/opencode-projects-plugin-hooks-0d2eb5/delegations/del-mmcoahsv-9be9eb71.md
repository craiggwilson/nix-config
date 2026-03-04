# Refactor IssueStorage Token

> Moved IssueStorageToken to the issues module level, typed against the abstract interface. Removed the concrete BeadsIssueStorage token and updated all imports accordingly.

## Metadata

| Field | Value |
|-------|-------|
| ID | del-mmcoahsv-9be9eb71 |
| Project | opencode-projects-plugin-hooks-0d2eb5 |
| Issue | opencode-projects-plugin-hooks-0d2eb5-944.14 |
| Status | completed |
| Started | 2026-03-04T23:33:36.031Z |
| Completed | 2026-03-04T23:35:51.042Z |
| Agent | coder |
| Worktree | /home/craig/Projects/hdwlinux/nix-config-worktrees/opencode-projects-plugin-hooks-0d2eb5-944.14 |

## Prompt

# Task: opencode-projects-plugin-hooks-0d2eb5-944.14

You are the PRIMARY agent for this task. Your role: coder

## Issue

Move IssueStorageToken to issues module; beads registers to that token

Currently `IssueStorageToken` lives in `src/issues/beads/token.ts` and is typed as `Token<BeadsIssueStorage>`. It should be typed as `Token<IssueStorage>` and live in `src/issues/token.ts`, exported from `src/issues/index.ts`. The beads sub-module registers `BeadsIssueStorage` against that token — the token itself has no knowledge of the concrete implementation.

**Changes required:**
- Create `src/issues/token.ts` exporting `IssueStorageToken: Token<IssueStorage>`
- Export `IssueStorageToken` from `src/issues/index.ts`
- Delete `src/issues/beads/token.ts`
- Update `src/issues/beads/index.ts` to remove the token re-export
- Update `src/index.ts` to import `IssueStorageToken` from `../issues/index.js`
- Update `src/projects/module.ts` to import `IssueStorageToken` from `../issues/index.js`
- Anywhere else that imports `IssueStorageToken` from `beads/token.ts` — update to `issues/index.js`
- The beads `ContainerModule` (or the registration in `src/index.ts`) registers `BeadsIssueStorage` against `IssueStorageToken` — no type change needed there since `BeadsIssueStorage implements IssueStorage`

**Acceptance criteria:**
- `IssueStorageToken` is `Token<IssueStorage>` exported from `src/issues/index.ts`
- No file outside `src/issues/beads/` references `src/issues/beads/token.ts`
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

You are working in an isolated worktree at: /home/craig/Projects/hdwlinux/nix-config-worktrees/opencode-projects-plugin-hooks-0d2eb5-944.14
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

All changes are complete. Here's a summary of what was done:

**Changes made:**

1. **Created `src/issues/token.ts`** — exports `IssueStorageToken: Token<IssueStorage>`, typed against the abstract interface rather than the concrete implementation.

2. **Updated `src/issues/index.ts`** — added `export { IssueStorageToken } from "./token.js"` so the token is accessible from the issues module barrel.

3. **Deleted `src/issues/beads/token.ts`** — the old file that had `Token<BeadsIssueStorage>`.

4. **Updated `src/issues/beads/index.ts`** — removed the `export { IssueStorageToken } from "./token.js"` line since the token no longer lives in the beads sub-module.

5. **Updated `src/index.ts`** — changed import from `./issues/beads/index.js` to `./issues/index.js`.

6. **Updated `src/projects/module.ts`** — changed import from `../issues/beads/token.js` to `../issues/token.js` (direct sibling import, consistent with how other modules import their tokens).

The `BeadsIssueStorage` registration in `src/index.ts` still works correctly because `BeadsIssueStorage implements IssueStorage`, so it satisfies the `Token<IssueStorage>` type constraint.

---

*Generated: 2026-03-04T23:35:51.042Z*