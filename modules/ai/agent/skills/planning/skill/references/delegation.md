# Subagent Delegation

Leverage specialized subagents when their expertise improves quality or efficiency.

## Available Planning Subagents

| Subagent | Specialty | Delegate When |
|----------|-----------|---------------|
| `roadmap-builder` | Strategic planning, OKR alignment | Roadmap planning with complex priorities |
| `project-planner` | Scope, resources, risk assessment | Project planning needing detailed WBS/risk analysis |
| `task-planner` | Stories, acceptance criteria, estimation | Task decomposition with complex dependencies |
| `codebase-analyst` | Code archaeology, architecture | Technical discovery for any planning type |
| `security-architect` | Security patterns, threat modeling | Security-related research or validation |
| `distributed-systems-architect` | Service design, resilience | Scalability research, system integration |

## Delegation Criteria

**Delegate when:**
- Complex multi-stakeholder planning (>3 stakeholders)
- Deep domain expertise needed (security, architecture, data)
- Detailed decomposition required (testable deliverables)
- Parallel work can accelerate planning
- Quality validation benefits from expert review

**Don't delegate when:**
- Simple single-stakeholder planning
- Context gathering only (no analysis)
- Quick updates to existing artifacts

## Handoff Process

**Context to provide subagent:**
1. Planning type and current phase
2. Relevant content from CONTEXT.md
3. Specific deliverable(s) expected
4. Constraints (timeline, resources, dependencies)
5. Quality criteria

**Expected deliverables:**
- Complete/refined artifacts in expected format
- Risks and blockers identified
- Recommendations for next steps
- Open questions requiring stakeholder input
