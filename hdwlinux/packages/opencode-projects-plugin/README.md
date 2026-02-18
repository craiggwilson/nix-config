# opencode-projects

Project planning, tracking, and execution plugin for OpenCode. Integrates with [beads](https://github.com/hdwlinux/beads) for issue tracking and supports parallel agent work with VCS worktree isolation.

## Features

- **Project Management**: Create, list, and track projects with hierarchical issue structures
- **Issue Tracking**: Create issues with dependencies, priorities, and status tracking via beads
- **Planning Workflows**: Conversational interviews to gather requirements and generate artifacts
- **Worktree Isolation**: Work on issues in isolated git/jj worktrees
- **Background Delegation**: Delegate work to background agents with result persistence
- **VCS Integration**: Automatic detection and support for both Git and Jujutsu (jj)

## Installation

Add to your OpenCode configuration:

```json
{
  "plugins": ["opencode-projects"]
}
```

### Prerequisites

- [beads](https://github.com/hdwlinux/beads) CLI (`bd`) for issue tracking
- Git or Jujutsu for version control

## Quick Start

```
# Create a new project
project_create(name="my-feature", description="Implement new feature")

# View project status
project_status()

# Create issues
issue_create(title="Design API", priority=0)
issue_create(title="Implement endpoints", priority=1, blockedBy=["my-feature.1"])

# Claim and work on an issue
issue_claim(issueId="my-feature.1")

# Close an issue when done
issue_update(issueId="my-feature.1", status="closed", comment="Completed design")
```

## Documentation

- [Tools Reference](docs/tools.md) - Complete tool documentation
- [Workflows](docs/workflows.md) - Common usage patterns
- [Architecture](docs/architecture.md) - Technical overview

## Configuration

Create `~/.config/opencode/opencode-projects.json`:

```json
{
  "version": "1.0",
  "defaults": {
    "storage": "local",
    "vcs": "auto",
    "beadsPath": ".beads",
    "projectsPath": ".projects"
  }
}
```

### Options

| Field | Description | Default |
|-------|-------------|---------|
| `defaults.storage` | Where to store projects (`local` or `global`) | `local` |
| `defaults.vcs` | VCS to use (`auto`, `git`, or `jj`) | `auto` |
| `defaults.beadsPath` | Path for beads data | `.beads` |
| `defaults.projectsPath` | Path for project data | `.projects` |

## License

MIT
