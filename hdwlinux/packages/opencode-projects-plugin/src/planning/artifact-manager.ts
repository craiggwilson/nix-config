/**
 * ArtifactManager - Handles generating and managing planning artifacts
 *
 * Artifacts are markdown documents generated during planning:
 * - roadmap.md: Milestones, timeline, and deliverables
 * - architecture.md: System overview, components, technology choices
 * - risks.md: Identified risks, impact assessment, mitigations
 * - success-criteria.md: KPIs, metrics, acceptance criteria
 * - resources.md: Team, budget, dependencies
 */

import * as fs from "node:fs/promises"
import * as path from "node:path"

/**
 * Artifact types
 */
export type ArtifactType =
  | "roadmap"
  | "architecture"
  | "risks"
  | "success-criteria"
  | "resources"

/**
 * Artifact metadata
 */
export interface ArtifactMetadata {
  type: ArtifactType
  exists: boolean
  path: string
  lastModified?: string
  size?: number
}

/**
 * Roadmap milestone
 */
export interface Milestone {
  name: string
  description?: string
  targetDate?: string
  deliverables: string[]
  dependencies?: string[]
  status?: "planned" | "in_progress" | "completed"
}

/**
 * Roadmap artifact content
 */
export interface RoadmapContent {
  vision: string
  milestones: Milestone[]
  timeline?: string
  assumptions?: string[]
  constraints?: string[]
}

/**
 * Architecture component
 */
export interface ArchitectureComponent {
  name: string
  description: string
  technology?: string
  responsibilities: string[]
  dependencies?: string[]
}

/**
 * Architecture artifact content
 */
export interface ArchitectureContent {
  overview: string
  components: ArchitectureComponent[]
  decisions?: Array<{
    title: string
    decision: string
    rationale: string
    alternatives?: string[]
  }>
  diagrams?: string[]
}

/**
 * Risk entry
 */
export interface Risk {
  id: string
  title: string
  description: string
  likelihood: "low" | "medium" | "high"
  impact: "low" | "medium" | "high"
  mitigation: string
  owner?: string
  status?: "identified" | "mitigating" | "resolved" | "accepted"
}

/**
 * Risks artifact content
 */
export interface RisksContent {
  summary: string
  risks: Risk[]
}

/**
 * Success criterion
 */
export interface SuccessCriterion {
  name: string
  description: string
  metric?: string
  target?: string
  measurement?: string
}

/**
 * Success criteria artifact content
 */
export interface SuccessCriteriaContent {
  overview: string
  criteria: SuccessCriterion[]
  acceptanceCriteria?: string[]
}

/**
 * ArtifactManager - manages planning artifacts
 */
export class ArtifactManager {
  private projectDir: string
  private plansDir: string

  constructor(projectDir: string) {
    this.projectDir = projectDir
    this.plansDir = path.join(projectDir, "plans")
  }

  /**
   * List all artifacts and their status
   */
  async listArtifacts(): Promise<ArtifactMetadata[]> {
    const types: ArtifactType[] = [
      "roadmap",
      "architecture",
      "risks",
      "success-criteria",
      "resources",
    ]

    const artifacts: ArtifactMetadata[] = []

    for (const type of types) {
      const filePath = path.join(this.plansDir, `${type}.md`)
      let exists = false
      let lastModified: string | undefined
      let size: number | undefined

      try {
        const stat = await fs.stat(filePath)
        exists = true
        lastModified = stat.mtime.toISOString()
        size = stat.size
      } catch {

      }

      artifacts.push({
        type,
        exists,
        path: filePath,
        lastModified,
        size,
      })
    }

    return artifacts
  }

  /**
   * Check if an artifact exists
   */
  async artifactExists(type: ArtifactType): Promise<boolean> {
    try {
      await fs.access(path.join(this.plansDir, `${type}.md`))
      return true
    } catch {
      return false
    }
  }

  /**
   * Read an artifact's raw content
   */
  async readArtifact(type: ArtifactType): Promise<string | null> {
    try {
      const filePath = path.join(this.plansDir, `${type}.md`)
      return await fs.readFile(filePath, "utf8")
    } catch {
      return null
    }
  }

