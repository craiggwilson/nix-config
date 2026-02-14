/**
 * POC Pipeline
 *
 * Proves or disproves a hypothesis with minimal code.
 *
 * Stages:
 * 1. parseHypothesis - Extract hypothesis and success criteria from issue
 * 2. minimalDesign - Create minimal design to test hypothesis
 * 3. implement - Implement the POC with focus on speed
 * 4. validate - Validate the hypothesis against success criteria
 * 5. produceRecommendation - Generate keep/refine/discard recommendation
 * 6. fileDiscoveredWork - Create follow-up issues for discovered work
 */

import type { IssueStorage, IssueRecord } from "opencode-planner-core";
import type { SubagentDispatcher, SubagentResult } from "../../../core/src/orchestration/subagent-dispatcher.js";
import type { POCResult, DiscoveredWorkItem } from "../types.js";

export interface POCStageResult<T> {
  stage: string;
  status: "completed" | "failed";
  data?: T;
  error?: string;
}

export interface ParsedHypothesis {
  hypothesis: string;
  successCriteria: string[];
  scope: string[];
  timeboxHours?: number;
}

export interface MinimalDesign {
  approach: string;
  components: string[];
  dependencies: string[];
  estimatedEffort: "hours" | "day" | "days";
  risks: string[];
}

export interface ImplementationArtifact {
  filesCreated: string[];
  filesModified: string[];
  testsCreated: string[];
  notes: string[];
}

export interface ValidationResult {
  criteriaResults: Array<{
    criterion: string;
    passed: boolean;
    evidence: string;
  }>;
  overallPassed: boolean;
  observations: string[];
}

export interface POCRecommendation {
  outcome: "keep" | "refine" | "discard";
  reasoning: string;
  nextSteps: string[];
  lessonsLearned: string[];
}

export interface POCPipelineState {
  issueId: string;
  issue: IssueRecord;
  parsedHypothesis?: ParsedHypothesis;
  minimalDesign?: MinimalDesign;
  implementationArtifact?: ImplementationArtifact;
  validationResult?: ValidationResult;
  recommendation?: POCRecommendation;
  discoveredWork?: DiscoveredWorkItem[];
  agentResults?: SubagentResult[];
  stages: POCStageResult<unknown>[];
}

export class POCPipeline {
  private storage: IssueStorage;
  private dispatcher?: SubagentDispatcher;
  private state: POCPipelineState | null = null;

  constructor(storage: IssueStorage, options?: { dispatcher?: SubagentDispatcher }) {
    this.storage = storage;
    this.dispatcher = options?.dispatcher;
  }

  /**
   * Execute the full POC pipeline
   */
  async execute(issueId: string): Promise<POCResult> {
    const issue = await this.storage.getIssue(issueId);
    if (!issue) {
      throw new Error(`Issue ${issueId} not found`);
    }

    this.state = {
      issueId,
      issue,
      stages: [],
    };

    // Stage 1: Parse the hypothesis
    const parseResult = await this.parseHypothesis();
    this.state.stages.push(parseResult);
    if (parseResult.status === "failed") {
      return this.buildFailedResult(parseResult.error || "Failed to parse hypothesis");
    }
    this.state.parsedHypothesis = parseResult.data;

    // Stage 2: Create minimal design
    const designResult = await this.minimalDesign();
    this.state.stages.push(designResult);
    if (designResult.status === "failed") {
      return this.buildFailedResult(designResult.error || "Failed to create design");
    }
    this.state.minimalDesign = designResult.data;

    // Stage 3: Implement the POC
    const implementResult = await this.implement();
    this.state.stages.push(implementResult);
    if (implementResult.status === "failed") {
      return this.buildFailedResult(implementResult.error || "Failed to implement POC");
    }
    this.state.implementationArtifact = implementResult.data;

    // Stage 4: Validate the hypothesis
    const validateResult = await this.validate();
    this.state.stages.push(validateResult);
    if (validateResult.status === "failed") {
      return this.buildFailedResult(validateResult.error || "Failed to validate hypothesis");
    }
    this.state.validationResult = validateResult.data;

    // Stage 5: Produce recommendation
    const recommendResult = await this.produceRecommendation();
    this.state.stages.push(recommendResult);
    if (recommendResult.status === "failed") {
      return this.buildFailedResult(recommendResult.error || "Failed to produce recommendation");
    }
    this.state.recommendation = recommendResult.data;

    // Stage 6: File discovered work
    const discoveredResult = await this.fileDiscoveredWork();
    this.state.stages.push(discoveredResult);
    if (discoveredResult.status === "failed") {
      return this.buildFailedResult(discoveredResult.error || "Failed to file discovered work");
    }
    this.state.discoveredWork = discoveredResult.data;

    // Update the issue with findings
    await this.updateIssueWithFindings();

    return this.buildSuccessResult();
  }

