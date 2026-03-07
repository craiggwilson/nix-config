# Constructive Feedback Patterns

## Comment Prefixes

| Prefix | Meaning | Blocking? |
|--------|---------|-----------|
| `nit:` | Minor style issue | No |
| `suggestion:` | Alternative approach | No |
| `question:` | Seeking clarification | No |
| `issue:` | Must be addressed | Yes |
| `praise:` | Positive feedback | No |

## Good vs Bad Feedback

### Be Specific

**Bad:**
> This is confusing.

**Good:**
> nit: Consider renaming `data` to `userProfiles` to clarify what this list contains.

### Explain Why

**Bad:**
> Use a map here.

**Good:**
> suggestion: Consider using a map for O(1) lookup instead of iterating through the list. This would improve performance when the list grows large.

### Offer Solutions

**Bad:**
> This won't scale.

**Good:**
> issue: This approach loads all records into memory. Consider using pagination or streaming to handle large datasets. Example: `db.query().batch(100).forEach(...)`.

## Tone Guidelines

- Use "we" instead of "you"
- Ask questions instead of making demands
- Acknowledge good work
- Be timely
- Assume good intent

## When to Approve

- All blocking issues resolved
- Code is "good enough"
- Don't block on preferences
- Trust the author
