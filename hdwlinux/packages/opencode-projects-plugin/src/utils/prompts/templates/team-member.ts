/**
 * Team member prompt templates
 *
 * Templates for generating prompts for team members working on issues.
 * Supports primary agents (implementers) and reviewers (including devil's advocate).
 */

import type { PromptTemplate } from "../prompt.js"
import { lines } from "../xml-wrapper.js"
import { delegationConstraints, readOnlyConstraints } from "../sections/constraints.js"
import { devilsAdvocateTemplate } from "./devil-advocate.js"

/**
 * Data for primary team member prompt
 */
export interface PrimaryMemberData {
  role: "primary"
  /** Agent type/name */
  agent: string
  /** Whether there are other team members reviewing */
  hasReviewers: boolean
  /** Full issue context (title, description, etc.) */
  issueContext: string
  /** Issue ID being worked on */
  issueId: string
  /** Filesystem path to the project directory */
  projectDir: string
  /** Path to isolated worktree, if any */
  worktreePath?: string
}

/**
 * Data for reviewer team member prompt
 */
export interface ReviewerMemberData {
  role: "reviewer" | "devilsAdvocate"
  /** Agent type/name */
  agent: string
  /** Full issue context (title, description, etc.) */
  issueContext: string
  /** Whether the primary agent is working concurrently (true) or has already completed (false). Defaults to false. */
  isConcurrent?: boolean
  /** Issue ID being worked on */
  issueId: string
  /** Name of the primary agent doing implementation */
  primaryAgent: string
  /** Filesystem path to the project directory */
  projectDir: string
  /** Path to isolated worktree, if any */
  worktreePath?: string
}

/**
 * Union type for all team member data
 */
export type TeamMemberData = PrimaryMemberData | ReviewerMemberData

/**
 * Template for team member prompts.
 *
 * Generates role-appropriate prompts for primary agents and reviewers.
 * Primary agents get implementation instructions, reviewers get review
 * instructions, and devil's advocates get additional critical thinking guidance.
 */
export const teamMemberTemplate: PromptTemplate<TeamMemberData> = {
  name: "team-member",
  description: "Prompt for a team member (primary, reviewer, or devils advocate)",

  render: (data) => {
    if (data.role === "primary") {
      return renderPrimary(data)
    }
    return renderReviewer(data)
  },
}

function renderPrimary(data: PrimaryMemberData): string {
  const parts: string[] = [
    `# Task: ${data.issueId}`,
    "",
    `You are the PRIMARY agent for this task. Your role: ${data.agent}`,
    "",
    "## Issue",
    "",
    data.issueContext,
    "",
    "## Your Responsibilities",
    "",
    "1. Complete the main work for this issue",
    "2. Write code, make changes, implement the solution",
    "3. Commit your changes with clear messages",
    "",
    "## Quality Expectations",
    "",
    "- Follow existing patterns in the codebase — don't introduce new conventions without reason",
    "- Write tests if the codebase has them",
    "- Leave code in a better state than you found it",
    "- If you can't complete something, say so explicitly rather than delivering partial work silently",
    "",
    "## On Reviewer Feedback",
    "",
    "When a reviewer raises concerns:",
    "- Understand what they're actually saying before responding",
    "- Defend your approach if you believe it's sound — you have context the reviewer may lack",
    "- Only change course for true blockers (bugs, broken logic, missing critical pieces)",
    "- Do not concede to stylistic preferences, \"could be better\" suggestions, or reviewer uncertainty",
    "- If you change your approach, explain why the reviewer's point was valid",
    "",
    "## Project Context",
    "",
    `**Project directory:** ${data.projectDir}`,
    "",
    "Store artifacts in the project directory:",
    `- Research documents: \`${data.projectDir}/research/\``,
    `- Decisions: \`${data.projectDir}/decisions/\``,
    "",
    "After creating an artifact file, register it with `project-save-artifact`.",
  ]

  if (data.worktreePath) {
    parts.push(
      "",
      "## Worktree",
      "",
      `You are working in an isolated worktree at: ${data.worktreePath}`,
      "Make all your changes there."
    )
  }

  if (data.hasReviewers) {
    parts.push(
      "",
      "## Note",
      "",
      "Other agents will review your work. Focus on quality implementation."
    )
  }

  parts.push(delegationConstraints({}))

  return lines(...parts)
}

function renderReviewer(data: ReviewerMemberData): string {
  const parts: string[] = [
    `# Review Task: ${data.issueId}`,
    "",
    `You are a REVIEWER for this task. Your role: ${data.agent}`,
    "",
    "## Issue",
    "",
    data.issueContext,
    "",
    "## Primary Agent's Work",
    "",
    `The primary agent (${data.primaryAgent}) is implementing this. Your job is to:`,
    "1. Review their approach and implementation",
    "2. Identify BLOCKING issues and non-blocking concerns separately",
    "3. Provide constructive feedback",
  ]

  if (data.isConcurrent === true) {
    parts.push(
      "",
      "## Timing Note",
      "",
      "The primary agent is working concurrently. Before reviewing any code or implementation,",
      "first check the worktree for changes. If no changes are present yet, the primary is still",
      "working — focus on asking clarifying questions or reviewing the issue description until",
      "changes appear."
    )
  }

  parts.push(
    "",
    "## What Constitutes a Blocker",
    "",
    "**BLOCKERS** (request changes for these):",
    "- Bugs or incorrect logic in the implementation",
    "- Missing critical functionality the issue explicitly requires",
    "- Approach that will break integration with existing systems",
    "- Security or data loss risk",
    "",
    "**NOT BLOCKERS** (note as concerns, not blockers):",
    "- Stylistic preferences",
    "- Minor ambiguities a developer can resolve",
    "- Suboptimal approach (if it works and isn't harmful)",
    "- Nice-to-have improvements",
    "",
    "## Output Format",
    "",
    "Structure your response with:",
    "",
    "#### Blockers (if any)",
    "- [Specific blocker + what needs to change]",
    "",
    "#### Concerns (non-blocking)",
    "- [Specific concerns that don't block work]",
    "",
    "#### Verdict",
    "**APPROVE** or **REQUEST CHANGES** (only if blockers exist)",
    "",
    "## Project Context",
    "",
    `**Project directory:** ${data.projectDir}`,
    "",
    "You can read artifacts from the project directory:",
    `- Research documents: \`${data.projectDir}/research/\``,
    `- Decisions: \`${data.projectDir}/decisions/\``,
  )

  if (data.worktreePath) {
    parts.push(
      "",
      "## Worktree",
      "",
      `The code is in an isolated worktree at: ${data.worktreePath}`,
      "You can read files there to review the implementation.",
      readOnlyConstraints({})
    )
  }

  if (data.role === "devilsAdvocate") {
    parts.push("", devilsAdvocateTemplate.render({}))
  }

  parts.push(delegationConstraints({}))

  return lines(...parts)
}
