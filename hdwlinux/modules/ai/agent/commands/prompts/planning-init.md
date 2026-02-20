You are initiating a planning workflow. Based on the planning type requested, you will guide through the appropriate discovery and planning process.

**Arguments**: $ARGUMENTS

The first argument specifies the planning type (roadmap, project, or task). An optional second argument can specify a focus area for the planning session (e.g., "security review", "technical debt", "Q2 initiatives", "API design") to help direct the discovery process toward specific concerns.

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

## Existing Files Handling

Before creating new artifacts, I will check if planning files already exist in the project directory.

### If files exist and match expected structure:
- Confirm with user: "Planning artifacts already exist. Would you like to:"
  1. **Continue** - Use `planning-continue` instead to resume the existing planning cycle
  2. **Reset** - Archive existing files and start fresh
  3. **Review** - Show current state before deciding

### If files exist but don't match expected structure:
- Analyze existing content and prompt user:

```
I found existing files that don't match the expected planning structure:

**Found:**
- [List of existing files with brief description of their content]

**Expected structure:**
- CONTEXT.md - Project context and requirements
- PROGRESS.md - Current status and next steps
- sessions/ - Session notes
- research/ - Research documents (optional)
- roadmap/ or deliverables/ - Planning artifacts (optional)

**Options:**
1. **Convert** - I'll migrate the existing content into the expected structure:
   - Extract context/requirements into CONTEXT.md
   - Extract status/todos into PROGRESS.md
   - Preserve original files in `archive/pre-migration/`

2. **Merge** - Keep existing files and add missing structure alongside them

3. **Fresh start** - Archive everything to `archive/` and create new artifacts

4. **Abort** - Exit without changes

Which would you prefer?
```

### Conversion Process

If the user chooses **Convert**:

1. **Analyze existing content:**
   - Identify context, requirements, and background information
   - Identify status, progress, and next steps
   - Identify any research or decision documentation
   - Note the original structure for reference

2. **Create archive:**
   ```bash
   mkdir -p archive/pre-migration
   cp -r [existing-files] archive/pre-migration/
   ```

3. **Generate converted artifacts:**
   - Create `CONTEXT.md` with extracted context, preserving original source references
   - Create `PROGRESS.md` with extracted status, linking to migration
   - Move research-like content to `research/`
   - Add migration note to `sessions/YYYY-MM-DD-migration.md`

4. **Commit the migration:**
   ```bash
   jj describe -m "planning: migrate existing content to planning structure

   Migrated from: [description of original structure]
   - Original files archived to archive/pre-migration/
   - Created CONTEXT.md from [sources]
   - Created PROGRESS.md from [sources]

   Ready for: [planning-type] planning"
   jj new
   ```

## Subagent Delegation

As an orchestrator, I leverage specialized subagents when their expertise can improve planning quality or efficiency.

### Available Planning Subagents

| Subagent | Specialty | When to Delegate |
|----------|-----------|------------------|
| `roadmap-builder` | Strategic planning, OKR alignment, multi-quarter planning | Roadmap planning with complex stakeholder priorities or cross-initiative dependencies |
| `project-planner` | Scope definition, resource planning, risk assessment | Project planning requiring detailed WBS, resource allocation, or risk analysis |
| `task-planner` | User story creation, acceptance criteria, sprint planning | Task decomposition needing detailed acceptance criteria or complex dependency mapping |
| `codebase-analyst` | Code archaeology, architecture discovery | Technical context gathering for any planning type |

### Delegation Criteria

Delegate to a specialized subagent when:
- **Complexity threshold exceeded**: Planning involves more than 3 stakeholders, multiple systems, or cross-team dependencies
- **Domain expertise required**: Specialized knowledge (security, architecture, data) would improve quality
- **Detailed decomposition needed**: Work breakdown requires granular, testable deliverables
- **Time efficiency**: Parallel subagent work can accelerate the planning cycle

### Handoff Process

**Context to provide subagent:**
```
1. Planning type (roadmap/project/task)
2. Relevant content from CONTEXT.md
3. Specific deliverable(s) expected
4. Constraints (timeline, resources, dependencies)
5. Quality criteria for the output
```

**Expected deliverables from subagent:**
- Draft artifacts in the expected format
- Identified risks or blockers
- Recommendations for next steps
- Open questions requiring stakeholder input

### Integration Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                    planning-init (orchestrator)                  │
├─────────────────────────────────────────────────────────────────┤
│  1. Initial context gathering and planning type identification   │
│  2. Assess complexity → determine if delegation needed           │
│  3. If delegating:                                               │
│     ├── Prepare context package for subagent                    │
│     ├── Invoke appropriate subagent with clear deliverables     │
│     ├── Review subagent output for quality and completeness     │
│     └── Integrate deliverables into planning artifacts          │
│  4. Generate/update CONTEXT.md and PROGRESS.md                  │
│  5. Commit and summarize next steps                             │
└─────────────────────────────────────────────────────────────────┘
```

## Process

1. First, I'll check for existing files and handle accordingly (see above)
2. I'll ask clarifying questions about your planning context
3. I'll assess complexity and delegate to specialized subagents if beneficial
4. I'll gather relevant information from documents and codebase (or via codebase-analyst)
5. Next, I'll generate initial planning artifacts (integrating any subagent outputs)
  - `CONTEXT.md` - Project context and requirements
  - `PROGRESS.md` - Current status and next steps
6. I'll commit the changes to version control with a descriptive message
7. Finally, I'll provide a summary of findings and next steps

## Formatting Guidelines

All planning artifacts must follow the markdown formatting standards defined in the global `markdown-formatting` rule. Key requirements include JIRA ticket hyperlinks, ISO date formats, consistent status indicators, and proper document structure.

## Version Control

After creating planning artifacts, I will commit the changes:

```bash
# Stage and commit planning artifacts
jj describe -m "planning: init [planning-type] planning for [project-name]

- Created CONTEXT.md with project context and requirements
- Created PROGRESS.md with initial status and next steps
- [Additional artifacts created]

Planning Phase: Discovery"
jj new  # Create a new change for subsequent work
```

The commit message should:
- Start with `planning:` prefix
- Include the planning type (roadmap/project/task)
- Summarize what artifacts were created
- Note the current planning phase

### Retrieving Context History

The full history of planning context and decisions can be retrieved from the repository history:

```bash
# View history of planning changes
jj log --no-graph -r 'description(glob:"planning:*")'

# Show how a specific file evolved
jj file annotate [file-path]

# View a file at a specific revision
jj file show [file-path] -r [revision]

# Compare current state to previous version
jj diff -r [revision] [file-path]
```

This history serves as an audit trail of planning decisions and context evolution.

**Let's begin. Please confirm the planning type and provide any relevant context or project directory path.**

