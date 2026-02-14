/**
 * Work Executor Orchestrator
 *
 * Central dispatcher for work execution.
 * Reads planning issues from storage and coordinates specialist subagents.
  */

import { ConfigManager, IssueStorage } from "opencode-planner-core";
import type {
  WorkItem,
  ResearchResult,
  POCResult,
  ImplementationResult,
  ReviewResult,
  ReviewMode,
  ExecutionMode,
  WorkExecutorConfig,
  SubagentSelection,
} from "./types.js";

const DEFAULT_CONFIG: WorkExecutorConfig = {
  riskPosture: "medium",
  alwaysRunSecurityReview: true,
  autonomousEditLimits: {
    maxFilesPerCommit: 10,
    requiresApprovalForPublicAPIs: true,
    requiresApprovalForDependencyChanges: true,
  },
  techStackPreferences: {
    defaultLanguage: undefined,
    preferredFrameworks: [],
  },
};

export class WorkExecutorOrchestrator {
  private storage: IssueStorage;
  private config: WorkExecutorConfig;
  private configManager: ConfigManager;

  constructor(storage: IssueStorage, configManager: ConfigManager) {
    this.storage = storage;
    this.configManager = configManager;
    this.config = configManager.load("work-executor", DEFAULT_CONFIG);
  }

  /**
   * Initialize the orchestrator
   */
  async initialize(): Promise<void> {
    // No-op for now; a future implementation can validate
    // connectivity to the underlying storage backend.
  }

  /**
   * Claim a suitable ready task
   */
  async claimWork(filters?: {
    project?: string;
    program?: string;
    labels?: string[];
    type?: string;
    priority?: number;
  }): Promise<{ workItemId: string; title: string }> {
    // Use storage to find ready items (no blocking dependencies) and
    // select the best candidate according to simple heuristics.

    const projectParent = filters?.project;
    const readyItems = await this.storage.findReady(projectParent);

    const narrowed = readyItems.filter((item) => {
      if (filters?.labels && filters.labels.length > 0) {
        const labels = item.labels || [];
        if (!filters.labels.some((l) => labels.includes(l))) {
          return false;
        }
      }

      if (filters?.type && filters.type.length > 0) {
        if (!filters.type.includes(item.type)) {
          return false;
        }
      }

      if (filters?.priority !== undefined) {
        if (item.priority !== filters.priority) {
          return false;
        }
      }

      // TODO: When program-level context is modeled explicitly in
      // IssueRecord (for example via labels), filter by program here.

      return true;
    });

    if (narrowed.length === 0) {
      return {
        workItemId: "",
        title: "",
      };
    }

    // findReady already returns items sorted by priority, so take first.
    const candidate = narrowed[0];

    await this.storage.updateIssue(candidate.id, {
      status: "in_progress",
      assignee: "agent:work-executor",
    });

    return {
      workItemId: candidate.id,
      title: candidate.title,
    };
  }

  /**
   * Execute one or more work items
   */
  async executeWork(input: {
    issueIds: string[];
    mode?: ExecutionMode;
  }): Promise<{
    results: Array<{
      issueId: string;
      status: "completed" | "partial" | "failed";
      result?: unknown;
      error?: string;
    }>;
  }> {
    const mode = input.mode || "full";
    const results: Array<{
      issueId: string;
      status: "completed" | "partial" | "failed";
      result?: unknown;
      error?: string;
    }> = [];

    for (const issueId of input.issueIds) {
      try {
        const issue = await this.storage.getIssue(issueId);
        if (!issue) {
          results.push({
            issueId,
            status: "failed",
            error: "Issue not found",
          });
          continue;
        }

        const workType = this.inferWorkType(issue.labels || []);

        if (mode === "research-only" && workType !== "research") {
          results.push({
            issueId,
            status: "partial",
            result: { skipped: true, reason: "Mode research-only" },
          });
          continue;
        }

        if (mode === "poc-only" && workType !== "poc") {
          results.push({
            issueId,
            status: "partial",
            result: { skipped: true, reason: "Mode poc-only" },
          });
          continue;
        }

        let result: unknown;

        if (workType === "research") {
          result = await this.executeResearch(issueId);
        } else if (workType === "poc") {
          result = await this.executePOC(issueId);
        } else if (workType === "review") {
          // Default to code review; caller can use work-review for
          // explicit control over review mode.
          result = await this.performReview({ issueId, mode: "code-review" });
        } else {
          result = await this.executeImplementation(issueId);
        }

        results.push({
          issueId,
          status: "completed",
          result,
        });
      } catch (error: any) {
        results.push({
          issueId,
          status: "failed",
          error: error?.message || String(error),
        });
      }
    }

    return { results };
  }

