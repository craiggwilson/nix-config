# Jujutsu Workflows

## Workspace Integration

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

**Why not squash?** `jj squash --from <branch>@` goes to the wrong parent when the workspace branched from an older commit, producing empty commits and non-linear history. The feature bookmark eliminates the need to track commit IDs manually.

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
