/**
 * Implementation Pipeline
 *
 * Fully implements a feature with tests and reviews.
 *
 * Stages:
 * 1. analyzeRequirements - Understand requirements and existing code
 * 2. design - Create design with appropriate experts
 * 3. implement - Implement the feature with tests
 * 4. test - Run tests and validate implementation
 * 5. codeReview - Perform code review
 * 6. securityReview - Perform security review
 * 7. wrapUp - Finalize and create follow-up issues
 */

import type { IssueStorage, IssueRecord } from "opencode-planner-core";
import type { ImplementationResult, DiscoveredWorkItem, ReviewFinding } from "../types.js";

export interface ImplementationStageResult<T> {
  stage: string;
  status: "completed" | "failed";
  data?: T;
  error?: string;
}

export interface AnalyzedRequirements {
  requirements: string[];
  acceptanceCriteria: string[];
  existingCode: {
    relevantFiles: string[];
    patterns: string[];
    testFiles: string[];
  };
  dependencies: string[];
  estimatedComplexity: "low" | "medium" | "high";
}

export interface DesignArtifact {
  approach: string;
  components: Array<{
    name: string;
    responsibility: string;
    interfaces: string[];
  }>;
  dataFlow: string;
  testStrategy: string;
  risks: string[];
  mitigations: string[];
}

export interface ImplementationArtifact {
  filesCreated: string[];
  filesModified: string[];
  linesAdded: number;
  linesRemoved: number;
  testsCreated: string[];
  notes: string[];
}

export interface TestResult {
  testsRun: number;
  testsPassed: number;
  testsFailed: number;
  testResults: Array<{
    name: string;
    passed: boolean;
    duration: number;
    error?: string;
  }>;
  coverage?: {
    lines: number;
    branches: number;
    functions: number;
  };
}

export interface CodeReviewResult {
  findings: ReviewFinding[];
  approved: boolean;
  summary: string;
  suggestedImprovements: string[];
}

export interface SecurityReviewResult {
  findings: ReviewFinding[];
  approved: boolean;
  summary: string;
  vulnerabilities: Array<{
    type: string;
    severity: "low" | "medium" | "high" | "critical";
    description: string;
    remediation: string;
  }>;
}

export interface ImplementationPipelineState {
  issueId: string;
  issue: IssueRecord;
  analyzedRequirements?: AnalyzedRequirements;
  design?: DesignArtifact;
  implementation?: ImplementationArtifact;
  testResult?: TestResult;
  codeReview?: CodeReviewResult;
  securityReview?: SecurityReviewResult;
  discoveredWork?: DiscoveredWorkItem[];
  stages: ImplementationStageResult<unknown>[];
}

export interface ImplementationPipelineConfig {
  alwaysRunSecurityReview: boolean;
  maxFilesPerCommit: number;
  requiresApprovalForPublicAPIs: boolean;
  requiresApprovalForDependencyChanges: boolean;
}

const DEFAULT_CONFIG: ImplementationPipelineConfig = {
  alwaysRunSecurityReview: true,
  maxFilesPerCommit: 10,
  requiresApprovalForPublicAPIs: true,
  requiresApprovalForDependencyChanges: true,
};

export class ImplementationPipeline {
  private storage: IssueStorage;
  private config: ImplementationPipelineConfig;
  private state: ImplementationPipelineState | null = null;

  constructor(storage: IssueStorage, config?: Partial<ImplementationPipelineConfig>) {
    this.storage = storage;
    this.config = { ...DEFAULT_CONFIG, ...config };
  }

