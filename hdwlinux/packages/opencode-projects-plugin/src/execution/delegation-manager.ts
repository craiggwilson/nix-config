/**
 * DelegationManager - Manages background agent delegations
 *
 * Handles delegating issue work to background agents, tracking their
 * status, and persisting results.
 */

import * as fs from "node:fs/promises"
import * as path from "node:path"
import * as crypto from "node:crypto"

import type { Logger } from "../core/types.js"

/**
 * Delegation status
 */
export type DelegationStatus = "pending" | "running" | "completed" | "failed" | "cancelled"

/**
 * Delegation record
 */
export interface Delegation {
  id: string
  projectId: string
  issueId: string
  worktreePath?: string
  status: DelegationStatus
  sessionId?: string
  agent?: string
  prompt: string
  result?: string
  error?: string
  startedAt: string
  completedAt?: string
}

/**
 * Options for creating a delegation
 */
export interface CreateDelegationOptions {
  issueId: string
  prompt: string
  worktreePath?: string
  agent?: string
}

/**
 * DelegationManager - manages background delegations
 */
export class DelegationManager {
  private projectDir: string
  private delegationsDir: string
  private researchDir: string
  private log: Logger
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  private client?: any

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  constructor(projectDir: string, log: Logger, client?: any) {
    this.projectDir = projectDir
    this.delegationsDir = path.join(projectDir, "delegations")
    this.researchDir = path.join(projectDir, "research")
    this.log = log
    this.client = client
  }

  /**
   * Create a new delegation
   */
  async create(
    projectId: string,
    options: CreateDelegationOptions
  ): Promise<Delegation> {
    const { issueId, prompt, worktreePath, agent } = options


    const id = this.generateId()
    const now = new Date().toISOString()

    const delegation: Delegation = {
      id,
      projectId,
      issueId,
      worktreePath,
      status: "pending",
      agent,
      prompt,
      startedAt: now,
    }


    await this.save(delegation)

    await this.log.info(`Created delegation ${id} for issue ${issueId}`)

    // If we have a client, try to start the delegation
    if (this.client) {
      try {
        delegation.status = "running"
        await this.save(delegation)


        const sessionResult = await this.client.session.create({
          body: {
            agent,
            title: `Delegation: ${issueId}`,
          },
        })

        const sessionId = sessionResult.data?.id
        if (sessionId) {
          delegation.sessionId = sessionId


          await this.client.session.prompt({
            path: { id: sessionId },
            body: { content: this.buildPrompt(delegation) },
          })

          await this.save(delegation)
        }
      } catch (error) {
        await this.log.error(`Failed to start delegation: ${error}`)
        delegation.status = "failed"
        delegation.error = String(error)
        await this.save(delegation)
      }
    }

    return delegation
  }

  /**
   * Get a delegation by ID
   */
  async get(delegationId: string): Promise<Delegation | null> {
    try {
      const filePath = path.join(this.delegationsDir, `${delegationId}.json`)
      const content = await fs.readFile(filePath, "utf8")
      return JSON.parse(content) as Delegation
    } catch {
      return null
    }
  }

  /**
   * List all delegations
   */
  async list(options?: { status?: DelegationStatus; issueId?: string }): Promise<Delegation[]> {
    const delegations: Delegation[] = []

    try {
      await fs.mkdir(this.delegationsDir, { recursive: true })
      const files = await fs.readdir(this.delegationsDir)

      for (const file of files) {
        if (file.endsWith(".json")) {
          const content = await fs.readFile(path.join(this.delegationsDir, file), "utf8")
          const delegation = JSON.parse(content) as Delegation
          delegations.push(delegation)
        }
      }
    } catch {

    }


    let filtered = delegations

    if (options?.status) {
      filtered = filtered.filter((d) => d.status === options.status)
    }

    if (options?.issueId) {
      filtered = filtered.filter((d) => d.issueId === options.issueId)
    }


    return filtered.sort(
      (a, b) => new Date(b.startedAt).getTime() - new Date(a.startedAt).getTime()
    )
  }

  /**
   * Mark a delegation as complete with result
   */
  async complete(delegationId: string, result: string): Promise<boolean> {
    const delegation = await this.get(delegationId)
    if (!delegation) return false

    delegation.status = "completed"
    delegation.result = result
    delegation.completedAt = new Date().toISOString()

    await this.save(delegation)


    await this.persistResult(delegation)

    await this.log.info(`Delegation ${delegationId} completed`)

    return true
  }

