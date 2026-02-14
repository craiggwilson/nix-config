/**
 * Subagent Dispatcher
 *
 * Orchestrates selection and dispatch of specialized subagents based on
 * issue labels and work type.
 */

import { AGENTS, getAgent, type Agent } from "../agents.js";
import type { IssueRecord } from "../beads.js";

/**
 * Task to be executed by a subagent
 */
export interface SubagentTask {
  issueId: string;
  taskType: "research" | "design" | "implement" | "review" | "analyze";
  context: {
    title: string;
    description?: string;
    labels?: string[];
    parent?: string;
  };
  instructions?: string;
}

/**
 * Result from a subagent execution
 */
export interface SubagentResult {
  agentName: string;
  status: "success" | "partial" | "failed";
  output?: unknown;
  findings?: string[];
  recommendations?: string[];
  error?: string;
  durationMs?: number;
}

/**
 * Label to agent mapping configuration
 */
interface LabelAgentMapping {
  label: string;
  agents: string[];
  priority: number;
}

/**
 * Default label-to-agent mappings
 */
const LABEL_AGENT_MAPPINGS: LabelAgentMapping[] = [
  // Language/Technology labels
  { label: "go", agents: ["go-expert"], priority: 1 },
  { label: "golang", agents: ["go-expert"], priority: 1 },
  { label: "java", agents: ["java-expert"], priority: 1 },
  { label: "jvm", agents: ["java-expert"], priority: 1 },
  { label: "nix", agents: ["nix-expert"], priority: 1 },
  { label: "nixos", agents: ["nix-expert"], priority: 1 },
  { label: "terraform", agents: ["terraform-expert"], priority: 1 },
  { label: "iac", agents: ["terraform-expert"], priority: 2 },
  { label: "infrastructure", agents: ["terraform-expert", "aws-expert"], priority: 2 },

  // Data/Streaming labels
  { label: "kafka", agents: ["kafka-expert"], priority: 1 },
  { label: "flink", agents: ["flink-expert"], priority: 1 },
  { label: "streaming", agents: ["kafka-expert", "flink-expert"], priority: 2 },
  { label: "mongodb", agents: ["mongodb-expert"], priority: 1 },
  { label: "mongo", agents: ["mongodb-expert"], priority: 1 },
  { label: "database", agents: ["mongodb-expert"], priority: 2 },

  // Architecture labels
  { label: "distributed-systems", agents: ["distributed-systems-architect"], priority: 1 },
  { label: "distributed", agents: ["distributed-systems-architect"], priority: 2 },
  { label: "scalability", agents: ["distributed-systems-architect"], priority: 2 },
  { label: "microservices", agents: ["distributed-systems-architect"], priority: 2 },
  { label: "aws", agents: ["aws-expert"], priority: 1 },
  { label: "cloud", agents: ["aws-expert"], priority: 2 },

  // Security labels
  { label: "security", agents: ["security-architect", "security-reviewer-agent"], priority: 1 },
  { label: "security-review", agents: ["security-reviewer-agent"], priority: 1 },
  { label: "threat-model", agents: ["security-architect"], priority: 1 },
  { label: "compliance", agents: ["security-architect"], priority: 2 },

  // Review labels
  { label: "review", agents: ["code-reviewer-agent"], priority: 1 },
  { label: "code-review", agents: ["code-reviewer-agent"], priority: 1 },

  // Analysis labels
  { label: "analysis", agents: ["codebase-analyst"], priority: 1 },
  { label: "exploration", agents: ["explore"], priority: 1 },
  { label: "archaeology", agents: ["codebase-analyst"], priority: 1 },
];

/**
 * Work type to default agent mappings
 */
const WORK_TYPE_AGENTS: Record<string, string[]> = {
  research: ["codebase-analyst", "explore"],
  poc: ["codebase-analyst"],
  implementation: ["code-reviewer-agent"],
  review: ["code-reviewer-agent", "security-reviewer-agent"],
  "security-review": ["security-reviewer-agent"],
};

/**
 * SubagentDispatcher orchestrates selection and dispatch of specialized subagents
 */
export class SubagentDispatcher {
  private labelMappings: LabelAgentMapping[];
  private executionHandler?: (agentName: string, task: SubagentTask) => Promise<SubagentResult>;

  constructor(options?: {
    customMappings?: LabelAgentMapping[];
    executionHandler?: (agentName: string, task: SubagentTask) => Promise<SubagentResult>;
  }) {
    this.labelMappings = options?.customMappings || LABEL_AGENT_MAPPINGS;
    this.executionHandler = options?.executionHandler;
  }

  /**
   * Select appropriate agents based on issue labels and type
   */
  selectAgents(issue: IssueRecord): string[] {
    const selectedAgents = new Set<string>();
    const labels = issue.labels || [];

    // Match labels to agents
    for (const label of labels) {
      const normalizedLabel = label.toLowerCase();

      for (const mapping of this.labelMappings) {
        if (normalizedLabel === mapping.label || normalizedLabel.includes(mapping.label)) {
          for (const agent of mapping.agents) {
            if (AGENTS[agent]) {
              selectedAgents.add(agent);
            }
          }
        }
      }
    }

    // Add default agents based on work type (inferred from labels)
    const workType = this.inferWorkType(labels);
    const defaultAgents = WORK_TYPE_AGENTS[workType] || [];
    for (const agent of defaultAgents) {
      if (AGENTS[agent]) {
        selectedAgents.add(agent);
      }
    }

    // Always include codebase-analyst for context if no specific agents selected
    if (selectedAgents.size === 0) {
      selectedAgents.add("codebase-analyst");
    }

    return Array.from(selectedAgents);
  }

