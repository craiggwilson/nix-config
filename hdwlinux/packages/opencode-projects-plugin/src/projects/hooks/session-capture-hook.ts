import type { Hook } from "../../hooks/index.js";
import type { ProjectManager } from "../project-manager.js";
import type { ConfigManager } from "../../config/index.js";
import type { Logger, OpencodeClient } from "../../utils/opencode-sdk/index.js";
import { summarizeSession } from "../../sessions/index.js";
import { extractConversationContent } from "../../utils/conversation/index.js";

/**
 * Summarises the session conversation and captures it in the project's session history.
 */
export function createSessionCaptureHook(
	projectManager: ProjectManager,
	typedClient: OpencodeClient,
	log: Logger,
	config: ConfigManager,
): Hook<"experimental.session.compacting"> {
	return {
		name: "experimental.session.compacting",
		priority: 40,
		handler: async (input, _output) => {
			const projectId = projectManager.getFocusedProjectId();
			if (!projectId) return;

			const sessionId = (input as { sessionID?: string }).sessionID;
			if (!sessionId) return;

			try {
				const sessionManager =
					await projectManager.getSessionManager(projectId);
				if (sessionManager) {
					const conversationContent = extractConversationContent(input);

					if (conversationContent) {
						const metadata = await projectManager.getProjectMetadata(projectId);
						const planningManager =
							await projectManager.getPlanningManager(projectId);
						const planningState = await planningManager?.getState();
						const planningPhase = planningState?.phase;

						const summaryResult = await summarizeSession(typedClient, log, {
							conversationContent,
							projectName: metadata?.name,
							planningPhase,
							timeoutMs: config.getSmallModelTimeoutMs(),
						});

						if (summaryResult.ok) {
							const captureResult = await sessionManager.captureSession({
								sessionId,
								summary: summaryResult.value.summary,
								keyPoints: summaryResult.value.keyPoints,
								openQuestionsAdded: summaryResult.value.openQuestionsAdded,
								decisionsMade: summaryResult.value.decisionsMade,
							});

							if (captureResult.ok) {
								if (summaryResult.value.whatsNext.length > 0) {
									await sessionManager.updateIndex({
										whatsNext: summaryResult.value.whatsNext,
									});
								}
								await log.debug(
									`Session ${sessionId} captured for project ${projectId}`,
								);
							} else if (captureResult.error.type === "already_exists") {
								if (summaryResult.value.whatsNext.length > 0) {
									await sessionManager.updateIndex({
										whatsNext: summaryResult.value.whatsNext,
									});
								}
								await log.debug(
									`Session ${sessionId} already captured, updated with compaction details`,
								);
							} else {
								await log.warn(
									`Failed to capture session ${sessionId}: ${captureResult.error.message}`,
								);
							}
						}
					}
				}
			} catch (error) {
				await log.warn(`Failed to capture session: ${error}`);
			}
		},
	};
}
