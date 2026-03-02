/**
 * BeadsIssueStorage - Issue storage implementation using beads CLI
 *
 * SECURITY: All user-provided strings (titles, descriptions, comments, etc.)
 * are passed directly to BeadsClient.execute() WITHOUT manual quoting.
 * The BeadsClient uses buildCommand() which properly escapes all shell
 * metacharacters. Never add manual quote escaping here - it bypasses the
 * security fix and remains vulnerable to backticks and $() injection.
 */

import * as fs from "node:fs/promises"
import * as path from "node:path"

import type {
  IssueStorage,
  Issue,
  CreateIssueOptions,
  IssueStatus,
  ListIssuesOptions,
  UpdateIssueOptions,
  IssueDelegationMetadata,
  ProjectStatus,
  IssueStorageError,
} from "../index.js"
import { StorageOperationError } from "../index.js"
import type { BunShell, Logger } from "../../utils/opencode-sdk/index.js"
import type { Result } from "../../utils/result/index.js"
import { ok, err } from "../../utils/result/index.js"
import { BeadsClient } from "./client.js"
import { BeadsResponseParser } from "./response-parser.js"
import { mapBeadsResult } from "./error-mapper.js"

/**
 * BeadsIssueStorage - High-level CRUD operations for beads issues
 */
export class BeadsIssueStorage implements IssueStorage {
  private client: BeadsClient
  private parser: BeadsResponseParser
  private log: Logger

  constructor(log: Logger) {
    this.log = log
    this.client = new BeadsClient()
    this.parser = new BeadsResponseParser()
  }

  /**
   * Set the shell to use for commands
   */
  setShell($: BunShell): void {
    this.client.setShell($)
  }

  async isAvailable(): Promise<Result<boolean, IssueStorageError>> {
    return mapBeadsResult(await this.client.isAvailable())
  }

  async init(projectDir: string, options?: { stealth?: boolean }): Promise<Result<void, IssueStorageError>> {
    const args = options?.stealth ? ["init", "--stealth"] : ["init"]
    const result = await this.client.execute(args, projectDir)
    if (!result.ok) {
      await this.log.error(`Storage init failed: ${result.error.message}`)
      return mapBeadsResult(result)
    }
    return ok(undefined)
  }

  async isInitialized(projectDir: string): Promise<Result<boolean, IssueStorageError>> {
    try {
      const beadsDir = path.join(projectDir, ".beads")
      await fs.access(beadsDir)
      return ok(true)
    } catch {
      return ok(false)
    }
  }

  async createIssue(
    projectDir: string,
    title: string,
    options?: CreateIssueOptions
  ): Promise<Result<string, IssueStorageError>> {
    // Arguments are escaped by buildCommand() in BeadsClient - no manual quoting needed
    const args: string[] = ["create", "--force", title]

    if (options?.priority !== undefined) {
      args.push("-p", String(options.priority))
    }
    if (options?.parent) {
      args.push("--parent", options.parent)
    }
    if (options?.description) {
      args.push("-d", options.description)
    }
    if (options?.labels?.length) {
      for (const label of options.labels) {
        args.push("-l", label)
      }
    }

    const result = await this.client.execute(args, projectDir)
    if (!result.ok) {
      await this.log.error(`Issue creation failed: ${result.error.message}`)
      return mapBeadsResult(result)
    }

    const match = result.value.stdout.match(/Created issue:\s+([\w.-]+)/)
    if (match) return ok(match[1])

    const altMatch = result.value.stdout.match(/✓\s+Created issue:\s+([\w.-]+)/)
    if (altMatch) return ok(altMatch[1])

    const idMatch = result.value.stdout.match(/[\w]+-[a-z0-9.]+/)
    if (idMatch) return ok(idMatch[0])

    return err(
      new StorageOperationError(
        "Failed to parse issue ID from storage output",
        "The command succeeded but the output format was unexpected"
      )
    )
  }

  async getIssue(issueId: string, projectDir: string): Promise<Result<Issue, IssueStorageError>> {
    const result = await this.client.execute(["show", issueId, "--json"], projectDir)
    if (!result.ok) {
      await this.log.debug(`Get issue ${issueId} failed: ${result.error.message}`)
      return mapBeadsResult(result)
    }

    const jsonResult = this.parser.parseJSON(result.value.stdout)
    if (!jsonResult.ok) {
      await this.log.error(`Get issue ${issueId} returned invalid JSON: ${jsonResult.error.message}`)
      return mapBeadsResult(jsonResult)
    }

    if (!Array.isArray(jsonResult.value) || jsonResult.value.length === 0) {
      await this.log.debug(`Get issue ${issueId} returned empty array`)
      return err(
        new StorageOperationError(
          `Issue ${issueId} not found`,
          "Check that the issue ID is correct"
        )
      )
    }

    const parseResult = this.parser.parseIssue(jsonResult.value[0])
    if (!parseResult.ok) {
      await this.log.error(
        `Get issue ${issueId} returned invalid issue data: ${parseResult.error.message}`
      )
      return mapBeadsResult(parseResult)
    }

    return ok(parseResult.value)
  }

