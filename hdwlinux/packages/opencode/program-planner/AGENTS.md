# OpenCode Program Planner Plugin

Long-term program planning, themes, and cross-project roadmaps.

## Overview

The Program Planner plugin owns multi-month programs and their decomposition into project epics. It uses beads as the canonical state store and delegates heavy lifting to specialized subagents.

## Architecture

### Orchestrator Agent: `program-planner`

Central dispatcher for program planning commands. Reads/writes beads and decides which subagents to spawn.

**Responsibilities**:
- Handle `/program-*` commands
- Fetch and parse beads context
- Spawn appropriate subagents for analysis, decomposition, and risk assessment
- Write back structured beads issues and dependencies

### Subagents

#### `program-requirements-agent`

Structures a program's charter and requirements.

**Input**:
- Raw program description from user
- Optional existing program issue to refine

**Output**:
- Structured program charter (goals, non-goals, metrics, constraints, timeline)
- Summary for beads issue description
- Optional link to external charter doc

#### `program-decomposer-agent`

Proposes decomposition of a program into project epics and cross-cutting features.

**Input**:
- Program description and charter
- Optional codebase summaries (repos/services in scope)
- Existing project epics (if any)

**Output**:
- Proposed project epics with:
  - Titles, types, priorities
  - Dependencies and sequencing
  - Rough effort estimates
- Cross-cutting epics (infra, security, platform)
- Dependency graph summary

#### `program-risk-agent`

Identifies risks and proposes mitigation tasks.

**Input**:
- Program description
- Proposed decomposition
- Historical context (if available)

**Output**:
- Risk assessment with:
  - Risk description
  - Likelihood and impact
  - Mitigation strategy
- Proposed risk/mitigation beads issues

### Orchestration & Parallelism

The `program-planner` orchestrator should:

- Run `program-requirements-agent`, `program-decomposer-agent`, and `program-risk-agent` in parallel when possible, then merge their outputs into a single program plan.
- Treat project-level planning and work execution as downstream concerns by creating or updating beads issues that project and work plugins can act on independently.

### Skills & External Tools

- **Beads CLI**: `bd show`, `bd new`, `bd dep add`, etc.
- **Documentation**: Google Docs/Drive or local `history/` files
- **Codebase Analysis**: Spawn `codebase-analyst` or `explore` agent when needed

## Commands

See SPEC.md for detailed command documentation:
- `/program-new` – Create a new program
- `/program-plan` – Decompose a program into project epics
- `/program-status` – Aggregate program-level status
- `/program-rebalance` – Adjust priorities

## State Model (Beads)

### Program Issues

- **Type**: `epic`
- **Labels**: `program`, `program:<slug>`
- **Priority**: Default `1` (high)
- **Description**: Goals, non-goals, metrics, constraints, timeline, link to charter doc
- **Children**: Project epics and cross-cutting epics

### Project Epics (Created by Program Planner)

- **Type**: `epic`
- **Labels**: `project`, `project:<slug>`, `program:<slug>`, optional `repo:<name>`
- **Parent**: Program epic
- **Dependencies**: Cross-program dependencies via `needs`

### Risk Issues (Created by Program Planner)

- **Type**: `task` or `chore`
- **Labels**: `risk`, `mitigation`
- **Parent**: Program epic
- **Description**: Risk description, likelihood, impact, mitigation strategy

## Configuration

File: `~/.config/opencode/plugins/program-planner.json`

```json
{
  "defaultHorizon": "quarter",
  "autoCreateProjectEpics": true,
  "defaultLabels": ["program"],
  "charterDocLocation": "external"
}
```

## Integration with Other Plugins

### Program → Project Planner

- `/program-plan` creates project epics that project planner can use as anchors
- Provides high-level requirements and goals

### Program ← Work Executor

- Receives research/POC outcomes that may alter program scope or priority
- Consumes aggregated status from project planners

## Development Notes

- Always use beads as the single source of truth
- Keep issue descriptions concise; use external docs for rich details
- Use hierarchical labels for organization (e.g., `program:platform-modernization`)
- Discovered work should be filed with `discovered-from` dependencies
