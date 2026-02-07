---
description: Google Workspace access configuration
type: agent-requested
---

# Google Workspace Access

When accessing Google documents, sheets, slides, or other Google Workspace resources, use the `google-workspace` MCP server.

## Configuration

**Email/Username**: `craig.wilson@mongodb.com`

## Usage

When making calls to google-workspace MCP tools, always use:

```
user_google_email: craig.wilson@mongodb.com
```

## Available Operations

### Google Drive
- `search_drive_files_google-workspace` - Search for files
- `get_drive_file_content_google-workspace` - Get file content
- `create_drive_file_google-workspace` - Create new files

### Google Docs
- `get_doc_content_google-workspace` - Read document content
- `create_doc_google-workspace` - Create new document
- `modify_doc_text_google-workspace` - Edit document text

### Google Sheets
- `read_sheet_values_google-workspace` - Read spreadsheet data
- `modify_sheet_values_google-workspace` - Write/update data
- `create_spreadsheet_google-workspace` - Create new spreadsheet

### Google Slides
- `get_presentation_google-workspace` - Get presentation details
- `create_presentation_google-workspace` - Create new presentation

## Example

```json
{
  "user_google_email": "craig.wilson@mongodb.com",
  "query": "project roadmap"
}
```

