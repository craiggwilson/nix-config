/**
 * DecisionManager - Manages decision records with status tracking
 *
 * Decision records capture architectural and design decisions made during
 * project work, providing a historical record of choices and their rationale.
 * Each decision includes the decision itself, rationale, alternatives considered,
 * and links to related research and issues.
 *
 * The decision index provides a table of contents organized by status:
 * pending decisions needing resolution, decided records, and superseded
 * decisions that have been replaced.
 *
 * State is persisted to `decisions/` within the project directory:
 * - `decisions/index.md` - TOC with pending and decided entries
 * - `decisions/{date}-{slug}.md` - Individual decision records
 *
 * @module decisions
 */

import * as fs from "node:fs/promises"
import * as path from "node:path"

import type { ArtifactRegistry } from "../artifacts/index.js"
import type { Logger } from "../utils/opencode-sdk/index.js"
import { ok, err, type Result } from "../utils/result/index.js"

/**
 * Lifecycle states for a decision record.
 *
 * - proposed: Under consideration, not yet decided
 * - decided: Final decision made
 * - rejected: Explicitly rejected (not chosen)
 * - deferred: Postponed for later consideration
 * - superseded: Replaced by a newer decision
 */
export type DecisionStatus = "proposed" | "decided" | "rejected" | "deferred" | "superseded"

/**
 * Represents an alternative that was considered but not chosen.
 */
export interface Alternative {
  /** Name of the alternative approach */
  name: string
  /** Description of what this alternative entails */
  description: string
  /** Explanation of why this alternative was not chosen */
  whyRejected?: string
}

/**
 * Represents a recorded decision with its metadata and rationale.
 *
 * Decision records are identified by their artifact ID from the registry.
 */
export interface DecisionRecord {
  /** Artifact ID from registry */
  id: string
  /** URL-friendly slug derived from title */
  slug: string
  /** The markdown filename (e.g., "2026-03-02-oauth2-over-saml.md") */
  filename: string
  /** Human-readable decision title */
  title: string
  /** Current status of the decision */
  status: DecisionStatus
  /** What was decided */
  decision: string
  /** Why this decision was made */
  rationale: string
  /** Alternatives that were considered */
  alternatives?: Alternative[]
  /** Session identifier where this decision was made */
  sourceSession?: string
  /** Research artifact IDs that informed this decision */
  sourceResearch?: string[]
  /** Related issue IDs */
  relatedIssues?: string[]
  /** ISO timestamp when the decision was created */
  createdAt: string
  /** ISO timestamp when the decision was last updated */
  updatedAt: string
  /** ID of the decision that supersedes this one */
  supersededBy?: string
}

/**
 * Represents a decision that needs to be made.
 *
 * Pending decisions track questions that are blocking progress and
 * need resolution before work can continue.
 */
export interface PendingDecision {
  /** The question that needs to be decided */
  question: string
  /** Additional context for the decision */
  context?: string
  /** What this decision is blocking (issue IDs or descriptions) */
  blocking?: string[]
  /** Research artifact IDs that might inform this decision */
  relatedResearch?: string[]
}

/**
 * Persisted state for the decision index.
 *
 * Organizes decisions by status for easy navigation.
 */
export interface DecisionIndex {
  /** Decisions needing resolution */
  pending: PendingDecision[]
  /** Decided records, sorted alphabetically by title */
  decided: DecisionRecord[]
  /** Superseded decisions that have been replaced */
  superseded: DecisionRecord[]
}

/**
 * Error types for decision operations.
 *
 * Uses discriminated unions for type-safe error handling.
 */
export type DecisionError =
  | { type: "already_exists"; title: string }
  | { type: "not_found"; id: string }
  | { type: "invalid_transition"; from: DecisionStatus; to: DecisionStatus }
  | { type: "persistence_failed"; message: string }

/**
 * Options for recording a new decision.
 *
 * The `id`, `slug`, `filename`, `createdAt`, and `updatedAt` fields are
 * generated automatically.
 */
export interface RecordDecisionOptions {
  /** Human-readable decision title */
  title: string
  /** What was decided */
  decision: string
  /** Why this decision was made */
  rationale: string
  /** Current status (defaults to "decided") */
  status?: DecisionStatus
  /** Alternatives that were considered */
  alternatives?: Alternative[]
  /** Session identifier where this decision was made */
  sourceSession?: string
  /** Research artifact IDs that informed this decision */
  sourceResearch?: string[]
  /** Related issue IDs */
  relatedIssues?: string[]
}

