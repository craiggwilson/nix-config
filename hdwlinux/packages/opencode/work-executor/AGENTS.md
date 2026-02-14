# OpenCode Work Executor Plugin

Actual implementation of work with specialist subagents for research, POCs, and code review.

## Overview

The Work Executor plugin owns claiming and executing beads issues. It orchestrates a stable of specialist subagents (language experts, distributed systems architects, security experts, code reviewers) to perform research, create POCs, implement features, and conduct reviews.

## Architecture

### Orchestrator Agent: `work-orchestrator`

Central dispatcher for work execution. Reads beads issues and coordinates specialist subagents.

**Responsibilities**:
- Handle `/work-*` commands
- Fetch and parse beads issue context
- Determine work type (research, POC, implementation, review)
- Select appropriate specialist subagents based on:
  - Issue labels (language, domain, tech stack)
  - Repo technology stack (detected or configured)
  - Work type and complexity
- Manage execution pipeline (analyze → design → implement → test → review → security review → wrap-up)
- Update beads with status, discovered work, and links to artifacts

### Specialist Implementation Subagents

#### Language & Framework Experts

- `go-expert` – Go development
- `java-expert` – Java/JVM development
- `nix-expert` – Nix/NixOS development
- `terraform-expert` – Terraform/IaC
- `flink-expert` – Apache Flink
- `kafka-expert` – Apache Kafka
- `mongodb-expert` – MongoDB
- (Additional experts as needed)

**Responsibilities**:
- Understand existing code and patterns
- Propose designs aligned with language/framework idioms
- Implement features with high quality
- Ensure tests are comprehensive
- Follow established code style and conventions

#### Distributed Systems Architect

- `distributed-systems-architect` – System design, scalability, fault tolerance

**Responsibilities**:
- Propose system designs for complex features
- Analyze scalability and performance implications
- Identify failure modes and mitigation strategies
- Review designs for distributed systems concerns

#### Security Architect

- `security-architect` – Threat modeling, secure design, hardening

**Responsibilities**:
- Threat modeling for new features
- Secure design review
- Identify security risks and mitigations
- Recommend security best practices

#### Cloud/Infrastructure Experts

- `aws-expert` – AWS services and architecture
- (Additional cloud providers as needed)

**Responsibilities**:
- Propose cloud-native designs
- Optimize for cost and performance
- Ensure compliance and security
- Recommend managed services vs self-hosted

#### Codebase Analysts

- `codebase-analyst` – Code archaeology, architecture discovery
- `explore` – Fast codebase exploration

**Responsibilities**:
- Understand existing code structure
- Identify relevant tests and patterns
- Locate similar implementations
- Propose minimal, consistent changes

### Reviewer Subagents

#### Code Reviewer

- `code-reviewer-agent` – Code quality, correctness, style

**Responsibilities**:
- Review code for correctness and logic
- Check style and consistency with codebase
- Verify tests are adequate
- Suggest improvements and refactorings
- Verify all changes are intentional and necessary

#### Security Reviewer

- `security-reviewer-agent` – Security-focused review

**Responsibilities**:
- Review for security vulnerabilities
- Check input validation and authorization
- Verify cryptographic usage
- Identify secrets or sensitive data exposure
- Check dependency security
- Create security-related follow-up issues

### Skills & External Tools

- **Beads CLI**: `bd show`, `bd new`, `bd dep add`, `bd update`, etc.
- **Code Execution**: Run tests, builds, linters
- **Documentation**: Google Docs/Drive or local `history/` files
- **Git/VCS**: Create branches, commits, PRs
- **Codebase Analysis**: Deep understanding of existing code

### Orchestration & Parallelism

The `work-orchestrator` coordinates specialist subagents and should:

- Spawn independent subagents in parallel (for example, language expert + codebase analyst + distributed-systems architect) and then aggregate their findings.
- Run review-focused subagents (code review and security review) concurrently once implementation and tests are in place.
- Expose a clear pipeline state back to beads so higher-level planners can see progress without blocking on individual subagent steps.

## Commands

See SPEC.md for detailed command documentation:
- `/work-claim` – Claim a suitable ready task
- `/work-execute` – Execute one or more specific issues
- `/work-poc` – Create and/or execute a POC
- `/work-research` – Perform pure research
- `/work-review` – Perform code or security review

## Work Types & Pipelines

### Research Pipeline

**Goal**: Investigate a topic and produce a recommendation.

**Steps**:
1. Understand issue context (beads + docs)
2. Spawn domain experts to:
   - Summarize options
   - Analyze pros/cons
   - Recommend a path
