# Agent Instructions

## Architecture Overview

### Key Abstractions

```
src/
├── index.ts              # Plugin entry point and hook registration
├── agents/               # Agent selection and small model integration
├── config/               # Configuration loading and validation
├── execution/            # Delegation and team management
├── issues/               # Issue storage abstraction
├── planning/             # Planning session management
├── projects/             # Project and focus management
├── tools/                # OpenCode tool implementations
├── utils/                # Shared utilities
│   ├── errors/           # Error types and formatting
│   ├── logging/          # Logger abstraction
│   ├── opencode-sdk/     # SDK type definitions
│   ├── prompts/          # Prompt building utilities
│   ├── result/           # Result type for error handling
│   ├── shell/            # Shell command execution
│   ├── testing/          # Test utilities
│   └── validation/       # Input validation with Zod
└── vcs/                  # Version control abstraction (jj, git)
```

### Core Components

| Component | Purpose |
|-----------|---------|
| `ProjectManager` | Central orchestrator for project lifecycle, issue management, and coordination |
| `FocusManager` | Tracks current project and issue context |
| `IssueStorage` | Interface for issue persistence |
| `DelegationManager` | Manages background agent delegations |
| `TeamManager` | Coordinates multi-agent team work |
| `WorktreeManager` | VCS-agnostic worktree operations |
| `VCSAdapter` | Interface for jj/git operations |
| `PlanningManager` | Manages planning session state and phases |

### Data Flow

```
User Request → Tool → ProjectManager → Storage/VCS/Delegation
                                    ↓
                              System Prompts ← Focus Context
```

---

## Development

### Prerequisites

This project uses Bun for building and testing.

### Building

```bash
bun install
bun run build
```

### Type Checking

```bash
bun run typecheck
```

### Linting

```bash
bun run lint
```

### Running Unit Tests

```bash
bun test
```

To run a specific test file:

```bash
bun test src/tools/project-create.test.ts
```

To run tests matching a pattern:

```bash
bun test --test-name-pattern 'should create'
```

---

## Code Style Guidelines

### Module Imports

Cross-module imports must use the module's `index.ts` barrel export, not internal files:

```typescript
// ✅ Correct - import from module's index.ts
import { ArtifactRegistry } from "../artifacts/index.js"
import { DelegationManager, TeamManager } from "../execution/index.js"

// ❌ Wrong - import from internal file
import { ArtifactRegistry } from "../artifacts/artifact-registry.js"
import { DelegationManager } from "../execution/delegation-manager.js"
```

Within-module imports (same directory or subdirectory) may reference internal files directly.

### Result Type for Error Handling

Use the `Result<T, E>` type instead of throwing exceptions:

```typescript
import { ok, err, type Result } from "../utils/result/index.js"

async function doSomething(): Promise<Result<string, MyError>> {
  if (failed) {
    return err({ type: "operation_failed", message: "..." })
  }
  return ok("success")
}

// Consuming results
const result = await doSomething()
if (!result.ok) {
  return formatError(result.error)
}
const value = result.value
```

### Error Types

Define discriminated union error types for type-safe error handling:

```typescript
export type MyError =
  | { type: "not_found"; id: string }
  | { type: "validation_failed"; field: string; message: string }
  | { type: "timeout"; timeoutMs: number }
```

### Tool Implementation Pattern

Tools follow a consistent pattern:

```typescript
import { tool } from "@opencode-ai/plugin"
import { formatError } from "../utils/errors/index.js"
import { validateToolArgs, formatValidationError } from "../utils/validation/index.js"

export function createMyTool(manager: Manager, log: Logger): Tool {
  return tool({
    description: `Tool description with usage guidance.`,
    
    args: {
      required: tool.schema.string().describe("Required parameter"),
      optional: tool.schema.string().optional().describe("Optional parameter"),
    },

    async execute(args: unknown, _ctx: ToolContext): Promise<string> {
      // 1. Validate input
      const validationResult = validateToolArgs(MyArgsSchema, args)
      if (!validationResult.ok) {
        return formatValidationError(validationResult.error)
      }
      
      // 2. Execute operation
      const result = await manager.doOperation(validationResult.value)
      
      // 3. Handle errors
      if (!result.ok) {
        return formatError(result.error)
      }
      
      // 4. Format success response
      return formatSuccess(result.value)
    },
  })
}
```

