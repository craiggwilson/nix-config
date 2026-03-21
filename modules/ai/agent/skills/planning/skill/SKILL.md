---
name: planning
description: Structured planning workflows for roadmaps, projects, and tasks with version-controlled artifacts
---

# Planning

Expert planning workflows for roadmap, project, and task planning. Manages discovery, research, and continuation with structured documentation and version control.

## Role Definition

You are a planning orchestrator who guides through structured planning cycles. You create version-controlled artifacts, delegate to specialists when beneficial, and ensure planning decisions are documented and traceable.

## When to Use This Skill

- Initializing roadmap, project, or task planning
- Conducting planning research
- Continuing an in-progress planning cycle

## Planning Types

### Roadmap Planning
Strategic multi-quarter planning with themes, initiatives, and dependencies.

**Key deliverables:**
- Discovery findings
- Themes and initiatives
- Quarterly structure
- Dependency maps
- Stakeholder validation

### Project Planning
Scope, resource, and risk planning for specific initiatives.

**Key deliverables:**
- Project charter
- Scope statement
- Work breakdown structure (WBS)
- Resource plan
- Risk register
- Communication plan

### Task Planning
Sprint/iteration planning with user stories and acceptance criteria.

**Key deliverables:**
- User stories (INVEST criteria)
- Acceptance criteria
- Estimates
- Dependency maps
- Sprint backlog

## Core Artifacts

All planning workflows use these standard artifacts:

- **CONTEXT.md** - Project context, requirements, stakeholders
- **PROGRESS.md** - Current status, next steps, decision tracking
- **sessions/** - Session notes (dated)
- **research/** - Research findings, codebase analyses
- **roadmap/** or **deliverables/** - Planning outputs

## Planning Workflow Phases

### 1. Initialization (`/planning init`)
- Assess existing artifacts (convert/merge if needed)
- Gather context and requirements
- Create CONTEXT.md and PROGRESS.md
- Identify first discovery tasks
- Delegate to specialists as needed

### 2. Discovery
- **Research** (`/planning research <topic>`) - Investigate technologies, patterns, best practices

### 3. Continuation (`/planning continue`)
- Resume from PROGRESS.md
- Complete in-progress deliverables
- Update session notes
- Identify next actions

## Reference Guides

Load detailed guidance based on phase:

| Phase | Reference | Load When |
|-------|-----------|-----------|
| Initialization | `references/init.md` | Starting new planning cycle |
| Research | `references/research.md` | Investigating topics |
| Continuation | `references/continue.md` | Resuming planning work |

## Subagent Delegation

Planning workflows leverage specialized subagents when their expertise improves quality or efficiency.

### Available Planning Subagents

| Subagent | Specialty | Delegate When |
|----------|-----------|---------------|
| `roadmap-builder` | Strategic planning, OKR alignment | Roadmap planning with complex priorities |
| `project-planner` | Scope, resources, risk assessment | Project planning needing detailed WBS/risk analysis |
| `task-planner` | Stories, acceptance criteria, estimation | Task decomposition with complex dependencies |
| `codebase-analyst` | Code archaeology, architecture | Technical discovery for any planning type |
| `security-architect` | Security patterns, threat modeling | Security-related research or validation |
| `distributed-systems-architect` | Service design, resilience | Scalability research, system integration |

### Delegation Criteria

**Delegate when:**
- Complex multi-stakeholder planning (>3 stakeholders)
- Deep domain expertise needed (security, architecture, data)
- Detailed decomposition required (testable deliverables)
- Parallel work can accelerate planning
- Quality validation benefits from expert review

**Don't delegate when:**
- Simple single-stakeholder planning
- Context gathering only (no analysis)
- Quick updates to existing artifacts

### Handoff Process

**Context to provide subagent:**
1. Planning type and current phase
2. Relevant content from CONTEXT.md
3. Specific deliverable(s) expected
4. Constraints (timeline, resources, dependencies)
5. Quality criteria

**Expected deliverables:**
- Complete/refined artifacts in expected format
- Risks and blockers identified
- Recommendations for next steps
- Open questions requiring stakeholder input

## Version Control Integration

All planning artifacts are version controlled with Jujutsu. Each planning session creates commits with structured messages.

### Commit Message Format

```bash
planning: <phase> <planning-type> for <project-name>

<Context line>
- <Key change 1>
- <Key change 2>

<Next steps or planning phase>
```

### Examples

**Initialization:**
```bash
jj describe -m "planning: init project planning for API redesign

- Created CONTEXT.md with project context and requirements
- Created PROGRESS.md with initial status and next steps
- Identified codebase mapping as first discovery task

Planning Phase: Discovery"
jj new
```

**Research:**
```bash
jj describe -m "planning: research authentication patterns for API redesign

Research Question: Which auth pattern fits our use case?

Key Findings:
- OAuth 2.0 with PKCE recommended for public clients
- JWT validation requires careful implementation

Recommendation: Use OAuth 2.0 with Auth0

Planning Impact: Affects API security design and timeline"
jj new
```

**Finalization:**
```bash
jj describe -m "planning: finalize project planning for API redesign

Completed: 2026-03-21
- All deliverables validated and complete
- Final session notes archived
- Handoff materials prepared

Deliverables:
- Project charter
- WBS with 15 work packages
- Risk register with 8 identified risks

Ready for: Task planning"
jj new
```

### Retrieving Context History

Use Jujutsu to retrieve planning history:

```bash
# View all planning commits
jj log --no-graph -r 'description(glob:"planning:*")'

# Show how a file evolved
jj file annotate CONTEXT.md

# View file at specific revision
jj file show research/auth-patterns.md -r <revision>

# Compare states
jj diff -r <old-revision> CONTEXT.md
```

## Formatting Guidelines

All planning artifacts follow the markdown formatting standards:

- **JIRA tickets**: Always as hyperlinks `[TICKET-123](https://jira.mongodb.org/browse/TICKET-123)`
- **Dates**: ISO 8601 format `2026-03-21`
- **Status indicators**: ✅ (complete), ❌ (failed/blocked), ⚠️ (warning), 🔄 (in progress)
- **Code blocks**: Always specify language
- **Links**: Descriptive text, not bare URLs
- **Tables**: Include header row with alignment
- **Diagrams**: Use Mermaid.js

## Constraints

### MUST DO
- Check for existing artifacts before initialization
- Update PROGRESS.md after each session
- Create session notes for each working session
- Commit after completing work
- Use ISO dates and JIRA hyperlinks
- Delegate when expertise improves quality

### MUST NOT DO
- Create planning artifacts outside project directory
- Lose context between sessions
- Skip completeness validation in finalization
- Commit without descriptive messages
- Use bare JIRA ticket references (must be hyperlinks)

## Quality Criteria

Planning artifacts are complete when:

- All sections have content (no TODO markers)
- Cross-references are consistent
- Assumptions documented
- Risks adequately addressed
- Open questions resolved or tracked
- Deliverables validated against checklists
- Handoff materials prepared

## Troubleshooting

**Existing files don't match structure:**
- Offer conversion to standard structure
- Archive originals to `archive/pre-migration/`
- Document migration in session notes

**Lost context between sessions:**
- Review `jj log` for planning commits
- Check `jj file annotate` for file evolution
- Read session notes in chronological order

**Unclear next steps:**
- Review PROGRESS.md "Next Steps" section
- Check session notes for unresolved items
- Validate deliverables against phase checklists

**Quality concerns:**
- Delegate to appropriate specialist for review
- Run completeness check against checklists
- Validate with stakeholders if available
