# OpenCode Planning & Execution Plugin Suite

A comprehensive system for long-term program planning, project execution planning, and work implementation using beads as the canonical state store.

## Overview

Three complementary plugins work together to manage software engineering from strategic planning through implementation:

- **Program Planner** (`opencode-program-planner`) – Multi-month programs, themes, and cross-project roadmaps
- **Project Planner** (`opencode-project-planner`) – Repo/service backlogs, sprints, and execution plans
- **Work Executor** (`opencode-work-executor`) – Actual implementation with specialist subagents for research, POCs, and code review

All three share beads as the canonical state store and collaborate via subagent invocation.

## Orchestration Model

Each plugin exposes a single orchestrator agent that owns its command surface:

- Program Planner → `program-planner` orchestrator
- Project Planner → `project-planner` orchestrator
- Work Executor → `work-orchestrator` orchestrator

These orchestrators:

- Handle the relevant `/program-*`, `/project-*`, and `/work-*` commands.
- Delegate heavy analysis, design, and implementation steps to subagents defined in the plugin-specific `AGENTS.md` files and in `AGENTS_AND_SKILLS.md`.
- Spawn subagents in parallel when work streams are independent (for example, language expert, security review, and architecture review running concurrently).
- Collaborate top-down while remaining independently useful:
  - Work Executor can run stand-alone on existing beads issues.
  - Project Planner can plan and manage backlogs, optionally delegating execution to the Work Executor.
  - Program Planner coordinates programs across projects via beads state and project-level rollups.

## Shared Data Model (Beads)

### Issue Types

- `epic` – Programs, large cross-cutting projects, sprints (if modeled as epics)
- `feature` – Medium-sized chunks of value
- `task` – Specific, usually implementable units of work
- `chore` – Maintenance/tooling
- `bug` – Defects

### Structural Labels

- **Programs**: `program`, `program:<slug>`
- **Projects**: `project`, `project:<slug>`, `repo:<name>` (or `service:<name>`)
- **Sprints/Iterations**: either `sprint:<name>` label or `sprint` epics
- **Work kinds**: `research`, `poc`, `implementation`, `review`, `security-review`

### Relationships

- **Parent/Child**: Programs → project epics → features/tasks via `parent` or hierarchical IDs
- **Dependencies**: `X needs Y` encoded as beads deps (`bd dep add X Y`)
- **Discovered Work**: `discovered-from:<id>` dependency for new bugs/chores/tasks born during work

### Status & Assignment

- `status`: `todo`, `in_progress`, `blocked`, `done`, etc.
- `assignee`: human or "agent" string (e.g., `agent:work-executor`)
- `priority`: `0–4` as beads defines

### Long-Form Documentation

- Stored as external docs (Google Docs/Drive) with links in issue descriptions, or
- In repo `history/` directory as per beads best practices
- Program and project planners own creating and linking charters/roadmaps
- Work executor may write technical designs/POC notes

## Plugin 1: Program Planner

### Responsibilities

- Define and maintain programs with goals, constraints, metrics, and timelines
- Decompose programs into project epics (per repo/service) and cross-cutting epics
- Manage program-level dependencies and risk
- Provide high-level views: active programs, health, risks, key milestones

### Commands

#### `/program-new`

Create a new program.

**Input** (conversational or args):
- Program name and short summary
- Rough horizon (quarter, half-year, etc.)
- Target outcomes/metrics
- Initial repos/services involved

**Behavior**:
- Create `epic` issue with labels: `program`, `program:<slug>`
- Optionally create/link a charter doc and store link in issue description
- Spawn `program-requirements-agent` to structure the charter

**Output**:
- New beads issue ID
- Link to charter doc (if created)

#### `/program-plan`

Decompose a program into project epics and cross-cutting features.

**Input**:
- Program ID or name (resolve via beads search)
- Optional: list of repos/services in scope

