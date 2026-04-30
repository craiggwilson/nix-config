# Zettelkasten

How this vault implements the zettelkasten method.

## Core Principle

Organization emerges from **links between atomic notes**, not from folder hierarchy. A note's value comes from what it connects to, not where it lives.

## This Vault's Implementation

| Concept | Implementation |
|:--------|:---------------|
| Atomic note | `notes/<slug>.md` — one idea, flat directory, title-based filenames |
| Link | Obsidian wikilink `[[notes/topic]]` — the primary navigation mechanism |
| Map of Content | `mocs/<area>.md` — curated entry points, not exhaustive indexes |
| Capture buffer | `inbox/inbox.md` — raw input before synthesis |

## Note Quality

A good zettelkasten note:
- Covers **one idea** — if you need "and" in the title, split it
- Explains **why and how**, not just what — add your own synthesis
- Links **densely** — every concept that has a note should be linked
- Is **permanent** — written to be understood without context months later
- Has a **title that is a claim or concept**, not a container label

Bad titles (container labels): `Multi-Region Notes`, `Atlas Research`  
Good titles (concepts): `active-passive-design`, `healing-scaling-target-architecture`

## MOCs vs Notes

| MOC | Note |
|:----|:-----|
| Entry point into a topic cluster | Atomic knowledge unit |
| Links to notes and other MOCs | Links to related notes |
| Adds context and structure | Explains a single idea |
| Updated when notes are added | Updated when the idea evolves |
| Lives in `mocs/` | Lives in `notes/` |

Only create a MOC when 3+ related notes exist. Don't pre-create MOCs speculatively.

## What Is NOT Zettelkasten

These live outside `notes/` and `mocs/` for good reason — they serve different purposes:

- **Projects** (`projects/`) — operational containers: progress, sessions, decisions
- **People** (`people/`) — structured records, not ideas
- **Reference** (`reference/`) — lookup facts, not synthesis
- **Codebases** (`codebases/`) — repo orientation, not portable concepts
- **Inbox** (`inbox/`) — temporary capture, not permanent notes

## Linking Practice

- Link on **first mention** of any concept that has a note
- Prefer `[[notes/slug|display text]]` when the slug is not human-readable
- Add a `related:` frontmatter list for notes that are closely related but not mentioned in the body
- When creating a note, always ask: what existing notes does this connect to?

## Processing Flow

```
inbox/inbox.md  →  search notes/  →  enrich existing  OR  create new note/
                                                               ↓
                                                        update mocs/
```

Never mirror inbox items verbatim. Always synthesize.
