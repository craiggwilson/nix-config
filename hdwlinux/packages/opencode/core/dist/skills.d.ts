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
export declare const SKILLS: Record<string, Skill>;
/**
 * Get skill by name
 */
export declare function getSkill(name: string): Skill | undefined;
/**
 * Get skills by category
 */
export declare function getSkillsByCategory(category: Skill["category"]): Skill[];
/**
 * Get skills by operation
 */
export declare function getSkillsByOperation(operation: string): Skill[];
/**
 * Get all skill names
 */
export declare function getAllSkillNames(): string[];
/**
 * Validate skill exists
 */
export declare function skillExists(name: string): boolean;
/**
 * Get required skills for an agent
 */
export declare function getRequiredSkillsForAgent(agentName: string): Skill[];
//# sourceMappingURL=skills.d.ts.map