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
│  Tool   │ ◄── project_create, issue_claim, etc.
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
