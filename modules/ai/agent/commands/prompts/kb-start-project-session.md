# /kb-start-project-session

Start a working session on an active KB project — read current state, orient, then do the work.

**Arguments**: `$ARGUMENTS` — project name (e.g. `mvcp`, `data-plane-availability`). If omitted, ask which project.

## What This Does

1. Loads the `kb` skill and its `references/project-management.md` reference
2. Reads `projects/<project>/progress.md` — orients on current state
3. Reads the most recent session file in `projects/<project>/sessions/` if more context needed
4. States understanding of current phase, what's in flight, and what's next — before acting
5. Does the work

**This command starts the session. Use `/kb-complete-project-session` when done.**

## Usage

```
/kb-start-project-session mvcp
/kb-start-project-session data-plane-availability
/kb-start-project-session          # will ask which project
```

## State Artifacts

| Artifact | Path | Role |
|:---------|:-----|:-----|
| Project overview | `projects/<project>/<project>.md` | Stable context — read, rarely change |
| Progress | `projects/<project>/progress.md` | Current state — read first |
| Recent sessions | `projects/<project>/sessions/` | Additional context if needed |

## Skills to Load

Always load:
- `kb` — conventions, vault structure, load `references/project-management.md`
- `obsidian-markdown` — for creating and editing vault files

Load if needed:
- `jujutsu` — for commit workflow detail
- `obsidian-cli` — if Obsidian is open and you want to use the CLI
