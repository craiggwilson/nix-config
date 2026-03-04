# Hook Registry Research

> Researched composable hook system design with lightweight DI container. Recommends typed hook names, sequential mutation pipeline, and hand-rolled service locator pattern.

## Metadata

| Field | Value |
|-------|-------|
| ID | del-mmcg8muk-e78d9227 |
| Project | opencode-projects-plugin-hooks-0d2eb5 |
| Issue | opencode-projects-plugin-hooks-0d2eb5-944.2 |
| Status | completed |
| Started | 2026-03-04T19:48:12.332Z |
| Completed | 2026-03-04T19:51:54.044Z |
| Agent | architect |

## Prompt

# Task: opencode-projects-plugin-hooks-0d2eb5-944.2

You are the PRIMARY agent for this task. Your role: architect

## Issue

Research: composable hook registry with DI container

The initial research recommended a HookRegistry class that contains hook implementations inline. This direction is rejected. Instead, explore a design where:

## Core Principles

1. **Hooks are compartmentalized** — each hook is its own unit (file/class/function), not a method on a registry class
2. **Multiple handlers per hook name** — the registry composes multiple handlers for the same hook name (e.g., two modules both contributing to `experimental.chat.system.transform`), calling all of them in sequence
3. **Hooks live close to their consumers** — if the TeamManager needs a hook to do its job, the hook implementation lives in the execution/ module, not in a central hooks/ directory
4. **A lightweight DI container** — modules self-register their hooks and other contributions (tools, agents, etc.) without a central place (src/index.ts) needing to know about everything explicitly

## Research Questions

1. **Hook interface design** — What should a Hook look like? Options:
   - A typed interface per hook name (e.g., `ChatSystemTransformHook`, `SessionCompactingHook`)
   - A generic `Hook<TInput, TOutput>` interface
   - Something else?
   - How do we define the input/output types for each hook name?

2. **Composition semantics** — When multiple handlers register for the same hook name, how do they compose?
   - Sequential mutation (each handler mutates output, next sees the result)
   - Parallel execution (all run concurrently, results merged)
   - Priority/ordering (some hooks run before others)
   - Should this differ per hook type?

3. **DI container design** — What's the right scope for a DI container here?
   - Look at existing lightweight TS DI options (tsyringe, inversify, awilix, or hand-rolled)
   - Does it need to handle async initialization?
   - How do modules declare what they provide and what they need?
   - How does this interact with the plugin's existing construction pattern (everything built in the Plugin function)?

4. **Module self-registration** — How does a module (e.g., execution/, sessions/, vcs/) declare its hooks?
   - Does each module export a `register(container)` function?
   - Does each module export a list of hook descriptors?
   - How does the container discover and wire them?

5. **Concrete mapping** — Map the 5 existing hooks to this new model:
   - Which module should own each hook?
   - What dependencies does each hook need from the container?
   - Show what the hook implementations would look like under this design

6. **src/index.ts role** — Under this design, what does index.ts still do? Ideally it becomes very thin.

## Constraints

- Must work with TypeScript (no decorators required, but ok if used)
- Must handle async initialization (some managers need async setup)
- Must be testable — hooks should be unit-testable in isolation
- Should not require a heavy framework — prefer simple and explicit over magic
- The existing module structure (execution/, sessions/, vcs/, projects/, etc.) should be respected

## Reference

- Current hooks in: `hdwlinux/packages/opencode-projects-plugin/src/index.ts`
- Existing module structure: `hdwlinux/packages/opencode-projects-plugin/src/`
- Prior research (for context on current hooks and dependencies): `.projects/opencode-projects-plugin-hooks-0d2eb5/research/hooks-abstraction-research.md`

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

The research is complete. Let me provide a summary of the key findings and recommendations:

## Research Complete: Composable Hook Registry with DI Container

I've completed the research on designing a composable hook system with a lightweight DI container. The full document is at `.projects/opencode-projects-plugin-hooks-0d2eb5/research/composable-hook-registry-di.md`.

### Key Recommendations

#### 1. Hook Interface Design: Typed Hook Names with Mapped Types

```typescript
interface HookSignatures {
  "experimental.chat.system.transform": {
    input: ChatSystemInput
    output: ChatSystemOutput
  }
  "experimental.session.compacting": {
    input: CompactingInput
    output: CompactingOutput
  }
  // ... other hooks
}

type HookHandler<K extends HookName> = (
  input: HookSignatures[K]["input"],
  output: HookSignatures[K]["output"]
) => Promise<void> | void
```

This provides full type safety for hook names and signatures with compile-time errors for invalid hook names.

#### 2. Composition Semantics: Sequential Mutation (Pipeline)

Multiple handlers for the same hook name are called sequentially, each mutating the output. Priority ordering (lower runs first) controls execution order. This matches OpenCode's existing hook semantics.

#### 3. DI Container: Hand-Rolled Service Locator

A simple ~50-line container with typed service tokens. No decorators, no magic, no external dependencies. Services are registered explicitly and resolved on demand.

#### 4. Module Self-Registration: `register(container)` Functions

Each module exports a `register(container)` function that:
- Registers its services (managers, utilities)
- Registers its hooks with the HookRegistry

#### 5. Hook Ownership Mapping

| Hook | Owner Module | Rationale |
|------|--------------|-----------|
| `experimental.chat.system.transform` | `projects/` | Injects project context |
| `shell.env` | `projects/` | Exports project ID |
| `experimental.session.compacting` | `sessions/` | Session capture is core responsibility |
| `event` | `execution/` | Tracks delegation lifecycle |
| `config` | `config/` | Registers agents, commands, skills |

#### 6. Thin `src/index.ts`

The entry point becomes ~50-80 lines that:
1. Creates the container
2. Registers infrastructure (client, shell, repo root)
3. Calls each module's register function in dependency order
4. Builds plugin hooks from the registry
5. Returns the plugin object

### Benefits

- **Compartmentalized hooks** — each hook is its own unit, not a method on a registry class
- **Multiple handlers per hook** — modules can contribute to the same hook name
- **Hooks close to consumers** — implementations live in the modules that need them
- **Testable** — hooks can be unit-tested in isolation with mock containers
- **No magic** — explicit registration, no decorators, no auto-discovery
- **Zero dependencies** — hand-rolled container, no tsyringe/awilix

---

*Generated: 2026-03-04T19:51:54.045Z*