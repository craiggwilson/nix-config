/**
 * Review Pipeline
 *
 * Provides code or security review for existing work.
 *
 * Stages:
 * 1. fetchTarget - Fetch the target code/PR to review
 * 2. analyze - Analyze the code for issues
 * 3. produceFindings - Generate structured findings
 * 4. createFollowUps - Create follow-up issues for findings
 */

import type { IssueStorage, IssueRecord } from "opencode-planner-core";
import type { SubagentDispatcher, SubagentResult } from "../../../core/src/orchestration/subagent-dispatcher.js";
import type { ReviewResult, ReviewFinding, DiscoveredWorkItem, ReviewMode } from "../types.js";

export interface ReviewStageResult<T> {
  stage: string;
  status: "completed" | "failed";
  data?: T;
  error?: string;
}

export interface FetchedTarget {
  targetType: "pr" | "commit" | "files" | "issue";
  targetRef: string;
  files: Array<{
    path: string;
    content: string;
    diff?: string;
  }>;
  metadata: {
    author?: string;
    title?: string;
    description?: string;
    labels?: string[];
  };
}

export interface AnalysisResult {
  codeQuality: {
    issues: Array<{
      type: string;
      severity: "info" | "warning" | "error";
      location: string;
      message: string;
      suggestion?: string;
    }>;
  };
  security: {
    vulnerabilities: Array<{
      type: string;
      severity: "low" | "medium" | "high" | "critical";
      location: string;
      description: string;
      remediation: string;
    }>;
  };
  patterns: {
    violations: Array<{
      pattern: string;
      location: string;
      message: string;
    }>;
  };
}

export interface ProducedFindings {
  findings: ReviewFinding[];
  summary: string;
  overallAssessment: "approve" | "request-changes" | "comment";
  criticalIssues: number;
  warnings: number;
  suggestions: number;
}

export interface ReviewPipelineState {
  issueId: string;
  issue: IssueRecord;
  mode: ReviewMode;
  fetchedTarget?: FetchedTarget;
  analysisResult?: AnalysisResult;
  producedFindings?: ProducedFindings;
  followUpIssues?: DiscoveredWorkItem[];
  agentResults?: SubagentResult[];
  stages: ReviewStageResult<unknown>[];
}

export class ReviewPipeline {
  private storage: IssueStorage;
  private dispatcher?: SubagentDispatcher;
  private state: ReviewPipelineState | null = null;

  constructor(storage: IssueStorage, options?: { dispatcher?: SubagentDispatcher }) {
    this.storage = storage;
    this.dispatcher = options?.dispatcher;
  }

  /**
   * Execute the review pipeline
   */
  async execute(issueId: string, mode: ReviewMode): Promise<ReviewResult> {
    const issue = await this.storage.getIssue(issueId);
    if (!issue) {
      throw new Error(`Issue ${issueId} not found`);
    }

    this.state = {
      issueId,
      issue,
      mode,
      stages: [],
    };

    // Stage 1: Fetch the target
    const fetchResult = await this.fetchTarget();
    this.state.stages.push(fetchResult);
    if (fetchResult.status === "failed") {
      return this.buildFailedResult(fetchResult.error || "Failed to fetch target");
    }
    this.state.fetchedTarget = fetchResult.data;

    // Stage 2: Analyze the code
    const analyzeResult = await this.analyze();
    this.state.stages.push(analyzeResult);
    if (analyzeResult.status === "failed") {
      return this.buildFailedResult(analyzeResult.error || "Failed to analyze");
    }
    this.state.analysisResult = analyzeResult.data;

    // Stage 3: Produce findings
    const findingsResult = await this.produceFindings();
    this.state.stages.push(findingsResult);
    if (findingsResult.status === "failed") {
      return this.buildFailedResult(findingsResult.error || "Failed to produce findings");
    }
    this.state.producedFindings = findingsResult.data;

    // Stage 4: Create follow-up issues
    const followUpsResult = await this.createFollowUps();
    this.state.stages.push(followUpsResult);
    if (followUpsResult.status === "failed") {
      return this.buildFailedResult(followUpsResult.error || "Failed to create follow-ups");
    }
    this.state.followUpIssues = followUpsResult.data;

    // Update the issue with review results
    await this.updateIssueWithResults();

    return this.buildSuccessResult();
  }

