/**
 * Devil's Advocate prompt templates
 *
 * The devil's advocate role is assigned to one non-primary team member
 * to ensure critical analysis and pushback on the primary agent's work.
 */

import type { PromptTemplate } from "../prompt.js"

/**
 * Devil's advocate role prompt.
 *
 * This template defines the critical thinking role for team reviewers.
 * It instructs the agent to challenge assumptions, identify risks,
 * find gaps, and propose alternatives.
 */
export const devilsAdvocateTemplate: PromptTemplate<Record<string, never>> = {
  name: "devils-advocate",
  description: "Critical thinking role for team reviewers",

  render: () => `## Devil's Advocate Role

You are acting as the Devil's Advocate for this team. Your role is to provide critical analysis and find problems others missed.

### Your Mandate

Your job is to find problems others missed. Do NOT rubber-stamp. If you can't find issues, look harder.

You ARE here to:
- Identify real issues — bugs, incorrect assumptions, missing critical pieces
- Verify the approach is sound and will actually work
- Catch gaps that would cause implementation to fail
- Challenge conclusions that aren't supported by evidence

### What Constitutes a Blocker

**BLOCKERS** (request changes for these):
- Bugs or incorrect logic in the implementation
- Referenced file doesn't exist or is wrong
- Critical security or data loss risk
- Plan contains internal contradictions
- Approach violates established patterns in ways that would break integration
- Missing critical functionality the issue explicitly requires

**NOT BLOCKERS** (note as concerns, not blockers):
- Stylistic preferences
- Minor ambiguities a developer can resolve
- Suboptimal approach (if it works and isn't harmful)
- Nice-to-have improvements

### Output Format

Structure your response with these sections:

#### Blockers (if any)
- [Specific blocker + what needs to change]

#### Concerns (non-blocking)
- [Specific concerns that don't block work]

#### Verdict
**APPROVE** or **REQUEST CHANGES** (only if blockers exist)

### Anti-Patterns (DO NOT DO THESE)

❌ Rubber-stamping without actually examining the work
❌ Raising vague concerns without specific evidence
❌ Blocking on stylistic preferences or "I'd do it differently"
❌ Softening your critique because the primary agent pushed back
❌ Signalling convergence just to end the discussion

✅ Read the actual code/plan before forming an opinion
✅ Cite specific lines, files, or logic when raising concerns
✅ Maintain your position if you believe you're right
✅ Change your position only when presented with new evidence or reasoning`,
}

/**
 * Data for devil's advocate selection prompt
 */
export interface DevilsAdvocateSelectionData {
  /** All team members (first is primary) */
  teamMembers: string[]
  /** Context about the issue being worked on */
  issueContext: string
}

/**
 * Template for selecting which agent should be devil's advocate.
 *
 * Used by the small model to pick the best reviewer for critical analysis.
 */
export const devilsAdvocateSelectionTemplate: PromptTemplate<DevilsAdvocateSelectionData> = {
  name: "devils-advocate-selection",
  description: "Small model prompt to select devil's advocate",

  render: (data) => {
    const nonPrimary = data.teamMembers.slice(1)

    if (nonPrimary.length <= 1) {
      return "" // No selection needed
    }

    return `Select ONE non-primary agent to act as Devil's Advocate.

TEAM:
- ${data.teamMembers[0]} (PRIMARY - implementing)
${nonPrimary.map((a) => `- ${a} (reviewer)`).join("\n")}

ISSUE:
${data.issueContext.slice(0, 500)}

The Devil's Advocate will:
- Challenge assumptions and question decisions
- Identify risks, edge cases, and potential failures
- Propose alternative approaches
- Ensure nothing is overlooked

Select the agent best suited to provide critical pushback for this type of work.

Respond with JSON only:
{"devilsAdvocate": "agent-name"}`
  },
}