  /**
   * Stage 1: Parse the hypothesis from the issue
   */
  private async parseHypothesis(): Promise<POCStageResult<ParsedHypothesis>> {
    if (!this.state) {
      return { stage: "parseHypothesis", status: "failed", error: "Pipeline not initialized" };
    }

    try {
      const description = this.state.issue.description || "";
      const title = this.state.issue.title;

      // Extract hypothesis
      const hypothesisMatch = description.match(/(?:hypothesis|theory|assumption):\s*(.+?)(?:\n|$)/i);
      const hypothesis = hypothesisMatch ? hypothesisMatch[1].trim() : title;

      // Extract success criteria
      const criteriaMatch = description.match(/(?:success criteria|criteria|acceptance):\s*(.+?)(?:\n\n|$)/is);
      const successCriteria = criteriaMatch
        ? criteriaMatch[1].split("\n").map((c) => c.replace(/^[-*]\s*/, "").trim()).filter(Boolean)
        : ["Hypothesis is validated"];

      // Extract scope from labels
      const scope = this.state.issue.labels?.filter((l) => !["poc", "todo", "in_progress"].includes(l)) || [];

      // Extract timebox
      const timeboxMatch = description.match(/(?:timebox|time limit|max time):\s*(\d+)\s*(?:hours?|h)/i);
      const timeboxHours = timeboxMatch ? parseInt(timeboxMatch[1], 10) : undefined;

      return {
        stage: "parseHypothesis",
        status: "completed",
        data: {
          hypothesis,
          successCriteria,
          scope,
          timeboxHours,
        },
      };
    } catch (error: any) {
      return {
        stage: "parseHypothesis",
        status: "failed",
        error: error?.message || String(error),
      };
    }
  }

  /**
   * Stage 2: Create minimal design to test hypothesis
   */
  private async minimalDesign(): Promise<POCStageResult<MinimalDesign>> {
    if (!this.state || !this.state.parsedHypothesis) {
      return { stage: "minimalDesign", status: "failed", error: "Missing parsed hypothesis" };
    }

    try {
      let approach = "";
      const risks: string[] = [];
      const components: string[] = [];
      const dependencies: string[] = [];
      let estimatedEffort: "hours" | "day" | "days" = "hours";

      // Use dispatcher to get domain expert input for design
      if (this.dispatcher) {
        const agents = this.dispatcher.selectAgents(this.state.issue);
        if (agents.length > 0) {
          const results = await this.dispatcher.dispatchSmart(agents, {
            issueId: this.state.issueId,
            taskType: "design",
            context: {
              title: this.state.parsedHypothesis.hypothesis,
              description: this.state.issue.description,
              labels: this.state.issue.labels,
            },
            instructions: [
              `Design minimal POC to test hypothesis: ${this.state.parsedHypothesis.hypothesis}`,
              "",
              `Success criteria: ${this.state.parsedHypothesis.successCriteria.join("; ")}`,
              this.state.parsedHypothesis.timeboxHours
                ? `Timebox: ${this.state.parsedHypothesis.timeboxHours} hours`
                : "",
              "",
              "## Instructions",
              "Design the simplest possible POC that can validate or invalidate the hypothesis.",
              "",
              "## Recommendations",
              "- First bullet: overall approach description",
              "- Components needed (prefix with 'Component:')",
              "- Dependencies required (prefix with 'Dependency:')",
              "- Effort estimate (prefix with 'Effort:' hours/day/days)",
              "",
              "## Findings",
              "- Risks and potential blockers (prefix with 'Risk:')",
              "- Existing code that can be leveraged",
            ].filter(Boolean).join("\n"),
          });
          this.state.agentResults = results;

          for (const result of results) {
            if (result.status === "failed") continue;
            if (result.recommendations?.length) {
              for (const rec of result.recommendations) {
                const lower = rec.toLowerCase();
                if (lower.startsWith("component:")) {
                  components.push(rec.replace(/^component:\s*/i, ""));
                } else if (lower.startsWith("dependency:")) {
                  dependencies.push(rec.replace(/^dependency:\s*/i, ""));
                } else if (lower.startsWith("effort:")) {
                  const effortStr = rec.replace(/^effort:\s*/i, "").toLowerCase();
                  if (effortStr.includes("days")) estimatedEffort = "days";
                  else if (effortStr.includes("day")) estimatedEffort = "day";
                } else if (!approach) {
                  approach = rec;
                }
              }
            }
            for (const finding of result.findings || []) {
              const lower = finding.toLowerCase();
              if (lower.startsWith("risk:") || lower.includes("risk") || lower.includes("blocker")) {
                risks.push(finding.replace(/^risk:\s*/i, ""));
              } else if (lower.includes("component") || lower.includes("module")) {
                components.push(finding);
              } else if (lower.includes("depend") || lower.includes("require")) {
                dependencies.push(finding);
              } else {
                risks.push(finding);
              }
            }
          }
        }
      }

      const design: MinimalDesign = {
        approach,
        components,
        dependencies,
        estimatedEffort,
        risks,
      };

      return {
        stage: "minimalDesign",
        status: "completed",
        data: design,
      };
    } catch (error: any) {
      return {
        stage: "minimalDesign",
        status: "failed",
        error: error?.message || String(error),
      };
    }
  }

