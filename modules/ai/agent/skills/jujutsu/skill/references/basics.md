# Jujutsu Basics

## Core Concepts

| Concept | Description |
|---------|-------------|
| Change | A snapshot (like a commit) |
| Working copy | Current change being edited |
| `@` | Symbol for working copy |
| Bookmark | Named pointer to a change |

## Essential Commands

```bash
# Status
jj status
jj st

# Log
jj log
jj log -r @      # Current change
jj log -r ::@    # Ancestors of current

# Create new change
jj new           # New change on top of @
jj new main      # New change on top of main

# Describe (commit message)
jj describe -m "Add feature X"
jj desc -m "Add feature X"

# Show diff
jj diff
jj diff -r @-    # Previous change
```

## Working with Changes

```bash
# Edit existing change
jj edit <revision>

# Squash into parent
jj squash
jj squash -m "Combined message"

# Split a change
jj split

# Abandon (delete) change
jj abandon @
```

## Bookmarks (Branches)

```bash
# Create bookmark
jj bookmark create feature-x

# Move bookmark
jj bookmark set feature-x -r @

# List bookmarks
jj bookmark list

# Delete bookmark
jj bookmark delete feature-x
```

## Undo

```bash
# Undo last operation
jj undo

# View operation log
jj op log

# Restore to previous state
jj op restore <operation-id>
```

## Key Differences from Git

- No staging area - all changes tracked automatically
- Working copy is always a change
- Changes are immutable (editing creates new change)
- Conflicts are first-class citizens
