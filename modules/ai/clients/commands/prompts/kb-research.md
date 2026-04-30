# /kb-research

Conduct research on a topic and capture findings as atomic zettelkasten notes in the KB.

**Arguments**: `$ARGUMENTS` — topic and optional area tag (e.g. `warpstream multi-region`, `flink state management`). If omitted, ask what to research.

## What This Does

1. Loads the `kb` skill and its `references/research.md` and `references/zettelkasten.md` references
2. Searches existing `notes/` and relevant MOCs to understand what's already captured
3. Conducts research on `$ARGUMENTS` — web, codebase, documents as relevant
4. Creates one atomic note per concept in `notes/<slug>.md`
5. Links new notes to related existing notes
6. Updates relevant MOCs in `mocs/`
7. Commits: `jj describe -m "notes: <topic(s)>" && jj new`

Full research workflow and note format are in the `kb` skill's `references/research.md`.

## Usage

```
/kb-research warpstream architecture
/kb-research flink windowing patterns stream-processing
/kb-research                    # will ask what to research
```

## Skills to Load

Always load:
- `kb` — conventions, vault structure, load `references/research.md` and `references/zettelkasten.md`
- `obsidian-markdown` — for creating vault notes

Load if needed:
- `jujutsu` — for commit workflow detail
