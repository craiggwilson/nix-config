import { Token } from "./token.js";
import type {
	BunShell,
	Logger,
	OpencodeClient,
} from "../utils/opencode-sdk/index.js";

/**
 * Infrastructure DI tokens for primitive/cross-cutting services with no owning domain module.
 *
 * Domain-specific tokens live alongside their types in each module's barrel export.
 * Token identity is by reference — always import from this module rather than
 * creating new tokens with the same name.
 */
export const Tokens = {
	Client: new Token<OpencodeClient>("Client"),
	Shell: new Token<BunShell>("Shell"),
	RepoRoot: new Token<string>("RepoRoot"),
	/** Absolute path to the plugin's own directory (dirname of index.ts). */
	PluginDir: new Token<string>("PluginDir"),
	Logger: new Token<Logger>("Logger"),
} as const;