/**
 * Valid status transitions for decision records.
 *
 * Maps current status to allowed next statuses.
 */
const VALID_TRANSITIONS: Record<DecisionStatus, DecisionStatus[]> = {
  proposed: ["decided", "rejected", "deferred"],
  decided: ["superseded"],
  rejected: ["proposed"], // Can be reconsidered
  deferred: ["proposed", "decided", "rejected"],
  superseded: [], // Terminal state
}

/**
 * Manages decision records for a project.
 *
 * The DecisionManager maintains an index of all decisions made during
 * project work, organized by status. It tracks pending decisions that
 * need resolution and provides a historical record of choices made.
 *
 * @example
 * ```typescript
 * const manager = new DecisionManager("/path/to/project", artifactRegistry, logger)
 * const index = await manager.load()
 *
 * const result = await manager.recordDecision({
 *   title: "OAuth2 over SAML",
 *   decision: "Use OAuth2 with PKCE instead of SAML for authentication",
 *   rationale: "Better mobile support and simpler implementation",
 *   alternatives: [
 *     { name: "SAML", description: "Enterprise SSO standard", whyRejected: "Poor mobile support" }
 *   ],
 *   sourceResearch: ["research-auth-patterns-abc123"]
 * })
 *
 * if (result.ok) {
 *   console.log("Recorded decision:", result.value.id)
 * }
 * ```
 */
export class DecisionManager {
  /** Path to the project directory */
  private projectDir: string
  /** Artifact registry for tracking decision artifacts */
  private artifactRegistry: ArtifactRegistry
  /** Logger for tracking decision operations */
  private log: Logger
  /** In-memory decision index, loaded from disk */
  private index: DecisionIndex

  /**
   * Creates a new DecisionManager for a specific project.
   *
   * Call `load()` before using other methods to initialize state from disk.
   *
   * @param projectDir - Absolute path to the project directory
   * @param artifactRegistry - Registry for tracking artifacts
   * @param log - Logger instance for operation tracking
   */
  constructor(projectDir: string, artifactRegistry: ArtifactRegistry, log: Logger) {
    this.projectDir = projectDir
    this.artifactRegistry = artifactRegistry
    this.log = log
    this.index = { pending: [], decided: [], superseded: [] }
  }

  /**
   * Resolves the path to the decisions directory.
   */
  private getDecisionsDir(): string {
    return path.join(this.projectDir, "decisions")
  }

  /**
   * Resolves the path to the decision index file.
   */
  private getIndexPath(): string {
    return path.join(this.getDecisionsDir(), "index.md")
  }

  /**
   * Ensures the decisions directory exists.
   */
  private async ensureDecisionsDir(): Promise<void> {
    const decisionsDir = this.getDecisionsDir()
    await fs.mkdir(decisionsDir, { recursive: true })
  }