### Input Validation with Zod

Define schemas in `src/utils/validation/input-schemas.ts`:

```typescript
import { z } from "zod"

export const MyArgsSchema = z.object({
  required: z.string().min(1),
  optional: z.string().optional(),
})

export type MyArgs = z.infer<typeof MyArgsSchema>
```

### Interface-Based Abstractions

Use interfaces for extensibility:

```typescript
// Define the interface
export interface IssueStorage {
  createIssue(dir: string, title: string): Promise<Result<string, IssueStorageError>>
  // ...
}

// Implement for different backends
export class MyIssueStorage implements IssueStorage { ... }
```

### Type Organization

Do not create separate `types.ts` files. Types should be co-located with their implementation or exported from the module's `index.ts`.

```typescript
// ❌ Bad - separate types file
// src/execution/types.ts
export type TeamMemberRole = "primary" | "secondary" | "devilsAdvocate"

// ✅ Good - types co-located with implementation
// src/execution/delegation-manager.ts
export type TeamMemberRole = "primary" | "secondary" | "devilsAdvocate"

export interface Delegation {
  role: TeamMemberRole
  // ...
}
```

### Comments and Documentation

**Inline comments** should only explain *why* or *how* something works when it is non-obvious. Never write comments that describe what the code is doing - the code itself should be clear enough.

```typescript
// ❌ Bad - restates what the code does
const name = issueId.replace(/[^a-zA-Z0-9]/g, "-") // Replace non-alphanumeric chars with dashes

// ✅ Good - explains why
const name = issueId.replace(/[^a-zA-Z0-9]/g, "-") // Sanitize for use as a filesystem path component
```

**JSDoc comments** follow the same principle - explain *why* or *how*, not *what* - but must be present on **all** exported types, fields, and functions, even if brief:

```typescript
// ❌ Bad - missing JSDoc on exported type
export type DelegationStatus = "pending" | "running" | "completed" | "failed"

// ✅ Good - explains the lifecycle
/**
 * Lifecycle states for a delegation. Terminal states (completed, failed, timeout,
 * cancelled) trigger pruning from memory after the configured retention limit.
 */
export type DelegationStatus = "pending" | "running" | "completed" | "failed" | "timeout" | "cancelled"

// ❌ Bad - JSDoc that just restates the name
/**
 * Creates an issue.
 */
async createIssue(dir: string, title: string): Promise<Result<string, IssueStorageError>>

// ✅ Good - explains what callers need to know
/**
 * Creates a new issue in the given project directory.
 * Returns the new issue ID on success, or a storage error if the backend is unavailable.
 */
async createIssue(dir: string, title: string): Promise<Result<string, IssueStorageError>>
```

### Logging

Use the logger abstraction:

```typescript
const log = createLogger(client)
await log.info("Operation started")
await log.warn("Something unexpected")
await log.error("Operation failed", error)
```

---

## Testing Strategy

### Unit Tests

Unit tests live alongside source files with `.test.ts` suffix:

```
src/
├── utils/
│   ├── result/
│   │   ├── result.ts
│   │   └── result.test.ts
│   └── shell/
│       ├── shell.ts
│       └── shell.test.ts
```

### Test Patterns

```typescript
import { describe, it, expect, beforeEach, mock } from "bun:test"

describe("ComponentName", () => {
  describe("methodName", () => {
    it("should do expected behavior", () => {
      // Arrange
      const input = createTestInput()
      
      // Act
      const result = component.method(input)
      
      // Assert
      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(result.value).toEqual(expected)
      }
    })

    it("should handle error case", () => {
      const result = component.method(invalidInput)
      expect(result.ok).toBe(false)
      if (!result.ok) {
        expect(result.error.type).toBe("expected_error_type")
      }
    })
  })
})
```

