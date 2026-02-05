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

Add this skill to your Augment Code configuration:

```bash
# Clone to your skills directory
git clone https://github.com/robtaylor/google-docs-skill.git ~/.augment/skills/google-docs

# Or add as submodule to your augment-config
cd ~/.augment
git submodule add https://github.com/robtaylor/google-docs-skill.git skills/google-docs
```

## Setup

1. **Create Google Cloud Project** and enable the Docs and Drive APIs
2. **Create OAuth 2.0 credentials** (Desktop application type)
3. **Download credentials** and save as `~/.augment/.google/client_secret.json`
4. **Run any command** - the script will prompt for authorization

The OAuth token is shared with other Google skills (Sheets, Calendar, Gmail, etc.).

## Usage

See [SKILL.md](SKILL.md) for complete documentation and examples.

### Quick Examples

```bash
# Read a document
~/.augment/skills/google-docs-skill/bin/ruby ~/.augment/skills/google-docs-skill/scripts/docs_manager.rb read <document_id>

# Create a document
echo '{"title": "My Doc", "content": "Hello World"}' | ~/.augment/skills/google-docs-skill/bin/ruby ~/.augment/skills/google-docs-skill/scripts/docs_manager.rb create

# Upload a file to Drive
~/.augment/skills/google-docs-skill/bin/ruby ~/.augment/skills/google-docs-skill/scripts/drive_manager.rb upload --file ./myfile.pdf --name "My PDF"

# Search Drive
~/.augment/skills/google-docs-skill/bin/ruby ~/.augment/skills/google-docs-skill/scripts/drive_manager.rb search --query "name contains 'Report'"
```

## License

MIT License - see [LICENSE](LICENSE) for details.
