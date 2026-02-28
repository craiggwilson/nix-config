/**
 * Error types module
 */

export {
  ProjectsPluginError,
  ProjectNotFoundError,
  IssueNotFoundError,
  BeadsNotAvailableError,
  VCSError,
  VCSNotDetectedError,
  VCSCommandError,
  WorktreeError,
  WorktreeExistsError,
  MergeConflictError,
  NoProjectFocusedError,
  ConfigurationError,
  formatError,
  formatBeadsError,
  formatDelegationError,
  formatTeamError,
  sanitizeErrorOutput,
} from "./errors.js"
export type { DelegationError, TeamError, BeadsError } from "./errors.js"