  /**
   * Stage 1: Fetch the target code/PR to review
   */
  private async fetchTarget(): Promise<ReviewStageResult<FetchedTarget>> {
    if (!this.state) {
      return { stage: "fetchTarget", status: "failed", error: "Pipeline not initialized" };
    }

    try {
      const description = this.state.issue.description || "";

      // Try to extract target reference from description
      const prMatch = description.match(/(?:pr|pull request)[:\s#]*(\d+)/i);
      const commitMatch = description.match(/(?:commit|sha)[:\s]*([a-f0-9]{7,40})/i);
      const filesMatch = description.match(/(?:files?|paths?)[:\s]*(.+?)(?:\n|$)/i);

      let targetType: "pr" | "commit" | "files" | "issue" = "issue";
      let targetRef = this.state.issueId;

      if (prMatch) {
        targetType = "pr";
        targetRef = prMatch[1];
      } else if (commitMatch) {
        targetType = "commit";
        targetRef = commitMatch[1];
      } else if (filesMatch) {
        targetType = "files";
        targetRef = filesMatch[1].trim();
      }

      // TODO: In a real implementation, this would:
      // - Fetch PR diff from GitHub/GitLab
      // - Fetch commit changes
      // - Read specified files from codebase

      return {
        stage: "fetchTarget",
        status: "completed",
        data: {
          targetType,
          targetRef,
          files: [],
          metadata: {
            title: this.state.issue.title,
            description: this.state.issue.description,
            labels: this.state.issue.labels,
          },
        },
      };
    } catch (error: any) {
      return {
        stage: "fetchTarget",
        status: "failed",
        error: error?.message || String(error),
      };
    }
  }

  /**
   * Stage 2: Analyze the code for issues
   */
  private async analyze(): Promise<ReviewStageResult<AnalysisResult>> {
    if (!this.state || !this.state.fetchedTarget) {
      return { stage: "analyze", status: "failed", error: "Missing fetched target" };
    }

    try {
      const result: AnalysisResult = {
        codeQuality: { issues: [] },
        security: { vulnerabilities: [] },
        patterns: { violations: [] },
      };

      // Use dispatcher to run appropriate reviewer agents based on mode
      if (this.dispatcher) {
        const reviewAgents: string[] = [];
        if (this.state.mode === "code-review" || this.state.mode === "both") {
          reviewAgents.push("code-reviewer-agent");
        }
        if (this.state.mode === "security-review" || this.state.mode === "both") {
          reviewAgents.push("security-reviewer-agent");
        }

        if (reviewAgents.length > 0) {
          const results = await this.dispatcher.dispatchParallel(reviewAgents, {
            issueId: this.state.issueId,
            taskType: "review",
            context: {
              title: this.state.issue.title,
              description: this.state.issue.description,
              labels: this.state.issue.labels,
            },
            instructions: `Perform ${this.state.mode} review for: ${this.state.issue.title}`,
          });
          this.state.agentResults = results;
        }
      }

      return {
        stage: "analyze",
        status: "completed",
        data: result,
      };
    } catch (error: any) {
      return {
        stage: "analyze",
        status: "failed",
        error: error?.message || String(error),
      };
    }
  }

  /**
   * Stage 3: Produce structured findings
   */
  private async produceFindings(): Promise<ReviewStageResult<ProducedFindings>> {
    if (!this.state || !this.state.analysisResult) {
      return { stage: "produceFindings", status: "failed", error: "Missing analysis result" };
    }

    try {
      const findings: ReviewFinding[] = [];
      let criticalIssues = 0;
      let warnings = 0;
      let suggestions = 0;

      // Convert code quality issues to findings
      for (const issue of this.state.analysisResult.codeQuality.issues) {
        const finding: ReviewFinding = {
          severity: issue.severity,
          category: `code-quality:${issue.type}`,
          description: issue.message,
          location: issue.location,
          suggestion: issue.suggestion,
        };
        findings.push(finding);

        if (issue.severity === "error") criticalIssues++;
        else if (issue.severity === "warning") warnings++;
        else suggestions++;
      }

      // Convert security vulnerabilities to findings
      for (const vuln of this.state.analysisResult.security.vulnerabilities) {
        const severity = vuln.severity === "critical" || vuln.severity === "high" ? "error" : vuln.severity === "medium" ? "warning" : "info";
        const finding: ReviewFinding = {
          severity,
          category: `security:${vuln.type}`,
          description: vuln.description,
          location: vuln.location,
          suggestion: vuln.remediation,
        };
        findings.push(finding);

        if (severity === "error") criticalIssues++;
        else if (severity === "warning") warnings++;
        else suggestions++;
      }

      // Convert pattern violations to findings
      for (const violation of this.state.analysisResult.patterns.violations) {
        const finding: ReviewFinding = {
          severity: "warning",
          category: `pattern:${violation.pattern}`,
          description: violation.message,
          location: violation.location,
        };
        findings.push(finding);
        warnings++;
      }

      // Determine overall assessment
      let overallAssessment: "approve" | "request-changes" | "comment" = "approve";
      if (criticalIssues > 0) {
        overallAssessment = "request-changes";
      } else if (warnings > 0) {
        overallAssessment = "comment";
      }

      // Build summary
      const summaryParts: string[] = [];
      if (criticalIssues > 0) {
        summaryParts.push(`${criticalIssues} critical issue(s)`);
      }
      if (warnings > 0) {
        summaryParts.push(`${warnings} warning(s)`);
      }
      if (suggestions > 0) {
        summaryParts.push(`${suggestions} suggestion(s)`);
      }

      const summary = summaryParts.length > 0
        ? `Review found: ${summaryParts.join(", ")}`
        : "No issues found";

      return {
        stage: "produceFindings",
        status: "completed",
        data: {
          findings,
          summary,
          overallAssessment,
          criticalIssues,
          warnings,
          suggestions,
        },
      };
    } catch (error: any) {
      return {
        stage: "produceFindings",
        status: "failed",
        error: error?.message || String(error),
      };
    }
  }

  /**
   * Stage 4: Create follow-up issues for findings
   */
  private async createFollowUps(): Promise<ReviewStageResult<DiscoveredWorkItem[]>> {
    if (!this.state || !this.state.producedFindings) {
      return { stage: "createFollowUps", status: "failed", error: "Missing produced findings" };
    }

    try {
      const followUps: DiscoveredWorkItem[] = [];

      // Create issues for critical findings
      for (const finding of this.state.producedFindings.findings) {
        if (finding.severity !== "error") continue;

        const issueType = finding.category.startsWith("security:") ? "bug" : "chore";
        const labels = [
          "review-finding",
          finding.category.split(":")[0],
          `discovered-from:${this.state.issueId}`,
        ];

        const issue = await this.storage.createIssue({
          type: issueType,
          title: `${finding.category}: ${finding.description.substring(0, 50)}`,
          description: `From review of ${this.state.issueId}\n\n**Category:** ${finding.category}\n**Severity:** ${finding.severity}\n**Location:** ${finding.location || "N/A"}\n**Description:** ${finding.description}\n${finding.suggestion ? `**Suggestion:** ${finding.suggestion}` : ""}`,
          labels,
          priority: 1,
          parent: this.state.issue.parent,
        });

        await this.storage.createDependency(issue.id, this.state.issueId, "discovered-from");

        followUps.push({
          id: issue.id,
          parentId: this.state.issueId,
          title: `${finding.category}: ${finding.description.substring(0, 50)}`,
          type: issueType as "bug" | "chore" | "task" | "feature",
          description: finding.description,
          priority: 1,
          createdAt: new Date().toISOString(),
        });
      }

      return {
        stage: "createFollowUps",
        status: "completed",
        data: followUps,
      };
    } catch (error: any) {
      return {
        stage: "createFollowUps",
        status: "failed",
        error: error?.message || String(error),
      };
    }
  }

  /**
   * Update the issue with review results
   */
  private async updateIssueWithResults(): Promise<void> {
    if (!this.state) return;

    const summary = this.buildSummary();

    await this.storage.updateIssue(this.state.issueId, {
      status: "done",
      description: `${this.state.issue.description || ""}\n\n---\n## Review Results\n\n${summary}`,
    });
  }

  /**
   * Build a summary of the review
   */
  private buildSummary(): string {
    if (!this.state) return "";

    const parts: string[] = [];

    parts.push(`**Review Mode:** ${this.state.mode}`);

    if (this.state.fetchedTarget) {
      parts.push(`**Target:** ${this.state.fetchedTarget.targetType} - ${this.state.fetchedTarget.targetRef}`);
    }

    if (this.state.producedFindings) {
      parts.push(`\n**Assessment:** ${this.state.producedFindings.overallAssessment}`);
      parts.push(`**Summary:** ${this.state.producedFindings.summary}`);

      if (this.state.producedFindings.findings.length > 0) {
        parts.push("\n**Findings:**");
        for (const finding of this.state.producedFindings.findings) {
          const icon = finding.severity === "error" ? "🔴" : finding.severity === "warning" ? "🟡" : "🔵";
          parts.push(`- ${icon} [${finding.category}] ${finding.description}`);
        }
      }
    }

    if (this.state.followUpIssues && this.state.followUpIssues.length > 0) {
      parts.push("\n**Follow-up Issues:**");
      for (const issue of this.state.followUpIssues) {
        parts.push(`- ${issue.id}: ${issue.title}`);
      }
    }

    return parts.join("\n");
  }

  /**
   * Build a successful result
   */
  private buildSuccessResult(): ReviewResult {
    if (!this.state) {
      throw new Error("Pipeline state not initialized");
    }

    return {
      issueId: this.state.issueId,
      mode: this.state.mode,
      findings: this.state.producedFindings?.findings || [],
      summary: this.state.producedFindings?.summary || "",
      followUpIssues: this.state.followUpIssues || [],
    };
  }

  /**
   * Build a failed result
   */
  private buildFailedResult(error: string): ReviewResult {
    return {
      issueId: this.state?.issueId || "",
      mode: this.state?.mode || "code-review",
      findings: [],
      summary: `Review failed: ${error}`,
      followUpIssues: [],
    };
  }

  /**
   * Get the current pipeline state (for testing/debugging)
   */
  getState(): ReviewPipelineState | null {
    return this.state;
  }
}
