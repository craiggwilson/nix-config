# Jujutsu Revsets

## Basic Revisions

| Symbol | Meaning |
|--------|---------|
| `@` | Working copy |
| `@-` | Parent of working copy |
| `@--` | Grandparent |
| `root()` | Root of repository |

## Operators

```bash
# Ancestors (inclusive)
::@              # All ancestors of @
@::              # All descendants of @

# Parents/Children
@-               # Parent
@+               # Children

# Range
main..@          # Changes between main and @

# Union
main | feature   # Either main or feature

# Intersection
main & feature   # Both main and feature

# Difference
main ~ feature   # In main but not feature
```

## Functions

```bash
# Bookmarks
bookmarks()              # All bookmarks
bookmark(name)           # Specific bookmark

# Heads and roots
heads(::@)               # Head changes
roots(@::)               # Root changes

# Filtering
author(email)            # By author
description(text)        # By description
empty()                  # Empty changes
conflict()               # Changes with conflicts

# Commits
commits(main..@)         # Commits in range
```

## Examples

```bash
# Log feature branch
jj log -r 'main..@'

# Find all my changes
jj log -r 'author("me@example.com")'

# Find changes with "fix" in description
jj log -r 'description("fix")'

# Show all bookmarks
jj log -r 'bookmarks()'

# Find conflicting changes
jj log -r 'conflict()'

# Rebase onto main
jj rebase -d main -s 'roots(main..@)'
```
