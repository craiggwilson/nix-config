---
name: google-drive
description: Manage Google Drive files with full file management operations. Upload, download, share, search, organize files and folders, and read comments.
category: productivity
version: 1.1.0
key_capabilities: upload, download, share, search, create-folder, move, copy, delete, convert-to-google-format, list-comments, get-comment
when_to_use: Drive file management, uploading files, downloading files, sharing files, searching files, organizing folders, reading document comments
allowed-tools: Bash(ruby:*)
---

# Google Drive Management Skill

## Skill Path

**Important**: All commands in this skill use `$SKILL_PATH` to refer to this skill's installation directory. You must substitute this with the actual path where this skill is installed. The `bin/` directory contains all required executables.

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
- Read comments and replies on files

## When to Use This Skill

Use this skill when:
- User wants to upload a file to Google Drive
- User wants to download a file from Google Drive
- User wants to share a file or folder
- User wants to search for files in Drive
- User wants to organize files into folders
- User wants to convert a markdown file to Google Docs
- User wants to read comments on a Google Doc or file
- Keywords: "Google Drive", "upload", "download", "share", "search files", "comments"

## Core Workflows

### 1. Upload Files

**Upload a file to Drive root**:
```bash
$SKILL_PATH/bin/ruby $SKILL_PATH/scripts/drive_manager.rb upload --file ./document.pdf
```

**Upload to specific folder**:
```bash
$SKILL_PATH/bin/ruby $SKILL_PATH/scripts/drive_manager.rb upload --file ./diagram.excalidraw --folder-id abc123
```

**Upload with custom name**:
```bash
$SKILL_PATH/bin/ruby $SKILL_PATH/scripts/drive_manager.rb upload --file ./local.txt --name "Remote Name.txt"
```

**Upload and convert markdown to Google Doc (RECOMMENDED for markdown files)**:
```bash
$SKILL_PATH/bin/ruby $SKILL_PATH/scripts/drive_manager.rb upload \
  --file ./document.md \
  --name "Document Title" \
  --convert-to google-docs
```

This uses Google Drive's native markdown conversion which handles all formatting reliably.

### 2. Download Files

**Download a file**:
```bash
$SKILL_PATH/bin/ruby $SKILL_PATH/scripts/drive_manager.rb download --file-id abc123 --output ./local_copy.pdf
```

**Export Google Doc as PDF**:
```bash
$SKILL_PATH/bin/ruby $SKILL_PATH/scripts/drive_manager.rb download --file-id abc123 --output ./doc.pdf --export-as pdf
```

**Export Google Sheet as CSV**:
```bash
$SKILL_PATH/bin/ruby $SKILL_PATH/scripts/drive_manager.rb download --file-id abc123 --output ./data.csv --export-as csv
```

### 3. Search and List Files

**List recent files**:
```bash
$SKILL_PATH/bin/ruby $SKILL_PATH/scripts/drive_manager.rb list --max-results 20
```

**Search by name**:
```bash
$SKILL_PATH/bin/ruby $SKILL_PATH/scripts/drive_manager.rb search --query "name contains 'Report'"
```

**Search by type**:
```bash
$SKILL_PATH/bin/ruby $SKILL_PATH/scripts/drive_manager.rb search --query "mimeType='application/vnd.google-apps.document'"
```

**Search in folder**:
```bash
$SKILL_PATH/bin/ruby $SKILL_PATH/scripts/drive_manager.rb search --query "'folder_id' in parents"
```

**Combine queries**:
```bash
$SKILL_PATH/bin/ruby $SKILL_PATH/scripts/drive_manager.rb search --query "name contains '.excalidraw' and modifiedTime > '2024-01-01'"
```

### 4. Share Files

**Share with specific user (reader)**:
```bash
$SKILL_PATH/bin/ruby $SKILL_PATH/scripts/drive_manager.rb share --file-id abc123 --email user@example.com --role reader
```

**Share with write access**:
```bash
$SKILL_PATH/bin/ruby $SKILL_PATH/scripts/drive_manager.rb share --file-id abc123 --email user@example.com --role writer
```

**Make publicly accessible (anyone with link)**:
```bash
$SKILL_PATH/bin/ruby $SKILL_PATH/scripts/drive_manager.rb share --file-id abc123 --type anyone --role reader
```

### 5. Folder Management

**Create a folder**:
```bash
$SKILL_PATH/bin/ruby $SKILL_PATH/scripts/drive_manager.rb create-folder --name "Project Documents"
```

**Create folder inside another folder**:
```bash
$SKILL_PATH/bin/ruby $SKILL_PATH/scripts/drive_manager.rb create-folder --name "Diagrams" --parent-id abc123
```

**Move file to folder**:
```bash
$SKILL_PATH/bin/ruby $SKILL_PATH/scripts/drive_manager.rb move --file-id file123 --folder-id folder456
```

