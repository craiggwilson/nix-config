# Project Management

How projects are structured, started, continued, and archived in this KB.

## Project Structure

```
projects/<name>/
├── <name>.md       # Project overview — stable context, rarely changes
├── progress.md     # Current state — read first, update last every session
├── sessions/
│   └── YYYY-MM-DD.md   # Session log — one per work session
└── decisions/      # Optional — ADRs or significant choices
```

## File Roles

### `<name>.md` — Project Overview
Stable context document. Sections: Overview, Goal, Current Status (link to progress), Key People, Program Structure / Pillars, Todos, Key Dependencies, Reference Documents, Related.

Do **not** update this frequently — it describes what the project *is*, not where it stands.

### `progress.md` — Current State
The **first file read** at the start of every session. Keep under 80 lines.

Sections: Current Status, In Flight, Next Up, Blocked, Decisions Made, Risks & Gaps.

Update at the **end** of every session to reflect actual current state. This is the handoff document between sessions.

### `sessions/YYYY-MM-DD.md` — Session Log
Created at the **end** of each session. Sections: Focus, Context (link to progress), Work Log, Key Decisions, Blockers / Risks, Next Steps, Related.

## Frontmatter

### Project overview
```yaml
---
aliases: []
created: YYYY-MM-DD
dri: "[[people/craig-wilson]]"
due: YYYY-MM-DD
priority: high          # low | medium | high
related: []
status: active          # active | paused | archived
tags:
  - project
type: project
updated: YYYY-MM-DD
---
```

### Progress
```yaml
---
project: "[[projects/<name>/<name>]]"
tags:
  - progress
type: progress
updated: YYYY-MM-DD
---
```

### Session
```yaml
---
created: YYYY-MM-DD
date: YYYY-MM-DD
project: "[[projects/<name>/<name>]]"
tags:
  - session
type: session
---
```

## Starting a New Project

1. Create `projects/<name>/` directory
2. Create `projects/<name>/<name>.md` from the project template
3. Create `projects/<name>/progress.md` from the progress template — initial state
4. Commit: `jj describe -m "project: start <name>" && jj new`

## Session Workflow

**Starting**: Use `/kb-start-project-session`
1. Read `progress.md` — orient fully before doing anything
2. Read the most recent session file if more context is needed
3. State understanding of current state before acting
4. Do the work

**Completing**: Use `/kb-complete-project-session`
1. Update `progress.md` to reflect actual new state
2. Create `sessions/YYYY-MM-DD.md`
3. Commit: `jj describe -m "<project>: <description>" && jj new`

## Archiving a Project

Use `/kb-archive-project` when a project is fully done.

1. Update `progress.md` — write a final outcomes summary: what shipped, what didn't, key decisions made
2. Set `status: archived` in `<name>.md` frontmatter, update `updated:` date
3. Move the project directory:
   ```bash
   # From ~/Projects/kb
   mkdir -p projects/archive
   mv projects/<name> projects/archive/<name>
   ```
4. Obsidian resolves links by filename, not path — existing wikilinks in `notes/` and `mocs/` pointing
   to project files will continue to resolve correctly after the move.
5. Commit: `jj describe -m "project: archive <name>" && jj new`

**What to keep**: Everything — progress, sessions, decisions. The archive is a record, not a trash can.

**What not to do**: Don't delete session files, don't summarize-and-destroy, don't update `notes/` or
`mocs/` links (they resolve automatically).

## Decisions

Significant architectural or directional choices belong in `projects/<name>/decisions/` as individual files or inline in `<name>.md`. Format:

```markdown
## Decision: <title>
**Date**: YYYY-MM-DD  
**Status**: accepted  
**Context**: Why this decision was needed  
**Decision**: What was decided  
**Consequences**: What this implies going forward  
```

## Linking to Notes

Project files link **into** `notes/` for concepts — they do not duplicate knowledge. Example: a project overview links to `[[notes/active-passive-design]]` rather than re-explaining the pattern inline.
