# Workflows

## Creating and Planning a Project

### 1. Create the Project

```
project_create(name="auth-system", description="User authentication and authorization")
```

This creates:
- Project directory at `.projects/auth-system/`
- Root epic issue in beads
- Project metadata file

### 2. Start Planning

```
project_plan(action="start", phase="discovery")
```

The planning interview will ask about:
- Vision and goals
- Key milestones
- Success criteria
- Risks and constraints

### 3. Generate Artifacts

After completing the interview, artifacts are generated:
- `plans/roadmap.md` - Timeline and milestones
- `plans/architecture.md` - Technical design
- `plans/risks.md` - Risk assessment
- `plans/success-criteria.md` - KPIs and metrics

### 4. Break Down into Issues

```
project_plan(action="start", phase="breakdown")
```

This creates issues from the roadmap with proper dependencies.

---

## Working on Issues

### 1. View Available Work

```
project_status()
```

Shows the issue tree with status icons:
- ⬜ Open
- 🔄 In Progress
- ✅ Completed
- ⏳ Blocked

### 2. Claim an Issue

```
issue_claim(issueId="auth-system.2")
```

This:
- Sets the issue status to "in_progress"
- Sets your focus to this issue
- Optionally creates an isolated worktree

### 3. Work in Isolation (Optional)

```
issue_claim(issueId="auth-system.2", isolated=true)
```

Creates a worktree at `../repo-worktrees/auth-system/auth-system.2/` where you can work without affecting the main branch.

### 4. Complete the Issue

```
issue_update(
  issueId="auth-system.2",
  status="closed",
  comment="Implemented login flow with OAuth support",
  mergeWorktree=true
)
```

This:
- Merges the worktree back (squash by default)
- Cleans up the worktree
- Adds a completion comment
- Updates the issue status

---

## Delegating Work

### 1. Delegate to Background Agent

```
issue_claim(issueId="auth-system.3", isolated=true, delegate=true)
```

This:
- Creates an isolated worktree
- Starts a background agent session
- Tracks delegation status

### 2. Check Delegation Status

```
project_status()
```

Shows active delegations and their status.

### 3. Review and Merge

When the delegation completes:
- Results are saved to `research/delegation-{id}.md`
- Review the changes in the worktree
- Merge when ready:

```
issue_update(issueId="auth-system.3", status="closed", mergeWorktree=true)
```

---

## Managing Dependencies

### Create Dependent Issues

```
issue_create(title="Implement login", blockedBy=["auth-system.1"])
issue_create(title="Implement logout", blockedBy=["auth-system.1"])
```

### View Dependency Tree

```
project_status()
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
issue_update(issueId="auth-system.1", status="closed")
```

Now `auth-system.2` and `auth-system.3` are unblocked.

---

## Multi-Project Workflows

### Switch Between Projects

```
project_focus(projectId="other-project")
```

### View All Projects

```
project_list()
```

### Work Across Projects

Each project maintains its own:
- Issue tree
- Planning artifacts
- Worktrees
- Delegation history
