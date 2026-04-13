# /kb-process-inbox

Process all items in the KB inbox — synthesize into notes, enrich existing notes, update MOCs, clear processed items.

**Arguments**: none.

## What This Does

1. Loads the `kb` skill and its `references/process-inbox.md` reference
2. Reads `~/Projects/kb/inbox/inbox.md` in full
3. For each item: searches `notes/` for an existing note to enrich, or creates a new one
4. Updates relevant MOCs in `mocs/`
5. Clears processed items from `inbox.md`
6. Commits: `jj describe -m "kb: process inbox" && jj new`

Full processing workflow is in the `kb` skill's `references/process-inbox.md`.

## Usage

```
/kb-process-inbox
```

## Skills to Load

Always load:
- `kb` — conventions, vault structure, load `references/process-inbox.md`
- `obsidian-markdown` — for creating and editing vault files

Load if needed:
- `jujutsu` — for commit workflow detail
