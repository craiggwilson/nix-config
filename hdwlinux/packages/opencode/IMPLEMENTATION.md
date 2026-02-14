# OpenCode Planning & Execution Plugin Suite - Implementation Guide

This document describes the implementation status and next steps for the plugin suite.

## Current Status

### Completed

- ✅ Comprehensive SPEC.md with all plugin specifications
- ✅ AGENTS.md files for each plugin describing architecture
- ✅ TypeScript type definitions for all plugins
- ✅ Orchestrator scaffolding for all three plugins
- ✅ Core plugin interface and utilities
- ✅ Configuration management system
- ✅ Command handler stubs for all plugins

### In Progress

- 🔄 Implement command handlers with full logic
- 🔄 Implement beads integration
- 🔄 Implement subagent coordination
- 🔄 Create integration tests

### TODO

- ⏳ Implement research/POC/implementation pipelines
- ⏳ Implement code and security review agents
- ⏳ Create example usage and documentation
- ⏳ Performance optimization and caching
- ⏳ Error handling and recovery

## Architecture Overview

### Plugin Structure

```
opencode/
├── core/                    # Shared utilities
│   ├── src/
│   │   ├── config.ts       # Configuration management
│   │   ├── beads.ts        # Beads query helpers
│   │   ├── plugin.ts       # Plugin interface
│   │   └── index.ts
│   └── package.json
├── program-planner/         # Long-term planning
│   ├── src/
│   │   ├── orchestrator.ts  # Command handlers
│   │   ├── types.ts         # Type definitions
│   │   └── index.ts         # Plugin entry point
│   └── package.json
├── project-planner/         # Project-level planning
│   ├── src/
│   │   ├── orchestrator.ts
│   │   ├── types.ts
│   │   └── index.ts
│   └── package.json
├── work-executor/           # Work execution
│   ├── src/
│   │   ├── orchestrator.ts
│   │   ├── types.ts
│   │   └── index.ts
│   └── package.json
├── SPEC.md                  # Complete specification
├── README.md                # Overview
└── package.json             # Workspace root
```

## Implementation Phases

### Phase 1: Core Infrastructure (Current)

**Goal**: Get basic plugin loading and command routing working

**Tasks**:
1. ✅ Define plugin interface
2. ✅ Create orchestrator scaffolding
3. ✅ Implement configuration management
4. 🔄 Implement storage abstraction for issues (initially in-memory)
5. 🔄 Create basic command handlers

**Deliverable**: Plugins load and respond to commands (with TODO stubs)

### Phase 2: Storage Backend Integration (Beads via Tools)

**Goal**: Full read/write capability against a real backend (typically beads), without coupling orchestrators to a specific implementation.

**Tasks**:
1. Implement an `IssueStorage` backend that calls `opencode-beads` tools via the OpenCode SDK:
   - `query()` - Filter issues by labels, status, priority, etc.
   - `findReady()` - Find tasks with no blocking dependencies
   - `analyzeDependencies()` - Detect cycles, critical path, blockers
   - `getChildren()` - Get all child issues
   - `getDependencies()` - Get all dependencies
   - `createIssue()` - Create new issues
   - `updateIssue()` - Update existing issues
   - `createDependency()` - Create dependencies
   - `search()` - Search by title/description

2. Implement orchestrator methods (using the storage abstraction only):
   - Program planner: `createProgram()`, `planProgram()`, `getProgramStatus()`, etc.
   - Project planner: `initProject()`, `planProject()`, `planSprint()`, etc.
   - Work executor: `claimWork()`, `executeWork()`, `executeResearch()`, etc.

**Deliverable**: Full CRUD operations on beads issues

### Phase 3: Subagent Coordination

**Goal**: Orchestrators can spawn and coordinate subagents

**Tasks**:
1. Implement subagent selection logic
2. Create subagent invocation interface
3. Implement result aggregation
4. Handle subagent errors and retries

**Deliverable**: Orchestrators can delegate to specialized agents

