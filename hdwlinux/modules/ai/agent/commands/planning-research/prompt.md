You are conducting focused research as part of a planning workflow. This command assumes you are working within a project directory context.

**Research Topic**: $ARGUMENTS

The research topic should describe what needs to be investigated (e.g., "authentication patterns", "database migration strategies", "event-driven architecture", "CI/CD pipeline options"). This helps focus the research on planning-relevant questions.

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

## Subagent Delegation

Research often benefits from specialized expertise. As orchestrator, I delegate to subagents when their focus can improve research depth or efficiency.

### Available Research Subagents

| Subagent | Specialty | When to Delegate |
|----------|-----------|------------------|
| `codebase-analyst` | Code archaeology, architecture discovery, dependency analysis | Codebase research, implementation patterns, technical debt analysis |
| `security-architect` | Threat modeling, security patterns, compliance | Security-related research, authentication/authorization patterns |
| `distributed-systems-architect` | Service design, resilience patterns, multi-region | Scalability research, system integration patterns |
| `aws-expert` | AWS services, well-architected framework | Cloud architecture research, AWS service evaluation |
| `terraform-expert` | Infrastructure as code, provider patterns | IaC research, deployment strategy evaluation |
| `mongodb-expert` | Data modeling, query optimization | Database research, data architecture decisions |
| `kafka-expert` | Event streaming, topic design | Messaging research, async communication patterns |

### Delegation Criteria

Delegate research to a specialized subagent when:
- **Domain expertise required**: Research topic requires deep specialized knowledge
- **Technical depth needed**: Analysis requires understanding complex implementation details
- **Cross-cutting concerns**: Research spans multiple technical domains
- **Best practice validation**: Need authoritative guidance on patterns or approaches

### Handoff Process

**Context to provide subagent:**
```
1. Research question and scope
2. Relevant context from CONTEXT.md
3. How findings will inform planning decisions
4. Specific areas of focus or concern
5. Constraints (timeline, technology stack, existing decisions)
```

**Expected deliverables from subagent:**
- Detailed analysis in the expected research format
- Trade-off evaluation with clear recommendations
- Risks identified with suggested mitigations
- References to authoritative sources
- Open questions for follow-up

### Integration Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                  planning-research (orchestrator)                │
├─────────────────────────────────────────────────────────────────┤
│  1. Review planning context and clarify research question        │
│  2. Identify research type and required expertise                │
│  3. If specialized expertise needed:                             │
│     ├── Select appropriate subagent(s)                          │
│     ├── Prepare context package with research focus             │
│     ├── Invoke subagent(s) - can run multiple in parallel       │
│     ├── Review outputs for quality and relevance                │
│     └── Synthesize findings into unified research document      │
│  4. Document findings in research/[topic].md                    │
│  5. Update CONTEXT.md and PROGRESS.md                           │
│  6. Commit and summarize planning implications                  │
└─────────────────────────────────────────────────────────────────┘
```

## Process

1. I'll review CONTEXT.md and PROGRESS.md for planning context
2. I'll clarify the research question if needed
3. I'll assess whether specialized subagents can improve research quality
4. I'll gather and analyze information (delegating to subagents as appropriate)
5. I'll synthesize all findings into `research/[topic].md`
6. I'll update CONTEXT.md with key references
7. I'll commit the changes to version control with a descriptive message
8. I'll summarize planning implications

## Formatting Guidelines

All planning artifacts must follow the markdown formatting standards defined in the global `markdown-formatting` rule. Key requirements include JIRA ticket hyperlinks, ISO date formats, consistent status indicators, and proper document structure.

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

