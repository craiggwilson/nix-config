# Agent Instructions

This project uses **bd** (beads) for issue tracking. Run `bd onboard` to get started.

## Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --status in_progress  # Claim work
bd close <id>         # Complete work
bd sync               # Sync with git
```

## Development

### Prerequisites

This project uses Bun for building and testing. Since this is a NixOS environment, use `nix-shell` to access Bun:

```bash
nix-shell -p bun --run "<command>"
```

### Building

```bash
nix-shell -p bun --run "bun install"
nix-shell -p bun --run "bun run build"
```

### Running Unit Tests

```bash
nix-shell -p bun --run "bun test"
```

To run a specific test file:

```bash
nix-shell -p bun --run "bun test src/tools/project-create.test.ts"
```

### Integration Testing with OpenCode

To test the plugin with a live OpenCode instance:

1. **Create a test directory with the plugin symlinked:**

```bash
mkdir -p /tmp/opencode-test/.opencode/plugins
ln -sf $(pwd)/dist/index.js /tmp/opencode-test/.opencode/plugins/opencode-projects.js
cd /tmp/opencode-test
jj git init  # or: git init
echo "# Test" > README.md
```

2. **Run OpenCode with a test prompt:**

```bash
cd /tmp/opencode-test
opencode run "Use project-list to list all projects"
```

3. **Test specific functionality:**

```bash
# Test project creation
opencode run "Create a project called 'test-proj' with description 'Testing'"

# Test issue creation (replace project ID with actual)
opencode run "Focus on project test-proj-XXXXX and create an issue titled 'Test issue'"

# Test research task (no isolation - runs in repo root)
opencode run "Focus on project test-proj-XXXXX and work on issue test-proj-XXXXX.1"

# Test code task (with isolation - creates worktree)
opencode run "Focus on project test-proj-XXXXX and work on issue test-proj-XXXXX.2 with isolate=true"

# Test planning workflow
opencode run "Focus on project test-proj-XXXXX and start planning"
opencode run "Focus on project test-proj-XXXXX and advance planning to the next phase"
```

4. **Check delegation results:**

```bash
# View delegation status
cat /tmp/opencode-test/delegations/*.json

# View delegation result markdown
cat /tmp/opencode-test/delegations/*.md

# Check worktree contents
ls -la /tmp/opencode-test-worktrees/
```

5. **Clean up between tests:**

```bash
rm -rf /tmp/opencode-test/delegations /tmp/opencode-test-worktrees /tmp/opencode-test/.projects
```

### Debugging

To see plugin logs, check the OpenCode log files:

```bash
find ~/.local/share/opencode -name "*.log" -mmin -5 | xargs cat | grep -i "delegation\|project"
```

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bd sync
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
