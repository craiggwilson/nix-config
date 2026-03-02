# Git Rebasing

## Basic Rebase

```bash
# Update feature branch with main
git checkout feature
git rebase main

# Equivalent to:
# 1. Find common ancestor
# 2. Reset to main
# 3. Replay feature commits
```

## Interactive Rebase

```bash
git rebase -i HEAD~5

# Editor opens with:
pick abc1234 First commit
pick def5678 Second commit
pick ghi9012 Third commit

# Commands:
# pick   - use commit
# reword - edit message
# edit   - stop for amending
# squash - meld into previous
# fixup  - squash, discard message
# drop   - remove commit
```

## Squashing Commits

```bash
git rebase -i HEAD~3

# Change to:
pick abc1234 First commit
squash def5678 Second commit
squash ghi9012 Third commit

# Results in single commit
```

## Resolving Conflicts

```bash
# During rebase, conflict occurs
# 1. Fix conflicts in files
# 2. Stage resolved files
git add resolved-file.txt

# 3. Continue rebase
git rebase --continue

# Or abort
git rebase --abort
```

## Rebase vs Merge

| Rebase | Merge |
|--------|-------|
| Linear history | Preserves history |
| Rewrites commits | Creates merge commit |
| Cleaner log | Shows actual timeline |
| Don't use on public branches | Safe for public branches |

## Golden Rule

**Never rebase public/shared branches**

```bash
# Bad - rewrites shared history
git checkout main
git rebase feature

# Good - rebase your feature onto main
git checkout feature
git rebase main
```
