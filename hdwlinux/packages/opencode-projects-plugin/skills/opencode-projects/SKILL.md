---
name: opencode-projects
description: Comprehensive reference for the opencode-projects-plugin including tool parameters, workflow examples, team composition strategies, artifact management, session continuity, worktree management, and troubleshooting guides.
---

# OpenCode Projects Skill

Complete reference documentation for the opencode-projects-plugin. This skill provides detailed information about tools, workflows, team composition, and troubleshooting.

## Tool Reference

### project-create

Creates a new project and initiates the planning process.

**Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `name` | string | Yes | - | Project name (used for identification) |
| `type` | `"roadmap"` \| `"project"` | No | `"project"` | Project type |
| `workspace` | string | No | current | Workspace/directory for the project |
| `storage` | `"local"` \| `"global"` | No | `"global"` | Where to store project data |
| `description` | string | No | - | Brief project description |

**Project Types:**

- **`roadmap`** (6+ months): Strategic initiatives with milestones, risks, architecture decisions
- **`project`** (0-3 months): Implementation-focused with detailed technical design

**Example:**

```json
{
  "name": "authentication-system",
  "type": "project",
  "description": "Implement OAuth2 authentication with social login support"
}
```

**Returns:** Project ID and initiates planning conversation.

---

### project-list

Lists all projects with optional filtering.

**Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `scope` | `"local"` \| `"global"` \| `"all"` | No | `"all"` | Which projects to list |
| `status` | `"active"` \| `"completed"` \| `"all"` | No | `"all"` | Filter by status |

**Example:**

```json
{
  "scope": "local",
  "status": "active"
}
```

**Returns:** List of projects with name, status, and issue counts.

---

### project-status

Shows detailed project status including progress and blockers.

**Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `projectId` | string | No | focused | Project to show status for |
| `format` | `"summary"` \| `"detailed"` \| `"tree"` | No | `"summary"` | Output format |

**Formats:**

- **`summary`**: Quick overview with counts
- **`detailed`**: Full issue list with status
- **`tree`**: Hierarchical view of epics/tasks/subtasks

**Example:**

```json
{
  "projectId": "auth-system",
  "format": "tree"
}
```

---

### project-focus

Sets or gets the current project context.

**Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `projectId` | string | No | - | Project to focus on |
| `issueId` | string | No | - | Specific issue to focus on |
| `clear` | boolean | No | false | Clear current focus |

**Effects of Focus:**

- Project context injected into prompts
- Beads queries scoped to the project
- Environment variables set for shell commands

**Example:**

```json
{
  "projectId": "auth-system",
  "issueId": "bd-a3f8.2"
}
```

Call without arguments to see current focus.

---

### project-plan

Manages project planning sessions.

**Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `projectId` | string | No | focused | Project to plan |
| `action` | `"start"` \| `"continue"` \| `"save"` \| `"advance"` \| `"phase"` \| `"status"` | No | `"continue"` | Planning action |
| `phase` | `"discovery"` \| `"synthesis"` \| `"breakdown"` \| `"complete"` | No | - | Target phase (for `phase` action) |
| `understanding` | string | No | - | Current understanding to save |
| `openQuestions` | string | No | - | Open questions to track |

**Planning Phases:**

1. **Discovery**: Understand the problem, stakeholders, timeline, constraints
2. **Synthesis**: Consolidate research, make decisions, identify risks
3. **Breakdown**: Create issues in beads with proper hierarchy
4. **Complete**: Planning finished, ready for execution

**Actions:**

- `start`: Begin new planning session (or continue existing)
- `continue`: Continue current planning session
- `save`: Save progress and summarize understanding
- `advance`: Move to next planning phase
- `phase`: Jump to specific phase
- `status`: Show current planning status

**Example:**

```json
{
  "projectId": "auth-system",
  "action": "advance"
}
```

---

### project-close

Closes a project with a reason and optional summary.

**Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `projectId` | string | Yes | - | Project to close |
| `reason` | `"completed"` \| `"cancelled"` \| `"archived"` | No | - | Closure reason |
| `summary` | string | No | - | Final summary |

