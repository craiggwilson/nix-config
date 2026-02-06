---
name: google-docs
description: Manage Google Docs with full document operations. Includes Markdown support for creating formatted documents with headings, bold, italic, lists, tables, and checkboxes.
category: productivity
version: 2.0.0
key_capabilities: create-from-markdown, insert-from-markdown, tables, formatted text, read, structure, insert, append, replace, format
when_to_use: Document content operations, formatted document creation from Markdown, tables, reading documents, editing documents
allowed-tools: Bash(ruby:*)
---

# Google Docs Management Skill

## Purpose

Manage Google Docs documents with comprehensive operations:

- Read document content and structure
- Insert and append text
- Find and replace text
- Basic text formatting (bold, italic, underline)
- Insert page breaks
- Create new documents
- Delete content ranges
- Get document structure (headings)
- Insert inline images from URLs
- Insert tables

**📚 Additional Resources**:
- See `references/docs_operations.md` for complete operation reference
- See `references/troubleshooting.md` for error handling and debugging
- See `references/formatting_guide.md` for text formatting options

**Note**: For Google Drive file operations (upload, download, share, search), use the `google-drive-skill` instead.

## When to Use This Skill

Use this skill when:
- User requests to read or view a Google Doc
- User wants to create a new document
- User wants to edit document content
- User requests text formatting or modifications
- User asks about document structure or headings
- User wants to find and replace text
- User wants to insert tables or images into a document
- Keywords: "Google Doc", "document", "edit doc", "format text", "insert text"

**📋 Discovering Your Documents**:
To list or search for documents, use the `google-drive-skill`:
```bash
~/.ai/agent/skills/google-drive-skill/bin/ruby ~/.ai/agent/skills/google-drive-skill/scripts/drive_manager.rb search \
  --query "mimeType='application/vnd.google-apps.document'"
```

## Core Workflows

### 1. Read Document

**Read full document content**:
```bash
~/.ai/agent/skills/google-docs-skill/bin/ruby ~/.ai/agent/skills/google-docs-skill/scripts/docs_manager.rb read <document_id>
```

**Get document structure (headings)**:
```bash
~/.ai/agent/skills/google-docs-skill/bin/ruby ~/.ai/agent/skills/google-docs-skill/scripts/docs_manager.rb structure <document_id>
```

**Output**:
- Full text content with paragraphs
- Document metadata (title, revision ID)
- Heading structure with levels and positions

### 2. Create Documents

> ⚠️ **TIP FOR MARKDOWN FILES**: When converting an existing markdown file to a Google Doc, use the `google-drive-skill` with `--convert-to google-docs` for more reliable formatting. This skill's `create-from-markdown` is best for programmatically generating content.

**Create new document (plain text)**:
```bash
echo '{
  "title": "Project Proposal",
  "content": "Initial plain text content..."
}' | ~/.ai/agent/skills/google-docs-skill/bin/ruby ~/.ai/agent/skills/google-docs-skill/scripts/docs_manager.rb create
```

**Create document from Markdown**:
```bash
echo '{
  "title": "Project Proposal",
  "markdown": "# Project Proposal\n\n## Overview\n\nThis is **bold** and *italic* text.\n\n- Bullet point 1\n- Bullet point 2\n\n| Column 1 | Column 2 |\n|----------|----------|\n| Data 1   | Data 2   |"
}' | ~/.ai/agent/skills/google-docs-skill/bin/ruby ~/.ai/agent/skills/google-docs-skill/scripts/docs_manager.rb create-from-markdown
```

**Supported Markdown Features** (for `create-from-markdown`):
- Headings: `#`, `##`, `###` → Google Docs HEADING_1, HEADING_2, HEADING_3
- Bold: `**text**`
- Italic: `*text*`
- Code: `` `text` `` → Courier New font
- Bullet lists: `- item` or `* item`
- Numbered lists: `1. item`
- Checkboxes: `- [ ] unchecked` and `- [x] checked`
- Horizontal rules: `---`
- Tables: `| col1 | col2 |` (with separator row)

**Document ID**:
- Returned in response for future operations
- Use with `google-drive-skill` for sharing/organizing

