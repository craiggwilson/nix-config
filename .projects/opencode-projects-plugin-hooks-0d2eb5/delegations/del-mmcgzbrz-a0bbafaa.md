# DI Framework Review

> Reviewer assessed the DI framework evaluation, noting minor inaccuracies in typed-inject async claims, understated iti cascade concerns, and misleading bundle size comparisons. Verdicts remain correct

## Metadata

| Field | Value |
|-------|-------|
| ID | del-mmcgzbrz-a0bbafaa |
| Project | opencode-projects-plugin-hooks-0d2eb5 |
| Issue | opencode-projects-plugin-hooks-0d2eb5-944.4 |
| Status | completed |
| Started | 2026-03-04T20:08:57.695Z |
| Completed | 2026-03-04T20:09:47.026Z |
| Agent | technical-writer |

## Prompt

# Review Task: opencode-projects-plugin-hooks-0d2eb5-944.4

You are a REVIEWER for this task. Your role: technical-writer

## Issue

Research: existing minimal TypeScript DI frameworks

Before building a hand-rolled DI container, survey what already exists in the TypeScript ecosystem that might be a good fit. We want something minimal — not Spring-level magic — that we could pull in rather than maintain ourselves.

## Evaluation Criteria

The plugin has specific constraints that should drive the evaluation:

- **No decorators required** — we don't want to require `experimentalDecorators` or `reflect-metadata`
- **Async factory support** — some services need async initialization (e.g., VCS detection)
- **Minimal footprint** — this is a plugin, not an app; we don't want a heavy framework
- **Explicit wiring** — prefer explicit registration over auto-discovery/scanning
- **TypeScript-native** — good type inference, not just `any` everywhere
- **Actively maintained** — not abandoned
- **Bundle-friendly** — works with ESM, no CommonJS-only packages

## Candidates to Evaluate (at minimum)

- **awilix** — explicit registration, no decorators, cradle proxy pattern
- **tsyringe** — decorator-based (likely ruled out, but confirm)
- **inversify** — decorator-based (likely ruled out, but confirm)
- **typed-inject** — no decorators, purely functional, TypeScript-first
- **brandi** — no decorators, token-based, similar to what we'd hand-roll
- **iti** — async-first, no decorators, tree-shakeable
- Any others worth considering

## For Each Candidate, Assess

1. Does it require decorators / reflect-metadata?
2. Does it support async factories natively?
3. Does it support lazy resolution (defer wiring until build time)?
4. How does registration look? (code example)
5. How does resolution look? (code example)
6. Package size and dependencies
7. Last release date / maintenance status
8. TypeScript type safety quality

## Deliverable

A comparison table plus a recommendation: is any existing library a better fit than hand-rolling, and if so, which one and why? If hand-rolling is still the right call, explain why none of the existing options fit.

## Context

- Current hand-rolled design: `.projects/opencode-projects-plugin-hooks-0d2eb5/research/composable-hook-registry-di.md` (Section 3)
- The lazy resolution question is being explored in parallel (issue 944.3) — coordinate if relevant

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

I have enough context to write a thorough review. The primary agent produced a well-structured DI framework evaluation document. Let me assess it carefully.

---

#### Blockers (if any)

None.

---

#### Concerns (non-blocking)

**1. typed-inject async claim may be overstated as a blocker**

The document states typed-inject has "No native async support" and calls it a "critical blocker." However, typed-inject v5 does support async factories via `provideFactory` with async functions — the limitation is that resolution itself is synchronous (the container doesn't `await` the factory). The document's own workaround example actually shows async factories working; the awkwardness is in resolution ergonomics, not a hard capability gap. The verdict is still correct (not recommended), but the stated reason is slightly imprecise. A more accurate framing: "async factories are supported but resolution is synchronous, requiring callers to `await` the resolved promise manually, which is error-prone."

**2. iti's "all resolutions return promises" concern is understated**

The document notes this as a con but doesn't fully articulate the downstream impact: every service that depends on an async service must also be async, which can cascade through the entire graph. For a plugin with mixed sync/async services, this is a more significant ergonomic problem than the document conveys. The verdict is still correct, but the reasoning could be stronger.

**3. Bundle size comparison is slightly misleading**

The comparison pits "~50 lines of code (< 1 kB)" against unpacked npm sizes (327 kB, 183 kB, etc.). Unpacked size includes source maps, type declarations, README, and other non-runtime files. The actual minified+gzipped runtime sizes would be significantly smaller (awilix is ~8 kB gzipped). The hand-rolled approach is still the right call, but the size argument as presented overstates the gap. Consider noting minified/gzipped sizes or clarifying that "unpacked" includes non-runtime files.

**4. The hand-rolled async example has a subtle inconsistency**

In Section "5. Async Handling," the document shows:

```typescript
const config = await container.resolve(Tokens.Config)
const logger = container.resolve(Tokens.Logger)
```

But the container design in `composable-hook-registry-di.md` Section 3 shows `resolve<T>()` returning `T` (not `Promise<T>`). If async factories are registered, the container would need to return `Promise<T>` for those tokens, or the caller would receive an unresolved promise. This inconsistency between the two documents should be reconciled — either the container's `resolve` method is always synchronous (and async factories are resolved eagerly during registration), or it returns `Promise<T>` for async tokens. The lazy-resolution research (`lazy-resolution-di.md`) appears to address this, but the DI evaluation document doesn't acknowledge the tension.

**5. inversify dismissal is too brief**

The issue brief explicitly asked to "confirm" why inversify is ruled out. The document gives it one sentence. A brief note confirming the decorator requirement (same as tsyringe) with a version reference would be more complete, even if the conclusion is the same.

**6. No mention of `effect/Context` or `fp-ts`**

The issue brief says "any others worth considering." For a TypeScript-native, functional, no-decorator approach, `effect`'s `Context` module and `fp-ts`'s `Reader` monad are worth at least a sentence of acknowledgment — even if only to rule them out as too opinionated/heavy. This is a minor gap in coverage.

---

#### Verdict

**APPROVE**

The research is well-structured, covers all required candidates, applies the evaluation criteria consistently, and reaches a well-reasoned conclusion. The concerns above are documentation quality improvements, not correctness issues. The recommendation to hand-roll is sound and well-supported. The document is ready to inform implementation.

---

*Generated: 2026-03-04T20:09:47.026Z*