  /**
   * Write an artifact
   */
  async writeArtifact(type: ArtifactType, content: string): Promise<void> {
    await fs.mkdir(this.plansDir, { recursive: true })
    const filePath = path.join(this.plansDir, `${type}.md`)
    await fs.writeFile(filePath, content, "utf8")
  }

  /**
   * Generate a roadmap artifact from structured content
   */
  async generateRoadmap(content: RoadmapContent): Promise<string> {
    const lines: string[] = []

    lines.push("# Roadmap")
    lines.push("")
    lines.push("## Vision")
    lines.push("")
    lines.push(content.vision)
    lines.push("")

    if (content.timeline) {
      lines.push("## Timeline")
      lines.push("")
      lines.push(content.timeline)
      lines.push("")
    }

    lines.push("## Milestones")
    lines.push("")

    for (const milestone of content.milestones) {
      const statusIcon =
        milestone.status === "completed"
          ? "✅"
          : milestone.status === "in_progress"
            ? "🔄"
            : "⬜"

      lines.push(`### ${statusIcon} ${milestone.name}`)
      lines.push("")

      if (milestone.targetDate) {
        lines.push(`**Target Date:** ${milestone.targetDate}`)
        lines.push("")
      }

      if (milestone.description) {
        lines.push(milestone.description)
        lines.push("")
      }

      if (milestone.deliverables.length > 0) {
        lines.push("**Deliverables:**")
        for (const deliverable of milestone.deliverables) {
          lines.push(`- ${deliverable}`)
        }
        lines.push("")
      }

      if (milestone.dependencies && milestone.dependencies.length > 0) {
        lines.push(`**Dependencies:** ${milestone.dependencies.join(", ")}`)
        lines.push("")
      }
    }

    if (content.assumptions && content.assumptions.length > 0) {
      lines.push("## Assumptions")
      lines.push("")
      for (const assumption of content.assumptions) {
        lines.push(`- ${assumption}`)
      }
      lines.push("")
    }

    if (content.constraints && content.constraints.length > 0) {
      lines.push("## Constraints")
      lines.push("")
      for (const constraint of content.constraints) {
        lines.push(`- ${constraint}`)
      }
      lines.push("")
    }

    lines.push("---")
    lines.push("")
    lines.push(`*Generated: ${new Date().toISOString()}*`)

    const markdown = lines.join("\n")
    await this.writeArtifact("roadmap", markdown)
    return markdown
  }

  /**
   * Generate an architecture artifact from structured content
   */
  async generateArchitecture(content: ArchitectureContent): Promise<string> {
    const lines: string[] = []

    lines.push("# Architecture")
    lines.push("")
    lines.push("## Overview")
    lines.push("")
    lines.push(content.overview)
    lines.push("")

    lines.push("## Components")
    lines.push("")

    for (const component of content.components) {
      lines.push(`### ${component.name}`)
      lines.push("")
      lines.push(component.description)
      lines.push("")

      if (component.technology) {
        lines.push(`**Technology:** ${component.technology}`)
        lines.push("")
      }

      if (component.responsibilities.length > 0) {
        lines.push("**Responsibilities:**")
        for (const resp of component.responsibilities) {
          lines.push(`- ${resp}`)
        }
        lines.push("")
      }

      if (component.dependencies && component.dependencies.length > 0) {
        lines.push(`**Dependencies:** ${component.dependencies.join(", ")}`)
        lines.push("")
      }
    }

    if (content.decisions && content.decisions.length > 0) {
      lines.push("## Architecture Decisions")
      lines.push("")

      for (const decision of content.decisions) {
        lines.push(`### ${decision.title}`)
        lines.push("")
        lines.push(`**Decision:** ${decision.decision}`)
        lines.push("")
        lines.push(`**Rationale:** ${decision.rationale}`)
        lines.push("")

        if (decision.alternatives && decision.alternatives.length > 0) {
          lines.push("**Alternatives Considered:**")
          for (const alt of decision.alternatives) {
            lines.push(`- ${alt}`)
          }
          lines.push("")
        }
      }
    }

    if (content.diagrams && content.diagrams.length > 0) {
      lines.push("## Diagrams")
      lines.push("")
      for (const diagram of content.diagrams) {
        lines.push(diagram)
        lines.push("")
      }
    }

    lines.push("---")
    lines.push("")
    lines.push(`*Generated: ${new Date().toISOString()}*`)

    const markdown = lines.join("\n")
    await this.writeArtifact("architecture", markdown)
    return markdown
  }

