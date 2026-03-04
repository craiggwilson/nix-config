/**
 * TeamNotifier - Handles parent session notifications
 *
 * Responsible for:
 * - Building XML notifications for parent sessions
 * - Sending notifications via OpenCode client
 * - Generating VCS-specific merge instructions
 */

import type { Logger, OpencodeClient } from "../utils/opencode-sdk/index.js"
import type { Team } from "./team-manager.js"

/**
 * Escape special XML characters to prevent injection and malformed XML.
 * Works for both text content and attribute values.
 */
function escapeXml(str: string): string {
  return str
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&apos;")
}

/**
 * Handles parent session notifications for completed teams.
 *
 * When a team completes (in background mode), the parent session needs to be
 * notified with the aggregated results. This class:
 * - Builds structured XML notifications with team results
 * - Sends notifications to the parent session
 * - Generates VCS-specific merge instructions for isolated worktrees
 */
export class TeamNotifier {
  private log: Logger
  private client: OpencodeClient

  /**
   * @param log - Logger for diagnostic output
   * @param client - OpenCode client for session management
   */
  constructor(log: Logger, client: OpencodeClient) {
    this.log = log
    this.client = client
  }

  /**
   * Notify parent session with aggregated team results.
   *
   * Sends an XML-formatted notification to the parent session containing
   * all member results, discussion history, and merge instructions.
   *
   * @param team - The completed team to notify about
   */
  async notifyParent(team: Team): Promise<void> {
    if (!team.parentSessionId) {
      await this.log.info(`Team ${team.id}: no parent session to notify`)
      return
    }

    const notification = this.buildTeamNotification(team)

    try {
      await this.client.session.prompt({
        path: { id: team.parentSessionId },
        body: {
          noReply: false,
          agent: team.parentAgent,
          parts: [{ type: "text", text: notification }],
        },
      })

      await this.log.info(
        `Team ${team.id}: notified parent session ${team.parentSessionId}`
      )
    } catch (error) {
      await this.log.warn(`Team ${team.id}: failed to notify parent: ${error}`)
    }
  }

  /**
   * Build XML notification for parent session.
   *
   * Creates a structured XML document containing:
   * - Team and issue identifiers
   * - Worktree information (if isolated)
   * - Member results and status
   * - Discussion history (if any)
   * - Merge instructions (if worktree exists)
   *
   * @param team - The team to build notification for
   * @returns XML-formatted notification string
   */
  buildTeamNotification(team: Team): string {
    const lines: string[] = []

    lines.push("<team-notification>")
    lines.push(`  <team-id>${escapeXml(team.id)}</team-id>`)
    lines.push(`  <issue>${escapeXml(team.issueId)}</issue>`)
    lines.push(`  <status>${escapeXml(team.status)}</status>`)

    if (team.worktreePath) {
      lines.push("  <worktree>")
      lines.push(`    <path>${escapeXml(team.worktreePath)}</path>`)
      lines.push(`    <branch>${escapeXml(team.worktreeBranch || team.issueId)}</branch>`)
      lines.push(`    <vcs>${escapeXml(team.vcs || "unknown")}</vcs>`)
      lines.push("  </worktree>")
    }

    lines.push("  <members>")
    for (const member of team.members) {
      const result = team.results[member.agent]
      lines.push(`    <member agent="${escapeXml(member.agent)}" role="${escapeXml(member.role)}">`)
      lines.push(`      <status>${escapeXml(member.status)}</status>`)
      if (result) {
        lines.push("      <result>")
        lines.push(escapeXml(result.result))
        lines.push("      </result>")
      }
      lines.push("    </member>")
    }
    lines.push("  </members>")

    if (team.discussionHistory.length > 0) {
      lines.push(`  <discussion rounds="${team.discussionHistory.length}">`)
      for (const round of team.discussionHistory) {
        lines.push(`    <round n="${round.round}">`)
        for (const [agent, response] of Object.entries(round.responses)) {
          lines.push(`      <response agent="${escapeXml(agent)}">${escapeXml(response)}</response>`)
        }
        lines.push("    </round>")
      }
      lines.push("  </discussion>")
    }

    const mergeInstructions = this.getMergeInstructions(team)
    if (mergeInstructions) {
      lines.push("  <merge-instructions>")
      lines.push(escapeXml(mergeInstructions))
      lines.push("  </merge-instructions>")
    }

    lines.push("</team-notification>")

    return lines.join("\n")
  }

  /**
   * Get VCS-specific merge instructions.
   *
   * Generates step-by-step instructions for merging the worktree changes
   * back to the main branch, specific to the VCS type (jj or git).
   *
   * @param team - The team with worktree information
   * @returns Human-readable merge instructions, or null if no worktree
   */
  getMergeInstructions(team: Team): string | null {
    // Non-isolated teams have no worktree to merge
    if (!team.worktreePath || !team.vcs) {
      return null
    }

    const branch = team.worktreeBranch || team.issueId

    if (team.vcs === "jj") {
      return `Review and merge the changes from the jj workspace:
1. Review: \`jj diff --from main --to ${branch}@\`
2. Squash: \`jj squash --from ${branch}@\` (from main workspace)
3. Clean up: \`jj workspace forget ${branch}\``
    } else {
      return `Review and merge the changes from the git worktree:
1. Review: \`git diff main..${branch}\`
2. Merge: \`git merge ${branch}\`
3. Clean up: \`git worktree remove ${team.worktreePath} && git branch -d ${branch}\``
    }
  }
}
