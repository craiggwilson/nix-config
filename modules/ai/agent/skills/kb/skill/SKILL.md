---
name: kb
description: Personal knowledge base conventions and session workflow for ~/Projects/kb
---

# Personal Knowledge Base (KB)

Framework for working with the Obsidian knowledge base at `~/Projects/kb`. Full conventions are in `~/Projects/kb/AGENTS.md` — read it at the start of any KB session.

## File Types

| Type | Location | Purpose |
|:-----|:---------|:--------|
| `project` | `projects/<name>/<name>.md` | Overview, goals, people, todos — stable context |
| `progress` | `projects/<name>/progress.md` | Current state — **read first, update last** |
| `session` | `projects/<name>/sessions/YYYY-MM-DD.md` | What happened today |
| `research` | `research/<area>/<topic>.md` | Synthesized deep-dive notes |
| `reference` | `reference/<topic>.md` | Stable lookup facts |
| `person` | `people/<name>.md` | One file per person |

## Session Workflow

### Starting
1. Read `projects/<project>/progress.md` — current phase, in-flight, next up, blockers
2. Read 1-2 recent session files if more context needed
3. State your understanding of where things stand before doing any work

### During
- Track decisions as they happen — don't rely on memory
- Note blockers and open questions immediately

### Ending
1. Update `projects/<project>/progress.md` — reflect actual current state
2. Create `projects/<project>/sessions/YYYY-MM-DD.md` using the session template
3. Commit: `jj describe -m "<brief description>" && jj new`

## Frontmatter

All files have YAML frontmatter with alphabetized fields. Key fields:
- `type`: categorizes the note (project, progress, session, research, reference, person)
- `updated`: ISO 8601 date, updated whenever the file changes
- `project`: wikilink to the project overview, e.g. `"[[projects/mvcp/mvcp]]"`

## Internal Links

Use Obsidian wikilinks with full vault-root paths:
```
[[projects/mvcp/progress|progress]]
[[people/craig-wilson|Craig Wilson]]
[[reference/mongodb/fiscal-calendar]]
```

## Finding Information

The KB vault is indexed by engram, so `engram-search` is the fastest way to locate relevant notes — it searches across all vault files by semantic similarity and returns snippets with file paths. Use it before reaching for the Obsidian CLI or manually navigating the vault structure.

## Storing information — KB vs engram

| What | Where |
|:-----|:------|
| Stable, permanent knowledge (decisions, research, references) | Write a KB file |
| Short-lived or session-scoped context worth recalling later | `engram-add` (type: episodic) |
| Standing preferences or constraints | `engram-add` (type: preference) |

Engram memories complement the KB — use them for things that don't warrant a full note but are worth remembering across sessions. The KB is for things you'd want to find and read in full; engram is for things you just want to surface as context.

## Anti-Patterns

❌ Starting work without reading `progress.md`
❌ Ending a session without updating `progress.md`
❌ Making decisions without recording them in the session file
❌ Using git instead of jj
❌ Manually browsing vault structure when `engram-search` would find it faster
