# /kb-complete-project

Wrap up a completed KB project — final session, archive state, update frontmatter.

**Arguments**: `$ARGUMENTS` — project name (e.g. `mvcp`). If omitted, ask which project.

## What This Does

1. Loads the `kb` skill and its `references/project-management.md` reference
2. Reads current `progress.md` and recent sessions to understand final state
3. Does any remaining wrap-up work
4. Updates `progress.md` — final status summary, outcomes
5. Updates `<project>.md` frontmatter: `status: archived`
6. Creates a final `sessions/YYYY-MM-DD.md` capturing outcomes and decisions
7. Asks whether to move the project to `projects/archive/<name>/`
8. Commits: `jj describe -m "project: complete <name>" && jj new`

## Usage

```
/kb-complete-project mvcp
/kb-complete-project                # will ask which project
```

## Skills to Load

Always load:
- `kb` — conventions, vault structure, load `references/project-management.md`
- `obsidian-markdown` — for editing vault files

Load if needed:
- `jujutsu` — for commit workflow detail
