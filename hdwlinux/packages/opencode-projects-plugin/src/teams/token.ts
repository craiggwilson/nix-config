import { Token } from "../container/index.js";
import type { TeamManager } from "./team-manager.js";

/** DI token for the {@link TeamManager} singleton. */
export const TeamManagerToken = new Token<TeamManager>("TeamManager");
