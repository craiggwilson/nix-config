# /kb-continue-project

Continue work on an active KB project — read current state, do the work, update progress, log the session.

**Arguments**: `$ARGUMENTS` — project name (e.g. `mvcp`, `data-plane-availability`). If omitted, ask which project.

## What This Does

1. Loads the `kb` skill and its `references/project-management.md` reference
2. Reads `projects/<project>/progress.md` — orients on current state
3. Reads the most recent session file in `projects/<project>/sessions/` if more context needed
4. States understanding of current phase, what's in flight, and what's next — before acting
5. Does the work
6. Updates `projects/<project>/progress.md` to reflect actual new state
7. Creates `projects/<project>/sessions/YYYY-MM-DD.md`
8. Commits: `jj describe -m "<project>: <description>" && jj new`

## Usage

```
/kb-continue-project mvcp
/kb-continue-project data-plane-availability
/kb-continue-project                          # will ask which project
```

## State Artifacts

| Artifact | Path | Role |
|:---------|:-----|:-----|
| Project overview | `projects/<project>/<project>.md` | Stable context — read, rarely change |
| Progress | `projects/<project>/progress.md` | Current state — read first, update last |
| Session | `projects/<project>/sessions/YYYY-MM-DD.md` | Today's log — create at end |

## Skills to Load

Always load:
- `kb` — conventions, vault structure, load `references/project-management.md`
- `obsidian-markdown` — for creating and editing vault files

Load if needed:
- `jujutsu` — for commit workflow detail
- `obsidian-cli` — if Obsidian is open and you want to use the CLI
