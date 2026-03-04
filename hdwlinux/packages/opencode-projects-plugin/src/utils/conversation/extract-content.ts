/**
 * Extract conversation content from compaction input.
 * The input structure may vary, so we handle multiple formats.
 */
export function extractConversationContent(input: unknown): string | null {
	if (typeof input !== "object" || input === null) {
		return null;
	}

	const inputObj = input as Record<string, unknown>;

	if (typeof inputObj.content === "string") {
		return inputObj.content;
	}

	if (typeof inputObj.conversation === "string") {
		return inputObj.conversation;
	}

	if (Array.isArray(inputObj.messages)) {
		return inputObj.messages
			.map(
				(msg: { role?: string; content?: string }) =>
					`${msg.role || "unknown"}: ${msg.content || ""}`,
			)
			.join("\n\n");
	}

	return null;
}
