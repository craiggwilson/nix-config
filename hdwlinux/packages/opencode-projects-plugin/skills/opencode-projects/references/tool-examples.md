# Tool Examples

## project-create

```json
{
  "name": "authentication-system",
  "type": "project",
  "description": "Implement OAuth2 authentication with social login support"
}
```

## project-list

```json
{
  "scope": "local",
  "status": "active"
}
```

## project-status

```json
{
  "projectId": "auth-system",
  "format": "tree"
}
```

## project-focus

```json
{
  "projectId": "auth-system",
  "issueId": "bd-a3f8.2"
}
```

Call without arguments to see current focus.

## project-plan

```json
{
  "projectId": "auth-system",
  "action": "advance"
}
```

## project-close

```json
{
  "projectId": "auth-system",
  "reason": "completed",
  "summary": "OAuth2 authentication implemented with Google and GitHub providers"
}
```

## project-create-issue

```json
{
  "title": "Implement OAuth2 token refresh",
  "projectId": "auth-system",
  "description": "Handle token expiration and automatic refresh",
  "priority": 1,
  "parent": "bd-a3f8",
  "labels": ["backend", "security"]
}
```

**Hierarchical IDs:**
- Epic: `bd-a3f8`
- Task (child of epic): `bd-a3f8.1`
- Subtask (child of task): `bd-a3f8.1.1`

## project-work-on-issue

```json
// Research task - no isolation
{
  "issueId": "bd-xxx.1",
  "agents": ["codebase-analyst"]
}

// Code change with explicit team
{
  "issueId": "bd-xxx.2",
  "isolate": true,
  "agents": ["go-expert", "security-architect"]
}

// Auto-select team for code change
{
  "issueId": "bd-xxx.3",
  "isolate": true
}

// Wait for quick task
{
  "issueId": "bd-xxx.4",
  "foreground": true,
  "agents": ["codebase-analyst"]
}
```

## project-update-issue

```json
// Close an issue
{
  "issueId": "bd-a3f8.2",
  "status": "closed",
  "comment": "OAuth2 implementation complete, all tests passing"
}
```

## project-record-decision

```json
{
  "title": "Use OAuth2 with PKCE over SAML",
  "decision": "Implement OAuth2 with PKCE flow for user authentication instead of SAML",
  "rationale": "OAuth2 has better mobile/SPA support, PKCE provides security without client secrets, simpler implementation",
  "status": "decided",
  "alternatives": [
    {
      "name": "SAML 2.0",
      "description": "Enterprise standard with strong SSO support",
      "whyRejected": "XML-based complexity, poor mobile support, requires more infrastructure"
    }
  ],
  "sourceResearch": ["research-auth-patterns-abc123"],
  "relatedIssues": ["bd-a3f8", "bd-a3f8.1"]
}
```

## project-save-artifact

```json
{
  "title": "Authentication Patterns Research",
  "type": "research",
  "path": "research/auth-patterns.md",
  "summary": "Analysis of OAuth2, SAML, and OIDC patterns for multi-tenant SaaS",
  "sourceIssue": "bd-a3f8.1"
}
```

**Common artifact types:** `research`, `decision`, `deliverable`, `plan`, `documentation`