  /**
   * Select agents by category
   */
  selectAgentsByCategory(category: Agent["category"]): string[] {
    return Object.entries(AGENTS)
      .filter(([_, agent]) => agent.category === category)
      .map(([name, _]) => name);
  }

  /**
   * Select agents by capability
   */
  selectAgentsByCapability(capability: string): string[] {
    return Object.entries(AGENTS)
      .filter(([_, agent]) => agent.capabilities.includes(capability))
      .map(([name, _]) => name);
  }

  /**
   * Dispatch agents in parallel
   */
  async dispatchParallel(agents: string[], task: SubagentTask): Promise<SubagentResult[]> {
    if (agents.length === 0) {
      return [];
    }

    const promises = agents.map((agentName) => this.executeAgent(agentName, task));
    return Promise.all(promises);
  }

  /**
   * Dispatch agents sequentially
   */
  async dispatchSequential(agents: string[], task: SubagentTask): Promise<SubagentResult[]> {
    const results: SubagentResult[] = [];

    for (const agentName of agents) {
      const result = await this.executeAgent(agentName, task);
      results.push(result);

      // Stop on failure if needed (could be configurable)
      if (result.status === "failed") {
        break;
      }
    }

    return results;
  }

  /**
   * Dispatch with automatic parallelization based on agent independence
   */
  async dispatchSmart(agents: string[], task: SubagentTask): Promise<SubagentResult[]> {
    // Group agents by category for parallel execution within groups
    const categoryGroups = new Map<string, string[]>();

    for (const agentName of agents) {
      const agent = getAgent(agentName);
      if (agent) {
        const category = agent.category;
        if (!categoryGroups.has(category)) {
          categoryGroups.set(category, []);
        }
        categoryGroups.get(category)!.push(agentName);
      }
    }

    // Execute each category group in parallel, but groups sequentially
    // This allows independent agents (same category) to run together
    const allResults: SubagentResult[] = [];

    // Analysis and language experts can run in parallel
    const parallelCategories = ["language", "analysis"];
    const sequentialCategories = ["review", "security"];

    // First, run parallel categories
    const parallelAgents: string[] = [];
    for (const category of parallelCategories) {
      const categoryAgents = categoryGroups.get(category) || [];
      parallelAgents.push(...categoryAgents);
    }

    if (parallelAgents.length > 0) {
      const parallelResults = await this.dispatchParallel(parallelAgents, task);
      allResults.push(...parallelResults);
    }

    // Then, run sequential categories (reviews should happen after implementation)
    for (const category of sequentialCategories) {
      const categoryAgents = categoryGroups.get(category) || [];
      if (categoryAgents.length > 0) {
        const sequentialResults = await this.dispatchSequential(categoryAgents, task);
        allResults.push(...sequentialResults);
      }
    }

    // Handle architecture category (can be parallel with language)
    const architectureAgents = categoryGroups.get("architecture") || [];
    if (architectureAgents.length > 0) {
      const archResults = await this.dispatchParallel(architectureAgents, task);
      allResults.push(...archResults);
    }

    return allResults;
  }

  /**
   * Execute a single agent
   */
  private async executeAgent(agentName: string, task: SubagentTask): Promise<SubagentResult> {
    const startTime = Date.now();
    const agent = getAgent(agentName);

    if (!agent) {
      return {
        agentName,
        status: "failed",
        error: `Agent not found: ${agentName}`,
        durationMs: Date.now() - startTime,
      };
    }

    try {
      // Use custom execution handler if provided
      if (this.executionHandler) {
        const result = await this.executionHandler(agentName, task);
        return {
          ...result,
          durationMs: Date.now() - startTime,
        };
      }

      // Default mock execution (actual execution would use OpenCode Task tool)
      return {
        agentName,
        status: "success",
        output: {
          agent: agent.name,
          category: agent.category,
          capabilities: agent.capabilities,
          taskType: task.taskType,
          issueId: task.issueId,
        },
        findings: [],
        recommendations: [],
        durationMs: Date.now() - startTime,
      };
    } catch (error: any) {
      return {
        agentName,
        status: "failed",
        error: error?.message || String(error),
        durationMs: Date.now() - startTime,
      };
    }
  }

  /**
   * Infer work type from labels
   */
  private inferWorkType(labels: string[]): string {
    if (labels.includes("research")) return "research";
    if (labels.includes("poc")) return "poc";
    if (labels.includes("security-review")) return "security-review";
    if (labels.includes("review") || labels.includes("code-review")) return "review";
    return "implementation";
  }

  /**
   * Get all available agent names
   */
  getAvailableAgents(): string[] {
    return Object.keys(AGENTS);
  }

  /**
   * Validate that all specified agents exist
   */
  validateAgents(agents: string[]): { valid: string[]; invalid: string[] } {
    const valid: string[] = [];
    const invalid: string[] = [];

    for (const agent of agents) {
      if (AGENTS[agent]) {
        valid.push(agent);
      } else {
        invalid.push(agent);
      }
    }

    return { valid, invalid };
  }
}