**Example:**

```json
{
  "projectId": "auth-system",
  "reason": "completed",
  "summary": "OAuth2 authentication implemented with Google and GitHub providers"
}
```

---

### project-create-issue

Creates a beads issue within a project.

**Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `title` | string | Yes | - | Issue title |
| `projectId` | string | No | focused | Project for the issue |
| `description` | string | No | - | Detailed description |
| `priority` | number | No | 2 | Priority (0=critical, 1=high, 2=medium, 3=low) |
| `parent` | string | No | - | Parent issue ID (for hierarchy) |
| `blockedBy` | string[] | No | - | Issue IDs that block this |
| `labels` | string[] | No | - | Labels for categorization |

**Hierarchical IDs:**

- Epic: `bd-a3f8`
- Task (child of epic): `bd-a3f8.1`
- Subtask (child of task): `bd-a3f8.1.1`

**Example:**

```json
{
  "title": "Implement OAuth2 token refresh",
  "projectId": "auth-system",
  "description": "Handle token expiration and automatic refresh",
  "priority": 1,
  "parent": "bd-a3f8",
  "labels": ["backend", "security"]
}
```

---

### project-work-on-issue

Starts work on an issue with a background agent or team.

**Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `issueId` | string | Yes | - | Issue to work on |
| `isolate` | boolean | No | false | Create isolated worktree |
| `agents` | string[] | No | auto | Agent names for the team |
| `foreground` | boolean | No | false | Wait for completion |

**Isolation Modes:**

- **`isolate=false`** (default): Runs in repo root. Good for research, analysis, documentation.
- **`isolate=true`**: Creates isolated worktree. Required for code changes that need merging.

**Agent Selection:**

- **Not specified**: Small model auto-selects a team (2-4 agents)
- **Single agent**: `["codebase-analyst"]` - Team of 1
- **Explicit team**: `["go-expert", "security-architect"]` - First is PRIMARY, others REVIEW

**Execution Modes:**

- **`foreground=false`** (default): Fire-and-forget. You receive `<team-notification>` when complete.
- **`foreground=true`**: Waits for completion and returns full results inline.

**Examples:**

```json
// Research task - no isolation
{
  "issueId": "bd-a3f8.1",
  "agents": ["codebase-analyst"]
}

// Code change with explicit team
{
  "issueId": "bd-a3f8.2",
  "isolate": true,
  "agents": ["go-expert", "security-architect"]
}

// Auto-select team for code change
{
  "issueId": "bd-a3f8.3",
  "isolate": true
}

// Wait for quick task
{
  "issueId": "bd-a3f8.4",
  "foreground": true,
  "agents": ["codebase-analyst"]
}
```

---

### project-update-issue

Updates an issue's fields including status, assignee, priority, and more.

**Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `issueId` | string | Yes | - | Issue to update |
| `projectId` | string | No | focused | Project containing the issue |
| `status` | `"open"` \| `"in_progress"` \| `"closed"` | No | - | New status |
| `assignee` | string | No | - | Assignee name |
| `priority` | number | No | - | New priority (0-3) |
| `description` | string | No | - | Updated description |
| `labels` | string[] | No | - | Updated labels |
| `blockedBy` | string[] | No | - | Updated blockers |
| `artifacts` | string[] | No | - | Artifact paths/URLs |
| `comment` | string | No | - | Add a comment |
| `mergeWorktree` | boolean | No | false | Merge associated worktree |
| `mergeStrategy` | `"squash"` \| `"merge"` \| `"rebase"` | No | - | How to merge |

**Example - Close with merge:**

```json
{
  "issueId": "bd-a3f8.2",
  "status": "closed",
  "mergeWorktree": true,
  "mergeStrategy": "squash",
  "comment": "OAuth2 implementation complete, all tests passing"
}
```

---

### project-internal-delegation-read

Reads the result of a delegation by ID.

**Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `id` | string | Yes | - | Delegation ID |
| `projectId` | string | No | focused | Project containing the delegation |

**Use Cases:**

