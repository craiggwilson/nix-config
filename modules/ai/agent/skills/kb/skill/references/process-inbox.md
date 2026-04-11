# Processing the Inbox

Synthesizes raw captures from `inbox/inbox.md` into the zettelkasten.

## Workflow

### 1. Read the inbox

Read `inbox/inbox.md` in full. Identify each discrete item — a bullet, paragraph, pasted link, or question. Items may be loosely related or entirely unrelated.

### 2. Search before creating

For each item, search `notes/` for an existing note it belongs to:

- Item adds detail or an example to an existing concept → **enrich** that note
- Item corrects or updates something → **update** that note
- Item is a genuinely new concept with no existing home → **create** a new note

**Rule**: Never create a note just to mirror an inbox item verbatim. Synthesize and connect.

### 3. Enriching an existing note

- Add new content where it fits — new paragraph, bullet, or subsection
- Add wikilinks to related notes the item implies
- Update the `updated:` frontmatter field to today's date

### 4. Creating a new note

```yaml
---
created: YYYY-MM-DD
related: []
tags:
  - <area-tag>
type: note
updated: YYYY-MM-DD
---
```

- Slug: lowercase, hyphenated, title-based — e.g. `notes/vector-index-tradeoffs.md`
- Write the note as an atomic idea — one concept, explained fully
- Link to related notes with wikilinks
- Do not just restate the inbox item — synthesize, add context, connect

### 5. Update MOCs

For any new note created:

- Find the most relevant MOC(s) in `mocs/` by topic
- Add a link and one-line description to the appropriate section
- Only create a new MOC if 3+ related notes exist with no existing home

### 6. Clear processed items

- Remove each processed item from `inbox/inbox.md`
- Leave items that are genuinely unresolvable with a `<!-- TODO: ... -->` comment
- The file should be empty or near-empty when done

### 7. Commit

```bash
jj describe -m "kb: process inbox" && jj new
```

## Decision Guide

| Situation | Action |
|:----------|:-------|
| Item matches an existing note | Enrich the existing note |
| Item is a new angle on an existing concept | Add a section, link back |
| Item is a genuinely new concept | Create `notes/<slug>.md` |
| Item is a question or unresolved thought | Leave with `<!-- TODO: ... -->` comment |
| Item is a bare URL with no context | Leave — needs user intent |
| Item references a project (not a concept) | Add to the project or session file instead |

## Anti-Patterns

❌ Creating a new note for every inbox item regardless of existing coverage  
❌ Copying inbox text verbatim without synthesis  
❌ Skipping the search step  
❌ Leaving the inbox cluttered after processing  
❌ Adding a note to `mocs/` without checking if it already appears there  
