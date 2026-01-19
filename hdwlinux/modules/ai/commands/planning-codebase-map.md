---
description: Map and document a codebase as part of planning discovery
argument-hint: [repository-path]
---

You are conducting a codebase mapping exercise as part of a planning workflow. This command assumes you are working within a project directory context.

**Repository to Map**: $ARGUMENTS

## Planning Context

First, I will:
1. Review `CONTEXT.md` for project context and existing source code references
2. Check `research/` for any prior codebase analysis
3. Understand how this codebase relates to the planning objectives

## Mapping Process

### 1. Repository Structure
- Directory organization and patterns
- Build system(s) identification
- Configuration and deployment structure
- Test organization

### 2. Architecture Discovery
- Service/module boundaries
- Entry points and APIs
- Dependency graph (internal/external)
- Data storage and messaging patterns

### 3. Technology Stack
- Languages, frameworks, versions
- Build and deployment tools
- Infrastructure dependencies

### 4. Key Patterns
- Code organization conventions
- Error handling, logging, observability
- Security and configuration patterns

### 5. Planning-Relevant Insights
- Technical debt indicators
- Complexity hotspots
- Integration points with other systems
- Areas requiring attention for planned work

## Outputs

### research/codebase-[repo-name].md
```markdown
# Codebase Analysis: [Repository Name]

- **Date**: YYYY-MM-DD
- **Status**: Complete
- **Purpose**: Codebase architecture documentation for planning
- **Related Planning**: [Link to relevant planning items]

## Executive Summary
[2-3 sentence overview relevant to planning objectives]

## Architecture Overview
[High-level architecture description]

## Module Breakdown
| Module | Path | Purpose | Complexity |
|--------|------|---------|------------|
| [name] | [path] | [desc] | [H/M/L] |

## Technology Stack
| Category | Technology | Version | Notes |
|----------|------------|---------|-------|
| Language | [lang] | [ver] | [notes] |

## Key Patterns
[Documented patterns with file references]

## Integration Points
[How this connects to other systems]

## Technical Debt & Risks
| Issue | Severity | Planning Impact |
|-------|----------|-----------------|
| [desc] | [H/M/L] | [impact on planned work] |

## Recommendations for Planning
1. [Consideration for roadmap/project/task planning]
```

### CONTEXT.md Updates
I will update the "Source Code Locations" section:
```markdown
## Source Code Locations

### [Repository Name]
- **Path**: [local path or git URL]
- **Language**: [primary language]
- **Build**: [build system]
- **Analysis**: [research/codebase-[name].md](research/codebase-[name].md)

#### Key Modules
| Module | Purpose |
|--------|---------|
| [name] | [description] |
```

## Process

1. I'll check CONTEXT.md for project context
2. I'll analyze the repository structure
3. I'll document findings in `research/codebase-[name].md`
4. I'll update CONTEXT.md with source code references
5. I'll commit the changes to version control with a descriptive message
6. I'll highlight planning-relevant insights

## Version Control

After documenting the codebase analysis, I will commit the changes:

```bash
# Stage and commit codebase mapping
jj describe -m "planning: map codebase [repo-name] for [project-name]

Repository: [repo-name]
- Language: [primary language]
- Build: [build system]

Key Modules:
- [module1]: [purpose]
- [module2]: [purpose]

Technical Debt/Risks:
- [Risk 1]

Planning Recommendations:
- [Key consideration for planning]"
jj new  # Create a new change for subsequent work
```

The commit message should:
- Start with `planning:` prefix
- Include the repository being mapped
- Summarize key modules discovered
- Note technical debt or risks relevant to planning

### Retrieving Context History

Previous codebase analyses and how understanding evolved can be retrieved from the repository history:

```bash
# View history of codebase mapping commits
jj log --no-graph -r 'description(glob:"planning: map codebase*")'

# Show how codebase analysis evolved
jj file annotate research/codebase-[name].md

# View analysis at a specific revision
jj file show research/codebase-[name].md -r [revision]

# Compare current analysis to earlier version
jj diff -r [revision] research/codebase-[name].md
```

This history tracks how codebase understanding evolved, useful when the codebase itself changes during planning.

**Let me begin by reviewing the project context and then mapping the codebase.**

