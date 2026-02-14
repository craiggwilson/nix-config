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
export declare const AGENTS: Record<string, Agent>;
/**
 * Get agent by name
 */
export declare function getAgent(name: string): Agent | undefined;
/**
 * Get agents by category
 */
export declare function getAgentsByCategory(category: Agent["category"]): Agent[];
/**
 * Get agents by capability
 */
export declare function getAgentsByCapability(capability: string): Agent[];
/**
 * Get all agent names
 */
export declare function getAllAgentNames(): string[];
/**
 * Validate agent exists
 */
export declare function agentExists(name: string): boolean;
//# sourceMappingURL=agents.d.ts.map