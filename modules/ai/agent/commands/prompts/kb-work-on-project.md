# /kb-work-on-project

Start a working session on an active KB project — read current state, orient, then do the work.

**Arguments**: `$ARGUMENTS` — project name (e.g. `mvcp`, `data-plane-availability`). If omitted, ask which project. May also be followed by initial instructions.

## What This Does

1. Loads the `kb` skill and its `references/project-management.md` reference
2. Reads `projects/<project>/progress.md` — orients on current state
3. Reads the most recent session file in `projects/<project>/sessions/` if more context needed
4. States understanding of current phase, what's in flight, and what's next — before acting
5. Does the work

**This command starts the session. Use `/kb-save-work-on-project` when done.**

## Usage

```
/kb-work-on-project mvcp
/kb-work-on-project data-plane-availability
/kb-work-on-project          # will ask which project
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

Load if needed:
- `jujutsu` — for commit workflow detail
