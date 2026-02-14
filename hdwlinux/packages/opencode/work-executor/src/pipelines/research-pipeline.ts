/**
 * Research Pipeline
 *
 * Investigates a topic and produces a recommendation with follow-up tasks.
 *
 * Stages:
 * 1. parseQuestion - Extract research question from issue
 * 2. gatherContext - Collect relevant context from codebase and docs
 * 3. analyzeOptions - Identify and analyze possible approaches
 * 4. synthesizeRecommendation - Produce final recommendation
 * 5. createFollowUps - Create follow-up implementation tasks
 */

import type { IssueStorage, IssueRecord } from "opencode-planner-core";
import type { SubagentDispatcher, SubagentResult } from "../../../core/src/orchestration/subagent-dispatcher.js";
import type { ResearchResult, DiscoveredWorkItem } from "../types.js";

export interface ResearchStageResult<T> {
  stage: string;
  status: "completed" | "failed";
  data?: T;
  error?: string;
}

export interface ParsedQuestion {
  question: string;
  scope: string[];
  constraints: string[];
  desiredOutcome: string;
}

export interface GatheredContext {
  codebaseFindings: string[];
  documentationFindings: string[];
  existingPatterns: string[];
  relatedIssues: IssueRecord[];
}

export interface AnalyzedOption {
  name: string;
  description: string;
  pros: string[];
  cons: string[];
  effort: "low" | "medium" | "high";
  risk: "low" | "medium" | "high";
}

export interface SynthesizedRecommendation {
  recommendation: string;
  reasoning: string;
  confidence: "low" | "medium" | "high";
  alternativeConsiderations: string[];
}

export interface ResearchPipelineState {
  issueId: string;
  issue: IssueRecord;
  parsedQuestion?: ParsedQuestion;
  gatheredContext?: GatheredContext;
  analyzedOptions?: AnalyzedOption[];
  synthesizedRecommendation?: SynthesizedRecommendation;
  followUpTasks?: DiscoveredWorkItem[];
  agentResults?: SubagentResult[];
  stages: ResearchStageResult<unknown>[];
}

export class ResearchPipeline {
  private storage: IssueStorage;
  private dispatcher?: SubagentDispatcher;
  private state: ResearchPipelineState | null = null;

  constructor(storage: IssueStorage, options?: { dispatcher?: SubagentDispatcher }) {
    this.storage = storage;
    this.dispatcher = options?.dispatcher;
  }

  /**
   * Execute the full research pipeline
   */
  async execute(issueId: string): Promise<ResearchResult> {
    const issue = await this.storage.getIssue(issueId);
    if (!issue) {
      throw new Error(`Issue ${issueId} not found`);
    }

    this.state = {
      issueId,
      issue,
      stages: [],
    };

    // Stage 1: Parse the research question
    const parseResult = await this.parseQuestion();
    this.state.stages.push(parseResult);
    if (parseResult.status === "failed") {
      return this.buildFailedResult(parseResult.error || "Failed to parse question");
    }
    this.state.parsedQuestion = parseResult.data;

    // Stage 2: Gather context
    const contextResult = await this.gatherContext();
    this.state.stages.push(contextResult);
    if (contextResult.status === "failed") {
      return this.buildFailedResult(contextResult.error || "Failed to gather context");
    }
    this.state.gatheredContext = contextResult.data;

    // Stage 3: Analyze options
    const optionsResult = await this.analyzeOptions();
    this.state.stages.push(optionsResult);
    if (optionsResult.status === "failed") {
      return this.buildFailedResult(optionsResult.error || "Failed to analyze options");
    }
    this.state.analyzedOptions = optionsResult.data;

    // Stage 4: Synthesize recommendation
    const recommendationResult = await this.synthesizeRecommendation();
    this.state.stages.push(recommendationResult);
    if (recommendationResult.status === "failed") {
      return this.buildFailedResult(recommendationResult.error || "Failed to synthesize recommendation");
    }
    this.state.synthesizedRecommendation = recommendationResult.data;

    // Stage 5: Create follow-up tasks
    const followUpsResult = await this.createFollowUps();
    this.state.stages.push(followUpsResult);
    if (followUpsResult.status === "failed") {
      return this.buildFailedResult(followUpsResult.error || "Failed to create follow-ups");
    }
    this.state.followUpTasks = followUpsResult.data;

    // Update the issue with findings
    await this.updateIssueWithFindings();

    return this.buildSuccessResult();
  }

