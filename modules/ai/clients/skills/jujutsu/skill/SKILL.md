---
name: jujutsu
description: Use when working with Jujutsu (jj) requiring change management, rebasing, or Git interop. Invoke for jj commands, revsets, bookmarks, squashing.
---

# Jujutsu

Change management, rebasing, and Git interoperability using Jujutsu's simpler mental model.

## When to Use This Skill

- Creating and editing changes
- Rebasing and squashing
- Working with bookmarks
- Using revsets for queries
- Interoperating with Git
- Recovering from mistakes

## Core Workflow

1. **New** - Create new change with `jj new`
2. **Edit** - Make changes (automatically tracked)
3. **Describe** - Add description with `jj describe`
4. **Rebase** - Move changes onto target with `jj rebase`
5. **Push** - Push bookmark with `jj git push`

## Workspace Integration Workflow

When integrating an isolated workspace back into mainline, **always rebase onto a moving feature bookmark — never squash or merge**. Name the bookmark after the feature or project being worked on.

### Setup (once per feature)
```bash
# Name after the feature, e.g. "prompt-improvements" or "my-feature"
jj bookmark create <feature-name> -r @
```

### Per workspace
```bash
# 1. Review full workspace delta against the feature bookmark
jj diff --from <feature-name> --to <workspace-branch>@

# 2. Rebase workspace tip onto the feature bookmark
jj rebase -s <workspace-branch>@ -d <feature-name>

# 3. Move the feature bookmark forward to the rebased commit
jj bookmark set <feature-name> -r <rebased-commit-id>

# 4. Clean up the workspace
jj workspace forget <workspace-name>
rm -rf <workspace-path>
```

### After all workspaces merged
```bash
jj new <feature-name>
```

### Multiple workspaces — rebase each onto the feature bookmark in order
```bash
jj rebase -s <workspace-a>@ -d <feature-name> && jj bookmark set <feature-name> -r <a-rebased>
jj rebase -s <workspace-b>@ -d <feature-name> && jj bookmark set <feature-name> -r <b-rebased>
jj new <feature-name>
jj workspace forget <workspace-a-name>
jj workspace forget <workspace-b-name>
```

### Key rules
- **Name the bookmark after the feature**, not a generic name like `dev`
- **Always diff against the feature bookmark**, not individual commits
- **Always rebase, never squash**: squash goes to the wrong parent when workspace branched from older commit
- **Move the feature bookmark forward after every rebase**: `jj bookmark set <feature-name> -r <rebased-id>`
- **Never create merge commits**: `jj new <a> <b>` — avoid for integration
- **Abandon empty commits** after rebase with `jj abandon <id>`

## Reference Guide

Load detailed guidance based on context:

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Basics | `references/basics.md` | Core commands, concepts |
| Revsets | `references/revsets.md` | Query syntax |
| Workflows | `references/workflows.md` | Common patterns |
| Git Interop | `references/git-interop.md` | Push, fetch, colocated |

## Constraints

### MUST DO
- Use `jj new` to start new work
- Write descriptive change messages
- Squash WIP changes before pushing
- Use bookmarks for feature branches
- Sync regularly with `jj git fetch`
- Use revsets for complex queries

### MUST NOT DO
- Force push to shared bookmarks
- Leave empty changes
- Skip change descriptions
- Ignore conflicts

## Output Templates

When working with jj, provide:
1. jj commands with explanations
2. Change description following conventions
3. Revset expressions if needed
4. Brief explanation of workflow

## Knowledge Reference

### Jujutsu Principles
- No staging area (all changes tracked)
- Changes are immutable (edit creates new)
- Working copy is always a change
- Simpler mental model than Git

### Key Differences from Git
- Branches → Bookmarks
- Commits → Changes
- HEAD → `@`
- Staging → Not needed

### Core Concepts
Changes, working copy, `@`, bookmarks, revsets, `jj new`, `jj describe`, `jj squash`, `jj rebase`, `jj edit`, `jj git push`, `jj git fetch`
