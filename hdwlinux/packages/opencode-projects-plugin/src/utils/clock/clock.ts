/**
 * Clock abstraction for testability.
 *
 * Provides a consistent interface for time-related operations, allowing
 * tests to control time without relying on wall clock.
 */

/**
 * Handle returned by setTimeout, used for clearTimeout.
 */
export type TimeoutHandle = ReturnType<typeof setTimeout>;

/**
 * Abstraction over time-related operations.
 *
 * Production code should use this interface instead of direct calls to
 * Date.now(), new Date(), or setTimeout. This enables tests to control
 * time progression without real delays.
 */
export interface Clock {
	/** Returns current timestamp in milliseconds since epoch */
	now(): number;

	/** Returns current time as ISO 8601 string */
	toISOString(): string;

	/** Schedule a callback after delay milliseconds */
	setTimeout(callback: () => void, delayMs: number): TimeoutHandle;

	/** Cancel a scheduled timeout */
	clearTimeout(handle: TimeoutHandle): void;

	/** Returns a promise that resolves after delay milliseconds */
	sleep(delayMs: number): Promise<void>;
}

/**
 * System clock implementation using real time.
 *
 * This is the default implementation for production use.
 */
export class SystemClock implements Clock {
	now(): number {
		return Date.now();
	}

	toISOString(): string {
		return new Date().toISOString();
	}

	setTimeout(callback: () => void, delayMs: number): TimeoutHandle {
		return setTimeout(callback, delayMs);
	}

	clearTimeout(handle: TimeoutHandle): void {
		clearTimeout(handle);
	}

	sleep(delayMs: number): Promise<void> {
		return new Promise((resolve) => setTimeout(resolve, delayMs));
	}
}

/**
 * Mock clock for testing with controllable time.
 *
 * Allows tests to advance time manually without real delays.
 * Scheduled callbacks are executed synchronously when time advances past their deadline.
 */
export class MockClock implements Clock {
	private currentTime: number;
	private nextId = 1;
	private scheduledCallbacks: Map<
		number,
		{ callback: () => void; deadline: number }
	> = new Map();
	private pendingSleeps: Array<{ deadline: number; resolve: () => void }> = [];

	constructor(initialTime: number = 0) {
		this.currentTime = initialTime;
	}

	now(): number {
		return this.currentTime;
	}

	toISOString(): string {
		return new Date(this.currentTime).toISOString();
	}

	setTimeout(callback: () => void, delayMs: number): TimeoutHandle {
		const id = this.nextId++;
		const deadline = this.currentTime + delayMs;
		this.scheduledCallbacks.set(id, { callback, deadline });
		return id as unknown as TimeoutHandle;
	}

	clearTimeout(handle: TimeoutHandle): void {
		this.scheduledCallbacks.delete(handle as unknown as number);
	}

	sleep(delayMs: number): Promise<void> {
		const deadline = this.currentTime + delayMs;
		return new Promise((resolve) => {
			this.pendingSleeps.push({ deadline, resolve });
		});
	}

	/**
	 * Advance time by the specified milliseconds.
	 *
	 * Executes any scheduled callbacks whose deadline has passed.
	 * Resolves any pending sleep promises whose deadline has passed.
	 */
	advance(ms: number): void {
		this.currentTime += ms;
		this.executeScheduledCallbacks();
		this.resolvePendingSleeps();
	}

	/**
	 * Set the current time to a specific value.
	 *
	 * Executes any scheduled callbacks whose deadline has passed.
	 */
	setTime(time: number): void {
		this.currentTime = time;
		this.executeScheduledCallbacks();
		this.resolvePendingSleeps();
	}

	/**
	 * Execute all scheduled callbacks whose deadline has passed.
	 * Callbacks are executed in deadline order (earliest first).
	 */
	private executeScheduledCallbacks(): void {
		const toExecute: Array<{
			callback: () => void;
			deadline: number;
			id: number;
		}> = [];

		for (const [id, { callback, deadline }] of this.scheduledCallbacks) {
			if (deadline <= this.currentTime) {
				toExecute.push({ callback, deadline, id });
				this.scheduledCallbacks.delete(id);
			}
		}

		// Sort by deadline (earliest first)
		toExecute.sort((a, b) => a.deadline - b.deadline);

		for (const { callback } of toExecute) {
			callback();
		}
	}

	/**
	 * Resolve all pending sleep promises whose deadline has passed.
	 */
	private resolvePendingSleeps(): void {
		const stillPending: Array<{ deadline: number; resolve: () => void }> = [];

		for (const { deadline, resolve } of this.pendingSleeps) {
			if (deadline <= this.currentTime) {
				resolve();
			} else {
				stillPending.push({ deadline, resolve });
			}
		}

		this.pendingSleeps = stillPending;
	}

	/**
	 * Get the number of pending scheduled callbacks.
	 */
	getPendingCount(): number {
		return this.scheduledCallbacks.size;
	}

	/**
	 * Get the number of pending sleep promises.
	 */
	getPendingSleepCount(): number {
		return this.pendingSleeps.length;
	}

	/**
	 * Clear all scheduled callbacks and pending sleeps.
	 */
	reset(time: number = 0): void {
		this.currentTime = time;
		this.scheduledCallbacks.clear();
		this.pendingSleeps = [];
	}
}

/**
 * Default system clock instance for production use.
 */
export const systemClock: Clock = new SystemClock();
