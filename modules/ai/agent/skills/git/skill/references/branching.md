# Git Branching Strategies

## GitHub Flow

```
main ─────●─────●─────●─────●─────●
           \         /
feature     ●───●───●
```

- Single main branch
- Feature branches for changes
- PR for review
- Merge to main
- Deploy from main

## GitFlow

```
main    ─────●─────────────────●─────
              \               /
release        ●─────●───────●
                \   /
develop  ●───●───●───●───●───●───●
          \     /
feature    ●───●
```

- main: production releases
- develop: integration branch
- feature/*: new features
- release/*: release prep
- hotfix/*: production fixes

## Trunk-Based Development

```
main ─────●─────●─────●─────●─────●
           \   /
feature     ●─●  (short-lived)
```

- Single main branch
- Very short-lived feature branches
- Feature flags for incomplete work
- Continuous integration

## Branch Naming

```
feature/add-user-auth
bugfix/fix-login-error
hotfix/security-patch
release/v1.2.0
chore/update-dependencies
```

## Choosing a Strategy

| Strategy | Team Size | Release Frequency |
|----------|-----------|-------------------|
| GitHub Flow | Small | Continuous |
| GitFlow | Large | Scheduled |
| Trunk-Based | Any | Continuous |
