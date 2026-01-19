---
description: Kickstart a planning cycle for roadmap, project, or task planning
argument-hint: [roadmap|project|task] [project-directory]
---

You are initiating a planning workflow. Based on the planning type requested, you will guide through the appropriate discovery and planning process.

**Planning Type**: $ARGUMENTS

## Workflow Selection

### If "roadmap" planning:
1. **Discovery Phase**
   - Review strategic context (vision, OKRs, constraints)
   - Analyze current capabilities and technical debt
   - Identify stakeholder priorities
   - Map dependencies across initiatives

2. **Initial Outputs**
   - Create/update `roadmap/` directory in project folder
   - Generate `roadmap/discovery.md` with findings
   - Draft initial themes and quarterly structure
   - Identify gaps requiring stakeholder input

3. **Next Steps Preparation**
   - List questions needing stakeholder answers
   - Identify risks and assumptions to validate
   - Prepare for prioritization discussions

### If "project" planning:
1. **Discovery Phase**
   - Review roadmap context and initiative scope
   - Identify all stakeholders and their interests
   - Assess technical complexity and risks
   - Determine resource requirements

2. **Initial Outputs**
   - Generate initial scope statement draft
   - Create stakeholder register
   - Draft high-level timeline

3. **Next Steps Preparation**
   - List scope clarifications needed
   - Identify resource constraints
   - Prepare for kickoff meeting

### If "task" planning:
1. **Discovery Phase**
   - Review project scope and work breakdown
   - Understand current sprint/iteration context
   - Identify technical dependencies
   - Assess team capacity

2. **Initial Outputs**
   - Generate user stories or task definitions
   - Define acceptance criteria
   - Create initial estimates
   - Map dependencies between tasks

3. **Next Steps Preparation**
   - List stories needing refinement
   - Identify blocked items
   - Prepare for sprint planning

## Process

1. First, I'll ask clarifying questions about your planning context
2. Then, I'll gather relevant information from documents and codebase
3. Next, I'll generate initial planning artifacts
  - `CONTEXT.md` - Project context and requirements
  - `PROGRESS.md` - Current status and next steps
4. Finally, I'll provide a summary of findings and next steps

**Let's begin. Please confirm the planning type and provide any relevant context or project directory path.**

