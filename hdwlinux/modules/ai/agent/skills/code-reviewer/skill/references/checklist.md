# Code Review Checklist

## Correctness
- [ ] Does the code do what it's supposed to do?
- [ ] Are edge cases handled?
- [ ] Are error conditions handled properly?
- [ ] Is the logic correct?

## Security
- [ ] Input validation present?
- [ ] SQL injection / XSS prevention?
- [ ] Authentication/authorization correct?
- [ ] Sensitive data handled properly?
- [ ] No secrets in code?

## Performance
- [ ] Efficient algorithms used?
- [ ] Database queries optimized?
- [ ] N+1 query problems?
- [ ] Unnecessary allocations?
- [ ] Appropriate caching?

## Maintainability
- [ ] Code is readable?
- [ ] Functions are focused?
- [ ] Naming is clear?
- [ ] No unnecessary complexity?
- [ ] DRY principle followed?

## Testing
- [ ] Tests cover the changes?
- [ ] Edge cases tested?
- [ ] Tests are readable?
- [ ] No flaky tests?

## Documentation
- [ ] Public APIs documented?
- [ ] Complex logic explained?
- [ ] README updated if needed?

## Style
- [ ] Follows project conventions?
- [ ] Consistent formatting?
- [ ] No commented-out code?
