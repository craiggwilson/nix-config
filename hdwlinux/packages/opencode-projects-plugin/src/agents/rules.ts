/**
 * System prompt rules for project management
 */

export const PROJECT_RULES = `<project-management-system>

## Project Management Tools

You have access to project planning and tracking tools:

### Project Tools
- \`project_create(name, type?, workspace?, storage?, description?)\` - Create a new project and start planning
- \`project_list(scope?, status?)\` - List all projects
- \`project_status(projectId?, format?)\` - Show project progress and blockers
- \`project_focus(projectId?, issueId?, clear?)\` - Set/get current project context
- \`project_plan(projectId?, phase?, focus?)\` - Continue or refine project planning
- \`project_close(projectId, reason?, summary?)\` - Close a project

### Issue Tools
- \`issue_create(title, projectId?, description?, priority?, parent?, blockedBy?, labels?)\` - Create a beads issue
- \`issue_claim(issueId, isolate?, delegate?)\` - Claim an issue and optionally start isolated work

## Workflow Guidelines

### Starting a New Project
1. Use \`project_create\` to initialize the project
2. Engage in conversational discovery to understand scope
3. Use \`project_plan\` to refine and break down work
4. Issues are automatically created in beads

### Working on Issues
1. Use \`project_focus\` to set context
2. Use \`project_status\` to see ready work
3. Use \`issue_claim\` to start work
4. For parallel work, use \`issue_claim(id, isolate=true, delegate=true)\`

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

</project-management-system>`
