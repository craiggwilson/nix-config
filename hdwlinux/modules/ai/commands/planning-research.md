---
description: Conduct focused research as part of planning discovery
argument-hint: [topic]
---

You are conducting focused research as part of a planning workflow. This command assumes you are working within a project directory context.

**Research Topic**: $ARGUMENTS

## Planning Context

First, I will:
1. Review `CONTEXT.md` for project context and objectives
2. Check `PROGRESS.md` for current planning phase and related tasks
3. Review `research/` for any prior related research
4. Understand how this research supports planning decisions

## Research Types

### Technical Research
- Technology evaluation for planned initiatives
- Architecture pattern investigation
- Best practices for proposed solutions
- Performance/security considerations

### Codebase Research
- How existing features are implemented
- Where specific logic lives
- Component interactions
- Historical decisions (git archaeology)

### External Research
- Industry standards and benchmarks
- Vendor/tool evaluation
- Competitor analysis
- Community practices

## Research Process

### 1. Scope Definition
- What question are we answering?
- What planning decisions will this inform?
- What's in/out of scope?

### 2. Information Gathering
- Codebase analysis (if code-related)
- Documentation review
- Web search for external context
- Tool/API documentation

### 3. Analysis
- Compare alternatives
- Identify trade-offs
- Assess risks and benefits
- Validate against planning constraints

### 4. Planning Integration
- How findings affect roadmap/project/task planning
- Risks to flag in planning documents
- Recommendations for next steps

## Outputs

### research/[topic-slug].md
```markdown
# Research: [Topic Title]

- **Date**: YYYY-MM-DD
- **Status**: Complete
- **Purpose**: [Why this research was needed for planning]
- **Related Planning**: [PROGRESS.md items this informs]

## Research Question
[Clear statement of what we're learning]

## Executive Summary
[2-3 sentence summary of key findings]

## Scope
**In Scope:** [What was investigated]
**Out of Scope:** [What was not investigated]

## Findings

### [Category 1]
[Detailed findings with evidence]

### [Category 2]
[Detailed findings with evidence]

## Trade-off Analysis
| Option | Pros | Cons | Effort | Risk |
|--------|------|------|--------|------|
| [A] | [+] | [-] | [H/M/L] | [H/M/L] |

## Risks
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| [desc] | [H/M/L] | [H/M/L] | [plan] |

## Recommendations
1. [Primary recommendation with rationale]
2. [Secondary recommendation if applicable]

## Planning Implications
- **Roadmap**: [How this affects strategic planning]
- **Project**: [How this affects project scope/timeline]
- **Tasks**: [Specific tasks that should be created]

## Open Questions
- [Questions for follow-up research]

## References
- [Source]: [URL or path]
```

### CONTEXT.md Updates
If research reveals important context, update:
- Reference Documents section with key sources
- Technical Architecture section if applicable
- Any section benefiting from findings

### PROGRESS.md Updates
- Link research to relevant planning items
- Note any new tasks identified

## Process

1. I'll review CONTEXT.md and PROGRESS.md for planning context
2. I'll clarify the research question if needed
3. I'll gather and analyze information
4. I'll document findings in `research/[topic].md`
5. I'll update CONTEXT.md with key references
6. I'll commit the changes to version control with a descriptive message
7. I'll summarize planning implications

## Version Control

After documenting research findings, I will commit the changes:

```bash
# Stage and commit research
jj describe -m "planning: research [topic-slug] for [project-name]

Research Question: [Brief question statement]

Key Findings:
- [Finding 1]
- [Finding 2]

Recommendation: [Primary recommendation]

Planning Impact: [How this affects roadmap/project/task planning]"
jj new  # Create a new change for subsequent work
```

The commit message should:
- Start with `planning:` prefix
- Include the research topic
- Summarize key findings
- Note the recommendation and planning impact

### Retrieving Context History

Previous research and how findings evolved can be retrieved from the repository history:

```bash
# View history of research commits
jj log --no-graph -r 'description(glob:"planning: research*")'

# Show how a research document evolved
jj file annotate research/[topic].md

# View research at a specific revision
jj file show research/[topic].md -r [revision]

# Compare current findings to earlier version
jj diff -r [revision] research/[topic].md
```

This history tracks how research findings and recommendations evolved as new information was discovered.

**Let me review the project context and begin the research.**

