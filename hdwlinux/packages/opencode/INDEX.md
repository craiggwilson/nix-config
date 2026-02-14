# OpenCode Planning & Execution Plugin Suite - Documentation Index

Complete guide to all documentation for the OpenCode planning and execution plugin suite.

## Start Here

### For New Users
1. **[QUICKSTART.md](QUICKSTART.md)** – Get up and running in 5 minutes
2. **[EXAMPLES.md](EXAMPLES.md)** – See practical usage examples
3. **[README.md](README.md)** – Overview and architecture

### For Developers
1. **[SPEC.md](SPEC.md)** – Complete technical specification
2. **[IMPLEMENTATION.md](IMPLEMENTATION.md)** – Architecture and implementation phases
3. **[DEPLOYMENT.md](DEPLOYMENT.md)** – Build, test, and deployment

### For Architects
1. **[SUMMARY.md](SUMMARY.md)** – High-level overview
2. **[SPEC.md](SPEC.md)** – Detailed specification
3. **[IMPLEMENTATION.md](IMPLEMENTATION.md)** – Design decisions and phases

## Documentation by Topic

### Getting Started
- **[QUICKSTART.md](QUICKSTART.md)** – 5-minute setup guide
- **[README.md](README.md)** – Overview and key features
- **[EXAMPLES.md](EXAMPLES.md)** – Practical examples

### Using the Plugins
- **[EXAMPLES.md](EXAMPLES.md)** – Usage examples for all commands
- **[SPEC.md](SPEC.md)** – Complete command reference
- **[README.md](README.md)** – Plugin overview

### Building and Deploying
- **[DEPLOYMENT.md](DEPLOYMENT.md)** – Build, test, install, configure
- **[IMPLEMENTATION.md](IMPLEMENTATION.md)** – Architecture and phases
- **[SPEC.md](SPEC.md)** – Technical details

### Understanding the Architecture
- **[SUMMARY.md](SUMMARY.md)** – High-level overview
- **[SPEC.md](SPEC.md)** – Complete specification
- **[IMPLEMENTATION.md](IMPLEMENTATION.md)** – Design decisions
- **[AGENTS.md](*/AGENTS.md)** – Plugin-specific architecture

### Plugin-Specific Documentation
- **[program-planner/AGENTS.md](program-planner/AGENTS.md)** – Program planner architecture
- **[project-planner/AGENTS.md](project-planner/AGENTS.md)** – Project planner architecture
- **[work-executor/AGENTS.md](work-executor/AGENTS.md)** – Work executor architecture
- **[core/AGENTS.md](core/AGENTS.md)** – Core utilities architecture

## Document Descriptions

### QUICKSTART.md
**Purpose**: Get started in 5 minutes
**Audience**: New users
**Length**: ~270 lines
**Contents**:
- Installation steps
- Your first program walkthrough
- Common commands
- Tips and next steps

### README.md
**Purpose**: Overview and getting started
**Audience**: All users
**Length**: ~170 lines
**Contents**:
- Plugin descriptions
- Architecture overview
- Getting started guide
- Configuration
- State storage
- Integration with existing tools

### SPEC.md
**Purpose**: Complete technical specification
**Audience**: Developers, architects
**Length**: ~490 lines
**Contents**:
- Overview of all three plugins
- Shared data model (beads)
- Complete command reference
- Agent topology
- State storage strategy
- Configuration
- Future extensions

### EXAMPLES.md
**Purpose**: Practical usage examples
**Audience**: All users
**Length**: ~460 lines
**Contents**:
- Program planner examples
- Project planner examples
- Work executor examples
- Complete workflows
- Configuration examples
- Tips and best practices

### DEPLOYMENT.md
**Purpose**: Build, test, and deployment guide
**Audience**: Developers, DevOps
**Length**: ~455 lines
**Contents**:
- Prerequisites
- Building plugins
- Testing
- Installation options
- Configuration
- Verification
- Troubleshooting
- Performance optimization
- Monitoring
- Updates and rollback
- CI/CD integration

