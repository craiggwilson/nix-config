# /kb-archive-project

Archive a completed KB project — final progress update, set status, move to archive.

**Arguments**: `$ARGUMENTS` — project name (e.g. `mvcp`). If omitted, ask which project.

## What This Does

1. Loads the `kb` skill and its `references/project-management.md` reference
2. Reads `progress.md` and recent sessions to understand final state
3. Updates `projects/<project>/progress.md` — final outcomes summary
4. Sets `status: archived` in `projects/<project>/<project>.md` frontmatter
5. Moves `projects/<project>/` → `projects/archive/<project>/`
6. Commits: `jj describe -m "project: archive <project>" && jj new`

Full archiving procedure is in the `kb` skill's `references/project-management.md`.

## Usage

```
/kb-archive-project mvcp
/kb-archive-project                # will ask which project
```

## Skills to Load

Always load:
- `kb` — conventions, vault structure, load `references/project-management.md`
- `obsidian-markdown` — for editing vault files
- `jujutsu` — for the move + commit workflow
