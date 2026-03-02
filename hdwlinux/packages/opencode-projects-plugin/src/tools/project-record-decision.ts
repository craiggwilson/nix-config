/**
 * project-record-decision tool - Record a decision with rationale and alternatives
 */

import { tool } from "@opencode-ai/plugin"

import type { ProjectManager } from "../projects/index.js"
import type { Logger } from "../utils/opencode-sdk/index.js"
import { formatError } from "../utils/errors/index.js"
import {
  ProjectRecordDecisionArgsSchema,
  validateToolArgs,
  formatValidationError,
} from "../utils/validation/index.js"
import type { ProjectToolContext, Tool } from "./tools.js"

/**
 * Creates the project-record-decision tool for recording decisions with rationale.
 * Gets the DecisionManager from ProjectManager at execution time since managers are per-project.
 */
export function createProjectRecordDecision(
  projectManager: ProjectManager,
  log: Logger,
): Tool {
  return tool({
    description: `Record a decision with rationale and alternatives considered.

Decisions are immutable once recorded. Use this to:
- Document architectural choices
- Record technology selections
- Capture design decisions with their reasoning

The decision will be linked to the current session and any specified research.`,

    args: {
      title: tool.schema.string().describe("Decision title (e.g., 'Use OAuth2 over SAML')"),
      decision: tool.schema.string().describe("What was decided"),
      rationale: tool.schema.string().describe("Why this decision was made"),
      status: tool.schema
        .enum(["proposed", "decided", "rejected", "deferred"])
        .optional()
        .describe("Decision status (default: 'decided')"),
      alternatives: tool.schema
        .array(
          tool.schema.object({
            name: tool.schema.string(),
            description: tool.schema.string(),
            whyRejected: tool.schema.string().optional(),
          }),
        )
        .optional()
        .describe("Alternatives that were considered"),
      sourceResearch: tool.schema
        .array(tool.schema.string())
        .optional()
        .describe("Research artifact IDs that informed this decision"),
      relatedIssues: tool.schema
        .array(tool.schema.string())
        .optional()
        .describe("Related issue IDs"),
      projectId: tool.schema.string().optional().describe("Project ID (defaults to focused project)"),
    },

    async execute(args: unknown, ctx: ProjectToolContext): Promise<string> {
      const validationResult = validateToolArgs(ProjectRecordDecisionArgsSchema, args)
      if (!validationResult.ok) {
        return formatValidationError(validationResult.error)
      }

      const { title, decision, rationale, status, alternatives, sourceResearch, relatedIssues, projectId } =
        validationResult.value

      const effectiveProjectId = projectId || projectManager.getFocusedProjectId()
      if (!effectiveProjectId) {
        return "No project focused. Use `project-focus(projectId)` first or specify projectId."
      }

      const decisionManager = await projectManager.getDecisionManager(effectiveProjectId)
      if (!decisionManager) {
        return `Could not get decision manager for project: ${effectiveProjectId}`
      }

      await log.info(`Recording decision: ${title}`)

      const sessionId = (ctx as { sessionId?: string }).sessionId

      const result = await decisionManager.recordDecision({
        title,
        decision,
        rationale,
        status,
        alternatives,
        sourceSession: sessionId,
        sourceResearch,
        relatedIssues,
      })

      if (!result.ok) {
        return formatError(result.error)
      }

      const record = result.value

      const lines: string[] = [
        `## Decision Recorded: ${record.title}`,
        "",
        `**ID:** ${record.id}`,
        `**Status:** ${record.status}`,
        `**File:** ${record.filename}`,
        "",
        "### Decision",
        record.decision,
        "",
        "### Rationale",
        record.rationale,
      ]

      if (record.alternatives && record.alternatives.length > 0) {
        lines.push("")
        lines.push("### Alternatives Considered")
        for (const alt of record.alternatives) {
          lines.push(`- **${alt.name}**: ${alt.description}`)
          if (alt.whyRejected) {
            lines.push(`  - *Why rejected:* ${alt.whyRejected}`)
          }
        }
      }

      return lines.join("\n")
    },
  })
}
