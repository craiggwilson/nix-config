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
  /** Issue ID being worked on */
  issueId: string
  /** Full issue context (title, description, etc.) */
  issueContext: string
  /** Path to isolated worktree, if any */
  worktreePath?: string
  /** Whether there are other team members reviewing */
  hasReviewers: boolean
}

/**
 * Data for reviewer team member prompt
 */
export interface ReviewerMemberData {
  role: "reviewer" | "devilsAdvocate"
  /** Agent type/name */
  agent: string
  /** Issue ID being worked on */
  issueId: string
  /** Full issue context (title, description, etc.) */
  issueContext: string
  /** Path to isolated worktree, if any */
  worktreePath?: string
  /** Name of the primary agent doing implementation */
  primaryAgent: string
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
    "2. Identify issues, risks, or improvements",
    "3. Provide constructive feedback",
  ]

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
