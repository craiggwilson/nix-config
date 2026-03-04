# Decision: TypeSafeContainer: hand-rolled two-phase DI container

**Date:** 2026-03-04
**Status:** Decided
**Updated:** 2026-03-04T20:41:31.304Z

## Decision

Implement a hand-rolled ~200-line TypeSafeContainer with two-phase initialization (register + build), typed token-based registration, variadic tuple type inference for factory signatures, cycle detection at build time, and immutable state after build.

## Rationale

No existing TypeScript DI framework satisfies all constraints (no decorators, async support, minimal footprint, explicit wiring, good type inference). The hand-rolled container is ~200 lines, zero dependencies, and perfectly sized for ~10 services. awilix is the migration target if the plugin ever grows significantly.

## Alternatives Considered

### awilix

Mature DI framework with 373k weekly downloads

**Why rejected:** 327kB unpacked, more features than needed for ~10 services

### typed-inject

No-decorator, TypeScript-first DI

**Why rejected:** Async factory ergonomics are awkward — resolution is synchronous, requiring manual await at call sites

### brandi

Token-based, no decorators

**Why rejected:** Adds token boilerplate without meaningful benefit over hand-rolling at this scale

### iti

Async-first DI

**Why rejected:** All-async design cascades through the dependency graph, creating ergonomic friction for sync services

## Related Issues

- opencode-projects-plugin-hooks-0d2eb5-944.4
- opencode-projects-plugin-hooks-0d2eb5-944.3
- opencode-projects-plugin-hooks-0d2eb5-944.5
