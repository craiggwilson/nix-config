# AGENTS.md - AI Assistant Guide

## Repository Overview

This is a NixOS/Home Manager configuration repository for personal systems using the **substrate** framework.

### Version Control

**This repository uses Jujutsu (jj), not Git.** Use `jj` commands for all version control operations:

```bash
jj status          # Check current state
jj diff            # View changes
jj new             # Create a new change
jj describe -m ""  # Add a description to the current change
jj squash          # Squash changes into parent
jj log             # View history
jj git push        # Push to remote
```
### Related Repositories

- **`nix-private`** (sibling repository): Contains private/sensitive substrateModules imported via `inputs.hdwlinux-private.substrateModules.nix-private`
- Clone location: `~/Projects/hdwlinux/nix-private`

---

## File Structure

```
nix-config/
├── hdwlinux/           # Active configuration using substrate
│   ├── flake.nix        # Main flake definition
│   ├── modules/         # Substrate modules
│   │   ├── apps/        # Application category definitions
│   │   ├── boot/        # Boot configuration
│   │   ├── desktop/     # Desktop environment (Hyprland, etc.)
│   │   ├── hardware/    # Hardware configurations
│   │   ├── hosts/       # Host-specific configurations
│   │   ├── programs/    # Program configurations
│   │   ├── services/    # System services
│   │   └── users/       # User configurations
│   └── packages/        # Custom package definitions
└── substrate/           # Framework for building NixOS/Home Manager configs
    ├── builders/        # Flake-parts integration
    ├── core/            # Core framework logic
    └── extensions/      # Tags, types, home-manager extensions
```

---

## Substrate Framework

### Core Concepts

Substrate is a framework for building modular NixOS and Home Manager configurations with a tag-based selection system.

#### Module Structure

Modules are defined under `config.substrate.modules.<path>.<name>`:

```nix
{
  config.substrate.modules.programs.example = {
    tags = [ "some-tag" ];  # Required tags to enable this module
    
    nixos = { pkgs, ... }: {
      # NixOS configuration
    };
    
    homeManager = { config, ... }: {
      # Home Manager configuration
    };
  };
}
```

#### Tags System

Tags control which modules are included in a configuration:

- Tags are hierarchical (e.g., `desktop:custom:hyprland` implies `desktop:custom` and `desktop`)
- Hosts and users declare tags; modules require tags to be included
- Use `hasTag` in module functions to conditionally configure based on active tags

#### Hosts and Users

Hosts are defined with associated users and tags:

```nix
substrate.hosts.hostname = {
  system = "x86_64-linux";
  users = [ "username@profile" ];
  tags = [ "host:hostname" ];
};
```

Users can have multiple profiles (e.g., `craig@personal`, `craig@work`).

---

## Code Style Guidelines

### Comments

**Only explain "why", never "what":**

- ✅ Document complex business logic or architectural decisions
- ✅ Explain non-obvious design choices or workarounds
- ✅ Note external dependencies or constraints
- ❌ Do not describe what code does if it's readable
- ❌ Do not add comments for simple/obvious functionality
- ❌ Do not use comments as code documentation for straightforward Nix expressions

### Nix Style

- Use `lib.mkIf` for conditional configuration
- Use `lib.mkOption` with proper types and descriptions for options
- Follow existing patterns in the codebase for consistency

---

## Development Workflow

### Building Configurations

```bash
# Build NixOS configuration
nix build .#nixosConfigurations.hostname.config.system.build.toplevel

# Build Home Manager configuration  
nix build .#homeConfigurations.username.activationPackage

# Run validation checks
nix flake check
```

### Testing Changes

```bash
# Test a new configuration (NixOS)
sudo nixos-rebuild test --flake .#hostname

# Test a new configuration (Home Manager standalone)
home-manager test --flake .#username
```

### Common Patterns

