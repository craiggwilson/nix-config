---
name: gws-docs-markdown
description: "Convert Markdown files into a Google Doc with tabs, extract tab content as markdown, and surgically update changed text. Supports Obsidian-flavored markdown: frontmatter, wikilinks, callouts, GFM tables, task lists, fenced code blocks."
---

# gws-docs-markdown

> **PREREQUISITES:**
> - Read `../gws-shared/SKILL.md` for auth and global flags.
> - `gws` must be authenticated (`gws auth login`).
> - `md2gdoc` path is baked into this skill at build time — no PATH setup required.

Converts Markdown files into a Google Doc using the Docs REST API. Each file becomes one tab. Supports headings, paragraphs, bold/italic/inline-code, fenced code blocks, bullet and ordered lists, task lists, GFM tables, blockquotes, Obsidian callouts, wikilinks (rendered as plain text), thematic breaks, and hyperlinks.

Frontmatter (`---` YAML block) is stripped and not written to the document.

---

## Commands

### Create a new document

```bash
$MD2GDOC create [--title "Doc Title"] FILE [FILE ...]
```

- Creates a new Google Doc with one tab per file.
- Tab titles are derived from each file's first H1, falling back to the filename stem.
- `--title` sets the document title (defaults to the first file's first H1).
- Prints the **document ID** to stdout on success.
- Progress messages go to stderr.

**Examples:**

```bash
# Single file → one tab
$MD2GDOC create ~/Projects/kb/projects/doc-process/doc-process.md

# Multiple files → one tab per file
$MD2GDOC create \
  --title "Doc Process" \
  ~/Projects/kb/projects/doc-process/doc-process.md \
  ~/Projects/kb/projects/doc-process/process/01-proposal-process.md \
  ~/Projects/kb/projects/doc-process/process/02-technical-design-process.md

# Capture document ID
DOC_ID=$($MD2GDOC create --title "My Doc" file.md)
echo "Created: https://docs.google.com/document/d/$DOC_ID/edit"
```

### Add a tab to an existing document

```bash
$MD2GDOC add-tab --document DOC_ID [--title "Tab Title"] FILE
```

- Appends a new tab to an existing document.
- `--title` overrides the tab title (defaults to first H1 or filename stem).
- Prints the **tab ID** to stdout on success.

**Examples:**

```bash
$MD2GDOC add-tab \
  --document 1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgVE2upms \
  ~/Projects/kb/projects/doc-process/process/03-scope-process.md

# With explicit tab title
$MD2GDOC add-tab \
  --document 1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgVE2upms \
  --title "Scope Process" \
  scope.md
```

---

### Extract markdown from an existing tab

```bash
$MD2GDOC extract-tab --document DOC_ID --tab TITLE_OR_ID
```

- Reads a live Google Doc tab and prints reconstructed **markdown** to stdout.
- Recovers inline styles: bold, italic, strikethrough, `` `code` ``, and hyperlinks.
- Headings render as `#` / `##` / etc. List items render as `- ` or `1. `. Tables render as GFM tables.
- Thematic breaks render as `---`. Task list checkboxes (☐/☑) render as `- [ ]` / `- [x]`.
- Internal tab links render as Obsidian wikilinks: `[[slug|display]]` where slug is derived by slugifying the tab title (e.g. `Proposal process` → `[[proposal-process|...]]`). These slugs will **not** match local filenames that have numeric prefixes — this is a known limitation.
- `--tab` accepts a tab title (case-insensitive) or an exact tab ID (e.g. `t.0`).
- Output is suitable for piping directly into `diff` against local markdown files.

**Stripping frontmatter for diff:**

Local markdown files have YAML frontmatter that must be stripped before diffing. Use `awk` — not `sed` — because `sed '/^---$/,/^---$/d'` incorrectly removes all `---` thematic breaks throughout the file:

```bash
strip_frontmatter() {
  awk 'NR==1 && /^---$/ { in_fm=1; next } in_fm && /^---$/ { in_fm=0; next } !in_fm' "$1"
}
```

**Examples:**

```bash
# Print the reconstructed markdown of a tab (by tab ID)
$MD2GDOC extract-tab \
  --document 11cZoPFZ--C2XYlQ3E0oFnA5pMww6Q1vdpufSFZNtxhE \
  --tab t.0

# Diff a live tab against a local file
strip_frontmatter() {
  awk 'NR==1 && /^---$/ { in_fm=1; next } in_fm && /^---$/ { in_fm=0; next } !in_fm' "$1"
}
diff \
  <($MD2GDOC extract-tab --document DOC_ID --tab t.0 2>/dev/null) \
  <(strip_frontmatter ~/Projects/kb/projects/doc-process/process/00-README.md)
```

---

### Diff a tab against a local markdown file

```bash
$MD2GDOC diff-tab --document DOC_ID --tab TITLE_OR_ID FILE
```

- Compares a live Google Doc tab against a local markdown file and reports all differences.
- **Structural changes** (reordered, added, removed, or renamed sections) are reported and require manual intervention in the Docs UI.
- **Text changes** (word/phrase/sentence edits within matched sections) are listed with live vs local preview and will be applied automatically by `update-tab`.
- Hunk merging: nearby character-level changes within a region are coalesced into semantically coherent replace operations (gap threshold: 8 chars).
- No writes are made to the document.

**Output format:**

```
Structural changes (require manual intervention):
  reordered  '02 Prfaq Process — PRFAQ'
             live position 9 → local position 6
  renamed    '[DRAFT] Atlas Data Service — Documentation Process'
          →  'Atlas Data Service — Documentation Process'

Text changes (8 region(s), 10 hunk(s)) — will be applied by update-tab:
  [1:52]
  - [DRAFT] Atlas Data Service — Documentation Process
  + Atlas Data Service — Documentation Process
  ...
```

**Examples:**

```bash
# Diff the README tab against its local file
$MD2GDOC diff-tab \
  --document 11cZoPFZ--C2XYlQ3E0oFnA5pMww6Q1vdpufSFZNtxhE \
  --tab t.0 \
  ~/Projects/kb/projects/doc-process/process/00-README.md
```

---

### Update changed text in an existing tab

```bash
$MD2GDOC update-tab --document DOC_ID --tab TITLE_OR_ID FILE
```

- Performs a **surgical, character-level update** of a live tab from a local markdown file.
- Uses heading-anchored structural alignment: headings (H1–H3) act as section boundaries. Regions within each section are aligned with `difflib.SequenceMatcher`. Only matched regions are diffed — unmatched blocks (structural additions/removals) are skipped safely.
- Only changed text is touched. Unchanged paragraphs, formatting, and comment anchors are preserved.
- Processes changes from the highest document index backward to prevent index drift.
- Uses `requiredRevisionId` for safety — fails if the document was edited concurrently.
- Progress and hunk counts are printed to stderr.

**Examples:**

```bash
# Update the README tab with a revised local file
$MD2GDOC update-tab \
  --document 11cZoPFZ--C2XYlQ3E0oFnA5pMww6Q1vdpufSFZNtxhE \
  --tab t.0 \
  ~/Projects/kb/projects/doc-process/process/00-README.md

# Update by tab title
$MD2GDOC update-tab --document DOC_ID --tab "Scope Process" scope-process.md
```

---

## Markdown node coverage

### Write path (local → Google Doc)

| Markdown construct | Google Docs rendering |
|:-------------------|:----------------------|
| `# H1` … `###### H6` | HEADING_1 … HEADING_6 paragraph style |
| Paragraph | NORMAL_TEXT paragraph style |
| `**bold**` | Bold text run |
| `*italic*` | Italic text run |
| `` `inline code` `` | Courier New, grey background |
| Fenced code block | Courier New, grey background, NORMAL_TEXT |
| `- item` / `* item` | Bullet list (disc/circle/square) |
| `1. item` | Numbered list (decimal/alpha/roman) |
| `- [ ] task` / `- [x] done` | ☐/☑ prefix; checked items struck through |
| `\| table \|` | Inserted as a GFM table |
| `> blockquote` | Left grey border, indented |
| `> [!NOTE]` (Obsidian callout) | Left blue border, indented |
| `[[target\|display]]` (wikilink) | Plain display text (link stripped) |
| `[text](url)` | Hyperlink |
| `---` (thematic break) | Paragraph with bottom border |
| YAML frontmatter | Stripped entirely |

### Extract path (Google Doc → markdown)

| Google Docs element | Markdown output |
|:--------------------|:----------------|
| HEADING_1 … HEADING_6 | `#` … `######` prefix |
| NORMAL_TEXT paragraph | Plain paragraph |
| Bold text run | `**bold**` |
| Italic text run | `*italic*` |
| Courier New font | `` `inline code` `` |
| Strikethrough | `~~text~~` |
| Hyperlink | `[text](url)` |
| Internal tab link | `[[slug\|display]]` (slug = slugified tab title) |
| Internal heading link | `[[#headingId\|display]]` |
| Bullet list item | `- item` (with `  ` indent per nesting level) |
| Numbered list item | `1. item` |
| ☐/☑ task prefix | `- [ ] item` / `- [x] item` |
| GFM table | `\| col \| col \|` with `:---` separator row; header row bold stripped |
| Paragraph with bottom border | `---` |
| Empty/structural paragraphs | Skipped |

---

## Sync workflow: diff then update

Use this workflow when local markdown files have changed and you need to push the minimal set of edits to an existing Google Doc while preserving reviewer comments.

### Step 1 — list tabs in the document

```bash
DOC_ID="11cZoPFZ--C2XYlQ3E0oFnA5pMww6Q1vdpufSFZNtxhE"

gws docs documents get \
  --params "{\"documentId\": \"$DOC_ID\"}" \
  --format json | jq '.tabs[].tabProperties | {tabId, title}'
```

This gives you the `tabId` → tab title mapping. Match tabs to local files manually or by title.

### Step 2 — diff each tab against its local file

```bash
PROCESS_DIR=~/Projects/kb/projects/doc-process/process

strip_frontmatter() {
  awk 'NR==1 && /^---$/ { in_fm=1; next } in_fm && /^---$/ { in_fm=0; next } !in_fm' "$1"
}

# Example: diff specific tab against its local counterpart
diff \
  <($MD2GDOC extract-tab --document "$DOC_ID" --tab t.0 2>/dev/null) \
  <(strip_frontmatter "$PROCESS_DIR/00-README.md")
```

**Tab slug mismatch**: Internal tab links in the extracted markdown use slugified tab titles (e.g. `[[proposal-process|...]]`), while local files use filename-based slugs (e.g. `[[03-proposal-process]]`). These will always appear as diff noise — ignore them when assessing whether real content has changed.

### Step 3 — apply updates for changed tabs

Only call `update-tab` for tabs where the diff shows real content changes (not just slug or blank-line noise):

```bash
$MD2GDOC update-tab --document "$DOC_ID" --tab t.0 \
  "$PROCESS_DIR/00-README.md"

$MD2GDOC update-tab --document "$DOC_ID" --tab t.59tsvz40mdos \
  "$PROCESS_DIR/04-scope-process.md"
```

### What `update-tab` handles

| Change type | Behaviour |
|:------------|:----------|
| Word or phrase changed | Delete old chars, insert new chars at the same position |
| Sentence rewritten | Character-level minimal edit within the paragraph |
| Table cell updated | Each cell paragraph diffed and updated independently |
| Paragraph added or removed | Skipped safely — structural changes require `add-tab` or manual edit |
| Formatting change only | Not detected — `update-tab` is text-only |

### Limitations of `update-tab`

- **Structural changes** (added or removed paragraphs, new table rows) are skipped — the heading-anchored alignment fails closed rather than corrupting content.
- **Formatting changes** (bold, italic, heading level) are not diffed — only text content.
- **Comment anchors** that overlap deleted text will be orphaned. Anchors on unchanged text are always preserved.
- **Concurrent edits**: the `requiredRevisionId` guard causes the command to fail if someone else edited the document between the GET and the batchUpdate. Re-run to retry.
- **Tab slug mismatch**: wikilinks in local files use filename slugs; extracted markdown uses tab-title slugs. `update-tab` diffs text only and handles this correctly — the link display text is what matters.

---

## Output and follow-up

After `create`, the document is immediately accessible:

```
https://docs.google.com/document/d/DOC_ID/edit
```

To share the document, use the Drive API via `gws`:

```bash
gws drive permissions create \
  --params '{"fileId": "DOC_ID", "sendNotificationEmail": false}' \
  --json '{"role": "reader", "type": "anyone"}'
```

---

## Limitations

- **Images**: Not supported. Image nodes are silently skipped.
- **Nested lists**: Rendered flat (nesting not yet propagated to `createParagraphBullets` indent level).
- **Wikilinks (write path)**: Always rendered as plain display text. The target path is not converted to a Docs hyperlink.
- **Wikilinks (extract path)**: Reconstructed as `[[slug|display]]` where slug is derived from the tab title. Will not match local filenames with numeric prefixes.
- **Ordered list detection**: Ordered list counter tracking requires `listProperties.nestingLevels[n].glyphType` to be present in the API response. If absent, falls back to `- ` (unordered). Content is preserved; only the marker style degrades.

---

## Troubleshooting

**`gws error: 403 Forbidden`** — The authenticated account lacks write access. Run `gws auth login` to re-authenticate.

**`gws error: 404 Not Found`** on `add-tab` — The document ID is wrong or the document was deleted.

**Tab content appears empty** — The file may contain only frontmatter with no body content. Check that the file has content after the closing `---`.

**`md2gdoc: command not found`** — The binary path is baked into this skill at build time and should always resolve. If this error appears, the skill derivation may not have been rebuilt after source changes. Run `home-manager switch` to rebuild.

**`extract-tab` shows no wikilinks** — Internal tab links only render as wikilinks when the document has tabs with titles. Documents created outside `md2gdoc` may use different link structures.

---

## See Also

- [gws-shared](../gws-shared/SKILL.md) — Global flags and auth
- [gws-docs](../gws-docs/SKILL.md) — Raw Google Docs API access
- [gws-drive](../gws-drive/SKILL.md) — Drive file management
