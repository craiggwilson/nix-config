# Planning Artifacts

## CONTEXT.md

**Nature**: Slowly-changing project context

### Required Sections

**Project Overview**
- Brief description (2-3 sentences)
- Related JIRA tickets (as hyperlinks)
- Related projects or initiatives

**Goals and Objectives**
- Primary goal
- Secondary goals
- Success criteria

**Stakeholders**
| Role | Name | Interest | Contact |
|------|------|----------|---------|
| Sponsor | [name] | [what they care about] | [how to reach] |

**Constraints**
- Timeline constraints
- Resource constraints
- Technical constraints
- Organizational constraints

**Assumptions**
- List key assumptions
- Note what needs validation

### Update Frequency
Only update when:
- Project scope fundamentally changes
- New stakeholders join
- Major constraints change
- Key assumptions proven wrong

---

## PROGRESS.md

**Nature**: Current state and next actions (updated every session)

### Required Sections

**Current Phase**
```markdown
Current Phase: Discovery / Planning / Execution
Started: YYYY-MM-DD
```

**Completed Items**
```markdown
- [YYYY-MM-DD] Completed item with outcome
- [YYYY-MM-DD] Another completed item
```

**In Progress Items**
```markdown
- [ ] Item being worked on now
  - Started: YYYY-MM-DD
  - Owner: [name if collaborative]
  - Blockers: None / [blocker description]
```

**Next Steps**
```markdown
1. [Specific next action] - [Why/context]
2. [Another action] - [Why/context]
```

**Open Questions**
```markdown
- [Question text]?
  - Asked: YYYY-MM-DD
  - Needs: [who can answer]
  - Impacts: [what this blocks]
```

**Blockers**
```markdown
- [Blocker description]
  - Identified: YYYY-MM-DD
  - Blocking: [what it blocks]
  - Resolution: [what needs to happen]
```

### Update Frequency
**Every session:**
- Move completed items from "In Progress" to "Completed"
- Update "Next Steps"
- Add/resolve "Open Questions"
- Add/resolve "Blockers"

---

## sessions/YYYY-MM-DD.md

**Nature**: Daily session log

### Template

```markdown
# Planning Session: YYYY-MM-DD

## Focus Area
[What this session aimed to accomplish]

## Work Completed
- [Specific thing done]
- [Another thing done]

## Decisions Made
- **Decision**: [What was decided]
  - **Rationale**: [Why]
  - **Alternatives considered**: [What else was considered]
  - **Decided by**: [Who decided, if collaborative]

## Open Questions Added
- [Question]? (see PROGRESS.md)

## Blockers Identified
- [Blocker] (see PROGRESS.md)

## Next Session
[What the next session should focus on]
```

### Guidelines
- Create one per working session
- Write at END of session (ensures completeness)
- Be specific about decisions and rationale
- Provide clear handoff to next session

---

## Planning Outputs

Location: `roadmap/` or `deliverables/`

### Structure by Planning Type

**Roadmap Planning** → `roadmap/`
- `roadmap/FYXX-QX.md` - Quarterly roadmaps
- `roadmap/themes.md` - Strategic themes
- `roadmap/dependencies.md` - Cross-initiative dependencies

**Project Planning** → `deliverables/`
- `deliverables/charter.md` - Project charter
- `deliverables/scope.md` - Scope statement
- `deliverables/wbs.md` - Work breakdown structure
- `deliverables/risks.md` - Risk register

**Task Planning** → `deliverables/`
- `deliverables/backlog.md` - Sprint backlog
- `deliverables/stories/` - Individual user stories

### Update Pattern
These are work products that evolve during planning:
1. Created during planning sessions
2. Referenced in PROGRESS.md "In Progress" or "Completed"
3. Committed alongside PROGRESS.md updates
4. Session notes reference specific updates made
