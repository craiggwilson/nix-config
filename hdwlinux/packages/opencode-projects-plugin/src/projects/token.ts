import { Token } from "../container/index.js";
import type { ProjectManager } from "./project-manager.js";
import type { FocusManager } from "./focus-manager.js";

/** DI token for the {@link ProjectManager} singleton. */
export const ProjectManagerToken = new Token<ProjectManager>("ProjectManager");

/** DI token for the {@link FocusManager} singleton. */
export const FocusManagerToken = new Token<FocusManager>("Focus");
