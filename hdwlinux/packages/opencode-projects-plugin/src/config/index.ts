/**
 * Configuration module
 */

export {
	ConfigManager,
	getDataDir,
	ConfigLoadError,
	type TeamDiscussionSettings,
} from "./config-manager.js";
export * from "./config-schema.js";
export { configModule } from "./module.js";

export { ConfigManagerToken } from "./token.js";
