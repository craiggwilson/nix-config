/**
 * Tests for InboxManager
 */

import { describe, test, expect, beforeEach, afterEach } from "bun:test";
import * as fs from "node:fs/promises";
import * as path from "node:path";
import * as os from "node:os";

import { InboxManager, type InboxMessage } from "./inbox-manager.js";
import { MockClock } from "../../utils/clock/index.js";

describe("InboxManager", () => {
	let tempDir: string;
	let manager: InboxManager;
	let clock: MockClock;

	beforeEach(async () => {
		tempDir = await fs.mkdtemp(path.join(os.tmpdir(), "inbox-test-"));
		clock = new MockClock(1000000000000); // Fixed timestamp
		manager = new InboxManager({ baseDir: tempDir, clock });
	});

	afterEach(async () => {
		await fs.rm(tempDir, { recursive: true, force: true });
	});

	describe("initialize", () => {
		test("creates inbox directory and file", async () => {
			await manager.initialize("team-123");

			const inboxPath = manager.getInboxPath("team-123");
			const exists = await fs
				.access(inboxPath)
				.then(() => true)
				.catch(() => false);

			expect(exists).toBe(true);
		});

		test("is idempotent", async () => {
			await manager.initialize("team-123");
			await manager.initialize("team-123");

			const exists = await manager.exists("team-123");
			expect(exists).toBe(true);
		});
	});

	describe("sendMessage", () => {
		test("appends message to inbox file", async () => {
			await manager.initialize("team-123");

			const message = await manager.sendMessage("team-123", {
				from: "agent-a",
				to: "broadcast",
				text: "Hello team!",
				type: "chat",
			});

			expect(message.id).toBeDefined();
			expect(message.from).toBe("agent-a");
			expect(message.to).toBe("broadcast");
			expect(message.text).toBe("Hello team!");
			expect(message.type).toBe("chat");
			expect(message.timestamp).toBe(1000000000000);
		});

		test("appends multiple messages", async () => {
			await manager.initialize("team-123");

			await manager.sendMessage("team-123", {
				from: "agent-a",
				to: "broadcast",
				text: "Message 1",
				type: "chat",
			});

			await manager.sendMessage("team-123", {
				from: "agent-b",
				to: "broadcast",
				text: "Message 2",
				type: "chat",
			});

			const messages = await manager.readAllMessages("team-123");
			expect(messages.length).toBe(2);
			expect(messages[0].text).toBe("Message 1");
			expect(messages[1].text).toBe("Message 2");
		});

		test("preserves metadata", async () => {
			await manager.initialize("team-123");

			const message = await manager.sendMessage("team-123", {
				from: "agent-a",
				to: "broadcast",
				text: "With metadata",
				type: "chat",
				metadata: { phase: "initial-work", priority: "high" },
			});

			expect(message.metadata).toEqual({
				phase: "initial-work",
				priority: "high",
			});

			const messages = await manager.readAllMessages("team-123");
			expect(messages[0].metadata).toEqual({
				phase: "initial-work",
				priority: "high",
			});
		});
	});

	describe("readMessages", () => {
		test("reads all messages from beginning", async () => {
			await manager.initialize("team-123");

			await manager.sendMessage("team-123", {
				from: "agent-a",
				to: "broadcast",
				text: "Message 1",
				type: "chat",
			});

			await manager.sendMessage("team-123", {
				from: "agent-b",
				to: "broadcast",
				text: "Message 2",
				type: "chat",
			});

			const { messages, cursor } = await manager.readMessages("team-123", 0);

			expect(messages.length).toBe(2);
			expect(cursor).toBe(2);
		});

		test("reads messages from cursor position", async () => {
			await manager.initialize("team-123");

			await manager.sendMessage("team-123", {
				from: "agent-a",
				to: "broadcast",
				text: "Message 1",
				type: "chat",
			});

			await manager.sendMessage("team-123", {
				from: "agent-b",
				to: "broadcast",
				text: "Message 2",
				type: "chat",
			});

			// Read from cursor 1 (skip first message)
			const { messages, cursor } = await manager.readMessages("team-123", 1);

			expect(messages.length).toBe(1);
			expect(messages[0].text).toBe("Message 2");
			expect(cursor).toBe(2);
		});

		test("returns empty for non-existent inbox", async () => {
			const { messages, cursor } = await manager.readMessages(
				"non-existent",
				0,
			);

			expect(messages.length).toBe(0);
			expect(cursor).toBe(0);
		});

		test("filters by recipient", async () => {
			await manager.initialize("team-123");

			await manager.sendMessage("team-123", {
				from: "agent-a",
				to: "agent-b",
				text: "Direct to B",
				type: "chat",
			});

			await manager.sendMessage("team-123", {
				from: "agent-a",
				to: "broadcast",
				text: "To everyone",
				type: "chat",
			});

			await manager.sendMessage("team-123", {
				from: "agent-a",
				to: "agent-c",
				text: "Direct to C",
				type: "chat",
			});

			// Filter for agent-b (should get direct message and broadcast)
			const { messages } = await manager.readMessages("team-123", 0, {
				to: "agent-b",
			});

			expect(messages.length).toBe(2);
			expect(messages[0].text).toBe("Direct to B");
			expect(messages[1].text).toBe("To everyone");
		});
	});

	describe("getMessagesForAgent", () => {
		test("returns messages addressed to agent or broadcast", async () => {
			await manager.initialize("team-123");

			await manager.sendMessage("team-123", {
				from: "agent-a",
				to: "agent-b",
				text: "For B",
				type: "chat",
			});

			await manager.sendMessage("team-123", {
				from: "agent-a",
				to: "broadcast",
				text: "For all",
				type: "chat",
			});

			const { messages } = await manager.getMessagesForAgent(
				"team-123",
				"agent-b",
			);

			expect(messages.length).toBe(2);
		});
	});

	describe("allAgentsDone", () => {
		test("returns false when no agents have signaled done", async () => {
			await manager.initialize("team-123");

			await manager.sendMessage("team-123", {
				from: "agent-a",
				to: "broadcast",
				text: "Still working",
				type: "chat",
			});

			const allDone = await manager.allAgentsDone("team-123", [
				"agent-a",
				"agent-b",
			]);
			expect(allDone).toBe(false);
		});

		test("returns false when some agents have signaled done", async () => {
			await manager.initialize("team-123");

			await manager.sendMessage("team-123", {
				from: "agent-a",
				to: "broadcast",
				text: "I'm done",
				type: "done",
			});

			const allDone = await manager.allAgentsDone("team-123", [
				"agent-a",
				"agent-b",
			]);
			expect(allDone).toBe(false);
		});

		test("returns true when all agents have signaled done", async () => {
			await manager.initialize("team-123");

			await manager.sendMessage("team-123", {
				from: "agent-a",
				to: "broadcast",
				text: "I'm done",
				type: "done",
			});

			await manager.sendMessage("team-123", {
				from: "agent-b",
				to: "broadcast",
				text: "I'm done too",
				type: "done",
			});

			const allDone = await manager.allAgentsDone("team-123", [
				"agent-a",
				"agent-b",
			]);
			expect(allDone).toBe(true);
		});
	});

	describe("getDoneAgents", () => {
		test("returns set of agents that have signaled done", async () => {
			await manager.initialize("team-123");

			await manager.sendMessage("team-123", {
				from: "agent-a",
				to: "broadcast",
				text: "Done",
				type: "done",
			});

			await manager.sendMessage("team-123", {
				from: "agent-b",
				to: "broadcast",
				text: "Still working",
				type: "chat",
			});

			const doneAgents = await manager.getDoneAgents("team-123");

			expect(doneAgents.has("agent-a")).toBe(true);
			expect(doneAgents.has("agent-b")).toBe(false);
		});
	});

	describe("cleanup", () => {
		test("removes inbox file", async () => {
			await manager.initialize("team-123");
			await manager.sendMessage("team-123", {
				from: "agent-a",
				to: "broadcast",
				text: "Test",
				type: "chat",
			});

			await manager.cleanup("team-123");

			const exists = await manager.exists("team-123");
			expect(exists).toBe(false);
		});

		test("is idempotent", async () => {
			await manager.initialize("team-123");
			await manager.cleanup("team-123");
			await manager.cleanup("team-123"); // Should not throw

			const exists = await manager.exists("team-123");
			expect(exists).toBe(false);
		});
	});

	describe("getMessageCount", () => {
		test("returns correct count", async () => {
			await manager.initialize("team-123");

			expect(await manager.getMessageCount("team-123")).toBe(0);

			await manager.sendMessage("team-123", {
				from: "agent-a",
				to: "broadcast",
				text: "Message 1",
				type: "chat",
			});

			expect(await manager.getMessageCount("team-123")).toBe(1);

			await manager.sendMessage("team-123", {
				from: "agent-b",
				to: "broadcast",
				text: "Message 2",
				type: "chat",
			});

			expect(await manager.getMessageCount("team-123")).toBe(2);
		});
	});

	describe("getInboxPath", () => {
		test("returns correct path", () => {
			const inboxPath = manager.getInboxPath("team-123");
			expect(inboxPath).toBe(
				path.join(tempDir, "team_inbox", "team-123.jsonl"),
			);
		});
	});

	describe("JSONL format", () => {
		test("writes valid JSONL", async () => {
			await manager.initialize("team-123");

			await manager.sendMessage("team-123", {
				from: "agent-a",
				to: "broadcast",
				text: "Line 1",
				type: "chat",
			});

			await manager.sendMessage("team-123", {
				from: "agent-b",
				to: "broadcast",
				text: "Line 2",
				type: "chat",
			});

			const inboxPath = manager.getInboxPath("team-123");
			const content = await fs.readFile(inboxPath, "utf8");
			const lines = content.trim().split("\n");

			expect(lines.length).toBe(2);

			// Each line should be valid JSON
			const msg1 = JSON.parse(lines[0]) as InboxMessage;
			const msg2 = JSON.parse(lines[1]) as InboxMessage;

			expect(msg1.text).toBe("Line 1");
			expect(msg2.text).toBe("Line 2");
		});

		test("handles messages with newlines in text", async () => {
			await manager.initialize("team-123");

			await manager.sendMessage("team-123", {
				from: "agent-a",
				to: "broadcast",
				text: "Line 1\nLine 2\nLine 3",
				type: "chat",
			});

			const messages = await manager.readAllMessages("team-123");
			expect(messages.length).toBe(1);
			expect(messages[0].text).toBe("Line 1\nLine 2\nLine 3");
		});

		test("handles special characters in text", async () => {
			await manager.initialize("team-123");

			await manager.sendMessage("team-123", {
				from: "agent-a",
				to: "broadcast",
				text: 'Special chars: "quotes", \\backslash, \ttab',
				type: "chat",
			});

			const messages = await manager.readAllMessages("team-123");
			expect(messages.length).toBe(1);
			expect(messages[0].text).toBe(
				'Special chars: "quotes", \\backslash, \ttab',
			);
		});
	});
});
