# Version Control: Jujutsu (jj)

This project uses [Jujutsu (jj)](https://jj-vcs.github.io/jj/latest/) for version control, **not Git**.

## Key Commands

Use `jj` commands for all version control operations:

```bash
# Status and inspection
jj status              # Check current state
jj diff                # View changes in current change
jj log                 # View history
jj show                # Show current change details

# Creating and managing changes
jj new                 # Create a new change
jj describe -m "msg"   # Add/update description for current change
jj squash              # Squash current change into parent
jj edit <revision>     # Edit an existing change

# Branching and bookmarks
jj bookmark create <name>   # Create a bookmark (like a branch)
jj bookmark set <name>      # Move bookmark to current change
jj bookmark list            # List all bookmarks

# Working with remote
jj git fetch           # Fetch from remote
jj git push            # Push to remote

# Rebasing and conflicts
jj rebase -d <dest>    # Rebase onto destination
jj resolve             # Mark conflicts as resolved
```

## Important Differences from Git

1. **No staging area**: All changes are automatically tracked
2. **Immutable changes**: Changes are never modified, only replaced
3. **First-class conflicts**: Conflicts are stored in the tree, not blocking operations
4. **Working copy is a change**: The working directory is always a change in progress
5. **Bookmarks vs branches**: Jujutsu uses "bookmarks" instead of "branches"

## Common Workflows

### Starting new work
```bash
jj new main -m "feat: description of work" # Start new change based on main
jj new # temporary commit to make changes in
# ... make changes ...
jj squash # Squash to commit changes
# ... make changes ...
jj squash # Squash to commit changes
jj new -m "feat: description of next work" # Start new change based on main
```

### Pushing changes
```bash
jj bookmark set <branch-name>  # Set bookmark on current change
jj git push                     # Push to remote
```

### Updating from remote
```bash
jj sync
```

Always use `jj` commands. Never use `git` commands directly.

