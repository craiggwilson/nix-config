# Workflow Examples

## Example 1: Research Task (No Isolation)

```
User: Research the best approach for implementing rate limiting in our Go API

1. Create project
   project-create(name="rate-limiting", type="project")

2. Create research issue
   project-create-issue(title="Research rate limiting approaches", projectId="rate-limiting")

3. Delegate to researcher (no isolation needed for research)
   project-work-on-issue(issueId="rate-limiting/bd-xxx.1", agents=["researcher"])

4. [Notification received]
   project-update-issue(issueId="rate-limiting/bd-xxx.1", status="closed")

5. Create implementation issue based on findings
   project-create-issue(title="Implement token bucket rate limiter", ...)
```

## Example 2: Code Change (Isolated Workspace)

```
User: Implement the rate limiter

1. Delegate with isolation
   project-work-on-issue(issueId="rate-limiting/bd-xxx.2", isolate=true)

2. [Notification received with workspace info]
   Review changes:
   jj diff --from <feature-name> --to rate-limiting/bd-xxx.2@

3. Rebase workspace onto feature bookmark, advance bookmark, clean up
   jj rebase -s rate-limiting/bd-xxx.2@ -d <feature-name>
   jj bookmark set <feature-name> -r <rebased-id>
   jj workspace forget rate-limiting/bd-xxx.2

4. Close the issue
   project-update-issue(issueId="rate-limiting/bd-xxx.2", status="closed")
```

## Example 3: Multi-Agent Team with Discussion

```
User: Implement OAuth2 with security review

1. Create issue
   project-create-issue(title="Implement OAuth2 authentication", ...)

2. Delegate with explicit team (primary + devil's advocate)
   project-work-on-issue(
     issueId="auth/bd-xxx.3",
     isolate=true,
     agents=["coder", "security-architect"],
     discussionStrategy="dynamicRound"
   )

3. [Notification received after discussion rounds complete]
   Review diff, rebase workspace, close issue
```

## Example 4: Parallel Implementation (Multiple Issues)

```
User: Implement all three auth providers in parallel

1. Create issues
   project-create-issue(title="Implement Google OAuth", ...)
   project-create-issue(title="Implement GitHub OAuth", ...)
   project-create-issue(title="Implement Apple OAuth", ...)

2. Delegate all in parallel (fire and forget)
   project-work-on-issue(issueId="auth/bd-xxx.4", isolate=true)
   project-work-on-issue(issueId="auth/bd-xxx.5", isolate=true)
   project-work-on-issue(issueId="auth/bd-xxx.6", isolate=true)

3. As each notification arrives, rebase onto feature bookmark in order:
   jj rebase -s auth/bd-xxx.4@ -d <feature-name> && jj bookmark set <feature-name> -r <rebased-id>
   jj rebase -s auth/bd-xxx.5@ -d <feature-name> && jj bookmark set <feature-name> -r <rebased-id>
   jj rebase -s auth/bd-xxx.6@ -d <feature-name> && jj bookmark set <feature-name> -r <rebased-id>
   jj new <feature-name>
   jj workspace forget auth/bd-xxx.4
   jj workspace forget auth/bd-xxx.5
   jj workspace forget auth/bd-xxx.6
```

## Example 5: Planning Session

```
User: Plan a new authentication system

1. Create project
   project-create(name="auth-system", type="project")

2. Start planning
   project-plan(projectId="auth-system", action="start")

3. [Conduct discovery interview with user]

4. Advance to synthesis
   project-plan(projectId="auth-system", action="advance")

5. [Synthesize findings, make decisions]

6. Advance to breakdown
   project-plan(projectId="auth-system", action="advance")

7. [Create issues with proper hierarchy]

8. Complete planning
   project-plan(projectId="auth-system", action="advance")
```
