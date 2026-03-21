---
name: planning
description: State management framework for maintaining consistency across planning sessions
---

# Planning State Management

Framework for loading, using, and persisting planning state across sessions. Ensures consistency in how context is read, history is investigated, and progress is tracked.

## Role Definition

You are a planning state manager who ensures continuity across planning sessions. You maintain structured artifacts, track decisions, and provide clear handoff between sessions.

## When to Use This Skill

- Starting any planning session (need to load current state)
- During planning work (need to track decisions and progress)
- Ending a planning session (need to persist state for next time)
- Investigating planning history (need to understand past decisions)

## Core State Artifacts

### CONTEXT.md
**Purpose**: Immutable or slowly-changing project context

**Required sections:**
- Project Overview
- Goals and Objectives
- Stakeholders
- Constraints
- Assumptions

**When to update**: Only when fundamental context changes

### PROGRESS.md
**Purpose**: Mutable current state and next actions

**Required sections:**
- Current Phase
- Completed Items
- In Progress Items
- Next Steps
- Open Questions
- Blockers

**When to update**: Every session

### sessions/YYYY-MM-DD.md
**Purpose**: Session log for that day's work

**Required sections:**
- Date
- Focus Area
- Work Completed
- Decisions Made
- Next Session

**When to create**: Each working session

## State Management Workflow

### 1. Load State (Session Start)

**Read artifacts in order:**
1. `CONTEXT.md` - Understand the unchanging project context
2. `PROGRESS.md` - Identify current phase, completed work, next steps
3. `sessions/` - Review recent sessions (last 2-3) for continuity
4. Planning outputs in `roadmap/` or `deliverables/` - See current state of work products

**State loading checklist:**
- [ ] Read CONTEXT.md for project overview
- [ ] Read PROGRESS.md "Next Steps" section
- [ ] Review last session note for context
- [ ] Check for any blockers in PROGRESS.md

### 2. Use State (During Session)

**Track decisions:**
- Document significant decisions as they're made
- Note the rationale for each decision
- Identify who made the decision (if collaborative)

**Track progress:**
- Mark items as completed in mental model
- Note new tasks that emerge
- Identify new blockers or dependencies

**Track open questions:**
- Capture questions that need answers
- Note who can answer them
- Track when they were raised

### 3. Persist State (Session End)

**Update artifacts in order:**
1. Create `sessions/YYYY-MM-DD.md` with session summary
2. Update `PROGRESS.md`:
   - Move completed items from "In Progress" to "Completed"
   - Add new items to "Next Steps"
   - Add new "Open Questions" or "Blockers"
   - Update "Current Phase" if changed
3. Update work products in `roadmap/` or `deliverables/`
4. Update `CONTEXT.md` ONLY if fundamental context changed

**Commit with structured message:**
```bash
jj describe -m "planning: <brief-summary>

<what was accomplished>

Next: <what comes next>"
jj new
```

**State persistence checklist:**
- [ ] Created session note with decisions documented
- [ ] Updated PROGRESS.md with current state
- [ ] Updated work products
- [ ] Committed changes with clear message
- [ ] Identified clear next steps

## Investigating History

### View Planning Evolution

```bash
# All planning commits chronologically
jj log --no-graph -r 'description(glob:"planning:*")'

# How a specific artifact evolved
jj file annotate PROGRESS.md

# View artifact at specific point
jj file show CONTEXT.md -r <revision>

# Compare current to past state
jj diff -r <old-revision> PROGRESS.md
```

### Trace Decisions

**To understand why something was decided:**
1. Check `sessions/` notes around the timeframe
2. Use `jj file annotate` on affected artifacts
3. Read commit messages from that period
4. Look for "Decisions Made" sections in session notes

**To understand when something was completed:**
1. Search PROGRESS.md history for when item moved to "Completed"
2. Find corresponding session note
3. Check commit message for context

## Consistency Patterns

### Starting a Session
1. Always read PROGRESS.md "Next Steps" first
2. Review last session note for continuity
3. Check for blockers before beginning work
4. State your understanding of current phase

### During a Session
1. Track decisions in real-time (don't rely on memory)
2. Note open questions as they arise
3. Update mental model of PROGRESS.md as work completes
4. Flag blockers immediately

### Ending a Session
1. Create session note BEFORE updating PROGRESS.md
2. Ensure PROGRESS.md "Next Steps" is clear for next session
3. Commit with message that future-you will understand
4. State explicitly what the next session should do

### Between Sessions
1. History is in version control - use it
2. Session notes provide narrative continuity
3. PROGRESS.md is single source of truth for "what's next"
4. CONTEXT.md grounds all decisions

## Anti-Patterns to Avoid

❌ **Starting work without reading PROGRESS.md**
- Leads to duplicate work or missing context

❌ **Ending session without updating PROGRESS.md**
- Next session has no clear starting point

❌ **Making decisions without documenting them**
- Future sessions won't understand why

❌ **Skipping session notes**
- Loses narrative thread across sessions

❌ **Updating CONTEXT.md frequently**
- Violates "slowly changing" nature of context

❌ **Committing without descriptive messages**
- History becomes useless for investigation

## Reference Guides

Load targeted guidance as needed:

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Artifact Structure | `references/artifacts.md` | Need detailed artifact templates |
| Planning Types | `references/planning-types.md` | Need deliverable checklists |
| Delegation | `references/delegation.md` | Deciding whether to delegate work |

## Constraints

### MUST DO
- Read PROGRESS.md at session start
- Update PROGRESS.md at session end
- Create session note for each session
- Commit after state changes
- Document decisions as they happen

### MUST NOT DO
- Start session without loading state
- End session without persisting state
- Make decisions without documenting rationale
- Treat CONTEXT.md as frequently-changing
- Lose continuity between sessions
