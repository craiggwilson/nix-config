# Artifact & Session Management

## Project Directory Structure

```
~/.local/share/opencode/projects/<project-id>/
├── project.json          # Project metadata and status
├── issues/               # All issues
│   ├── <issue-id>.json
│   └── ...
├── sessions/             # Session history
│   ├── <session-id>.json
│   └── ...
├── decisions/            # Recorded decisions
│   ├── <decision-id>.json
│   └── ...
├── artifacts/            # Artifact registry
│   ├── registry.json
│   └── ...
└── research/             # Research documents
    ├── <artifact-file>.md
    └── ...
```

## Sessions & Continuity

Each conversation is a session. Sessions are automatically tracked and linked to the project.

**Resuming a delegation after session compaction:**
```json
project-internal-delegation-read(id="delegation-id", projectId="project-id")
```

Use this when a `<team-notification>` arrives after session compaction and you need to read the full result.

## Research Artifacts

Research agents should save their findings as artifacts:

```json
project-save-artifact(
  title="Rate Limiting Patterns Research",
  type="research",
  path="research/rate-limiting-patterns.md",
  summary="Analysis of token bucket, leaky bucket, and sliding window approaches",
  sourceIssue="rate-limiting/bd-xxx.1"
)
```

Artifacts are registered in `artifacts/registry.json` and linked to their source issue and session.

## Decisions

Record architectural and design decisions with full rationale:

```json
project-record-decision(
  title="Use token bucket for rate limiting",
  decision="Implement token bucket algorithm using Redis for distributed rate limiting",
  rationale="Token bucket allows burst traffic, Redis provides atomic operations across instances",
  status="decided",
  alternatives=[
    {
      name: "Leaky bucket",
      description: "Smooths traffic to constant rate",
      whyRejected: "Too restrictive for API use cases with legitimate burst patterns"
    }
  ],
  relatedIssues=["rate-limiting/bd-xxx.2"]
)
```

**Decision statuses:** `proposed`, `decided`, `rejected`, `deferred`

## Issue Hierarchy

Issues support three levels of hierarchy:

```
Epic (bd-a3f8)
├── Task (bd-a3f8.1)
│   ├── Subtask (bd-a3f8.1.1)
│   └── Subtask (bd-a3f8.1.2)
└── Task (bd-a3f8.2)
```

Create child issues with the `parent` field:
```json
project-create-issue(title="...", parent="bd-a3f8.1")
```

## Issue Labels & Priority

**Priority levels:**
- `1` — P1: Critical, blocking
- `2` — P2: High importance
- `3` — P3: Normal
- `4` — P4: Low, deferred

**Common labels:** `research`, `implementation`, `bug`, `enhancement`, `documentation`, `future`, `blocked`
