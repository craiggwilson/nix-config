/**
 * Compaction context builders
 *
 * Builds context blocks that survive session compaction.
 * These help the agent resume work after context is compacted.
 */

import { xmlWrap, lines } from "../../utils/prompts/index.js";
import type { ProjectManager } from "../project-manager.js";
import type { Delegation } from "../../delegation/index.js";
import type { Team } from "../../teams/index.js";

/**
 * Build context for session compaction.
 *
 * This context survives compaction and helps the agent resume work.
 * Includes project progress, ready issues, and quick reference.
 */
export async function buildCompactionContext(
	projectManager: ProjectManager,
): Promise<string | null> {
	const projectId = projectManager.getFocusedProjectId();
	if (!projectId) return null;

	const sections: string[] = [];

	sections.push(`## Active Project: ${projectId}`);

	try {
		const status = await projectManager.getProjectStatus(projectId);
		if (status?.issueStatus) {
			sections.push("");
			sections.push("## Project Progress");
			sections.push(
				`- **Completed:** ${status.issueStatus.completed}/${status.issueStatus.total}`,
			);
			sections.push(`- **In Progress:** ${status.issueStatus.inProgress}`);
			sections.push(`- **Blocked:** ${status.issueStatus.blocked}`);
		}
	} catch {
		// Project may not exist
	}

	try {
		const ready = await projectManager.getReadyIssues(projectId);
		if (ready.length > 0) {
			sections.push("");
			sections.push("## Ready Issues (unblocked)");
			for (const issue of ready.slice(0, 5)) {
				const priority =
					issue.priority !== undefined ? `P${issue.priority}` : "";
				sections.push(`- ${issue.id}: ${issue.title} ${priority}`.trim());
			}
			if (ready.length > 5) {
				sections.push(`- ... and ${ready.length - 5} more`);
			}
		}
	} catch {
		// Project may not exist
	}

	sections.push("");
	sections.push("## Quick Reference");
	sections.push("- `project-status` - Full project state");
	sections.push("- `project-focus` - Change focus");
	sections.push("- `project-work-on-issue` - Start work on an issue");
	sections.push("- `project-update-issue` - Update/close an issue");
	sections.push(
		"- `project-internal-delegation-read` - Read delegation results",
	);

	return xmlWrap("project-compaction-context", lines(...sections));
}

/**
 * Build context for delegations during compaction.
 *
 * Includes both running and recent completed delegations.
 */
export function buildDelegationCompactionContext(
	running: Delegation[],
	completed: Delegation[],
): string {
	const sections: string[] = [];

	if (running.length > 0) {
		sections.push("## Running Delegations");
		sections.push("");

		for (const d of running) {
			sections.push(`### ${d.id}`);
			sections.push(`- **Issue:** ${d.issueId}`);
			sections.push(`- **Agent:** ${d.agent || "(auto)"}`);
			sections.push(`- **Started:** ${d.startedAt}`);
			if (d.worktreePath) {
				sections.push(`- **Worktree:** ${d.worktreePath}`);
			}
			sections.push("");
		}

		sections.push(
			"> You will be notified via `<delegation-notification>` when delegations complete.",
		);
		sections.push("> Do NOT poll for status - continue productive work.");
		sections.push("");
	}

	if (completed.length > 0) {
		sections.push("## Recent Completed Delegations");
		sections.push("");

		for (const d of completed) {
			const statusIcon =
				d.status === "completed" ? "✅" : d.status === "failed" ? "❌" : "⏱️";
			sections.push(`### ${statusIcon} ${d.id}`);
			sections.push(`- **Title:** ${d.title || "(no title)"}`);
			sections.push(`- **Issue:** ${d.issueId}`);
			sections.push(`- **Status:** ${d.status}`);
			if (d.completedAt) {
				sections.push(`- **Completed:** ${d.completedAt}`);
			}
			sections.push("");
		}

		sections.push(
			"> Use `project-internal-delegation-read(id)` to retrieve full results.",
		);
		sections.push("");
	}

	return xmlWrap("delegation-context", lines(...sections));
}

/**
 * Build context for running teams during compaction.
 */
export function buildTeamCompactionContext(teams: Team[]): string {
	const sections: string[] = [];

	sections.push("## Running Teams");
	sections.push("");

	for (const team of teams) {
		sections.push(`### Team ${team.id}`);
		sections.push(`- **Issue:** ${team.issueId}`);
		sections.push(`- **Status:** ${team.status}`);
		sections.push(
			`- **Members:** ${team.members.map((m) => `${m.agent} (${m.role})`).join(", ")}`,
		);
		sections.push(`- **Started:** ${team.startedAt}`);

		if (team.status === "discussing") {
			sections.push(
				`- **Discussion Rounds Completed:** ${team.discussionHistory.length}`,
			);
		}

		if (team.worktreePath) {
			sections.push(`- **Worktree:** ${team.worktreePath}`);
		}
		sections.push("");
	}

	sections.push(
		"> You will be notified via `<team-notification>` when teams complete.",
	);
	sections.push("> Do NOT poll for status - continue productive work.");
	sections.push("");

	return xmlWrap("team-context", lines(...sections));
}