  /**
   * Mark a delegation as failed
   */
  async fail(delegationId: string, error: string): Promise<boolean> {
    const delegation = await this.get(delegationId)
    if (!delegation) return false

    delegation.status = "failed"
    delegation.error = error
    delegation.completedAt = new Date().toISOString()

    await this.save(delegation)

    await this.log.warn(`Delegation ${delegationId} failed: ${error}`)

    return true
  }

  /**
   * Cancel a delegation
   */
  async cancel(delegationId: string): Promise<boolean> {
    const delegation = await this.get(delegationId)
    if (!delegation) return false

    if (delegation.status === "completed" || delegation.status === "failed") {
      return false // Can't cancel finished delegations
    }

    delegation.status = "cancelled"
    delegation.completedAt = new Date().toISOString()

    await this.save(delegation)

    await this.log.info(`Delegation ${delegationId} cancelled`)

    return true
  }

  /**
   * Check if all delegations for an issue are complete
   */
  async areAllComplete(issueId: string): Promise<boolean> {
    const delegations = await this.list({ issueId })

    if (delegations.length === 0) return true

    return delegations.every(
      (d) => d.status === "completed" || d.status === "failed" || d.status === "cancelled"
    )
  }

  /**
   * Get pending/running delegations for an issue
   */
  async getActiveDelegations(issueId: string): Promise<Delegation[]> {
    const delegations = await this.list({ issueId })

    return delegations.filter(
      (d) => d.status === "pending" || d.status === "running"
    )
  }

  /**
   * Generate a unique delegation ID
   */
  private generateId(): string {
    const timestamp = Date.now().toString(36)
    const random = crypto.randomBytes(4).toString("hex")
    return `del-${timestamp}-${random}`
  }

  /**
   * Save a delegation to disk
   */
  private async save(delegation: Delegation): Promise<void> {
    await fs.mkdir(this.delegationsDir, { recursive: true })
    const filePath = path.join(this.delegationsDir, `${delegation.id}.json`)
    await fs.writeFile(filePath, JSON.stringify(delegation, null, 2), "utf8")
  }

  /**
   * Build the full prompt for a delegation
   */
  private buildPrompt(delegation: Delegation): string {
    const lines: string[] = []

    lines.push(`# Delegated Task: ${delegation.issueId}`)
    lines.push("")
    lines.push(`**Project:** ${delegation.projectId}`)
    lines.push(`**Delegation ID:** ${delegation.id}`)

    if (delegation.worktreePath) {
      lines.push(`**Worktree:** ${delegation.worktreePath}`)
      lines.push("")
      lines.push("You are working in an isolated worktree. Make your changes there.")
    }

    lines.push("")
    lines.push("## Task")
    lines.push("")
    lines.push(delegation.prompt)
    lines.push("")
    lines.push("## Instructions")
    lines.push("")
    lines.push("1. Complete the task described above")
    lines.push("2. Commit your changes with clear commit messages")
    lines.push("3. Provide a summary of what you accomplished")

    return lines.join("\n")
  }

  /**
   * Persist delegation result to research directory
   */
  private async persistResult(delegation: Delegation): Promise<void> {
    await fs.mkdir(this.researchDir, { recursive: true })

    const filename = `delegation-${delegation.id}.md`
    const filePath = path.join(this.researchDir, filename)

    const lines: string[] = []

    lines.push(`# Delegation: ${delegation.issueId}`)
    lines.push("")
    lines.push(`**ID:** ${delegation.id}`)
    lines.push(`**Project:** ${delegation.projectId}`)
    lines.push(`**Issue:** ${delegation.issueId}`)
    lines.push(`**Status:** ${delegation.status}`)
    lines.push(`**Started:** ${delegation.startedAt}`)
    lines.push(`**Completed:** ${delegation.completedAt || "N/A"}`)

    if (delegation.agent) {
      lines.push(`**Agent:** ${delegation.agent}`)
    }

    if (delegation.worktreePath) {
      lines.push(`**Worktree:** ${delegation.worktreePath}`)
    }

    lines.push("")
    lines.push("## Prompt")
    lines.push("")
    lines.push(delegation.prompt)
    lines.push("")

    if (delegation.result) {
      lines.push("## Result")
      lines.push("")
      lines.push(delegation.result)
      lines.push("")
    }

    if (delegation.error) {
      lines.push("## Error")
      lines.push("")
      lines.push(delegation.error)
      lines.push("")
    }

    lines.push("---")
    lines.push("")
    lines.push(`*Generated: ${new Date().toISOString()}*`)

    await fs.writeFile(filePath, lines.join("\n"), "utf8")
  }
}
