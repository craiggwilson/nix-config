/**
 * SessionManager - Captures session summaries and maintains session history
 *
 * Sessions track the work done across multiple conversations, providing
 * continuity and context for ongoing projects. Each session captures a
 * summary, key points, and links to artifacts and decisions produced.
 *
 * The session index provides a table of contents with accumulated open
 * questions, pending decisions, and next steps - enabling quick orientation
 * at the start of each new conversation.
 *
 * State is persisted to `sessions/` within the project directory:
 * - `sessions/index.md` - TOC with summaries and accumulated state
 * - `sessions/{seq}-{sessionId}-{date}.md` - Individual session files
 *
 * @module sessions
 */

import * as fs from "node:fs/promises"
import * as path from "node:path"

import type { Logger } from "../utils/opencode-sdk/index.js"
import { ok, err, type Result } from "../utils/result/index.js"

/**
 * Represents a captured session with its summary and metadata.
 *
 * Sessions are identified by their OpenCode session ID and ordered by
 * sequence number for chronological sorting.
 */
export interface SessionSummary {
  /** Session ID from OpenCode */
  id: string
  /** Sequence number for ordering (1-based) */
  sequence: number
  /** The markdown filename (e.g., "001-ses_abc123-2026-03-02.md") */
  filename: string
  /** ISO date (YYYY-MM-DD) */
  date: string
  /** Full ISO timestamp */
  timestamp: string
  /** 2-3 sentence summary of the session */
  summary: string
  /** 3-5 bullet points of key accomplishments */
  keyPoints: string[]
  /** Questions identified in this session */
  openQuestionsAdded: string[]
  /** Decisions recorded (links to decision records) */
  decisionsMade: string[]
  /** Artifact IDs created during this session */
  artifactsCreated: string[]
}

/**
 * Accumulated state across all sessions.
 *
 * The index tracks open questions, pending decisions, and next steps
 * that persist across sessions, along with the full session history.
 */
export interface SessionIndex {
  /** Current open questions (accumulated across sessions) */
  openQuestions: string[]
  /** Decisions needing resolution */
  pendingDecisions: string[]
  /** Next steps for upcoming work */
  whatsNext: string[]
  /** All sessions, most recent first */
  sessions: SessionSummary[]
}

/**
 * Error types for session operations.
 *
 * Uses discriminated unions for type-safe error handling.
 */
export type SessionError =
  | { type: "already_exists"; sessionId: string }
  | { type: "persistence_failed"; message: string }

/**
 * Options for capturing a new session.
 *
 * The sessionId comes from OpenCode; other fields are provided by the
 * agent summarizing the session.
 */
export interface CaptureSessionOptions {
  /** Session ID from OpenCode */
  sessionId: string
  /** 2-3 sentence summary of the session */
  summary: string
  /** 3-5 bullet points of key accomplishments */
  keyPoints: string[]
  /** Questions identified in this session */
  openQuestionsAdded?: string[]
  /** Decisions recorded (links to decision records) */
  decisionsMade?: string[]
  /** Artifact IDs created during this session */
  artifactsCreated?: string[]
}

/**
 * Options for writing an incremental session snapshot.
 *
 * Snapshots are written on every `session.idle` event for the orchestrator
 * session. They are cheap — no model calls, just raw state.
 */
export interface WriteSnapshotOptions {
  /** Session ID from OpenCode */
  sessionId: string
  /** ISO timestamp of the snapshot */
  timestamp: string
  /** Current project state summary */
  projectState: string
  /** Last N messages from the conversation, formatted as text */
  recentMessages: string
}

/**
 * Formats the content of a session snapshot file.
 *
 * @param options - Snapshot options
 * @returns Markdown content for the snapshot file
 */
function formatSnapshotContent(options: WriteSnapshotOptions): string {
  const { sessionId, timestamp, projectState, recentMessages } = options
  const lines: string[] = []

  lines.push(`# Session Snapshot`)
  lines.push("")
  lines.push(`**Session ID:** ${sessionId}`)
  lines.push(`**Updated:** ${timestamp}`)
  lines.push("")
  lines.push("## Project State")
  lines.push(projectState)
  lines.push("")
  lines.push("## Recent Conversation")
  lines.push(recentMessages || "*No messages yet*")
  lines.push("")

  return lines.join("\n")
}