  async listIssues(projectDir: string, options?: ListIssuesOptions): Promise<Result<Issue[], IssueStorageError>> {
    const args = ["list", "--json"]

    if (options?.all) {
      args.push("--all")
    } else if (options?.status) {
      args.push("--status", options.status)
    }

    const result = await this.client.execute(args, projectDir)
    if (!result.ok) {
      await this.log.debug(`List issues failed: ${result.error.message}`)
      return mapBeadsResult(result)
    }

    const jsonResult = this.parser.parseJSON(result.value.stdout)
    if (!jsonResult.ok) {
      await this.log.error(`List issues returned invalid JSON: ${jsonResult.error.message}`)
      return mapBeadsResult(jsonResult)
    }

    const parseResult = this.parser.parseIssueArray(jsonResult.value)
    if (!parseResult.ok) {
      await this.log.error(`List issues returned invalid issue data: ${parseResult.error.message}`)
      return mapBeadsResult(parseResult)
    }

    return ok(parseResult.value)
  }

  async updateIssue(
    issueId: string,
    projectDir: string,
    options: UpdateIssueOptions
  ): Promise<Result<void, IssueStorageError>> {
    const args = ["update", issueId]

    if (options.status) {
      args.push("--status", options.status)
    }
    if (options.priority !== undefined) {
      args.push("-p", String(options.priority))
    }
    if (options.description) {
      args.push("-d", options.description)
    }
    if (options.assignee) {
      args.push("--assignee", options.assignee)
    }

    const result = await this.client.execute(args, projectDir)
    if (!result.ok) {
      await this.log.error(`Update issue failed: ${result.error.message}`)
      return mapBeadsResult(result)
    }

    return ok(undefined)
  }

  async getReadyIssues(projectDir: string): Promise<Result<Issue[], IssueStorageError>> {
    const result = await this.client.execute(["list", "--ready", "--json"], projectDir)

    if (!result.ok) {
      await this.log.debug(`Get ready issues failed, falling back to filter: ${result.error.message}`)
      const allIssuesResult = await this.listIssues(projectDir, { status: "open" })
      if (!allIssuesResult.ok) {
        return allIssuesResult
      }
      return ok(allIssuesResult.value.filter((i) => !i.blockedBy || i.blockedBy.length === 0))
    }

    const jsonResult = this.parser.parseJSON(result.value.stdout)
    if (!jsonResult.ok) {
      await this.log.error(`Get ready issues returned invalid JSON: ${jsonResult.error.message}`)
      return mapBeadsResult(jsonResult)
    }

    const parseResult = this.parser.parseIssueArray(jsonResult.value)
    if (!parseResult.ok) {
      await this.log.error(
        `Get ready issues returned invalid issue data: ${parseResult.error.message}`
      )
      return mapBeadsResult(parseResult)
    }

    return ok(parseResult.value)
  }

  async claimIssue(issueId: string, projectDir: string, assignee?: string): Promise<Result<void, IssueStorageError>> {
    const args = ["update", issueId, "--status", "in_progress"]
    if (assignee) {
      args.push("--assignee", assignee)
    }

    const result = await this.client.execute(args, projectDir)
    if (!result.ok) {
      await this.log.debug(`Claim issue ${issueId} failed: ${result.error.message}`)
      return mapBeadsResult(result)
    }
    return ok(undefined)
  }

  async updateStatus(issueId: string, status: IssueStatus, projectDir: string): Promise<Result<void, IssueStorageError>> {
    const result = await this.client.execute(["update", issueId, "--status", status], projectDir)
    if (!result.ok) {
      await this.log.debug(`Update status ${issueId} to ${status} failed: ${result.error.message}`)
      return mapBeadsResult(result)
    }
    return ok(undefined)
  }

  async setDelegationMetadata(
    issueId: string,
    projectDir: string,
    metadata: IssueDelegationMetadata
  ): Promise<Result<void, IssueStorageError>> {
    const label = `delegation:${metadata.delegationId}:${metadata.delegationStatus}`
    const result = await this.client.execute(["update", issueId, "-l", label], projectDir)
    if (!result.ok) {
      await this.log.error(`Set delegation metadata failed: ${result.error.message}`)
      return mapBeadsResult(result)
    }
    return ok(undefined)
  }

  async getDelegationMetadata(
    issueId: string,
    projectDir: string
  ): Promise<Result<IssueDelegationMetadata | null, IssueStorageError>> {
    const issueResult = await this.getIssue(issueId, projectDir)
    if (!issueResult.ok) {
      await this.log.debug(`Get delegation metadata ${issueId} failed: ${issueResult.error.message}`)
      return issueResult
    }

    const issue = issueResult.value
    if (!issue.labels) return ok(null)

    const delegationLabel = issue.labels.find((l) => l.startsWith("delegation:"))
    if (!delegationLabel) return ok(null)

    const parts = delegationLabel.split(":")
    if (parts.length < 3) return ok(null)

    return ok({
      delegationId: parts[1],
      delegationStatus: parts[2],
    })
  }

