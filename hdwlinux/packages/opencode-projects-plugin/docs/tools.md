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

Start or continue planning sessions.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| `projectId` | string | No | Project ID (default: focused project) |
| `action` | `"start"` \| `"continue"` \| `"complete"` \| `"list"` | No | Planning action |
| `phase` | `"discovery"` \| `"refinement"` \| `"breakdown"` | No | Planning phase |

**Returns:** Interview session state or artifact list.

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

Claim an issue to work on, optionally in an isolated worktree.

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| `issueId` | string | Yes | Issue ID to claim |
| `projectId` | string | No | Project ID (default: focused project) |
| `isolated` | boolean | No | Create isolated worktree |
| `delegate` | boolean | No | Delegate to background agent |

**Returns:** Claim confirmation with worktree path if isolated.

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
