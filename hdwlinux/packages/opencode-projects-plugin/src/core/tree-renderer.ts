/**
 * ASCII tree renderer for visualizing issue dependencies
 */

import type { Issue } from "../storage/issue-storage.js"

/**
 * Tree node for rendering
 */
interface TreeNode {
  issue: Issue
  children: TreeNode[]
}

/**
 * Status icons for issues
 */
const STATUS_ICONS: Record<string, string> = {
  open: "⬜",
  in_progress: "🔄",
  closed: "✅",
  blocked: "⏳",
}

/**
 * Build a tree structure from a flat list of issues
 */
export function buildIssueTree(issues: Issue[]): TreeNode[] {
  const issueMap = new Map<string, Issue>()
  const childrenMap = new Map<string, Issue[]>()

  for (const issue of issues) {
    issueMap.set(issue.id, issue)
  }

  for (const issue of issues) {
    if (issue.parent) {
      const siblings = childrenMap.get(issue.parent) || []
      siblings.push(issue)
      childrenMap.set(issue.parent, siblings)
    }
  }

  function buildNode(issue: Issue): TreeNode {
    const children = childrenMap.get(issue.id) || []
    return {
      issue,
      children: children
        .sort((a, b) => a.id.localeCompare(b.id))
        .map((child) => buildNode(child)),
    }
  }

  const roots = issues.filter((issue) => !issue.parent || !issueMap.has(issue.parent))

  return roots.sort((a, b) => a.id.localeCompare(b.id)).map((root) => buildNode(root))
}

/**
 * Render a tree as ASCII art
 */
export function renderTree(nodes: TreeNode[], options?: { showStatus?: boolean }): string {
  const lines: string[] = []
  const showStatus = options?.showStatus ?? true

  function renderNode(node: TreeNode, prefix: string, isLast: boolean): void {
    const connector = isLast ? "└── " : "├── "
    const statusIcon = showStatus ? getStatusIcon(node.issue) + " " : ""
    const priorityBadge = node.issue.priority !== undefined ? ` [P${node.issue.priority}]` : ""

    lines.push(`${prefix}${connector}${statusIcon}${node.issue.id}: ${node.issue.title}${priorityBadge}`)

    const childPrefix = prefix + (isLast ? "    " : "│   ")

    for (let i = 0; i < node.children.length; i++) {
      const isLastChild = i === node.children.length - 1
      renderNode(node.children[i], childPrefix, isLastChild)
    }
  }

  for (let i = 0; i < nodes.length; i++) {
    const isLast = i === nodes.length - 1
    renderNode(nodes[i], "", isLast)
  }

  return lines.join("\n")
}

/**
 * Get the status icon for an issue
 */
function getStatusIcon(issue: Issue): string {
  if (issue.blockedBy && issue.blockedBy.length > 0 && issue.status !== "closed") {
    return STATUS_ICONS.blocked
  }
  return STATUS_ICONS[issue.status] || "⬜"
}

/**
 * Render issues as a dependency tree
 */
export function renderIssueTree(issues: Issue[], options?: { showStatus?: boolean }): string {
  if (issues.length === 0) {
    return "(no issues)"
  }

  const tree = buildIssueTree(issues)
  return renderTree(tree, options)
}