  /**
   * Stage 1: Parse the research question from the issue
   */
  private async parseQuestion(): Promise<ResearchStageResult<ParsedQuestion>> {
    if (!this.state) {
      return { stage: "parseQuestion", status: "failed", error: "Pipeline not initialized" };
    }

    try {
      const description = this.state.issue.description || "";
      const title = this.state.issue.title;

      // Extract question - look for explicit question markers or use title
      const questionMatch = description.match(/(?:question|investigate|research):\s*(.+?)(?:\n|$)/i);
      const question = questionMatch ? questionMatch[1].trim() : title;

      // Extract scope from labels or description
      const scopeMatch = description.match(/(?:scope|areas?):\s*(.+?)(?:\n|$)/i);
      const scope = scopeMatch
        ? scopeMatch[1].split(",").map((s) => s.trim())
        : this.state.issue.labels?.filter((l) => !["research", "todo", "in_progress"].includes(l)) || [];

      // Extract constraints
      const constraintsMatch = description.match(/(?:constraints?|limitations?):\s*(.+?)(?:\n\n|$)/is);
      const constraints = constraintsMatch
        ? constraintsMatch[1].split("\n").map((c) => c.replace(/^[-*]\s*/, "").trim()).filter(Boolean)
        : [];

      // Extract desired outcome
      const outcomeMatch = description.match(/(?:outcome|goal|objective):\s*(.+?)(?:\n|$)/i);
      const desiredOutcome = outcomeMatch ? outcomeMatch[1].trim() : "Provide a recommendation";

      return {
        stage: "parseQuestion",
        status: "completed",
        data: {
          question,
          scope,
          constraints,
          desiredOutcome,
        },
      };
    } catch (error: any) {
      return {
        stage: "parseQuestion",
        status: "failed",
        error: error?.message || String(error),
      };
    }
  }

  /**
   * Stage 2: Gather context from codebase and documentation
   */
  private async gatherContext(): Promise<ResearchStageResult<GatheredContext>> {
    if (!this.state || !this.state.parsedQuestion) {
      return { stage: "gatherContext", status: "failed", error: "Missing parsed question" };
    }

    try {
      let codebaseFindings: string[] = [];
      let documentationFindings: string[] = [];
      let existingPatterns: string[] = [];

      // Use dispatcher to gather context from multiple agents in parallel
      if (this.dispatcher) {
        const agents = this.dispatcher.selectAgents(this.state.issue);
        if (agents.length > 0) {
          const results = await this.dispatcher.dispatchParallel(agents, {
            issueId: this.state.issueId,
            taskType: "research",
            context: {
              title: this.state.parsedQuestion.question,
              description: this.state.issue.description,
              labels: this.state.issue.labels,
              parent: this.state.issue.parent,
            },
            instructions: [
              `Gather context for research question: ${this.state.parsedQuestion.question}`,
              "",
              "Scope: " + (this.state.parsedQuestion.scope.join(", ") || "general"),
              "Constraints: " + (this.state.parsedQuestion.constraints.join("; ") || "none"),
              "",
              "Please provide:",
              "## Findings",
              "- Relevant code patterns, files, and existing implementations",
              "- Documentation references and prior art",
              "",
              "## Recommendations",
              "- Existing patterns that could be reused or extended",
              "- Relevant documentation or design docs found",
            ].join("\n"),
          });
          this.state.agentResults = results;

          for (const result of results) {
            if (result.status === "failed") continue;
            // Classify findings: documentation-related vs codebase
            for (const finding of result.findings || []) {
              const lower = finding.toLowerCase();
              if (lower.includes("doc") || lower.includes("readme") || lower.includes("spec") || lower.includes("design")) {
                documentationFindings.push(finding);
              } else if (lower.includes("pattern") || lower.includes("convention") || lower.includes("existing")) {
                existingPatterns.push(finding);
              } else {
                codebaseFindings.push(finding);
              }
            }
            // Recommendations about patterns go to existingPatterns
            for (const rec of result.recommendations || []) {
              const lower = rec.toLowerCase();
              if (lower.includes("pattern") || lower.includes("reuse") || lower.includes("existing") || lower.includes("convention")) {
                existingPatterns.push(rec);
              } else if (lower.includes("doc") || lower.includes("reference")) {
                documentationFindings.push(rec);
              }
            }
          }
        }
      }

      const relatedIssues = await this.storage.search(this.state.parsedQuestion.question);

      return {
        stage: "gatherContext",
        status: "completed",
        data: {
          codebaseFindings,
          documentationFindings,
          existingPatterns,
          relatedIssues: relatedIssues.filter((i) => i.id !== this.state!.issueId),
        },
      };
    } catch (error: any) {
      return {
        stage: "gatherContext",
        status: "failed",
        error: error?.message || String(error),
      };
    }
  }

