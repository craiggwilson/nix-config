import { Token } from "../container/index.js";
import type { WorktreeManager } from "./worktree-manager.js";

/** DI token for the {@link WorktreeManager} singleton. */
export const WorktreeManagerToken = new Token<WorktreeManager>(
	"WorktreeManager",
);
