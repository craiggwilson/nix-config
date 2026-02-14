/**
 * Skill Definitions and Registry
 *
 * Defines all skills (capabilities/tools) available to agents.
 * Skills are the "how" - the tools and capabilities agents use.
 */

/**
 * Skill type definition
 */
export interface Skill {
  name: string;
  description: string;
  category: "beads" | "code" | "testing" | "build" | "documentation" | "analysis" | "security";
  operations: string[];
  requiredTools: string[];
}

/**
 * Skills available in the plugin suite
 */
export const SKILLS: Record<string, Skill> = {
  // Beads Skills
  "beads-query": {
    name: "Beads Query",
    description: "Query beads issues with filters (labels, status, priority, etc.)",
    category: "beads",
    operations: ["query", "search", "filter", "list"],
    requiredTools: ["beads-cli"],
  },

  "beads-crud": {
    name: "Beads CRUD",
    description: "Create, read, update, delete beads issues",
    category: "beads",
    operations: ["create", "read", "update", "delete"],
    requiredTools: ["beads-cli"],
  },

  "beads-dependencies": {
    name: "Beads Dependencies",
    description: "Manage dependencies between beads issues",
    category: "beads",
    operations: ["create-dependency", "remove-dependency", "analyze-graph"],
    requiredTools: ["beads-cli"],
  },

  // Code Skills
  "code-analysis": {
    name: "Code Analysis",
    description: "Analyze code structure, patterns, and quality",
    category: "code",
    operations: ["understand-code", "identify-patterns", "detect-issues"],
    requiredTools: ["codebase-access", "language-tools"],
  },

  "code-modification": {
    name: "Code Modification",
    description: "Modify code files with proper formatting and style",
    category: "code",
    operations: ["edit-files", "refactor", "format"],
    requiredTools: ["editor", "formatter", "linter"],
  },

  // Testing Skills
  "testing": {
    name: "Testing",
    description: "Run tests and analyze test coverage",
    category: "testing",
    operations: ["run-tests", "analyze-coverage", "create-tests"],
    requiredTools: ["test-runner", "coverage-tool"],
  },

  // Build Skills
  "build": {
    name: "Build",
    description: "Build and compile code",
    category: "build",
    operations: ["compile", "build", "package"],
    requiredTools: ["compiler", "build-tool"],
  },

  // Documentation Skills
  "documentation": {
    name: "Documentation",
    description: "Create and update documentation",
    category: "documentation",
    operations: ["create-doc", "update-doc", "generate-docs"],
    requiredTools: ["doc-tool", "markdown-processor"],
  },

  // Analysis Skills
  "architecture-analysis": {
    name: "Architecture Analysis",
    description: "Analyze system architecture and design",
    category: "analysis",
    operations: ["analyze-architecture", "identify-patterns", "assess-design"],
    requiredTools: ["codebase-access", "architecture-tools"],
  },

  "dependency-analysis": {
    name: "Dependency Analysis",
    description: "Analyze code dependencies and relationships",
    category: "analysis",
    operations: ["analyze-dependencies", "detect-cycles", "identify-risks"],
    requiredTools: ["dependency-tool", "graph-analyzer"],
  },

  // Security Skills
  "security-analysis": {
    name: "Security Analysis",
    description: "Analyze code for security vulnerabilities",
    category: "security",
    operations: ["detect-vulnerabilities", "analyze-permissions", "check-secrets"],
    requiredTools: ["security-scanner", "sast-tool"],
  },

  "threat-modeling": {
    name: "Threat Modeling",
    description: "Perform threat modeling and risk assessment",
    category: "security",
    operations: ["identify-threats", "assess-risks", "recommend-mitigations"],
    requiredTools: ["threat-model-tool"],
  },
};

/**
 * Get skill by name
 */
export function getSkill(name: string): Skill | undefined {
  return SKILLS[name];
}

/**
 * Get skills by category
 */
export function getSkillsByCategory(category: Skill["category"]): Skill[] {
  return Object.values(SKILLS).filter((skill) => skill.category === category);
}

/**
 * Get skills by operation
 */
export function getSkillsByOperation(operation: string): Skill[] {
  return Object.values(SKILLS).filter((skill) => skill.operations.includes(operation));
}

/**
 * Get all skill names
 */
export function getAllSkillNames(): string[] {
  return Object.keys(SKILLS);
}

/**
 * Validate skill exists
 */
export function skillExists(name: string): boolean {
  return name in SKILLS;
}

/**
 * Get required skills for an agent
 */
export function getRequiredSkillsForAgent(agentName: string): Skill[] {
  // This would be implemented with agent definitions
  // For now, return empty array
  return [];
}