  /**
   * Stage 3: Analyze possible options/approaches
   */
  private async analyzeOptions(): Promise<ResearchStageResult<AnalyzedOption[]>> {
    if (!this.state || !this.state.parsedQuestion || !this.state.gatheredContext) {
      return { stage: "analyzeOptions", status: "failed", error: "Missing required context" };
    }

    try {
      const options: AnalyzedOption[] = [];

      // Build rich context from gathered data
      const contextSummary = [
        this.state.gatheredContext.codebaseFindings.length > 0
          ? "Codebase findings:\n" + this.state.gatheredContext.codebaseFindings.map((f) => `- ${f}`).join("\n")
          : "",
        this.state.gatheredContext.existingPatterns.length > 0
          ? "Existing patterns:\n" + this.state.gatheredContext.existingPatterns.map((p) => `- ${p}`).join("\n")
          : "",
        this.state.gatheredContext.relatedIssues.length > 0
          ? "Related issues:\n" + this.state.gatheredContext.relatedIssues.map((i) => `- ${i.title}`).join("\n")
          : "",
      ].filter(Boolean).join("\n\n");

      // Use dispatcher to dispatch domain experts for option analysis
      if (this.dispatcher) {
        const agents = this.dispatcher.selectAgents(this.state.issue);
        if (agents.length > 0) {
          const results = await this.dispatcher.dispatchSmart(agents, {
            issueId: this.state.issueId,
            taskType: "analyze",
            context: {
              title: this.state.parsedQuestion.question,
              description: this.state.issue.description,
              labels: this.state.issue.labels,
            },
            instructions: [
              `Analyze options for: ${this.state.parsedQuestion.question}`,
              "",
              contextSummary ? `## Context\n${contextSummary}` : "",
              "",
              "## Instructions",
              "For each viable option/approach, provide:",
              "## Findings",
              "- Pros and cons of each approach (prefix with 'Pro:' or 'Con:')",
              "- Risk factors (prefix with 'Risk:')",
              "",
              "## Recommendations",
              "- Each recommended option as a separate bullet",
              "- Include effort estimate (prefix with 'Effort:' low/medium/high)",
            ].filter(Boolean).join("\n"),
          });

          for (const result of results) {
            if (result.status === "failed") continue;

            // Build options from recommendations
            if (result.recommendations && result.recommendations.length > 0) {
              for (const rec of result.recommendations) {
                const pros: string[] = [];
                const cons: string[] = [];
                let effort: "low" | "medium" | "high" = "medium";
                let risk: "low" | "medium" | "high" = "medium";

                // Parse structured info from findings for this agent
                for (const finding of result.findings || []) {
                  const lower = finding.toLowerCase();
                  if (lower.startsWith("pro:") || lower.includes("advantage") || lower.includes("benefit")) {
                    pros.push(finding.replace(/^pro:\s*/i, ""));
                  } else if (lower.startsWith("con:") || lower.includes("disadvantage") || lower.includes("drawback")) {
                    cons.push(finding.replace(/^con:\s*/i, ""));
                  } else if (lower.startsWith("risk:") || lower.includes("risk")) {
                    const riskLevel = lower.includes("high") ? "high" : lower.includes("low") ? "low" : "medium";
                    risk = riskLevel;
                  }
                }

                // Parse effort from recommendation text
                const effortMatch = rec.match(/effort:\s*(low|medium|high)/i);
                if (effortMatch) {
                  effort = effortMatch[1].toLowerCase() as "low" | "medium" | "high";
                }

                options.push({
                  name: `${result.agentName}: ${rec.substring(0, 60)}`,
                  description: rec,
                  pros,
                  cons,
                  effort,
                  risk,
                });
              }
            }
          }
        }
      }

      return {
        stage: "analyzeOptions",
        status: "completed",
        data: options,
      };
    } catch (error: any) {
      return {
        stage: "analyzeOptions",
        status: "failed",
        error: error?.message || String(error),
      };
    }
  }

