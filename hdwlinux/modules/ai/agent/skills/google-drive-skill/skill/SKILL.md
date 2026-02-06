---
name: google-drive
description: Manage Google Drive files with full file management operations. Upload, download, share, search, and organize files and folders.
category: productivity
version: 1.0.0
key_capabilities: upload, download, share, search, create-folder, move, copy, delete, convert-to-google-format
when_to_use: Drive file management, uploading files, downloading files, sharing files, searching files, organizing folders
allowed-tools: Bash(ruby:*)
---

# Google Drive Management Skill

## Purpose

Manage Google Drive files with comprehensive operations:

- Upload files to Drive (with optional conversion to Google formats)
- Download files from Drive
- Export Google Docs/Sheets/Slides to various formats
- Search and list files
- Share files with users or publicly
- Create folders
- Move, copy, and delete files
- Get file metadata

## When to Use This Skill

Use this skill when:
- User wants to upload a file to Google Drive
- User wants to download a file from Google Drive
- User wants to share a file or folder
- User wants to search for files in Drive
- User wants to organize files into folders
- User wants to convert a markdown file to Google Docs
- Keywords: "Google Drive", "upload", "download", "share", "search files"

## Core Workflows

### 1. Upload Files

**Upload a file to Drive root**:
```bash
~/.ai/agent/skills/google-drive-skill/bin/ruby ~/.ai/agent/skills/google-drive-skill/scripts/drive_manager.rb upload --file ./document.pdf
```

**Upload to specific folder**:
```bash
~/.ai/agent/skills/google-drive-skill/bin/ruby ~/.ai/agent/skills/google-drive-skill/scripts/drive_manager.rb upload --file ./diagram.excalidraw --folder-id abc123
```

**Upload with custom name**:
```bash
~/.ai/agent/skills/google-drive-skill/bin/ruby ~/.ai/agent/skills/google-drive-skill/scripts/drive_manager.rb upload --file ./local.txt --name "Remote Name.txt"
```

**Upload and convert markdown to Google Doc (RECOMMENDED for markdown files)**:
```bash
~/.ai/agent/skills/google-drive-skill/bin/ruby ~/.ai/agent/skills/google-drive-skill/scripts/drive_manager.rb upload \
  --file ./document.md \
  --name "Document Title" \
  --convert-to google-docs
```

This uses Google Drive's native markdown conversion which handles all formatting reliably.

### 2. Download Files

**Download a file**:
```bash
~/.ai/agent/skills/google-drive-skill/bin/ruby ~/.ai/agent/skills/google-drive-skill/scripts/drive_manager.rb download --file-id abc123 --output ./local_copy.pdf
```

**Export Google Doc as PDF**:
```bash
~/.ai/agent/skills/google-drive-skill/bin/ruby ~/.ai/agent/skills/google-drive-skill/scripts/drive_manager.rb download --file-id abc123 --output ./doc.pdf --export-as pdf
```

**Export Google Sheet as CSV**:
```bash
~/.ai/agent/skills/google-drive-skill/bin/ruby ~/.ai/agent/skills/google-drive-skill/scripts/drive_manager.rb download --file-id abc123 --output ./data.csv --export-as csv
```

### 3. Search and List Files

**List recent files**:
```bash
~/.ai/agent/skills/google-drive-skill/bin/ruby ~/.ai/agent/skills/google-drive-skill/scripts/drive_manager.rb list --max-results 20
```

**Search by name**:
```bash
~/.ai/agent/skills/google-drive-skill/bin/ruby ~/.ai/agent/skills/google-drive-skill/scripts/drive_manager.rb search --query "name contains 'Report'"
```

**Search by type**:
```bash
~/.ai/agent/skills/google-drive-skill/bin/ruby ~/.ai/agent/skills/google-drive-skill/scripts/drive_manager.rb search --query "mimeType='application/vnd.google-apps.document'"
```

**Search in folder**:
```bash
~/.ai/agent/skills/google-drive-skill/bin/ruby ~/.ai/agent/skills/google-drive-skill/scripts/drive_manager.rb search --query "'folder_id' in parents"
```

**Combine queries**:
```bash
~/.ai/agent/skills/google-drive-skill/bin/ruby ~/.ai/agent/skills/google-drive-skill/scripts/drive_manager.rb search --query "name contains '.excalidraw' and modifiedTime > '2024-01-01'"
```

### 4. Share Files

**Share with specific user (reader)**:
```bash
~/.ai/agent/skills/google-drive-skill/bin/ruby ~/.ai/agent/skills/google-drive-skill/scripts/drive_manager.rb share --file-id abc123 --email user@example.com --role reader
```

**Share with write access**:
```bash
~/.ai/agent/skills/google-drive-skill/bin/ruby ~/.ai/agent/skills/google-drive-skill/scripts/drive_manager.rb share --file-id abc123 --email user@example.com --role writer
```

