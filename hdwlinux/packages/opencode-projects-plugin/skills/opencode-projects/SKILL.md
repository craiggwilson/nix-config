---
name: opencode-projects
description: Reference for the opencode-projects-plugin — tools for managing projects, issues, delegations, and multi-agent teams.
---

# OpenCode Projects Skill

Tools for managing projects, issues, delegations, and multi-agent teams directly from opencode.

## References

Load these when you need detailed information:

- **[Tool Examples](references/tool-examples.md)** — Full examples for every tool
- **[Workflow Examples](references/workflow-examples.md)** — End-to-end workflow walkthroughs
- **[Team Composition](references/team-composition.md)** — Agent types, team sizes, roles, discussion strategies
- **[Workspace Management](references/workspace-management.md)** — jj workspace integration workflow, feature bookmarks
- **[Artifact & Session Management](references/artifact-session-management.md)** — Project structure, research, decisions, issue hierarchy
- **[Configuration](references/configuration.md)** — Full config schema with all options and defaults
- **[Troubleshooting](references/troubleshooting.md)** — Common issues and fixes

---

## Tool Reference

### project-create
Creates a new project and initiates planning.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `name` | string | Yes | Project name |
| `type` | `"roadmap"` \| `"project"` | No | `"project"` for 0-3 month work, `"roadmap"` for 6+ month strategic initiatives |
| `storage` | `"local"` \| `"global"` | No | Where to store project data |
| `description` | string | No | Brief description |

### project-list
Lists projects with optional filtering by scope and status.

| Parameter | Type | Description |
|-----------|------|-------------|
| `scope` | `"local"` \| `"global"` \| `"all"` | Which projects to list |
| `status` | `"active"` \| `"completed"` \| `"all"` | Filter by status |

### project-status
Shows project progress, open issues, and blockers.

| Parameter | Type | Description |
|-----------|------|-------------|
| `projectId` | string | Project to show (defaults to focused project) |
| `format` | `"summary"` \| `"detailed"` \| `"tree"` | Output format |

### project-focus
Sets or gets the current project context. Call without arguments to see current focus.

| Parameter | Type | Description |
|-----------|------|-------------|
| `projectId` | string | Project to focus on |
| `clear` | boolean | Clear current focus |

### project-plan
Manages planning sessions through discovery → synthesis → breakdown → complete phases.

| Parameter | Type | Description |
|-----------|------|-------------|
| `projectId` | string | Project to plan |
| `action` | `"start"` \| `"continue"` \| `"save"` \| `"advance"` \| `"phase"` \| `"status"` | Planning action |
| `phase` | `"discovery"` \| `"synthesis"` \| `"breakdown"` \| `"complete"` | Jump to specific phase |

### project-close
Closes a project with a reason and optional summary.

| Parameter | Type | Description |
|-----------|------|-------------|
| `projectId` | string | **Required.** Project to close |
| `reason` | `"completed"` \| `"cancelled"` \| `"archived"` | Closure reason |
| `summary` | string | Final summary |

### project-create-issue
Creates an issue within a project. Supports hierarchical IDs (epic → task → subtask).

| Parameter | Type | Description |
|-----------|------|-------------|
| `title` | string | **Required.** Issue title |
| `projectId` | string | Project to create issue in |
| `description` | string | Full issue description |
| `priority` | `1`\|`2`\|`3`\|`4` | P1 (critical) to P4 (low) |
| `parent` | string | Parent issue ID for hierarchy |
| `labels` | string[] | Labels for categorization |
| `blockedBy` | string[] | Issue IDs this is blocked by |

### project-work-on-issue
Delegates an issue to a background agent or team.

| Parameter | Type | Description |
|-----------|------|-------------|
| `issueId` | string | **Required.** Issue to work on |
| `isolate` | boolean | Create isolated jj workspace (required for code changes) |
| `agents` | string[] | Agent names. First is primary, others review. Omit for auto-selection. |
| `discussionStrategy` | `"fixedRound"` \| `"dynamicRound"` \| `"realtime"` | Override default strategy |
| `foreground` | boolean | Wait for completion (blocks conversation) |

### project-update-issue
Updates an issue's status, priority, assignee, or adds a comment.

| Parameter | Type | Description |
|-----------|------|-------------|
| `issueId` | string | **Required.** Issue to update |
| `status` | `"open"` \| `"in_progress"` \| `"closed"` | New status |
| `comment` | string | Comment to add |
| `priority` | number | New priority |
| `labels` | string[] | New labels |

### project-record-decision
Records an architectural or design decision with rationale and alternatives.

| Parameter | Type | Description |
|-----------|------|-------------|
| `title` | string | **Required.** Decision title |
| `decision` | string | **Required.** What was decided |
| `rationale` | string | **Required.** Why this decision was made |
| `status` | `"proposed"` \| `"decided"` \| `"rejected"` \| `"deferred"` | Decision status |
| `alternatives` | object[] | Alternatives considered and why rejected |
| `relatedIssues` | string[] | Related issue IDs |

### project-save-artifact
Registers a file as a project artifact (research, deliverable, plan, etc.).

| Parameter | Type | Description |
|-----------|------|-------------|
| `title` | string | **Required.** Artifact title |
| `type` | string | **Required.** `research`, `deliverable`, `plan`, `documentation` |
| `path` | string | **Required.** File path (must already exist) |
| `summary` | string | Brief description |
| `sourceIssue` | string | Issue that produced this artifact |

### project-internal-delegation-read
Retrieves a delegation result by ID. Use after session compaction when a notification arrives.

| Parameter | Type | Description |
|-----------|------|-------------|
| `id` | string | **Required.** Delegation ID |
| `projectId` | string | Project context |

---

## Best Practices

### Project Sizing
- **`project`** type: 0-3 months, implementation-focused, detailed technical design
- **`roadmap`** type: 6+ months, strategic, milestones and architecture decisions
- Keep issues small enough to complete in one delegation session

### Issue Granularity
- One clear deliverable per issue
- Include enough context that an agent can work without asking questions
- Research issues should produce artifacts; implementation issues should produce code

### When to Isolate
- `isolate=true` for any code changes that need to be merged
- `isolate=false` for research, analysis, documentation, planning
- Isolated workspaces use jj — always rebase onto the feature bookmark, never squash

### Team Selection
- Omit `agents` to let the small model auto-select (recommended for most tasks)
- Specify agents explicitly when you need a particular skill set or review perspective
- Two agents (primary + devil's advocate) is the sweet spot for most code changes
- The devil's advocate is adversarial by design — it assumes something is wrong and looks hard

### Delegation Flow
1. Fire delegations in parallel when issues are independent
2. Use `foreground=true` only for quick tasks where you need the result immediately
3. When notifications arrive, review the diff, rebase onto the feature bookmark, close the issue
4. For multiple parallel workspaces, rebase each in order — move the feature bookmark forward after each

### Closing Issues
Always close issues after merging their workspace:
```json
project-update-issue(issueId="...", status="closed", comment="Brief summary of what was done")
```
