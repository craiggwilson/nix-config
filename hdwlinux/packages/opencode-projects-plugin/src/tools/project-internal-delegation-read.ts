/**
 * project-internal-delegation-read tool - Read delegation results
 *
 * Retrieves the result of a completed delegation by ID.
 * Useful after session compaction when delegation notifications
 * may have been lost.
 */

import { tool } from "@opencode-ai/plugin"
import * as fs from "node:fs/promises"
import * as path from "node:path"

import type { ToolDepsV2, ProjectToolContext } from "../core/types.js"

interface DelegationReadArgs {
  id: string
  projectId?: string
}

/**
 * Create the project-internal-delegation-read tool
 */
export function createDelegationRead(deps: ToolDepsV2) {
  const { projectManager, log } = deps

  return tool({
    description: `Read the result of a delegation by ID.

Use this to retrieve delegation results after session compaction,
or to review what a background delegation accomplished.

Returns the full delegation result including metadata, prompt, and output.`,

    args: {
      id: tool.schema.string().describe("Delegation ID (e.g., 'del-abc123')"),
      projectId: tool.schema
        .string()
        .optional()
        .describe("Project ID (default: focused project)"),
    },

    async execute(args: DelegationReadArgs, _ctx: ProjectToolContext): Promise<string> {
      const { id } = args

      const projectId = args.projectId || projectManager.getFocusedProjectId()

      if (!projectId) {
        return "No project specified and no project is currently focused.\n\nUse `project-focus(projectId)` to set context, or provide projectId explicitly."
      }

      const projectDir = await projectManager.getProjectDir(projectId)
      if (!projectDir) {
        return `Project '${projectId}' not found.`
      }

      await log.info(`Reading delegation ${id} from project ${projectId}`)

      // Try to read the JSON file first for structured data
      const jsonPath = path.join(projectDir, "delegations", `${id}.json`)
      const mdPath = path.join(projectDir, "delegations", `${id}.md`)

      try {
        const jsonContent = await fs.readFile(jsonPath, "utf8")
        const delegation = JSON.parse(jsonContent)

        const lines: string[] = []

        lines.push(`## Delegation: ${id}`)
        lines.push("")

        if (delegation.title) {
          lines.push(`### ${delegation.title}`)
          lines.push("")
        }

        if (delegation.description) {
          lines.push(`> ${delegation.description}`)
          lines.push("")
        }

        lines.push("### Metadata")
        lines.push("")
        lines.push(`- **Issue:** ${delegation.issueId}`)
        lines.push(`- **Status:** ${delegation.status}`)
        lines.push(`- **Started:** ${delegation.startedAt}`)
        lines.push(`- **Completed:** ${delegation.completedAt || "N/A"}`)

        if (delegation.agent) {
          lines.push(`- **Agent:** ${delegation.agent}`)
        }

        if (delegation.worktreePath) {
          lines.push(`- **Worktree:** ${delegation.worktreePath}`)
        }

        lines.push("")
        lines.push("### Prompt")
        lines.push("")
        lines.push("```")
        lines.push(delegation.prompt)
        lines.push("```")
        lines.push("")

        if (delegation.result) {
          lines.push("### Result")
          lines.push("")
          lines.push(delegation.result)
          lines.push("")
        }

        if (delegation.error) {
          lines.push("### Error")
          lines.push("")
          lines.push("```")
          lines.push(delegation.error)
          lines.push("```")
          lines.push("")
        }

        if (delegation.status === "running") {
          lines.push("---")
          lines.push("")
          lines.push("**Note:** This delegation is still running. You will be notified when it completes.")
        }

        return lines.join("\n")
      } catch {
        // JSON not found, try markdown
      }

      try {
        const mdContent = await fs.readFile(mdPath, "utf8")
        return mdContent
      } catch {
        // Neither found
      }

      return `Delegation '${id}' not found in project '${projectId}'.

Possible reasons:
- The delegation ID is incorrect
- The delegation was created in a different project
- The delegation has not been persisted yet (still running)

Use \`project-status\` to see active delegations.`
    },
  })
}
