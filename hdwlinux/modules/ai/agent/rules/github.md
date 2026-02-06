---
description: GitHub access configuration
alwaysApply: true
---

# GitHub Access

When accessing GitHub repositories, issues, pull requests, or other GitHub resources, use the `github` MCP server.

## Configuration

**Username**: `craiggwilson`
**Email**: `craiggwilson@gmail.com`

## Usage

When making calls to GitHub MCP tools, use:
- Username: `craiggwilson`
- Email: `craiggwilson@gmail.com`

## Available Operations

### Repository Operations
- `get_file_contents_github` - Get file or directory contents
- `create_repository_github` - Create new repository
- `fork_repository_github` - Fork a repository
- `create_branch_github` - Create a new branch
- `list_branches_github` - List repository branches
- `list_commits_github` - Get commit history
- `get_commit_github` - Get commit details

### File Operations
- `create_or_update_file_github` - Create or update a file
- `delete_file_github` - Delete a file
- `push_files_github` - Push multiple files in one commit
- `search_code_github` - Search code across repositories

### Issues
- `list_issues_github` - List repository issues
- `search_issues_github` - Search issues
- `issue_read_github` - Get issue details, comments, labels
- `issue_write_github` - Create or update issues
- `add_issue_comment_github` - Add comment to issue

### Pull Requests
- `list_pull_requests_github` - List PRs
- `search_pull_requests_github` - Search PRs
- `create_pull_request_github` - Create new PR
- `update_pull_request_github` - Update existing PR
- `pull_request_read_github` - Get PR details, diff, status
- `merge_pull_request_github` - Merge a PR

### Reviews
- `pull_request_review_write_github` - Create/submit PR review
- `add_comment_to_pending_review_github` - Add review comments
- `request_copilot_review_github` - Request Copilot review

### Other
- `get_me_github` - Get authenticated user info
- `search_repositories_github` - Search repositories
- `search_users_github` - Search users
- `list_releases_github` - List releases
- `get_latest_release_github` - Get latest release

## Example

```json
{
  "owner": "craiggwilson",
  "repo": "my-repo",
  "path": "README.md"
}
```

Always use the GitHub MCP server for GitHub operations rather than direct API calls or git commands for GitHub-specific features.

