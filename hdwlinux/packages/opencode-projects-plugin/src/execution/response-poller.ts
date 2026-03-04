import type { Logger, OpencodeClient, MessageItem, Part } from "../utils/opencode-sdk/index.js"
import type { Clock } from "../utils/clock/index.js"

/**
 * Polls a session until an assistant response is available.
 *
 * Waits up to `timeoutMs` milliseconds, checking every 2 seconds.
 * Throws if no response arrives within the timeout.
 */
export async function waitForResponse(
  client: OpencodeClient,
  sessionId: string,
  timeoutMs: number,
  clock: Clock,
  log: Logger,
): Promise<string> {
  const startTime = clock.now()
  const pollInterval = 2000

  while (clock.now() - startTime < timeoutMs) {
    await clock.sleep(pollInterval)

    try {
      const messages = await client.session.messages({
        path: { id: sessionId },
      })

      const messageData: MessageItem[] | undefined = messages.data
      if (!messageData || messageData.length === 0) {
        continue
      }

      const assistantMessages = messageData.filter(
        (m) => m.info?.role === "assistant"
      )
      if (assistantMessages.length === 0) {
        continue
      }

      const lastMessage = assistantMessages[assistantMessages.length - 1]

      const parts: Part[] = lastMessage.parts || []
      const textParts = parts.filter((p) => p.type === "text")
      const text = textParts.map((p) => p.text || "").join("\n")

      if (text && text.length > 0) {
        return text
      }
    } catch (error) {
      await log.debug(`Error polling session ${sessionId}: ${error}`)
    }
  }

  throw new Error(`Timeout waiting for response after ${timeoutMs / 1000}s`)
}
