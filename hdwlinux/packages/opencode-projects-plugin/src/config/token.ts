import { Token } from "../container/index.js";
import type { ConfigManager } from "./config-manager.js";

/** DI token for the {@link ConfigManager} singleton. */
export const ConfigManagerToken = new Token<ConfigManager>("Config");
