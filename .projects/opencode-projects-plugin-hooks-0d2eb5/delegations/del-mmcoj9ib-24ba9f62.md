# Hook extraction approved

> All specified hooks extracted into dedicated files with correct priorities. Session compaction hooks moved to projects module. All 1348 tests pass, build succeeds.

## Metadata

| Field | Value |
|-------|-------|
| ID | del-mmcoj9ib-24ba9f62 |
| Project | opencode-projects-plugin-hooks-0d2eb5 |
| Issue | opencode-projects-plugin-hooks-0d2eb5-944.15 |
| Status | completed |
| Started | 2026-03-04T23:40:25.187Z |
| Completed | 2026-03-04T23:43:51.468Z |
| Agent | code-reviewer |
| Worktree | /home/craig/Projects/hdwlinux/nix-config-worktrees/opencode-projects-plugin-hooks-0d2eb5-944.15 |

## Prompt

# Review Task: opencode-projects-plugin-hooks-0d2eb5-944.15

You are a REVIEWER for this task. Your role: code-reviewer

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

The code is in an isolated worktree at: /home/craig/Projects/hdwlinux/nix-config-worktrees/opencode-projects-plugin-hooks-0d2eb5-944.15
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

All hooks are registered correctly. The implementation looks solid.

---

## Review Summary

#### Blockers (if any)

None identified.

#### Concerns (non-blocking)

1. **nit:** The `execution/module.ts` still has inline event hooks. While this is out of scope for this issue (the issue specifically lists vcs, projects, config, and sessions modules), it creates an inconsistency in the codebase. Consider a follow-up issue to extract these as well.

2. **suggestion:** The `config-hook.ts` handler parameter is typed as `Record<string, unknown>` rather than using the `Config` type from the SDK. This works but loses some type safety:

````typescript path=hdwlinux/packages/opencode-projects-plugin/src/config/hooks/config-hook.ts mode=EXCERPT
export function createConfigHook(configManager: ConfigManager, log: Logger, pluginDir: string): Hook<"config"> {
  return {
    name: "config",
    handler: async (opencodeConfig: Record<string, unknown>) => {
````

The `HookSignatures` interface defines `config.input` as `Config`, so the handler should receive that type. However, since the handler mutates the config object and the SDK's `Config` type may not have all the fields being added, this pragmatic approach is acceptable.

3. **praise:** Clean extraction pattern - each hook file exports a single factory function that takes dependencies and returns a `Hook<K>` object. This is consistent and testable.

4. **praise:** The session compaction hooks were correctly moved from `sessions/module.ts` to `projects/hooks/` as specified, with the rationale documented in the updated JSDoc comment.

5. **praise:** All 1348 tests pass, build succeeds, and the hook priorities match the issue requirements exactly.

#### Verdict

**APPROVE**

The implementation correctly extracts all hooks specified in the issue into dedicated files, moves session compaction hooks to the projects module, and maintains the same behavior with matching priorities. The code is well-structured, follows the established patterns, and all tests pass.

---

*Generated: 2026-03-04T23:43:51.468Z*