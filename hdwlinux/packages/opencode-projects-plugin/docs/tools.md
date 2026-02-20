# Tools Reference

## Project Tools

### project-create

Create a new project with optional initial structure.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| `name` | string | Yes | Project name (used to generate ID) |
| `description` | string | No | Project description |
| `storage` | `"local"` \| `"global"` | No | Where to store (default: local) |

**Returns:** Project creation confirmation with ID and path.

---

### project-list

List all projects with optional filtering.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| `status` | `"active"` \| `"completed"` \| `"all"` | No | Filter by status (default: all) |
| `storage` | `"local"` \| `"global"` \| `"all"` | No | Filter by storage (default: all) |

**Returns:** List of projects with status summaries.

---

### project-status

Get detailed status of a project including issue tree.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| `projectId` | string | No | Project ID (default: focused project) |

**Returns:** Project status with progress, issue tree, and blockers.

---

### project-focus

Set or clear project/issue focus.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| `projectId` | string | No | Project to focus on |
| `issueId` | string | No | Issue to focus on within project |
| `clear` | boolean | No | Clear current focus |

**Returns:** Current focus state.

---

### project-plan

Manage project planning sessions.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| `projectId` | string | No | Project ID (default: focused project) |
| `action` | `"start"` \| `"continue"` \| `"save"` \| `"advance"` \| `"phase"` \| `"status"` | No | Planning action (default: continue) |
| `phase` | `"discovery"` \| `"synthesis"` \| `"breakdown"` \| `"complete"` | No | Phase to jump to (for action='phase') |
| `understanding` | string | No | JSON string of understanding updates (for action='save') |
| `openQuestions` | string | No | Comma-separated list of open questions (for action='save') |

**Returns:** Planning session state with phase guidance.

---

### project-close

Close a project.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| `projectId` | string | No | Project ID (default: focused project) |
| `reason` | string | No | Reason for closing |

**Returns:** Closure confirmation.

---

## Issue Tools

### project-create-issue

Create a new issue within a project.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| `title` | string | Yes | Issue title |
| `projectId` | string | No | Project ID (default: focused project) |
| `description` | string | No | Issue description |
| `priority` | number | No | Priority (0=highest, 3=lowest) |
| `parent` | string | No | Parent issue ID |
| `blockedBy` | string[] | No | Issues that block this one |
| `labels` | string[] | No | Labels to apply |

**Returns:** Created issue details.

---

### project-work-on-issue

Start work on an issue with a background agent.

This tool:
1. Claims the issue (sets status to in_progress)
2. Optionally creates an isolated git worktree or jj workspace (if isolate=true)
3. Delegates work to a background agent
4. Returns immediately - you'll be notified when complete

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| `issueId` | string | Yes | Issue ID to work on |
| `isolate` | boolean | No | Create isolated worktree (default: false). Use true for code changes. |
| `agent` | string | No | Agent to use (auto-selected if not specified) |

**Behavior:**
- `isolate=false` (default): Runs in repo root. Good for research, analysis, documentation.
- `isolate=true`: Creates git worktree or jj workspace. Required for code changes that need merging.

When `isolate=true`, the completion notification includes VCS-specific merge instructions.

**Returns:** Delegation confirmation with worktree path (if isolated) and delegation ID.

---

### project-update-issue

Update issue fields including status.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| `issueId` | string | Yes | Issue ID to update |
| `projectId` | string | No | Project ID (default: focused project) |
| `status` | `"open"` \| `"in_progress"` \| `"closed"` | No | New status |
| `assignee` | string | No | New assignee |
| `priority` | number | No | New priority |
| `description` | string | No | New description |
| `labels` | string[] | No | New labels |
| `blockedBy` | string[] | No | Blocking issues |
| `mergeWorktree` | boolean | No | Merge worktree on close |
| `mergeStrategy` | `"squash"` \| `"merge"` \| `"rebase"` | No | Merge strategy |
| `comment` | string | No | Comment to add |
| `artifacts` | string[] | No | Artifacts to reference |

**Returns:** Update confirmation with changes summary.

---

## Delegation Tools

### project-internal-delegation-read

Read the result of a completed delegation.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| `id` | string | Yes | Delegation ID (e.g., 'del-abc123') |
| `projectId` | string | No | Project ID (default: focused project) |

**Returns:** Full delegation result including metadata, prompt, and output.

**Use cases:**
- Retrieve results after session compaction
- Review what a background delegation accomplished
- Debug delegation failures