### Test Utilities

Use `src/utils/testing/test-utils.ts` for common test helpers:

```typescript
import { createMockLogger, createMockShell } from "../utils/testing/index.js"

const log = createMockLogger()
const $ = createMockShell()
```

### Integration Testing with OpenCode

To test the plugin with a live OpenCode instance:

1. **Create a test directory:**

```bash
mkdir -p /tmp/opencode-test
cd /tmp/opencode-test
jj git init  # or: git init
echo "# Test" > README.md
```

2. **Run OpenCode with a test prompt:**

```bash
cd /tmp/opencode-test
opencode run "Use project-list to list all projects"
```

3. **Test specific functionality:**

**CRITICAL**: when testing project-work-on-issue, ensure it is run with `foreground=true` so results are returned inline rather than as a background delegation notification.
**CRITICAL**: when creating a project, ensure it is run with `storage=local` to avoid polluting global storage (`~/.local/share/opencode/projects/`) with test projects.

```bash
# Test project creation
opencode run "Create a project called 'test-proj' with description 'Testing' with storage='local'"

# Test issue creation (replace project ID with actual)
opencode run "Focus on project test-proj-XXXXX and create an issue titled 'Test issue'"

# Test research task (no isolation - runs in repo root)
opencode run "Focus on project test-proj-XXXXX and work on issue test-proj-XXXXX.1"

# Test code task (with isolation - creates worktree)
opencode run "Focus on project test-proj-XXXXX and work on issue test-proj-XXXXX.2 with isolate=true"

# Test planning workflow
opencode run "Focus on project test-proj-XXXXX and start planning"
opencode run "Focus on project test-proj-XXXXX and advance planning to the next phase"
```

4. **Check delegation results:**

```bash
# View delegation status
cat /tmp/opencode-test/delegations/*.json

# View delegation result markdown
cat /tmp/opencode-test/delegations/*.md

# Check worktree contents
ls -la /tmp/opencode-test-worktrees/
```

5. **Clean up between tests:**

```bash
rm -rf /tmp/opencode-test/delegations /tmp/opencode-test-worktrees /tmp/opencode-test/.projects
```

---

## Debugging

### Plugin Logs

To see plugin logs, check the OpenCode log files:

```bash
find ~/.local/share/opencode -name "*.log" -mmin -5 | xargs cat | grep -i "delegation\|project"
```

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| "No project focused" | Missing project context | Use `project-focus(projectId)` first |
| "Validation error" | Invalid tool arguments | Check argument types and required fields |
| "VCS not detected" | Not in a jj/git repo | Initialize a repository first |

### Debugging Result Errors

When a Result fails, check the error type:

```typescript
const result = await operation()
if (!result.ok) {
  console.log("Error type:", result.error.type)
  console.log("Error details:", result.error)
}
```

---

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until work has been committed and you are on a new, empty revision.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items

4. **Clean up** - Remove any temporary files or worktrees
5. **Verify** - All changes committed AND a new, empty revision is on the stack
6. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until work has been committed and you are on a new, empty revision.

---

## Key Files Reference

| File | Purpose |
|------|---------|
| `src/index.ts` | Plugin entry point, hook registration |
| `src/tools/tools.ts` | Tool type definitions |
| `src/issues/issue-storage.ts` | IssueStorage interface |
| `src/vcs/adapter.ts` | VCSAdapter interface |
| `src/utils/result/result.ts` | Result type implementation |
| `src/utils/errors/errors.ts` | Error types and formatting |
| `src/utils/validation/input-schemas.ts` | Zod validation schemas |
| `src/config/config-schema.ts` | Configuration schema |
| `docs/architecture.md` | Detailed architecture documentation |
| `docs/tools.md` | Tool reference documentation |
| `docs/workflows.md` | Usage workflow examples |