  /**
   * Execute a research task
   */
  async executeResearch(issueId: string): Promise<ResearchResult> {
    const issue = await this.storage.getIssue(issueId);
    if (!issue) {
      throw new Error(`Issue ${issueId} not found`);
    }

    // TODO: Parse research question from issue description
    // TODO: Spawn domain experts to investigate
    // TODO: Produce research report
    // TODO: Create follow-up implementation tasks if needed
    // TODO: Update beads issue with findings

    return {
      issueId,
      question: "",
      summary: "",
      options: [],
      recommendation: "",
      reasoning: "",
    };
  }

  /**
   * Execute a POC task
   */
  async executePOC(issueId: string): Promise<POCResult> {
    const issue = await this.storage.getIssue(issueId);
    if (!issue) {
      throw new Error(`Issue ${issueId} not found`);
    }

    // TODO: Parse hypothesis from issue description
    // TODO: Spawn appropriate experts for minimal design
    // TODO: Implement POC with focus on speed
    // TODO: Validate hypothesis
    // TODO: Produce "Keep/Refine/Discard" recommendation
    // TODO: File discovered work issues
    // TODO: Update beads issue with outcome

    return {
      issueId,
      hypothesis: "",
      outcome: "discard",
      findings: "",
      recommendation: "",
      discoveredWork: [],
    };
  }

  /**
   * Execute an implementation task
   */
  async executeImplementation(issueId: string): Promise<ImplementationResult> {
    const issue = await this.storage.getIssue(issueId);
    if (!issue) {
      throw new Error(`Issue ${issueId} not found`);
    }

    // TODO: Analyze requirements and existing code
    // TODO: Design step (spawn experts as needed)
    // TODO: Implementation step (spawn language expert)
    // TODO: Testing step (run tests)
    // TODO: Code review step (spawn code-reviewer-agent)
    // TODO: Security review step (spawn security-reviewer-agent)
    // TODO: File discovered work issues
    // TODO: Update beads issue with status

    return {
      issueId,
      status: "completed",
      changes: {
        filesModified: 0,
        linesAdded: 0,
        linesRemoved: 0,
      },
      testsRun: 0,
      testsPassed: 0,
      testsFailed: 0,
      codeReviewFindings: [],
      securityReviewFindings: [],
      discoveredWork: [],
    };
  }

  /**
   * Perform code or security review
   */
  async performReview(input: {
    issueId: string;
    mode: ReviewMode;
  }): Promise<ReviewResult> {
    const issue = await this.storage.getIssue(input.issueId);
    if (!issue) {
      throw new Error(`Issue ${input.issueId} not found`);
    }

    // TODO: Fetch target code/PR
    // TODO: Spawn appropriate reviewer subagent(s)
    // TODO: Produce review findings
    // TODO: Create follow-up issues for findings
    // TODO: Attach review to beads issue

    return {
      issueId: input.issueId,
      mode: input.mode,
      findings: [],
      summary: "",
      followUpIssues: [],
    };
  }