### 3. Insert and Append Text

**Insert plain text at specific position**:
```bash
echo '{
  "document_id": "abc123",
  "text": "This text will be inserted at the beginning.\n\n",
  "index": 1
}' | ~/.ai/agent/skills/google-docs-skill/bin/ruby ~/.ai/agent/skills/google-docs-skill/scripts/docs_manager.rb insert
```

**Insert formatted Markdown (RECOMMENDED)**:
```bash
echo '{
  "document_id": "abc123",
  "markdown": "## New Section\n\nThis has **bold** and *italic* formatting.\n\n- Item 1\n- Item 2",
  "index": 1
}' | ~/.ai/agent/skills/google-docs-skill/bin/ruby ~/.ai/agent/skills/google-docs-skill/scripts/docs_manager.rb insert-from-markdown
```

**Append text to end of document**:
```bash
echo '{
  "document_id": "abc123",
  "text": "\n\nThis text will be appended to the end."
}' | ~/.ai/agent/skills/google-docs-skill/bin/ruby ~/.ai/agent/skills/google-docs-skill/scripts/docs_manager.rb append
```

**Index Positions**:
- Document starts at index 1
- Use `read` command to see current content
- Use `structure` command to find heading positions
- End of document: use `append` instead of calculating index
- For `insert-from-markdown`, omit index to append at end

### 4. Find and Replace

**Simple find and replace**:
```bash
echo '{
  "document_id": "abc123",
  "find": "old text",
  "replace": "new text"
}' | ~/.ai/agent/skills/google-docs-skill/bin/ruby ~/.ai/agent/skills/google-docs-skill/scripts/docs_manager.rb replace
```

**Case-sensitive replacement**:
```bash
echo '{
  "document_id": "abc123",
  "find": "IMPORTANT",
  "replace": "CRITICAL",
  "match_case": true
}' | ~/.ai/agent/skills/google-docs-skill/bin/ruby ~/.ai/agent/skills/google-docs-skill/scripts/docs_manager.rb replace
```

**Replace all occurrences**:
- Automatically replaces all matches
- Returns count of replacements made
- Use for bulk text updates

### 5. Text Formatting

**Format text range (bold)**:
```bash
echo '{
  "document_id": "abc123",
  "start_index": 1,
  "end_index": 20,
  "bold": true
}' | ~/.ai/agent/skills/google-docs-skill/bin/ruby ~/.ai/agent/skills/google-docs-skill/scripts/docs_manager.rb format
```

**Multiple formatting options**:
```bash
echo '{
  "document_id": "abc123",
  "start_index": 50,
  "end_index": 100,
  "bold": true,
  "italic": true,
  "underline": true
}' | ~/.ai/agent/skills/google-docs-skill/bin/ruby ~/.ai/agent/skills/google-docs-skill/scripts/docs_manager.rb format
```

**Formatting Options**:
- `bold`: true/false
- `italic`: true/false
- `underline`: true/false
- All options are independent and can be combined

### 6. Page Breaks

**Insert page break**:
```bash
echo '{
  "document_id": "abc123",
  "index": 500
}' | ~/.ai/agent/skills/google-docs-skill/bin/ruby ~/.ai/agent/skills/google-docs-skill/scripts/docs_manager.rb page-break
```

**Use Cases**:
- Separate document sections
- Start new content on fresh page
- Organize long documents

### 7. Delete Content

**Delete text range**:
```bash
echo '{
  "document_id": "abc123",
  "start_index": 100,
  "end_index": 200
}' | ~/.ai/agent/skills/google-docs-skill/bin/ruby ~/.ai/agent/skills/google-docs-skill/scripts/docs_manager.rb delete
```

**Clear entire document**:
```bash
# Read document first to get end index
~/.ai/agent/skills/google-docs-skill/bin/ruby ~/.ai/agent/skills/google-docs-skill/scripts/docs_manager.rb read abc123

# Then delete all content (start at 1, end at last index - 1)
echo '{
  "document_id": "abc123",
  "start_index": 1,
  "end_index": 500
}' | ~/.ai/agent/skills/google-docs-skill/bin/ruby ~/.ai/agent/skills/google-docs-skill/scripts/docs_manager.rb delete
```

