/**
 * HookRegistry — composable hook registry and type definitions.
 *
 * Handlers run in ascending priority order (lower number = first). When two
 * handlers share the same priority, registration order is the tiebreaker.
 * If a handler throws, the error is logged and execution continues with the
 * next handler.
 */

import type { Event, Config, Model } from "@opencode-ai/sdk";
import type { Logger } from "../utils/opencode-sdk/index.js";

// ============================================================================
// HookSignatures — maps hook names to their input/output types
// ============================================================================

/**
 * Maps every supported hook name to its input and output types.
 *
 * Types are derived from the opencode SDK so that changes to the SDK propagate
 * here. Add new entries when the SDK gains new hooks. This is intentionally a
 * subset of all available SDK hooks — only hooks used by this plugin are listed.
 */
export interface HookSignatures {
	"experimental.chat.system.transform": {
		input: { sessionID?: string; model: Model };
		output: { system: string[] };
	};
	"experimental.session.compacting": {
		input: { sessionID: string };
		output: { context: string[]; prompt?: string };
	};
	"shell.env": {
		input: { cwd: string };
		output: { env: Record<string, string> };
	};
	event: {
		input: { event: Event };
		output: undefined;
	};
	config: {
		input: Config;
		output: undefined;
	};
}

// ============================================================================
// HookName and Hook
// ============================================================================

/**
 * Union of all supported hook names.
 */
export type HookName = keyof HookSignatures;

/**
 * A single hook handler unit.
 *
 * Handlers for the same hook name are composed sequentially by the
 * HookRegistry in ascending priority order (lower number = first).
 * The default priority is 100.
 */
export interface Hook<K extends HookName> {
	/** Hook name this handler is registered for. */
	name: K;
	/**
	 * Execution order relative to other handlers for the same hook name.
	 * Lower values run first. Defaults to 100 when omitted.
	 * Registration order is the tiebreaker for equal priorities.
	 */
	priority?: number;
	/**
	 * The handler function. Receives the hook input and mutates the output
	 * object in place. For hooks with no output (`event`, `config`), the
	 * output parameter is `void` and should be ignored.
	 */
	handler: (
		input: HookSignatures[K]["input"],
		output: HookSignatures[K]["output"],
	) => Promise<void> | void;
}

// ============================================================================
// HookRegistry
// ============================================================================

/** Registered handler entry with priority and insertion index for stable sort. */
interface HandlerEntry<K extends HookName> {
	hook: Hook<K>;
	insertionIndex: number;
}

/**
 * Composes multiple hook handlers registered for the same hook name.
 */
export class HookRegistry {
	private readonly handlers = new Map<HookName, HandlerEntry<HookName>[]>();
	private insertionCounter = 0;

	/**
	 * Register a hook handler. Multiple handlers for the same hook name are
	 * composed sequentially by priority when `buildHooks()` is called.
	 */
	register<K extends HookName>(hook: Hook<K>): void {
		const entries = this.handlers.get(hook.name) ?? [];
		// Cast through unknown: TypeScript can't unify Hook<K> with Hook<HookName>
		// because K is a subtype of HookName, not HookName itself.
		entries.push({
			hook: hook as unknown as Hook<HookName>,
			insertionIndex: this.insertionCounter++,
		});
		this.handlers.set(hook.name, entries);
	}

	/**
	 * Build the plugin hooks object from all registered handlers.
	 *
	 * Returns an object whose keys are hook names and whose values are composed
	 * async functions matching the calling convention opencode expects. Hook
	 * names with no registered handlers are omitted.
	 */
	buildHooks(log?: Logger): Record<string, unknown> {
		const result: Record<string, unknown> = {};

		for (const [name, entries] of this.handlers) {
			const sorted = [...entries].sort(
				(a, b) =>
					(a.hook.priority ?? 100) - (b.hook.priority ?? 100) ||
					a.insertionIndex - b.insertionIndex,
			);

			if (name === "event" || name === "config") {
				// event and config are single-argument hooks in the opencode SDK.
				result[name] = async (input: HookSignatures[typeof name]["input"]) => {
					for (const entry of sorted) {
						try {
							await (
								entry.hook.handler as (
									input: unknown,
									output: undefined,
								) => Promise<void> | void
							)(input, undefined as unknown as undefined);
						} catch (error) {
							await log?.warn(`Hook handler for "${name}" failed: ${error}`);
						}
					}
				};
			} else {
				// All other hooks are two-argument: (input, output) => Promise<void>
				result[name] = async (
					input: HookSignatures[typeof name]["input"],
					output: HookSignatures[typeof name]["output"],
				) => {
					for (const entry of sorted) {
						try {
							await (
								entry.hook.handler as (
									input: unknown,
									output: unknown,
								) => Promise<void> | void
							)(input, output);
						} catch (error) {
							await log?.warn(`Hook handler for "${name}" failed: ${error}`);
						}
					}
				};
			}
		}

		return result;
	}
}