  /**
   * Handle /work-claim command
   */
  async handleWorkClaim(args: string[]): Promise<void> {
    try {
      const result = await this.claimWork();
      if (result.workItemId) {
        console.log(`Claimed work item: ${result.title} (${result.workItemId})`);
      } else {
        console.log("No ready work items available");
      }
    } catch (error) {
      console.error("Error claiming work:", error);
    }
  }

  /**
   * Handle /work-execute command
   */
  async handleWorkExecute(args: string[]): Promise<void> {
    if (args.length === 0) {
      console.log("Usage: /work-execute <issue-id> [issue-id2] ... [--mode full|research-only|poc-only]");
      return;
    }

    const issueIds = args.filter((arg) => !arg.startsWith("--"));
    const modeArg = args.find((arg) => arg.startsWith("--mode"));
    const mode = modeArg ? (modeArg.split("=")[1] as any) : "full";

    try {
      const result = await this.executeWork({ issueIds, mode });
      console.log(`Executed ${result.results.length} work items`);
      for (const r of result.results) {
        console.log(`  - ${r.issueId}: ${r.status}`);
        if (r.error) {
          console.log(`    Error: ${r.error}`);
        }
      }
    } catch (error) {
      console.error("Error executing work:", error);
    }
  }

  /**
   * Handle /work-poc command
   */
  async handleWorkPOC(args: string[]): Promise<void> {
    if (args.length === 0) {
      console.log("Usage: /work-poc <issue-id> [parent-id]");
      return;
    }

    const issueId = args[0];

    try {
      const result = await this.executePOC(issueId);
      console.log(`POC Result: ${result.outcome}`);
      console.log(`Findings: ${result.findings}`);
      console.log(`Recommendation: ${result.recommendation}`);
    } catch (error) {
      console.error("Error executing POC:", error);
    }
  }

  /**
   * Handle /work-research command
   */
  async handleWorkResearch(args: string[]): Promise<void> {
    if (args.length === 0) {
      console.log("Usage: /work-research <issue-id>");
      return;
    }

    const issueId = args[0];

    try {
      const result = await this.executeResearch(issueId);
      console.log(`Research Question: ${result.question}`);
      console.log(`Summary: ${result.summary}`);
      console.log(`Recommendation: ${result.recommendation}`);
    } catch (error) {
      console.error("Error executing research:", error);
    }
  }

  /**
   * Handle /work-review command
   */
  async handleWorkReview(args: string[]): Promise<void> {
    if (args.length < 2) {
      console.log("Usage: /work-review <issue-id> <code-review|security-review|both>");
      return;
    }

    const issueId = args[0];
    const mode = args[1] as any;

    try {
      const result = await this.performReview({ issueId, mode });
      console.log(`Review Mode: ${result.mode}`);
      console.log(`Findings: ${result.findings.length}`);
      console.log(`Summary: ${result.summary}`);
    } catch (error) {
      console.error("Error performing review:", error);
    }
  }

  /**
   * Handle /work-status command
   */
  async handleWorkStatus(args: string[]): Promise<void> {
    console.log("work-status command handler - TODO");
  }

  /**
   * Select appropriate subagents for a work item
   */
  private selectSubagents(issue: unknown): SubagentSelection {
    // TODO: Parse issue labels and description
    // TODO: Detect language/domain from labels
    // TODO: Determine if distributed systems expertise needed
    // TODO: Determine if security expertise needed
    // TODO: Determine if code review needed
    // TODO: Determine if security review needed

      return {
        domains: [],
        requiresDistributedSystems: false,
        requiresSecurity: false,
        requiresCodeReview: false,
        requiresSecurityReview: this.config.alwaysRunSecurityReview,
      };
  }

  /**
   * Infer work type from issue labels.
   *
   * Falls back to "implementation" if no specific work-type label is
   * present so that generic tasks still execute.
   */
  private inferWorkType(labels: string[]): "research" | "poc" | "implementation" | "review" {
    if (labels.includes("research")) return "research";
    if (labels.includes("poc")) return "poc";
    if (labels.includes("review") || labels.includes("security-review")) return "review";
    return "implementation";
  }
}
