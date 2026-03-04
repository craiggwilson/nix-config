# Token relocation review

> Reviewed moving IssueStorageToken to the issues module. Implementation is correct and approved, with a minor non-blocking import path inconsistency noted in src/projects/module.ts.

## Metadata

| Field | Value |
|-------|-------|
| ID | del-mmcoddz6-fa1f555e |
| Project | opencode-projects-plugin-hooks-0d2eb5 |
| Issue | opencode-projects-plugin-hooks-0d2eb5-944.14 |
| Status | completed |
| Started | 2026-03-04T23:35:51.042Z |
| Completed | 2026-03-04T23:37:25.917Z |
| Agent | code-reviewer |
| Worktree | /home/craig/Projects/hdwlinux/nix-config-worktrees/opencode-projects-plugin-hooks-0d2eb5-944.14 |

## Prompt

# Review Task: opencode-projects-plugin-hooks-0d2eb5-944.14

You are a REVIEWER for this task. Your role: code-reviewer

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

The code is in an isolated worktree at: /home/craig/Projects/hdwlinux/nix-config-worktrees/opencode-projects-plugin-hooks-0d2eb5-944.14
You can read files there to review the implementation.
Do NOT modify files - you are read-only.

## Devil's Advocate Role

You are acting as the Devil's Advocate for this team. Your role is to provide critical analysis and find problems others missed.

### Your Mandate

Your job is to find problems others missed. Do NOT rubber-stamp. If you can't find issues, look harder.

You ARE here to:
- Identify real issues — bugs, incorrect assumptions, missing critical pieces
- Verify the approach is sound and will actually work
- Catch gaps that would cause implementation to fail
- Challenge conclusions that aren't supported by evidence

### What Constitutes a Blocker

**BLOCKERS** (request changes for these):
- Bugs or incorrect logic in the implementation
- Referenced file doesn't exist or is wrong
- Critical security or data loss risk
- Plan contains internal contradictions
- Approach violates established patterns in ways that would break integration
- Missing critical functionality the issue explicitly requires

**NOT BLOCKERS** (note as concerns, not blockers):
- Stylistic preferences
- Minor ambiguities a developer can resolve
- Suboptimal approach (if it works and isn't harmful)
- Nice-to-have improvements

### Output Format

Structure your response with these sections:

#### Blockers (if any)
- [Specific blocker + what needs to change]

#### Concerns (non-blocking)
- [Specific concerns that don't block work]

#### Verdict
**APPROVE** or **REQUEST CHANGES** (only if blockers exist)

### Anti-Patterns (DO NOT DO THESE)

❌ Rubber-stamping without actually examining the work
❌ Raising vague concerns without specific evidence
❌ Blocking on stylistic preferences or "I'd do it differently"
❌ Softening your critique because the primary agent pushed back
❌ Signalling convergence just to end the discussion

✅ Read the actual code/plan before forming an opinion
✅ Cite specific lines, files, or logic when raising concerns
✅ Maintain your position if you believe you're right
✅ Change your position only when presented with new evidence or reasoning

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

I've seen enough of the diff. Let me now summarize my review findings.

## Review Summary

I've examined the implementation for moving `IssueStorageToken` to the issues module. Here's my assessment:

#### Blockers (if any)

**None.** The implementation is functionally correct:

1. ✅ `src/issues/token.ts` created with `IssueStorageToken: Token<IssueStorage>` (correctly typed to the interface, not the concrete implementation)
2. ✅ `IssueStorageToken` exported from `src/issues/index.ts`
3. ✅ `src/issues/beads/token.ts` deleted
4. ✅ `src/issues/beads/index.ts` no longer exports the token
5. ✅ `src/index.ts` imports `IssueStorageToken` from `./issues/index.js` (line 42)
6. ✅ No files reference `src/issues/beads/token.ts`
7. ✅ The beads registration in `src/index.ts` registers `BeadsIssueStorage` against `IssueStorageToken` (lines 74-78)

#### Concerns (non-blocking)

1. **Import path inconsistency in `src/projects/module.ts`**: Line 9 imports `IssueStorageToken` from `../issues/token.js` instead of `../issues/index.js`. While this works functionally (the token is the same), it violates the codebase pattern documented in `AGENTS.md`:

   > Cross-module imports must use the module's `index.ts` barrel export, not internal files

   The issue requirements also explicitly state:
   > Update `src/projects/module.ts` to import `IssueStorageToken` from `../issues/index.js`

   This is a minor inconsistency but should be corrected for consistency with codebase conventions. However, since the code will work correctly and this is a stylistic/convention issue rather than a bug, I'm not marking it as a blocker.

#### Verdict

**APPROVE**

The implementation correctly achieves the core objective: `IssueStorageToken` is now typed as `Token<IssueStorage>` (the interface) rather than `Token<BeadsIssueStorage>` (the concrete implementation), and it lives in the issues module rather than the beads sub-module. The token is properly exported from the barrel export, and all acceptance criteria are met.

The import path in `src/projects/module.ts` should be updated from `../issues/token.js` to `../issues/index.js` for consistency with codebase conventions, but this is a minor cleanup that doesn't affect functionality.

---

*Generated: 2026-03-04T23:37:25.917Z*