### 8. Insert Images

**Insert image from URL**:
```bash
echo '{
  "document_id": "abc123",
  "image_url": "https://storage.googleapis.com/bucket/image.png"
}' | ~/.ai/agent/skills/google-docs-skill/bin/ruby ~/.ai/agent/skills/google-docs-skill/scripts/docs_manager.rb insert-image
```

**Insert image with specific size**:
```bash
echo '{
  "document_id": "abc123",
  "image_url": "https://storage.googleapis.com/bucket/image.png",
  "width": 400,
  "height": 300
}' | ~/.ai/agent/skills/google-docs-skill/bin/ruby ~/.ai/agent/skills/google-docs-skill/scripts/docs_manager.rb insert-image
```

**Insert image at specific position**:
```bash
echo '{
  "document_id": "abc123",
  "image_url": "https://storage.googleapis.com/bucket/image.png",
  "index": 100
}' | ~/.ai/agent/skills/google-docs-skill/bin/ruby ~/.ai/agent/skills/google-docs-skill/scripts/docs_manager.rb insert-image
```

**Image URL Requirements**:
- URL must be publicly accessible (Google Docs fetches the image)
- Supported formats: PNG, JPEG, GIF
- SVG is NOT supported - convert to PNG first
- For private images, upload to GCS and make public, or use signed URLs

**Sizing Tips**:
- To fit page width with default margins: use `width: 468` (points)
- Specifying only width will auto-scale height proportionally
- Specifying only height will auto-scale width proportionally
- 1 inch = 72 points

### 9. Insert Tables

**Insert empty table**:
```bash
echo '{
  "document_id": "abc123",
  "rows": 3,
  "cols": 4
}' | ~/.ai/agent/skills/google-docs-skill/bin/ruby ~/.ai/agent/skills/google-docs-skill/scripts/docs_manager.rb insert-table
```

**Insert table with data**:
```bash
echo '{
  "document_id": "abc123",
  "rows": 3,
  "cols": 2,
  "data": [
    ["Header 1", "Header 2"],
    ["Row 1 Col 1", "Row 1 Col 2"],
    ["Row 2 Col 1", "Row 2 Col 2"]
  ]
}' | ~/.ai/agent/skills/google-docs-skill/bin/ruby ~/.ai/agent/skills/google-docs-skill/scripts/docs_manager.rb insert-table
```

**Insert table at specific position**:
```bash
echo '{
  "document_id": "abc123",
  "rows": 2,
  "cols": 3,
  "index": 100,
  "data": [["A", "B", "C"], ["1", "2", "3"]]
}' | ~/.ai/agent/skills/google-docs-skill/bin/ruby ~/.ai/agent/skills/google-docs-skill/scripts/docs_manager.rb insert-table
```

**Note**: Tables can also be created via Markdown in `create-from-markdown`:
```markdown
| Column 1 | Column 2 | Column 3 |
|----------|----------|----------|
| Data 1   | Data 2   | Data 3   |
```

## Natural Language Examples

### User Says: "Read the content of this Google Doc: abc123"
```bash
~/.ai/agent/skills/google-docs-skill/bin/ruby ~/.ai/agent/skills/google-docs-skill/scripts/docs_manager.rb read abc123
```

### User Says: "Create a new document called 'Meeting Notes' with the text 'Attendees: John, Sarah'"
```bash
echo '{
  "title": "Meeting Notes",
  "content": "Attendees: John, Sarah"
}' | ~/.ai/agent/skills/google-docs-skill/bin/ruby ~/.ai/agent/skills/google-docs-skill/scripts/docs_manager.rb create
```

### User Says: "Add 'Next Steps' section to the end of document abc123"
```bash
echo '{
  "document_id": "abc123",
  "text": "\n\n## Next Steps\n\n- Review proposals\n- Schedule follow-up"
}' | ~/.ai/agent/skills/google-docs-skill/bin/ruby ~/.ai/agent/skills/google-docs-skill/scripts/docs_manager.rb append
```

