/**
 * Devil's Advocate prompt injection for critical thinking agents
 *
 * The devil's advocate role is assigned to one non-primary team member
 * to ensure critical analysis and pushback on the primary agent's work.
 */

/**
 * Prompt to inject for the devil's advocate agent
 */
export const DEVILS_ADVOCATE_PROMPT = `
## Devil's Advocate Role

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
- Provide actionable feedback that can improve the work
`

/**
 * Build the small model prompt to select which agent should be devil's advocate
 */
export function buildDevilsAdvocateSelectionPrompt(
  teamMembers: string[],
  issueContext: string
): string {
  const nonPrimary = teamMembers.slice(1)

  if (nonPrimary.length === 0) {
    return "" // No non-primary members to select from
  }

  if (nonPrimary.length === 1) {
    return "" // Only one option, no need to ask
  }

  return `Select ONE non-primary agent to act as Devil's Advocate.

TEAM:
- ${teamMembers[0]} (PRIMARY - implementing)
${nonPrimary.map((a) => `- ${a} (reviewer)`).join("\n")}

ISSUE:
${issueContext.slice(0, 500)}

The Devil's Advocate will:
- Challenge assumptions and question decisions
- Identify risks, edge cases, and potential failures
- Propose alternative approaches
- Ensure nothing is overlooked

Select the agent best suited to provide critical pushback for this type of work.

Respond with JSON only:
{"devilsAdvocate": "agent-name"}`
}