- Retrieve delegation results after session compaction
- Review what a background delegation accomplished
- Debug delegation issues

**Returns:** Full delegation result including metadata, prompt, and output.

---

### project-record-decision

Records a decision with rationale and alternatives considered.

**Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `title` | string | Yes | - | Decision title (e.g., "Use OAuth2 over SAML") |
| `decision` | string | Yes | - | What was decided |
| `rationale` | string | Yes | - | Why this decision was made |
| `status` | `"proposed"` \| `"decided"` \| `"rejected"` \| `"deferred"` | No | `"decided"` | Decision status |
| `alternatives` | array | No | - | Alternatives considered (see below) |
| `sourceResearch` | string[] | No | - | Research artifact IDs that informed this |
| `relatedIssues` | string[] | No | - | Related issue IDs |
| `projectId` | string | No | focused | Project for the decision |

**Alternative Object:**

```json
{
  "name": "Alternative name",
  "description": "What this alternative entails",
  "whyRejected": "Why it was not chosen"
}
```

**Decision Statuses:**

- `proposed`: Under consideration, not yet final
- `decided`: Final decision made
- `rejected`: Explicitly rejected (useful for documenting what NOT to do)
- `deferred`: Postponed for later consideration
- `superseded`: Replaced by a newer decision (set via status update)

**Example:**

```json
{
  "title": "Use OAuth2 with PKCE over SAML",
  "decision": "Implement OAuth2 with PKCE flow for user authentication instead of SAML",
  "rationale": "OAuth2 has better mobile/SPA support, PKCE provides security without client secrets, simpler implementation",
  "status": "decided",
  "alternatives": [
    {
      "name": "SAML 2.0",
      "description": "Enterprise standard with strong SSO support",
      "whyRejected": "XML-based complexity, poor mobile support, requires more infrastructure"
    },
    {
      "name": "OpenID Connect only",
      "description": "Pure OIDC without OAuth2 token flows",
      "whyRejected": "Need OAuth2 tokens for API authorization"
    }
  ],
  "sourceResearch": ["research-auth-patterns-abc123"],
  "relatedIssues": ["bd-a3f8", "bd-a3f8.1"]
}
```

**Returns:** Decision record with ID and file location.

**Notes:**
- Decisions are immutable once recorded
- Automatically linked to current session
- Registered in artifact registry with type="decision"
- Decision file created in `projectDir/decisions/`

---

### project-save-artifact

Registers an artifact in the project registry for tracking and context.

**Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `title` | string | Yes | - | Artifact title |
| `type` | string | Yes | - | Artifact type (see below) |
| `path` | string | Yes | - | Path to the artifact file |
| `summary` | string | No | - | Brief description |
| `sourceIssue` | string | No | - | Issue that produced this artifact |
| `projectId` | string | No | focused | Project for the artifact |

**Common Artifact Types:**

| Type | Description |
|------|-------------|
| `research` | Analysis, findings, exploration results |
| `decision` | Decision records (auto-registered by project-record-decision) |
| `deliverable` | Code, documentation, configs in user's workspace |
| `plan` | Architecture docs, roadmaps, risk registers |
| `documentation` | User-facing documentation |

**Path Handling:**

- **Relative paths**: Resolved relative to current working directory
- **Absolute paths**: Used as-is
- **External artifacts**: Paths outside projectDir are marked as external

**Example:**

```json
{
  "title": "Authentication Patterns Research",
  "type": "research",
  "path": "research/auth-patterns.md",
  "summary": "Analysis of OAuth2, SAML, and OIDC patterns for multi-tenant SaaS",
  "sourceIssue": "bd-a3f8.1"
}
```

**Returns:** Artifact record with ID and registration details.

