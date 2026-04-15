---
name: gws-docs-markdown
description: "Convert Markdown files into a Google Doc with tabs. One file per tab. Supports Obsidian-flavored markdown: frontmatter, wikilinks, callouts, GFM tables, task lists, fenced code blocks."
---

# gws-docs-markdown

> **PREREQUISITES:**
> - Read `../gws-shared/SKILL.md` for auth and global flags.
> - `gws` must be authenticated (`gws auth login`).
> - `md2gdoc` must be on `$PATH` (provided by this skill's Nix derivation).

Converts Markdown files into a Google Doc using the Docs REST API. Each file becomes one tab. Supports headings, paragraphs, bold/italic/inline-code, fenced code blocks, bullet and ordered lists, task lists, GFM tables, blockquotes, Obsidian callouts, wikilinks (rendered as plain text), thematic breaks, and hyperlinks.

Frontmatter (`---` YAML block) is stripped and not written to the document.

---

## Commands

### Create a new document

```bash
md2gdoc create [--title "Doc Title"] FILE [FILE ...]
```

- Creates a new Google Doc with one tab per file.
- Tab titles are derived from each file's first H1, falling back to the filename stem.
- `--title` sets the document title (defaults to the first file's first H1).
- Prints the **document ID** to stdout on success.
- Progress messages go to stderr.

**Examples:**

```bash
# Single file → one tab
md2gdoc create ~/Projects/kb/projects/doc-process/doc-process.md

# Multiple files → one tab per file
md2gdoc create \
  --title "Doc Process" \
  ~/Projects/kb/projects/doc-process/doc-process.md \
  ~/Projects/kb/projects/doc-process/process/01-proposal-process.md \
  ~/Projects/kb/projects/doc-process/process/02-technical-design-process.md

# Capture document ID
DOC_ID=$(md2gdoc create --title "My Doc" file.md)
echo "Created: https://docs.google.com/document/d/$DOC_ID/edit"
```

### Add a tab to an existing document

```bash
md2gdoc add-tab --document DOC_ID [--title "Tab Title"] FILE
```

- Appends a new tab to an existing document.
- `--title` overrides the tab title (defaults to first H1 or filename stem).
- Prints the **tab ID** to stdout on success.

**Examples:**

```bash
md2gdoc add-tab \
  --document 1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgVE2upms \
  ~/Projects/kb/projects/doc-process/process/03-scope-process.md

# With explicit tab title
md2gdoc add-tab \
  --document 1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgVE2upms \
  --title "Scope Process" \
  scope.md
```

---

## Markdown node coverage

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
| `| table |` | Inserted as a table + TSV text fallback |
| `> blockquote` | Left grey border, indented |
| `> [!NOTE]` (Obsidian callout) | Left blue border, indented |
| `[[target\|display]]` (wikilink) | Plain display text (link stripped) |
| `[text](url)` | Hyperlink |
| `---` (thematic break) | Paragraph with bottom border |
| YAML frontmatter | Stripped entirely |

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

To read back the document content:

```bash
gws docs documents get \
  --params '{"documentId": "DOC_ID", "includeTabsContent": true}' \
  --format json
```

---

## Limitations

- **Table cell content**: Table cells are inserted as a TSV plain-text block in the current version. The Docs API requires a second GET to discover cell object IDs before writing styled content into cells.
- **Images**: Not supported. Image nodes are silently skipped.
- **Nested lists**: Rendered flat (nesting not yet propagated to `createParagraphBullets` indent level).
- **Wikilinks**: Always rendered as plain display text. The target path is not converted to a Docs hyperlink.

---

## Troubleshooting

**`gws error: 403 Forbidden`** — The authenticated account lacks write access. Run `gws auth login` to re-authenticate.

**`gws error: 404 Not Found`** on `add-tab` — The document ID is wrong or the document was deleted.

**Tab content appears empty** — The file may contain only frontmatter with no body content. Check that the file has content after the closing `---`.

**`md2gdoc: command not found`** — The skill's Nix derivation is not active. Rebuild the Home Manager config: `home-manager switch`.

---

## See Also

- [gws-shared](../gws-shared/SKILL.md) — Global flags and auth
- [gws-docs](../gws-docs/SKILL.md) — Raw Google Docs API access
- [gws-drive](../gws-drive/SKILL.md) — Drive file management