3. Produce concise report:
   - Attached to beads issue
   - Optional external doc in `history/research/`
4. Create follow-up implementation tasks (if needed)

**Output**:
- Research issue marked `done`
- Report summary in issue description
- Optional follow-up tasks with `discovered-from` dependency

### POC Pipeline

**Goal**: Prove or disprove a hypothesis with minimal code.

**Steps**:
1. Clarify hypothesis and success criteria
2. Minimal design from appropriate experts
3. Focused implementation and basic validation
4. Produce "Keep/Refine/Discard" recommendation
5. Capture notes for planners
6. File discovered work tasks

**Output**:
- POC issue marked `done`
- Recommendation in issue description
- Optional POC notes in `history/pocs/`
- Discovered work issues with `discovered-from` dependency

### Implementation Pipeline

**Goal**: Fully implement a feature with tests and reviews.

**Steps**:
1. Analyze requirements and existing code/tests
2. Design step:
   - Spawn appropriate experts (distributed systems, security, language)
   - Produce design doc (optional, in `history/designs/`)
3. Implementation step:
   - Spawn language/domain expert
   - Implement with tests
   - Run tests and linters
4. Code review:
   - Spawn `code-reviewer-agent`
   - Address feedback
5. Security review:
   - Spawn `security-reviewer-agent`
   - Address findings
   - Create security follow-up issues if needed
6. Wrap-up:
   - Mark issue `done`
   - Update beads with discovered work
   - Create PR or commit as appropriate

**Output**:
- Implementation issue marked `done`
- Code changes in repo
- Tests passing
- Review comments addressed
- Discovered work issues filed

### Review Pipeline

**Goal**: Provide code or security review for existing work.

**Steps**:
1. Fetch target code/PR
2. Spawn appropriate reviewer subagent(s)
3. Produce review with:
   - Findings and suggestions
   - Severity levels
   - Actionable recommendations
4. Create follow-up issues for findings (if needed)

**Output**:
- Review comments on PR or beads issue
- Follow-up issues for findings

## State Model (Beads)

### Work Issues

- **Types**: `task`, `feature`, `chore`, `bug`
- **Labels**: Work type (`research`, `poc`, `implementation`, `review`, `security-review`)
- **Labels**: Domain/tech labels (e.g., `kafka`, `nix`, `distributed-systems`, `security`)
- **Status**: `todo`, `in_progress`, `blocked`, `done`
- **Assignee**: User or `agent:work-executor`
- **Parent**: Project epic or program epic
- **Description**: Clear requirements, acceptance criteria, links to design docs

### Discovered Work Issues

- **Created during work execution**
- **Linked via `discovered-from:<parent-id>` dependency**
- **Types**: `bug`, `chore`, `task`, `feature`
- **Labels**: `discovered-from:<parent-id>` (for easy filtering)

### Review Issues

- **Type**: `task`
- **Labels**: `review` or `security-review`
- **Status**: `in_progress` during review, `done` when complete
- **Description**: Review findings and recommendations

## Configuration

File: `~/.config/opencode/plugins/work-executor.json`

```json
{
  "riskPosture": "high",
  "alwaysRunSecurityReview": true,
  "autonomousEditLimits": {
    "maxFilesPerCommit": 10,
    "requiresApprovalForPublicAPIs": true,
    "requiresApprovalForDependencyChanges": true
  },
  "techStackPreferences": {
    "defaultLanguage": "go",
    "preferredFrameworks": ["nix", "terraform"]
  }
}
```

Per-repo config: `.beads/work-executor.json` or `.opencode/work-executor.json`

```json
{
  "language": "go",
  "domains": ["distributed-systems", "kafka"],
  "alwaysRunSecurityReview": true
}
```

## Integration with Other Plugins

### Work Executor ← Project Planner

- Receives ready tasks with clear descriptions and parents
- Inherits project/program context

### Work Executor → Project Planner

- Updates task statuses
- Files discovered work with `discovered-from` dependencies
- Provides implementation status for project health

### Work Executor ← Program Planner

- May receive research/POC requests
- Provides outcomes that may alter program scope

## Development Notes

- Always use beads as the single source of truth
- Keep issue descriptions concise; use external docs for rich details
- Use hierarchical labels for organization (e.g., `domain:kafka`)
- Discovered work should be filed with `discovered-from` dependencies
- Always run code review and security review for implementation work
- Produce clear, actionable recommendations for research and POCs
- Store rich artifacts (reports, POC notes, design docs) in `history/` or external docs
