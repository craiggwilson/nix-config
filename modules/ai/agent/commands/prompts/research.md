# Research Command

Conduct research and capture findings in the KB.

**Arguments**: `$ARGUMENTS` — topic and optional area (e.g. `"warpstream multi-region" atlas`, `"active-passive patterns" software-engineering`).

## What This Does

1. Loads the `kb` skill for KB conventions
2. Checks `~/Projects/kb/research/` for existing notes on the topic
3. Conducts research (web, codebase, documents — whatever is relevant)
4. Synthesizes findings into a research note at `~/Projects/kb/research/<area>/<topic>.md`
5. Links the note from the relevant project or research index if appropriate
6. Commits: `jj describe -m "research: <topic>" && jj new` (run from `~/Projects/kb`)

## Usage

```
/research "warpstream multi-region architecture" atlas
/research "active-passive failover patterns" software-engineering
/research "mongodb change streams" atlas
```

## Research Note Structure

Research notes use `type: research` frontmatter and explain *why* and *how*, not just *what*:

```markdown
---
area: <area>
created: YYYY-MM-DD
related: []
tags:
  - research
type: research
updated: YYYY-MM-DD
---

# <Topic>

## Overview
## Key Findings
## Architecture / Design
## Open Questions
## Related
```

## Skills to Load

Always load at start:
- `kb` — KB conventions and file types
- `obsidian-markdown` — for creating research notes

Load based on topic:
- `obsidian-cli` — to search existing vault notes before starting
- Domain skills as relevant (e.g. `mongodb-specialist`, `distributed-systems-architect`)

**Now load the `kb` skill and check for existing research before beginning.**
