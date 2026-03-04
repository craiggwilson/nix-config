# Configuration Reference

Configuration lives in `opencode.json` under the `opencode-projects` plugin key.

## Full Default Configuration

```json
{
  "version": "0.9.0",
  "defaults": {
    "storage": "local",
    "vcs": "auto"
  },
  "projects": {},
  "worktrees": {
    "autoCleanup": true,
    "basePath": null
  },
  "delegation": {
    "timeoutMs": 900000,
    "smallModelTimeoutMs": 30000
  },
  "teamDiscussions": {
    "default": "fixedRound",
    "fixedRound": {
      "rounds": 3,
      "roundTimeoutMs": 300000
    },
    "dynamicRound": {
      "maxRounds": 10,
      "minRounds": 2,
      "roundTimeoutMs": 300000
    },
    "realtime": {
      "pollIntervalMs": 1000,
      "maxWaitTimeMs": 1800000,
      "promptTimeoutMs": 300000
    }
  },
  "teams": {
    "maxTeamSize": 5,
    "retryFailedMembers": true
  }
}
```

## `defaults`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `storage` | `"local" \| "global"` | `"local"` | Where project data is stored. `local` = `.projects/` in repo root. `global` = `~/.local/share/opencode/projects/` |
| `vcs` | `"auto" \| "git" \| "jj"` | `"auto"` | Version control system. `auto` detects from repo. |

## `projects`

Per-project overrides keyed by project ID:

```json
{
  "projects": {
    "my-project-id": {
      "storage": "global",
      "workspaces": ["workspace-a", "workspace-b"]
    }
  }
}
```

| Field | Type | Description |
|-------|------|-------------|
| `storage` | `"local" \| "global"` | Override storage location for this project |
| `workspaces` | `string[]` | Named workspaces associated with this project |

## `worktrees`

Settings for isolated jj workspaces created during delegation.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `autoCleanup` | `boolean` | `true` | Automatically clean up workspace directories after merging |
| `basePath` | `string \| null` | `null` | Base directory for workspace creation. Defaults to `<repo-root>-worktrees/` |

## `delegation`

Settings for background agent delegations.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `timeoutMs` | `number` | `900000` (15 min) | Maximum time to wait for a delegation to complete |
| `smallModelTimeoutMs` | `number` | `30000` (30 sec) | Maximum time for small model queries (e.g., auto team selection) |

## `teamDiscussions`

### Top-level

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `default` | `"fixedRound" \| "dynamicRound" \| "realtime"` | `"fixedRound"` | Default discussion strategy when none is specified in `project-work-on-issue` |

### `teamDiscussions.fixedRound`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `rounds` | `number` | `3` | Number of discussion rounds. All rounds always run — no early termination. |
| `roundTimeoutMs` | `number` | `300000` (5 min) | Maximum time per round before timing out |

### `teamDiscussions.dynamicRound`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `maxRounds` | `number` | `10` | Maximum rounds before forcing termination |
| `minRounds` | `number` | `2` | Minimum rounds before convergence assessment begins. Prevents premature convergence. |
| `roundTimeoutMs` | `number` | `300000` (5 min) | Maximum time per round before timing out |

### `teamDiscussions.realtime`

Agents communicate asynchronously via a shared inbox. All agents launch concurrently (`memberLaunchOrdering: "concurrent"`).

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `pollIntervalMs` | `number` | `1000` (1 sec) | How often agents check the inbox for new messages |
| `maxWaitTimeMs` | `number` | `1800000` (30 min) | Maximum total time before forcing termination |
| `promptTimeoutMs` | `number` | `300000` (5 min) | Maximum time to wait for each agent's response per prompt |

## `teams`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `maxTeamSize` | `number` | `5` | Maximum number of agents in a team |
| `retryFailedMembers` | `boolean` | `true` | Automatically retry a team member if their delegation fails |

## Discussion Strategy: Launch Ordering

Each strategy has a fixed `memberLaunchOrdering` that controls when secondary agents start:

| Strategy | Launch Ordering | Behaviour |
|----------|----------------|-----------|
| `fixedRound` | `sequential` | Reviewers wait for primary to complete before starting |
| `dynamicRound` | `sequential` | Reviewers wait for primary to complete before starting |
| `realtime` | `concurrent` | All agents launch immediately and communicate via inbox |

## Convergence Signals (dynamicRound & realtime)

Agents use structured signals to control discussion termination:

| Signal | Meaning |
|--------|---------|
| `CONVERGED` | Primary: satisfied with outcome. Devil's advocate: exhausted objections (not agreement). |
| `STUCK` | A blocker is unresolved — veto convergence until addressed. |
| `CONTINUE` | More to discuss — explain what still needs resolution. |

Both primary AND devil's advocate must signal `CONVERGED` before discussion ends. A `STUCK` signal from any member vetoes termination.
