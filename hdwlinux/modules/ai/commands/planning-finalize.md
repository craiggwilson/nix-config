---
description: Finalize and wrap up a planning cycle
argument-hint: [project-directory]
---

You are finalizing a planning workflow. Your task is to ensure all deliverables are complete, validated, and ready for execution.

**Project Directory**: $ARGUMENTS

## Finalization Process

### 1. Completeness Review
Review all planning artifacts for completeness:

**For Roadmap Planning:**
- [ ] All quarters have defined themes and objectives
- [ ] Initiatives are prioritized and sequenced
- [ ] Dependencies are documented and validated
- [ ] Resource requirements are identified
- [ ] Success metrics are defined
- [ ] Risk assessment is complete
- [ ] Stakeholder buy-in is documented

**For Project Planning:**
- [ ] Project charter is approved
- [ ] Scope statement is finalized and signed off
- [ ] WBS is complete to work package level
- [ ] Resource allocation is confirmed
- [ ] Schedule baseline is set
- [ ] Risk register is reviewed and accepted
- [ ] Communication plan is distributed
- [ ] RACI is approved
- [ ] Kickoff is scheduled or complete

**For Task Planning:**
- [ ] All stories meet INVEST criteria
- [ ] Acceptance criteria are testable
- [ ] Estimates are validated by team
- [ ] Dependencies are cleared or managed
- [ ] Sprint goal is defined and agreed
- [ ] Definition of Done is confirmed
- [ ] Team has committed to sprint backlog

### 2. Quality Validation
Ensure quality standards are met:

- Artifacts are properly formatted and readable
- Cross-references are consistent
- Assumptions are documented
- Risks are adequately addressed
- All open questions are resolved or tracked

### 3. Deliverable Packaging
Create final deliverable package:

- Executive summary document
- Complete artifact set
- Decision log
- Risk register
- Open items list (if any)
- Handoff notes

### 4. Transition Preparation
Prepare for handoff to execution:

**Roadmap → Project Planning:**
- Initiative briefs for each roadmap item
- Priority and sequencing guidance
- Resource allocation recommendations

**Project → Task Planning:**
- Work packages ready for decomposition
- Technical context for teams
- Sprint planning preparation

**Task → Execution:**
- Sprint backlog is visible to team
- Dependencies are coordinated
- Blockers are escalated

### 5. Archive and Document
Finalize documentation:

- Update `PROGRESS.md` with completion status
- Create final session note in `sessions/`
- Archive working documents
- Update `CONTEXT.md` if context changed
- Create lessons learned summary

## Finalization Checklist Output

I will generate a final checklist showing:
```markdown
# Planning Finalization: [Project Name]

## Completion Status
| Deliverable | Status | Notes |
|-------------|--------|-------|
| [Item]      | ✅/⚠️/❌ | [Notes] |

## Open Items
- [ ] [Any remaining items with owners]

## Handoff Summary
[Brief summary of what's ready for the next phase]

## Lessons Learned
- [Key learnings from this planning cycle]

## Next Steps
1. [Immediate next action]
2. [Follow-up action]
```

## Process

1. I'll review all planning artifacts in the project directory
2. I'll validate completeness against the appropriate checklist
3. I'll identify any gaps and either resolve them or document them
4. I'll create the finalization summary
5. I'll prepare handoff materials for the next phase
6. I'll commit the changes to version control with a descriptive message

## Version Control

After finalizing the planning cycle, I will commit the changes:

```bash
# Stage and commit finalization
jj describe -m "planning: finalize [project-name] [planning-type] planning

Completed: YYYY-MM-DD
- All deliverables validated and complete
- Final session notes archived
- Handoff materials prepared

Deliverables:
- [List key deliverables]

Ready for: [Next phase - e.g., execution, project planning, task planning]"
jj new  # Create a new change for subsequent work
```

The commit message should:
- Start with `planning:` prefix
- Indicate this is a finalization
- List the completed deliverables
- Note what phase comes next

### Retrieving Context History

The complete history of the planning cycle can be retrieved from the repository:

```bash
# View all planning commits for this cycle
jj log --no-graph -r 'description(glob:"planning:*")'

# Show how a specific file evolved
jj file annotate [file-path]

# View a file at a specific revision
jj file show [file-path] -r [revision]

# Compare final state to initial init
jj diff -r [init-revision] [file-path]
```

This history serves as a complete audit trail of the planning cycle, useful for retrospectives and future reference.

**Let me review the project directory and begin the finalization process.**

