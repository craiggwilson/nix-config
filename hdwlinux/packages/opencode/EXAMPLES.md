# OpenCode Planning & Execution Plugin Suite - Examples

This document provides practical examples of how to use the planning and execution plugins.

These examples describe the target behavior of the suite. As of version 0.1.x, some flows still rely on placeholder implementations for beads integration, automatic decomposition, and subagent coordination.

## Program Planner Examples

### Create a New Program

```bash
/program-new
```

This will prompt you for:
- Program name: "Platform Modernization"
- Summary: "Modernize our infrastructure and improve developer experience"
- Horizon: "quarter"
- Goals: "Reduce deployment time by 50%", "Improve system reliability"
- Non-goals: "Rewrite all services"
- Metrics: "Deployment time", "System uptime"
- Constraints: "Budget: $100k", "Timeline: 3 months"

Creates a beads epic with label `program:platform-modernization`.

### Plan a Program

```bash
/program-plan PROG-123 service-a service-b service-c
```

Decomposes the program into project epics for each service:
- Creates `PROJ-456` for service-a
- Creates `PROJ-457` for service-b
- Creates `PROJ-458` for service-c
- Links them as children of the program

### Check Program Status

```bash
/program-status PROG-123
```

Output:
```
Program: Platform Modernization
Status: in_progress
Progress: 45%
Projects: 2/4 done
```

Or list all programs:

```bash
/program-status
```

Output:
```
Found 3 programs:
  - Platform Modernization: 45% complete
  - Security Hardening: 20% complete
  - API Redesign: 80% complete
```

### Rebalance Program Priorities

```bash
/program-rebalance
```

Output:
```
Suggested 2 priority adjustments:
  - PROG-123: 1 → 0 (3 blocked items)
  - PROG-124: 2 → 3 (80% complete)
```

## Project Planner Examples

### Initialize a Project

```bash
/project-init my-service "My Service Project" PROG-123
```

Creates a project epic for the service:
- Title: "My Service Project"
- Labels: `project`, `project:my-service-project`, `repo:my-service`, `program:PROG-123`
- Parent: PROG-123

### Plan a Project

```bash
/project-plan PROJ-456
```

Decomposes the project into backlog items:
- Creates features, tasks, and chores
- Assigns priorities
- Creates dependencies

Output:
```
Created 8 backlog items
Created items: FEAT-001, TASK-002, TASK-003, CHORE-004, ...
```

### Plan a Sprint

```bash
/project-sprint PROJ-456 "Sprint 1" 2026-02-17 2026-03-02 20
```

Creates a sprint with:
- Name: "Sprint 1"
- Duration: 2 weeks
- Capacity: 20 story points
- Selects ready items based on priority and dependencies

Output:
```
Created sprint: Sprint 1
Capacity: 75% utilized
```

### Check Project Status

```bash
/project-status PROJ-456
```

Output:
```
Project: My Service Project
Repository: my-service
Status: in_progress
Progress: 35%
Backlog: 3/8 done
```

### Get Project Focus

```bash
/project-focus PROJ-456
```

Output:
```
Found 3 ready items
  - Setup database schema (TASK-002)
  - Implement API endpoints (FEAT-001)
  - Write integration tests (TASK-003)

Suggested next: TASK-002
```

## Work Executor Examples

### Claim a Ready Task

```bash
/work-claim
```

Finds the highest-priority ready task and claims it:

Output:
```
Claimed work item: Setup database schema (TASK-002)
```

### Execute a Task

```bash
/work-execute TASK-002
```

Runs the full execution pipeline:
1. Analyze requirements
2. Design solution
3. Implement code
4. Run tests
5. Code review
6. Security review
7. Mark done

Output:
```
Executed 1 work items
  - TASK-002: completed
```

### Execute with Specific Mode

```bash
/work-execute TASK-002 --mode research-only
```

Runs only the research phase:
- Investigates the task
- Produces a recommendation
- Creates follow-up tasks if needed

### Perform Research

```bash
/work-research TASK-003
```

Investigates a topic and produces a report:

Output:
```
Research Question: What database should we use?
Summary: Evaluated PostgreSQL, MongoDB, and DynamoDB
Recommendation: Use PostgreSQL for ACID compliance
```

### Create and Execute a POC

```bash
/work-poc TASK-004 PROJ-456
```

Creates a proof-of-concept:
1. Clarifies hypothesis
2. Minimal design
3. Quick implementation
4. Validation
5. Recommendation (Keep/Refine/Discard)

Output:
```
POC Result: keep
Findings: Approach works well, minimal performance impact
Recommendation: Proceed with full implementation
```

### Perform Code Review

```bash
/work-review TASK-002 code-review
```

