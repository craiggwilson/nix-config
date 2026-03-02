# opencode-projects

Project planning, tracking, and execution plugin for [OpenCode](https://opencode.ai) with [beads](https://github.com/craiggwilson/beads) integration.

## Features

- **Project Management** - Create, list, focus, and close projects with flexible storage backends
- **Issue Tracking** - Create and manage issues with beads integration
- **Planning Sessions** - Structured planning with discovery, synthesis, and breakdown phases
- **Delegation Workflows** - Background agent execution with worktree isolation for code changes
- **Team Coordination** - Multi-agent team execution with discussion and consensus
- **VCS Agnostic** - Works with both Git and Jujutsu (jj) version control systems

## Installation

### Requirements

- **Bun** >= 1.0.0 (required runtime)
- **OpenCode** >= 1.2.15
- **beads** (for issue storage)

### Install from npm

```bash
bun add opencode-projects
```

### Install from local path (development)

```bash
bun add /path/to/opencode-projects-plugin
```

## Quick Start

### 1. Configure OpenCode

Add the plugin to your OpenCode configuration (`~/.config/opencode/opencode.json`):

```json
{
  "plugin": [
    "npm:opencode-projects"
  ]
}
```

Or for local development:

```json
{
  "plugin": [
    "file:///path/to/opencode-projects-plugin"
  ]
}
```

### 2. Create a Project

```bash
opencode run "Create a project called 'my-project' with description 'My first project' with storage='local'"
```

### 3. List Projects

```bash
opencode run "List all projects"
```

### 4. Focus on a Project

```bash
opencode run "Focus on project my-project-XXXXX"
```

### 5. Create an Issue

```bash
opencode run "Create an issue titled 'Implement feature X' with description 'Details here'"
```

### 6. Work on an Issue

For research/analysis (no isolation):
```bash
opencode run "Work on issue my-project-XXXXX.1"
```

For code changes (with worktree isolation):
```bash
opencode run "Work on issue my-project-XXXXX.2 with isolate=true"
```

## Documentation

- **[Architecture](./docs/architecture.md)** - System design and module structure
- **[Tools Reference](./docs/tools.md)** - Complete tool documentation
- **[Workflows](./docs/workflows.md)** - Usage patterns and examples
- **[Developer Guide](./AGENTS.md)** - Development and testing guide

## Project State Storage

Projects are stored in `.projects/` directory in your repository:

```
.projects/
├── projects.json          # Project metadata
├── issues/
│   └── <project-id>/      # Issues for each project
└── delegations/           # Delegation results and state
```

## VCS Support

The plugin automatically detects and works with:

- **Git** - Standard Git repositories
- **Jujutsu (jj)** - Modern VCS with better change management

Worktree isolation for code changes is supported on both systems.

## Configuration

Create a `.opencode-projects.json` file in your repository root to customize behavior:

```json
{
  "storage": "local",
  "issueStorage": "beads",
  "vcs": "auto"
}
```

## License

MIT - See [LICENSE](./LICENSE) file for details

## Contributing

This is a pre-1.0 release. Breaking changes are allowed. Please report issues and suggest improvements.

## Related Projects

- [OpenCode](https://opencode.ai) - AI-powered development environment
- [beads](https://github.com/craiggwilson/beads) - Issue tracking system
- [nix-config](https://github.com/craiggwilson/nix-config) - NixOS configuration