### User Says: "Replace all instances of 'Q3' with 'Q4' in document abc123"
```bash
echo '{
  "document_id": "abc123",
  "find": "Q3",
  "replace": "Q4"
}' | ~/.ai/agent/skills/google-docs-skill/bin/ruby ~/.ai/agent/skills/google-docs-skill/scripts/docs_manager.rb replace
```

### User Says: "Make the first 50 characters of document abc123 bold"
```bash
echo '{
  "document_id": "abc123",
  "start_index": 1,
  "end_index": 50,
  "bold": true
}' | ~/.ai/agent/skills/google-docs-skill/bin/ruby ~/.ai/agent/skills/google-docs-skill/scripts/docs_manager.rb format
```

## Understanding Document Index Positions

**Index System**:
- Documents use zero-based indexing with offset
- Index 1 = start of document (after title)
- Each character (including spaces and newlines) has an index
- Use `read` to see current content and plan insertions
- Use `structure` to find heading positions

**Finding Positions**:
1. Read document to see content
2. Count characters to desired position
3. Or use heading structure for section starts
4. Remember: index 1 = very beginning

**Example**:
```
"Hello World\n\nSecond paragraph"

Index 1: "H" (start)
Index 11: "\n" (first newline)
Index 13: "S" (start of "Second")
Index 29: end of document
```

## Integration with Google Drive

For file management operations (upload, download, share, search, organize), use the `google-drive-skill`. The two skills work together:

- **This skill (google-docs)**: Create and edit document content
- **google-drive-skill**: Upload, download, share, organize files

### Example Workflow

```bash
# Step 1: Create document (returns document_id)
echo '{"title":"Report"}' | ~/.ai/agent/skills/google-docs-skill/bin/ruby ~/.ai/agent/skills/google-docs-skill/scripts/docs_manager.rb create
# Returns: {"document_id": "abc123"}

# Step 2: Add content
echo '{"document_id":"abc123","text":"# Report\n\nContent here"}' | ~/.ai/agent/skills/google-docs-skill/bin/ruby ~/.ai/agent/skills/google-docs-skill/scripts/docs_manager.rb insert

# Step 3: Use google-drive-skill to organize and share
# See google-drive-skill for move, share, download operations
```

### Export Document to PDF

Use the `google-drive-skill` download command with `--export-as pdf`:
```bash
~/.ai/agent/skills/google-drive-skill/bin/ruby ~/.ai/agent/skills/google-drive-skill/scripts/drive_manager.rb download --file-id abc123 --output ./report.pdf --export-as pdf
```

### Excalidraw Diagrams Workflow

For creating and managing Excalidraw diagrams, see the `excalidraw-diagrams` skill which integrates with `google-drive-skill` for:
- Uploading .excalidraw files to Drive
- Getting shareable edit URLs for Excalidraw web
- Round-trip editing between AI and human

## Authentication Setup

**Shared with Other Google Skills**:
- Uses same OAuth credentials and token
- Located at: `~/.ai/agent/.google/client_secret.json` and `~/.ai/agent/.google/token.json`
- Shares token with email, calendar, contacts, drive, and sheets skills
- Requires Documents, Drive, Sheets, Calendar, Contacts, and Gmail API scopes

**First Time Setup**:
1. Run any docs operation
2. Script will prompt for authorization URL
3. Visit URL and authorize all Google services
4. Enter authorization code when prompted
5. Token stored for all Google skills

**Re-authorization**:
- Token automatically refreshes when expired
- If refresh fails, re-run authorization flow
- All Google skills will work after single re-auth

## Bundled Resources

### Scripts

**`~/.ai/agent/skills/google-docs-skill/bin/ruby ~/.ai/agent/skills/google-docs-skill/scripts/docs_manager.rb`**
- Comprehensive Google Docs API wrapper
- All document operations: read, create, insert, append, replace, format, delete
- Document structure analysis (headings)
- Automatic token refresh
- Shared OAuth with other Google skills

