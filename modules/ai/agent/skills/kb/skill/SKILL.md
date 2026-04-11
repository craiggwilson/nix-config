---
name: kb
description: Personal knowledge base conventions and session workflow for ~/Projects/kb
---

# Personal Knowledge Base (KB)

Framework for working with the Obsidian knowledge base at `~/Projects/kb`. Full conventions are in `~/Projects/kb/AGENTS.md` — read it at the start of any KB session.

## Structure

| Location | Purpose |
|:---------|:--------|
| `inbox/inbox.md` | Raw capture buffer — drop anything here |
| `notes/<topic>.md` | Atomic zettelkasten notes (flat, title-based) |
| `mocs/<area>.md` | Maps of Content — curated entry points into notes |
| `projects/<name>/` | Project overview, progress, and session files |
| `reference/<topic>.md` | Stable lookup facts |
| `people/<name>.md` | One file per person |
| `codebases/<name>/` | Codebase orientation notes |

## File Types

| Type | Schema |
|:-----|:-------|
| `note` | Atomic zettelkasten note — one idea, densely linked |
| `moc` | Map of Content — navigable entry point into a topic cluster |
| `project` | Project overview — goals, status, people, todos |
| `progress` | Current state snapshot — read first, update last |
| `session` | What happened in a work session |
| `reference` | Stable lookup facts |
| `person` | Who someone is |

## Session Workflow

### Starting
1. Read `projects/<project>/progress.md` — current phase, in-flight, next up, blockers
2. Read 1-2 recent session files if more context needed
3. State your understanding before doing any work

### During
- Track decisions as they happen
- Note blockers and open questions immediately

### Ending
1. Update `projects/<project>/progress.md` — reflect actual current state
2. Create `projects/<project>/sessions/YYYY-MM-DD.md`
3. Commit: `jj describe -m "<brief description>" && jj new`

## Frontmatter

All files have YAML frontmatter with **alphabetized** fields. Key fields:
- `type`: categorizes the note (note, moc, project, progress, session, reference, person)
- `updated`: ISO 8601 date, updated whenever the file changes
- `project`: wikilink to project overview, e.g. `"[[projects/mvcp/mvcp]]"`

## Internal Links

Use Obsidian wikilinks with full vault-root paths:
```
[[notes/active-passive-design]]
[[mocs/atlas-control-plane]]
[[projects/mvcp/progress|progress]]
[[people/craig-wilson|Craig Wilson]]
[[reference/mongodb/fiscal-calendar]]
```

## Reference Guide

Load detailed guidance based on context:

| Topic | Reference | Load When |
|:------|:----------|:----------|
| Inbox processing | `references/process-inbox.md` | User asks to process inbox, synthesize captures, or clear inbox items |

## Anti-Patterns

❌ Creating a note without first checking if one already exists  
❌ Ending a session without updating `progress.md`  
❌ Using git instead of jj  
❌ Putting atomic knowledge in projects/ instead of notes/  
❌ Creating a MOC with fewer than 3 linked notes  
