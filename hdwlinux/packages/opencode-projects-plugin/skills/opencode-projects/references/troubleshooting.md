# Troubleshooting

## Delegation Issues

### Agent seems stuck or not responding
- Check if the delegation is still running: look for pending `<team-notification>`
- For foreground delegations, they block until complete — be patient for complex tasks
- If truly stuck, the delegation will eventually timeout per config

### Notification arrived after session compaction
Use `project-internal-delegation-read` to retrieve the full result:
```json
project-internal-delegation-read(id="delegation-id", projectId="project-id")
```

### Wrong agent selected
Specify agents explicitly:
```json
project-work-on-issue(issueId="...", agents=["coder", "security-engineer"])
```

## Workspace Issues

### Workspace appears empty when reviewer looks at it
This is the known timing issue with `concurrent` launch ordering (realTime strategy). The reviewer prompt includes guidance to check for changes before reviewing. For `sequential` strategies (fixedRound, dynamicRound), reviewers don't start until the primary completes.

### Empty commits after rebase
```bash
jj abandon <empty-commit-id>
```

### Non-linear history / merge commits
If you accidentally created a merge commit with `jj new <a> <b>`, rebase to fix:
```bash
jj rebase -s <merge-commit> -d <correct-parent>
```

### Workspace not cleaning up
```bash
jj workspace forget <workspace-name>
rm -rf <workspace-path>
```

## Project Issues

### Can't find project ID
```json
project-list(scope="all", status="all")
```

### Issue not showing in status
Issues are scoped to their project. Make sure you're focused on the right project:
```json
project-focus(projectId="correct-project-id")
```

### Planning session lost after compaction
```json
project-plan(projectId="...", action="status")
```
This shows the current planning phase and what's been captured so far.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Using `jj squash --from <workspace>@` | Use `jj rebase -s <workspace>@ -d <feature-bookmark>` instead |
| Creating merge commits with `jj new <a> <b>` | Rebase to linearize |
| Not moving the feature bookmark after rebase | `jj bookmark set <feature-name> -r <rebased-id>` |
| Starting reviewer before primary completes | Use `sequential` launch ordering (default for fixedRound/dynamicRound) |
| Forgetting to close issues after merging | `project-update-issue(issueId="...", status="closed")` |
