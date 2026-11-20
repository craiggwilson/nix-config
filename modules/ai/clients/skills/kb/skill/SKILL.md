---
name: kb
description: Knowledge base conventions and session workflow for the Obsidian vaults at ~/Projects/github.com/craiggwilson/kb (personal) and ~/Projects/github.com/craiggwilson/kb-work (MongoDB work)
---

# Knowledge Base (KB)

Framework for working with Craig's Obsidian knowledge base. Both vaults use the **same** conventions, file types, frontmatter, and session workflow — only the content and location differ. Pick the right vault first, then follow the shared rules below.

## Which vault

| Vault | Path | Use for |
|:------|:-----|:--------|
| `kb` (personal) | `~/Projects/github.com/craiggwilson/kb` | Non-work projects, captures, personal reference |
| `kb-work` (work) | `~/Projects/github.com/craiggwilson/kb-work` | MongoDB engineering context: projects, PRs, briefings, daily plans, codebases, notes, reference |

- Work task (MongoDB, engineering, a PR, a work project) → `kb-work`.
- Personal task (a personal project, personal reference) → `kb`.
- When unsure, ask which vault before writing anything.
- Full conventions for the chosen vault: `<vault>/AGENTS.md` — read it at the start of any KB session.

## Structure (shared)

| Location | Purpose |
|:---------|:--------|
| `inbox/inbox.md` | Raw capture buffer — drop anything here |
| `projects/<name>/` | Project overview, progress, and session files |
| `notes/<topic>.md` | Atomic zettelkasten notes (work vault) |
| `mocs/<area>.md` | Maps of Content — entry points into notes (work vault) |
| `people/<name>.md` | One file per person (work vault) |
| `codebases/<name>/` | Codebase orientation notes (work vault) |
| `reference/<topic>.md` | Stable lookup facts |
| `briefings/`, `daily/`, `prs/`, `docs/` | Generated work artifacts (work vault) |
| `templates/` | Obsidian templates |
| `AGENTS.md` | Full vault conventions |

## File Types

| Type | Schema |
|:-----|:-------|
| `project` | Project overview — goals, status, people, todos |
| `progress` | Current state snapshot — read first, update last |
| `session` | What happened in a work session |
| `note` | Atomic zettelkasten note |
| `moc` | Map of Content — entry point into a topic cluster |
| `decision` | A decision record |
| `person` | Who someone is |
| `reference` | Stable lookup facts |

## Session Workflow (shared)

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
- `type`: categorizes the note (project, progress, session, note, moc, decision, reference, person)
- `updated`: ISO 8601 date, updated whenever the file changes
- `project`: wikilink to project overview, e.g. `"[[projects/mvcp/mvcp]]"`

## Internal Links

Use Obsidian wikilinks with full vault-root paths:
```
[[projects/mvcp/progress|progress]]
[[people/craig-wilson|Craig Wilson]]
[[notes/active-passive-design]]
```

## Reference Guide

Load detailed guidance based on context:

| Topic | Reference | Load When |
|:------|:----------|:----------|
| Zettelkasten | `references/zettelkasten.md` | Creating or linking notes, unsure what belongs in notes/ vs elsewhere |
| Research | `references/research.md` | Conducting research, creating new notes from investigation |
| Project management | `references/project-management.md` | Starting, continuing, or completing a project |
| Inbox processing | `references/process-inbox.md` | Processing inbox, synthesizing captures, clearing inbox items |

## Anti-Patterns

❌ Creating a note without first checking if one already exists  
❌ Ending a session without updating `progress.md`  
❌ Using git instead of jj  
❌ Writing work content into the personal vault, or personal content into the work vault  
❌ Creating a MOC with fewer than 3 linked notes
