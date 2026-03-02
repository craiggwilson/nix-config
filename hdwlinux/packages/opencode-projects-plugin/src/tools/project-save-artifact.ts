/**
 * project-save-artifact tool - Register an artifact in the project registry
 */

import * as path from "node:path"

import { tool } from "@opencode-ai/plugin"

import type { ProjectManager } from "../projects/index.js"
import type { Logger } from "../utils/opencode-sdk/index.js"
import { formatError } from "../utils/errors/index.js"
import {
  ProjectSaveArtifactArgsSchema,
  validateToolArgs,
  formatValidationError,
} from "../utils/validation/index.js"
import type { ProjectToolContext, Tool } from "./tools.js"

/**
 * Creates the project-save-artifact tool for registering artifacts in the project registry.
 * Gets the ArtifactRegistry from ProjectManager at execution time since registries are per-project.
 */
export function createProjectSaveArtifact(
  projectManager: ProjectManager,
  log: Logger,
): Tool {
  return tool({
    description: `Register an artifact in the project registry.

Use this to track artifacts produced during the project:
- Research documents
- Deliverables (code, documentation)
- Planning documents (architecture, roadmaps)

Artifacts are linked to their source issue and session for traceability.
The artifact file must already exist at the specified path.`,

    args: {
      title: tool.schema.string().describe("Artifact title"),
      type: tool.schema
        .string()
        .describe("Artifact type (e.g., 'research', 'deliverable', 'documentation')"),
      path: tool.schema
        .string()
        .describe("Path to the artifact file (relative to workspace or absolute)"),
      summary: tool.schema.string().optional().describe("Brief description of the artifact"),
      sourceIssue: tool.schema.string().optional().describe("Issue ID that produced this artifact"),
      projectId: tool.schema.string().optional().describe("Project ID (defaults to focused project)"),
    },

    async execute(args: unknown, ctx: ProjectToolContext): Promise<string> {
      const validationResult = validateToolArgs(ProjectSaveArtifactArgsSchema, args)
      if (!validationResult.ok) {
        return formatValidationError(validationResult.error)
      }

      const { title, type, path: artifactPath, summary, sourceIssue, projectId } = validationResult.value

      const effectiveProjectId = projectId || projectManager.getFocusedProjectId()
      if (!effectiveProjectId) {
        return "No project focused. Use `project-focus(projectId)` first or specify projectId."
      }

      const projectDir = await projectManager.getProjectDir(effectiveProjectId)
      if (!projectDir) {
        return `Project not found: ${effectiveProjectId}`
      }

      const artifactRegistry = await projectManager.getArtifactRegistry(effectiveProjectId)
      if (!artifactRegistry) {
        return `Could not get artifact registry for project: ${effectiveProjectId}`
      }

      await log.info(`Saving artifact: ${title} (${type})`)

      // Resolve paths - determine if absolute or relative
      const isAbsolute = path.isAbsolute(artifactPath)
      const absolutePath = isAbsolute ? artifactPath : path.resolve(process.cwd(), artifactPath)

      // Determine if external (outside projectDir)
      const normalizedProjectDir = path.normalize(projectDir)
      const normalizedAbsolutePath = path.normalize(absolutePath)
      const external = !normalizedAbsolutePath.startsWith(normalizedProjectDir + path.sep) &&
        normalizedAbsolutePath !== normalizedProjectDir

      // Calculate relative path for storage
      let relativePath: string
      if (external) {
        // For external files, store path relative to workspace (cwd)
        relativePath = path.relative(process.cwd(), absolutePath)
      } else {
        // For internal files, store path relative to projectDir
        relativePath = path.relative(projectDir, absolutePath)
      }

      // Get current session ID from context if available
      const sessionId = (ctx as { sessionId?: string }).sessionId

      const result = await artifactRegistry.register({
        type,
        title,
        path: relativePath,
        absolutePath,
        external,
        sourceIssue,
        sourceSession: sessionId,
        summary,
      })

      if (!result.ok) {
        return formatError(result.error)
      }

      const artifact = result.value

      const lines: string[] = [
        `## Artifact Registered: ${artifact.title}`,
        "",
        `**ID:** ${artifact.id}`,
        `**Type:** ${artifact.type}`,
        `**Path:** ${artifact.path}`,
        `**External:** ${artifact.external ? "Yes (outside project directory)" : "No"}`,
      ]

      if (artifact.sourceIssue) {
        lines.push(`**Source Issue:** ${artifact.sourceIssue}`)
      }

      if (artifact.summary) {
        lines.push("")
        lines.push("### Summary")
        lines.push(artifact.summary)
      }

      return lines.join("\n")
    },
  })
}