/**
 * Manages session history for a project.
 *
 * The SessionManager maintains a chronological record of all sessions,
 * with an index file providing quick access to accumulated state and
 * recent session summaries.
 *
 * @example
 * ```typescript
 * const manager = new SessionManager("/path/to/project", logger)
 * const index = await manager.load()
 *
 * const result = await manager.captureSession({
 *   sessionId: "ses_abc123",
 *   summary: "Completed authentication research and made key decisions.",
 *   keyPoints: [
 *     "Analyzed OAuth2 vs SAML for enterprise SSO",
 *     "Decided on OAuth2 with PKCE for mobile support",
 *     "Created architecture diagram"
 *   ],
 *   openQuestionsAdded: ["How to handle token refresh in offline mode?"],
 *   decisionsMade: ["[OAuth2 with PKCE](../decisions/auth-protocol.md)"],
 *   artifactsCreated: ["research-auth-patterns-abc123"]
 * })
 *
 * if (result.ok) {
 *   console.log("Captured session:", result.value.filename)
 * }
 * ```
 */
export class SessionManager {
  /** Path to the project directory */
  private projectDir: string
  /** Logger for tracking session operations */
  private log: Logger
  /** In-memory session index, loaded from disk */
  private index: SessionIndex

  /**
   * Creates a new SessionManager for a specific project.
   *
   * Call `load()` before using other methods to initialize state from disk.
   *
   * @param projectDir - Absolute path to the project directory
   * @param log - Logger instance for operation tracking
   */
  constructor(projectDir: string, log: Logger) {
    this.projectDir = projectDir
    this.log = log
    this.index = {
      openQuestions: [],
      pendingDecisions: [],
      whatsNext: [],
      sessions: [],
    }
  }

  /**
   * Resolves the path to the sessions directory.
   */
  private getSessionsDir(): string {
    return path.join(this.projectDir, "sessions")
  }

  /**
   * Resolves the path to the session index file.
   */
  private getIndexPath(): string {
    return path.join(this.getSessionsDir(), "index.md")
  }

  /**
   * Ensures the sessions directory exists.
   */
  private async ensureSessionsDir(): Promise<void> {
    const sessionsDir = this.getSessionsDir()
    await fs.mkdir(sessionsDir, { recursive: true })
  }

  /**
   * Loads the session index from disk.
   *
   * Parses the index.md file to reconstruct the SessionIndex structure.
   * Creates an empty index if the file doesn't exist.
   *
   * @returns The loaded session index
   */
  async load(): Promise<SessionIndex> {
    const indexPath = this.getIndexPath()

    try {
      const content = await fs.readFile(indexPath, "utf-8")
      this.index = this.parseIndexFile(content)
      await this.log.debug(`Loaded ${this.index.sessions.length} sessions from index`)
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code === "ENOENT") {
        this.index = {
          openQuestions: [],
          pendingDecisions: [],
          whatsNext: [],
          sessions: [],
        }
        await this.log.debug("No existing session index, starting fresh")
      } else {
        throw error
      }
    }