### Phase 4: Execution Pipelines

**Goal**: Full research, POC, and implementation pipelines

**Tasks**:
1. Implement research pipeline
2. Implement POC pipeline
3. Implement implementation pipeline
4. Implement code review pipeline
5. Implement security review pipeline

**Deliverable**: End-to-end work execution

### Phase 5: Testing & Documentation

**Goal**: Comprehensive tests and examples

**Tasks**:
1. Create unit tests for each plugin
2. Create integration tests
3. Create example usage scenarios
4. Write deployment guide

**Deliverable**: Production-ready plugins

## Key Implementation Details

### Storage Abstraction and Beads Integration

All plugins use a storage abstraction focused on planning issues. The default implementation can be backed by beads via tools provided by the `opencode-beads` plugin.

```typescript
// Query issues
const issues = await storage.query({
  labels: ["program"],
  status: ["todo", "in_progress"],
  priority: [1, 2],
});

// Create issues
const issue = await storage.createIssue({
  type: "epic",
  title: "Platform Modernization",
  labels: ["program", "program:modernization"],
  priority: 1,
});

// Manage dependencies
await storage.createDependency("PROJ-123", "PROJ-456", "needs");
```

### Command Handling

Commands are routed through the TUI command hook:

```typescript
"tui.command.execute": async (input, output) => {
  const command = input.command;  // e.g., "program-new"
  const args = input.args || [];  // command arguments
  
  // Route to appropriate handler
  switch (command) {
    case "program-new":
      await orchestrator.handleProgramNew(args);
      output.handled = true;
      break;
  }
}
```

### Subagent Invocation

Orchestrators spawn subagents for specialized work:

```typescript
// Spawn a decomposer agent
const proposal = await spawnSubagent("program-decomposer-agent", {
  programDescription: program.description,
  existingProjectEpics: program.children,
  codebaseSummaries: repos
});

// Spawn a code reviewer
const review = await spawnSubagent("code-reviewer-agent", {
  issueId: workItem.id,
  changes: diff
});
```

### Configuration

Plugins support both global and per-repo configuration:

```json
// ~/.config/opencode/plugins/program-planner.json
{
  "defaultHorizon": "quarter",
  "autoCreateProjectEpics": true,
  "defaultLabels": ["program"],
  "charterDocLocation": "external"
}

// .beads/program-planner.json (per-repo override)
{
  "defaultHorizon": "month"
}
```

## Next Steps

1. **Implement IssueStorage methods** - Start with query and CRUD operations, then wire a real backend that calls `opencode-beads` tools via the OpenCode SDK
2. **Implement orchestrator methods** - Add full logic to command handlers
3. **Create integration tests** - Test plugin loading and command execution
4. **Implement subagent coordination** - Add subagent spawning and result handling
5. **Build execution pipelines** - Implement research, POC, and implementation workflows

## Testing Strategy

### Unit Tests

Test individual components:
- ConfigManager loading and merging
- IssueStorage query building
- Orchestrator command parsing
- Type validation

### Integration Tests

Test plugin interactions:
- Plugin loading and initialization
- Command routing and execution
- Beads read/write operations
- Subagent coordination

### End-to-End Tests

Test complete workflows:
- Create program → decompose → create projects → plan backlog → execute work
- Verify beads state at each step
- Verify discovered work creation
- Verify status aggregation

## Performance Considerations

- Cache beads queries to avoid repeated reads
- Batch dependency graph operations
- Lazy-load subagents only when needed
- Implement pagination for large result sets
- Use streaming for large file operations

## Security Considerations

- Validate all user input before beads operations
- Sanitize command arguments
- Restrict file operations to project directory
- Validate subagent responses
- Log all significant operations

## Future Extensions

- Calendar integration (Google Calendar, Outlook)
- Capacity planning and resource allocation
- Automated sprint planning
- Risk prediction and mitigation
- Integration with external project management tools
- Custom domain-specific subagents
- Performance analytics and reporting
