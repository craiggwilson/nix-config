/**
 * InterviewManager - Handles saving and resuming planning interviews
 *
 * Interviews are conversational exchanges during project planning.
 * They are persisted incrementally to the project's interviews directory.
 */

import * as fs from "node:fs/promises"
import * as path from "node:path"
import * as crypto from "node:crypto"

/**
 * A single exchange in an interview
 */
export interface InterviewExchange {
  timestamp: string
  role: "assistant" | "user"
  content: string
}

/**
 * Interview session metadata
 */
export interface InterviewSession {
  id: string
  projectId: string
  phase: "discovery" | "refinement" | "breakdown"
  topic?: string
  startedAt: string
  lastUpdatedAt: string
  exchanges: InterviewExchange[]
  status: "active" | "completed" | "abandoned"
}

/**
 * Summary of an interview session (without full exchanges)
 */
export interface InterviewSummary {
  id: string
  phase: string
  topic?: string
  startedAt: string
  lastUpdatedAt: string
  exchangeCount: number
  status: string
}

/**
 * InterviewManager - manages interview persistence
 */
export class InterviewManager {
  private projectDir: string
  private interviewsDir: string
  private currentSession: InterviewSession | null = null

  constructor(projectDir: string) {
    this.projectDir = projectDir
    this.interviewsDir = path.join(projectDir, "interviews")
  }

  /**
   * Start a new interview session
   */
  async startSession(
    projectId: string,
    phase: "discovery" | "refinement" | "breakdown",
    topic?: string
  ): Promise<InterviewSession> {

    await fs.mkdir(this.interviewsDir, { recursive: true })

    const sessionId = this.generateSessionId()
    const now = new Date().toISOString()

    this.currentSession = {
      id: sessionId,
      projectId,
      phase,
      topic,
      startedAt: now,
      lastUpdatedAt: now,
      exchanges: [],
      status: "active",
    }

    await this.saveSession()
    return this.currentSession
  }

  /**
   * Resume an existing session
   */
  async resumeSession(sessionId: string): Promise<InterviewSession | null> {
    const session = await this.loadSession(sessionId)
    if (session && session.status === "active") {
      this.currentSession = session
      return session
    }
    return null
  }

  /**
   * Get the current active session
   */
  getCurrentSession(): InterviewSession | null {
    return this.currentSession
  }

  /**
   * Add an exchange to the current session
   */
  async addExchange(role: "assistant" | "user", content: string): Promise<void> {
    if (!this.currentSession) {
      throw new Error("No active interview session")
    }

    this.currentSession.exchanges.push({
      timestamp: new Date().toISOString(),
      role,
      content,
    })

    this.currentSession.lastUpdatedAt = new Date().toISOString()
    await this.saveSession()
  }

  /**
   * Complete the current session
   */
  async completeSession(): Promise<void> {
    if (!this.currentSession) {
      throw new Error("No active interview session")
    }

    this.currentSession.status = "completed"
    this.currentSession.lastUpdatedAt = new Date().toISOString()
    await this.saveSession()
    this.currentSession = null
  }

  /**
   * Abandon the current session
   */
  async abandonSession(): Promise<void> {
    if (!this.currentSession) {
      return
    }

    this.currentSession.status = "abandoned"
    this.currentSession.lastUpdatedAt = new Date().toISOString()
    await this.saveSession()
    this.currentSession = null
  }

  /**
   * List all interview sessions
   */
  async listSessions(): Promise<InterviewSummary[]> {
    const summaries: InterviewSummary[] = []

    try {
      const files = await fs.readdir(this.interviewsDir)

      for (const file of files) {
        if (file.endsWith(".json")) {
          const sessionId = file.replace(".json", "")
          const session = await this.loadSession(sessionId)

          if (session) {
            summaries.push({
              id: session.id,
              phase: session.phase,
              topic: session.topic,
              startedAt: session.startedAt,
              lastUpdatedAt: session.lastUpdatedAt,
              exchangeCount: session.exchanges.length,
              status: session.status,
            })
          }
        }
      }
    } catch {

    }


    return summaries.sort(
      (a, b) => new Date(b.lastUpdatedAt).getTime() - new Date(a.lastUpdatedAt).getTime()
    )
  }

  /**
   * Get the most recent active session
   */
  async getMostRecentActiveSession(): Promise<InterviewSession | null> {
    const summaries = await this.listSessions()
    const active = summaries.find((s) => s.status === "active")

    if (active) {
      return this.loadSession(active.id)
    }

    return null
  }

  /**
   * Export session to markdown
   */
  async exportToMarkdown(sessionId: string): Promise<string | null> {
    const session = await this.loadSession(sessionId)
    if (!session) return null

    const lines: string[] = []

    lines.push(`# Interview: ${session.phase}`)
    if (session.topic) {
      lines.push(`## Topic: ${session.topic}`)
    }
    lines.push("")
    lines.push(`**Started:** ${session.startedAt}`)
    lines.push(`**Status:** ${session.status}`)
    lines.push("")
    lines.push("---")
    lines.push("")

    for (const exchange of session.exchanges) {
      const roleLabel = exchange.role === "assistant" ? "**Assistant:**" : "**User:**"
      lines.push(roleLabel)
      lines.push("")
      lines.push(exchange.content)
      lines.push("")
      lines.push("---")
      lines.push("")
    }

    return lines.join("\n")
  }

  /**
   * Get context for continuing an interview
   */
  getInterviewContext(): string | null {
    if (!this.currentSession) return null

    const lines: string[] = []

    lines.push("<interview-context>")
    lines.push(`## Active Interview: ${this.currentSession.phase}`)

    if (this.currentSession.topic) {
      lines.push(`**Topic:** ${this.currentSession.topic}`)
    }

    lines.push(`**Exchanges:** ${this.currentSession.exchanges.length}`)
    lines.push("")


    const recentExchanges = this.currentSession.exchanges.slice(-4)
    if (recentExchanges.length > 0) {
      lines.push("### Recent Discussion")
      lines.push("")

      for (const exchange of recentExchanges) {
        const roleLabel = exchange.role === "assistant" ? "**Assistant:**" : "**User:**"
        lines.push(roleLabel)

        const content =
          exchange.content.length > 500
            ? exchange.content.slice(0, 497) + "..."
            : exchange.content
        lines.push(content)
        lines.push("")
      }
    }

    lines.push("</interview-context>")

    return lines.join("\n")
  }

  /**
   * Generate a unique session ID
   */
  private generateSessionId(): string {
    const timestamp = new Date().toISOString().slice(0, 10).replace(/-/g, "")
    const random = crypto.randomBytes(3).toString("hex")
    return `${timestamp}-${random}`
  }

  /**
   * Save the current session to disk
   */
  private async saveSession(): Promise<void> {
    if (!this.currentSession) return

    await fs.mkdir(this.interviewsDir, { recursive: true })

    const filePath = path.join(this.interviewsDir, `${this.currentSession.id}.json`)
    await fs.writeFile(filePath, JSON.stringify(this.currentSession, null, 2), "utf8")
  }

  /**
   * Load a session from disk
   */
  private async loadSession(sessionId: string): Promise<InterviewSession | null> {
    try {
      const filePath = path.join(this.interviewsDir, `${sessionId}.json`)
      const content = await fs.readFile(filePath, "utf8")
      return JSON.parse(content) as InterviewSession
    } catch {
      return null
    }
  }
}
