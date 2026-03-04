/**
 * Agent and team selection prompt templates
 *
 * Templates for small model prompts that select agents for tasks
 * and compose teams for collaborative work.
 */

import type { PromptTemplate } from "../prompt.js";

/**
 * Basic agent information for selection
 */
export interface AgentInfo {
	/** Agent name/identifier */
	name: string;
	/** Human-readable description of the agent's capabilities */
	description?: string;
}

/**
 * Data for team composition selection
 */
export interface TeamCompositionData {
	/** Context about the issue to work on */
	issueContext: string;
	/** Available agents to choose from */
	agents: AgentInfo[];
}

/**
 * Template for team composition selection.
 *
 * Used by the small model to select 3-4 agents to work on an issue
 * as a team, with the first agent being the primary implementer.
 */
export const teamCompositionTemplate: PromptTemplate<TeamCompositionData> = {
	name: "team-composition",
	description: "Small model prompt to select team composition",

	render: (data) => {
		const agentList = data.agents
			.map((a) => `- ${a.name}: ${a.description || "(no description)"}`)
			.join("\n");

		return `Select 3-4 agents to work on this issue as a team.

ISSUE:
${data.issueContext.slice(0, 5000)}

AVAILABLE AGENTS:
${agentList}

RULES:
1. First agent is PRIMARY - does the main implementation work
2. Other agents REVIEW the primary's work
3. Choose agents with complementary skills
4. Consider: implementation, testing, security, documentation needs
5. Default to 3 agents; use 4 for large or high-stakes work; use fewer only with a specific reason

Respond with JSON only:
{"agents": ["primary-agent", "reviewer-1", "reviewer-2"]}`;
	},
};

/**
 * Data for single agent selection
 */
export interface SingleAgentSelectionData {
	/** Description of the task to perform */
	taskDescription: string;
	/** Available agents to choose from */
	agents: AgentInfo[];
}

/**
 * Template for single agent selection.
 *
 * Used by the small model to select the best agent for a task.
 */
export const singleAgentSelectionTemplate: PromptTemplate<SingleAgentSelectionData> =
	{
		name: "single-agent-selection",
		description: "Small model prompt to select a single agent",

		render: (data) => {
			const agentList = data.agents
				.map((a) => `- ${a.name}: ${a.description || "(no description)"}`)
				.join("\n");

			return `Select the best agent for this task.

AVAILABLE AGENTS:
${agentList}

TASK DESCRIPTION:
${data.taskDescription.slice(0, 1000)}

Respond with ONLY valid JSON in this exact format:
{"agent": "agent-name", "reason": "brief reason for selection"}`;
		},
	};
