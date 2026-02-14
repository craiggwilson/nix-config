# OpenCode Planning & Execution Plugin Suite - Quick Start

Get up and running with the planning and execution plugins in 5 minutes.

## Installation

### 1. Build the Plugins

```bash
cd hdwlinux/packages/opencode
bun run build
```

### 2. Link to OpenCode

```bash
opencode plugin link ./program-planner/dist
opencode plugin link ./project-planner/dist
opencode plugin link ./work-executor/dist
```

### 3. Verify Installation

```bash
opencode plugin list
```

You should see all three plugins listed.

Note: In the 0.1.x series the commands described below are wired up to orchestrators, but many operations still use placeholder implementations (for example, automatic decomposition, sprint planning, and subagent-driven execution). Treat this quick start as a guide to the intended workflow while building out full behavior.

## Your First Program

### Step 1: Create a Program

```bash
/program-new
```

Follow the prompts:
- **Name**: "My First Program"
- **Summary**: "A test program to learn the system"
- **Horizon**: "quarter"
- **Goals**: "Learn the system", "Create a working example"
- **Non-Goals**: "Production deployment"
- **Metrics**: "Completion percentage"
- **Constraints**: "Learning exercise"

This creates a beads epic with label `program:my-first-program`.

### Step 2: Plan the Program

```bash
/program-plan PROG-123 my-service
```

(Replace PROG-123 with the actual program ID from step 1)

This creates a project epic for your service.

### Step 3: Initialize a Project

```bash
/project-init my-service "My Service" PROG-123
```

This creates a project epic for your service.

### Step 4: Plan the Project

```bash
/project-plan PROJ-456
```

(Replace PROJ-456 with the actual project ID from step 3)

This creates backlog items for your project.

### Step 5: Check Status

```bash
/program-status PROG-123
/project-status PROJ-456
```

You should see:
- Program progress
- Project progress
- Backlog status

## Your First Task

### Step 1: Get Focus

```bash
/project-focus PROJ-456
```

This shows ready tasks you can work on.

### Step 2: Claim Work

```bash
/work-claim
```

This claims the highest-priority ready task.

### Step 3: Execute Work

```bash
/work-execute TASK-001
```

(Replace TASK-001 with the actual task ID)

This runs the full execution pipeline:
- Analyze requirements
- Design solution
- Implement code
- Run tests
- Code review
- Security review

### Step 4: Check Status

```bash
/project-status PROJ-456
```

You should see the task marked as done.

## Common Commands

### Program Management

```bash
# List all programs
/program-list

# Get program status
/program-status PROG-123

# Rebalance priorities
/program-rebalance
```

### Project Management

```bash
# List all projects
/project-list

# Get project status
/project-status PROJ-456

# Plan a sprint
/project-sprint PROJ-456 "Sprint 1" 2026-02-17 2026-03-02 20

# Get focus items
/project-focus PROJ-456
```

### Work Execution

```bash
# Claim a task
/work-claim

# Execute a task
/work-execute TASK-001

# Perform research
/work-research TASK-002

# Create a POC
/work-poc TASK-003

# Review code
/work-review TASK-001 code-review
```

## Understanding the Structure

### Programs

Programs are long-term initiatives (quarters, half-years):
- Represent strategic goals
- Decompose into project epics
- Track cross-project dependencies
- Managed by program planner

### Projects

Projects are repo/service-level work:
- Represent concrete deliverables
- Decompose into backlog items
- Track sprints and iterations
- Managed by project planner

### Work Items

Work items are specific tasks:
- Features, tasks, chores, bugs
- Can be research, POC, or implementation
- Tracked through execution pipeline
- Managed by work executor

### Beads

All state is stored in beads:
- Programs are `epic` issues with label `program`
- Projects are `epic` issues with label `project`
- Work items are `task`, `feature`, `chore`, or `bug` issues
- Dependencies are tracked via beads dependencies

## Tips

1. **Start small**: Create one program, one project, one task
2. **Use labels**: Organize with hierarchical labels (e.g., `program:my-program`)
3. **Check status regularly**: Use `/program-status` and `/project-status`
4. **Leverage subagents**: Let domain experts design and review
5. **Document findings**: Use external docs for rich details

## Next Steps

1. Read [SPEC.md](SPEC.md) for complete documentation
2. Review [EXAMPLES.md](EXAMPLES.md) for more use cases
3. Check [DEPLOYMENT.md](DEPLOYMENT.md) for production setup
4. Explore [IMPLEMENTATION.md](IMPLEMENTATION.md) for architecture details

## Troubleshooting

### Commands Not Found

Make sure plugins are linked:
```bash
opencode plugin list
```

### Beads Issues Not Showing

Verify beads is working:
```bash
bd list
```

### Configuration Issues

Check configuration:
```bash
cat ~/.config/opencode/plugins/program-planner.json
```

## Getting Help

- Check the documentation files (SPEC.md, EXAMPLES.md, etc.)
- Review the AGENTS.md files for each plugin
- Check OpenCode logs: `opencode logs`
- Open an issue on GitHub

## What's Next?

Once you're comfortable with the basics:

1. **Create multiple programs** for different initiatives
2. **Plan sprints** for your projects
3. **Execute work** through the full pipeline
4. **Review code and security** with the review agents
5. **Track discovered work** as you implement

Happy planning and executing!