1. **Adding a new program**: Create `hdwlinux/modules/programs/<name>/default.nix` with appropriate tags
2. **Adding a new host**: Create `hdwlinux/modules/hosts/<hostname>/default.nix` with disko config if needed
3. **Adding a new tag**: Add to the `substrate.settings.tags` list in the flake


### Agent Usage

You can consult the **nix-expert** on best nix practices and other types of questions.

---

## Key Files

- `hdwlinux/flake.nix` - Main entry point, imports all modules and defines substrate settings
- `substrate/extensions/tags/default.nix` - Tag system implementation
- `substrate/builders/flake-parts/*.nix` - NixOS and Home Manager configuration builders

## Goal

Build and refine a three-layer OpenCode plugin suite in `hdwlinux/packages/opencode`:

- **Program Planner** (`program-planner`): long-horizon, cross-project planning ("programs").
- **Project Planner** (`project-planner`): per-project backlog, sprint planning, and focus.
- **Work Executor** (`work-executor`): executes individual work items.

Key goals:

- **Top-down orchestration:** program → project → work, with each plugin also usable standalone.
- **Subagent orchestration & parallelism:** orchestrators coordinate specialized subagents (language, architecture, security, review, etc.), delegating work in parallel where possible.
- **Backend-agnostic planning state:** use a generic issue/storage abstraction (`IssueStorage`), with beads as one backend later, accessed via tools (OpenCode SDK + `opencode-beads`), never via direct `opencode-beads` imports or CLI calls.
- **Tests and safety nets:** add Bun-based tests for core orchestration behavior.

---

## Instructions

- **Architecture & hierarchy**
  - Three main plugins:
    - `program-planner`
    - `project-planner`
    - `work-executor`
  - Each plugin:
    - Has its own orchestrator.
    - Can be called directly via its commands.
    - May call the layer below:
      - Program planner delegates to project planner.
      - Project planner delegates to work executor.
  - Orchestrators should coordinate subagents and aggregate their results.

- **Subagents & parallelism**
  - Use specialized subagents for tasks:
    - e.g., `nix-expert`, `distributed-systems-architect`, `security-architect`, `code-reviewer-agent`, etc.
  - Orchestrators:
    - Identify relevant subagents per task.
    - Run them in parallel where tasks are independent.
    - Aggregate and store results via `IssueStorage`.

- **Storage / beads integration**
  - Planners and executor **must not** depend directly on `opencode-beads` or call beads CLI.
  - All beads interactions will eventually go through OpenCode SDK tools exposed by `opencode-beads`.
  - `IssueStorage` is the canonical abstraction:
    - Current implementation is **in-memory** only.
    - A pluggable backend interface (`IssueStorageBackend`) is defined, to later support a beads-backed implementation.
  - Storage abstraction naming is generic (issues, storage), not beads-specific.

- **Tooling / workflow**
  - Use **Jujutsu (jj)**:
    - Frequent, small commits with descriptive messages.
    - Multiple workspaces allowed (e.g., `nix-config-opencode-plugins-1`, `-2`) to run parallel "lanes" of work.
  - Testing:
    - Use **Bun** for tests, but Bun is not installed globally.
    - Always run tests via Nix:
      - `nix-shell -p bun --run "<bun command>"`
  - No dependency installs/changes without explicit user permission (package.json edits are okay only for scripts/tests, not deps).

- **Specs & docs**
  - There are extensive design docs:
    - `SPEC.md`, `IMPLEMENTATION.md`, `AGENTS_AND_SKILLS.md`, per-plugin `AGENTS.md`, and overview docs (`README.md`, `SUMMARY.md`, etc.).
  - Code and behavior should remain aligned with these documents.
  - Status: **"In Development"** (not production-ready yet); docs reflect that.

- **External references**
  - OpenCode plugin docs: https://opencode.ai/docs/plugins/
  - Beads: https://github.com/steveyegge/beads
  - `opencode-beads`: https://github.com/joshuadavidthomas/opencode-beads
  - Background agents example: https://github.com/kdcokenny/opencode-background-agents

---

## Accomplished

