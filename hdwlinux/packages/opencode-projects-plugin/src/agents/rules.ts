/**
 * System prompt rules for project management
 */

export const PROJECT_RULES = `<project-management-system>

## Project Management Tools

You have access to project planning and tracking tools:

### Project Tools
- \`project-create(name, type?, workspace?, storage?, description?)\` - Create a new project and start planning
- \`project-list(scope?, status?)\` - List all projects
- \`project-status(projectId?, format?)\` - Show project progress and blockers
- \`project-focus(projectId?, issueId?, clear?)\` - Set/get current project context
- \`project-plan(projectId?, phase?, focus?)\` - Continue or refine project planning
- \`project-close(projectId, reason?, summary?)\` - Close a project

### Issue Tools
- \`project-create-issue(title, projectId?, description?, priority?, parent?, blockedBy?, labels?)\` - Create a beads issue
- \`project-claim-issue(issueId, isolate?, delegate?)\` - Claim an issue and optionally start isolated work
- \`project-update-issue(issueId, status?, ...)\` - Update issue status and fields

### Delegation Tools
- \`project-internal-delegation-read(id)\` - Read delegation results by ID

## Workflow Guidelines

### Starting a New Project
1. Use \`project-create\` to initialize the project
2. Engage in conversational discovery to understand scope
3. Use \`project-plan\` to refine and break down work
4. Issues are automatically created in beads

### Working on Issues
1. Use \`project-focus\` to set context
2. Use \`project-status\` to see ready work
3. Use \`project-claim-issue\` to start work
4. For parallel work, use \`project-claim-issue(id, isolate=true, delegate=true)\`

### Project Types
- **Roadmap** (6+ months): Strategic planning with milestones, risks, architecture
- **Project** (0-3 months): Implementation-focused with detailed technical design

### Beads Integration
All issues are tracked in beads (\`bd\` CLI). Key concepts:
- Hierarchical IDs: \`bd-a3f8\` (epic) → \`bd-a3f8.1\` (task) → \`bd-a3f8.1.1\` (subtask)
- Dependencies: Issues can block other issues
- Ready queue: \`bd ready\` shows unblocked work

### Focus Mode
When focused on a project/issue:
- Context is automatically injected into prompts
- Beads queries are scoped to the focused project
- Environment variables are set for shell commands

## Background Delegations

When you delegate work to a background agent:
1. The delegation starts immediately and runs in the background
2. You will receive a \`<delegation-notification>\` when it completes
3. Do NOT poll for status - continue with other productive work
4. Multiple delegations can run in parallel
5. You will be notified when ALL delegations complete

### Delegation Notifications

Notifications arrive in this format:
\`\`\`xml
<delegation-notification>
  <delegation-id>del-abc123</delegation-id>
  <issue>issue-id</issue>
  <status>complete|failed|timeout</status>
  <title>Generated Title</title>
  <description>Brief description of what was accomplished.</description>
  <result>The full delegation result...</result>
</delegation-notification>
\`\`\`

When all delegations complete:
\`\`\`xml
<delegation-notification>
  <status>all-complete</status>
  <summary>All delegations complete. Review the results above and continue.</summary>
</delegation-notification>
\`\`\`

### Disabled Tools in Delegations

Delegated agents cannot use state-modifying tools:
- project-create, project-close, project-create-issue, project-update-issue, project-claim-issue
- task, delegate (no recursive delegation)

</project-management-system>`
