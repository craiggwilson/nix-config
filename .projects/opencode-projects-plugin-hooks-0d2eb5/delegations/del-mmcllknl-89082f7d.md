# Hook split review

> Code review of splitting monolithic hook handlers into single-responsibility hooks. All acceptance criteria met with no blockers identified.

## Metadata

| Field | Value |
|-------|-------|
| ID | del-mmcllknl-89082f7d |
| Project | opencode-projects-plugin-hooks-0d2eb5 |
| Issue | opencode-projects-plugin-hooks-0d2eb5-944.11 |
| Status | completed |
| Started | 2026-03-04T22:18:14.097Z |
| Completed | 2026-03-04T22:21:34.591Z |
| Agent | code-reviewer |
| Worktree | /home/craig/Projects/hdwlinux/nix-config-worktrees/opencode-projects-plugin-hooks-0d2eb5-944.11 |

## Prompt

# Review Task: opencode-projects-plugin-hooks-0d2eb5-944.11

You are a REVIEWER for this task. Your role: code-reviewer

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

The code is in an isolated worktree at: /home/craig/Projects/hdwlinux/nix-config-worktrees/opencode-projects-plugin-hooks-0d2eb5-944.11
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

I notice something: the priority 20 hook pushes both `PROJECT_RULES` and the focus context. According to the issue requirements, these should potentially be separate concerns. However, looking at the original code and the issue description more carefully:

The issue says:
- **VCS context hook** — appends the VCS context block (owned by the vcs/worktree module) ✅
- **Project context hook** — appends the focused-project context block (owned by the projects module) ✅
- **Planning context hook** — appends the planning manager context block (owned by the projects module) ✅

The `PROJECT_RULES` is a static constant that's part of the project context, so bundling it with the focus context in the same hook is reasonable. The issue doesn't explicitly require separating `PROJECT_RULES` from the focus context.

Now let me write my review:

---

## Code Review: Issue 944.11 - Split monolithic hook handlers into single-responsibility hooks

### Overall Assessment

The implementation successfully splits the monolithic `experimental.chat.system.transform` handler into three separate hooks with clear ownership and priorities. The session compacting and event hooks have also been decomposed appropriately. The code is well-structured and follows the established patterns.

---

#### Blockers (if any)

**None identified.**

The implementation meets all acceptance criteria:
1. ✅ `experimental.chat.system.transform` is registered as 3 separate `Hook` objects (vcs/module.ts:24, projects/module.ts:37, projects/module.ts:50)
2. ✅ Each hook has a clear, single responsibility (VCS context, project context, planning context)
3. ✅ Priorities are set correctly (10, 20, 30) to preserve output order
4. ✅ Other multi-concern handlers are similarly decomposed:
   - `experimental.session.compacting`: 4 handlers (priorities 10, 20, 30, 40)
   - `event`: 2 handlers (priorities 10, 20)
5. ✅ No functional change to the injected system prompt content (same order, same content)

---

#### Concerns (non-blocking)

1. **Typecheck error exists (unrelated to this work)**: There's a typecheck error in `src/execution/fixed-round/fixed-round-discussion-strategy.test.ts` related to missing `setTimeout` and `clearTimeout` properties on the `Clock` type. This is unrelated to the hooks refactoring but should be addressed separately.

2. **`PROJECT_RULES` bundled with focus context**: The priority 20 hook in `projects/module.ts` pushes both `PROJECT_RULES` (a static constant) and the dynamic focus context. While this is acceptable since both are "project context" concerns, a purist interpretation might separate them. However, the issue description groups them together as "Project context hook — appends the focused-project context block", so this is fine.

3. **Lazy resolution in hook handlers**: The hook handlers call `container.resolve(Tokens.ProjectManager)` inside the handler function rather than capturing the resolved value at registration time. This is intentional (lazy resolution) and works correctly, but it means the container must remain accessible. This is the established pattern and is correct.

4. **No explicit tests for the split hooks**: The `registry.test.ts` tests the `HookRegistry` mechanics (priority ordering, error handling, etc.) but there are no integration tests verifying that the specific module hooks produce the expected output. This is acceptable for a refactoring task where behavior should be unchanged, but could be added as a follow-up.

---

#### Verdict

**APPROVE**

The implementation correctly addresses all acceptance criteria. The hooks are properly split by responsibility, priorities preserve the original output order, and the code follows established patterns. The typecheck error is unrelated to this work and should be tracked separately.

---

*Generated: 2026-03-04T22:21:34.591Z*