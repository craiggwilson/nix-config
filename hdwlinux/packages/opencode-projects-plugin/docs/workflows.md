# Workflows

## Creating and Planning a Project

### 1. Create the Project

```
project-create(name="auth-system", description="User authentication and authorization")
```

This creates:
- Project directory at `.projects/auth-system/`
- Root epic issue in beads
- Project metadata file

### 2. Start Planning

```
project-plan(action="start")
```

The planning session guides you through phases:
- **Discovery** - Understand the problem, stakeholders, timeline, constraints
- **Synthesis** - Consolidate research, make decisions, identify risks
- **Breakdown** - Create actionable issues in beads

### 3. Conduct Research During Planning

When you need to research something:

```
project-create-issue(title="Research: Authentication patterns for multi-tenant SaaS")
project-work-on-issue(issueId="auth-system.2")
```

This starts a background agent to research the topic. You'll be notified when complete.

### 4. Advance Through Phases

```
project-plan(action="advance")
```

Move from discovery → synthesis → breakdown → complete.

### 5. Save Progress

```
project-plan(action="save", understanding='{"problem": "...", "goals": ["..."]}')
```

Save accumulated understanding to resume later.

---

## Working on Issues

### 1. View Available Work

```
project-status()
```

Shows the issue tree with status icons:
- ⬜ Open
- 🔄 In Progress
- ✅ Completed
- ⏳ Blocked

### 2. Start Work on an Issue

**For research, analysis, or documentation (no code changes):**
```
project-work-on-issue(issueId="auth-system.2")
```

**For code changes (requires isolation):**
```
project-work-on-issue(issueId="auth-system.3", isolate=true)
```

This:
- Claims the issue (sets status to in_progress)
- Creates an isolated git worktree or jj workspace (if isolate=true)
- Delegates work to a background agent
- Returns immediately

You'll be notified via `<delegation-notification>` when the work completes.

### 3. Review and Merge Completed Work

When a delegation with `isolate=true` completes, the notification includes merge instructions.

**For jj:**
```bash
jj diff --from main --to <branch>     # Review
jj squash --from <branch>              # Merge
jj workspace forget <branch>           # Clean up
```

**For git:**
```bash
git diff main..<branch>                # Review
git merge <branch>                     # Merge
git worktree remove <path> && git branch -d <branch>  # Clean up
```

Then close the issue:
```
project-update-issue(issueId="auth-system.2", status="closed")
```

---

## Parallel Work

### Start Multiple Issues

```
project-work-on-issue(issueId="auth-system.2")                  # Research (no isolation)
project-work-on-issue(issueId="auth-system.3", isolate=true)    # Code changes (isolated)
project-work-on-issue(issueId="auth-system.4", isolate=true)    # Code changes (isolated)
```

Each issue runs with a background agent. Isolated issues get their own worktree.

### Monitor Progress

```
project-status()
```

Shows active delegations and their status.

### Retrieve Results After Compaction

If the session is compacted, use:

```
project-internal-delegation-read(id="del-abc123")
```

---

## Managing Dependencies

### Create Dependent Issues

```
project-create-issue(title="Implement login", blockedBy=["auth-system.1"])
project-create-issue(title="Implement logout", blockedBy=["auth-system.1"])
```

### View Dependency Tree

```
project-status()
```

Output:
```
├── ✅ auth-system.1: Design auth flow
│   ├── 🔄 auth-system.2: Implement login
│   └── ⬜ auth-system.3: Implement logout
```

### Unblock Issues

When you close a blocking issue, dependent issues become ready:

```
project-update-issue(issueId="auth-system.1", status="closed")
```

Now `auth-system.2` and `auth-system.3` are unblocked.

---

## Multi-Project Workflows

### Switch Between Projects

```
project-focus(projectId="other-project")
```

### View All Projects

```
project-list()
```

### Work Across Projects

Each project maintains its own:
- Issue tree
- Planning state
- Worktrees
- Delegation history