**Make publicly accessible (anyone with link)**:
```bash
~/.ai/agent/skills/google-drive-skill/bin/ruby ~/.ai/agent/skills/google-drive-skill/scripts/drive_manager.rb share --file-id abc123 --type anyone --role reader
```

### 5. Folder Management

**Create a folder**:
```bash
~/.ai/agent/skills/google-drive-skill/bin/ruby ~/.ai/agent/skills/google-drive-skill/scripts/drive_manager.rb create-folder --name "Project Documents"
```

**Create folder inside another folder**:
```bash
~/.ai/agent/skills/google-drive-skill/bin/ruby ~/.ai/agent/skills/google-drive-skill/scripts/drive_manager.rb create-folder --name "Diagrams" --parent-id abc123
```

**Move file to folder**:
```bash
~/.ai/agent/skills/google-drive-skill/bin/ruby ~/.ai/agent/skills/google-drive-skill/scripts/drive_manager.rb move --file-id file123 --folder-id folder456
```

### 6. Other Operations

**Get file metadata**:
```bash
~/.ai/agent/skills/google-drive-skill/bin/ruby ~/.ai/agent/skills/google-drive-skill/scripts/drive_manager.rb get-metadata --file-id abc123
```

**Copy a file**:
```bash
~/.ai/agent/skills/google-drive-skill/bin/ruby ~/.ai/agent/skills/google-drive-skill/scripts/drive_manager.rb copy --file-id abc123 --name "Copy of Document"
```

**Update file content (replace)**:
```bash
~/.ai/agent/skills/google-drive-skill/bin/ruby ~/.ai/agent/skills/google-drive-skill/scripts/drive_manager.rb update --file-id abc123 --file ./new_content.pdf
```

**Delete file (moves to trash)**:
```bash
~/.ai/agent/skills/google-drive-skill/bin/ruby ~/.ai/agent/skills/google-drive-skill/scripts/drive_manager.rb delete --file-id abc123
```

## Output Format

All commands return JSON with consistent structure:
```json
{
  "status": "success",
  "operation": "upload",
  "file": {
    "id": "1abc...",
    "name": "document.pdf",
    "mime_type": "application/pdf",
    "web_view_link": "https://drive.google.com/file/d/1abc.../view",
    "web_content_link": "https://drive.google.com/uc?id=1abc...",
    "created_time": "2024-01-15T10:30:00Z",
    "modified_time": "2024-01-15T10:30:00Z",
    "size": 12345
  }
}
```

## Authentication Setup

**Shared with Other Google Skills**:
- Uses same OAuth credentials and token as google-docs-skill
- Located at: `~/.ai/agent/.google/client_secret.json` and `~/.ai/agent/.google/token.json`
- Shares token with docs, email, calendar, contacts, and sheets skills
- Requires Drive, Documents, Sheets, Calendar, Contacts, and Gmail API scopes

**First Time Setup**:
1. Run any drive operation
2. Script will prompt for authorization URL
3. Visit URL and authorize all Google services
4. Enter authorization code when prompted
5. Token stored for all Google skills

## Error Handling

**Authentication Error**:
```json
{
  "status": "error",
  "error_code": "AUTH_REQUIRED",
  "message": "Authorization required..."
}
```
**Action**: Use docs_manager.rb auth flow for initial setup

**File Not Found**:
```json
{
  "status": "error",
  "error_code": "FILE_NOT_FOUND",
  "message": "File not found: ..."
}
```
**Action**: Verify local file path exists

**API Error**:
```json
{
  "status": "error",
  "error_code": "API_ERROR",
  "message": "Google Drive API error: ..."
}
```
**Action**: Check file ID, verify permissions

## Bundled Resources

### Scripts

**`~/.ai/agent/skills/google-drive-skill/scripts/drive_manager.rb`**
- Comprehensive Google Drive API wrapper
- All file operations: upload, download, share, move, copy, delete
- Folder management
- Search and list functionality
- Automatic token refresh
- Shared OAuth with other Google skills

**Operations**:
- `upload`: Upload file to Drive
- `download`: Download file from Drive
- `list`: List files in folder
- `search`: Search files with query
- `get-metadata`: Get file metadata
- `create-folder`: Create folder
- `move`: Move file to folder
- `share`: Share file with user or publicly
- `delete`: Delete file (trash or permanent)
- `copy`: Copy file
- `update`: Update file content

## Version History

- **1.0.0** (2026-02-06) - Initial release. Split from google-docs-skill. All Drive operations: upload, download, search, list, share, move, copy, delete, folder management. Supports `--convert-to` for uploading markdown as Google Docs.

---

**Dependencies**: Ruby with `google-apis-drive_v3`, `googleauth` gems (shared with other Google skills)