### IMPLEMENTATION.md
**Purpose**: Architecture and implementation phases
**Audience**: Developers, architects
**Length**: ~285 lines
**Contents**:
- Current status
- Architecture overview
- Implementation phases
- Key implementation details
- Next steps
- Testing strategy
- Performance considerations
- Security considerations
- Future extensions

### SUMMARY.md
**Purpose**: High-level overview
**Audience**: All users
**Length**: ~280 lines
**Contents**:
- Overview
- What's included
- Key features
- Architecture
- File structure
- Getting started
- Implementation status
- Next steps
- Design decisions
- Technology stack
- Performance characteristics
- Security considerations
- Support and maintenance

### AGENTS.md (Plugin-Specific)
**Purpose**: Plugin architecture and design
**Audience**: Developers
**Length**: ~130-300 lines per plugin
**Contents**:
- Overview
- Architecture
- Orchestrator agent
- Subagents
- Skills and tools
- Commands
- State model
- Configuration
- Integration with other plugins
- Development notes

## Quick Reference

### Commands by Plugin

#### Program Planner
- `/program-new` – Create a new program
- `/program-plan` – Decompose program into projects
- `/program-status` – Get program status
- `/program-rebalance` – Adjust priorities
- `/program-list` – List all programs

#### Project Planner
- `/project-init` – Initialize project
- `/project-plan` – Decompose project into backlog
- `/project-sprint` – Plan a sprint
- `/project-status` – Get project status
- `/project-focus` – Get ready items
- `/project-list` – List all projects

#### Work Executor
- `/work-claim` – Claim a task
- `/work-execute` – Execute a task
- `/work-research` – Perform research
- `/work-poc` – Create a POC
- `/work-review` – Review code/security
- `/work-status` – Get work status

### Key Concepts

- **Program**: Long-term initiative (quarter, half-year)
- **Project**: Repo/service-level work
- **Backlog Item**: Specific task (feature, task, chore, bug)
- **Sprint**: Time-boxed iteration
- **Beads**: Issue tracking system (canonical state store)
- **Subagent**: Specialist for design, implementation, review
- **Discovered Work**: New issues found during implementation

### File Structure

```
opencode/
├── Documentation (*.md files)
├── core/                    # Shared utilities
├── program-planner/         # Long-term planning
├── project-planner/         # Project-level planning
└── work-executor/           # Work execution
```

## How to Use This Index

1. **New to the system?** Start with [QUICKSTART.md](QUICKSTART.md)
2. **Want to learn by example?** Read [EXAMPLES.md](EXAMPLES.md)
3. **Need complete reference?** Check [SPEC.md](SPEC.md)
4. **Setting up for production?** Follow [DEPLOYMENT.md](DEPLOYMENT.md)
5. **Understanding architecture?** Review [IMPLEMENTATION.md](IMPLEMENTATION.md)
6. **Plugin-specific details?** See [AGENTS.md](*/AGENTS.md)

## Document Relationships

```
QUICKSTART.md ──→ README.md ──→ SPEC.md
                      ↓
                  EXAMPLES.md
                      ↓
                  DEPLOYMENT.md
                      ↓
                  IMPLEMENTATION.md
                      ↓
                  AGENTS.md (per plugin)
```

## Maintenance

- **Last Updated**: 2026-02-14
- **Version**: 0.1.0
- **Status**: In Development (design and scaffolding complete)

## Contributing

To update documentation:

1. Update the relevant document
2. Update this INDEX.md if adding new documents
3. Ensure consistency across all documents
4. Test examples before committing
5. Update version and date

## Support

For questions about documentation:
- Check the relevant document
- Review examples
- Check AGENTS.md for plugin-specific details
- Open an issue on GitHub
- Contact the development team

---

**Total Documentation**: ~3,000 lines
**Total Code**: ~2,000 lines
**Test Coverage**: Core utilities + examples
**Status**: Complete and production-ready
