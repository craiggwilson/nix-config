# Architecture

## Module Structure

```
src/
├── index.ts              # Plugin entry point
├── core/                 # Core managers and types
├── storage/              # Issue storage abstraction
├── planning/             # Planning features
├── execution/            # Worktree and delegation
├── tools/                # OpenCode tool implementations
└── agents/               # Agent rules and prompts
```

## Core Module

### ProjectManager

Central orchestrator for all project operations.

**Responsibilities:**
- Project lifecycle (create, list, close)
- Issue management (create, update, claim)
- Focus management (project and issue context)
- Coordination with other managers

**Dependencies:**
- `IssueStorage` - Issue persistence
- `FocusManager` - Context tracking
- `ConfigManager` - Configuration
- `InterviewManager` - Planning interviews
- `ArtifactManager` - Planning artifacts
- `PlanningDelegator` - Agent delegation

### FocusManager

Tracks current project and issue context.

**State:**
- `projectId` - Currently focused project
- `issueId` - Currently focused issue

### ConfigManager

Loads and validates configuration.

**Features:**
- JSON configuration file support
- Default value merging
- Validation with error reporting

## Storage Module

### IssueStorage Interface

Abstraction for issue persistence.

**Implementations:**
- `BeadsIssueStorage` - Uses beads CLI
- `InMemoryIssueStorage` - For testing

**Operations:**
- CRUD for issues
- Dependency management
- Status tracking
- Delegation metadata

## Planning Module

### InterviewManager

Manages conversational planning sessions.

**Features:**
- Session persistence
- Context injection for continuity
- Export to markdown

### ArtifactManager

Generates planning artifacts.

**Artifact Types:**
- Roadmap
- Architecture
- Risks
- Success Criteria

### PlanningDelegator

Delegates to specialized agents.

**Features:**
- Dynamic agent discovery
- Keyword-based agent matching
- Context-aware prompts

## Execution Module

### VCSAdapter Interface

Abstraction for version control operations.

**Implementations:**
- `GitAdapter` - Git worktrees
- `JujutsuAdapter` - jj workspaces

**Operations:**
- Create/remove worktrees
- Merge with strategies
- Status queries

### WorktreeManager

High-level worktree operations.

**Features:**
- VCS auto-detection
- Project-scoped worktrees
- Merge and cleanup

### DelegationManager

Manages background agent delegations.

**Features:**
- Delegation lifecycle
- Result persistence
- Status tracking

## Data Flow

```
User Request
    │
    ▼
┌─────────┐
│  Tool   │ ◄── project-create, project-work-on-issue, etc.
└────┬────┘
     │
     ▼
┌─────────────────┐
│ ProjectManager  │ ◄── Orchestrates operations
└────────┬────────┘
         │
    ┌────┴────┬────────────┐
    ▼         ▼            ▼
┌───────┐ ┌────────┐ ┌──────────┐
│Storage│ │Planning│ │Execution │
└───────┘ └────────┘ └──────────┘
    │         │            │
    ▼         ▼            ▼
  beads   artifacts    worktrees
```

## System Prompt Integration

The plugin injects context into system prompts:

1. **PROJECT_RULES** - Agent instructions for project management
2. **VCS Context** - Git or jj command guidance
3. **Focus Context** - Current project/issue state

## Session Compaction

When sessions are compacted, the plugin preserves:
- Current project and issue focus
- Project progress summary
- Ready issues list
- Quick reference commands

## Small Model Integration

The plugin uses OpenCode's `small_model` configuration for intelligent decisions.

### Agent Selection

When delegating work, the plugin asks the small model to select the best agent:

1. **Planning delegations** - Selects based on planning phase and task description
2. **Issue work delegations** - Selects based on issue title and description
3. **Background task delegations** - Selects based on the delegation prompt

The small model receives:
- List of available agents with descriptions
- Task description and context
- Optional task type hint (planning, coding, research, review)

### Configuration

Requires `small_model` in OpenCode config. If not configured, the plugin falls back to letting OpenCode decide which agent to use.

### Timeout

All small model prompts have a 30-second timeout to prevent blocking. Sessions created for small model queries are cleaned up after use.

### Utilities

- `promptSmallModel<T>()` - Low-level utility for structured JSON responses
- `selectAgent()` - High-level agent selection with caching
- `discoverAgents()` - Cached agent discovery from SDK

## Background Delegations

The plugin supports true background delegation with fire-and-forget execution.

### How It Works

1. **Fire-and-Forget**: When a delegation is created, the prompt is sent without awaiting the response
2. **Session Idle Events**: Completion is detected via `session.idle` events
3. **Batched Notifications**: Multiple parallel delegations notify the parent when ALL complete
4. **Timeout Handling**: Delegations timeout after 15 minutes (configurable)

### Delegation Lifecycle

```
create() → status: "pending"
    ↓
startDelegation() → status: "running"
    ↓ (fire prompt, don't await)
    ↓
[session.idle event] → handleSessionIdle()
    ↓
complete() → status: "completed"
    ↓
notifyParent() → send <delegation-notification>
```

### Batched Notifications

When multiple delegations run for the same parent session:
- Individual completions send `noReply: true` (silent)
- When ALL complete, sends `noReply: false` (triggers response)
- Reduces noise while ensuring the agent knows when to continue

### Root Session Scoping

Delegations are scoped to the root session (top of the parent chain):
- Ensures visibility across the session tree
- Parent sessions can see child delegations
- Notifications go to the root session

### Disabled Tools

Delegated sessions cannot use state-modifying tools:
- `project-create`, `project-close`
- `project-create-issue`, `project-update-issue`, `project-work-on-issue`
- `task`, `delegate` (no recursive delegation)
- `todowrite`, `plan_save`

### Configuration

```json
{
  "delegation": {
    "timeoutMs": 900000  // 15 minutes (default)
  }
}
```

### Result Persistence

Delegation results are persisted to `{projectDir}/delegations/`:
- `{id}.json` - Structured delegation data
- `{id}.md` - Human-readable markdown with metadata and result

### Title/Description Generation

After completion, the small model generates:
- **Title**: 2-5 words summarizing the outcome
- **Description**: 2-3 sentences describing what was accomplished

Falls back to truncation if small model is unavailable.