Reviews code for correctness and style:

Output:
```
Review Mode: code-review
Findings: 3
Summary: Good implementation, minor style issues
```

### Perform Security Review

```bash
/work-review TASK-002 security-review
```

Reviews code for security vulnerabilities:

Output:
```
Review Mode: security-review
Findings: 1
Summary: Input validation needed on API endpoint
```

## Workflow Examples

### Complete Workflow: From Program to Implementation

1. **Create a program**
   ```bash
   /program-new
   # Creates PROG-123: "API Redesign"
   ```

2. **Plan the program**
   ```bash
   /program-plan PROG-123 api-service web-service mobile-service
   # Creates PROJ-456, PROJ-457, PROJ-458
   ```

3. **Initialize a project**
   ```bash
   /project-init api-service "API Service" PROG-123
   # Creates PROJ-456
   ```

4. **Plan the project**
   ```bash
   /project-plan PROJ-456
   # Creates backlog items
   ```

5. **Plan a sprint**
   ```bash
   /project-sprint PROJ-456 "Sprint 1" 2026-02-17 2026-03-02 20
   # Selects items for the sprint
   ```

6. **Get focus**
   ```bash
   /project-focus PROJ-456
   # Shows ready items
   ```

7. **Claim and execute work**
   ```bash
   /work-claim
   # Claims TASK-001
   
   /work-execute TASK-001
   # Executes the task through all phases
   ```

8. **Check status**
   ```bash
   /program-status PROG-123
   # Shows overall program progress
   
   /project-status PROJ-456
   # Shows project progress
   ```

### Research-Driven Workflow

1. **Create a research task**
   ```bash
   /project-plan PROJ-456
   # Creates TASK-001: "Evaluate caching strategies"
   ```

2. **Perform research**
   ```bash
   /work-research TASK-001
   # Investigates options and produces recommendation
   ```

3. **Create follow-up tasks**
   - If research recommends Redis: Create TASK-002 "Implement Redis caching"
   - If research recommends in-memory: Create TASK-003 "Implement in-memory cache"

4. **Execute follow-up tasks**
   ```bash
   /work-execute TASK-002
   # Implements the chosen solution
   ```

### POC-Driven Workflow

1. **Create a POC task**
   ```bash
   /project-plan PROJ-456
   # Creates TASK-001: "POC: GraphQL migration"
   ```

2. **Execute POC**
   ```bash
   /work-poc TASK-001 PROJ-456
   # Creates minimal GraphQL implementation
   ```

3. **Based on POC outcome**
   - If "keep": Create TASK-002 "Full GraphQL implementation"
   - If "refine": Create TASK-003 "Refine GraphQL approach"
   - If "discard": Archive and move to next task

## Configuration Examples

### Global Configuration

File: `~/.config/opencode/plugins/program-planner.json`

```json
{
  "defaultHorizon": "quarter",
  "autoCreateProjectEpics": true,
  "defaultLabels": ["program"],
  "charterDocLocation": "external"
}
```

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

File: `~/.config/opencode/plugins/work-executor.json`

```json
{
  "riskPosture": "high",
  "alwaysRunSecurityReview": true,
  "autonomousEditLimits": {
    "maxFilesPerCommit": 10,
    "requiresApprovalForPublicAPIs": true,
    "requiresApprovalForDependencyChanges": true
  },
  "techStackPreferences": {
    "defaultLanguage": "go",
    "preferredFrameworks": ["nix", "terraform"]
  }
}
```

### Per-Repo Configuration

File: `.beads/project-planner.json`

```json
{
  "sprintStyle": "epics",
  "defaultSprintLength": 1,
  "defaultSprintLengthUnit": "weeks"
}
```

File: `.beads/work-executor.json`

```json
{
  "language": "go",
  "domains": ["distributed-systems", "kafka"],
  "alwaysRunSecurityReview": true
}
```

## Tips and Best Practices

1. **Use hierarchical labels** for organization:
   - `program:platform-modernization`
   - `project:api-service`
   - `repo:my-service`

2. **Keep descriptions concise** in beads:
   - Use external docs for rich details
   - Link to Google Docs or `history/` files

3. **Create discovered work** during implementation:
   - Use `discovered-from:<parent-id>` dependencies
   - File bugs and chores as you find them

4. **Review regularly**:
   - Check program status weekly
   - Check project status before each sprint
   - Review work items before marking done

5. **Use POCs for uncertainty**:
   - Create POCs before major decisions
   - Use research tasks for investigation
   - Document findings for future reference

6. **Leverage subagents**:
   - Let domain experts design solutions
   - Use code reviewers for quality
   - Use security reviewers for safety
