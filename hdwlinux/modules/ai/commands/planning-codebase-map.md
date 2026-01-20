---
description: Map and document a codebase as part of planning discovery
argument-hint: [repository-name-or-focus]
---

You are conducting a codebase mapping exercise as part of a planning workflow. This command assumes you are working within a project directory context.

**Mapping Target**: $ARGUMENTS

The argument can be a repository name (if multiple repos are involved in the project) or a focus area for the analysis (e.g., "API layer", "data models", "security patterns", "test infrastructure"). If analyzing the current directory's codebase, the argument can specify which aspects to focus on.

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

## Subagent Delegation

Codebase mapping is an ideal candidate for subagent delegation, as it requires deep technical analysis that specialized agents excel at.

### Primary Subagent: codebase-analyst

The `codebase-analyst` subagent is the primary expert for codebase mapping tasks. It specializes in:
- Code archaeology and pattern recognition
- Architecture discovery and documentation
- Dependency analysis and complexity assessment
- Technical debt identification

### Additional Specialized Subagents

| Subagent | Specialty | When to Delegate |
|----------|-----------|------------------|
| `security-architect` | Security pattern analysis | Identifying authentication, authorization, and security patterns |
| `distributed-systems-architect` | Service architecture | Analyzing microservices, API boundaries, resilience patterns |
| `go-expert` / `java-expert` | Language-specific patterns | Deep dive into language-specific idioms and best practices |
| `terraform-expert` | Infrastructure analysis | Mapping infrastructure-as-code alongside application code |
| `mongodb-expert` / `kafka-expert` | Data layer analysis | Understanding data models, event flows, and integration patterns |

### Delegation Criteria

Delegate codebase analysis when:
- **Repository size**: Large codebases (>100 files) benefit from focused analysis
- **Multi-language**: Repository contains multiple languages requiring different expertise
- **Complex architecture**: Microservices, event-driven, or distributed systems
- **Security-sensitive**: Financial, healthcare, or other regulated domains
- **Legacy systems**: Older codebases requiring archaeological investigation

### Handoff Process

**Context to provide codebase-analyst:**
```
1. Repository path and primary language(s)
2. Planning context from CONTEXT.md
3. Specific areas of focus (e.g., "focus on API layer" or "assess test coverage")
4. Known systems this integrates with
5. Planning questions the analysis should answer
```

**Expected deliverables from subagent:**
- Complete codebase analysis document
- Architecture diagram descriptions
- Module breakdown with complexity assessment
- Technical debt inventory
- Planning-specific recommendations

### Integration Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                planning-codebase-map (orchestrator)              │
├─────────────────────────────────────────────────────────────────┤
│  1. Review CONTEXT.md for planning objectives                   │
│  2. Initial repository assessment (size, languages, structure)  │
│  3. Determine delegation strategy:                               │
│     ├── Simple/small repos → handle directly                   │
│     ├── Complex repos → delegate to codebase-analyst           │
│     ├── Multi-domain repos → parallel subagent calls           │
│     │   (e.g., codebase-analyst + security-architect)          │
│  4. Review and integrate subagent outputs                       │
│  5. Generate research/codebase-[name].md                        │
│  6. Update CONTEXT.md with source code references               │
│  7. Commit and highlight planning-relevant insights             │
└─────────────────────────────────────────────────────────────────┘
```

### Parallel Analysis Pattern

For complex repositories, multiple subagents can analyze different aspects simultaneously:

```
┌────────────────────┐  ┌────────────────────┐  ┌────────────────────┐
│  codebase-analyst  │  │ security-architect │  │  [domain]-expert   │
│  (architecture)    │  │  (security review) │  │  (tech-specific)   │
└─────────┬──────────┘  └─────────┬──────────┘  └─────────┬──────────┘
          │                       │                       │
          └───────────────────────┼───────────────────────┘
                                  │
                    ┌─────────────▼─────────────┐
                    │   Synthesized Analysis    │
                    │  research/codebase-*.md   │
                    └───────────────────────────┘
```

## Process

1. I'll check CONTEXT.md for project context
2. I'll perform initial repository assessment
3. I'll delegate to codebase-analyst (and other specialists as needed)
4. I'll synthesize subagent findings into `research/codebase-[name].md`
5. I'll update CONTEXT.md with source code references
6. I'll commit the changes to version control with a descriptive message
7. I'll highlight planning-relevant insights

## Formatting Guidelines

All planning artifacts must follow the markdown formatting standards defined in the global `markdown-formatting` rule. Key requirements include JIRA ticket hyperlinks, ISO date formats, consistent status indicators, and proper document structure.

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

