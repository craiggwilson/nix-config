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
import type { SubagentDispatcher, SubagentResult } from "../../../core/src/orchestration/subagent-dispatcher.js";
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
  agentResults?: SubagentResult[];
  stages: ImplementationStageResult<unknown>[];
}

export interface ImplementationPipelineConfig {
  alwaysRunSecurityReview: boolean;
  maxFilesPerCommit: number;
  requiresApprovalForPublicAPIs: boolean;
  requiresApprovalForDependencyChanges: boolean;
  dispatcher?: SubagentDispatcher;
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
  private dispatcher?: SubagentDispatcher;
  private state: ImplementationPipelineState | null = null;

  constructor(storage: IssueStorage, config?: Partial<ImplementationPipelineConfig>) {
    this.storage = storage;
    this.dispatcher = config?.dispatcher;
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

      const patterns: string[] = [];
      const relevantFiles: string[] = [];
      const testFiles: string[] = [];
      const dependencies: string[] = [];
      let estimatedComplexity: "low" | "medium" | "high" = "medium";

      // Use dispatcher to analyze codebase for relevant context
      if (this.dispatcher) {
        const agents = this.dispatcher.selectAgents(this.state.issue);
        if (agents.length > 0) {
          const results = await this.dispatcher.dispatchSmart(agents, {
            issueId: this.state.issueId,
            taskType: "analyze",
            context: {
              title: this.state.issue.title,
              description: this.state.issue.description,
              labels: this.state.issue.labels,
              parent: this.state.issue.parent,
            },
            instructions: [
              `Analyze requirements and existing code for: ${title}`,
              "",
              `Requirements: ${requirements.join("; ")}`,
              `Acceptance criteria: ${acceptanceCriteria.join("; ")}`,
              "",
              "## Instructions",
              "Search the codebase for relevant files, patterns, and test files.",
              "",
              "## Findings",
              "- Relevant source files (prefix with 'File:')",
              "- Relevant test files (prefix with 'TestFile:')",
              "- Code patterns found (prefix with 'Pattern:')",
              "- Dependencies needed (prefix with 'Dependency:')",
              "- Complexity estimate (prefix with 'Complexity:' low/medium/high)",
              "",
              "## Recommendations",
              "- Approach suggestions and existing code to leverage",
            ].join("\n"),
          });
          this.state.agentResults = results;

          for (const result of results) {
            if (result.status === "failed") continue;
            for (const finding of result.findings || []) {
              const lower = finding.toLowerCase();
              if (lower.startsWith("file:")) {
                relevantFiles.push(finding.replace(/^file:\s*/i, ""));
              } else if (lower.startsWith("testfile:")) {
                testFiles.push(finding.replace(/^testfile:\s*/i, ""));
              } else if (lower.startsWith("pattern:")) {
                patterns.push(finding.replace(/^pattern:\s*/i, ""));
              } else if (lower.startsWith("dependency:")) {
                dependencies.push(finding.replace(/^dependency:\s*/i, ""));
              } else if (lower.startsWith("complexity:")) {
                const c = finding.replace(/^complexity:\s*/i, "").toLowerCase();
                if (c.includes("high")) estimatedComplexity = "high";
                else if (c.includes("low")) estimatedComplexity = "low";
              } else {
                // Heuristic: extract file paths from general findings
                const pathMatch = finding.match(/[`']?([a-zA-Z0-9_/.-]+\.[a-zA-Z]+)[`']?/);
                if (pathMatch) {
                  const path = pathMatch[1];
                  if (path.includes("test") || path.includes("spec")) {
                    testFiles.push(path);
                  } else {
                    relevantFiles.push(path);
                  }
                } else {
                  patterns.push(finding);
                }
              }
            }
          }
        }
      }

      return {
        stage: "analyzeRequirements",
        status: "completed",
        data: {
          requirements,
          acceptanceCriteria,
          existingCode: {
            relevantFiles,
            patterns,
            testFiles,
          },
          dependencies,
          estimatedComplexity,
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
      let approach = "";
      const components: Array<{ name: string; responsibility: string; interfaces: string[] }> = [];
      let dataFlow = "";
      let testStrategy = "";
      const risks: string[] = [];
      const mitigations: string[] = [];

      // Build context from requirements analysis
      const reqContext = [
        `Requirements: ${this.state.analyzedRequirements.requirements.join("; ")}`,
        `Acceptance criteria: ${this.state.analyzedRequirements.acceptanceCriteria.join("; ")}`,
        this.state.analyzedRequirements.existingCode.patterns.length > 0
          ? `Existing patterns: ${this.state.analyzedRequirements.existingCode.patterns.join("; ")}`
          : "",
        this.state.analyzedRequirements.existingCode.relevantFiles.length > 0
          ? `Relevant files: ${this.state.analyzedRequirements.existingCode.relevantFiles.join(", ")}`
          : "",
        `Estimated complexity: ${this.state.analyzedRequirements.estimatedComplexity}`,
      ].filter(Boolean).join("\n");

      // Use dispatcher to get architecture/domain expert input
      if (this.dispatcher) {
        const agents = this.dispatcher.selectAgents(this.state.issue);
        if (agents.length > 0) {
          const results = await this.dispatcher.dispatchSmart(agents, {
            issueId: this.state.issueId,
            taskType: "design",
            context: {
              title: this.state.issue.title,
              description: this.state.issue.description,
              labels: this.state.issue.labels,
            },
            instructions: [
              `Design implementation approach for: ${this.state.issue.title}`,
              "",
              reqContext,
              "",
              "## Instructions",
              "Produce a design with components, data flow, and test strategy.",
              "",
              "## Recommendations",
              "- First bullet: overall approach",
              "- Components (prefix with 'Component: name - responsibility')",
              "- Data flow description (prefix with 'DataFlow:')",
              "- Test strategy (prefix with 'TestStrategy:')",
              "- Risk mitigations (prefix with 'Mitigation:')",
              "",
              "## Findings",
              "- Risks and concerns (prefix with 'Risk:')",
              "- Existing code that should be leveraged",
            ].join("\n"),
          });

          for (const result of results) {
            if (result.status === "failed") continue;
            for (const rec of result.recommendations || []) {
              const lower = rec.toLowerCase();
              if (lower.startsWith("component:")) {
                const parts = rec.replace(/^component:\s*/i, "").split(/\s*[-–—]\s*/);
                components.push({
                  name: parts[0]?.trim() || rec,
                  responsibility: parts[1]?.trim() || "",
                  interfaces: [],
                });
              } else if (lower.startsWith("dataflow:")) {
                dataFlow = rec.replace(/^dataflow:\s*/i, "");
              } else if (lower.startsWith("teststrategy:")) {
                testStrategy = rec.replace(/^teststrategy:\s*/i, "");
              } else if (lower.startsWith("mitigation:")) {
                mitigations.push(rec.replace(/^mitigation:\s*/i, ""));
              } else if (!approach) {
                approach = rec;
              }
            }
            for (const finding of result.findings || []) {
              const lower = finding.toLowerCase();
              if (lower.startsWith("risk:") || lower.includes("risk")) {
                risks.push(finding.replace(/^risk:\s*/i, ""));
              } else {
                // General findings may inform the design
                risks.push(finding);
              }
            }
          }
        }
      }

      const design: DesignArtifact = {
        approach,
        components,
        dataFlow,
        testStrategy,
        risks,
        mitigations,
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
      const filesCreated: string[] = [];
      const filesModified: string[] = [];
      const testsCreated: string[] = [];
      const notes: string[] = [];
      let linesAdded = 0;
      let linesRemoved = 0;

      // Build design context for the implementation agent
      const designContext = [
        `Approach: ${this.state.design.approach || "not specified"}`,
        this.state.design.components.length > 0
          ? `Components:\n${this.state.design.components.map((c) => `- ${c.name}: ${c.responsibility}`).join("\n")}`
          : "",
        this.state.design.dataFlow ? `Data flow: ${this.state.design.dataFlow}` : "",
        this.state.design.testStrategy ? `Test strategy: ${this.state.design.testStrategy}` : "",
        this.state.analyzedRequirements?.existingCode.relevantFiles.length
          ? `Relevant files: ${this.state.analyzedRequirements.existingCode.relevantFiles.join(", ")}`
          : "",
        this.state.analyzedRequirements?.existingCode.patterns.length
          ? `Existing patterns: ${this.state.analyzedRequirements.existingCode.patterns.join("; ")}`
          : "",
      ].filter(Boolean).join("\n");

      if (this.dispatcher) {
        // Select language/domain experts for implementation
        const agents = this.dispatcher.selectAgents(this.state.issue);
        // Filter to language and analysis agents for implementation
        const implAgents = agents.filter((a) => {
          const agent = this.state!.agentResults?.find((r) => r.agentName === a);
          return true; // Use all selected agents
        });

        if (implAgents.length > 0) {
          const results = await this.dispatcher.dispatchSmart(implAgents, {
            issueId: this.state.issueId,
            taskType: "implement",
            context: {
              title: this.state.issue.title,
              description: this.state.issue.description,
              labels: this.state.issue.labels,
            },
            instructions: [
              `Implement: ${this.state.issue.title}`,
              "",
              designContext,
              "",
              `Requirements: ${this.state.analyzedRequirements?.requirements.join("; ") || "see description"}`,
              `Acceptance criteria: ${this.state.analyzedRequirements?.acceptanceCriteria.join("; ") || "see description"}`,
              "",
              "## Instructions",
              "Implement the feature following the design. Create tests alongside the implementation.",
              "Follow existing patterns found in the codebase.",
              "",
              "## Findings",
              "- Files created (prefix with 'Created:')",
              "- Files modified (prefix with 'Modified:')",
              "- Tests created (prefix with 'Test:')",
              "- Lines added/removed (prefix with 'Lines: +N -M')",
              "",
              "## Recommendations",
              "- Implementation notes and decisions made",
            ].join("\n"),
          });

          for (const result of results) {
            if (result.status === "failed") continue;
            for (const finding of result.findings || []) {
              const lower = finding.toLowerCase();
              if (lower.startsWith("created:")) {
                filesCreated.push(finding.replace(/^created:\s*/i, ""));
              } else if (lower.startsWith("modified:")) {
                filesModified.push(finding.replace(/^modified:\s*/i, ""));
              } else if (lower.startsWith("test:")) {
                testsCreated.push(finding.replace(/^test:\s*/i, ""));
              } else if (lower.startsWith("lines:")) {
                const lineMatch = finding.match(/\+(\d+)\s*-(\d+)/);
                if (lineMatch) {
                  linesAdded += parseInt(lineMatch[1], 10);
                  linesRemoved += parseInt(lineMatch[2], 10);
                }
              } else {
                // Try to extract file paths from general findings
                const pathMatch = finding.match(/[`']?([a-zA-Z0-9_/.-]+\.[a-zA-Z]+)[`']?/);
                if (pathMatch) {
                  filesModified.push(pathMatch[1]);
                }
              }
            }
            for (const rec of result.recommendations || []) {
              notes.push(`[${result.agentName}] ${rec}`);
            }
          }
        }
      }

      const artifact: ImplementationArtifact = {
        filesCreated,
        filesModified,
        linesAdded,
        linesRemoved,
        testsCreated,
        notes,
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
      let testsRun = 0;
      let testsPassed = 0;
      let testsFailed = 0;
      const testResults: Array<{ name: string; passed: boolean; duration: number; error?: string }> = [];
      let coverage: { lines: number; branches: number; functions: number } | undefined;

      if (this.dispatcher) {
        const testFiles = [
          ...this.state.implementation.testsCreated,
          ...this.state.analyzedRequirements?.existingCode.testFiles || [],
        ];

        const results = await this.dispatcher.dispatchParallel(["codebase-analyst"], {
          issueId: this.state.issueId,
          taskType: "analyze",
          context: {
            title: this.state.issue.title,
            description: this.state.issue.description,
            labels: this.state.issue.labels,
          },
          instructions: [
            `Run tests and validate implementation for: ${this.state.issue.title}`,
            "",
            this.state.implementation.filesCreated.length > 0
              ? `Files created: ${this.state.implementation.filesCreated.join(", ")}`
              : "",
            this.state.implementation.filesModified.length > 0
              ? `Files modified: ${this.state.implementation.filesModified.join(", ")}`
              : "",
            testFiles.length > 0
              ? `Test files: ${testFiles.join(", ")}`
              : "",
            "",
            "## Instructions",
            "Run the test suite. Report results for each test.",
            "",
            "## Findings",
            "- Test results (format: 'TestResult: name | pass/fail | duration_ms [| error]')",
            "- Coverage (format: 'Coverage: lines% branches% functions%')",
            "",
            "## Recommendations",
            "- Suggestions for additional tests or fixes",
          ].filter(Boolean).join("\n"),
        });

        for (const result of results) {
          if (result.status === "failed") continue;
          for (const finding of result.findings || []) {
            const lower = finding.toLowerCase();
            // Parse test results
            const testMatch = finding.match(/testresult:\s*(.+?)\s*\|\s*(pass|fail)\s*\|\s*(\d+)/i);
            if (testMatch) {
              const passed = testMatch[2].toLowerCase() === "pass";
              const duration = parseInt(testMatch[3], 10);
              const errorMatch = finding.match(/\|\s*(\d+)\s*\|\s*(.+)$/);
              testResults.push({
                name: testMatch[1].trim(),
                passed,
                duration,
                error: !passed && errorMatch ? errorMatch[2].trim() : undefined,
              });
              testsRun++;
              if (passed) testsPassed++;
              else testsFailed++;
            }
            // Parse coverage
            const covMatch = finding.match(/coverage:\s*(\d+(?:\.\d+)?)%?\s*(\d+(?:\.\d+)?)%?\s*(\d+(?:\.\d+)?)%?/i);
            if (covMatch) {
              coverage = {
                lines: parseFloat(covMatch[1]),
                branches: parseFloat(covMatch[2]),
                functions: parseFloat(covMatch[3]),
              };
            }
          }
        }
      }

      const testResult: TestResult = {
        testsRun,
        testsPassed,
        testsFailed,
        testResults,
        coverage,
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
      const findings: ReviewFinding[] = [];
      const suggestedImprovements: string[] = [];

      // Use dispatcher to run code-reviewer-agent
      if (this.dispatcher) {
        const filesList = [
          ...this.state.implementation.filesCreated.map((f) => `Created: ${f}`),
          ...this.state.implementation.filesModified.map((f) => `Modified: ${f}`),
        ].join("\n");

        const results = await this.dispatcher.dispatchParallel(["code-reviewer-agent"], {
          issueId: this.state.issueId,
          taskType: "review",
          context: {
            title: this.state.issue.title,
            description: this.state.issue.description,
            labels: this.state.issue.labels,
          },
          instructions: [
            `Review code changes for: ${this.state.issue.title}`,
            "",
            filesList ? `## Changed Files\n${filesList}` : "",
            this.state.implementation.notes.length > 0
              ? `## Implementation Notes\n${this.state.implementation.notes.join("\n")}`
              : "",
            "",
            "## Instructions",
            "Review the code for correctness, style, and quality.",
            "",
            "## Findings",
            "- Issues found (format: 'severity|category|description[|location][|suggestion]')",
            "  severity: info, warning, error",
            "",
            "## Recommendations",
            "- Suggested improvements",
          ].filter(Boolean).join("\n"),
        });

        for (const result of results) {
          if (result.status === "failed") continue;
          for (const finding of result.findings || []) {
            // Try to parse structured finding format
            const parts = finding.split("|").map((p) => p.trim());
            if (parts.length >= 3) {
              const severity = (["info", "warning", "error"].includes(parts[0]) ? parts[0] : "info") as "info" | "warning" | "error";
              findings.push({
                severity,
                category: parts[1] || "code-quality",
                description: parts[2] || finding,
                location: parts[3],
                suggestion: parts[4],
              });
            } else {
              // Unstructured finding — classify by keywords
              const lower = finding.toLowerCase();
              const severity: "info" | "warning" | "error" =
                lower.includes("error") || lower.includes("bug") || lower.includes("critical") ? "error" :
                lower.includes("warning") || lower.includes("should") || lower.includes("consider") ? "warning" : "info";
              findings.push({
                severity,
                category: "code-quality",
                description: finding,
              });
            }
          }
          if (result.recommendations?.length) {
            suggestedImprovements.push(...result.recommendations);
          }
        }
      }

      const hasErrors = findings.some((f) => f.severity === "error");
      const review: CodeReviewResult = {
        findings,
        approved: !hasErrors,
        summary: findings.length > 0
          ? `Code review found ${findings.length} issue(s): ${findings.filter((f) => f.severity === "error").length} errors, ${findings.filter((f) => f.severity === "warning").length} warnings`
          : "Code review completed — no issues found",
        suggestedImprovements,
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
      const findings: ReviewFinding[] = [];
      const vulnerabilities: Array<{ type: string; severity: "low" | "medium" | "high" | "critical"; description: string; remediation: string }> = [];
      const recommendations: string[] = [];

      // Use dispatcher to run security-reviewer-agent
      if (this.dispatcher) {
        const filesList = [
          ...this.state.implementation.filesCreated.map((f) => `Created: ${f}`),
          ...this.state.implementation.filesModified.map((f) => `Modified: ${f}`),
        ].join("\n");

        const results = await this.dispatcher.dispatchParallel(["security-reviewer-agent"], {
          issueId: this.state.issueId,
          taskType: "review",
          context: {
            title: this.state.issue.title,
            description: this.state.issue.description,
            labels: this.state.issue.labels,
          },
          instructions: [
            `Security review for: ${this.state.issue.title}`,
            "",
            filesList ? `## Changed Files\n${filesList}` : "",
            "",
            "## Instructions",
            "Review for security vulnerabilities: injection, auth issues, data exposure, etc.",
            "",
            "## Findings",
            "- Vulnerabilities (format: 'severity|description[|location][|remediation]')",
            "  severity: low, medium, high, critical",
            "",
            "## Recommendations",
            "- Security best practices and hardening suggestions",
          ].filter(Boolean).join("\n"),
        });

        for (const result of results) {
          if (result.status === "failed") continue;
          for (const finding of result.findings || []) {
            const parts = finding.split("|").map((p) => p.trim());
            if (parts.length >= 2) {
              const severity = (["low", "medium", "high", "critical"].includes(parts[0]) ? parts[0] : "medium") as "low" | "medium" | "high" | "critical";
              const desc = parts[1] || finding;
              vulnerabilities.push({
                type: parts[2] || "general",
                severity,
                description: desc,
                remediation: parts[3] || "Review and remediate",
              });
              // Also add as a ReviewFinding
              const reviewSeverity: "info" | "warning" | "error" =
                severity === "critical" || severity === "high" ? "error" :
                severity === "medium" ? "warning" : "info";
              findings.push({
                severity: reviewSeverity,
                category: "security",
                description: desc,
                location: parts[2],
                suggestion: parts[3],
              });
            } else {
              // Unstructured finding
              const lower = finding.toLowerCase();
              const severity = (lower.includes("critical") ? "critical" :
                lower.includes("high") ? "high" :
                lower.includes("low") ? "low" : "medium") as "low" | "medium" | "high" | "critical";
              vulnerabilities.push({
                type: "general",
                severity,
                description: finding,
                remediation: "Review and remediate",
              });
              const reviewSeverity: "info" | "warning" | "error" =
                severity === "critical" || severity === "high" ? "error" :
                severity === "medium" ? "warning" : "info";
              findings.push({
                severity: reviewSeverity,
                category: "security",
                description: finding,
              });
            }
          }
          if (result.recommendations?.length) {
            recommendations.push(...result.recommendations);
          }
        }
      }

      const hasCritical = vulnerabilities.some((v) => v.severity === "critical" || v.severity === "high");
      const secReview: SecurityReviewResult = {
        findings,
        approved: !hasCritical,
        summary: vulnerabilities.length > 0
          ? `Security review found ${vulnerabilities.length} vulnerability(ies): ${vulnerabilities.filter((v) => v.severity === "critical" || v.severity === "high").length} high/critical`
          : "Security review passed — no vulnerabilities found",
        vulnerabilities,
      };

      return {
        stage: "securityReview",
        status: "completed",
        data: secReview,
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