  /**
   * Execute the full implementation pipeline
   */
  async execute(issueId: string): Promise<ImplementationResult> {
    const issue = await this.storage.getIssue(issueId);
    if (!issue) {
      throw new Error(`Issue ${issueId} not found`);
    }

    this.state = {
      issueId,
      issue,
      stages: [],
    };

    // Stage 1: Analyze requirements
    const analyzeResult = await this.analyzeRequirements();
    this.state.stages.push(analyzeResult);
    if (analyzeResult.status === "failed") {
      return this.buildFailedResult(analyzeResult.error || "Failed to analyze requirements");
    }
    this.state.analyzedRequirements = analyzeResult.data;

    // Stage 2: Design
    const designResult = await this.design();
    this.state.stages.push(designResult);
    if (designResult.status === "failed") {
      return this.buildFailedResult(designResult.error || "Failed to create design");
    }
    this.state.design = designResult.data;

    // Stage 3: Implement
    const implementResult = await this.implement();
    this.state.stages.push(implementResult);
    if (implementResult.status === "failed") {
      return this.buildFailedResult(implementResult.error || "Failed to implement");
    }
    this.state.implementation = implementResult.data;

    // Stage 4: Test
    const testResult = await this.test();
    this.state.stages.push(testResult);
    if (testResult.status === "failed") {
      return this.buildFailedResult(testResult.error || "Tests failed");
    }
    this.state.testResult = testResult.data;

    // Stage 5: Code review
    const codeReviewResult = await this.codeReview();
    this.state.stages.push(codeReviewResult);
    if (codeReviewResult.status === "failed") {
      return this.buildFailedResult(codeReviewResult.error || "Code review failed");
    }
    this.state.codeReview = codeReviewResult.data;

    // Stage 6: Security review (if configured)
    if (this.config.alwaysRunSecurityReview) {
      const securityReviewResult = await this.securityReview();
      this.state.stages.push(securityReviewResult);
      if (securityReviewResult.status === "failed") {
        return this.buildFailedResult(securityReviewResult.error || "Security review failed");
      }
      this.state.securityReview = securityReviewResult.data;
    }

    // Stage 7: Wrap up
    const wrapUpResult = await this.wrapUp();
    this.state.stages.push(wrapUpResult);
    if (wrapUpResult.status === "failed") {
      return this.buildFailedResult(wrapUpResult.error || "Failed to wrap up");
    }
    this.state.discoveredWork = wrapUpResult.data;

    // Update the issue
    await this.updateIssueWithResults();

    return this.buildSuccessResult();
  }

  /**
   * Stage 1: Analyze requirements and existing code
   */
  private async analyzeRequirements(): Promise<ImplementationStageResult<AnalyzedRequirements>> {
    if (!this.state) {
      return { stage: "analyzeRequirements", status: "failed", error: "Pipeline not initialized" };
    }

    try {
      const description = this.state.issue.description || "";
      const title = this.state.issue.title;

      // Extract requirements
      const requirementsMatch = description.match(/(?:requirements?|specs?|specification):\s*(.+?)(?:\n\n|$)/is);
      const requirements = requirementsMatch
        ? requirementsMatch[1].split("\n").map((r) => r.replace(/^[-*]\s*/, "").trim()).filter(Boolean)
        : [title];

      // Extract acceptance criteria
      const criteriaMatch = description.match(/(?:acceptance criteria|criteria|done when):\s*(.+?)(?:\n\n|$)/is);
      const acceptanceCriteria = criteriaMatch
        ? criteriaMatch[1].split("\n").map((c) => c.replace(/^[-*]\s*/, "").trim()).filter(Boolean)
        : ["Feature is implemented and tested"];

      // TODO: In a real implementation, this would:
      // - Spawn codebase-analyst to find relevant files
      // - Identify existing patterns and test files
      // - Analyze dependencies

      return {
        stage: "analyzeRequirements",
        status: "completed",
        data: {
          requirements,
          acceptanceCriteria,
          existingCode: {
            relevantFiles: [],
            patterns: [],
            testFiles: [],
          },
          dependencies: [],
          estimatedComplexity: "medium",
        },
      };
    } catch (error: any) {
      return {
        stage: "analyzeRequirements",
        status: "failed",
        error: error?.message || String(error),
      };
    }
  }

  /**
   * Stage 2: Create design with appropriate experts
   */
  private async design(): Promise<ImplementationStageResult<DesignArtifact>> {
    if (!this.state || !this.state.analyzedRequirements) {
      return { stage: "design", status: "failed", error: "Missing analyzed requirements" };
    }

    try {
      // TODO: In a real implementation, this would:
      // - Spawn domain experts based on issue labels
      // - Have distributed-systems-architect review if needed
      // - Have security-architect review if needed
      // - Produce design document

      const design: DesignArtifact = {
        approach: "",
        components: [],
        dataFlow: "",
        testStrategy: "",
        risks: [],
        mitigations: [],
      };

      return {
        stage: "design",
        status: "completed",
        data: design,
      };
    } catch (error: any) {
      return {
        stage: "design",
        status: "failed",
        error: error?.message || String(error),
      };
    }
  }

  /**
   * Stage 3: Implement the feature with tests
   */
  private async implement(): Promise<ImplementationStageResult<ImplementationArtifact>> {
    if (!this.state || !this.state.design) {
      return { stage: "implement", status: "failed", error: "Missing design" };
    }

    try {
      // TODO: In a real implementation, this would:
      // - Spawn language expert to implement
      // - Create tests alongside implementation
      // - Follow existing patterns from analysis

      const artifact: ImplementationArtifact = {
        filesCreated: [],
        filesModified: [],
        linesAdded: 0,
        linesRemoved: 0,
        testsCreated: [],
        notes: [],
      };

      return {
        stage: "implement",
        status: "completed",
        data: artifact,
      };
    } catch (error: any) {
      return {
        stage: "implement",
        status: "failed",
        error: error?.message || String(error),
      };
    }
  }

