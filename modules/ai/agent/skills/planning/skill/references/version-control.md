# Version Control Integration

All planning artifacts are version controlled with Jujutsu.

## Commit Message Format

```bash
planning: <phase> <planning-type> for <project-name>

<Context line>
- <Key change 1>
- <Key change 2>

<Next steps or planning phase>
```

## Examples

**Initialization:**
```bash
jj describe -m "planning: init project planning for API redesign

- Created CONTEXT.md with project context and requirements
- Created PROGRESS.md with initial status and next steps

Planning Phase: Discovery"
jj new
```

**Research:**
```bash
jj describe -m "planning: research authentication patterns for API redesign

Research Question: Which auth pattern fits our use case?

Key Findings:
- OAuth 2.0 with PKCE recommended for public clients
- JWT validation requires careful implementation

Recommendation: Use OAuth 2.0 with Auth0

Planning Impact: Affects API security design and timeline"
jj new
```

**Continuation:**
```bash
jj describe -m "planning: continue API redesign planning

Session: 2026-03-21
- Completed WBS decomposition
- Updated risk register
- Identified 3 new dependencies

Next: Resource allocation planning"
jj new
```

## Retrieving Context History

```bash
# View all planning commits
jj log --no-graph -r 'description(glob:"planning:*")'

# Show how a file evolved
jj file annotate CONTEXT.md

# View file at specific revision
jj file show research/auth-patterns.md -r <revision>

# Compare states
jj diff -r <old-revision> CONTEXT.md
```
