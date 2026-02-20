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
  StartWorkOptions,
  StartWorkResult,
} from "./project-manager.js"

export { IssueManager } from "./issue-manager.js"
export type {
  UpdateIssueOptions,
  CompletionCommentOptions,
  IssueManagerDeps,
} from "./issue-manager.js"

export { FocusManager } from "./focus-manager.js"

export { ConfigManager } from "./config-manager.js"

export { createLogger } from "./logger.js"

export * from "./types.js"

export * from "./test-utils.js"

export { buildIssueTree, renderTree, renderIssueTree } from "./tree-renderer.js"

export { promptSmallModel } from "./small-model.js"
export type { SmallModelOptions, SmallModelResult } from "./small-model.js"

export { selectAgent, discoverAgents } from "./agent-selector.js"
export type { AgentInfo, AgentSelectionContext } from "./agent-selector.js"

export { runShell, runShellInDir } from "./shell-utils.js"
export type { ShellResult } from "./shell-utils.js"

export {
  ProjectsPluginError,
  ProjectNotFoundError,
  IssueNotFoundError,
  BeadsNotAvailableError,
  VCSNotDetectedError,
  WorktreeError,
  MergeConflictError,
  NoProjectFocusedError,
  ConfigurationError,
  formatError,
} from "./errors.js"
