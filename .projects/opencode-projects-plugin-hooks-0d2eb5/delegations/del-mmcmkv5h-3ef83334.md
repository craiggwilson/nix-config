# onBuild callback review

> Code review completed for TypeSafeContainer.onBuild() implementation. All 9 acceptance criteria verified as passing with 1348 tests passing. No blocking issues found.

## Metadata

| Field | Value |
|-------|-------|
| ID | del-mmcmkv5h-3ef83334 |
| Project | opencode-projects-plugin-hooks-0d2eb5 |
| Issue | opencode-projects-plugin-hooks-0d2eb5-944.13 |
| Status | completed |
| Started | 2026-03-04T22:45:40.661Z |
| Completed | 2026-03-04T22:48:04.047Z |
| Agent | code-reviewer |
| Worktree | /home/craig/Projects/hdwlinux/nix-config-worktrees/opencode-projects-plugin-hooks-0d2eb5-944.13 |

## Prompt

# Review Task: opencode-projects-plugin-hooks-0d2eb5-944.13

You are a REVIEWER for this task. Your role: code-reviewer

## Issue

Add onBuild callback to TypeSafeContainer for post-build wiring

The current `ContainerModule.register()` implementations resolve `Tokens.HookRegistry` (a pre-registered instance) and then register hook handlers that lazily call `container.resolve()` inside the handler closure. This works today but is fragile — it relies on the handler running after `build()` and captures the container reference rather than resolved dependencies.

The cleaner model is for modules to declare post-build work via a callback registered during the registration phase. After `container.build()` completes, all callbacks are invoked in registration order with the fully-built container.

**Proposed API:**
```typescript
container.onBuild((container) => {
  const hookRegistry = container.resolve(Tokens.HookRegistry)
  const projectManager = container.resolve(Tokens.ProjectManager)
  hookRegistry.register({ name: "...", handler: async (...) => { ... } })
})
```

**Changes required:**
- Add `onBuild(callback: (container: TypeSafeContainer) => void | Promise<void>)` to `TypeSafeContainer`
- `build()` invokes all registered callbacks after resolving all services
- Update `ContainerModule` interface: `register()` uses `container.onBuild()` for hook wiring instead of resolving inside handler closures
- Update all module implementations (`config`, `vcs`, `projects`, `execution`, `sessions`) to use `onBuild` for their hook registrations
- Update `src/index.ts` — the explicit `container.resolve(Tokens.HookRegistry)` after `build()` can be moved into an `onBuild` callback or kept as-is
- Add tests for `onBuild` in `container.test.ts`

**Acceptance criteria:**
- `TypeSafeContainer.onBuild()` exists and callbacks are called after `build()` in registration order
- All module hook registrations use `onBuild` — no `container.resolve()` calls inside handler closures
- `container.test.ts` covers: callbacks run after build, async callbacks, callback order, errors in callbacks propagate
- All existing tests continue to pass

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

The code is in an isolated worktree at: /home/craig/Projects/hdwlinux/nix-config-worktrees/opencode-projects-plugin-hooks-0d2eb5-944.13
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

Now I have a complete picture of the implementation. Let me provide my review:

---

## Code Review: Add onBuild callback to TypeSafeContainer

### Overall Assessment

The implementation is **well-executed** and meets all acceptance criteria from the issue. The code is clean, follows existing patterns, and has comprehensive test coverage.

### Acceptance Criteria Verification

| Criteria | Status |
|:---------|:------:|
| `TypeSafeContainer.onBuild()` exists | ✅ |
| Callbacks called after `build()` in registration order | ✅ (tested) |
| All module hook registrations use `onBuild` | ✅ |
| No `container.resolve()` calls inside handler closures | ✅ |
| Tests cover: callbacks run after build | ✅ |
| Tests cover: async callbacks | ✅ |
| Tests cover: callback order | ✅ |
| Tests cover: errors in callbacks propagate | ✅ |
| All existing tests continue to pass | ✅ (1348 tests pass) |

---

#### Blockers

None.

---

#### Concerns (non-blocking)

1. **suggestion:** The `onBuild` method sets `this.frozen = true` *before* invoking callbacks (line 147-151 in `container.ts`). This is intentional and correct — it allows callbacks to call `resolve()` on factory-based services. However, it also means that if a callback throws, the container remains frozen but in a potentially inconsistent state (some callbacks ran, some didn't). This is acceptable behavior for a DI container, but worth noting. The current approach is reasonable — failing fast is better than silently continuing.

2. **nit:** The pre-existing type error in `fixed-round-discussion-strategy.test.ts` (missing `setTimeout`/`clearTimeout` on `Clock` mock) is unrelated to this change but should be addressed separately.

3. **praise:** The test coverage for `onBuild` is excellent — it covers the happy path, async callbacks, registration order, error propagation (both sync and async), and the edge case of registering callbacks after build. The idempotency test (callbacks only run once even if `build()` is called multiple times) is a nice touch.

4. **praise:** The module implementations (`configModule`, `vcsModule`, `projectsModule`, `executionModule`, `sessionsModule`) all correctly use the `onBuild` pattern — they resolve dependencies at the top of the callback and then register hooks with those resolved values. This eliminates the fragile closure-capture pattern mentioned in the issue.

---

#### Verdict

**APPROVE**

The implementation is correct, well-tested, and meets all acceptance criteria. The approach is sound — `onBuild` callbacks provide a clean mechanism for post-build wiring without relying on lazy resolution inside handler closures.

---

*Generated: 2026-03-04T22:48:04.047Z*