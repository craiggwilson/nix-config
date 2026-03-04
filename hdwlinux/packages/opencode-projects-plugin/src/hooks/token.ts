import { Token } from "../container/index.js";
import type { HookRegistry } from "./registry.js";

/** DI token for the {@link HookRegistry} singleton. */
export const HookRegistryToken = new Token<HookRegistry>("HookRegistry");
