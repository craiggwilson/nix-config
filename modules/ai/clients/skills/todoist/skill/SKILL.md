---
name: todoist-cli
description: Use the Todoist CLI (`td`) to inspect, create, update, and complete Todoist tasks from the command line. Use when the agent needs to check what's due, add new tasks, review projects or inbox items, or act on tasks in Todoist. Prefer `td` for machine-readable output (`--json`, `--ndjson`, `--ids-only`) and non-interactive auth via `TODOIST_API_TOKEN`.
---

# Todoist CLI

Use `td` to work with Todoist from the terminal.

## Common commands

```bash
td auth status
td today --accessible
td inbox
td task list --json
td task list --project "Work" --ids-only
td task view "Draft launch notes"
td add "Buy milk tomorrow #Shopping"
td task complete "Buy milk"
```

## Agent notes

- Prefer `--json`, `--ndjson`, or `--ids-only` when the output will be consumed by another tool.
- Read `td <command> --help` when you need exact flags for a subcommand.
