# Decision Log

## Pending Decisions

*No pending decisions*
---

## Decided

### Composable hook registry: separate units, multiple handlers per hook name
**Status:** Decided
**Date:** 2026-03-04
**Decision:** Hooks are individual units (not methods on a registry class). The HookRegistry composes multiple handlers registered for the same hook name, calling them sequentially in priority order. Hooks live in the module that owns them, not in a central hooks/ directory. src/index.ts becomes a thin bootstrap.
**Link:** [Full record](./2026-03-04-composable-hook-registry-separate-units-multiple-h.md)

### TypeSafeContainer: hand-rolled two-phase DI container
**Status:** Decided
**Date:** 2026-03-04
**Decision:** Implement a hand-rolled ~200-line TypeSafeContainer with two-phase initialization (register + build), typed token-based registration, variadic tuple type inference for factory signatures, cycle detection at build time, and immutable state after build.
**Link:** [Full record](./2026-03-04-typesafecontainer-hand-rolled-two-phase-di-contain.md)

---

## Superseded

*(None yet)*
