/**
 * Core module - Project management fundamentals
 */

export { ProjectManager } from "./project-manager.js"
export type {
  ProjectMetadata,
  CreateProjectOptions,
  ListProjectsOptions,
  CloseProjectOptions,
  CreateProjectResult,
  ProjectManagerDeps,
} from "./project-manager.js"

export { FocusManager } from "./focus-manager.js"

export { ConfigManager } from "./config-manager.js"

export { createLogger } from "./logger.js"

export * from "./types.js"

export * from "./test-utils.js"
