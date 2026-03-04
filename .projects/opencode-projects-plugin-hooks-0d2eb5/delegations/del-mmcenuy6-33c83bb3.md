# Hooks Research Review

> Reviewed hooks abstraction research, verifying 5 hooks against actual source code. Identified minor inconsistency in executive summary count (6 vs 5) and noted missing tool.execute.after hook.

## Metadata

| Field | Value |
|-------|-------|
| ID | del-mmcenuy6-33c83bb3 |
| Project | opencode-projects-plugin-hooks-0d2eb5 |
| Issue | opencode-projects-plugin-hooks-0d2eb5-944.1 |
| Status | completed |
| Started | 2026-03-04T19:04:03.438Z |
| Completed | 2026-03-04T19:05:13.976Z |
| Agent | architect |

## Prompt

# Review Task: opencode-projects-plugin-hooks-0d2eb5-944.1

You are a REVIEWER for this task. Your role: architect

## Issue

Research: hooks abstraction patterns and design options

Research how to best abstract hook registration in the opencode-projects-plugin. Currently all hooks (experimental.chat.system.transform, experimental.session.compacting, shell.env, event, config, tool.execute.after, etc.) are registered inline in src/index.ts, which will become unwieldy as more hooks are added.

Reference for inspiration: https://github.com/alvinunreal/oh-my-opencode-slim/tree/master/src/hooks — they use a `createXxxHook()` factory pattern where each hook lives in its own directory under src/hooks/ and returns an object with the hook handler(s) it implements.

Research should cover:
1. Inventory all current hooks in src/index.ts and what dependencies they need (projectManager, delegationManager, config, log, typedClient, etc.)
2. Analyze the oh-my-opencode-slim approach and its tradeoffs
3. Explore alternative designs (e.g., a HookRegistry class, a hooks/ module with composed handlers, decorator pattern, etc.)
4. Consider how the design handles hooks that need shared state/dependencies (most hooks need access to projectManager, etc.)
5. Consider how easy it is to add a new hook in each design
6. Produce a design recommendation with rationale and tradeoffs documented

The plugin source is at: hdwlinux/packages/opencode-projects-plugin/src/index.ts

## Primary Agent's Work

The primary agent (researcher) is implementing this. Your job is to:
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

Now I have a comprehensive view of the research. Let me verify one more thing - the line numbers claimed in the research against the actual source:

Looking at the actual `src/index.ts`:
- `experimental.chat.system.transform`: lines 151-170 ✓
- `experimental.session.compacting`: lines 172-271 ✓
- `shell.env`: lines 273-279 ✓
- `event`: lines 281-316 ✓
- `config`: lines 318-371 ✓

The research claims 6 hooks but I only count 5 in the table. Let me verify this is accurate.

Looking at the actual code, I see exactly 5 hooks:
1. `experimental.chat.system.transform` (line 151)
2. `experimental.session.compacting` (line 172)
3. `shell.env` (line 273)
4. `event` (line 281)
5. `config` (line 318)

The research document says "6 hooks" in the executive summary but the table only lists 5. This is a minor inconsistency.

Now let me provide my review:

---

## Review: Hooks Abstraction Research

### Blockers (if any)

**None identified.**

The research is thorough, accurate, and provides a well-reasoned recommendation. The hook inventory matches the actual source code (with one minor count discrepancy noted below), the dependency analysis is correct, and the design alternatives are fairly evaluated.

### Concerns (non-blocking)

1. **Minor inconsistency in hook count**: The executive summary states "6 hooks" but the inventory table lists only 5 hooks. The actual source code has 5 hooks. This is a typo that should be corrected but doesn't affect the recommendation.

2. **`tool.execute.after` hook mentioned in issue but not found**: The issue description mentions `tool.execute.after` as one of the hooks to inventory, but this hook doesn't exist in the current `src/index.ts`. The research correctly inventoried only the hooks that actually exist, but could have explicitly noted that `tool.execute.after` was not found.

3. **Implementation guide includes full code**: The implementation guide in `research/implementation-guide.md` includes a complete ~450-line HookRegistry implementation. While comprehensive, this is essentially writing the implementation rather than guiding it. This is fine for research purposes but the implementer should verify the code compiles and works rather than copy-pasting blindly.

4. **Type definitions in implementation guide are approximate**: The implementation guide uses `any` types in several places (e.g., `async (_input: unknown, output: any)`) and references types like `LoggerType` that may not match the actual codebase. The implementer will need to verify and correct these.

5. **Missing consideration of `import.meta.url` in HookRegistry**: The `config` hook uses `import.meta.url` to resolve the plugin directory. When moved to `HookRegistry`, this will resolve to the hooks directory instead of the plugin root. The implementation guide addresses this by using dynamic imports, but this is a subtle detail that could cause issues if not handled correctly.

6. **Scoring methodology not explained**: The scoring matrix assigns numeric scores (e.g., "Modularity: 9") but doesn't explain the criteria for each score. This makes it harder to validate the recommendation, though the qualitative analysis is sound.

### Verdict

**APPROVE**

The research comprehensively addresses all requirements from the issue:
1. ✅ Inventoried all current hooks with dependencies
2. ✅ Analyzed the oh-my-opencode-slim approach and tradeoffs
3. ✅ Explored alternative designs (HookRegistry, Modular Factories, Decorators, Composition)
4. ✅ Considered shared state/dependency handling
5. ✅ Evaluated ease of adding new hooks
6. ✅ Produced a design recommendation with rationale and tradeoffs

The HookRegistry recommendation is well-justified and aligns with existing codebase patterns (ProjectManager, DelegationManager). The implementation guide provides a clear path forward. The minor concerns noted above are easily addressable during implementation and don't block the research from being considered complete.

---

*Generated: 2026-03-04T19:05:13.976Z*