**Notes:**
- Artifact file must already exist at the specified path
- Automatically linked to current session
- Artifacts are immutable (path and content don't change)
- Index files are regenerated to include new artifacts

---

## Workflow Examples

### Example 1: Research Task

User wants to understand how authentication works in the codebase.

```
1. Create project
   project-create(name="auth-research", type="project", 
     description="Research authentication patterns in codebase")

2. Create research issue
   project-create-issue(title="Research authentication patterns",
     description="Understand current auth implementation, identify patterns")

3. Delegate to analyst (no isolation - just reading)
   project-work-on-issue(issueId="bd-xxx.1", agents=["codebase-analyst"])

4. [Continue other work while delegation runs]

5. [Receive <team-notification>]

6. Review findings and close
   project-update-issue(issueId="bd-xxx.1", status="closed",
     comment="Research complete - documented in delegation result")
```

### Example 2: Feature Implementation

User wants to add rate limiting to the API.

```
1. Create project
   project-create(name="rate-limiting", type="project",
     description="Add rate limiting to API endpoints")

2. Discovery conversation
   - Understand requirements (requests per minute, per user vs global)
   - Identify affected endpoints
   - Discuss storage (Redis, in-memory)

3. Advance planning to create issues
   project-plan(action="advance")
   
   Issues created:
   - bd-xxx: Epic - Rate Limiting Implementation
   - bd-xxx.1: Research rate limiting libraries
   - bd-xxx.2: Implement rate limiter middleware
   - bd-xxx.3: Add rate limit headers to responses
   - bd-xxx.4: Write tests

4. Delegate research (no isolation)
   project-work-on-issue(issueId="bd-xxx.1", agents=["codebase-analyst"])

5. [Notification received] - Review research findings

6. Delegate implementation (with isolation)
   project-work-on-issue(issueId="bd-xxx.2", isolate=true,
     agents=["go-expert", "security-architect"])

7. [Notification received with worktree info]
   Review changes:
   jj diff --from main --to rate-limiting/bd-xxx.2

8. Merge and close
   project-update-issue(issueId="bd-xxx.2", status="closed",
     mergeWorktree=true, mergeStrategy="squash")

9. Continue with remaining issues...
```

### Example 3: Multi-Agent Architecture Review

User wants a thorough review of a proposed architecture change.

```
1. Create issue for review
   project-create-issue(title="Review microservices migration proposal",
     description="Evaluate proposed migration from monolith to microservices",
     labels=["architecture", "review"])

2. Delegate to diverse team (no isolation - analysis only)
   project-work-on-issue(issueId="bd-xxx.1",
     agents=["distributed-systems-architect", "security-architect", 
             "devops-engineer", "database-architect"])

3. Team dynamics:
   - distributed-systems-architect: PRIMARY - leads analysis
   - security-architect: SECONDARY - reviews security implications
   - devops-engineer: SECONDARY - reviews operational concerns
   - database-architect: DEVIL'S ADVOCATE - challenges data assumptions

4. Discussion rounds (2 by default):
   Round 1: Each agent responds to primary's analysis
   Round 2: Agents respond to each other, reach consensus

5. [Notification received with comprehensive analysis]

6. Review and close with summary
   project-update-issue(issueId="bd-xxx.1", status="closed",
     comment="Architecture review complete - see delegation for full analysis")
```

### Example 4: Parallel Delegations

User has multiple independent tasks to complete.

```
1. Create issues
   project-create-issue(title="Update API documentation")
   project-create-issue(title="Fix authentication bug")
   project-create-issue(title="Add logging to payment service")

2. Delegate all in parallel (separate tool calls)
   project-work-on-issue(issueId="bd-xxx.1", agents=["documentation-writer"])
   project-work-on-issue(issueId="bd-xxx.2", isolate=true, 
     agents=["go-expert", "security-architect"])
   project-work-on-issue(issueId="bd-xxx.3", isolate=true,
     agents=["go-expert", "observability-expert"])

3. [Continue other work]

4. [Receive notifications as each completes]
   - Handle each completion independently
   - Merge isolated worktrees as they finish
   - Close issues

5. All work completes in parallel, faster than sequential
```

---

## Artifact and Session Management

### Project Directory Structure

When artifacts and sessions are enabled, the project directory contains:

```
projectDir/
├── project.json              # Project metadata
├── planning.json             # Planning state
├── artifacts.json            # Artifact registry
├── sessions/
│   ├── index.md              # Session history with open questions, what's next
│   └── {seq}-{id}-{date}.md  # Individual session summaries
├── research/
│   ├── index.md              # Research index with summaries
│   └── {slug}.md             # Research documents
├── decisions/
│   ├── index.md              # Decision log
│   └── {date}-{slug}.md      # Decision records
└── delegations/              # Delegation results
```

### Session Capture

Sessions are automatically captured when the conversation compacts.

**What's Captured:**

| Field | Description |
|-------|-------------|
| `summary` | 2-3 sentence overview |
| `keyPoints` | 3-5 bullet points |
| `openQuestionsAdded` | Questions raised but not resolved |
| `decisionsMade` | Links to decision records |
| `whatsNext` | Concrete next steps |

**Session Index Format:**

```markdown
# Session History

## Open Questions
- How should we handle token refresh for offline users?
- What's the migration path for existing sessions?

## Pending Decisions
- Authentication provider selection (Auth0 vs Okta vs Keycloak)

## What's Next
- Complete research on token refresh patterns
- Make decision on auth provider
- Begin implementation of OAuth2 flow

---

## Sessions

### 003-ses_xyz789-2026-03-03
**Summary:** Continued authentication planning...
**Key Points:**
- OAuth2 with PKCE confirmed
- Need to research offline token refresh
**Link:** [Full session](./003-ses_xyz789-2026-03-03.md)

### 002-ses_abc456-2026-03-02
...
```

Sessions are listed most-recent-first so the agent can stop reading earlier if needed.

### Research Management

Research artifacts are managed in `projectDir/research/` (or a custom path).

**Creating Research:**

1. Complete research delegation
2. Save the research document
3. Register with `project-save-artifact`:

```json
{
  "title": "Token Refresh Strategies",
  "type": "research",
  "path": "research/token-refresh.md",
  "summary": "Analysis of offline token refresh patterns",
  "sourceIssue": "bd-a3f8.3"
}
```

**Research Index:**

The research index (`research/index.md`) is automatically regenerated with:
- Summary table of all research
- Individual entries with key findings
- Links to full documents

**Custom Research Path:**

Set `researchPath` when creating the project to store research elsewhere:

```json
{
  "name": "auth-system",
  "researchPath": "/path/to/project/docs/research"
}
```

External research is linked in the index but stored at the specified location.

### Decision Management

Decisions are recorded in `projectDir/decisions/`.

**Recording Decisions:**

Use `project-record-decision` when:
- An architectural choice is made
- A technology is selected
- A design pattern is chosen
- A constraint is accepted

**Decision Record Format:**

```markdown
# Decision: Use OAuth2 with PKCE

**Date:** 2026-03-02
**Status:** Decided
**Updated:** 2026-03-02T14:30:00Z

## Decision

Use OAuth2 with PKCE flow instead of SAML for user authentication.

## Rationale

- OAuth2 has better mobile/SPA support
- PKCE provides security without client secrets
- Simpler implementation and debugging

## Alternatives Considered

### SAML 2.0
Enterprise standard with strong SSO support.
**Why rejected:** XML-based complexity, poor mobile support

### OpenID Connect only
Pure OIDC without OAuth2 token flows.
**Why rejected:** Need OAuth2 tokens for API authorization

## Sources

- **Session:** [002-ses_abc456-2026-03-02](../sessions/002-ses_abc456-2026-03-02.md)
- **Research:** [Auth Patterns](../research/auth-patterns.md)

## Related Issues

- bd-a3f8: Authentication System (epic)
- bd-a3f8.1: Research authentication patterns
```

**Decision Index:**

The decision index (`decisions/index.md`) contains:
- Pending decisions needing resolution
- Decided items (alphabetically sorted)
- Superseded decisions

### Artifact Registry

All artifacts are tracked in `artifacts.json`:

```json
{
  "artifacts": [
    {
      "id": "research-auth-patterns-abc123",
      "type": "research",
      "title": "Authentication Patterns Analysis",
      "path": "research/auth-patterns.md",
      "absolutePath": "/home/user/projects/auth/.projects/auth-system/research/auth-patterns.md",
      "external": false,
      "createdAt": "2026-03-02T14:30:00Z",
      "sourceIssue": "bd-a3f8.1",
      "sourceSession": "002-ses_abc456-2026-03-02",
      "summary": "Analysis of OAuth2, SAML, and OIDC patterns"
    }
  ]
}
```

**Artifact IDs:**

Format: `{type}-{slug}-{random}`

Examples:
- `research-auth-patterns-abc123`
- `decision-oauth2-over-saml-def456`
- `deliverable-auth-middleware-ghi789`

### Context Injection

When a project is focused, the following context is injected:

1. **Project Progress**: Issue counts, blockers
2. **Recent Sessions**: Last 2-3 session summaries
3. **Open Questions**: Accumulated from all sessions
4. **Pending Decisions**: Decisions needing resolution
5. **What's Next**: From the most recent session
6. **Artifact Summary**: Compact list of available artifacts by type

This context enables seamless resumption without re-reading project history.

---

## Team Composition Guide

### Single Agent (Team of 1)

Best for:
- Simple, focused tasks
- Research and exploration
- Documentation updates
- Quick fixes

```json
{"agents": ["codebase-analyst"]}
{"agents": ["documentation-writer"]}
{"agents": ["go-expert"]}
```

### Two-Agent Teams

Best for:
- Code changes needing review
- Security-sensitive work
- Complex analysis requiring expertise

**Recommended Pairings:**

| Primary | Secondary | Use Case |
|---------|-----------|----------|
| `go-expert` | `security-architect` | Secure Go code |
| `typescript-expert` | `testing-expert` | Tested frontend code |
| `python-expert` | `database-architect` | Data-heavy Python |
| `codebase-analyst` | domain expert | Understanding + implementation |
| `devops-engineer` | `security-architect` | Secure infrastructure |

### Three-Agent Teams

Best for:
- Critical infrastructure changes
- Cross-cutting concerns
- Architecture decisions

**Example Compositions:**

```json
// Secure API implementation
{"agents": ["go-expert", "security-architect", "api-designer"]}

// Full-stack feature
{"agents": ["typescript-expert", "go-expert", "testing-expert"]}

// Infrastructure change
{"agents": ["terraform-expert", "security-architect", "devops-engineer"]}
```

### Four+ Agent Teams

Best for:
- Major architectural decisions
- Security-critical systems
- Complex migrations

**Example:**

```json
// Microservices migration analysis
{"agents": ["distributed-systems-architect", "security-architect", 
            "devops-engineer", "database-architect"]}
```

### Auto-Selection

When `agents` is not specified, the small model:

1. Analyzes the issue title and description
2. Considers the project context
3. Selects 2-4 appropriate agents
4. Assigns roles (primary, secondary, devilsAdvocate)

This works well for most tasks. Use explicit agents when you have specific expertise requirements.

---

## Team Roles and Discussion

### Roles

| Role | Responsibility | Selection |
|------|----------------|-----------|
| **Primary** | Does the main work, writes code/analysis | First agent in list |
| **Secondary** | Reviews, provides feedback, catches issues | Other agents |
| **Devil's Advocate** | Challenges assumptions, forces justification | Small model selects one secondary |

### Discussion Rounds

Default: 2 rounds after initial work completes.

**Round Flow:**

1. Primary agent completes initial work
2. Secondary agents review and respond
3. Devil's advocate challenges assumptions
4. Agents respond to each other
5. Convergence toward consensus

**Configuration:**

Discussion rounds are configured in the plugin settings:
- `discussionRounds`: Number of rounds (default: 2, 0 = disabled)
- `discussionRoundTimeout`: Timeout per round (default: 5 minutes)

### Devil's Advocate Injection

The devil's advocate receives additional prompt injection:

> You are the devil's advocate. Your role is to:
> - Challenge assumptions made by other agents
> - Identify potential flaws or risks
> - Force justification of decisions
> - Consider alternative approaches
> 
> Be constructive but rigorous. Don't accept claims without evidence.

---

## Worktree Management

When `isolate=true`, the delegation creates an isolated worktree. The completion notification includes merge instructions.

### Notification Format

```xml
<team-notification>
  <team-id>team-abc123</team-id>
  <issue>bd-a3f8.2</issue>
  <status>completed</status>
  <worktree>
    <path>/path/to/worktree</path>
    <branch>project-id/bd-a3f8.2</branch>
    <vcs>jj</vcs>
  </worktree>
  <merge-instructions>
    VCS-specific instructions...
  </merge-instructions>
  <result>Full delegation result...</result>
</team-notification>
```

### Jujutsu (jj) Workflow

**Review changes:**
```bash
jj diff --from main --to <branch>
```

**View commit log:**
```bash
jj log -r <branch>
```

**Merge changes (squash into main):**
```bash
jj squash --from <branch>
```

**Alternative: Rebase onto main:**
```bash
jj rebase -s <branch> -d main
```

**Clean up worktree:**
```bash
jj workspace forget <branch>
```

**Full workflow:**
```bash
# Review
jj diff --from main --to project-id/bd-a3f8.2

# Merge
jj squash --from project-id/bd-a3f8.2

# Clean up
jj workspace forget project-id/bd-a3f8.2
```

### Git Workflow

**Review changes:**
```bash
git diff main..<branch>
```

**View commit log:**
```bash
git log main..<branch>
```

**Merge changes:**
```bash
git checkout main
git merge <branch>
```

**Or squash merge:**
```bash
git checkout main
git merge --squash <branch>
git commit -m "Merge: <description>"
```

**Clean up:**
```bash
git worktree remove <path>
git branch -d <branch>
```

**Full workflow:**
```bash
# Review
git diff main..project-id/bd-a3f8.2

# Merge
git checkout main
git merge --squash project-id/bd-a3f8.2
git commit -m "feat: implement OAuth2 token refresh"

# Clean up
git worktree remove /path/to/worktree
git branch -d project-id/bd-a3f8.2
```

### Using project-update-issue for Merge

You can also merge via the tool:

```json
{
  "issueId": "bd-a3f8.2",
  "status": "closed",
  "mergeWorktree": true,
  "mergeStrategy": "squash"
}
```

This handles the merge and cleanup automatically.

---

## Beads Integration

Issues are tracked in beads (`bd` CLI).

### Hierarchical IDs

```
bd-a3f8           # Epic
├── bd-a3f8.1     # Task
│   ├── bd-a3f8.1.1  # Subtask
│   └── bd-a3f8.1.2  # Subtask
├── bd-a3f8.2     # Task
└── bd-a3f8.3     # Task
```

### Common Commands

```bash
# List all issues
bd list

# Show ready (unblocked) issues
bd ready

# Show issue details
bd show bd-a3f8.1

# Update issue status
bd update bd-a3f8.1 --status in_progress

# Add comment
bd comment bd-a3f8.1 "Started implementation"
```

### Dependencies

Issues can block other issues:

```json
{
  "title": "Deploy to production",
  "blockedBy": ["bd-a3f8.1", "bd-a3f8.2", "bd-a3f8.3"]
}
```

The blocked issue won't appear in `bd ready` until all blockers are closed.

---

## Troubleshooting

### Delegation Never Completes

**Symptoms:** No notification received, delegation seems stuck.

**Causes and Solutions:**

1. **Agent timeout**: Check if the task is too large
   - Break into smaller issues
   - Use `foreground=true` to see progress

2. **Model errors**: Check OpenCode logs
   - Look for API errors
   - Verify model availability

3. **Worktree conflicts**: For isolated delegations
   - Check if worktree was created: `jj workspace list` or `git worktree list`
   - Manual cleanup may be needed

### Merge Conflicts

**Symptoms:** Merge fails with conflicts.

**Solutions:**

1. **Review the conflict:**
   ```bash
   jj diff --from main --to <branch>
   ```

2. **Resolve manually:**
   - Check out the worktree
   - Fix conflicts
   - Complete the merge

3. **Abandon and retry:**
   - Close the issue without merging
   - Create new issue with updated context
   - Re-delegate

### Agent Selection Issues

**Symptoms:** Auto-selected team doesn't match the task.

**Solutions:**

1. **Use explicit agents:**
   ```json
   {"agents": ["go-expert", "security-architect"]}
   ```

2. **Improve issue description:**
   - Add more context
   - Specify technologies involved
   - Mention security/performance concerns

3. **Confirm available agents with the user:**
   - Ask the user which agents are configured on their system
   - Only use agents that have been confirmed to work in the current session
   - Do not assume any specific agent names are available

### Worktree Cleanup

**Symptoms:** Orphaned worktrees after failed delegations.

**Jujutsu cleanup:**
```bash
# List workspaces
jj workspace list

# Remove orphaned workspace
jj workspace forget <name>
```

**Git cleanup:**
```bash
# List worktrees
git worktree list

# Remove worktree
git worktree remove <path> --force

# Prune stale worktrees
git worktree prune
```

### Focus Issues

**Symptoms:** Wrong project context, queries return unexpected results.

**Solutions:**

1. **Check current focus:**
   ```
   project-focus()
   ```

2. **Clear and reset:**
   ```
   project-focus(clear=true)
   project-focus(projectId="correct-project")
   ```

---

## Best Practices

### Project Sizing

| Type | Duration | Scope | Issues |
|------|----------|-------|--------|
| Roadmap | 6+ months | Strategic initiative | 10-50+ |
| Project | 1-3 months | Feature/milestone | 5-20 |
| Mini-project | 1-2 weeks | Focused task | 2-10 |

### Issue Granularity

| Level | Duration | Description |
|-------|----------|-------------|
| Epic | Days-weeks | Major feature or milestone |
| Task | Hours-days | Delegatable work item |
| Subtask | Hours | Specific implementation step |

**Rule of thumb:** If a task takes more than a day, break it down.

### When to Use Isolation

| Scenario | Isolate? | Reason |
|----------|----------|--------|
| Research/analysis | No | Just reading, no changes |
| Documentation | No | Usually safe in main |
| Bug investigation | No | Reading and analysis |
| Code implementation | Yes | Changes need review/merge |
| Refactoring | Yes | Significant changes |
| Test writing | Yes | New files, changes |

### When to Use Foreground

| Scenario | Foreground? | Reason |
|----------|-------------|--------|
| Quick research | Yes | Need answer immediately |
| Debugging | Yes | See progress in real-time |
| Sequential tasks | Yes | Next task depends on result |
| Long implementation | No | Do other work while waiting |
| Multiple parallel tasks | No | Maximize throughput |

### Team Selection Guidelines

| Task Type | Recommended Team |
|-----------|------------------|
| Simple bug fix | Single domain expert |
| Feature implementation | Domain expert + reviewer |
| Security-sensitive | Domain expert + security-architect |
| API changes | Domain expert + api-designer |
| Database changes | Domain expert + database-architect |
| Infrastructure | terraform/devops + security-architect |
| Architecture decision | 3-4 diverse experts |

### Communication Patterns

1. **Start with discovery**: Don't jump to implementation
2. **Break down first**: Create issues before delegating
3. **Review before merge**: Always check delegation results
4. **Close promptly**: Update issue status when done
5. **Document decisions**: Use comments for context

---

## Configuration Reference

The plugin reads configuration from OpenCode's config system.

### Team Settings

| Setting | Default | Description |
|---------|---------|-------------|
| `discussionRounds` | 2 | Number of discussion rounds (0 = disabled) |
| `discussionRoundTimeout` | 300000 | Timeout per round in ms (5 min) |
| `delegationTimeout` | 600000 | Overall delegation timeout in ms (10 min) |
| `maxRetries` | 2 | Retries for failed team members |

### Worktree Settings

| Setting | Default | Description |
|---------|---------|-------------|
| `worktreeBase` | `.worktrees` | Directory for isolated worktrees |
| `cleanupOnMerge` | true | Remove worktree after merge |
