/**
 * InboxManager - Manages JSONL-based message inboxes for realtime team communication
 *
 * Provides a polling-based message transport using append-only JSONL files.
 * Each team has a shared inbox file where agents write messages and poll for updates.
 *
 * Design decisions:
 * - JSONL format for O(1) append operations
 * - Single file per team (not per agent) for simpler coordination
 * - Polling-based delivery (500-2000ms latency acceptable)
 * - Messages include read tracking for efficient polling
 */

import * as fs from "node:fs/promises";
import * as path from "node:path";
import * as crypto from "node:crypto";

import type { Clock } from "../../utils/clock/index.js";
import { systemClock } from "../../utils/clock/index.js";

/**
 * Message types for team communication.
 *
 * - chat: Regular discussion message between agents
 * - status: Agent status update (e.g., "working on X")
 * - done: Agent signals completion of their work
 * - system: System-generated message (e.g., "agent joined")
 */
export type MessageType = "chat" | "done" | "status" | "system";

/**
 * A message in the team inbox.
 *
 * Messages are immutable once written. The `read` field is tracked
 * per-reader in memory, not in the file itself.
 */
export interface InboxMessage {
	/** Unique message identifier (UUID) */
	id: string;
	/** Agent name that sent the message */
	from: string;
	/** Target agent name, or "broadcast" for all agents */
	to: string;
	/** Message content */
	text: string;
	/** Unix timestamp when the message was created */
	timestamp: number;
	/** Message type for routing and display */
	type: MessageType;
	/** Optional metadata for extensibility */
	metadata?: Record<string, unknown>;
}

/**
 * Configuration for InboxManager.
 */
export interface InboxManagerConfig {
	/** Base directory for inbox files */
	baseDir: string;
	/** Clock for timing operations (optional, uses system clock) */
	clock?: Clock;
}

/**
 * Result of reading messages from an inbox.
 */
export interface ReadResult {
	/** Messages retrieved */
	messages: InboxMessage[];
	/** Cursor position for next read (line number) */
	cursor: number;
}

/**
 * Manages JSONL-based message inboxes for team communication.
 *
 * Each team has a single shared inbox file at:
 * `{baseDir}/team_inbox/{teamId}.jsonl`
 *
 * Agents write messages by appending to the file and read by scanning
 * from their last known cursor position.
 *
 * @example
 * ```typescript
 * const manager = new InboxManager({ baseDir: "/tmp/project" })
 * await manager.initialize("team-123")
 * await manager.sendMessage("team-123", {
 *   from: "agent-a",
 *   to: "broadcast",
 *   text: "Hello team!",
 *   type: "chat"
 * })
 * const { messages, cursor } = await manager.readMessages("team-123", 0)
 * ```
 */
export class InboxManager {
	private config: InboxManagerConfig;
	private clock: Clock;

	constructor(config: InboxManagerConfig) {
		this.config = config;
		this.clock = config.clock ?? systemClock;
	}

	/**
	 * Get the path to a team's inbox file.
	 */
	getInboxPath(teamId: string): string {
		return path.join(this.config.baseDir, "team_inbox", `${teamId}.jsonl`);
	}

	/**
	 * Initialize the inbox for a team.
	 *
	 * Creates the inbox directory and an empty inbox file if they don't exist.
	 *
	 * @param teamId - The team identifier
	 */
	async initialize(teamId: string): Promise<void> {
		const inboxPath = this.getInboxPath(teamId);
		const inboxDir = path.dirname(inboxPath);

		await fs.mkdir(inboxDir, { recursive: true });

		// Create empty file if it doesn't exist
		try {
			await fs.access(inboxPath);
		} catch {
			await fs.writeFile(inboxPath, "", "utf8");
		}
	}

	/**
	 * Send a message to the team inbox.
	 *
	 * Appends the message as a single JSONL line. This is an O(1) operation.
	 *
	 * @param teamId - The team identifier
	 * @param message - Message data (id and timestamp will be auto-generated if not provided)
	 * @returns The complete message with generated fields
	 */
	async sendMessage(
		teamId: string,
		message: Omit<InboxMessage, "id" | "timestamp"> & {
			id?: string;
			timestamp?: number;
		},
	): Promise<InboxMessage> {
		const inboxPath = this.getInboxPath(teamId);

		const completeMessage: InboxMessage = {
			id: message.id ?? crypto.randomUUID(),
			from: message.from,
			to: message.to,
			text: message.text,
			timestamp: message.timestamp ?? this.clock.now(),
			type: message.type,
			...(message.metadata ? { metadata: message.metadata } : {}),
		};

		const line = `${JSON.stringify(completeMessage)}\n`;
		await fs.appendFile(inboxPath, line, "utf8");

		return completeMessage;
	}

