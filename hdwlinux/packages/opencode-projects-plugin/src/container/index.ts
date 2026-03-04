/**
 * Type-safe two-phase dependency injection container.
 *
 * @example
 *   import { Token, TypeSafeContainer } from "./container/index.js"
 *
 *   const Tokens = {
 *     Config: new Token<Config>("Config"),
 *     Logger: new Token<Logger>("Logger"),
 *   }
 *
 *   const container = new TypeSafeContainer()
 *   container.register(Tokens.Config, [], () => ConfigManager.loadOrThrow())
 *   container.register(Tokens.Logger, [Tokens.Config], (cfg) => createLogger(cfg))
 *   await container.build()
 *
 *   const logger = container.resolve(Tokens.Logger)
 */

export { TypeSafeContainer } from "./container.js";
export { Token } from "./token.js";
export type {
	Factory,
	Resolve,
	ResolveTokens,
	ServiceDescriptor,
} from "./token.js";
export type { ContainerModule } from "./module.js";
export { Tokens } from "./tokens.js";
