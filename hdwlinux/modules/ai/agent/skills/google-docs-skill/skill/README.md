# Google Docs Skill for Augment Code

A Augment Code skill for managing Google Docs and Google Drive with comprehensive document and file operations.

## Features

### Google Docs Operations
- Read document content and structure
- Create new documents
- Insert and append text
- Find and replace text
- Text formatting (bold, italic, underline)
- Insert page breaks and images
- Delete content ranges

### Google Drive Operations
- Upload and download files
- Search across Drive
- Create and list folders
- Share files and folders
- Move and organize files
- Export files to different formats (PDF, PNG, etc.)

## Installation

This skill is installed via your configuration system (e.g., Nix, etc.). The installation path varies by system.

## Setup

1. **Create Google Cloud Project** and enable the Docs and Drive APIs
2. **Create OAuth 2.0 credentials** (Desktop application type)
3. **Download credentials** and save as `~/.ai/agent/.google/client_secret.json`
4. **Run any command** - the script will prompt for authorization

The OAuth token is shared with other Google skills (Sheets, Calendar, Gmail, etc.).

## Usage

See [SKILL.md](SKILL.md) for complete documentation and examples.

In all examples below, `$SKILL_PATH` refers to this skill's installation directory.

### Quick Examples

```bash
# Read a document
$SKILL_PATH/bin/ruby $SKILL_PATH/scripts/docs_manager.rb read <document_id>

# Create a document
echo '{"title": "My Doc", "content": "Hello World"}' | $SKILL_PATH/bin/ruby $SKILL_PATH/scripts/docs_manager.rb create

# Upload a file to Drive (use google-drive-skill)
$DRIVE_SKILL_PATH/bin/ruby $DRIVE_SKILL_PATH/scripts/drive_manager.rb upload --file ./myfile.pdf --name "My PDF"

# Search Drive (use google-drive-skill)
$DRIVE_SKILL_PATH/bin/ruby $DRIVE_SKILL_PATH/scripts/drive_manager.rb search --query "name contains 'Report'"
```

## License

MIT License - see [LICENSE](LICENSE) for details.