  /**
   * Stage 4: Run tests and validate implementation
   */
  private async test(): Promise<ImplementationStageResult<TestResult>> {
    if (!this.state || !this.state.implementation) {
      return { stage: "test", status: "failed", error: "Missing implementation" };
    }

    try {
      // TODO: In a real implementation, this would:
      // - Run test suite
      // - Collect coverage metrics
      // - Report failures

      const testResult: TestResult = {
        testsRun: 0,
        testsPassed: 0,
        testsFailed: 0,
        testResults: [],
        coverage: undefined,
      };

      return {
        stage: "test",
        status: "completed",
        data: testResult,
      };
    } catch (error: any) {
      return {
        stage: "test",
        status: "failed",
        error: error?.message || String(error),
      };
    }
  }

  /**
   * Stage 5: Perform code review
   */
  private async codeReview(): Promise<ImplementationStageResult<CodeReviewResult>> {
    if (!this.state || !this.state.implementation) {
      return { stage: "codeReview", status: "failed", error: "Missing implementation" };
    }

    try {
      // TODO: In a real implementation, this would:
      // - Spawn code-reviewer-agent
      // - Review all changes
      // - Produce findings and suggestions

      const review: CodeReviewResult = {
        findings: [],
        approved: true,
        summary: "Code review pending",
        suggestedImprovements: [],
      };

      return {
        stage: "codeReview",
        status: "completed",
        data: review,
      };
    } catch (error: any) {
      return {
        stage: "codeReview",
        status: "failed",
        error: error?.message || String(error),
      };
    }
  }

  /**
   * Stage 6: Perform security review
   */
  private async securityReview(): Promise<ImplementationStageResult<SecurityReviewResult>> {
    if (!this.state || !this.state.implementation) {
      return { stage: "securityReview", status: "failed", error: "Missing implementation" };
    }

    try {
      // TODO: In a real implementation, this would:
      // - Spawn security-reviewer-agent
      // - Review for security vulnerabilities
      // - Check input validation, authorization, etc.

      const review: SecurityReviewResult = {
        findings: [],
        approved: true,
        summary: "Security review pending",
        vulnerabilities: [],
      };

      return {
        stage: "securityReview",
        status: "completed",
        data: review,
      };
    } catch (error: any) {
      return {
        stage: "securityReview",
        status: "failed",
        error: error?.message || String(error),
      };
    }
  }

  /**
   * Stage 7: Wrap up and create follow-up issues
   */
  private async wrapUp(): Promise<ImplementationStageResult<DiscoveredWorkItem[]>> {
    if (!this.state) {
      return { stage: "wrapUp", status: "failed", error: "Pipeline not initialized" };
    }

    try {
      const discoveredWork: DiscoveredWorkItem[] = [];

      // Create issues for code review findings that need follow-up
      if (this.state.codeReview) {
        for (const finding of this.state.codeReview.findings) {
          if (finding.severity === "error" || finding.severity === "warning") {
            const issue = await this.storage.createIssue({
              type: "chore",
              title: `Code review: ${finding.description.substring(0, 50)}`,
              description: `From code review of ${this.state.issueId}\n\n**Category:** ${finding.category}\n**Severity:** ${finding.severity}\n**Description:** ${finding.description}\n${finding.suggestion ? `**Suggestion:** ${finding.suggestion}` : ""}`,
              labels: ["code-review-finding", `discovered-from:${this.state.issueId}`],
              priority: finding.severity === "error" ? 1 : 2,
              parent: this.state.issue.parent,
            });

            await this.storage.createDependency(issue.id, this.state.issueId, "discovered-from");

            discoveredWork.push({
              id: issue.id,
              parentId: this.state.issueId,
              title: `Code review: ${finding.description.substring(0, 50)}`,
              type: "chore",
              description: finding.description,
              priority: finding.severity === "error" ? 1 : 2,
              createdAt: new Date().toISOString(),
            });
          }
        }
      }

      // Create issues for security review findings
      if (this.state.securityReview) {
        for (const vuln of this.state.securityReview.vulnerabilities) {
          const priority = vuln.severity === "critical" ? 0 : vuln.severity === "high" ? 1 : vuln.severity === "medium" ? 2 : 3;

          const issue = await this.storage.createIssue({
            type: "bug",
            title: `Security: ${vuln.type}`,
            description: `From security review of ${this.state.issueId}\n\n**Type:** ${vuln.type}\n**Severity:** ${vuln.severity}\n**Description:** ${vuln.description}\n**Remediation:** ${vuln.remediation}`,
            labels: ["security", "security-finding", `discovered-from:${this.state.issueId}`],
            priority,
            parent: this.state.issue.parent,
          });

          await this.storage.createDependency(issue.id, this.state.issueId, "discovered-from");

          discoveredWork.push({
            id: issue.id,
            parentId: this.state.issueId,
            title: `Security: ${vuln.type}`,
            type: "bug",
            description: vuln.description,
            priority: priority as 0 | 1 | 2 | 3 | 4,
            createdAt: new Date().toISOString(),
          });
        }
      }

      return {
        stage: "wrapUp",
        status: "completed",
        data: discoveredWork,
      };
    } catch (error: any) {
      return {
        stage: "wrapUp",
        status: "failed",
        error: error?.message || String(error),
      };
    }
  }

