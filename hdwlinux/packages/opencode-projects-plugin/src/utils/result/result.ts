/**
 * Result type for explicit error handling without exceptions
 */

/**
 * Base error interface that all domain errors should extend
 */
export interface BaseError {
	/** Error name/type identifier */
	readonly name: string;
	/** Human-readable error message */
	readonly message: string;
	/** Machine-readable error code */
	readonly code: string;
	/** Whether the error is recoverable */
	readonly recoverable: boolean;
	/** Optional suggestion for resolving the error */
	readonly suggestion?: string;
	/** Optional underlying cause */
	readonly cause?: unknown;
}

/**
 * Result type representing either success or failure
 *
 * The error type E can be any type - BaseError for structured errors,
 * discriminated unions for type-safe error handling, or simple strings.
 */
export type Result<T, E = BaseError> =
	| { ok: true; value: T }
	| { ok: false; error: E };

/**
 * Create a successful Result
 */
export function ok<T>(value: T): Result<T, never> {
	return { ok: true, value };
}

/**
 * Create a failed Result
 */
export function err<E>(error: E): Result<never, E> {
	return { ok: false, error };
}

/**
 * Check if a Result is successful
 */
export function isOk<T, E>(
	result: Result<T, E>,
): result is { ok: true; value: T } {
	return result.ok === true;
}

/**
 * Check if a Result is a failure
 */
export function isErr<T, E>(
	result: Result<T, E>,
): result is { ok: false; error: E } {
	return result.ok === false;
}

/**
 * Map a successful Result value to a new value
 */
export function map<T, U, E>(
	result: Result<T, E>,
	fn: (value: T) => U,
): Result<U, E> {
	if (result.ok) {
		return ok(fn(result.value));
	}
	return result;
}

/**
 * Map a successful Result value to a new Result (flatMap/chain)
 */
export function flatMap<T, U, E, F>(
	result: Result<T, E>,
	fn: (value: T) => Result<U, F>,
): Result<U, E | F> {
	if (result.ok) {
		return fn(result.value);
	}
	return result;
}

/**
 * Map an error to a new error type
 */
export function mapErr<T, E, F>(
	result: Result<T, E>,
	fn: (error: E) => F,
): Result<T, F> {
	if (result.ok) {
		return result;
	}
	return err(fn(result.error));
}

/**
 * Unwrap a Result, throwing if it's an error
 */
export function unwrap<T, E>(result: Result<T, E>): T {
	if (result.ok) {
		return result.value;
	}
	const errorMsg =
		typeof result.error === "object" &&
		result.error !== null &&
		"message" in result.error
			? String((result.error as { message: unknown }).message)
			: String(result.error);
	throw new Error(`Unwrap failed: ${errorMsg}`);
}

/**
 * Unwrap a Result or return a default value
 */
export function unwrapOr<T, E>(result: Result<T, E>, defaultValue: T): T {
	if (result.ok) {
		return result.value;
	}
	return defaultValue;
}

/**
 * Unwrap a Result or compute a default value from the error
 */
export function unwrapOrElse<T, E>(
	result: Result<T, E>,
	fn: (error: E) => T,
): T {
	if (result.ok) {
		return result.value;
	}
	return fn(result.error);
}

/**
 * Match on a Result, providing handlers for both cases
 */
export function match<T, E, U>(
	result: Result<T, E>,
	handlers: {
		ok: (value: T) => U;
		err: (error: E) => U;
	},
): U {
	if (result.ok) {
		return handlers.ok(result.value);
	}
	return handlers.err(result.error);
}

/**
 * Combine multiple Results into a single Result containing an array
 * Returns the first error encountered, or all values if all succeed
 */
export function all<T, E>(results: Result<T, E>[]): Result<T[], E> {
	const values: T[] = [];
	for (const result of results) {
		if (!result.ok) {
			return result;
		}
		values.push(result.value);
	}
	return ok(values);
}

/**
 * Wrap a function that may throw into a Result
 */
export function tryCatch<T, E>(
	fn: () => T,
	onError: (error: unknown) => E,
): Result<T, E> {
	try {
		return ok(fn());
	} catch (error) {
		return err(onError(error));
	}
}

/**
 * Wrap an async function that may throw into a Result
 */
export async function tryCatchAsync<T, E>(
	fn: () => Promise<T>,
	onError: (error: unknown) => E,
): Promise<Result<T, E>> {
	try {
		return ok(await fn());
	} catch (error) {
		return err(onError(error));
	}
}

/**
 * Convert a Result to a Promise (for interop with async/await)
 */
export function toPromise<T, E>(result: Result<T, E>): Promise<T> {
	if (result.ok) {
		return Promise.resolve(result.value);
	}
	const errorMsg =
		typeof result.error === "object" &&
		result.error !== null &&
		"message" in result.error
			? String((result.error as { message: unknown }).message)
			: String(result.error);
	return Promise.reject(new Error(errorMsg));
}

/**
 * Convert a Promise to a Result
 */
export async function fromPromise<T, E>(
	promise: Promise<T>,
	onError: (error: unknown) => E,
): Promise<Result<T, E>> {
	try {
		return ok(await promise);
	} catch (error) {
		return err(onError(error));
	}
}

/**
 * Tap into a successful Result without modifying it (for side effects)
 */
export function tap<T, E>(
	result: Result<T, E>,
	fn: (value: T) => void,
): Result<T, E> {
	if (result.ok) {
		fn(result.value);
	}
	return result;
}

/**
 * Tap into a failed Result without modifying it (for side effects)
 */
export function tapErr<T, E>(
	result: Result<T, E>,
	fn: (error: E) => void,
): Result<T, E> {
	if (!result.ok) {
		fn(result.error);
	}
	return result;
}

/**
 * Provide a fallback Result if the first one fails
 */
export function orElse<T, E, F>(
	result: Result<T, E>,
	fn: (error: E) => Result<T, F>,
): Result<T, F> {
	if (result.ok) {
		return result;
	}
	return fn(result.error);
}

/**
 * Return the first successful Result, or the last error if all fail
 */
export function firstOk<T, E>(results: Result<T, E>[]): Result<T, E> {
	let lastError: E | undefined;
	for (const result of results) {
		if (result.ok) {
			return result;
		}
		lastError = result.error;
	}
	if (lastError) {
		return err(lastError);
	}
	throw new Error("firstOk called with empty array");
}