  async clearDelegationMetadata(issueId: string, projectDir: string): Promise<Result<void, IssueStorageError>> {
    const issueResult = await this.getIssue(issueId, projectDir)
    if (!issueResult.ok) {
      await this.log.error(`Clear delegation metadata failed: ${issueResult.error.message}`)
      return issueResult
    }

    const issue = issueResult.value
    if (!issue.labels) return ok(undefined)

    const delegationLabel = issue.labels.find((l) => l.startsWith("delegation:"))
    if (!delegationLabel) return ok(undefined)

    const result = await this.client.execute(
      ["update", issueId, "--remove-label", delegationLabel],
      projectDir
    )
    if (!result.ok) {
      await this.log.error(`Clear delegation metadata failed: ${result.error.message}`)
      return mapBeadsResult(result)
    }
    return ok(undefined)
  }

  async addComment(issueId: string, projectDir: string, comment: string): Promise<Result<void, IssueStorageError>> {
    // Arguments are escaped by buildCommand() in BeadsClient - no manual quoting needed
    const result = await this.client.execute(
      ["comment", issueId, comment],
      projectDir
    )
    if (!result.ok) {
      await this.log.error(`Add comment failed: ${result.error.message}`)
      return mapBeadsResult(result)
    }
    return ok(undefined)
  }

  async addDependency(childId: string, parentId: string, projectDir: string): Promise<Result<void, IssueStorageError>> {
    const result = await this.client.execute(["update", childId, "--blocked-by", parentId], projectDir)
    if (!result.ok) {
      await this.log.error(`Add dependency failed: ${result.error.message}`)
      return mapBeadsResult(result)
    }
    return ok(undefined)
  }

  async getProjectStatus(projectDir: string): Promise<Result<ProjectStatus, IssueStorageError>> {
    // Must fetch all issues including closed ones to calculate accurate progress
    const issuesResult = await this.listIssues(projectDir, { all: true })
    if (!issuesResult.ok) {
      await this.log.debug(`Get project status failed: ${issuesResult.error.message}`)
      return issuesResult
    }

    const issues = issuesResult.value
    const total = issues.length
    const completed = issues.filter((i) => i.status === "closed").length
    const inProgress = issues.filter((i) => i.status === "in_progress").length

    // Build a map for efficient lookup of issue status by ID
    const issueMap = new Map(issues.map((i) => [i.id, i]))

    // An issue is blocked only if it has blockers AND at least one blocker is not closed
    const blockedIssues = issues.filter((i) => {
      if (!i.blockedBy || i.blockedBy.length === 0) return false
      return i.blockedBy.some((blockerId) => {
        const blocker = issueMap.get(blockerId)
        return blocker && blocker.status !== "closed"
      })
    })

    const blockers = blockedIssues.map((i) => ({
      issueId: i.id,
      title: i.title,
      blockedBy: i.blockedBy || [],
    }))

    return ok({
      total,
      completed,
      inProgress,
      blocked: blockedIssues.length,
      blockers,
    })
  }

  async getChildren(issueId: string, projectDir: string): Promise<Result<Issue[], IssueStorageError>> {
    const result = await this.client.execute(["list", "--parent", issueId, "--json"], projectDir)
    if (!result.ok) {
      await this.log.debug(`Get children ${issueId} failed: ${result.error.message}`)
      return mapBeadsResult(result)
    }

    const jsonResult = this.parser.parseJSON(result.value.stdout)
    if (!jsonResult.ok) {
      await this.log.error(
        `Get children ${issueId} returned invalid JSON: ${jsonResult.error.message}`
      )
      return mapBeadsResult(jsonResult)
    }

    const parseResult = this.parser.parseIssueArray(jsonResult.value)
    if (!parseResult.ok) {
      await this.log.error(
        `Get children ${issueId} returned invalid issue data: ${parseResult.error.message}`
      )
      return mapBeadsResult(parseResult)
    }

    return ok(parseResult.value)
  }

  async getTree(projectDir: string, rootId?: string): Promise<Result<Issue[], IssueStorageError>> {
    const args = ["tree", "--json"]
    if (rootId) {
      args.push(rootId)
    }

    const result = await this.client.execute(args, projectDir)
    if (!result.ok) {
      await this.log.debug(`Get tree failed: ${result.error.message}`)
      return mapBeadsResult(result)
    }

    const jsonResult = this.parser.parseJSON(result.value.stdout)
    if (!jsonResult.ok) {
      await this.log.error(`Get tree returned invalid JSON: ${jsonResult.error.message}`)
      return mapBeadsResult(jsonResult)
    }

    const parseResult = this.parser.parseIssueArray(jsonResult.value)
    if (!parseResult.ok) {
      await this.log.error(`Get tree returned invalid issue data: ${parseResult.error.message}`)
      return mapBeadsResult(parseResult)
    }

    return ok(parseResult.value)
  }

}
