import type { TypeSafeContainer } from "../../container/index.js";
import { Tokens } from "../../container/index.js";
import { HookRegistryToken } from "../../hooks/index.js";
import { ProjectManagerToken } from "../../projects/index.js";
import { DelegationManagerToken } from "../token.js";
import type { MessageItem } from "../../utils/opencode-sdk/index.js";
import type { Logger, OpencodeClient } from "../../utils/opencode-sdk/index.js";
import type { ProjectManager } from "../../projects/index.js";

/** Maximum number of recent messages to include in the snapshot. */
const SNAPSHOT_MESSAGE_LIMIT = 20;

/**
 * Registers delegation lifecycle hooks and orchestrator snapshot hook into the DI container.
 *
 * Separated from the module registration so hooks can be composed independently.
 */
export function registerDelegationHooks(container: TypeSafeContainer): void {
	container.onBuild((c) => {
		const hookRegistry = c.resolve(HookRegistryToken);
		const projectManager = c.resolve(ProjectManagerToken);
		const delegationManager = c.resolve(DelegationManagerToken);
		const typedClient = c.resolve(Tokens.Client);
		const log = c.resolve(Tokens.Logger);

		// Track the orchestrator session ID — the root session with no parentID.
		// Set on session.created; used to filter session.idle events.
		// Shared across both event hooks registered below.
		let orchestratorSessionId: string | null = null;

		hookRegistry.register({
			name: "event",
			priority: 10,
			handler: async ({ event }) => {
				if (event.type === "session.created") {
					const session = event.properties.info;
					if (!session.parentID && !orchestratorSessionId) {
						orchestratorSessionId = session.id;
						await log.debug(
							`Orchestrator session identified: ${orchestratorSessionId}`,
						);
					}
				}
			},
		});

		hookRegistry.register({
			name: "event",
			priority: 20,
			handler: async ({ event }) => {
				if (event.type === "session.idle") {
					const sessionId = event.properties.sessionID;

					if (sessionId) {
						const delegationId = delegationManager.findBySession(sessionId);
						if (delegationId) {
							await delegationManager.handleSessionIdle(sessionId);
						}
					}

					if (sessionId && sessionId === orchestratorSessionId) {
						const projectId = projectManager.getFocusedProjectId();
						if (projectId) {
							await writeOrchestratorSnapshot(
								typedClient,
								projectManager,
								projectId,
								sessionId,
								log,
							);
						}
					}
				}
			},
		});
	});
}

/**
 * Writes a lightweight incremental snapshot for the orchestrator session.
 *
 * Called on every `session.idle` event for the root orchestrator session.
 * Overwrites the snapshot file — always reflects current state. Does NOT
 * call the small model; this is intentionally cheap.
 */
async function writeOrchestratorSnapshot(
	client: OpencodeClient,
	projectManager: ProjectManager,
	projectId: string,
	sessionId: string,
	log: Logger,
): Promise<void> {
	try {
		const sessionManager = await projectManager.getSessionManager(projectId);
		if (!sessionManager) return;

		const status = await projectManager.getProjectStatus(projectId);
		const metadata = await projectManager.getProjectMetadata(projectId);

		const projectStateLines: string[] = [];
		projectStateLines.push(`**Project:** ${metadata?.name || projectId}`);
		projectStateLines.push(`**Status:** ${metadata?.status || "active"}`);
		if (status?.issueStatus) {
			const { completed, total } = status.issueStatus;
			projectStateLines.push(
				`**Progress:** ${completed}/${total} issues complete`,
			);
		}
		const projectState = projectStateLines.join("\n");

		const recentMessages = await fetchRecentMessages(
			client,
			sessionId,
			SNAPSHOT_MESSAGE_LIMIT,
		);

		await sessionManager.writeSnapshot({
			sessionId,
			timestamp: new Date().toISOString(),
			projectState,
			recentMessages,
		});

		await log.debug(`Wrote orchestrator snapshot for session ${sessionId}`);
	} catch (error) {
		await log.warn(`Failed to write orchestrator snapshot: ${error}`);
	}
}

/**
 * Fetches the last N messages from a session and formats them as text.
 *
 * Returns a formatted string of recent conversation turns, suitable for
 * inclusion in a snapshot file.
 */
async function fetchRecentMessages(
	client: OpencodeClient,
	sessionId: string,
	limit: number,
): Promise<string> {
	try {
		const result = await client.session.messages({ path: { id: sessionId } });
		const messages: MessageItem[] = result.data ?? [];

		const recent = messages.slice(-limit);
		if (recent.length === 0) {
			return "*No messages yet*";
		}

		return recent
			.map((msg) => {
				const role = msg.info?.role ?? "unknown";
				const text = msg.parts
					?.filter((p) => p.type === "text")
					.map((p) => p.text ?? "")
					.join("")
					.trim();
				return `**${role}:** ${text || "(no text content)"}`;
			})
			.join("\n\n");
	} catch {
		return "*Could not fetch messages*";
	}
}
