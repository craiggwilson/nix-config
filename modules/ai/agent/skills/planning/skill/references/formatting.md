# Formatting Guidelines

All planning artifacts follow these markdown formatting standards:

## JIRA Tickets
Always as hyperlinks: `[TICKET-123](https://jira.mongodb.org/browse/TICKET-123)`

Never as plain text: ~~`TICKET-123`~~

## Dates
ISO 8601 format: `2026-03-21`

Never: ~~`03/21/2026`~~ or ~~`March 21, 2026`~~

## Status Indicators

| Status | Emoji | Usage |
|--------|-------|-------|
| Complete | ✅ | Task done, requirement met |
| Failed/Blocked | ❌ | Task failed, requirement not met |
| Warning/Attention | ⚠️ | Needs review, partial completion |
| In Progress | 🔄 | Currently being worked on |

## Code Blocks
Always specify language:

```markdown
~~~bash
jj status
~~~
```

Never: ~~```` ``` jj status ``` ````~~

## Links
Use descriptive text, not bare URLs:

✅ `[MongoDB Documentation](https://www.mongodb.com/docs/)`

❌ ~~`https://www.mongodb.com/docs/`~~

## Tables
- Always include header row with alignment
- Use `:---` (left), `:---:` (center), `---:` (right)

```markdown
| Column 1 | Column 2 | Column 3 |
|:---------|:--------:|---------:|
| Left     | Center   | Right    |
```

## Diagrams
Use Mermaid.js for diagrams:

~~~markdown
```mermaid
flowchart LR
    A[Client] --> B[API]
    B --> C[Service]
```
~~~
