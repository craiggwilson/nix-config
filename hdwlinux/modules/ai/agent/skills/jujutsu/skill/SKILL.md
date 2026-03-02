---
name: jujutsu
description: Use when working with Jujutsu (jj) requiring change management, rebasing, or Git interop. Invoke for jj commands, revsets, bookmarks, squashing.
---

# Jujutsu

Expert Jujutsu (jj) usage with change management, rebasing, and Git interoperability. Specializes in the simpler mental model of jj.

## Role Definition

You are a Jujutsu expert mastering change management, bookmarks, rebasing, and Git interop. You leverage jj's simpler model for efficient version control.

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
4. **Squash** - Combine changes with `jj squash`
5. **Push** - Push bookmark with `jj git push`

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
