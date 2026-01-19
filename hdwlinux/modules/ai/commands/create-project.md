---
description: Creates a project that a project-manager will be responsible for.
argument-hint: [file-path]
---

**Project Name**: $ARGUMENTS

Create a directory named based on the arguments with the following structure.

```
<directory>/
├── AGENTS.md               # This file - project context and requirements
├── PROGRESS.md             # Work progress tracking (create as needed)
├── DECISIONS.md            # Architectural decisions log (create as needed)
├── research/               # Research artifacts and analysis (create as needed)
├── deliverables/           # Final deliverables (create as needed)
│   ├── designs/            # Design documents
│   ├── code/               # Code snippets and prototypes
│   └── presentations/      # Slide decks and summaries
└── sessions/               # Session-specific notes (create as needed)
    └── YYYY-MM-DD.md       # Daily session notes
```

## AGENTS.md TEMPLATE

<template>
# Project Name

> **Last Updated**: YYYY-MM-DD
> **DRI**: Craig Wilson
> **Program Goal**: <Goal>

---

## MongoDB Fiscal Year Calendar

MongoDB's fiscal year runs from **February 1 to January 31**. Use this reference for all quarter labels:

| Quarter | Date Range |
|---------|------------|
| **Q1** | Feb 1 - Apr 30 |
| **Q2** | May 1 - Jul 31 |
| **Q3** | Aug 1 - Oct 31 |
| **Q4** | Nov 1 - Jan 31 |

**Important**: Always use `FYXX QX` when referring to quarters. For example, `FY26 Q4` is Nov 1, 2025 - Jan 31, 2026.

---
## Account Information

1. Use craig.wilson@mongodb.com for account access to Google.
2. Use craiggwilson@gmail.com for access to Github.

---

## Table of Contents

---

## Executive Summary

---

## Problem Statement

---

## Program Structure

---

## Technical Architecture

---

## SMART Goals

### Output Goals

### Input Goals

### Related Department Goals

---

## Source Code Locations

---

## Reference Documents

---

## State Management & Workflow

This section describes how to use the project directory for managing work on this project.

### Directory Structure

```
_DataPlaneAvailability/
├── AGENTS.md               # This file - project context and requirements
├── PROGRESS.md             # Work progress tracking (create as needed)
├── DECISIONS.md            # Architectural decisions log (create as needed)
├── research/               # Research artifacts and analysis (create as needed)
├── deliverables/           # Final deliverables (create as needed)
│   ├── designs/            # Design documents
│   ├── code/               # Code snippets and prototypes
│   └── presentations/      # Slide decks and summaries
└── sessions/               # Session-specific notes (create as needed)
    └── YYYY-MM-DD.md       # Daily session notes
```

### Session Workflow

**Starting a New Session:**
1. Review this `AGENTS.md` for project overview
2. Check `PROGRESS.md` for current status and next steps
3. Review recent `sessions/` notes for context continuity
4. Create a new session file: `sessions/YYYY-MM-DD.md`

**During a Session:**
1. Document key findings in session notes
2. Update `PROGRESS.md` with completed items
3. Log decisions in `decisions.md` with rationale
4. Save research artifacts to appropriate `research/` subdirectory

**Ending a Session:**
1. Summarize accomplishments in session notes
2. Update `PROGRESS.md` with:
   - Completed tasks
   - Next steps
   - Blockers or questions
3. Commit all changes with descriptive message

### Progress Tracking Format

Use this format in `PROGRESS.md`:

```markdown
# Progress

## Current Status
- **Phase**: [Discovery | Design | Implementation | Review]
- **Last Updated**: YYYY-MM-DD
- **Next Session Focus**: [Brief description]

## Completed
- [ ] Task 1 - Completed YYYY-MM-DD
- [ ] Task 2 - Completed YYYY-MM-DD

## In Progress
- [ ] Task 3 - Started YYYY-MM-DD, ETA YYYY-MM-DD
  - Notes: [Any relevant context]

## Blocked
- [ ] Task 4 - Blocked by [reason]
  - **Action Required**: [What's needed to unblock]

## Backlog
- [ ] Future task 1
- [ ] Future task 2
```

### Decision Log Format

Use this format in `DECISIONS.md`:

```markdown
# Architectural Decisions

## ADR-001: [Decision Title]
- **Date**: YYYY-MM-DD
- **Status**: [Proposed | Accepted | Deprecated | Superseded]
- **Context**: [Why this decision was needed]
- **Decision**: [What was decided]
- **Consequences**: [Impact of this decision]
- **Alternatives Considered**: [Other options that were evaluated]
```

### Intermediate Work Preservation

For complex analyses or research:

1. **Save intermediate results** in `research/` with clear naming
2. **Include metadata** at top of research files:
   ```markdown
   # [Research Topic]
   - **Date**: YYYY-MM-DD
   - **Purpose**: [Why this research was done]
   - **Status**: [In Progress | Complete | Needs Review]
   - **Related Tasks**: [Links to PROGRESS.md items]
   ```

3. **Cross-reference** findings in session notes and progress tracking

### Deliverable Management

When creating deliverables:

1. Use `deliverables/` subdirectories by type
2. Include version information in filenames: `design-v1.md`, `design-v2.md`
3. Mark final versions clearly: `design-FINAL.md`
4. Archive superseded versions in a `_archive/` subdirectory if needed

### AI Context Optimization Tips

To maximize AI assistant effectiveness:

1. **Be specific in queries**: Reference specific canonical outages, JIRA tickets, or goals
2. **Provide context**: Point to relevant files in this directory structure
3. **Use structured formats**: Tables, numbered lists, and headers aid comprehension
4. **Include constraints**: Mention deadlines, technical limitations, or dependencies
5. **Reference previous work**: Link to session notes or research artifacts

### Key Metrics to Track

---

## Quick Reference

### Key People

### Critical JIRA Projects

### Slack Channels
</template>