  /**
   * Stage 3: Implement the POC
   */
  private async implement(): Promise<POCStageResult<ImplementationArtifact>> {
    if (!this.state || !this.state.minimalDesign) {
      return { stage: "implement", status: "failed", error: "Missing minimal design" };
    }

    try {
      const notes: string[] = [];
      const filesCreated: string[] = [];
      const filesModified: string[] = [];
      const testsCreated: string[] = [];

      // Use dispatcher to get language expert guidance for implementation
      if (this.dispatcher) {
        const agents = this.dispatcher.selectAgents(this.state.issue);
        if (agents.length > 0) {
          const results = await this.dispatcher.dispatchSmart(agents, {
            issueId: this.state.issueId,
            taskType: "implement",
            context: {
              title: this.state.parsedHypothesis!.hypothesis,
              description: this.state.issue.description,
              labels: this.state.issue.labels,
            },
            instructions: [
              `Implement minimal POC for: ${this.state.parsedHypothesis!.hypothesis}`,
              "",
              `Approach: ${this.state.minimalDesign.approach || "not specified"}`,
              this.state.minimalDesign.components.length > 0
                ? `Components: ${this.state.minimalDesign.components.join(", ")}`
                : "",
              this.state.minimalDesign.dependencies.length > 0
                ? `Dependencies: ${this.state.minimalDesign.dependencies.join(", ")}`
                : "",
              "",
              "## Instructions",
              "Implement the minimal POC. Focus on speed over polish.",
              "Create basic tests to validate the hypothesis.",
              "",
              "## Findings",
              "- Files created (prefix with 'Created:')",
              "- Files modified (prefix with 'Modified:')",
              "- Tests created (prefix with 'Test:')",
              "",
              "## Recommendations",
              "- Implementation notes and observations",
            ].filter(Boolean).join("\n"),
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
              } else if (lower.includes("file") || lower.includes("path")) {
                // Heuristic: extract file paths from findings
                const pathMatch = finding.match(/[`']?([a-zA-Z0-9_/.-]+\.[a-zA-Z]+)[`']?/);
                if (pathMatch) {
                  filesModified.push(pathMatch[1]);
                }
              }
            }
            if (result.recommendations?.length) {
              notes.push(...result.recommendations.map((r) => `[${result.agentName}] ${r}`));
            }
          }
        }
      }

      const artifact: ImplementationArtifact = {
        filesCreated,
        filesModified,
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
   * Stage 4: Validate the hypothesis against success criteria
   */
  private async validate(): Promise<POCStageResult<ValidationResult>> {
    if (!this.state || !this.state.parsedHypothesis || !this.state.implementationArtifact) {
      return { stage: "validate", status: "failed", error: "Missing required context" };
    }

    try {
      const observations: string[] = [];
      let criteriaResults = this.state.parsedHypothesis.successCriteria.map((criterion) => ({
        criterion,
        passed: false,
        evidence: "Validation pending",
      }));

      // Use dispatcher to validate the POC against success criteria
      if (this.dispatcher) {
        const agents = this.dispatcher.selectAgents(this.state.issue);
        if (agents.length > 0) {
          const criteriaList = this.state.parsedHypothesis.successCriteria
            .map((c, i) => `${i + 1}. ${c}`)
            .join("\n");

          const implNotes = this.state.implementationArtifact.notes.join("\n");
          const filesList = [
            ...this.state.implementationArtifact.filesCreated.map((f) => `Created: ${f}`),
            ...this.state.implementationArtifact.filesModified.map((f) => `Modified: ${f}`),
            ...this.state.implementationArtifact.testsCreated.map((f) => `Test: ${f}`),
          ].join("\n");

          const results = await this.dispatcher.dispatchParallel(agents, {
            issueId: this.state.issueId,
            taskType: "analyze",
            context: {
              title: this.state.parsedHypothesis.hypothesis,
              description: this.state.issue.description,
              labels: this.state.issue.labels,
            },
            instructions: [
              `Validate POC for hypothesis: ${this.state.parsedHypothesis.hypothesis}`,
              "",
              "## Success Criteria",
              criteriaList,
              "",
              filesList ? `## Files\n${filesList}` : "",
              implNotes ? `## Implementation Notes\n${implNotes}` : "",
              "",
              "## Instructions",
              "Run tests if available. Evaluate each success criterion.",
              "",
              "## Findings",
              "- For each criterion, report: 'Criterion N: PASS|FAIL - evidence'",
              "- General observations about the POC",
              "",
              "## Recommendations",
              "- Suggestions for improvement",
            ].filter(Boolean).join("\n"),
          });

          // Parse validation results from agent findings
          for (const result of results) {
            if (result.status === "failed") continue;
            for (const finding of result.findings || []) {
              const criterionMatch = finding.match(/criterion\s+(\d+):\s*(pass|fail)\s*[-–—]\s*(.*)/i);
              if (criterionMatch) {
                const idx = parseInt(criterionMatch[1], 10) - 1;
                if (idx >= 0 && idx < criteriaResults.length) {
                  criteriaResults[idx] = {
                    ...criteriaResults[idx],
                    passed: criterionMatch[2].toLowerCase() === "pass",
                    evidence: criterionMatch[3].trim(),
                  };
                }
              } else {
                observations.push(finding);
              }
            }
            for (const rec of result.recommendations || []) {
              observations.push(`[${result.agentName}] ${rec}`);
            }
          }
        }
      }

      const overallPassed = criteriaResults.every((r) => r.passed);

      return {
        stage: "validate",
        status: "completed",
        data: {
          criteriaResults,
          overallPassed,
          observations,
        },
      };
    } catch (error: any) {
      return {
        stage: "validate",
        status: "failed",
        error: error?.message || String(error),
      };
    }
  }

  /**
   * Stage 5: Produce keep/refine/discard recommendation
   */
  private async produceRecommendation(): Promise<POCStageResult<POCRecommendation>> {
    if (!this.state || !this.state.validationResult) {
      return { stage: "produceRecommendation", status: "failed", error: "Missing validation result" };
    }

    try {
      const { overallPassed, criteriaResults, observations } = this.state.validationResult;

      let outcome: "keep" | "refine" | "discard";
      let reasoning: string;
      const nextSteps: string[] = [];
      const lessonsLearned: string[] = [];

      if (overallPassed) {
        outcome = "keep";
        reasoning = "All success criteria were met. The hypothesis is validated.";
        nextSteps.push("Proceed with full implementation");
        nextSteps.push("Create implementation tasks based on POC learnings");
      } else {
        const passedCount = criteriaResults.filter((r) => r.passed).length;
        const totalCount = criteriaResults.length;

        if (passedCount > totalCount / 2) {
          outcome = "refine";
          reasoning = `${passedCount}/${totalCount} criteria passed. The approach shows promise but needs refinement.`;
          nextSteps.push("Address failing criteria");
          nextSteps.push("Consider alternative approaches for problematic areas");
        } else {
          outcome = "discard";
          reasoning = `Only ${passedCount}/${totalCount} criteria passed. The hypothesis is not validated.`;
          nextSteps.push("Research alternative approaches");
          nextSteps.push("Document lessons learned for future reference");
        }
      }

      // Add observations as lessons learned
      lessonsLearned.push(...observations);

      return {
        stage: "produceRecommendation",
        status: "completed",
        data: {
          outcome,
          reasoning,
          nextSteps,
          lessonsLearned,
        },
      };
    } catch (error: any) {
      return {
        stage: "produceRecommendation",
        status: "failed",
        error: error?.message || String(error),
      };
    }
  }

  /**
   * Stage 6: File discovered work issues
   */
  private async fileDiscoveredWork(): Promise<POCStageResult<DiscoveredWorkItem[]>> {
    if (!this.state || !this.state.recommendation) {
      return { stage: "fileDiscoveredWork", status: "failed", error: "Missing recommendation" };
    }

    try {
      const discoveredWork: DiscoveredWorkItem[] = [];
      const { outcome, nextSteps } = this.state.recommendation;

      // Create follow-up tasks based on recommendation
      for (const step of nextSteps) {
        const taskType = outcome === "keep" ? "task" : outcome === "refine" ? "task" : "task";
        const labels = [
          "implementation",
          `discovered-from:${this.state.issueId}`,
          `poc-outcome:${outcome}`,
        ];

        const followUpIssue = await this.storage.createIssue({
          type: taskType,
          title: step,
          description: `Follow-up from POC ${this.state.issueId}\n\nPOC Outcome: ${outcome}\n\n${this.state.recommendation.reasoning}`,
          labels,
          priority: this.state.issue.priority,
          parent: this.state.issue.parent,
        });

        // Create dependency link
        await this.storage.createDependency(followUpIssue.id, this.state.issueId, "discovered-from");

        discoveredWork.push({
          id: followUpIssue.id,
          parentId: this.state.issueId,
          title: step,
          type: taskType as "task" | "bug" | "chore" | "feature",
          description: `Follow-up from POC: ${this.state.recommendation.reasoning}`,
          priority: this.state.issue.priority as 0 | 1 | 2 | 3 | 4 || 2,
          createdAt: new Date().toISOString(),
        });
      }

      return {
        stage: "fileDiscoveredWork",
        status: "completed",
        data: discoveredWork,
      };
    } catch (error: any) {
      return {
        stage: "fileDiscoveredWork",
        status: "failed",
        error: error?.message || String(error),
      };
    }
  }

  /**
   * Update the issue with POC findings
   */
  private async updateIssueWithFindings(): Promise<void> {
    if (!this.state) return;

    const summary = this.buildSummary();

    await this.storage.updateIssue(this.state.issueId, {
      status: "done",
      description: `${this.state.issue.description || ""}\n\n---\n## POC Results\n\n${summary}`,
    });
  }

  /**
   * Build a summary of the POC findings
   */
  private buildSummary(): string {
    if (!this.state) return "";

    const parts: string[] = [];

    if (this.state.parsedHypothesis) {
      parts.push(`**Hypothesis:** ${this.state.parsedHypothesis.hypothesis}`);
    }

    if (this.state.recommendation) {
      parts.push(`\n**Outcome:** ${this.state.recommendation.outcome.toUpperCase()}`);
      parts.push(`\n**Reasoning:** ${this.state.recommendation.reasoning}`);
    }

    if (this.state.validationResult) {
      parts.push("\n**Validation Results:**");
      for (const result of this.state.validationResult.criteriaResults) {
        const status = result.passed ? "✓" : "✗";
        parts.push(`- ${status} ${result.criterion}`);
      }
    }

    if (this.state.recommendation?.nextSteps.length) {
      parts.push("\n**Next Steps:**");
      for (const step of this.state.recommendation.nextSteps) {
        parts.push(`- ${step}`);
      }
    }

    if (this.state.discoveredWork && this.state.discoveredWork.length > 0) {
      parts.push("\n**Follow-up Tasks:**");
      for (const task of this.state.discoveredWork) {
        parts.push(`- ${task.id}: ${task.title}`);
      }
    }

    return parts.join("\n");
  }

  /**
   * Build a successful result
   */
  private buildSuccessResult(): POCResult {
    if (!this.state) {
      throw new Error("Pipeline state not initialized");
    }

    return {
      issueId: this.state.issueId,
      hypothesis: this.state.parsedHypothesis?.hypothesis || "",
      outcome: this.state.recommendation?.outcome || "discard",
      findings: this.buildSummary(),
      recommendation: this.state.recommendation?.reasoning || "",
      discoveredWork: this.state.discoveredWork || [],
    };
  }

  /**
   * Build a failed result
   */
  private buildFailedResult(error: string): POCResult {
    return {
      issueId: this.state?.issueId || "",
      hypothesis: this.state?.parsedHypothesis?.hypothesis || "",
      outcome: "discard",
      findings: `POC failed: ${error}`,
      recommendation: "",
      discoveredWork: [],
    };
  }

  /**
   * Get the current pipeline state (for testing/debugging)
   */
  getState(): POCPipelineState | null {
    return this.state;
  }
}