**Operations**:
- `read`: View document content
- `structure`: Get document headings and structure
- `insert`: Insert plain text at specific index
- `insert-from-markdown`: Insert formatted markdown content
- `append`: Append text to end
- `replace`: Find and replace text
- `format`: Apply text formatting (bold, italic, underline)
- `page-break`: Insert page break
- `create`: Create new document (plain text)
- `create-from-markdown`: Create document with formatted markdown
- `delete`: Delete content range
- `insert-image`: Insert inline image from URL
- `insert-table`: Insert table with optional data

**Output Format**:
- JSON with `status: 'success'` or `status: 'error'`
- Document operations return document_id and revision_id
- See script help: `~/.ai/agent/skills/google-docs-skill/bin/ruby ~/.ai/agent/skills/google-docs-skill/scripts/docs_manager.rb --help`

### References

**`references/docs_operations.md`**
- Complete operation reference
- Parameter documentation
- Index position examples
- Common workflows

**`references/formatting_guide.md`**
- Text formatting options
- Style guidelines
- Document structure best practices
- Heading hierarchy

### Examples

**`examples/sample_operations.md`**
- Common document operations
- Workflow examples
- Index calculation examples

## Error Handling

**Authentication Error**:
```json
{
  "status": "error",
  "code": "AUTH_ERROR",
  "message": "Token refresh failed: ..."
}
```
**Action**: Guide user through re-authorization

**Document Not Found**:
```json
{
  "status": "error",
  "code": "API_ERROR",
  "message": "Document not found"
}
```
**Action**: Verify document ID, check permissions

**Invalid Index**:
```json
{
  "status": "error",
  "code": "API_ERROR",
  "message": "Invalid index position"
}
```
**Action**: Read document to verify current length, adjust index

**API Error**:
```json
{
  "status": "error",
  "code": "API_ERROR",
  "message": "Failed to update document: ..."
}
```
**Action**: Display error to user, suggest troubleshooting steps

## Best Practices

### Document Creation
1. Always provide meaningful title
2. Add initial content when creating for better context
3. Save returned document_id for future operations
4. Use `google-drive-skill` to organize and share

### Text Insertion
1. Read document first to understand current structure
2. Use `structure` command to find heading positions
3. Index 1 = start of document
4. Use `append` for adding to end (simpler than calculating index)
5. Include newlines (\n) for proper formatting

### Find and Replace
1. Test pattern match first on small section
2. Use case-sensitive matching for precise replacements
3. Returns count of replacements made
4. Cannot undo - consider reading document first for backup

### Text Formatting
1. Calculate index positions carefully
2. Read document to verify text location
3. Can combine bold, italic, underline
4. Formatting applies to exact character range

### Document Structure
1. Use heading structure for navigation
2. Insert page breaks between major sections
3. Maintain consistent formatting throughout
4. Use `structure` command to validate hierarchy

## Quick Reference

**Read document**:
```bash
~/.ai/agent/skills/google-docs-skill/bin/ruby ~/.ai/agent/skills/google-docs-skill/scripts/docs_manager.rb read <document_id>
```

**Create document from Markdown (RECOMMENDED)**:
```bash
echo '{"title":"My Doc","markdown":"# Heading\n\nParagraph with **bold**."}' | ~/.ai/agent/skills/google-docs-skill/bin/ruby ~/.ai/agent/skills/google-docs-skill/scripts/docs_manager.rb create-from-markdown
```

**Create document (plain text)**:
```bash
echo '{"title":"My Doc","content":"Initial text"}' | ~/.ai/agent/skills/google-docs-skill/bin/ruby ~/.ai/agent/skills/google-docs-skill/scripts/docs_manager.rb create
```

**Insert formatted Markdown**:
```bash
echo '{"document_id":"abc123","markdown":"## Section\n\n- Item 1\n- Item 2"}' | ~/.ai/agent/skills/google-docs-skill/bin/ruby ~/.ai/agent/skills/google-docs-skill/scripts/docs_manager.rb insert-from-markdown
```

**Insert plain text at beginning**:
```bash
echo '{"document_id":"abc123","text":"New text","index":1}' | ~/.ai/agent/skills/google-docs-skill/bin/ruby ~/.ai/agent/skills/google-docs-skill/scripts/docs_manager.rb insert
```

