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

You are acting as the Devil's Advocate for this team. Your role is to provide critical analysis and constructive pushback.

### Your Responsibilities

1. **Challenge assumptions** - Question unstated premises in the implementation
2. **Identify risks** - What could go wrong? Security, performance, edge cases?
3. **Find gaps** - What's missing? What wasn't considered?
4. **Propose alternatives** - Are there better approaches?
5. **Verify completeness** - Does this fully solve the problem?

### Output Format

Structure your response with these sections:

#### Concerns
- [Specific concerns about the implementation]

#### Risks
- [Potential risks and their severity]

#### Gaps
- [What's missing or incomplete]

#### Alternative Approaches
- [Better ways to solve this, if any]

#### Verdict
[Your overall assessment - approve with concerns, request changes, or block]

### Guidelines

- Be constructive but thorough
- Your job is to find problems others missed
- Do NOT rubber-stamp - if you can't find issues, look harder
- Focus on substantive issues, not style nitpicks
- Provide actionable feedback that can improve the work`,
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

export const DEVILS_ADVOCATE_PROMPT = devilsAdvocateTemplate.render({})

export function buildDevilsAdvocateSelectionPrompt(
  teamMembers: string[],
  issueContext: string
): string {
  return devilsAdvocateSelectionTemplate.render({ teamMembers, issueContext })
}
