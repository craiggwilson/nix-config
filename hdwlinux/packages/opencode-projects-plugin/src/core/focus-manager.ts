/**
 * Focus management for opencode-projects plugin
 *
 * Tracks the currently focused project and issue for context injection.
 */

import type { FocusState } from "./types.js"

/**
 * Focus manager - tracks current project/issue context
 *
 * Note: This is in-memory state that persists for the plugin lifetime.
 * For cross-session persistence, we rely on session compaction hooks
 * to inject focus state into the continuation prompt.
 */
export class FocusManager {
  private current: FocusState | null = null

  /**
   * Get current focus state
   */
  getCurrent(): FocusState | null {
    return this.current
  }

  /**
   * Set focus to a project (and optionally an issue)
   */
  setFocus(projectId: string, issueId?: string): void {
    this.current = { projectId, issueId }
  }

  /**
   * Set focus to a specific issue within the current project
   */
  setIssueFocus(issueId: string): boolean {
    if (!this.current) {
      return false
    }
    this.current.issueId = issueId
    return true
  }

  /**
   * Clear all focus
   */
  clear(): void {
    this.current = null
  }

  /**
   * Clear issue focus but keep project focus
   */
  clearIssueFocus(): void {
    if (this.current) {
      this.current.issueId = undefined
    }
  }

  /**
   * Check if focused on a specific project
   */
  isFocusedOn(projectId: string): boolean {
    return this.current?.projectId === projectId
  }

  /**
   * Check if focused on a specific issue
   */
  isFocusedOnIssue(issueId: string): boolean {
    return this.current?.issueId === issueId
  }

  /**
   * Get focused project ID
   */
  getProjectId(): string | null {
    return this.current?.projectId || null
  }

  /**
   * Get focused issue ID
   */
  getIssueId(): string | null {
    return this.current?.issueId || null
  }

  /**
   * Serialize focus state for persistence
   */
  serialize(): string | null {
    if (!this.current) return null
    return JSON.stringify(this.current)
  }

  /**
   * Restore focus state from serialized form
   */
  restore(serialized: string): boolean {
    try {
      const state = JSON.parse(serialized) as FocusState
      if (state.projectId) {
        this.current = state
        return true
      }
      return false
    } catch {
      return false
    }
  }
}