**Behavior**:
- Orchestrator fetches program issue + existing children/deps
- Spawns subagents:
  - `program-decomposer-agent` – proposes project epics and cross-cutting epics
  - `codebase-analyst` – understands repo structure if needed
- Writes beads issues:
  - New project epics: type `epic`, labels `project`, `project:<slug>`, `program:<slug>`, optional `repo:<name>`
  - Dependencies between program and projects and among projects

**Output**:
- List of created/updated beads issues
- Dependency graph summary

#### `/program-status`

Aggregate program-level status.

**Behavior**:
- For each program:
  - List key project epics and their aggregate statuses
  - List major blocked epics and their blockers
  - Summarize progress vs timeline (if using due dates)
- Highlight risks and critical path items

**Output**:
- Formatted status report
- Optionally written to a doc or printed to stdout

#### `/program-rebalance`

Adjust priorities at program and project-epic level.

**Behavior**:
- Analyze current priorities, dependencies, and capacity
- Suggest priority changes
- Optionally apply them in beads

**Output**:
- Proposed changes with rationale
- Confirmation of applied changes

### Agent Topology

- **Orchestrator**: `program-planner`
  - Reads/writes beads
  - Decides when to call:
    - `program-requirements-agent` – structures the program's charter
    - `program-decomposer-agent` – proposes epics/features and dependencies
    - `program-risk-agent` – identifies and creates risk/mitigation tasks

- **Supporting Skills**:
  - Beads access (CLI)
  - Documentation skills (Google Docs/Drive or local history)
  - Codebase exploration when decomposition needs repo knowledge

### State Storage

- **Beads**: Program epics, project epics, high-level features, risks
- **Docs**: Program charters + roadmaps linked from program issues
- **Plugin Config**: User defaults (planning horizon, default labels, auto-create project epics)

## Plugin 2: Project Planner

### Responsibilities

- Initialize project planning and link repos/services to programs
- Decompose epics into backlog items tied to code
- Build and maintain sprints based on capacity, priorities, dependencies
- Provide project status and roll-ups for program planner

### Commands

#### `/project-init`

Initialize project planning for a repo/service.

**Input**:
- Current repo (implicit) and optional project name
- Optional program to attach to

**Behavior**:
- Create `epic` issue with labels: `project`, `project:<slug>`, `repo:<name>`, optionally `program:<slug>`
- Optionally create a minimal "project charter" doc linked in the issue

**Output**:
- New project epic ID
- Link to charter doc (if created)

#### `/project-plan`

Decompose a project epic into backlog items.

**Input**:
- Project epic ID (or derive from current repo)
- Optional: specific program epic to align with

**Behavior**:
- Orchestrator fetches project epic + existing backlog
- Spawns `backlog-decomposer-agent` to:
  - Propose new features/tasks/chores
  - Attach them as children or dependents of the project epic
  - Assign initial priorities and statuses
- Optionally spawn work-executor subagents for research spikes
- Write beads issues and dependencies

**Output**:
- List of created/updated backlog items
- Dependency graph summary

#### `/project-sprint`

Plan a sprint or iteration.

**Input**:
- Sprint name or default (`sprint:<YYYY-WW>`)
- Duration, capacity, and whether to auto-assign tasks

**Behavior**:
- Orchestrator + `sprint-planner-agent`:
  - Collect ready backlog for the project (via beads filters)
  - Select tasks based on priority, dependencies, risk, and capacity
  - Mark membership via:
    - Labels `sprint:<name>`, or
    - New `epic` with label `sprint` and parent relationships

**Output**:
- Sprint composition with task list
- Capacity summary and risk flags

#### `/project-status`

Summarize project health.

**Behavior**:
- For a project epic or repo:
  - Show counts and examples of todo/in progress/blocked/done
  - Highlight critical blockers and stale tasks
  - Optionally summarize for upstream programs

**Output**:
- Formatted status report
- Optionally written to a doc or printed to stdout

#### `/project-focus`

Surface "do next" work for the current repo.

