/**
 * Agent Definitions and Registry
 *
 * Defines all specialized agents available to the planning and execution plugins.
 */

/**
 * Agent type definition
 */
export interface Agent {
  name: string;
  description: string;
  category: "language" | "architecture" | "security" | "review" | "analysis";
  capabilities: string[];
  requiredSkills: string[];
}

/**
 * Specialized agents available in the plugin suite
 */
export const AGENTS: Record<string, Agent> = {
  // Language Experts
  "go-expert": {
    name: "Go Expert",
    description: "Expert Go developer with deep knowledge of idiomatic Go and concurrency patterns",
    category: "language",
    capabilities: ["code-implementation", "code-review", "testing", "performance-optimization"],
    requiredSkills: ["code-analysis", "testing", "build"],
  },

  "java-expert": {
    name: "Java Expert",
    description: "Expert Java developer with deep knowledge of JVM ecosystem and enterprise patterns",
    category: "language",
    capabilities: ["code-implementation", "code-review", "testing", "performance-optimization"],
    requiredSkills: ["code-analysis", "testing", "build"],
  },

  "nix-expert": {
    name: "Nix Expert",
    description: "Expert Nix developer with deep knowledge of NixOS, Home Manager, and flakes",
    category: "language",
    capabilities: ["code-implementation", "code-review", "testing", "system-design"],
    requiredSkills: ["code-analysis", "testing", "build"],
  },

  "terraform-expert": {
    name: "Terraform Expert",
    description: "Expert Terraform engineer with deep knowledge of infrastructure as code",
    category: "language",
    capabilities: ["code-implementation", "code-review", "testing", "infrastructure-design"],
    requiredSkills: ["code-analysis", "testing", "build"],
  },

  "flink-expert": {
    name: "Flink Expert",
    description: "Expert Apache Flink architect with deep knowledge of stream processing",
    category: "language",
    capabilities: ["code-implementation", "code-review", "testing", "performance-optimization"],
    requiredSkills: ["code-analysis", "testing", "build"],
  },

  "kafka-expert": {
    name: "Kafka Expert",
    description: "Expert Apache Kafka architect with deep knowledge of event streaming",
    category: "language",
    capabilities: ["code-implementation", "code-review", "testing", "performance-optimization"],
    requiredSkills: ["code-analysis", "testing", "build"],
  },

  "mongodb-expert": {
    name: "MongoDB Expert",
    description: "Expert MongoDB architect with deep knowledge of database design and optimization",
    category: "language",
    capabilities: ["code-implementation", "code-review", "testing", "performance-optimization"],
    requiredSkills: ["code-analysis", "testing", "build"],
  },

  // Architecture Experts
  "distributed-systems-architect": {
    name: "Distributed Systems Architect",
    description: "Distributed systems architect designing scalable, resilient service ecosystems",
    category: "architecture",
    capabilities: ["system-design", "architecture-review", "performance-analysis", "risk-assessment"],
    requiredSkills: ["code-analysis", "architecture-analysis"],
  },

  "aws-expert": {
    name: "AWS Expert",
    description: "Expert AWS architect with deep knowledge of AWS services and cloud-native patterns",
    category: "architecture",
    capabilities: ["system-design", "architecture-review", "cost-optimization", "compliance"],
    requiredSkills: ["code-analysis", "architecture-analysis"],
  },

  // Security Experts
  "security-architect": {
    name: "Security Architect",
    description: "Security architect specializing in secure system design and threat modeling",
    category: "security",
    capabilities: ["threat-modeling", "secure-design", "security-review", "compliance"],
    requiredSkills: ["security-analysis", "code-analysis"],
  },

  // Review Agents
  "code-reviewer-agent": {
    name: "Code Reviewer",
    description: "Code reviewer specializing in code quality, correctness, and style",
    category: "review",
    capabilities: ["code-review", "style-check", "testing-review", "refactoring-suggestions"],
    requiredSkills: ["code-analysis", "testing"],
  },

  "security-reviewer-agent": {
    name: "Security Reviewer",
    description: "Security reviewer specializing in security vulnerability detection",
    category: "review",
    capabilities: ["security-review", "vulnerability-detection", "dependency-analysis"],
    requiredSkills: ["security-analysis", "code-analysis"],
  },

  // Analysis Agents
  "codebase-analyst": {
    name: "Codebase Analyst",
    description: "Codebase analyst specializing in code archaeology and architecture discovery",
    category: "analysis",
    capabilities: ["code-analysis", "architecture-analysis", "dependency-analysis", "pattern-detection"],
    requiredSkills: ["code-analysis"],
  },

  "explore": {
    name: "Codebase Explorer",
    description: "Fast codebase exploration agent for quick understanding of code structure",
    category: "analysis",
    capabilities: ["code-analysis", "quick-exploration", "pattern-detection"],
    requiredSkills: ["code-analysis"],
  },
};

/**
 * Get agent by name
 */
export function getAgent(name: string): Agent | undefined {
  return AGENTS[name];
}

/**
 * Get agents by category
 */
export function getAgentsByCategory(category: Agent["category"]): Agent[] {
  return Object.values(AGENTS).filter((agent) => agent.category === category);
}

/**
 * Get agents by capability
 */
export function getAgentsByCapability(capability: string): Agent[] {
  return Object.values(AGENTS).filter((agent) => agent.capabilities.includes(capability));
}

/**
 * Get all agent names
 */
export function getAllAgentNames(): string[] {
  return Object.keys(AGENTS);
}

/**
 * Validate agent exists
 */
export function agentExists(name: string): boolean {
  return name in AGENTS;
}
