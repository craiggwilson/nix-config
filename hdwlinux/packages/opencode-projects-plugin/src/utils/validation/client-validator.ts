/**
 * Runtime validation for OpenCode SDK client
 *
 * Validates that the client object from the plugin context matches
 * the expected OpencodeClient interface. This prevents cryptic runtime
 * failures when the SDK API changes.
 */

import { z } from "zod";
import type { OpencodeClient } from "../opencode-sdk/index.js";
import type { Result } from "../result/index.js";

/**
 * Validation error with detailed context
 */
export class ClientValidationError extends Error {
	constructor(
		message: string,
		public readonly path?: string,
		public readonly expected?: string,
	) {
		super(message);
		this.name = "ClientValidationError";
	}
}

/**
 * Zod schema for the app object
 */
const AppSchema = z.object({
	log: z.function(),
	agents: z.function(),
});

/**
 * Zod schema for the session object
 */
const SessionSchema = z.object({
	create: z.function(),
	get: z.function(),
	prompt: z.function(),
	messages: z.function(),
	delete: z.function(),
});

/**
 * Zod schema for the config object
 */
const ConfigSchema = z.object({
	get: z.function(),
});

/**
 * Zod schema for the complete OpencodeClient interface
 */
const OpencodeClientSchema = z.object({
	app: AppSchema,
	session: SessionSchema,
	config: ConfigSchema,
});

/**
 * Validates that a client object conforms to the OpencodeClient interface.
 *
 * This function performs runtime validation to ensure the SDK client has
 * all required properties and methods. If validation fails, it returns
 * a detailed error explaining what's missing or invalid.
 *
 * @param client - The client object to validate (from plugin context)
 * @returns Result with validated client or detailed error
 *
 * @example
 * ```typescript
 * const result = validateClient(ctx.client)
 * if (!result.ok) {
 *   throw new Error(`Invalid OpenCode client: ${result.error.message}`)
 * }
 * const client = result.value
 * ```
 */
export function validateClient(
	client: unknown,
): Result<OpencodeClient, ClientValidationError> {
	if (!client || typeof client !== "object") {
		return {
			ok: false,
			error: new ClientValidationError(
				"OpenCode client must be an object",
				undefined,
				"object with app, session, and config properties",
			),
		};
	}

	const result = OpencodeClientSchema.safeParse(client);

	if (!result.success) {
		const issues = result.error?.issues || [];
		const firstIssue = issues[0];

		if (!firstIssue) {
			return {
				ok: false,
				error: new ClientValidationError(
					"OpenCode client validation failed with unknown error",
					undefined,
					undefined,
				),
			};
		}

		const path = firstIssue.path.join(".");
		const message = firstIssue.message;
		const expected = (firstIssue as { expected?: string }).expected;

		return {
			ok: false,
			error: new ClientValidationError(
				`OpenCode client validation failed at '${path}': ${message}`,
				path,
				expected,
			),
		};
	}

	return {
		ok: true,
		value: client as OpencodeClient,
	};
}

/**
 * Validates the client and throws if invalid.
 *
 * Convenience wrapper around validateClient that throws instead of
 * returning a Result type.
 *
 * @param client - The client object to validate
 * @returns The validated client
 * @throws {ClientValidationError} If validation fails
 *
 * @example
 * ```typescript
 * try {
 *   const client = validateClientOrThrow(ctx.client)
 *   // Use client safely
 * } catch (error) {
 *   if (error instanceof ClientValidationError) {
 *     console.error(`Invalid client at ${error.path}: ${error.message}`)
 *   }
 * }
 * ```
 */
export function validateClientOrThrow(client: unknown): OpencodeClient {
	const result = validateClient(client);
	if (!result.ok) {
		throw result.error;
	}
	return result.value;
}