	/**
	 * Read messages from the team inbox starting from a cursor position.
	 *
	 * The cursor is a line number (0-based). Returns all messages from that
	 * line onwards and the new cursor position for the next read.
	 *
	 * @param teamId - The team identifier
	 * @param cursor - Line number to start reading from (0 = beginning)
	 * @param filter - Optional filter for message recipient (agent name or "broadcast")
	 * @returns Messages and new cursor position
	 */
	async readMessages(
		teamId: string,
		cursor: number = 0,
		filter?: { to?: string },
	): Promise<ReadResult> {
		const inboxPath = this.getInboxPath(teamId);

		let content: string;
		try {
			content = await fs.readFile(inboxPath, "utf8");
		} catch {
			// File doesn't exist yet
			return { messages: [], cursor: 0 };
		}

		const lines = content.split("\n").filter((line) => line.trim().length > 0);
		const messages: InboxMessage[] = [];

		for (let i = cursor; i < lines.length; i++) {
			try {
				const message = JSON.parse(lines[i]) as InboxMessage;

				// Apply filter if provided
				if (filter?.to) {
					if (message.to !== filter.to && message.to !== "broadcast") {
						continue;
					}
				}

				messages.push(message);
			} catch {
				// Skip malformed lines
			}
		}

		return {
			messages,
			cursor: lines.length,
		};
	}

	/**
	 * Read all messages from the team inbox.
	 *
	 * Convenience method that reads from the beginning.
	 *
	 * @param teamId - The team identifier
	 * @returns All messages in the inbox
	 */
	async readAllMessages(teamId: string): Promise<InboxMessage[]> {
		const { messages } = await this.readMessages(teamId, 0);
		return messages;
	}

	/**
	 * Get messages for a specific agent (including broadcasts).
	 *
	 * @param teamId - The team identifier
	 * @param agentName - The agent to get messages for
	 * @param cursor - Line number to start reading from
	 * @returns Messages addressed to the agent or broadcast
	 */
	async getMessagesForAgent(
		teamId: string,
		agentName: string,
		cursor: number = 0,
	): Promise<ReadResult> {
		return this.readMessages(teamId, cursor, { to: agentName });
	}

	/**
	 * Check if all specified agents have sent a "done" message.
	 *
	 * @param teamId - The team identifier
	 * @param agentNames - List of agent names to check
	 * @returns true if all agents have signaled done
	 */
	async allAgentsDone(teamId: string, agentNames: string[]): Promise<boolean> {
		const messages = await this.readAllMessages(teamId);

		const doneAgents = new Set<string>();
		for (const message of messages) {
			if (message.type === "done") {
				doneAgents.add(message.from);
			}
		}

		return agentNames.every((agent) => doneAgents.has(agent));
	}

	/**
	 * Get the list of agents that have signaled done.
	 *
	 * @param teamId - The team identifier
	 * @returns Set of agent names that have sent "done" messages
	 */
	async getDoneAgents(teamId: string): Promise<Set<string>> {
		const messages = await this.readAllMessages(teamId);

		const doneAgents = new Set<string>();
		for (const message of messages) {
			if (message.type === "done") {
				doneAgents.add(message.from);
			}
		}

		return doneAgents;
	}

	/**
	 * Clean up the inbox file for a team.
	 *
	 * @param teamId - The team identifier
	 */
	async cleanup(teamId: string): Promise<void> {
		const inboxPath = this.getInboxPath(teamId);

		try {
			await fs.unlink(inboxPath);
		} catch {
			// File doesn't exist, that's fine
		}
	}

	/**
	 * Check if an inbox exists for a team.
	 *
	 * @param teamId - The team identifier
	 * @returns true if the inbox file exists
	 */
	async exists(teamId: string): Promise<boolean> {
		const inboxPath = this.getInboxPath(teamId);

		try {
			await fs.access(inboxPath);
			return true;
		} catch {
			return false;
		}
	}

	/**
	 * Get the message count in an inbox.
	 *
	 * @param teamId - The team identifier
	 * @returns Number of messages in the inbox
	 */
	async getMessageCount(teamId: string): Promise<number> {
		const messages = await this.readAllMessages(teamId);
		return messages.length;
	}
}