### 6. Other Operations

**Get file metadata**:
```bash
$SKILL_PATH/bin/ruby $SKILL_PATH/scripts/drive_manager.rb get-metadata --file-id abc123
```

**Copy a file**:
```bash
$SKILL_PATH/bin/ruby $SKILL_PATH/scripts/drive_manager.rb copy --file-id abc123 --name "Copy of Document"
```

**Update file content (replace)**:
```bash
$SKILL_PATH/bin/ruby $SKILL_PATH/scripts/drive_manager.rb update --file-id abc123 --file ./new_content.pdf
```

**Delete file (moves to trash)**:
```bash
$SKILL_PATH/bin/ruby $SKILL_PATH/scripts/drive_manager.rb delete --file-id abc123
```

### 7. Read Comments

**List all comments on a file**:
```bash
$SKILL_PATH/bin/ruby $SKILL_PATH/scripts/drive_manager.rb list-comments --file-id abc123
```

**Get a specific comment with replies**:
```bash
$SKILL_PATH/bin/ruby $SKILL_PATH/scripts/drive_manager.rb get-comment --file-id abc123 --comment-id xyz789
```

**Include deleted comments**:
```bash
$SKILL_PATH/bin/ruby $SKILL_PATH/scripts/drive_manager.rb list-comments --file-id abc123 --include-deleted
```

**Comment output format**:
```json
{
  "status": "success",
  "operation": "list_comments",
  "file_id": "abc123",
  "comments": [
    {
      "id": "AAAA1234",
      "content": "We should add more detail here.",
      "author": {
        "display_name": "Jane Smith",
        "email": "jane@example.com",
        "photo_link": "https://..."
      },
      "created_time": "2026-02-05T14:30:00Z",
      "modified_time": "2026-02-05T14:30:00Z",
      "resolved": false,
      "quoted_content": "Target State: Multi-Region",
      "replies": [
        {
          "id": "BBBB5678",
          "content": "Good point, I'll add that.",
          "author": {
            "display_name": "Craig Wilson",
            "email": "craig@example.com"
          },
          "created_time": "2026-02-05T15:00:00Z",
          "modified_time": "2026-02-05T15:00:00Z"
        }
      ]
    }
  ],
  "next_page_token": null,
  "count": 1
}
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
- Located at: `~/.config/google-drive-skill/client_secret.json` and `~/.local/share/google-drive-skill/token.json`
- Shares token with docs, email, calendar, contacts, and sheets skills
- Requires Drive, Documents, Sheets, Calendar, Contacts, and Gmail API scopes

**First Time Setup**:
1. Run any drive operation
2. Script will output JSON with authorization URL and instructions
3. Visit URL and authorize all Google services
4. Copy the authorization code
5. Run: `$SKILL_PATH/bin/ruby $SKILL_PATH/scripts/drive_manager.rb auth <code>`
6. Token stored for all Google skills

**Complete Authorization**:
```bash
$SKILL_PATH/bin/ruby $SKILL_PATH/scripts/drive_manager.rb auth YOUR_AUTH_CODE
```

**Re-authorization**:
- Token automatically refreshes when expired
- If refresh fails, re-run authorization flow
- All Google skills will work after single re-auth

## Error Handling

**Authentication Error**:
```json
{
  "status": "error",
  "error_code": "AUTH_REQUIRED",
  "message": "Authorization required..."
}
```
**Action**: Follow the instructions in the error response to complete authorization using `drive_manager.rb auth <code>`

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

**`$SKILL_PATH/scripts/drive_manager.rb`**
- Comprehensive Google Drive API wrapper
- All file operations: upload, download, share, move, copy, delete
- Folder management
- Search and list functionality
- Read comments and replies
- Automatic token refresh
- Shared OAuth with other Google skills

**Operations**:
- `auth`: Complete OAuth authorization with code
- `upload`: Upload file to Drive
- `download`: Download file from Drive
- `list`: List files in folder
- `search`: Search files with query
- `get-metadata`: Get file metadata
- `list-comments`: List comments on a file
- `get-comment`: Get a specific comment by ID
- `create-folder`: Create folder
- `move`: Move file to folder
- `share`: Share file with user or publicly
- `delete`: Delete file (trash or permanent)
- `copy`: Copy file
- `update`: Update file content

## Version History

- **1.1.0** (2026-02-09) - Added readonly comments access: `list-comments` and `get-comment` commands to read document comments and replies.
- **1.0.0** (2026-02-06) - Initial release. Split from google-docs-skill. All Drive operations: upload, download, search, list, share, move, copy, delete, folder management. Supports `--convert-to` for uploading markdown as Google Docs.

---

**Dependencies**: Ruby with `google-apis-drive_v3`, `googleauth` gems (shared with other Google skills)