### Completed (as of 2026-02-14)

1. **Core storage abstraction** (`core/src/beads.ts`)
   - `IssueStorage` class with in-memory Map-based store
   - Methods: `query`, `findReady`, `getChildren`, `getDependencies`, `createIssue`, `updateIssue`, `createDependency`, `search`, `getIssue`, `clearCache`, `analyzeDependencies`
   - Stable stub ID format: `ISSUE-<timestamp>-<seq>`

2. **IssueStorageBackend interface** (`core/src/storage-backend.ts`)
   - Pluggable backend interface for future beads-backed implementation
   - Methods: `query`, `getIssue`, `createIssue`, `updateIssue`, `createDependency`

3. **BeadsIssueStorageBackend** (`core/src/backends/beads-backend.ts`)
   - Mock implementation of `IssueStorageBackend`
   - Factory function `createBeadsBackend()`
   - TODO comments marking where OpenCode SDK tool calls will go
   - **22 tests** in `core/tests/beads-backend.test.ts`

4. **SubagentDispatcher** (`core/src/orchestration/subagent-dispatcher.ts`)
   - `selectAgents(issue)` - selects agents based on labels (kafka→kafka-expert, security→security-architect, etc.)
   - `dispatchParallel()` / `dispatchSequential()` - parallel and sequential agent dispatch
   - `dispatchSmart()` - automatic parallelization based on agent category independence
   - Label-to-agent mappings for: kafka, flink, mongodb, go, java, nix, terraform, aws, security, distributed-systems
   - **17 tests** in `core/tests/subagent-dispatcher.test.ts`

5. **Execution Pipelines** (`work-executor/src/pipelines/`)
   - `ResearchPipeline` - 5 stages: parseQuestion → gatherContext → analyzeOptions → synthesizeRecommendation → createFollowUps
   - `POCPipeline` - 6 stages: parseHypothesis → minimalDesign → implement → validate → produceRecommendation → fileDiscoveredWork
   - `ImplementationPipeline` - 7 stages: analyzeRequirements → design → implement → test → codeReview → securityReview → wrapUp
   - `ReviewPipeline` - 4 stages: fetchTarget → analyze → produceFindings → createFollowUps
   - Orchestrator updated to use pipeline classes
   - **22 tests** in `work-executor/tests/pipelines.test.ts`

6. **Cross-Plugin Integration Tests** (`tests/integration/`)
   - `full-flow.test.ts` - End-to-end program → project → work flow
   - `cross-plugin-status.test.ts` - Status aggregation across plugins
   - `discovered-work.test.ts` - Discovered work creation and linking
   - **18 tests** verifying full orchestration hierarchy

7. **Program Planner Orchestrator** (`program-planner/src/orchestrator.ts`)
   - `createProgram`, `planProgram`, `getProgramStatus`, `rebalancePrograms`, `listPrograms`
   - Tests in `program-planner/tests/program-orchestrator.test.ts`

8. **Project Planner Orchestrator** (`project-planner/src/orchestrator.ts`)
   - `initProject`, `planProject`, `planSprint`, `getProjectStatus`, `getProjectFocus`, `listProjects`
   - Tests in `project-planner/tests/project-focus.test.ts`

9. **Work Executor Orchestrator** (`work-executor/src/orchestrator.ts`)
   - `claimWork`, `executeWork`, `executeResearch`, `executePOC`, `executeImplementation`, `performReview`
   - Tests in `work-executor/tests/orchestrator.test.ts`

### Test Summary

**91 tests pass** across 11 test files:
- `core/tests/beads.test.ts` - IssueStorage basic behavior
- `core/tests/beads-backend.test.ts` - BeadsIssueStorageBackend (22 tests)
- `core/tests/config.test.ts` - ConfigManager
- `core/tests/subagent-dispatcher.test.ts` - SubagentDispatcher (17 tests)
- `work-executor/tests/orchestrator.test.ts` - WorkExecutorOrchestrator
- `work-executor/tests/pipelines.test.ts` - Execution pipelines (22 tests)
- `program-planner/tests/program-orchestrator.test.ts` - ProgramPlannerOrchestrator
- `project-planner/tests/project-focus.test.ts` - ProjectPlannerOrchestrator
- `tests/integration/full-flow.test.ts` - End-to-end flow
- `tests/integration/cross-plugin-status.test.ts` - Status aggregation
- `tests/integration/discovered-work.test.ts` - Discovered work