**Append to end**:
```bash
echo '{"document_id":"abc123","text":"Appended text"}' | ~/.ai/agent/skills/google-docs-skill/bin/ruby ~/.ai/agent/skills/google-docs-skill/scripts/docs_manager.rb append
```

**Find and replace**:
```bash
echo '{"document_id":"abc123","find":"old","replace":"new"}' | ~/.ai/agent/skills/google-docs-skill/bin/ruby ~/.ai/agent/skills/google-docs-skill/scripts/docs_manager.rb replace
```

**Format text**:
```bash
echo '{"document_id":"abc123","start_index":1,"end_index":50,"bold":true}' | ~/.ai/agent/skills/google-docs-skill/bin/ruby ~/.ai/agent/skills/google-docs-skill/scripts/docs_manager.rb format
```

**Get document structure**:
```bash
~/.ai/agent/skills/google-docs-skill/bin/ruby ~/.ai/agent/skills/google-docs-skill/scripts/docs_manager.rb structure <document_id>
```

**Insert table**:
```bash
echo '{"document_id":"abc123","rows":3,"cols":2,"data":[["A","B"],["1","2"],["3","4"]]}' | ~/.ai/agent/skills/google-docs-skill/bin/ruby ~/.ai/agent/skills/google-docs-skill/scripts/docs_manager.rb insert-table
```

**Insert image from URL**:
```bash
echo '{"document_id":"abc123","image_url":"https://example.com/image.png"}' | ~/.ai/agent/skills/google-docs-skill/bin/ruby ~/.ai/agent/skills/google-docs-skill/scripts/docs_manager.rb insert-image
```

## Example Workflow: Creating and Editing a Report

1. **Create document with formatted content**:
   ```bash
   echo '{
     "title": "Q4 Report",
     "markdown": "# Q4 Report\n\n## Executive Summary\n\nRevenue increased **25%** over Q3 targets.\n\n## Key Metrics\n\n| Metric | Q3 | Q4 |\n|--------|-----|-----|\n| Revenue | $1M | $1.25M |\n| Users | 10K | 15K |\n\n## Next Steps\n\n- [ ] Finalize budget\n- [ ] Schedule review meeting\n- [x] Complete analysis"
   }' | ~/.ai/agent/skills/google-docs-skill/bin/ruby ~/.ai/agent/skills/google-docs-skill/scripts/docs_manager.rb create-from-markdown
   # Returns: {"document_id": "abc123"}
   ```

2. **Add more content later**:
   ```bash
   echo '{
     "document_id": "abc123",
     "markdown": "\n\n## Appendix\n\nAdditional *details* and **notes** here."
   }' | ~/.ai/agent/skills/google-docs-skill/bin/ruby ~/.ai/agent/skills/google-docs-skill/scripts/docs_manager.rb insert-from-markdown
   ```

3. **Replace text if needed**:
   ```bash
   echo '{
     "document_id": "abc123",
     "find": "Q3",
     "replace": "Q4"
   }' | ~/.ai/agent/skills/google-docs-skill/bin/ruby ~/.ai/agent/skills/google-docs-skill/scripts/docs_manager.rb replace
   ```

4. **Share with team** (use `google-drive-skill`):
   ```bash
   ~/.ai/agent/skills/google-drive-skill/bin/ruby ~/.ai/agent/skills/google-drive-skill/scripts/drive_manager.rb share --file-id abc123 --email team@company.com --role writer
   ```

## Version History

- **2.0.0** (2026-02-06) - Split Google Drive operations into separate `google-drive-skill`. This skill now focuses on document content operations only. Use `google-drive-skill` for file management (upload, download, share, search, organize).
- **1.3.0** (2026-02-05) - Added `--convert-to` option for Drive uploads.
- **1.2.0** (2025-12-25) - Added markdown support: `create-from-markdown`, `insert-from-markdown`, `insert-table` commands.
- **1.1.0** (2025-12-20) - Added Google Drive operations (now moved to `google-drive-skill`).
- **1.0.0** (2025-11-10) - Initial Google Docs skill with full document operations.

---

**Dependencies**: Ruby with `google-apis-docs_v1`, `googleauth` gems (shared with other Google skills)