  /**
   * Generate a risks artifact from structured content
   */
  async generateRisks(content: RisksContent): Promise<string> {
    const lines: string[] = []

    lines.push("# Risk Assessment")
    lines.push("")
    lines.push("## Summary")
    lines.push("")
    lines.push(content.summary)
    lines.push("")


    const highRisks = content.risks.filter(
      (r) => r.likelihood === "high" || r.impact === "high"
    )
    const mediumRisks = content.risks.filter(
      (r) =>
        r.likelihood === "medium" &&
        r.impact === "medium" &&
        !highRisks.includes(r)
    )

    lines.push("## Risk Overview")
    lines.push("")
    lines.push(`| Severity | Count |`)
    lines.push(`|----------|-------|`)
    lines.push(`| High | ${highRisks.length} |`)
    lines.push(`| Medium | ${mediumRisks.length} |`)
    lines.push(`| Low | ${content.risks.length - highRisks.length - mediumRisks.length} |`)
    lines.push("")

    lines.push("## Identified Risks")
    lines.push("")

    for (const risk of content.risks) {
      const severityIcon =
        risk.likelihood === "high" || risk.impact === "high"
          ? "🔴"
          : risk.likelihood === "medium" || risk.impact === "medium"
            ? "🟡"
            : "🟢"

      lines.push(`### ${severityIcon} ${risk.id}: ${risk.title}`)
      lines.push("")
      lines.push(risk.description)
      lines.push("")
      lines.push(`| Attribute | Value |`)
      lines.push(`|-----------|-------|`)
      lines.push(`| Likelihood | ${risk.likelihood} |`)
      lines.push(`| Impact | ${risk.impact} |`)
      lines.push(`| Status | ${risk.status || "identified"} |`)
      if (risk.owner) {
        lines.push(`| Owner | ${risk.owner} |`)
      }
      lines.push("")
      lines.push(`**Mitigation:** ${risk.mitigation}`)
      lines.push("")
    }

    lines.push("---")
    lines.push("")
    lines.push(`*Generated: ${new Date().toISOString()}*`)

    const markdown = lines.join("\n")
    await this.writeArtifact("risks", markdown)
    return markdown
  }

  /**
   * Generate a success criteria artifact from structured content
   */
  async generateSuccessCriteria(content: SuccessCriteriaContent): Promise<string> {
    const lines: string[] = []

    lines.push("# Success Criteria")
    lines.push("")
    lines.push("## Overview")
    lines.push("")
    lines.push(content.overview)
    lines.push("")

    lines.push("## Key Performance Indicators")
    lines.push("")

    for (const criterion of content.criteria) {
      lines.push(`### ${criterion.name}`)
      lines.push("")
      lines.push(criterion.description)
      lines.push("")

      if (criterion.metric || criterion.target) {
        lines.push(`| Attribute | Value |`)
        lines.push(`|-----------|-------|`)
        if (criterion.metric) {
          lines.push(`| Metric | ${criterion.metric} |`)
        }
        if (criterion.target) {
          lines.push(`| Target | ${criterion.target} |`)
        }
        if (criterion.measurement) {
          lines.push(`| Measurement | ${criterion.measurement} |`)
        }
        lines.push("")
      }
    }

    if (content.acceptanceCriteria && content.acceptanceCriteria.length > 0) {
      lines.push("## Acceptance Criteria")
      lines.push("")
      for (const criterion of content.acceptanceCriteria) {
        lines.push(`- [ ] ${criterion}`)
      }
      lines.push("")
    }

    lines.push("---")
    lines.push("")
    lines.push(`*Generated: ${new Date().toISOString()}*`)

    const markdown = lines.join("\n")
    await this.writeArtifact("success-criteria", markdown)
    return markdown
  }
}
