---
description: Finalize and wrap up a planning cycle
argument-hint: [optional-focus-area]
---

You are finalizing a planning workflow. Your task is to ensure all deliverables are complete, validated, and ready for execution.

**Finalization Focus**: $ARGUMENTS

If provided, the focus area (e.g., "security review", "stakeholder signoff", "handoff preparation") directs the finalization toward specific validation concerns. Otherwise, I'll perform a comprehensive completeness review based on the planning type.

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

## Subagent Delegation

During finalization, subagents can provide quality assurance reviews and help fill gaps identified in the completeness check.

### Available Finalization Subagents

| Subagent | Specialty | When to Delegate |
|----------|-----------|------------------|
| `roadmap-builder` | Strategic alignment validation | Roadmap finalization, ensuring OKR alignment |
| `project-planner` | Scope/risk/resource review | Project artifact validation, risk register completeness |
| `task-planner` | Story quality, INVEST criteria | Sprint backlog validation, acceptance criteria review |
| `codebase-analyst` | Technical feasibility review | Validating technical assumptions in plans |
| `security-architect` | Security review | Validating security considerations in plans |

### Delegation Criteria

Delegate during finalization when:
- **Gap filling**: Completeness review identifies missing elements requiring expertise
- **Quality validation**: Artifacts benefit from expert review before handoff
- **Cross-domain review**: Plans span multiple domains needing specialized validation
- **Lessons learned**: Capturing insights requires domain-specific retrospection

### Handoff Process

**Context to provide subagent:**
```
1. Planning type and artifacts to review
2. Specific gaps or concerns identified
3. Quality criteria for this planning type
4. Handoff requirements for next phase
5. Stakeholder expectations
```

**Expected deliverables from subagent:**
- Validation report with findings
- Gap remediation content (if filling gaps)
- Quality improvement recommendations
- Handoff readiness assessment

### Integration Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                  planning-finalize (orchestrator)                │
├─────────────────────────────────────────────────────────────────┤
│  1. Completeness review against checklist                       │
│  2. For each gap or quality concern:                             │
│     ├── Minor issues → resolve directly                         │
│     ├── Expertise gaps → delegate to appropriate subagent       │
│     └── Cross-domain issues → parallel subagent review          │
│  3. Quality validation (can delegate specialized reviews)       │
│  4. Integrate subagent outputs into final artifacts             │
│  5. Package deliverables and prepare handoff                    │
│  6. Document lessons learned (can delegate to relevant experts) │
│  7. Commit finalization and archive                              │
└─────────────────────────────────────────────────────────────────┘
```

## Process

1. I'll review all planning artifacts in the project directory
2. I'll validate completeness against the appropriate checklist
3. I'll identify any gaps and assess whether subagent expertise is needed
4. I'll resolve gaps directly or delegate to subagents as appropriate
5. I'll integrate all outputs and create the finalization summary
6. I'll prepare handoff materials for the next phase
7. I'll commit the changes to version control with a descriptive message

## Formatting Guidelines

All planning artifacts must follow the markdown formatting standards defined in the global `markdown-formatting` rule. Key requirements include JIRA ticket hyperlinks, ISO date formats, consistent status indicators, and proper document structure.

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