  /**
   * Generates a slug from a title for use in filenames.
   *
   * @param title - The title to slugify
   * @returns Lowercase, hyphenated slug
   */
  private slugify(title: string): string {
    return title
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-|-$/g, "")
      .slice(0, 50)
  }

  /**
   * Loads the decision index from disk.
   *
   * Parses the index.md file to reconstruct the DecisionIndex structure.
   * Creates an empty index if the file doesn't exist.
   *
   * @returns The loaded decision index
   */
  async load(): Promise<DecisionIndex> {
    const indexPath = this.getIndexPath()

    try {
      const content = await fs.readFile(indexPath, "utf-8")
      this.index = this.parseIndexFile(content)
      const totalDecisions = this.index.decided.length + this.index.superseded.length
      await this.log.debug(
        `Loaded ${totalDecisions} decisions and ${this.index.pending.length} pending from index`
      )
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code === "ENOENT") {
        this.index = { pending: [], decided: [], superseded: [] }
        await this.log.debug("No existing decision index, starting fresh")
      } else {
        throw error
      }
    }

    return this.index
  }

  /**
   * Persists the decision index to disk.
   *
   * Writes the index.md file with the current state.
   *
   * @param index - The index to persist
   */
  async save(index: DecisionIndex): Promise<void> {
    await this.ensureDecisionsDir()
    const indexPath = this.getIndexPath()
    const content = this.formatIndexFile(index)
    await fs.writeFile(indexPath, content)
    this.index = index
    const totalDecisions = index.decided.length + index.superseded.length
    await this.log.debug(
      `Saved decision index with ${totalDecisions} decisions and ${index.pending.length} pending`
    )
  }

  /**
   * Records a new decision.
   *
   * Writes the decision document to the decisions directory, registers it
   * in the artifact registry, and updates the index. Returns an error if
   * a decision with the same title already exists.
   *
   * @param options - Decision recording options
   * @returns The recorded decision, or an error
   */
  async recordDecision(
    options: RecordDecisionOptions
  ): Promise<Result<DecisionRecord, DecisionError>> {
    // Check for duplicate title
    const existingDecided = this.index.decided.find(
      (d) => d.title.toLowerCase() === options.title.toLowerCase()
    )
    const existingSuperseded = this.index.superseded.find(
      (d) => d.title.toLowerCase() === options.title.toLowerCase()
    )
    if (existingDecided || existingSuperseded) {
      return err({ type: "already_exists", title: options.title })
    }

    const now = new Date()
    const date = now.toISOString().split("T")[0]
    const timestamp = now.toISOString()
    const slug = this.slugify(options.title)
    const filename = `${date}-${slug}.md`
    const decisionsDir = this.getDecisionsDir()
    const absolutePath = path.join(decisionsDir, filename)
    const relativePath = path.relative(this.projectDir, absolutePath)
    const status = options.status ?? "decided"

    try {
      // Ensure directory exists
      await this.ensureDecisionsDir()

      // Register in artifact registry first to get the ID
      const artifactResult = await this.artifactRegistry.register({
        type: "decision",
        title: options.title,
        path: relativePath,
        absolutePath,
        external: false,
        sourceSession: options.sourceSession,
        summary: options.decision,
      })

      if (!artifactResult.ok) {
        return err({
          type: "persistence_failed",
          message: `Failed to register artifact: ${artifactResult.error.type}`,
        })
      }

      const record: DecisionRecord = {
        id: artifactResult.value.id,
        slug,
        filename,
        title: options.title,
        status,
        decision: options.decision,
        rationale: options.rationale,
        alternatives: options.alternatives,
        sourceSession: options.sourceSession,
        sourceResearch: options.sourceResearch,
        relatedIssues: options.relatedIssues,
        createdAt: timestamp,
        updatedAt: timestamp,
      }

      // Write the decision document
      const content = this.formatDecisionFile(record)
      await fs.writeFile(absolutePath, content)

      // Add to appropriate list based on status
      if (status === "superseded") {
        this.index.superseded.push(record)
        this.index.superseded.sort((a, b) => a.title.localeCompare(b.title))
      } else {
        this.index.decided.push(record)
        this.index.decided.sort((a, b) => a.title.localeCompare(b.title))
      }

      // Save the updated index
      await this.save(this.index)

      await this.log.info(`Recorded decision: ${record.id} (${record.title})`)
      return ok(record)
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error)
      return err({ type: "persistence_failed", message })
    }
  }

  /**
   * Updates the status of an existing decision.
   *
   * Validates that the transition is allowed and updates both the decision
   * file and the index. When superseding, the supersededBy field is set.
   *
   * @param id - Decision ID to update
   * @param status - New status
   * @param supersededBy - ID of the decision that supersedes this one (required for superseded status)
   * @returns The updated decision record, or an error
   */
  async updateStatus(
    id: string,
    status: DecisionStatus,
    supersededBy?: string
  ): Promise<Result<DecisionRecord, DecisionError>> {
    // Find the decision in either list
    let record = this.index.decided.find((d) => d.id === id)
    let sourceList: DecisionRecord[] = this.index.decided

    if (!record) {
      record = this.index.superseded.find((d) => d.id === id)
      sourceList = this.index.superseded
    }

    if (!record) {
      return err({ type: "not_found", id })
    }

    // Validate transition
    const allowedTransitions = VALID_TRANSITIONS[record.status]
    if (!allowedTransitions.includes(status)) {
      return err({ type: "invalid_transition", from: record.status, to: status })
    }

    // Update the record
    const updatedRecord: DecisionRecord = {
      ...record,
      status,
      updatedAt: new Date().toISOString(),
      supersededBy: status === "superseded" ? supersededBy : record.supersededBy,
    }

    try {
      // Remove from source list
      const sourceIndex = sourceList.findIndex((d) => d.id === id)
      if (sourceIndex !== -1) {
        sourceList.splice(sourceIndex, 1)
      }

      // Add to appropriate list based on new status
      if (status === "superseded") {
        this.index.superseded.push(updatedRecord)
        this.index.superseded.sort((a, b) => a.title.localeCompare(b.title))
      } else {
        this.index.decided.push(updatedRecord)
        this.index.decided.sort((a, b) => a.title.localeCompare(b.title))
      }

      // Update the decision file
      const absolutePath = path.join(this.getDecisionsDir(), updatedRecord.filename)
      const content = this.formatDecisionFile(updatedRecord)
      await fs.writeFile(absolutePath, content)

      // Save the updated index
      await this.save(this.index)

      await this.log.info(`Updated decision status: ${id} -> ${status}`)
      return ok(updatedRecord)
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error)
      return err({ type: "persistence_failed", message })
    }
  }

  /**
   * Adds a pending decision to the index.
   *
   * Pending decisions track questions that need resolution before
   * work can continue.
   *
   * @param pending - The pending decision to add
   */
  async addPendingDecision(pending: PendingDecision): Promise<void> {
    // Avoid duplicates based on question
    const existing = this.index.pending.find(
      (p) => p.question.toLowerCase() === pending.question.toLowerCase()
    )
    if (!existing) {
      this.index.pending.push(pending)
      await this.save(this.index)
      await this.log.info(`Added pending decision: ${pending.question}`)
    }
  }

  /**
   * Removes a pending decision from the index.
   *
   * Call this when a pending decision has been resolved (either decided
   * or no longer relevant).
   *
   * @param question - The question to remove
   */
  async removePendingDecision(question: string): Promise<void> {
    const index = this.index.pending.findIndex(
      (p) => p.question.toLowerCase() === question.toLowerCase()
    )
    if (index !== -1) {
      this.index.pending.splice(index, 1)
      await this.save(this.index)
      await this.log.info(`Removed pending decision: ${question}`)
    }
  }

  /**
   * Lists decisions with optional status filtering.
   *
   * @param options - Optional filter for status
   * @returns Array of matching decision records
   */
  list(options?: { status?: DecisionStatus }): DecisionRecord[] {
    if (!options?.status) {
      return [...this.index.decided, ...this.index.superseded]
    }

    if (options.status === "superseded") {
      return this.index.superseded
    }

    return this.index.decided.filter((d) => d.status === options.status)
  }

  /**
   * Retrieves a decision record by its unique ID.
   *
   * @param id - Decision ID to look up
   * @returns The decision record if found, or null
   */
  getById(id: string): DecisionRecord | null {
    const decided = this.index.decided.find((d) => d.id === id)
    if (decided) return decided

    const superseded = this.index.superseded.find((d) => d.id === id)
    if (superseded) return superseded

    return null
  }

  /**
   * Gets all pending decisions.
   *
   * @returns Array of pending decisions
   */
  getPending(): PendingDecision[] {
    return this.index.pending
  }

  /**
   * Formats an individual decision file as markdown.
   *
   * @param record - The decision record to format
   * @returns Markdown content for the decision file
   */
  formatDecisionFile(record: DecisionRecord): string {
    const lines: string[] = []

    lines.push(`# Decision: ${record.title}`)
    lines.push("")
    lines.push(`**Date:** ${record.createdAt.split("T")[0]}`)
    lines.push(`**Status:** ${this.formatStatus(record.status)}`)
    lines.push(`**Updated:** ${record.updatedAt}`)
    lines.push("")

    lines.push("## Decision")
    lines.push("")
    lines.push(record.decision)
    lines.push("")

    lines.push("## Rationale")
    lines.push("")
    lines.push(record.rationale)
    lines.push("")

    if (record.alternatives && record.alternatives.length > 0) {
      lines.push("## Alternatives Considered")
      lines.push("")

      for (const alt of record.alternatives) {
        lines.push(`### ${alt.name}`)
        lines.push("")
        lines.push(alt.description)
        lines.push("")

        if (alt.whyRejected) {
          lines.push(`**Why rejected:** ${alt.whyRejected}`)
          lines.push("")
        }
      }
    }

    if (record.sourceSession || (record.sourceResearch && record.sourceResearch.length > 0)) {
      lines.push("## Sources")
      lines.push("")

      if (record.sourceSession) {
        lines.push(`- **Session:** [${record.sourceSession}](../sessions/${record.sourceSession}.md)`)
      }

      if (record.sourceResearch && record.sourceResearch.length > 0) {
        for (const researchId of record.sourceResearch) {
          lines.push(`- **Research:** [${researchId}](../research/${researchId}.md)`)
        }
      }

      lines.push("")
    }

    if (record.relatedIssues && record.relatedIssues.length > 0) {
      lines.push("## Related Issues")
      lines.push("")

      for (const issueId of record.relatedIssues) {
        lines.push(`- ${issueId}`)
      }

      lines.push("")
    }

    if (record.supersededBy) {
      lines.push("## Superseded By")
      lines.push("")
      lines.push(`This decision has been superseded by: ${record.supersededBy}`)
      lines.push("")
    }

    return lines.join("\n")
  }

  /**
   * Formats the decision index file as markdown.
   *
   * @param index - The decision index to format
   * @returns Markdown content for index.md
   */
  formatIndexFile(index: DecisionIndex): string {
    const lines: string[] = []

    lines.push("# Decision Log")
    lines.push("")

    // Pending Decisions section
    lines.push("## Pending Decisions")
    lines.push("")

    if (index.pending.length === 0) {
      lines.push("*No pending decisions*")
    } else {
      for (const pending of index.pending) {
        lines.push(`### ${this.extractTitle(pending.question)}`)
        lines.push(`**Question:** ${pending.question}`)

        if (pending.context) {
          lines.push(`**Context:** ${pending.context}`)
        }

        if (pending.blocking && pending.blocking.length > 0) {
          lines.push(`**Blocking:** ${pending.blocking.join(", ")}`)
        }

        if (pending.relatedResearch && pending.relatedResearch.length > 0) {
          const links = pending.relatedResearch
            .map((id) => `[${id}](../research/${id}.md)`)
            .join(", ")
          lines.push(`**Related Research:** ${links}`)
        }

        lines.push("")
      }
    }

    lines.push("---")
    lines.push("")

    // Decided section
    lines.push("## Decided")
    lines.push("")

    if (index.decided.length === 0) {
      lines.push("*No decisions recorded yet*")
    } else {
      for (const record of index.decided) {
        lines.push(`### ${record.title}`)
        lines.push(`**Status:** ${this.formatStatus(record.status)}`)
        lines.push(`**Date:** ${record.createdAt.split("T")[0]}`)
        lines.push(`**Decision:** ${record.decision}`)
        lines.push(`**Link:** [Full record](./${record.filename})`)
        lines.push("")
      }
    }

    lines.push("---")
    lines.push("")

    // Superseded section
    lines.push("## Superseded")
    lines.push("")

    if (index.superseded.length === 0) {
      lines.push("*(None yet)*")
    } else {
      for (const record of index.superseded) {
        lines.push(`### ${record.title}`)
        lines.push(`**Date:** ${record.createdAt.split("T")[0]}`)
        lines.push(`**Superseded By:** ${record.supersededBy ?? "Unknown"}`)
        lines.push(`**Link:** [Full record](./${record.filename})`)
        lines.push("")
      }
    }

    lines.push("")
    return lines.join("\n")
  }

  /**
   * Formats a status value for display.
   *
   * @param status - The status to format
   * @returns Capitalized status string
   */
  private formatStatus(status: DecisionStatus): string {
    return status.charAt(0).toUpperCase() + status.slice(1)
  }

  /**
   * Extracts a short title from a question for section headers.
   *
   * @param question - The question to extract a title from
   * @returns A short title suitable for a section header
   */
  private extractTitle(question: string): string {
    // Remove common question prefixes and truncate
    const cleaned = question
      .replace(/^(which|what|how|should we|do we need to)\s+/i, "")
      .replace(/\?$/, "")

    // Capitalize first letter and truncate
    const title = cleaned.charAt(0).toUpperCase() + cleaned.slice(1)
    return title.length > 50 ? title.slice(0, 47) + "..." : title
  }

  /**
   * Parses the index.md file to reconstruct the DecisionIndex.
   *
   * This is a best-effort parser that extracts structured data from
   * the markdown format. It handles missing sections gracefully.
   *
   * @param content - The raw markdown content
   * @returns Parsed decision index
   */
  private parseIndexFile(content: string): DecisionIndex {
    const index: DecisionIndex = { pending: [], decided: [], superseded: [] }
    const lines = content.split("\n")

    let currentSection: "pending" | "decided" | "superseded" | null = null
    let currentPending: Partial<PendingDecision> | null = null
    let currentDecision: Partial<DecisionRecord> | null = null

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i]

      // Track which section we're in
      if (line.startsWith("## Pending Decisions")) {
        currentSection = "pending"
        continue
      } else if (line.startsWith("## Decided")) {
        // Save any pending decision in progress
        if (currentPending?.question) {
          index.pending.push(currentPending as PendingDecision)
          currentPending = null
        }
        currentSection = "decided"
        continue
      } else if (line.startsWith("## Superseded")) {
        // Save any decision in progress
        if (currentDecision?.id) {
          index.decided.push(currentDecision as DecisionRecord)
          currentDecision = null
        }
        currentSection = "superseded"
        continue
      } else if (line.startsWith("---")) {
        // Save any in-progress items at section boundaries
        if (currentPending?.question) {
          index.pending.push(currentPending as PendingDecision)
          currentPending = null
        }
        if (currentDecision?.id) {
          if (currentSection === "superseded") {
            index.superseded.push(currentDecision as DecisionRecord)
          } else {
            index.decided.push(currentDecision as DecisionRecord)
          }
          currentDecision = null
        }
        continue
      }

      // Parse pending decisions
      if (currentSection === "pending") {
        if (line.startsWith("### ")) {
          // Save previous pending if exists
          if (currentPending?.question) {
            index.pending.push(currentPending as PendingDecision)
          }
          currentPending = {}
        } else if (line.startsWith("**Question:**") && currentPending) {
          currentPending.question = line.replace("**Question:**", "").trim()
        } else if (line.startsWith("**Context:**") && currentPending) {
          currentPending.context = line.replace("**Context:**", "").trim()
        } else if (line.startsWith("**Blocking:**") && currentPending) {
          const blocking = line.replace("**Blocking:**", "").trim()
          currentPending.blocking = blocking.split(",").map((s) => s.trim())
        } else if (line.startsWith("**Related Research:**") && currentPending) {
          // Extract IDs from markdown links
          const matches = line.matchAll(/\[([^\]]+)\]/g)
          currentPending.relatedResearch = Array.from(matches).map((m) => m[1])
        }
      }

      // Parse decided/superseded decisions
      if (currentSection === "decided" || currentSection === "superseded") {
        if (line.startsWith("### ")) {
          // Save previous decision if exists
          if (currentDecision?.id) {
            if (currentSection === "superseded") {
              index.superseded.push(currentDecision as DecisionRecord)
            } else {
              index.decided.push(currentDecision as DecisionRecord)
            }
          }
          currentDecision = {
            title: line.slice(4).trim(),
            status: currentSection === "superseded" ? "superseded" : "decided",
          }
        } else if (line.startsWith("**Status:**") && currentDecision) {
          const statusStr = line.replace("**Status:**", "").trim().toLowerCase()
          if (this.isValidStatus(statusStr)) {
            currentDecision.status = statusStr
          }
        } else if (line.startsWith("**Date:**") && currentDecision) {
          const dateStr = line.replace("**Date:**", "").trim()
          currentDecision.createdAt = `${dateStr}T00:00:00.000Z`
          currentDecision.updatedAt = currentDecision.createdAt
        } else if (line.startsWith("**Decision:**") && currentDecision) {
          currentDecision.decision = line.replace("**Decision:**", "").trim()
        } else if (line.startsWith("**Superseded By:**") && currentDecision) {
          currentDecision.supersededBy = line.replace("**Superseded By:**", "").trim()
        } else if (line.startsWith("**Link:**") && currentDecision) {
          // Extract filename from markdown link
          const match = line.match(/\[Full record\]\(\.\/([^)]+)\)/)
          if (match) {
            currentDecision.filename = match[1]
            // Extract slug from filename (date-slug.md)
            const slugMatch = match[1].match(/^\d{4}-\d{2}-\d{2}-(.+)\.md$/)
            if (slugMatch) {
              currentDecision.slug = slugMatch[1]
            }
            // Generate ID from filename if not present
            if (!currentDecision.id) {
              currentDecision.id = `decision-${currentDecision.slug ?? "unknown"}-unknown`
            }
          }
        }
      }
    }

    // Save any remaining items
    if (currentPending?.question) {
      index.pending.push(currentPending as PendingDecision)
    }
    if (currentDecision?.id) {
      if (currentSection === "superseded") {
        index.superseded.push(currentDecision as DecisionRecord)
      } else {
        index.decided.push(currentDecision as DecisionRecord)
      }
    }

    // Sort decided alphabetically by title
    index.decided.sort((a, b) => a.title.localeCompare(b.title))
    index.superseded.sort((a, b) => a.title.localeCompare(b.title))

    return index
  }

  /**
   * Type guard for valid decision status values.
   *
   * @param status - The status string to check
   * @returns True if the status is valid
   */
  private isValidStatus(status: string): status is DecisionStatus {
    return ["proposed", "decided", "rejected", "deferred", "superseded"].includes(status)
  }
}