  /**
   * Update the issue with implementation results
   */
  private async updateIssueWithResults(): Promise<void> {
    if (!this.state) return;

    const summary = this.buildSummary();

    await this.storage.updateIssue(this.state.issueId, {
      status: "done",
      description: `${this.state.issue.description || ""}\n\n---\n## Implementation Results\n\n${summary}`,
    });
  }

  /**
   * Build a summary of the implementation
   */
  private buildSummary(): string {
    if (!this.state) return "";

    const parts: string[] = [];

    if (this.state.implementation) {
      parts.push("**Changes:**");
      parts.push(`- Files created: ${this.state.implementation.filesCreated.length}`);
      parts.push(`- Files modified: ${this.state.implementation.filesModified.length}`);
      parts.push(`- Lines added: ${this.state.implementation.linesAdded}`);
      parts.push(`- Lines removed: ${this.state.implementation.linesRemoved}`);
    }

    if (this.state.testResult) {
      parts.push("\n**Tests:**");
      parts.push(`- Tests run: ${this.state.testResult.testsRun}`);
      parts.push(`- Tests passed: ${this.state.testResult.testsPassed}`);
      parts.push(`- Tests failed: ${this.state.testResult.testsFailed}`);
    }

    if (this.state.codeReview) {
      parts.push("\n**Code Review:**");
      parts.push(`- Approved: ${this.state.codeReview.approved ? "Yes" : "No"}`);
      parts.push(`- Findings: ${this.state.codeReview.findings.length}`);
    }

    if (this.state.securityReview) {
      parts.push("\n**Security Review:**");
      parts.push(`- Approved: ${this.state.securityReview.approved ? "Yes" : "No"}`);
      parts.push(`- Vulnerabilities: ${this.state.securityReview.vulnerabilities.length}`);
    }

    if (this.state.discoveredWork && this.state.discoveredWork.length > 0) {
      parts.push("\n**Follow-up Issues:**");
      for (const task of this.state.discoveredWork) {
        parts.push(`- ${task.id}: ${task.title}`);
      }
    }

    return parts.join("\n");
  }

  /**
   * Build a successful result
   */
  private buildSuccessResult(): ImplementationResult {
    if (!this.state) {
      throw new Error("Pipeline state not initialized");
    }

    const allFindings: ReviewFinding[] = [];
    if (this.state.codeReview) {
      allFindings.push(...this.state.codeReview.findings);
    }

    const securityFindings: ReviewFinding[] = [];
    if (this.state.securityReview) {
      securityFindings.push(...this.state.securityReview.findings);
    }

    return {
      issueId: this.state.issueId,
      status: "completed",
      changes: {
        filesModified: (this.state.implementation?.filesCreated.length || 0) +
          (this.state.implementation?.filesModified.length || 0),
        linesAdded: this.state.implementation?.linesAdded || 0,
        linesRemoved: this.state.implementation?.linesRemoved || 0,
      },
      testsRun: this.state.testResult?.testsRun || 0,
      testsPassed: this.state.testResult?.testsPassed || 0,
      testsFailed: this.state.testResult?.testsFailed || 0,
      codeReviewFindings: allFindings,
      securityReviewFindings: securityFindings,
      discoveredWork: this.state.discoveredWork || [],
    };
  }

  /**
   * Build a failed result
   */
  private buildFailedResult(error: string): ImplementationResult {
    return {
      issueId: this.state?.issueId || "",
      status: "failed",
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
   * Get the current pipeline state (for testing/debugging)
   */
  getState(): ImplementationPipelineState | null {
    return this.state;
  }
}
