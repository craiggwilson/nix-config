import type { Team, DiscussionRound } from "./team-manager.js"

/**
 * Build context for a discussion round.
 *
 * Assembles context from primary agent's work, other agents' findings,
 * and all previous discussion rounds.
 */
export function buildDiscussionContext(
  team: Team,
  round: number,
  discussionHistory: DiscussionRound[]
): string {
  const lines: string[] = []

  const primary = team.members.find((m) => m.role === "primary")
  if (primary && team.results[primary.agent]) {
    lines.push("## Primary Agent's Implementation")
    lines.push("")
    lines.push(team.results[primary.agent].result)
    lines.push("")
  }

  lines.push("## Team Findings")
  lines.push("")
  for (const member of team.members) {
    if (member.role !== "primary" && team.results[member.agent]) {
      lines.push(`### ${member.agent}`)
      lines.push("")
      lines.push(team.results[member.agent].result)
      lines.push("")
    }
  }

  if (round > 1 && discussionHistory.length > 0) {
    lines.push("## Previous Discussion")
    lines.push("")
    for (const prevRound of discussionHistory) {
      lines.push(`### Round ${prevRound.round}`)
      lines.push("")
      for (const [agent, response] of Object.entries(prevRound.responses)) {
        lines.push(`**${agent}:**`)
        lines.push(response)
        lines.push("")
      }
    }
  }

  return lines.join("\n")
}
