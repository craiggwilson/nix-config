# OpenCode Planning & Execution Plugin Suite - Agents and Skills

## Overview

This document describes the agents and skills available in the OpenCode planning and execution plugin suite.

**Agents** are "who" - the specialized workers that perform tasks.
**Skills** are "how" - the tools and capabilities that agents use.

## Orchestration and Parallelism

The three plugins each have an orchestrator agent (program planner, project planner, work executor) that coordinates subagents.

- Orchestrators treat agents as subagents they can spawn for focused tasks (analysis, design, implementation, review).
- Independent subagents should be spawned in parallel where possible (for example, language expert + security architect + distributed-systems architect), with the orchestrator aggregating results.
- At a coarse level, the project planner can treat the work executor as a subagent for implementation, and the program planner can treat the project planner as a subagent for project-scale planning, all collaborating through beads as the shared state store.

## Agents

### What is an Agent?

An agent is a specialized worker with expertise in a particular domain. Agents are invoked by orchestrators to perform specific tasks like:
- Designing solutions
- Implementing code
- Reviewing code
- Analyzing architecture
- Assessing security

### Agent Categories

#### 1. Language Experts

Specialists in specific programming languages and frameworks.

**Available Agents:**
- `go-expert` – Go development with idiomatic patterns
- `java-expert` – Java/JVM development with enterprise patterns
- `nix-expert` – Nix/NixOS development and system configuration
- `terraform-expert` – Infrastructure as code with Terraform
- `flink-expert` – Apache Flink stream processing
- `kafka-expert` – Apache Kafka event streaming
- `mongodb-expert` – MongoDB database design and optimization

**Capabilities:**
- Code implementation
- Code review
- Testing
- Performance optimization

**Example Usage:**
```typescript
// Spawn a Go expert to implement a feature
const implementation = await spawnSubagent("go-expert", {
  task: "Implement caching layer",
  requirements: "...",
  existingCode: "..."
});
```

#### 2. Architecture Experts

Specialists in system design and architecture.

**Available Agents:**
- `distributed-systems-architect` – Scalable, resilient service design
- `aws-expert` – AWS services and cloud-native patterns

**Capabilities:**
- System design
- Architecture review
- Performance analysis
- Risk assessment

**Example Usage:**
```typescript
// Spawn a distributed systems architect for design review
const design = await spawnSubagent("distributed-systems-architect", {
  problem: "Design a caching layer",
  constraints: "...",
  requirements: "..."
});
```

#### 3. Security Experts

Specialists in security and threat modeling.

**Available Agents:**
- `security-architect` – Secure system design and threat modeling

**Capabilities:**
- Threat modeling
- Secure design
- Security review
- Compliance assessment

**Example Usage:**
```typescript
// Spawn a security architect for threat modeling
const threats = await spawnSubagent("security-architect", {
  system: "API design",
  assets: "User data, authentication tokens",
  threats: "..."
});
```

#### 4. Review Agents

Specialists in code and security review.

**Available Agents:**
- `code-reviewer-agent` – Code quality, correctness, style
- `security-reviewer-agent` – Security vulnerability detection

**Capabilities:**
- Code review
- Style checking
- Testing review
- Vulnerability detection
- Dependency analysis

**Example Usage:**
```typescript
// Spawn a code reviewer
const review = await spawnSubagent("code-reviewer-agent", {
  code: "...",
  context: "...",
  standards: "..."
});

// Spawn a security reviewer
const securityReview = await spawnSubagent("security-reviewer-agent", {
  code: "...",
  context: "...",
  threats: "..."
});
```

#### 5. Analysis Agents

Specialists in code analysis and understanding.

**Available Agents:**
- `codebase-analyst` – Code archaeology and architecture discovery
- `explore` – Fast codebase exploration

**Capabilities:**
- Code analysis
- Architecture analysis
- Dependency analysis
- Pattern detection

**Example Usage:**
```typescript
// Spawn a codebase analyst to understand existing code
const analysis = await spawnSubagent("codebase-analyst", {
  codebase: "...",
  question: "How is authentication implemented?"
});
```

## Skills

### What is a Skill?

A skill is a tool or capability that agents use to perform their work. Skills are the "how" - the mechanisms by which agents accomplish tasks.

### Skill Categories

#### 1. Beads Skills

Skills for interacting with the beads issue tracking system.

**Available Skills:**
- `beads-query` – Query issues with filters
- `beads-crud` – Create, read, update, delete issues
- `beads-dependencies` – Manage dependencies between issues

**Operations:**
- Query issues by labels, status, priority
- Create new issues
- Update issue fields
- Create and analyze dependencies

**Example Usage:**
```typescript
// Query beads for ready tasks
const readyTasks = await useSkill("beads-query", {
  labels: ["task"],
  status: ["todo"],
  dependencies: [] // no blocking dependencies
});

// Create a new issue
const newIssue = await useSkill("beads-crud", {
  operation: "create",
  type: "task",
  title: "Implement feature X",
  labels: ["implementation"]
});
```

#### 2. Code Skills

Skills for analyzing and modifying code.

**Available Skills:**
- `code-analysis` – Analyze code structure and patterns
- `code-modification` – Modify code with proper formatting