**Behavior**:
- For the current repo, surface:
  - A short "do next" list from ready tasks
  - Optionally call into work-executor to start one

**Output**:
- Prioritized list of ready tasks
- Suggested next action

### Agent Topology

- **Orchestrator**: `project-planner`
  - Integrates:
    - `backlog-decomposer-agent`
    - `sprint-planner-agent`
    - `status-aggregator-agent`

- **Supporting Skills**:
  - Codebase explorers to understand actual code layout
  - Domain experts as subagents when planning requires deep infra/domain knowledge

### State Storage

- **Beads**: Project epics, backlog items, sprints, and their dependencies
- **Docs**: Optional project charters, implementation/design docs under `history/` or external docs
- **Plugin Config**: Per-repo preferences (default project epic ID, sprint style, default sprint length)

## Plugin 3: Work Executor

### Responsibilities

- Claim and execute tickets from ready/backlog queues
- Perform research, POCs, and full implementation
- Provide structured execution pipelines: Analyze → Design → Implement → Test → Review → Security Review → Wrap-up
- Maintain high-quality outputs with code and security reviews
- Create discovered work issues and link properly

### Work Types

Represented as beads issues with labels:

- `research` – Pure research/investigation, no code changes
- `poc` – Proof of concept/spike, optimized for speed
- `implementation` – Full implementation with tests and reviews
- `review` – Code review or security review
- `security-review` – Security-focused review

### Commands

#### `/work-claim`

Claim a suitable ready task.

**Input**:
- Optional filters: project, program, labels, type, priority

**Behavior**:
- Find a suitable `ready` bead matching filters
- Set `status=in_progress`, `assignee` to user or `agent:work-executor`
- Start an orchestrated execution pipeline for that issue

**Output**:
- Claimed issue ID
- Execution pipeline summary

#### `/work-execute`

Execute one or more specific beads issues.

**Input**:
- Specific beads ID(s) to work on
- Optional "mode": `full`, `research-only`, `poc-only`

**Behavior**:
- Orchestrator reads issue description, dependencies, and linked docs
- Chooses a workflow:
  - For `research`: research pipeline (no code changes, produce design/recommendation)
  - For `poc`: spike pipeline optimized for speed with "throwaway or keep" guidance
  - For `implementation`: full pipeline through reviews
- Spawns specialist subagents as appropriate at each phase

**Output**:
- Execution summary
- Links to created artifacts (docs, PRs, discovered issues)

#### `/work-poc`

Create and/or execute a POC.

**Input**:
- POC description or hypothesis
- Optional parent issue (program/project epic)

**Behavior**:
- Create or use existing `poc` labeled issue linked to parent
- Run research subagents to validate hypothesis
- Run implementation subagents for minimal POC
- Produce "Keep/Refine/Discard" recommendation

**Output**:
- POC issue ID
- Recommendation and findings

#### `/work-research`

Perform pure research.

**Input**:
- Research question or topic
- Optional parent issue

**Behavior**:
- Create or use existing `research` issue
- Run research subagents (domain experts, codebase analysts)
- Produce concise report
- Spin off follow-up implementation tasks via project planner if needed

**Output**:
- Research issue ID
- Report summary
- Follow-up task IDs (if created)

#### `/work-review`

Perform code or security review.

**Input**:
- Target: beads issue, PR reference, or code path
- Mode: `code-review`, `security-review`, or `both`

**Behavior**:
- Orchestrator spawns reviewer subagents
- Attaches reviews as:
  - Comments/notes in the beads issue, and/or
  - Comments on the actual PR via appropriate tooling

**Output**:
- Review summary
- List of findings/suggestions
- Links to created follow-up issues (if any)

### Execution Pipelines

#### Research Pipeline

1. Understand issue context (beads + docs)
2. Use domain experts + codebase analysis to:
   - Summarize options
   - Recommend a path with pros/cons
3. Output:
   - Concise report attached to issue and/or linked doc
   - Optional follow-up tasks created via project planner

