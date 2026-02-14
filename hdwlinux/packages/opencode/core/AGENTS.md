# OpenCode Planner Core

Shared utilities and helpers for the planning and execution plugin suite.

## Overview

The Core module provides shared functionality used by Program Planner, Project Planner, and Work Executor plugins:

- Beads query and manipulation helpers
- Dependency graph analysis
- Common subagents (generic decomposer, status aggregator)
- Configuration management
- Artifact storage and linking

## Shared Utilities

### Beads Helpers

- `beads-query` – Query beads with filters (labels, status, priority, parent, etc.)
- `beads-create` – Create new issues with proper structure
- `beads-update` – Update existing issues
- `beads-deps` – Manage dependencies
- `beads-search` – Search issues by title/description

### Dependency Graph Analysis

- `graph-analyze` – Analyze dependency graph for cycles, critical path, blockers
- `graph-visualize` – Produce ASCII or structured representation of dependencies
- `graph-ready` – Identify ready tasks (no blocking dependencies)

### Configuration Management

- `config-load` – Load plugin configuration from `~/.config/opencode/plugins/`
- `config-merge` – Merge global and per-repo configuration
- `config-validate` – Validate configuration schema

### Artifact Management

- `artifact-create` – Create and link artifacts (docs, reports, POC notes)
- `artifact-link` – Link artifacts to beads issues
- `artifact-store` – Store artifacts in `history/` or external docs

## Common Subagents

### Generic Decomposer Agent

Proposes decomposition of an epic into smaller issues.

**Input**:
- Epic description and context
- Optional codebase analysis
- Existing child issues (if any)

**Output**:
- Proposed child issues with:
  - Titles, types, priorities
  - Dependencies and sequencing
  - Rough effort estimates

### Status Aggregator Agent

Summarizes status of an epic and its children.

**Input**:
- Epic and all child issues
- Optional historical data

**Output**:
- Status report with:
  - Counts: todo, in progress, blocked, done
  - Critical blockers
  - Progress summary

## Data Models

### Program

```
{
  "id": "PROG-123",
  "type": "epic",
  "title": "Platform Modernization",
  "labels": ["program", "program:platform-modernization"],
  "priority": 1,
  "description": "...",
  "charterDocUrl": "https://docs.google.com/...",
  "horizon": "quarter",
  "goals": [...],
  "nonGoals": [...],
  "metrics": [...],
  "constraints": [...],
  "children": ["PROJ-456", "PROJ-789"],
  "dependencies": []
}
```

### Project

```
{
  "id": "PROJ-456",
  "type": "epic",
  "title": "Service Refactor",
  "labels": ["project", "project:service-refactor", "repo:my-service", "program:platform-modernization"],
  "priority": 1,
  "description": "...",
  "charterDocUrl": "https://docs.google.com/...",
  "parent": "PROG-123",
  "children": ["FEAT-001", "TASK-002"],
  "dependencies": []
}
```

### Work Item

```
{
  "id": "TASK-001",
  "type": "task",
  "title": "Implement caching layer",
  "labels": ["implementation", "kafka", "distributed-systems"],
  "priority": 2,
  "status": "todo",
  "assignee": "agent:work-executor",
  "description": "...",
  "parent": "PROJ-456",
  "dependencies": ["TASK-002"],
  "discoveredFrom": null
}
```

### Discovered Work Item

```
{
  "id": "BUG-001",
  "type": "bug",
  "title": "Race condition in cache invalidation",
  "labels": ["discovered-from:TASK-001"],
  "priority": 2,
  "status": "todo",
  "description": "...",
  "parent": "PROJ-456",
  "discoveredFrom": "TASK-001"
}
```

## Integration Points

### Program Planner Uses

- `beads-query` – Find programs and project epics
- `beads-create` – Create program and project epics
- `beads-deps` – Manage program-level dependencies
- `config-load` – Load program planner preferences
- `generic-decomposer-agent` – Propose project epics

### Project Planner Uses

- `beads-query` – Find project epics and backlog items
- `beads-create` – Create backlog items
- `beads-deps` – Manage project-level dependencies
- `graph-ready` – Identify ready tasks
- `config-load` – Load project planner preferences
- `config-merge` – Merge global and per-repo config
- `generic-decomposer-agent` – Propose backlog items
- `status-aggregator-agent` – Summarize project health

### Work Executor Uses

- `beads-query` – Find work items
- `beads-update` – Update work item status
- `beads-create` – Create discovered work issues
- `beads-deps` – Manage discovered work dependencies
- `graph-ready` – Identify ready tasks
- `config-load` – Load work executor preferences
- `config-merge` – Merge global and per-repo config
- `artifact-create` – Create research/POC reports
- `artifact-link` – Link artifacts to issues

## Development Notes

- Keep utilities focused and composable
- Use consistent error handling and logging
- Support both CLI and programmatic interfaces
- Maintain backward compatibility as utilities evolve
- Document all public functions and data structures