**Operations:**
- Understand code structure
- Identify patterns and anti-patterns
- Detect issues
- Edit files
- Refactor code
- Format code

**Example Usage:**
```typescript
// Analyze code
const analysis = await useSkill("code-analysis", {
  code: "...",
  question: "What design patterns are used?"
});

// Modify code
const modified = await useSkill("code-modification", {
  file: "src/main.ts",
  changes: "..."
});
```

#### 3. Testing Skills

Skills for running and analyzing tests.

**Available Skills:**
- `testing` – Run tests and analyze coverage

**Operations:**
- Run test suites
- Analyze test coverage
- Create new tests

**Example Usage:**
```typescript
// Run tests
const results = await useSkill("testing", {
  operation: "run-tests",
  suite: "unit"
});

// Analyze coverage
const coverage = await useSkill("testing", {
  operation: "analyze-coverage"
});
```

#### 4. Build Skills

Skills for building and compiling code.

**Available Skills:**
- `build` – Build and compile code

**Operations:**
- Compile code
- Build artifacts
- Package for distribution

**Example Usage:**
```typescript
// Build the project
const build = await useSkill("build", {
  operation: "compile",
  target: "release"
});
```

#### 5. Documentation Skills

Skills for creating and updating documentation.

**Available Skills:**
- `documentation` – Create and update documentation

**Operations:**
- Create new documents
- Update existing documents
- Generate documentation

**Example Usage:**
```typescript
// Create documentation
const doc = await useSkill("documentation", {
  operation: "create-doc",
  title: "API Reference",
  content: "..."
});
```

#### 6. Analysis Skills

Skills for analyzing system architecture and dependencies.

**Available Skills:**
- `architecture-analysis` – Analyze system architecture
- `dependency-analysis` – Analyze code dependencies

**Operations:**
- Analyze architecture
- Identify patterns
- Assess design
- Analyze dependencies
- Detect cycles
- Identify risks

**Example Usage:**
```typescript
// Analyze architecture
const arch = await useSkill("architecture-analysis", {
  codebase: "...",
  question: "What is the overall architecture?"
});

// Analyze dependencies
const deps = await useSkill("dependency-analysis", {
  codebase: "...",
  operation: "detect-cycles"
});
```

#### 7. Security Skills

Skills for security analysis and threat modeling.

**Available Skills:**
- `security-analysis` – Analyze code for vulnerabilities
- `threat-modeling` – Perform threat modeling

**Operations:**
- Detect vulnerabilities
- Analyze permissions
- Check for secrets
- Identify threats
- Assess risks
- Recommend mitigations

**Example Usage:**
```typescript
// Analyze security
const vulns = await useSkill("security-analysis", {
  code: "...",
  operation: "detect-vulnerabilities"
});

// Threat modeling
const threats = await useSkill("threat-modeling", {
  system: "...",
  operation: "identify-threats"
});
```

## Agent-Skill Mapping

### Go Expert

**Required Skills:**
- code-analysis
- code-modification
- testing
- build

**Typical Workflow:**
1. Use `code-analysis` to understand existing code
2. Use `code-modification` to implement changes
3. Use `testing` to verify implementation
4. Use `build` to compile and package

### Security Architect

**Required Skills:**
- security-analysis
- threat-modeling
- architecture-analysis

**Typical Workflow:**
1. Use `architecture-analysis` to understand system
2. Use `threat-modeling` to identify threats
3. Use `security-analysis` to assess risks
4. Recommend mitigations

### Code Reviewer

**Required Skills:**
- code-analysis
- testing
- security-analysis

**Typical Workflow:**
1. Use `code-analysis` to review code quality
2. Use `testing` to verify test coverage
3. Use `security-analysis` to check for vulnerabilities
4. Provide feedback

## Extending Agents and Skills

### Adding a New Agent

1. Define the agent in `core/src/agents.ts`:
```typescript
"my-expert": {
  name: "My Expert",
  description: "Expert in my domain",
  category: "language",
  capabilities: ["capability1", "capability2"],
  requiredSkills: ["skill1", "skill2"]
}
```

2. Document in AGENTS_AND_SKILLS.md

3. Update orchestrators to use the new agent

### Adding a New Skill

1. Define the skill in `core/src/skills.ts`:
```typescript
"my-skill": {
  name: "My Skill",
  description: "Capability for my domain",
  category: "code",
  operations: ["operation1", "operation2"],
  requiredTools: ["tool1", "tool2"]
}
```

2. Document in AGENTS_AND_SKILLS.md

3. Implement the skill in the appropriate agent

## Future Enhancements

### Phase 2: Subagent Coordination

- Implement subagent spawning interface
- Add result aggregation
- Handle errors and retries
- Add timeout management

### Phase 3: Skill Integration

- Implement skill execution interface
- Add skill chaining
- Add skill result caching
- Add skill performance monitoring

### Phase 4: Advanced Features

- Agent collaboration
- Skill composition
- Dynamic agent selection
- Performance optimization

## References

- See [SPEC.md](SPEC.md) for plugin specifications
- See [AGENTS.md](*/AGENTS.md) for plugin-specific agent details
- See [IMPLEMENTATION.md](IMPLEMENTATION.md) for architecture details
