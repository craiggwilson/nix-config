# /kb-start-project

Create a new project in the KB — directory structure, overview, and initial progress file.

**Arguments**: `$ARGUMENTS` — project name/slug (e.g. `data-plane-availability`, `mvcp`). If omitted, ask for the project name and a brief description.

## What This Does

1. Loads the `kb` skill and its `references/project-management.md` reference
2. Creates `~/Projects/kb/projects/<name>/` directory
3. Creates `projects/<name>/<name>.md` — project overview with frontmatter and skeleton sections
4. Creates `projects/<name>/progress.md` — initial progress file
5. Asks for: goal, key people, priority, due date — fills frontmatter accordingly
6. Commits: `jj describe -m "project: start <name>" && jj new`

## Usage

```
/kb-start-project data-plane-availability
/kb-start-project                          # will ask for project name and context
```

## State Artifacts Created

| Artifact | Path |
|:---------|:-----|
| Project overview | `projects/<name>/<name>.md` |
| Initial progress | `projects/<name>/progress.md` |

## Skills to Load

Always load:
- `kb` — conventions, vault structure, load `references/project-management.md`
- `obsidian-markdown` — for creating vault files

Load if needed:
- `jujutsu` — for commit workflow detail
