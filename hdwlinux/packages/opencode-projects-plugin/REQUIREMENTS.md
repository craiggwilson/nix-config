# opencode-projects Plugin Requirements

## Overview

**opencode-projects** is an OpenCode plugin that provides a comprehensive project planning, tracking, and execution framework. It integrates with [beads](https://github.com/steveyegge/beads) for issue tracking and leverages OpenCode's subagent system for parallel work with VCS worktree isolation.

## Goals

1. **Planning**: Support both long-horizon (6+ months) and short-term (0-3 months) project planning through conversational discovery
2. **Tracking**: Use beads as the source of truth for all project/issue state
3. **Execution**: Enable parallel agent work with git worktree/jj workspace isolation
4. **Context Preservation**: Persist research artifacts and inject project context into sessions

## Non-Goals (v1)

- External tool integration (Jira, Linear, GitHub Issues)
- Nested background delegation (flat structure only)
- Real-time collaboration features

---

## Architecture

### Storage Locations

```
# Local repository (default, preferred)
<repo>/.projects/
├── <project-id>/
│   ├── .beads/              # Beads database (via bd init)
│   ├── research/            # Research artifacts
│   │   ├── <issue-id>.md
│   │   └── <issue-id>-2.md  # Numbered if multiple
│   ├── interviews/          # User interview transcripts
│   │   └── <session-id>.md
│   └── plans/               # Planning documents
│       ├── roadmap.md
│       ├── architecture.md
│       ├── risks.md
│       └── success-criteria.md

# Global fallback (when no workspace or explicitly requested)
$XDG_DATA_HOME/opencode/projects/
└── <project-id>/
    └── ... (same structure)

# Configuration
$XDG_CONFIG_HOME/opencode/opencode-projects.json
```

### Configuration Schema

```json
{
  "$schema": "https://opencode.ai/schemas/opencode-projects.json",
  "version": "1.0.0",
  
  "defaults": {
    "storage": "local",           // "local" | "global"
    "beadsPath": ".beads",        // Relative to project root
    "projectsPath": ".projects",  // Relative to repo root (local) or absolute (global)
    "vcs": "auto"                 // "auto" | "git" | "jj"
  },
  
  "projects": {
    "<project-id>": {
      "storage": "local",         // Override default
      "workspaces": ["<repo-path>"],  // Associated repositories
      "beadsPath": ".beads"       // Override beads location
    }
  },
  
  "agents": {
    "plannerModel": null,         // Override model for planning agents
    "researcherModel": null       // Override model for research
  },
  
  "worktrees": {
    "autoCleanup": true,          // Remove worktrees after merge
    "basePath": null              // Custom worktree location (default: ../<repo>-worktrees/)
  }
}
```

---

## Tools

### Project Management

#### `project_create`

Create a new project and initiate planning interview.

```typescript
interface ProjectCreateArgs {
  name: string;                    // Project name
  type?: "roadmap" | "project";    // Planning type (default: inferred from scope)
  workspace?: string;              // Repository path (default: current directory)
  storage?: "local" | "global";    // Storage location (default: from config)
  description?: string;            // Initial description
}

interface ProjectCreateResult {
  projectId: string;
  beadsPath: string;
  message: string;
  nextStep: "interview";           // Always starts interview
}
```

**Behavior:**
1. Generate unique project ID (slug from name + short hash)
2. Create project directory structure
3. Initialize beads database (`bd init`)
4. Create root epic in beads
5. Start conversational planning interview
6. Persist interview incrementally

#### `project_list`

List all projects (local and global).

```typescript
interface ProjectListArgs {
  scope?: "local" | "global" | "all";  // Filter scope (default: "all")
  status?: "active" | "completed" | "all";  // Filter by status
}

interface ProjectListResult {
  projects: Array<{
    id: string;
    name: string;
    storage: "local" | "global";
    workspace?: string;
    status: "active" | "completed";
    issueCount: { open: number; closed: number };
    lastActivity: string;          // ISO date
  }>;
}
```

#### `project_status`

Show detailed project status including progress and blockers.

```typescript
interface ProjectStatusArgs {
  projectId?: string;              // Project ID (default: focused project)
  format?: "summary" | "detailed" | "tree";
}

interface ProjectStatusResult {
  project: {
    id: string;
    name: string;
    description: string;
  };
  progress: {
    total: number;
    completed: number;
    inProgress: number;
    blocked: number;
    percentage: number;
  };
  blockers: Array<{
    issueId: string;
    title: string;
    blockedBy: string[];
  }>;
  recentActivity: Array<{
    issueId: string;
    action: string;
    timestamp: string;
  }>;
  dependencyTree?: string;         // ASCII tree (if format=tree)
}
```

#### `project_focus`

Set or get the current project context for the session.

```typescript
interface ProjectFocusArgs {
  projectId?: string;              // Set focus (omit to get current)
  issueId?: string;                // Also focus on specific issue
  clear?: boolean;                 // Clear focus
}

interface ProjectFocusResult {
  focused: boolean;
  project?: {
    id: string;
    name: string;
  };
  issue?: {
    id: string;
    title: string;
  };
  contextInjected: boolean;        // Whether context was added to session
}
```

**Behavior:**
- When focused, inject project/issue context into system prompt
- Filter beads queries to focused project
- Persist focus across session compaction

#### `project_plan`

Continue or refine project planning.

```typescript
interface ProjectPlanArgs {
  projectId?: string;              // Project ID (default: focused)
  phase?: "discovery" | "refinement" | "breakdown";
  focus?: string;                  // Specific area to focus on
}
```

**Behavior:**
1. Load existing planning artifacts
2. Resume conversational interview if incomplete
3. Delegate to specialized agents as needed:
   - `roadmap-builder` for strategic planning
   - `project-planner` for scope/resource planning
   - `task-planner` for issue breakdown
4. Update beads with new/refined issues
5. Persist artifacts incrementally

#### `project_close`

Close a project (mark complete or archive).

```typescript
interface ProjectCloseArgs {
  projectId: string;
  reason?: "completed" | "cancelled" | "archived";
  summary?: string;                // Final summary
}
```

### Issue Management

#### `issue_create`

Create a beads issue within a project.

```typescript
interface IssueCreateArgs {
  projectId?: string;              // Project ID (default: focused)
  title: string;
  description?: string;
  priority?: 0 | 1 | 2 | 3;        // P0-P3
  parent?: string;                 // Parent issue ID for hierarchy
  blockedBy?: string[];            // Dependency links
  labels?: string[];
}

interface IssueCreateResult {
  issueId: string;                 // e.g., "bd-a3f8" or "bd-a3f8.1"
  message: string;
}
```

#### `issue_claim`

Claim an issue and optionally start work in an isolated worktree.

```typescript
interface IssueClaimArgs {
  issueId: string;
  isolate?: boolean;               // Create worktree/workspace (default: false)
  delegate?: boolean;              // Delegate to background agent (default: false)
  agent?: string;                  // Agent for delegation (default: "coder")
}

interface IssueClaimResult {
  issueId: string;
  status: "claimed" | "delegated";
  worktree?: {
    path: string;
    branch: string;
  };
  delegationId?: string;           // If delegated
}
```

**Behavior:**
1. Run `bd update <id> --claim`
2. If `isolate=true`:
   - Detect VCS (jj or git)
   - Create worktree/workspace: `git worktree add` or `jj workspace add`
   - Branch name: `<project-id>/<issue-id>`
3. If `delegate=true`:
   - Create background delegation with issue context
   - Agent works in isolated worktree
   - Notify parent on completion

---

## Agents

### Hybrid Agent Strategy

The plugin defines custom agents that delegate to existing specialized agents for specific tasks.

#### `project-orchestrator`

Main planning orchestrator that coordinates the planning workflow.

```yaml
name: project-orchestrator
description: Orchestrates project planning and coordinates specialized agents
mode: all  # Can be invoked directly or as subagent

system_prompt: |
  You are a project planning orchestrator. Your role is to:
  1. Guide users through conversational project discovery
  2. Delegate specialized work to appropriate subagents
  3. Synthesize findings into actionable project plans
  4. Maintain project artifacts and beads issues
  
  Available subagents for delegation:
  - roadmap-builder: Strategic planning, OKR alignment, multi-quarter planning
  - project-planner: Scope definition, resource planning, risk assessment  
  - task-planner: User story creation, acceptance criteria, sprint planning
  - codebase-analyst: Technical context gathering, architecture discovery
  - researcher: External research, best practices, technology evaluation
  
  Always persist findings incrementally. Use beads for issue tracking.
```

#### `project-researcher`

Read-only research agent for background information gathering.

```yaml
name: project-researcher
description: Gathers research for project planning decisions
mode: subagent

permissions:
  edit: deny
  write: deny
  bash:
    "*": deny
    "bd *": allow      # Allow beads commands
    "curl *": allow    # Allow web fetching
    "jj log *": allow  # Allow VCS inspection
    "git log *": allow

system_prompt: |
  You are a research specialist supporting project planning.
  Your outputs will be persisted to the project's research directory.
  
  Focus on:
  - Technology evaluation and comparisons
  - Best practices and patterns
  - Risk identification
  - Dependency analysis
  
  Structure your findings with clear sections and actionable recommendations.
```

---

## Events & Hooks

### Event Subscriptions

```typescript
// Session idle - check for completed delegations
"session.idle": async (sessionID) => {
  // Check if any project delegations completed
  // Notify parent with results
}

// Tool execution - inject project context
"tool.execute.before": async (input, output) => {
  // If focused on project, inject context into relevant tools
}

// Session compacting - preserve project context
"experimental.session.compacting": async (input, output) => {
  // Inject focused project/issue context
  // Include recent beads activity
  // List pending delegations
}

// System prompt transform - add project rules
"experimental.chat.system.transform": async (input, output) => {
  // Inject project management rules
  // Add focused project context
}
```

### Shell Environment

```typescript
"shell.env": async (input, output) => {
  // Inject project-related env vars
  output.env.OPENCODE_PROJECT_ID = focusedProjectId
  output.env.OPENCODE_ISSUE_ID = focusedIssueId
  output.env.BEADS_DIR = beadsPath
}
```

---

## Worktree/Workspace Management

### VCS Detection

```typescript
async function detectVCS(directory: string): Promise<"jj" | "git" | null> {
  // Check for .jj first (preferred)
  if (await exists(path.join(directory, ".jj"))) return "jj"
  if (await exists(path.join(directory, ".git"))) return "git"
  return null
}
```

### Worktree Operations

```typescript
interface WorktreeManager {
  // Create isolated worktree for issue work
  create(issueId: string, baseBranch?: string): Promise<WorktreeInfo>
  
  // List active worktrees for project
  list(projectId: string): Promise<WorktreeInfo[]>
  
  // Merge worktree back to parent
  merge(worktreePath: string, strategy?: "merge" | "rebase"): Promise<void>
  
  // Cleanup worktree after merge
  cleanup(worktreePath: string): Promise<void>
}

interface WorktreeInfo {
  path: string
  branch: string
  issueId: string
  vcs: "git" | "jj"
  status: "active" | "merged" | "abandoned"
}
```

### Git Worktree Commands

```bash
# Create worktree
git worktree add -b <project>/<issue> ../<repo>-worktrees/<issue> <base-branch>

# List worktrees
git worktree list --porcelain

# Remove worktree
git worktree remove ../<repo>-worktrees/<issue>
```

### Jujutsu Workspace Commands

```bash
# Create workspace
jj workspace add --name <issue> ../<repo>-workspaces/<issue>

# List workspaces
jj workspace list

# Remove workspace
jj workspace forget <issue>
```

---

## Background Delegation

### Dispatcher Abstraction

Building on the `opencode-background-agents` pattern, but scoped to project work:

```typescript
interface ProjectDispatcher {
  // Delegate issue work to background agent
  delegateIssue(args: {
    issueId: string
    agent: string
    prompt?: string           // Additional instructions
    isolate?: boolean         // Use worktree
  }): Promise<DelegationInfo>
  
  // Check delegation status
  getStatus(delegationId: string): Promise<DelegationStatus>
  
  // Get delegation result
  getResult(delegationId: string): Promise<string>
  
  // List active delegations for project
  listActive(projectId: string): Promise<DelegationInfo[]>
}
```

### Delegation Flow

```
1. User: issue_claim(issueId, delegate=true, isolate=true)
2. Plugin:
   a. Claim issue in beads
   b. Create worktree/workspace
   c. Spawn background session with:
      - Issue context from beads
      - Project context
      - Worktree as working directory
3. Background agent works in isolation
4. On completion:
   a. Persist results to research/<issue-id>.md
   b. Update beads issue status
   c. Notify parent session
5. Parent agent:
   a. Reviews work
   b. Merges worktree (or requests changes)
   c. Cleanup worktree
```

---

## Planning Artifacts

### Long-Horizon Projects (6+ months)

Generated artifacts in `<project>/.projects/<id>/plans/`:

1. **roadmap.md** - High-level milestones and timeline
   - Quarterly breakdown
   - Key deliverables per phase
   - Dependencies between phases

2. **success-criteria.md** - Measurable outcomes
   - KPIs and metrics
   - Acceptance criteria
   - Definition of done

3. **architecture.md** - Technical design decisions
   - System overview
   - Key components
   - Integration points
   - Technology choices

4. **risks.md** - Risk assessment
   - Identified risks
   - Impact/probability matrix
   - Mitigation strategies

5. **resources.md** - Resource plan
   - Skills required
   - Tools and infrastructure
   - External dependencies

### Short-Term Projects (0-3 months)

Same artifacts but with implementation focus:

1. **roadmap.md** - Sprint/iteration breakdown
2. **success-criteria.md** - Detailed acceptance criteria
3. **architecture.md** - Technical design with implementation details
4. **risks.md** - Technical risks and blockers
5. **resources.md** - Immediate dependencies

### Interview Transcripts

Persisted in `<project>/.projects/<id>/interviews/`:

```markdown
# Planning Interview - <session-id>

**Date**: 2026-02-17
**Phase**: Discovery
**Status**: In Progress | Complete

## Context
<Initial context provided>

## Exchanges

### Q1: <Question>
**Response**: <User response>
**Insights**: <Extracted insights>

### Q2: <Question>
...

## Summary
<Generated summary of key decisions and findings>

## Next Steps
- [ ] <Action item>
- [ ] <Action item>
```

---

## Implementation Phases

### Phase 1: Foundation (MVP)
- [ ] Project structure and configuration
- [ ] Beads integration (auto-detect, init, basic commands)
- [ ] Core tools: `project_create`, `project_list`, `project_status`
- [ ] Focus mode with context injection
- [ ] Basic planning interview flow

### Phase 2: Planning
- [ ] Full conversational interview system
- [ ] Artifact generation (roadmap, risks, etc.)
- [ ] Integration with existing planning agents
- [ ] `project_plan` tool with phase support

### Phase 3: Execution
- [ ] Worktree/workspace management
- [ ] Background delegation for issues
- [ ] `issue_create`, `issue_claim` tools
- [ ] Merge workflow

### Phase 4: Polish
- [ ] Dependency visualization
- [ ] Session compaction hooks
- [ ] Configuration validation
- [ ] Error handling and recovery

---

## Dependencies

### Required
- `beads` (`bd` CLI) - Issue tracking
- `@opencode-ai/plugin` - Plugin types
- `@opencode-ai/sdk` - OpenCode SDK

### Optional
- `unique-names-generator` - Readable IDs for delegations

---

## Open Questions

1. **Beads initialization**: Should we auto-run `bd init` or require user to do it?
   - Recommendation: Auto-init with `--stealth` for non-repo projects

2. **Interview resumption**: How to handle interrupted interviews across sessions?
   - Recommendation: Persist state to interview file, detect and offer resume

3. **Worktree naming**: Convention for worktree paths?
   - Recommendation: `../<repo>-worktrees/<issue-id>/`

4. **Conflict resolution**: What if beads and plugin state diverge?
   - Recommendation: Beads is always truth, plugin re-syncs on load
