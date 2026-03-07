# Git Workflows

## Pull Request Workflow

```bash
# 1. Create branch
git checkout -b feature/add-auth

# 2. Make changes and commit
git add -p
git commit -m "feat: add authentication"

# 3. Push branch
git push -u origin feature/add-auth

# 4. Create PR (via GitHub/GitLab)

# 5. Address review feedback
git add -p
git commit -m "fix: address review comments"
git push

# 6. Squash and merge (via UI)
# or locally:
git checkout main
git merge --squash feature/add-auth
git commit -m "feat: add authentication (#123)"
git push
```

## Keeping Branch Updated

```bash
# Option 1: Rebase (cleaner history)
git fetch origin
git rebase origin/main

# Option 2: Merge (preserves history)
git fetch origin
git merge origin/main
```

## Code Review Best Practices

### As Author
- Keep PRs small and focused
- Write clear descriptions
- Self-review before requesting
- Respond to feedback promptly

### As Reviewer
- Review within 24 hours
- Be constructive
- Approve when "good enough"
- Use prefixes (nit:, suggestion:)

## Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Examples

```
feat(auth): add OAuth2 login

Implement OAuth2 authentication flow with Google provider.
Includes token refresh and session management.

Closes #123
```

```
fix(api): handle null response from external service

The external API sometimes returns null instead of empty array.
Added null check to prevent TypeError.

Fixes #456
```
