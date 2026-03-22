# Session Command

Start a KB project session from anywhere.

**Arguments**: `$ARGUMENTS` — project name (e.g. `mvcp`, `data-plane-availability`). If omitted, ask which project.

## What This Does

1. Loads the `kb` skill for KB conventions and workflow
2. Reads `~/Projects/kb/projects/<project>/progress.md` — orients on current state
3. Reviews the most recent session file in `~/Projects/kb/projects/<project>/sessions/`
4. States understanding of current phase, what's in flight, and what's next
5. Does the work
6. Updates `progress.md` to reflect new state
7. Creates `~/Projects/kb/projects/<project>/sessions/YYYY-MM-DD.md`
8. Commits: `jj describe -m "<description>" && jj new` (run from `~/Projects/kb`)

## Usage

```
/session mvcp
/session data-plane-availability
/session                          # will ask which project
```

## Skills to Load

Always load at start:
- `kb` — KB conventions, file types, session workflow
- `obsidian-markdown` — for creating/editing vault files

Load if needed:
- `obsidian-cli` — if Obsidian is open and you want to use the CLI
- `jujutsu` — for commit workflow detail

## State Artifacts

| Artifact | Path | Role |
|:---------|:-----|:-----|
| Project overview | `projects/<project>/<project>.md` | Stable context — read, don't overwrite |
| Progress | `projects/<project>/progress.md` | Current state — read first, update last |
| Session | `projects/<project>/sessions/YYYY-MM-DD.md` | Today's log — create at end |

**Now load the `kb` skill and begin the session.**