  /**
   * Stage 4: Synthesize a recommendation from analyzed options
   */
  private async synthesizeRecommendation(): Promise<ResearchStageResult<SynthesizedRecommendation>> {
    if (!this.state || !this.state.analyzedOptions) {
      return { stage: "synthesizeRecommendation", status: "failed", error: "Missing analyzed options" };
    }

    try {
      const recommendation: SynthesizedRecommendation = {
        recommendation: "",
        reasoning: "",
        confidence: "medium",
        alternativeConsiderations: [],
      };

      // Build options summary for synthesis prompt
      const optionsSummary = this.state.analyzedOptions.map((opt, i) => {
        const parts = [`${i + 1}. ${opt.name}: ${opt.description}`];
        if (opt.pros.length > 0) parts.push(`   Pros: ${opt.pros.join("; ")}`);
        if (opt.cons.length > 0) parts.push(`   Cons: ${opt.cons.join("; ")}`);
        parts.push(`   Effort: ${opt.effort}, Risk: ${opt.risk}`);
        return parts.join("\n");
      }).join("\n");

      if (this.dispatcher && this.state.analyzedOptions.length > 0) {
        // Use a general-purpose agent to synthesize across all options
        const results = await this.dispatcher.dispatchParallel(["codebase-analyst"], {
          issueId: this.state.issueId,
          taskType: "analyze",
          context: {
            title: this.state.parsedQuestion!.question,
            description: this.state.issue.description,
            labels: this.state.issue.labels,
          },
          instructions: [
            `Synthesize a recommendation for: ${this.state.parsedQuestion!.question}`,
            "",
            `Desired outcome: ${this.state.parsedQuestion!.desiredOutcome}`,
            this.state.parsedQuestion!.constraints.length > 0
              ? `Constraints: ${this.state.parsedQuestion!.constraints.join("; ")}`
              : "",
            "",
            "## Options analyzed:",
            optionsSummary || "(no options identified)",
            "",
            "## Instructions",
            "## Recommendations",
            "- Provide a single clear recommendation as the first bullet",
            "- Explain the reasoning",
            "",
            "## Findings",
            "- Alternative considerations or caveats",
            "- Confidence assessment (prefix with 'Confidence:' low/medium/high)",
          ].filter(Boolean).join("\n"),
        });

        for (const result of results) {
          if (result.status === "failed") continue;
          if (result.recommendations?.length) {
            recommendation.recommendation = result.recommendations[0];
            if (result.recommendations.length > 1) {
              recommendation.reasoning = result.recommendations.slice(1).join(" ");
            }
          }
          for (const finding of result.findings || []) {
            const lower = finding.toLowerCase();
            if (lower.startsWith("confidence:") || lower.includes("confidence")) {
              if (lower.includes("high")) recommendation.confidence = "high";
              else if (lower.includes("low")) recommendation.confidence = "low";
            } else {
              recommendation.alternativeConsiderations.push(finding);
            }
          }
        }
      }

      // Fallback: if dispatcher didn't produce a recommendation, pick the best option
      if (!recommendation.recommendation && this.state.analyzedOptions.length > 0) {
        const bestOption = this.state.analyzedOptions[0];
        recommendation.recommendation = `Recommend: ${bestOption.name}`;
        recommendation.reasoning = bestOption.description;
        // Add other options as alternatives
        for (const opt of this.state.analyzedOptions.slice(1)) {
          recommendation.alternativeConsiderations.push(`${opt.name}: ${opt.description}`);
        }
      }

      return {
        stage: "synthesizeRecommendation",
        status: "completed",
        data: recommendation,
      };
    } catch (error: any) {
      return {
        stage: "synthesizeRecommendation",
        status: "failed",
        error: error?.message || String(error),
      };
    }
  }

