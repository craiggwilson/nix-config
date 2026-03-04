/**
 * Token class for type-safe dependency injection.
 *
 * Each token represents a service in the container. The type parameter T
 * carries the resolved type through the type system, enabling the container
 * to infer factory argument types from the dependency array.
 *
 * Token identity is by reference, not by name — two tokens with the same
 * name are distinct. Always define tokens in a single canonical object and
 * reuse them.
 *
 * @example
 *   const Tokens = {
 *     Config: new Token<Config>("Config"),
 *     Shell: new Token<Shell>("Shell"),
 *   }
 */
export class Token<_T = unknown> {
	/**
	 * Creates a new token.
	 *
	 * @param name - Human-readable name used in error messages and debug output.
	 */
	constructor(readonly name: string) {}

	toString(): string {
		return `Token(${this.name})`;
	}
}

/**
 * Extracts the resolved type from a token.
 *
 * @example
 *   type ConfigType = Resolve<Token<Config>>  // Config
 */
export type Resolve<T> = T extends Token<infer U> ? U : never;

/**
 * Maps a tuple of tokens to a tuple of their resolved types.
 *
 * Enables the container to derive factory argument types directly from the
 * dependency array, eliminating the need to declare types twice.
 *
 * @example
 *   type Args = ResolveTokens<[Token<Config>, Token<Shell>]>
 *   // Args = [Config, Shell]
 */
export type ResolveTokens<T extends readonly Token<unknown>[]> = {
	[K in keyof T]: T[K] extends Token<infer U> ? U : never;
};

/**
 * Factory function type that receives resolved dependencies as positional arguments.
 *
 * Supports both synchronous and asynchronous factories. The argument types are
 * inferred from the token array, so the factory never needs to call resolve().
 *
 * @example
 *   type PM_Factory = Factory<[Token<Config>, Token<Shell>], ProjectManager>
 *   // (config: Config, shell: Shell) => ProjectManager | Promise<ProjectManager>
 */
export type Factory<Deps extends readonly Token<unknown>[], T> = (
	...args: ResolveTokens<Deps>
) => T | Promise<T>;

/**
 * Internal descriptor stored per registered service.
 */
export interface ServiceDescriptor {
	/** The token this descriptor is registered under. */
	token: Token<unknown>;
	/** Ordered list of tokens this service depends on. */
	dependencies: Token<unknown>[];
	/** Factory called with resolved dependency values as positional arguments. */
	factory: (...args: unknown[]) => unknown | Promise<unknown>;
}