    return this.index
  }

  /**
   * Persists the session index to disk.
   *
   * Writes the index.md file with the current state.
   *
   * @param index - The index to persist
   */
  async save(index: SessionIndex): Promise<void> {
    await this.ensureSessionsDir()
    const indexPath = this.getIndexPath()
    const content = this.formatIndexFile(index)
    await fs.writeFile(indexPath, content)
    this.index = index
    await this.log.debug(`Saved session index with ${index.sessions.length} sessions`)
  }

  /**
   * Gets the next sequence number for a new session.
   *
   * Sequence numbers are 1-based and increment monotonically.
   *
   * @returns The next sequence number
   */
  async getNextSequence(): Promise<number> {
    if (this.index.sessions.length === 0) {
      return 1
    }
    const maxSequence = Math.max(...this.index.sessions.map((s) => s.sequence))
    return maxSequence + 1
  }

  /**
   * Captures a new session and adds it to the index.
   *
   * Creates the session file and updates the index with the new session
   * prepended (most recent first). Returns an error if a session with
   * the same ID already exists.
   *
   * @param options - Session capture options
   * @returns The captured session summary, or an error
   */
  async captureSession(
    options: CaptureSessionOptions
  ): Promise<Result<SessionSummary, SessionError>> {
    // Check for duplicate session ID
    const existing = this.index.sessions.find((s) => s.id === options.sessionId)
    if (existing) {
      return err({ type: "already_exists", sessionId: options.sessionId })
    }

    const sequence = await this.getNextSequence()
    const now = new Date()
    const date = now.toISOString().split("T")[0]
    const timestamp = now.toISOString()
    const filename = this.formatFilename(sequence, options.sessionId, date)

    const summary: SessionSummary = {
      id: options.sessionId,
      sequence,
      filename,
      date,
      timestamp,
      summary: options.summary,
      keyPoints: options.keyPoints,
      openQuestionsAdded: options.openQuestionsAdded ?? [],
      decisionsMade: options.decisionsMade ?? [],
      artifactsCreated: options.artifactsCreated ?? [],
    }

    // Write the individual session file
    try {
      await this.ensureSessionsDir()
      const sessionPath = path.join(this.getSessionsDir(), filename)
      const sessionContent = this.formatSessionFile(summary)
      await fs.writeFile(sessionPath, sessionContent)

      // Prepend to sessions list (most recent first)
      this.index.sessions.unshift(summary)

      // Add new open questions to the accumulated list
      if (options.openQuestionsAdded?.length) {
        for (const q of options.openQuestionsAdded) {
          if (!this.index.openQuestions.includes(q)) {
            this.index.openQuestions.push(q)
          }
        }
      }

      // Save the updated index
      await this.save(this.index)

      await this.log.info(`Captured session: ${filename}`)
      return ok(summary)
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error)
      return err({ type: "persistence_failed", message })
    }
  }

  /**
   * Updates the index metadata without capturing a new session.
   *
   * Use this to modify open questions, pending decisions, or next steps
   * independently of session capture.
   *
   * @param updates - Partial updates to apply
   */
  async updateIndex(
    updates: Partial<Pick<SessionIndex, "openQuestions" | "pendingDecisions" | "whatsNext">>
  ): Promise<void> {
    if (updates.openQuestions !== undefined) {
      this.index.openQuestions = updates.openQuestions
    }
    if (updates.pendingDecisions !== undefined) {
      this.index.pendingDecisions = updates.pendingDecisions
    }
    if (updates.whatsNext !== undefined) {
      this.index.whatsNext = updates.whatsNext
    }
    await this.save(this.index)
  }

  /**
   * Gets the N most recent sessions.
   *
   * Sessions are already stored most-recent-first, so this is a simple slice.
   *
   * @param limit - Maximum number of sessions to return
   * @returns Array of recent sessions
   */
  getRecentSessions(limit: number): SessionSummary[] {
    return this.index.sessions.slice(0, limit)
  }

  /**
   * Writes a lightweight incremental snapshot for the current session.
   *
   * Called on every `session.idle` event for the orchestrator session.
   * Overwrites the snapshot file each time — always reflects current state.
   * Does NOT call the small model; this is intentionally cheap.
   *
   * The snapshot file is written to `sessions/<sessionId>.md` and the
   * session index is updated to reference it.
   *
   * @param options - Snapshot options
   */
  async writeSnapshot(options: WriteSnapshotOptions): Promise<void> {
    await this.ensureSessionsDir()

    const { sessionId, timestamp, projectState, recentMessages } = options
    const snapshotFilename = `${sessionId}.md`
    const snapshotPath = path.join(this.getSessionsDir(), snapshotFilename)

    const content = formatSnapshotContent({ sessionId, timestamp, projectState, recentMessages })
    await fs.writeFile(snapshotPath, content, "utf-8")

    // Update the index to reference the current snapshot
    await this.updateSnapshotIndex(sessionId, snapshotFilename, timestamp)

    await this.log.debug(`Wrote session snapshot: ${snapshotFilename}`)
  }

  /**
   * Updates the session index to reference the current snapshot file.
   *
   * Reads the existing index, updates the current session reference, and
   * writes it back. This is a lightweight update — no session history is
   * modified.
   *
   * @param sessionId - The orchestrator session ID
   * @param snapshotFilename - The snapshot filename
   * @param timestamp - ISO timestamp of the snapshot
   */
  private async updateSnapshotIndex(
    sessionId: string,
    snapshotFilename: string,
    timestamp: string,
  ): Promise<void> {
    const indexPath = this.getIndexPath()

    let content: string
    try {
      content = await fs.readFile(indexPath, "utf-8")
    } catch {
      content = ""
    }

    const currentRef = `**Current session:** [${sessionId}](./${snapshotFilename}) (updated ${timestamp})`

    // Replace or prepend the current session reference
    const currentRefPattern = /^\*\*Current session:\*\*.*$/m
    if (currentRefPattern.test(content)) {
      content = content.replace(currentRefPattern, currentRef)
    } else {
      // Prepend to the index
      content = `${currentRef}\n\n${content}`
    }

    await fs.writeFile(indexPath, content, "utf-8")
  }

  /**
   * Formats a session filename from its components.
   *
   * @param sequence - Zero-padded sequence number
   * @param sessionId - OpenCode session ID
   * @param date - ISO date (YYYY-MM-DD)
   * @returns Filename like "001-ses_abc123-2026-03-02.md"
   */
  private formatFilename(sequence: number, sessionId: string, date: string): string {
    const paddedSeq = String(sequence).padStart(3, "0")
    return `${paddedSeq}-${sessionId}-${date}.md`
  }

  /**
   * Formats an individual session file as markdown.
   *
   * @param summary - The session summary to format
   * @returns Markdown content for the session file
   */
  formatSessionFile(summary: SessionSummary): string {
    const lines: string[] = []

    lines.push(`# Session: ${summary.date}`)
    lines.push("")
    lines.push(`**Session ID:** ${summary.id}`)
    lines.push(`**Timestamp:** ${summary.timestamp}`)
    lines.push("")
    lines.push("## Summary")
    lines.push(summary.summary)
    lines.push("")
    lines.push("## Key Points")
    for (const point of summary.keyPoints) {
      lines.push(`- ${point}`)
    }

    if (summary.openQuestionsAdded.length > 0) {
      lines.push("")
      lines.push("## Open Questions Added")
      for (const question of summary.openQuestionsAdded) {
        lines.push(`- ${question}`)
      }
    }

    if (summary.decisionsMade.length > 0) {
      lines.push("")
      lines.push("## Decisions Made")
      for (const decision of summary.decisionsMade) {
        lines.push(`- ${decision}`)
      }
    }

    if (summary.artifactsCreated.length > 0) {
      lines.push("")
      lines.push("## Artifacts Created")
      for (const artifact of summary.artifactsCreated) {
        lines.push(`- ${artifact}`)
      }
    }

    lines.push("")
    return lines.join("\n")
  }

  /**
   * Formats the session index file as markdown.
   *
   * @param index - The session index to format
   * @returns Markdown content for index.md
   */
  formatIndexFile(index: SessionIndex): string {
    const lines: string[] = []

    lines.push("# Session History")
    lines.push("")

    lines.push("## Open Questions")
    if (index.openQuestions.length > 0) {
      for (const question of index.openQuestions) {
        lines.push(`- ${question}`)
      }
    } else {
      lines.push("*No open questions*")
    }
    lines.push("")

    lines.push("## Pending Decisions")
    if (index.pendingDecisions.length > 0) {
      for (const decision of index.pendingDecisions) {
        lines.push(`- ${decision}`)
      }
    } else {
      lines.push("*No pending decisions*")
    }
    lines.push("")

    lines.push("## What's Next")
    if (index.whatsNext.length > 0) {
      for (const next of index.whatsNext) {
        lines.push(`- ${next}`)
      }
    } else {
      lines.push("*No next steps defined*")
    }
    lines.push("")

    lines.push("---")
    lines.push("")
    lines.push("## Sessions")
    lines.push("")

    for (const session of index.sessions) {
      lines.push(`### ${session.filename.replace(".md", "")}`)
      lines.push(`**Summary:** ${session.summary}`)
      lines.push("")
      lines.push("**Key Points:**")
      for (const point of session.keyPoints) {
        lines.push(`- ${point}`)
      }
      lines.push("")
      lines.push(`**Link:** [Full session](./${session.filename})`)
      lines.push("")
      lines.push("---")
      lines.push("")
    }

    return lines.join("\n")
  }

  /**
   * Parses the index.md file to reconstruct the SessionIndex.
   *
   * This is a best-effort parser that extracts structured data from
   * the markdown format. It handles missing sections gracefully.
   *
   * @param content - The raw markdown content
   * @returns Parsed session index
   */
  private parseIndexFile(content: string): SessionIndex {
    const index: SessionIndex = {
      openQuestions: [],
      pendingDecisions: [],
      whatsNext: [],
      sessions: [],
    }

    const lines = content.split("\n")
    let currentSection = ""

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i]

      // Track which section we're in
      if (line.startsWith("## Open Questions")) {
        currentSection = "openQuestions"
        continue
      } else if (line.startsWith("## Pending Decisions")) {
        currentSection = "pendingDecisions"
        continue
      } else if (line.startsWith("## What's Next")) {
        currentSection = "whatsNext"
        continue
      } else if (line.startsWith("## Sessions")) {
        currentSection = "sessions"
        continue
      } else if (line.startsWith("### ")) {
        // Parse session header
        if (currentSection === "sessions") {
          const session = this.parseSessionFromIndex(lines, i)
          if (session) {
            index.sessions.push(session)
          }
        }
        continue
      }

      // Parse list items in metadata sections
      if (line.startsWith("- ") && !line.includes("*No ")) {
        const item = line.slice(2).trim()
        if (currentSection === "openQuestions") {
          index.openQuestions.push(item)
        } else if (currentSection === "pendingDecisions") {
          index.pendingDecisions.push(item)
        } else if (currentSection === "whatsNext") {
          index.whatsNext.push(item)
        }
      }
    }

    return index
  }

  /**
   * Parses a single session entry from the index file.
   *
   * @param lines - All lines of the index file
   * @param startIndex - Index of the session header line
   * @returns Parsed session summary, or null if parsing fails
   */
  private parseSessionFromIndex(lines: string[], startIndex: number): SessionSummary | null {
    const headerLine = lines[startIndex]
    // Header format: ### 001-ses_abc123-2026-03-02
    const headerMatch = headerLine.match(/^### (\d{3})-(.+)-(\d{4}-\d{2}-\d{2})$/)
    if (!headerMatch) {
      return null
    }

    const sequence = parseInt(headerMatch[1], 10)
    const sessionId = headerMatch[2]
    const date = headerMatch[3]
    const filename = `${headerMatch[1]}-${headerMatch[2]}-${headerMatch[3]}.md`

    let summary = ""
    const keyPoints: string[] = []
    let inKeyPoints = false

    // Parse the session block until we hit the next separator or session
    for (let i = startIndex + 1; i < lines.length; i++) {
      const line = lines[i]

      if (line.startsWith("---") || line.startsWith("### ")) {
        break
      }

      if (line.startsWith("**Summary:**")) {
        summary = line.replace("**Summary:**", "").trim()
        inKeyPoints = false
      } else if (line.startsWith("**Key Points:**")) {
        inKeyPoints = true
      } else if (line.startsWith("**Link:**")) {
        inKeyPoints = false
      } else if (inKeyPoints && line.startsWith("- ")) {
        keyPoints.push(line.slice(2).trim())
      }
    }

    return {
      id: sessionId,
      sequence,
      filename,
      date,
      timestamp: `${date}T00:00:00.000Z`, // Approximate; full timestamp is in individual file
      summary,
      keyPoints,
      openQuestionsAdded: [], // Not stored in index summary
      decisionsMade: [], // Not stored in index summary
      artifactsCreated: [], // Not stored in index summary
    }
  }
}
