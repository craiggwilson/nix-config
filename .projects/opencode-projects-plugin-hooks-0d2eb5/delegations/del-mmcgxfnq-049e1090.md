# DI Framework Evaluation

> Evaluated 5 TypeScript DI frameworks against plugin constraints. Hand-rolled container recommended over existing frameworks due to minimal footprint (~50 lines, 0 deps) and perfect fit for ~10 service

## Metadata

| Field | Value |
|-------|-------|
| ID | del-mmcgxfnq-049e1090 |
| Project | opencode-projects-plugin-hooks-0d2eb5 |
| Issue | opencode-projects-plugin-hooks-0d2eb5-944.4 |
| Status | completed |
| Started | 2026-03-04T20:07:29.414Z |
| Completed | 2026-03-04T20:08:57.691Z |
| Agent | researcher |

## Prompt

# Task: opencode-projects-plugin-hooks-0d2eb5-944.4

You are the PRIMARY agent for this task. Your role: researcher

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

Excellent! Now let me create a final summary of the research findings:

## Summary

I have completed a comprehensive evaluation of existing TypeScript DI frameworks for the opencode-projects-plugin. Here are the key findings:

### Research Completed

**Document:** `/home/craig/Projects/hdwlinux/nix-config/.projects/opencode-projects-plugin-hooks-0d2eb5/research/di-framework-evaluation.md` (491 lines)

### Candidates Evaluated

1. **awilix** (v13.0.3) - 373k weekly downloads
   - ✅ Meets all constraints
   - ❌ Overkill for ~10 services (327 kB unpacked)
   - Verdict: Too complex for plugin's needs

2. **typed-inject** (v5.0.0) - 307k weekly downloads
   - ✅ Excellent type safety
   - ❌ **No async factory support** (critical blocker)
   - Verdict: Ruled out due to async limitation

3. **brandi** (v5.1.0) - 12k weekly downloads
   - ✅ Meets all constraints
   - ❌ Token boilerplate, smaller ecosystem
   - Verdict: Possible but hand-rolled is simpler

4. **iti** (v0.8.0) - 3k weekly downloads
   - ✅ Async-first design
   - ❌ Forces all resolutions to be async (awkward for sync services)
   - Verdict: Not ideal for mixed sync/async needs

5. **tsyringe** & **inversify** - Ruled out immediately
   - ❌ Require decorators + reflect-metadata (violates core constraint)

### Recommendation: Hand-Rolled Container

**Proceed with the hand-rolled design** documented in `composable-hook-registry-di.md` (Section 3).

#### Why Hand-Rolled Wins

| Criterion | Hand-Rolled | Best Framework |
|-----------|------------|-----------------|
| **Footprint** | ~50 lines, <1 kB | awilix: 327 kB |
| **Dependencies** | 0 | awilix: 1+ |
| **Async Support** | ✅ Native | ✅ (awilix) |
| **Type Safety** | ✅ Typed tokens | ✅ (typed-inject) |
| **Complexity** | Minimal | Medium-High |
| **Transparency** | Crystal clear | Requires learning |
| **Fit for ~10 services** | Perfect | Overkill |

#### Key Advantages

1. **Perfect fit** — Designed for exactly this plugin's needs
2. **Minimal footprint** — ~50 lines vs 100+ kB
3. **Zero dependencies** — No external packages to maintain
4. **Transparent** — Simple, debuggable code
5. **Type-safe** — Typed tokens provide compile-time safety
6. **Async-friendly** — Handles both sync and async factories naturally
7. **No decorators** — Meets core constraint

#### Migration Path (If Needed)

If the plugin grows to 100+ services, **awilix** is the recommended migration target:
- Most mature ecosystem (373k weekly downloads)
- Best documentation
- Actively maintained (released 1 day ago)
- Supports all advanced features
- Can be adopted incrementally

### Deliverable

Complete evaluation document with:
- ✅ Detailed analysis of each framework
- ✅ Comparison table with all criteria
- ✅ Risk assessment for hand-rolled vs frameworks
- ✅ Code examples for each framework
- ✅ Clear recommendation with rationale

The research confirms that **hand-rolling is the right choice** for this plugin's specific constraints and scale.

---

*Generated: 2026-03-04T20:08:57.691Z*