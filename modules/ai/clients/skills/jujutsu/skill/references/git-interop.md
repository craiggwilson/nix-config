# Jujutsu Git Interop

## Colocated Repositories

```bash
# Initialize jj in existing git repo
cd my-git-repo
jj git init --colocate

# Both .git and .jj directories exist
# Can use both jj and git commands
```

## Git Operations

```bash
# Fetch from remote
jj git fetch
jj git fetch --remote origin

# Push to remote
jj git push
jj git push --bookmark feature-x

# Clone repository
jj git clone https://github.com/user/repo.git
```

## Bookmarks and Branches

```bash
# Bookmarks map to git branches
jj bookmark create feature-x
# Creates git branch 'feature-x'

# Track remote branch
jj bookmark track feature-x@origin

# List with remote tracking
jj bookmark list --all
```

## Importing Git History

```bash
# Import existing git repo
jj git import

# Export jj changes to git
jj git export
```

## Working with PRs

```bash
# Create branch for PR
jj bookmark create pr-branch
jj git push --bookmark pr-branch

# After PR merged, clean up
jj git fetch
jj bookmark delete pr-branch
```

## Differences from Git

| Git | Jujutsu |
|-----|---------|
| `git commit` | `jj new` + `jj describe` |
| `git add` | Automatic |
| `git stash` | `jj new` (just start new change) |
| `git branch` | `jj bookmark` |
| `git checkout` | `jj edit` or `jj new` |
| `git rebase -i` | `jj squash`, `jj split`, `jj edit` |

## Tips

- Use `jj git fetch` regularly
- Bookmarks are just pointers, not special
- Conflicts are normal, not blocking
- `jj undo` works for most operations
