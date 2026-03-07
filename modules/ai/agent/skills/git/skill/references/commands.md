# Git Commands

## Daily Workflow

```bash
# Start new work
git checkout main
git pull
git checkout -b feature/my-feature

# Stage and commit
git add -p                    # Interactive staging
git commit -m "feat: add X"

# Push
git push -u origin feature/my-feature
```

## Viewing History

```bash
# Log
git log --oneline -20
git log --graph --oneline --all
git log -p file.txt           # Show changes to file

# Diff
git diff                      # Unstaged changes
git diff --staged             # Staged changes
git diff main..feature        # Between branches
```

## Undoing Changes

```bash
# Discard unstaged changes
git checkout -- file.txt
git restore file.txt          # Git 2.23+

# Unstage
git reset HEAD file.txt
git restore --staged file.txt

# Amend last commit
git commit --amend

# Undo commit (keep changes)
git reset --soft HEAD~1

# Undo commit (discard changes)
git reset --hard HEAD~1
```

## Branches

```bash
# List
git branch -a

# Create and switch
git checkout -b new-branch
git switch -c new-branch      # Git 2.23+

# Delete
git branch -d branch-name
git push origin --delete branch-name
```

## Stashing

```bash
git stash
git stash pop
git stash list
git stash apply stash@{1}
git stash drop stash@{0}
```

## Rebasing

```bash
# Rebase onto main
git rebase main

# Interactive rebase
git rebase -i HEAD~3

# Continue after conflict
git rebase --continue

# Abort
git rebase --abort
```

## Recovery

```bash
# Find lost commits
git reflog

# Recover deleted branch
git checkout -b recovered <sha>
```
