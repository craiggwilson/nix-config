# Hook Registration Review

> Code review completed for moving hook registration into ContainerModule. All 1340 tests pass. Two non-blocking concerns noted around outdated JSDoc and dependency resolution patterns.

## Metadata

| Field | Value |
|-------|-------|
| ID | del-mmcla17w-d5aeb6fc |
| Project | opencode-projects-plugin-hooks-0d2eb5 |
| Issue | opencode-projects-plugin-hooks-0d2eb5-944.10 |
| Status | completed |
| Started | 2026-03-04T22:09:15.692Z |
| Completed | 2026-03-04T22:11:49.178Z |
| Agent | code-reviewer |
| Worktree | /home/craig/Projects/hdwlinux/nix-config-worktrees/opencode-projects-plugin-hooks-0d2eb5-944.10 |

## Prompt

# Review Task: opencode-projects-plugin-hooks-0d2eb5-944.10

You are a REVIEWER for this task. Your role: code-reviewer

## Issue

Register hooks via ContainerModule — move hook registration into each module

Each domain module's `ContainerModule.register()` should also register its hooks into the `HookRegistry`. The `HookRegistry` token must be resolvable from the container at registration time (it is pre-registered as an instance before modules run). The standalone `registerXxxHooks()` functions in `src/*/hooks.ts` should be absorbed into the respective `ContainerModule` implementations and the explicit hook-registration calls in `src/index.ts` removed.

**Acceptance criteria:**
- Each `ContainerModule.register()` resolves `Tokens.HookRegistry` from the container and registers its hooks
- The top-level `registerProjectHooks`, `registerSessionHooks`, `registerExecutionHooks`, `registerConfigHooks` calls in `src/index.ts` are removed
- Hook behaviour is unchanged

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

The code is in an isolated worktree at: /home/craig/Projects/hdwlinux/nix-config-worktrees/opencode-projects-plugin-hooks-0d2eb5-944.10
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

I've completed my review. Let me provide my assessment.

---

## Code Review: Register hooks via ContainerModule

### Overall Assessment

The implementation correctly moves hook registration from standalone functions in `src/index.ts` into each domain module's `ContainerModule.register()` method. The acceptance criteria are met:

1. ✅ Each `ContainerModule.register()` resolves `Tokens.HookRegistry` from the container and registers its hooks
2. ✅ The top-level `registerProjectHooks`, `registerSessionHooks`, `registerExecutionHooks`, `registerConfigHooks` calls in `src/index.ts` are removed
3. ✅ Hook behaviour is unchanged (all 1340 tests pass)

---

#### Blockers (if any)

None.

---

#### Concerns (non-blocking)

1. **Outdated documentation in `ContainerModule` interface** (src/container/module.ts:15-17)
   
   The JSDoc comment states:
   > "Implementations must not call `container.resolve()` here — resolution happens only after `build()`."
   
   However, all module implementations now call `container.resolve(Tokens.HookRegistry)` during registration, which is explicitly supported by the container (see container.ts:70-92 which allows resolving instances registered via `registerInstance()` before `build()`).
   
   **Suggestion:** Update the documentation to reflect the actual behavior:
   ```typescript
   /**
    * Registers this module's services into the container.
    *
    * Called during the registration phase, before `container.build()`.
    * Implementations may call `container.resolve()` for instances registered
    * via `registerInstance()` (e.g., HookRegistry), but not for factory-based
    * services — those are only available after `build()`.
    */
   ```

2. **nit: Inconsistent hook handler dependency resolution pattern**
   
   The hook handlers resolve their dependencies from the container inside the handler function (e.g., `const projectManager = container.resolve(Tokens.ProjectManager)`). This is correct because handlers run after `build()`, but it creates a subtle coupling where the handler captures the container reference.
   
   This is fine for now, but if the codebase grows, consider whether a more explicit dependency injection pattern for hooks would be cleaner (e.g., passing resolved dependencies when registering the hook). Not a blocker — the current approach works and is consistent across all modules.

3. **Pre-existing TypeScript error** (unrelated to this change)
   
   There's a TypeScript error in `src/execution/fixed-round/fixed-round-discussion-strategy.test.ts` related to a missing `Clock` interface property. This exists on main and is not introduced by this change.

---

#### Verdict

**APPROVE**

The implementation correctly satisfies all acceptance criteria. The hook registration has been successfully moved into each module's `ContainerModule.register()` method, the standalone hook registration calls have been removed from `src/index.ts`, and all tests pass. The only concern is a documentation inconsistency that should be fixed but doesn't block the implementation.

---

*Generated: 2026-03-04T22:11:49.178Z*