# /kb-add-to-inbox

Add a thought, note, or fragment to the KB inbox.

**Arguments**: `$ARGUMENTS` — the content to add. If omitted, ask what to capture.

## What This Does

1. Loads the `kb` skill
2. Appends `$ARGUMENTS` as a new item to `~/Projects/kb/inbox/inbox.md`
3. Confirms what was added — no further processing

This is a pure capture command. No synthesis, no note creation. Just drop it in.

## Format

Append as a bullet under the existing content:

```markdown
- <captured content>
```

If the content is multi-line or a paste, use a blockquote or paragraph instead of a bullet.

## Usage

```
/kb-add-to-inbox active-passive failover latency is higher than expected in practice
/kb-add-to-inbox link to read: https://example.com/paper
/kb-add-to-inbox                    # will ask what to capture
```

## Skills to Load

- `kb` — for vault path and inbox conventions
