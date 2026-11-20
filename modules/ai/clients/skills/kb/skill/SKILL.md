---
name: kb
description: Personal knowledge base conventions and session workflow for the `kb` vault at ~/Projects/github.com/craiggwilson/kb
---

# Personal Knowledge Base (KB)

Framework for working with the personal Obsidian vault at `~/Projects/github.com/craiggwilson/kb`. Full conventions are in `~/Projects/github.com/craiggwilson/kb/AGENTS.md` — read it at the start of any KB session.

> For MongoDB work, use the `kb-work` vault at `~/Projects/github.com/craiggwilson/kb-work` instead.

## Structure

| Location | Purpose |
|:---------|:--------|
| `inbox/inbox.md` | Raw capture buffer — drop anything here |
| `projects/<name>/` | Project overview, progress, and session files |
| `templates/` | Obsidian templates |
| `AGENTS.md` | Full vault conventions |

## File Types

| Type | Schema |
|:-----|:-------|
| `project` | Project overview — goals, status, people, todos |
| `progress` | Current state snapshot — read first, update last |
| `session` | What happened in a work session |
| `decision` | A decision record |
| `person` | Who someone is |
| `reference` | Stable lookup facts |

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
- `type`: categorizes the note (project, progress, session, decision, reference, person)
- `updated`: ISO 8601 date, updated whenever the file changes
- `project`: wikilink to project overview, e.g. `"[[projects/bloobiverse/bloobiverse]]"`

## Internal Links

Use Obsidian wikilinks with full vault-root paths:
```
[[projects/bloobiverse/progress|progress]]
[[people/craig-wilson|Craig Wilson]]
```

## Reference Guide

Load detailed guidance based on context:

| Topic | Reference | Load When |
|:------|:----------|:----------|
| Project management | `references/project-management.md` | Starting, continuing, or completing a project |
| Inbox processing | `references/process-inbox.md` | Processing inbox, synthesizing captures, clearing inbox items |

## Anti-Patterns

❌ Creating a note without first checking if one already exists  
❌ Ending a session without updating `progress.md`  
❌ Using git instead of jj  
❌ Putting knowledge that belongs in `notes/` inside a project file
