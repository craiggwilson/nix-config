# Jujutsu Workflows

## Feature Development

```bash
# Start new feature
jj new main
jj bookmark create feature-x

# Make changes (automatically tracked)
# Edit files...

# Describe the change
jj describe -m "feat: add feature X"

# Continue working
jj new
# Edit more files...
jj describe -m "feat: add tests for X"

# Squash before pushing
jj squash --into @-
jj describe -m "feat: add feature X with tests"

# Push
jj git push
```

## Keeping Up to Date

```bash
# Fetch latest
jj git fetch

# Rebase onto main
jj rebase -d main

# Or rebase entire branch
jj rebase -d main -s 'roots(main..@)'
```

## Code Review Workflow

```bash
# Create PR branch
jj bookmark create pr-123

# Address review feedback
jj new @-           # Insert change before current
# Make fixes...
jj describe -m "fix: address review comments"

# Squash fixes into original
jj squash

# Push updated branch
jj git push
```

## Working with Conflicts

```bash
# Conflicts are visible in status
jj status

# Resolve conflicts in files
# Edit files to resolve...

# Mark as resolved (automatic when file saved)
jj status  # Should show resolved

# Continue working
jj new
```

## Stashing Work

```bash
# No explicit stash needed
# Just create new change
jj new main
# Work on something else...

# Return to previous work
jj edit <previous-change-id>
```

## Splitting Changes

```bash
# Split current change
jj split

# Interactive: select what goes in first change
# Remaining goes in second change
```