  /**
   * Stage 5: Create follow-up implementation tasks
   */
  private async createFollowUps(): Promise<ResearchStageResult<DiscoveredWorkItem[]>> {
    if (!this.state || !this.state.synthesizedRecommendation) {
      return { stage: "createFollowUps", status: "failed", error: "Missing recommendation" };
    }

    try {
      const followUps: DiscoveredWorkItem[] = [];

      // If we have a recommendation, create an implementation task
      if (this.state.synthesizedRecommendation.recommendation) {
        const followUpIssue = await this.storage.createIssue({
          type: "task",
          title: `Implement: ${this.state.parsedQuestion?.question || "research findings"}`,
          description: `Follow-up from research ${this.state.issueId}\n\n${this.state.synthesizedRecommendation.recommendation}\n\nReasoning: ${this.state.synthesizedRecommendation.reasoning}`,
          labels: ["implementation", `discovered-from:${this.state.issueId}`],
          priority: this.state.issue.priority,
          parent: this.state.issue.parent,
        });

        // Create dependency link
        await this.storage.createDependency(followUpIssue.id, this.state.issueId, "discovered-from");

        followUps.push({
          id: followUpIssue.id,
          parentId: this.state.issueId,
          title: `Implement: ${this.state.parsedQuestion?.question || "research findings"}`,
          type: "task",
          description: this.state.synthesizedRecommendation.recommendation,
          priority: this.state.issue.priority as 0 | 1 | 2 | 3 | 4 || 2,
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
   * Update the issue with research findings
   */
  private async updateIssueWithFindings(): Promise<void> {
    if (!this.state) return;

    const summary = this.buildSummary();

    await this.storage.updateIssue(this.state.issueId, {
      status: "done",
      description: `${this.state.issue.description || ""}\n\n---\n## Research Findings\n\n${summary}`,
    });
  }

  /**
   * Build a summary of the research findings
   */
  private buildSummary(): string {
    if (!this.state) return "";

    const parts: string[] = [];

    if (this.state.parsedQuestion) {
      parts.push(`**Question:** ${this.state.parsedQuestion.question}`);
    }

    if (this.state.analyzedOptions && this.state.analyzedOptions.length > 0) {
      parts.push("\n**Options Analyzed:**");
      for (const opt of this.state.analyzedOptions) {
        parts.push(`- ${opt.name}: ${opt.description}`);
      }
    }

    if (this.state.synthesizedRecommendation) {
      parts.push(`\n**Recommendation:** ${this.state.synthesizedRecommendation.recommendation}`);
      parts.push(`\n**Reasoning:** ${this.state.synthesizedRecommendation.reasoning}`);
      parts.push(`\n**Confidence:** ${this.state.synthesizedRecommendation.confidence}`);
    }

    if (this.state.followUpTasks && this.state.followUpTasks.length > 0) {
      parts.push("\n**Follow-up Tasks:**");
      for (const task of this.state.followUpTasks) {
        parts.push(`- ${task.id}: ${task.title}`);
      }
    }

    return parts.join("\n");
  }

  /**
   * Build a successful result
   */
  private buildSuccessResult(): ResearchResult {
    if (!this.state) {
      throw new Error("Pipeline state not initialized");
    }

    return {
      issueId: this.state.issueId,
      question: this.state.parsedQuestion?.question || "",
      summary: this.buildSummary(),
      options: (this.state.analyzedOptions || []).map((opt) => ({
        name: opt.name,
        pros: opt.pros,
        cons: opt.cons,
      })),
      recommendation: this.state.synthesizedRecommendation?.recommendation || "",
      reasoning: this.state.synthesizedRecommendation?.reasoning || "",
      followUpTasks: this.state.followUpTasks?.map((t) => t.id),
    };
  }

  /**
   * Build a failed result
   */
  private buildFailedResult(error: string): ResearchResult {
    return {
      issueId: this.state?.issueId || "",
      question: this.state?.parsedQuestion?.question || "",
      summary: `Research failed: ${error}`,
      options: [],
      recommendation: "",
      reasoning: "",
    };
  }

  /**
   * Get the current pipeline state (for testing/debugging)
   */
  getState(): ResearchPipelineState | null {
    return this.state;
  }
}
