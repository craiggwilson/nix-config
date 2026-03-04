# Decision: Composable hook registry: separate units, multiple handlers per hook name

**Date:** 2026-03-04
**Status:** Decided
**Updated:** 2026-03-04T20:41:46.425Z

## Decision

Hooks are individual units (not methods on a registry class). The HookRegistry composes multiple handlers registered for the same hook name, calling them sequentially in priority order. Hooks live in the module that owns them, not in a central hooks/ directory. src/index.ts becomes a thin bootstrap.

## Rationale

Keeps hooks cohesive with the code that needs them. Enables multiple modules to contribute to the same hook without a central coordinator knowing about everything. Matches the user's stated design intent.

## Alternatives Considered

### HookRegistry class with inline implementations

Single class containing all hook implementations as methods

**Why rejected:** Rejected by user — creates a god class, hooks are not compartmentalized, adding a new hook requires touching the central class

## Related Issues

- opencode-projects-plugin-hooks-0d2eb5-944.2
