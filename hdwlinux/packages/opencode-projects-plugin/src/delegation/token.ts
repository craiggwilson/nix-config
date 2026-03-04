import { Token } from "../container/index.js";
import type { DelegationManager } from "./delegation-manager.js";

/** DI token for the {@link DelegationManager} singleton. */
export const DelegationManagerToken = new Token<DelegationManager>(
	"DelegationManager",
);
