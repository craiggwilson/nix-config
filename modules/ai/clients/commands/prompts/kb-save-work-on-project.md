# /kb-save-work-on-project

Complete the current working session on a KB project — update progress, create session log, commit.

**Arguments**: `$ARGUMENTS` — project name (e.g. `mvcp`, `data-plane-availability`). If omitted, ask which project.

## What This Does

1. Loads the `kb` skill and its `references/project-management.md` reference
2. Updates `projects/<project>/progress.md` to reflect actual new state
3. Creates `projects/<project>/sessions/YYYY-MM-DD.md` — session log
4. Commits: `jj describe -m "<project>: <description>" && jj new`

**Use this after `/kb-work-on-project` when the session's work is done.**

## Session Log Sections

```markdown
---
created: YYYY-MM-DD
date: YYYY-MM-DD
project: "[[projects/<project>/<project>]]"
tags:
  - session
type: session
---

# YYYY-MM-DD

## Focus
What this session set out to do.

## Work log
What actually happened — decisions, changes, findings.

## Key decisions
Significant choices made and why.

## Blockers / risks
What's stuck or concerning.

## Next steps
What comes next.

## Related
Wikilinks to notes, MOCs, or other files touched.
```

## Usage

```
/kb-save-work-on-project mvcp
/kb-save-work-on-project data-plane-availability
/kb-save-work-on-project       # will ask which project
```

## State Artifacts Updated

| Artifact | Path | Action |
|:---------|:-----|:-------|
| Progress | `projects/<project>/progress.md` | Update to reflect new state |
| Session | `projects/<project>/sessions/YYYY-MM-DD.md` | Create |

## Skills to Load

Always load:
- `kb` — conventions, vault structure, load `references/project-management.md`
- `obsidian-markdown` — for creating vault files

Load if needed:
- `jujutsu` — for commit workflow detail
