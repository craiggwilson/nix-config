# Review: Import & Lint Issues

> Delegation identified TypeScript compilation failures due to wrong import paths and incomplete ESLint patterns missing multi-level parent imports.

## Metadata

| Field | Value |
|-------|-------|
| ID | del-mmcpmdmp-c9bc70de |
| Project | opencode-projects-plugin-hooks-0d2eb5 |
| Issue | opencode-projects-plugin-hooks-0d2eb5-944.17 |
| Status | completed |
| Started | 2026-03-05T00:10:50.113Z |
| Completed | 2026-03-05T00:13:26.231Z |
| Agent | code-reviewer |
| Worktree | /home/craig/Projects/hdwlinux/nix-config-worktrees/opencode-projects-plugin-hooks-0d2eb5-944.17 |

## Prompt

# Review Task: opencode-projects-plugin-hooks-0d2eb5-944.17

You are a REVIEWER for this task. Your role: code-reviewer

## Issue

Enforce barrel-only import/export rule across the codebase

Establish and enforce import/export rules and code quality rules using Biome as the linter.

## Rules to enforce

### Structural rules (the barrel-only import rule)

**Rule 1 — No cross-module imports from internal files.**
Every import that crosses a module boundary must go through the target module's `index.ts` barrel. Importing `../some-module/some-file.js` directly is forbidden; use `../some-module/index.js`.

**Rule 2 — No cross-module exports from internal files.**
A module's public API is exactly what its `index.ts` exports.

**Exception:** Within a module, files may import siblings directly (`./token.js`, `./manager.js`). The rule only applies at module boundaries (`../`-prefixed paths into another module directory).

Enforce with Biome `noRestrictedImports` using the `patterns` option:
```json
"patterns": [{ "group": ["../*/*"], "message": "Cross-module imports must go through the module's index.ts barrel." }]
```
The pattern `../*/*` matches `../module/file.js` but NOT `../module/index.js` — verify this is correct before shipping.

### Code quality rules

Enable all of the following in `biome.json`:

- **`noConsole`** — real `console.warn` violations exist in `config-manager.ts`; all logging must go through the injected `Logger`
- **`useImportType`** — enforce `import type` for type-only imports (auto-fixable)
- **`noUnusedImports`** — catch dead imports (auto-fixable)
- **`noUnusedVariables`** — catch dead variables
- **`noExplicitAny`** — ban `: any` type annotations
- **`useThrowOnlyError`** — only `Error` instances (or subclasses) may be thrown
- **`noParameterAssign`** — prevent reassigning function parameters

## Implementation steps

1. `bun add -d @biomejs/biome` — install Biome
2. Create `biome.json` with all rules above set to `"error"`
3. Add scripts to `package.json`:
   - `"lint": "biome lint src/"`
   - `"lint:fix": "biome lint --write src/"`
4. Run `bun run lint:fix` to auto-fix `useImportType` and `noUnusedImports`
5. Manually fix remaining violations (`noConsole`, `noExplicitAny`, etc.)
6. Update `AGENTS.md` to document: the barrel-only import rule, that `bun run lint` enforces it, and the other active rules

## Acceptance criteria

- `bun run lint` passes with zero errors
- `bun run lint:fix` is available for auto-fixable issues
- Pattern correctly flags `../module/internal-file.js`, allows `../module/index.js` and `./sibling.js`
- All existing tests continue to pass
- AGENTS.md documents the rules and how to run the linter

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

The code is in an isolated worktree at: /home/craig/Projects/hdwlinux/nix-config-worktrees/opencode-projects-plugin-hooks-0d2eb5-944.17
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

The correct import should be from `../../delegation/index.js`, not `../../execution/index.js`. This is a bug in the implementation.

Let me summarize my findings:

---

## Review Summary

#### Blockers

1. **TypeScript compilation fails** - The code has 9 TypeScript errors and doesn't compile:
   - `src/projects/hooks/delegation-compaction-hook.ts:3` imports from non-existent module `../../execution/index.js` - should be `../../delegation/index.js`
   - `src/projects/hooks/team-compaction-hook.ts:3` has the same issue
   - Multiple other type errors in `delegation-manager.ts`, `team-manager.ts`, `project-manager.ts`, etc.
   
   The acceptance criteria states "All existing tests continue to pass" but the code doesn't even compile.

2. **Pattern doesn't catch multi-level parent imports** - The `noRestrictedImports` pattern `../*/*` only catches single-level parent directory imports (`../module/file.js`), but NOT multi-level imports (`../../module/file.js`). There are **15 violations** at the `../../` level that are not being caught:
   - `src/delegation/hooks/index.ts` imports `../../container/container.js`, `../../container/tokens.js`, `../../hooks/token.js`, `../../projects/token.js`
   - `src/discussions/*/` files import `../../teams/team-manager.js`, `../../teams/permission-manager.js`
   
   The pattern needs to be extended to something like:
   ```json
   "patterns": [
     { "group": ["../*/*", "!../*/index.js"], "message": "..." },
     { "group": ["../../*/*", "!../../*/index.js"], "message": "..." },
     { "group": ["../../../*/*", "!../../../*/index.js"], "message": "..." }
   ]
   ```
   Or use a more comprehensive glob pattern.

#### Concerns (non-blocking)

1. **22 warnings for `noNonNullAssertion` and `noStaticOnlyClass`** - These are warnings (exit code 0), not errors, so they don't violate the "zero errors" acceptance criteria. However, the issue description didn't mention these rules, so it's unclear if they should be addressed. The `noNonNullAssertion` warnings are mostly in test files and could be suppressed with an override similar to `noExplicitAny`.

2. **Test file overrides** - The biome.json correctly disables `noExplicitAny` and `noConsole` for test files, which is reasonable. However, the `noNonNullAssertion` warnings in test files might also warrant an override.

#### Verdict

**REQUEST CHANGES**

The implementation has two critical blockers:
1. The code doesn't compile due to imports from a non-existent `execution` module
2. The barrel-only import pattern is incomplete and misses multi-level parent directory imports (`../../`, `../../../`, etc.)

---

*Generated: 2026-03-05T00:13:26.231Z*