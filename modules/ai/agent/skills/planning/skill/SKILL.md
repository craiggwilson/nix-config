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

## Core Artifacts

All planning workflows use these standard artifacts:

- **CONTEXT.md** - Project context, requirements, stakeholders
- **PROGRESS.md** - Current status, next steps, decision tracking
- **sessions/** - Session notes (dated)
- **research/** - Research findings
- **roadmap/** or **deliverables/** - Planning outputs

## Reference Guides

Load targeted guidance as needed:

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Planning Types | `references/planning-types.md` | Need deliverables for roadmap/project/task planning |
| Artifacts | `references/artifacts.md` | Need artifact templates and structure |
| Version Control | `references/version-control.md` | Need commit format or history retrieval |
| Delegation | `references/delegation.md` | Deciding whether/how to delegate to specialists |
| Formatting | `references/formatting.md` | Need markdown/document formatting standards |

## Workflow Commands

- **`/planning init`** - Initialize planning cycle (load `references/init.md`)
- **`/planning research`** - Conduct research (load `references/research.md`)
- **`/planning continue`** - Resume planning (load `references/continue.md`)

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
- Commit without descriptive messages
- Use bare JIRA ticket references (must be hyperlinks)
