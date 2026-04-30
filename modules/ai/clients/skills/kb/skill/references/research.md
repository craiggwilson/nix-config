# Research

How to conduct research and capture findings as zettelkasten notes.

## Core Principle

Research produces **atomic notes in `notes/`**, not monolithic documents. A research session may create multiple small notes rather than one large one. Each note covers one concept, linked densely to others.

## Before Researching

Always check what already exists:

1. Search `notes/` for existing notes on the topic and related concepts
2. Check relevant MOCs in `mocs/` for the area
3. Identify what's missing or shallow — research fills gaps, doesn't duplicate

## Research Workflow

1. **Define the question** — what specifically do you need to understand?
2. **Search existing notes** — don't research what you already know
3. **Conduct research** — web, codebase, documents, whatever is relevant
4. **Synthesize into notes** — one concept per note, explain why and how
5. **Link everything** — to existing notes, from relevant MOCs
6. **Commit**: `jj describe -m "notes: <topic(s)>" && jj new`

## Creating a Research Note

Notes live at `notes/<slug>.md`. Use a slug that names the concept, not the research session.

```yaml
---
created: YYYY-MM-DD
related:
  - "[[notes/related-concept]]"
tags:
  - <area-tag>         # e.g. atlas, multi-region, flink
type: note
updated: YYYY-MM-DD
---
```

Sections (adapt as needed):
```markdown
# <Concept Name>

## Overview
One paragraph: what this is and why it matters.

## Key Findings
The substance — what you learned. Explain why and how, not just what.

## Architecture / Design
If applicable — structure, components, tradeoffs.

## Open Questions
What remains unclear or needs follow-up.

## Related
Dense wikilinks to related notes and MOCs.
```

## Deciding How Many Notes to Create

| Situation | Action |
|:----------|:-------|
| Single coherent concept | One note |
| Two related but distinct concepts | Two notes, linked to each other |
| A concept + its implementation | Two notes (concept in `notes/`, impl detail in `codebases/` if codebase-specific) |
| A survey of a large area | One note per sub-concept + a MOC if 3+ notes result |

## Updating MOCs

After creating notes:
- Find the relevant MOC(s) in `mocs/`
- Add the note with a one-line description
- If no MOC fits and you've created 3+ related notes, create a new MOC

## Atlas / Work Research

For Atlas-specific research, use area tags: `atlas`, `control-plane`, `data-plane`, `stream-processing`, `multi-region`. These correspond to existing MOCs:
- `[[mocs/atlas-control-plane]]`
- `[[mocs/atlas-data-plane]]`
- `[[mocs/atlas-stream-processing]]`
- `[[mocs/multi-region-patterns]]`
- `[[mocs/availability-engineering]]`

## Anti-Patterns

❌ Creating one large "research dump" note instead of atomic notes  
❌ Naming notes after sessions (`2026-04-13-warpstream-research.md`) instead of concepts  
❌ Researching without first checking what already exists  
❌ Writing what something *is* without explaining *why* and *how*  
❌ Leaving notes unlinked from any MOC  
