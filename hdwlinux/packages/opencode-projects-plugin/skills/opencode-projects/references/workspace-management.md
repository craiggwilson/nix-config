# Workspace Management

## Jujutsu (jj) Workflow

**Always rebase onto a moving feature bookmark — never squash or merge.** Squash goes to the wrong parent when the workspace branched from an older commit, producing empty commits and non-linear history. A feature bookmark eliminates the need to track commit IDs manually.

### Setup (once per feature)
```bash
# Name after the feature, e.g. "prompt-improvements" or "rate-limiting"
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
rm -rf <workspace-path-a> <workspace-path-b>
```

### Key rules
- **Name the bookmark after the feature**, not a generic name
- **Always diff against the feature bookmark**, not individual commits
- **Always rebase, never squash**: squash goes to the wrong parent
- **Move the feature bookmark forward after every rebase**
- **Never create merge commits**: `jj new <a> <b>` — avoid for integration
- **Abandon empty commits** after rebase with `jj abandon <id>`

## Team Notification Format

When a delegation completes with `isolate=true`, you receive a notification like:

```xml
<team-notification>
  <issue>project-id/bd-xxx.2</issue>
  <status>completed</status>
  <worktree>
    <path>/path/to/nix-config-worktrees/project-id/bd-xxx.2</path>
    <branch>project-id/bd-xxx.2</branch>
    <vcs>jj</vcs>
  </worktree>
  <members>...</members>
  <merge-instructions>...</merge-instructions>
</team-notification>
```

**Always ignore the `<merge-instructions>` squash commands** — use the rebase + feature bookmark pattern above instead.

## Checking Workspace Status

```bash
# List all active workspaces
jj workspace list

# Check what's in a workspace vs the feature bookmark
jj diff --from <feature-name> --to <workspace-branch>@

# See the full log including workspace branches
jj log
```