Run all tests: `nix-shell -p bun --run "cd hdwlinux/packages/opencode && bun test --timeout 30000"`

### Current jj History

```
wzyowskw  opencode: add storage backend, subagent orchestration, execution pipelines, and integration tests
ttqowson  opencode: sync dist files and work-executor tests
yxtlnxxs  opencode: introduce IssueStorage abstraction and decouple beads
puqzkupx  opencode-plugins: code review, agents/skills, and nix packaging
```

---

## Not Yet Done / Next Steps

1. **Beads-backed storage backend**
   - `BeadsIssueStorageBackend` exists as mock; needs real implementation using OpenCode SDK tool calls to `opencode-beads`
   - Refactor `IssueStorage` to optionally delegate to a configured backend

2. **Wire SubagentDispatcher into orchestrators**
   - Orchestrators have dispatcher but don't yet use it for real agent selection/dispatch
   - Implement actual subagent invocation via OpenCode Task tool

3. **Flesh out pipeline stage implementations**
   - Pipelines have structure but stages are still mostly stubs
   - Connect to actual codebase analysis, code generation, test execution

4. **Cross-plugin delegation**
   - Program planner should delegate to project planner
   - Project planner should delegate to work executor
   - Currently each operates independently

5. **Real discovered work creation**
   - Pipelines should create actual discovered work issues during execution
   - Link via dependencies with `discovered-from` pattern

---

## Relevant Files

### Core (`hdwlinux/packages/opencode/core/`)
- `src/beads.ts` - IssueStorage, IssueRecord, IssueQuery, DependencyNode
- `src/storage-backend.ts` - IssueStorageBackend interface
- `src/backends/beads-backend.ts` - BeadsIssueStorageBackend mock
- `src/backends/index.ts` - Backend exports
- `src/orchestration/subagent-dispatcher.ts` - SubagentDispatcher
- `src/orchestration/index.ts` - Orchestration exports
- `src/agents.ts` - Agent registry (AGENTS)
- `src/skills.ts` - Skills registry
- `src/config.ts` - ConfigManager
- `src/index.ts` - Main exports

### Program Planner (`hdwlinux/packages/opencode/program-planner/`)
- `src/orchestrator.ts` - ProgramPlannerOrchestrator
- `src/types.ts` - Type definitions
- `tests/program-orchestrator.test.ts` - Tests

### Project Planner (`hdwlinux/packages/opencode/project-planner/`)
- `src/orchestrator.ts` - ProjectPlannerOrchestrator
- `src/types.ts` - Type definitions
- `tests/project-focus.test.ts` - Tests

### Work Executor (`hdwlinux/packages/opencode/work-executor/`)
- `src/orchestrator.ts` - WorkExecutorOrchestrator
- `src/types.ts` - Type definitions
- `src/pipelines/research-pipeline.ts` - ResearchPipeline
- `src/pipelines/poc-pipeline.ts` - POCPipeline
- `src/pipelines/implementation-pipeline.ts` - ImplementationPipeline
- `src/pipelines/review-pipeline.ts` - ReviewPipeline
- `src/pipelines/index.ts` - Pipeline exports
- `tests/orchestrator.test.ts` - Orchestrator tests
- `tests/pipelines.test.ts` - Pipeline tests

### Integration Tests (`hdwlinux/packages/opencode/tests/`)
- `integration/full-flow.test.ts` - End-to-end flow
- `integration/cross-plugin-status.test.ts` - Status aggregation
- `integration/discovered-work.test.ts` - Discovered work
