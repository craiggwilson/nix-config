# OpenCode Planning & Execution Plugin Suite

A comprehensive system for long-term program planning, project execution planning, and work implementation using beads as the canonical state store.

## Plugins

### Program Planner (`opencode-program-planner`)

Long-term, cross-project program planning. Owns multi-month programs, themes, and roadmaps.

**Key Commands**:
- `/program-new` – Create a new program
- `/program-plan` – Decompose a program into project epics
- `/program-status` – Aggregate program-level status
- `/program-rebalance` – Adjust priorities

**See**: `program-planner/AGENTS.md`

### Project Planner (`opencode-project-planner`)

Repo/service-level backlog management, sprint planning, and execution coordination.

**Key Commands**:
- `/project-init` – Initialize project planning for a repo/service
- `/project-plan` – Decompose a project epic into backlog items
- `/project-sprint` – Plan a sprint or iteration
- `/project-status` – Summarize project health
- `/project-focus` – Surface "do next" work

**See**: `project-planner/AGENTS.md`

### Work Executor (`opencode-work-executor`)

Actual implementation of work with specialist subagents for research, POCs, and code review.

**Key Commands**:
- `/work-claim` – Claim a suitable ready task
- `/work-execute` – Execute one or more specific issues
- `/work-poc` – Create and/or execute a POC
- `/work-research` – Perform pure research
- `/work-review` – Perform code or security review

**See**: `work-executor/AGENTS.md`

### Core (`opencode-planner-core`)

Shared utilities and helpers for the planning and execution plugin suite.

**See**: `core/AGENTS.md`

## Architecture

All three plugins share:

- **Beads** as the canonical state store for programs, projects, and work items
- **Subagents** for specialized tasks (language experts, distributed systems architects, security experts, code reviewers)
- **Collaboration** via beads dependencies and subagent invocation

### Data Flow

```
Program Planner
    ↓ (creates project epics)
Project Planner
    ↓ (creates ready tasks)
Work Executor
    ↓ (updates status, files discovered work)
Project Planner
    ↓ (aggregates status)
Program Planner
```

## Getting Started

1. **Read the Spec**: `SPEC.md` contains the complete specification for all plugins, commands, and data models.

2. **Understand the Architecture**: Each plugin has an `AGENTS.md` file describing its orchestrator, subagents, and integration points.

3. **Initialize a Program**: Use `/program-new` to create your first program.

4. **Decompose into Projects**: Use `/program-plan` to create project epics for each repo/service.

5. **Plan a Project**: Use `/project-init` and `/project-plan` to create backlog items.

6. **Execute Work**: Use `/work-claim` or `/work-execute` to start implementing tasks.

## Configuration

Each plugin has optional configuration in `~/.config/opencode/plugins/`:

- `program-planner.json` – Program planner preferences
- `project-planner.json` – Project planner preferences
- `work-executor.json` – Work executor preferences

Per-repo configuration can be stored in `.beads/` or `.opencode/` directories.

## State Storage

### Beads Issues

All planning and work state is stored in beads:
- Programs, projects, and work items as beads issues
- Dependencies encoded as beads dependencies
- Status, priority, and assignee tracked in beads

### External Artifacts

Rich documentation is stored separately:
- Program charters: external docs or `history/programs/`
- Design docs: `history/designs/`
- Research reports: `history/research/`
- POC notes: `history/pocs/`

This keeps `.beads/issues.jsonl` readable and light while enabling rich documentation.

## Integration with Existing Tools

- **Beads**: Uses beads CLI for all state management
- **Google Docs/Drive**: Optional for collaborative documentation
- **Git/Jujutsu**: For code changes and version control
- **Existing Agents**: Leverages language experts, distributed systems architects, security experts, and code reviewers

## Development

Each plugin is independently deployable but shares common utilities from `core/`.

### Plugin Structure

```
<plugin-name>/
├── AGENTS.md          # Architecture and agent descriptions
├── src/               # Implementation (TypeScript, etc.)
├── tests/             # Tests
└── package.json       # Dependencies
```

### Shared Utilities

  The `core/` module provides:
  - Beads query and manipulation helpers
  - Dependency graph analysis
  - Common subagents
  - Configuration management
  - Artifact storage and linking

## Current Status

The plugin suite is in active development:

- Orchestrators, shared types, and core utilities are implemented.
- Beads helpers and wiring exist, but full beads CLI integration is not yet complete.
- Subagent coordination and execution pipelines are fully specified in `SPEC.md`, `AGENTS.md`, and `AGENTS_AND_SKILLS.md` but still need implementation work.

## Future Extensions

- `opencode-planner-calendar` – Maps program/project milestones to calendar events
- Additional domain-specific subagents (e.g., Kubernetes, database design)
- Integration with project management tools (Jira, Linear, etc.)
- Automated capacity planning and resource allocation

## Contributing

When adding new features or subagents:

1. Update the relevant `AGENTS.md` file
2. Update `SPEC.md` if adding new commands or data models
3. Add tests for new functionality
4. Ensure integration with other plugins is documented

## References

- `SPEC.md` – Complete specification for all plugins
- `program-planner/AGENTS.md` – Program planner architecture
- `project-planner/AGENTS.md` – Project planner architecture
- `work-executor/AGENTS.md` – Work executor architecture
- `core/AGENTS.md` – Core utilities and helpers
- OpenCode plugin reference – https://opencode.ai/docs/plugins/
- Beads issue tracker – https://github.com/steveyegge/beads
- OpenCode Beads integration – https://github.com/joshuadavidthomas/opencode-beads
- Background agents example plugin – https://github.com/kdcokenny/opencode-background-agents