#### POC Pipeline

1. Clarify the hypothesis the POC should prove/disprove
2. Minimal design from appropriate experts
3. Focused implementation and basic validation
4. Outcome:
   - Clear "Keep/Refine/Discard" recommendation
   - Notes captured for planners
   - Discovered work tasks filed

#### Implementation Pipeline

1. Analyze requirements and existing code/tests
2. Design step (with distributed systems/security/language experts as needed)
3. Implementation step via appropriate language/domain expert
4. Testing: ensure/extend tests and run them
5. Code review via `code-reviewer-agent`
6. Security review via `security-reviewer-agent`
7. Update beads:
   - Status to `done` when criteria met
   - Add `discovered-from` issues as necessary

### Agent Topology

- **Orchestrator**: `work-orchestrator`
  - Central dispatcher for a given issue
  - Decides which specialist subagents to employ based on:
    - Labels: language, domain (`kafka`, `nix`, `terraform`, etc.)
    - Repo technology stack (detected or configured)
    - Work type: `research`, `poc`, `implementation`, `review`

- **Specialist Implementation Subagents**:
  - Language experts: `go-expert`, `java-expert`, `nix-expert`, `terraform-expert`, `flink-expert`, `kafka-expert`, `mongodb-expert`, etc.
  - Distributed systems: `distributed-systems-architect`
  - Security: `security-architect`
  - Infra/cloud: `aws-expert` or similar
  - Codebase: `codebase-analyst` or `explore`

- **Reviewer Subagents**:
  - `code-reviewer-agent` – Reviews for correctness, style, maintainability
  - `security-reviewer-agent` – Reviews with security lens (input validation, authz, crypto, secrets, dependency risk)

### State Storage

- **Beads**: Execution state per ticket (status, assignee, labels), discovered issues, review findings
- **Docs**: Research reports and POC notes under `history/` or external docs, linked back to issues
- **Plugin Config**: Language/tech stack preferences per repo, risk posture, limits on autonomous edits

## Plugin Collaboration

### Program → Project

- `/program-plan` creates/updates project epics and dependencies
- Provides high-level requirements and goals to project planner

### Project → Work

- `/project-plan` and `/project-sprint` produce ready tasks with clear descriptions and parents
- Work executor claims these tasks (`/work-claim` / `/work-execute`) and runs execution pipelines

### Work → Project/Program

- Work executor:
  - Updates statuses and adds discovered issues with `discovered-from` pointing to parent program/project items
  - Attaches research/POC outputs and design docs
- Project planner consumes:
  - Newly discovered work to rebalance sprints/backlog
  - Implementation status for project health
- Program planner consumes:
  - Aggregated status and risks from project planners
  - Research/POC outcomes that may alter program scope or priority

## Output Storage Strategy

### Beads Issues (Essential Summary)

- Title, description, status, priority, assignee
- Links to external artifacts
- Short "Findings" or "Recommendation" section for research/POCs
- Discovered work issues with `discovered-from` dependencies

### External Artifacts (Rich Details)

- Research reports: `history/research/<issue-id>-<topic>.md`
- POC notes: `history/pocs/<issue-id>-<topic>.md`
- Design docs: `history/designs/<issue-id>-<topic>.md`
- Google Docs/Drive for collaborative or long-form documentation

This split keeps `.beads/issues.jsonl` readable and light while enabling rich documentation via better tools.

## Configuration

Each plugin has optional configuration stored in `~/.config/opencode/plugins/`:

- `program-planner.json` – Default planning horizon, labels, auto-create preferences
- `project-planner.json` – Per-repo preferences, sprint style, default sprint length
- `work-executor.json` – Language/tech stack preferences, risk posture, autonomous edit limits

## Future Extensions

- `opencode-planner-core` – Shared helpers for beads queries, dependency graph analysis, common subagents
- `opencode-planner-calendar` – Maps program/project milestones to calendar events (Google Calendar, etc.)
