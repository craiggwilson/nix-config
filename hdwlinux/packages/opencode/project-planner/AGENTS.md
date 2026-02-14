# OpenCode Project Planner Plugin

Repo/service-level backlog management, sprint planning, and execution coordination.

## Overview

The Project Planner plugin owns project-scale planning: per-repo or per-service execution of program epics, sprint/backlog management, and day-to-day "what should I do next?" guidance. It uses beads as the canonical state store and delegates to specialized subagents.

## Architecture

### Orchestrator Agent: `project-planner`

Central dispatcher for project planning commands. Reads/writes beads and coordinates subagents.

**Responsibilities**:
- Handle `/project-*` commands
- Fetch and parse beads context for current repo/project
- Spawn appropriate subagents for decomposition, sprint planning, and status aggregation
- Write back structured beads issues and dependencies

### Subagents

#### `backlog-decomposer-agent`

Proposes concrete backlog items from a project or program epic.

**Input**:
- Project epic or program epic description
- Codebase analysis (existing code, tests, architecture)
- Optional existing backlog items

**Output**:
- Proposed features/tasks/chores with:
  - Titles, types, priorities
  - Dependencies and sequencing
  - Rough effort estimates
  - Links to relevant code/tests
- Dependency graph summary

#### `sprint-planner-agent`

Selects and organizes tasks for a sprint.

**Input**:
- Available backlog items (filtered by project/program)
- Sprint parameters: name, duration, capacity
- Current team/assignee capacity (if available)

**Output**:
- Sprint composition with:
  - Selected tasks and their priorities
  - Capacity summary
  - Risk flags (overcommitted, blocked dependencies, etc.)
- Sprint epic or label assignments

#### `status-aggregator-agent`

Summarizes project and backlog health.

**Input**:
- Project epic and all child issues
- Sprint information (if applicable)
- Historical status data

**Output**:
- Status report with:
  - Counts: todo, in progress, blocked, done
  - Critical blockers and stale tasks
  - Upcoming milestones
  - Discovered work summary

### Orchestration & Parallelism

The `project-planner` orchestrator should:

- Delegate backlog decomposition, sprint selection, and status aggregation to subagents, running them in parallel when they do not depend on each other.
- Use beads as the coordination layer so that the Work Executor can claim and execute ready tasks while project-level planning continues.

### Skills & External Tools

- **Beads CLI**: `bd show`, `bd new`, `bd dep add`, etc.
- **Codebase Analysis**: `codebase-analyst` or `explore` agent for repo structure and test discovery
- **Documentation**: Google Docs/Drive or local `history/` files
- **Domain Experts**: Spawn specialized agents (distributed systems, security, etc.) when planning requires deep knowledge

## Commands

See SPEC.md for detailed command documentation:
- `/project-init` – Initialize project planning for a repo/service
- `/project-plan` – Decompose a project epic into backlog items
- `/project-sprint` – Plan a sprint or iteration
- `/project-status` – Summarize project health
- `/project-focus` – Surface "do next" work

## State Model (Beads)

### Project Epics

- **Type**: `epic`
- **Labels**: `project`, `project:<slug>`, `repo:<name>`, optional `program:<slug>`
- **Priority**: Inherited from program or set locally
- **Description**: Project goals, scope, link to charter doc
- **Parent**: Program epic (if applicable)
- **Children**: Features, tasks, chores

### Backlog Items

- **Types**: `feature`, `task`, `chore`, `bug`
- **Labels**: Optional domain/tech labels (e.g., `kafka`, `nix`, `frontend`)
- **Parent**: Project epic
- **Priority**: Set during planning
- **Status**: `todo`, `in_progress`, `blocked`, `done`

### Sprint Representation

Two supported styles (configurable):

**Option 1: Sprint Labels**
- Backlog items tagged with `sprint:<YYYY-WW>`

**Option 2: Sprint Epics**
- `epic` with label `sprint`
- Backlog items as children

## Configuration

File: `~/.config/opencode/plugins/project-planner.json`

```json
{
  "sprintStyle": "labels",
  "defaultSprintLength": 2,
  "defaultSprintLengthUnit": "weeks",
  "autoAssignTasks": false,
  "charterDocLocation": "external"
}
```

Per-repo config: `.beads/project-planner.json` or `.opencode/project-planner.json`

```json
{
  "projectEpicId": "PROJ-123",
  "programEpicId": "PROG-456",
  "sprintStyle": "epics"
}
```

## Integration with Other Plugins

### Project ← Program Planner

- Receives project epics created by program planner
- Inherits high-level requirements and goals

### Project → Work Executor

- Produces ready tasks with clear descriptions and parents
- Work executor claims and executes these tasks

### Project ← Work Executor

- Receives status updates and discovered work
- Rebalances sprints based on new discoveries

## Development Notes

- Always use beads as the single source of truth
- Keep issue descriptions concise; use external docs for rich details
- Use hierarchical labels for organization (e.g., `repo:service-name`)
- Discovered work should be filed with `discovered-from` dependencies
- Support both label-based and epic-based sprint models
