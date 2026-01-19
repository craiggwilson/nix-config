---
description: Continue an in-progress planning cycle
argument-hint: [project-directory]
---

You are continuing an existing planning workflow. Your task is to pick up where the previous session left off and drive progress toward completion.

**Project Directory**: $ARGUMENTS

## Resume Process

### 1. Context Recovery
First, I will review the current state by examining:

- `CONTEXT.md` - Project context and requirements
- `PROGRESS.md` - Current status and next steps
- `sessions/` - Recent session notes for continuity
- Any planning artifacts in `roadmap/`, `deliverables/`, or `research/`

### 2. Status Assessment
I will determine:

- What phase we're in (Discovery, Analysis, Synthesis, Validation)
- What was completed in previous sessions
- What blockers or open questions exist
- What the immediate next actions are

### 3. Work Continuation
Based on the assessment, I will:

- Address any resolved blockers
- Continue work on in-progress items
- Generate next planning artifacts
- Update PROGRESS.md with current session work

### 4. Session Documentation
At the end of this session, I will:

- Create/update `sessions/YYYY-MM-DD.md` with session notes
- Update `PROGRESS.md` with completed and next items
- Document any decisions in `DECISIONS.md` if applicable
- Identify what needs to happen in the next session

## Deliverable Progress Tracking

### Roadmap Planning Deliverables
- [ ] Discovery findings documented
- [ ] Themes and initiatives defined
- [ ] Quarterly structure drafted
- [ ] Dependencies mapped
- [ ] Stakeholder validation complete
- [ ] Final roadmap approved

### Project Planning Deliverables
- [ ] Project charter complete
- [ ] Scope statement finalized
- [ ] WBS developed
- [ ] Resource plan created
- [ ] Risk register populated
- [ ] Communication plan ready
- [ ] Kickoff conducted

### Task Planning Deliverables
- [ ] User stories written
- [ ] Acceptance criteria defined
- [ ] Estimates completed
- [ ] Dependencies mapped
- [ ] Sprint backlog ready
- [ ] Sprint goal defined

## Process

1. I'll review the project directory to understand current state
2. I'll summarize where we left off and what's next
3. I'll continue work on the highest priority items
4. I'll update all tracking documents
5. I'll commit the changes to version control with a descriptive message
6. I'll provide clear next steps for the following session

## Version Control

After updating planning documents, I will commit the changes:

```bash
# Stage and commit session work
jj describe -m "planning: continue [project-name] planning session

Session: YYYY-MM-DD
- [Summary of work completed this session]
- Updated PROGRESS.md with current status
- [Other artifacts created/updated]

Next: [Brief description of next steps]"
jj new  # Create a new change for subsequent work
```

The commit message should:
- Start with `planning:` prefix
- Include the session date
- Summarize what was accomplished
- Note what comes next

### Retrieving Context History

If context from previous sessions is unclear or needs verification, retrieve it from the repository history:

```bash
# View history of planning changes
jj log --no-graph -r 'description(glob:"planning:*")'

# Show how a specific file evolved
jj file annotate [file-path]

# View a file at a specific revision
jj file show [file-path] -r [revision]

# Compare current state to previous version
jj diff -r [revision] [file-path]
```

This history provides full traceability of how planning artifacts evolved across sessions.

**Let me review the project directory and resume the planning work.**

