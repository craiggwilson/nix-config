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
  formatDelegationError,
  formatPlanningError,
  formatTeamError,
  sanitizeErrorOutput,
} from "./errors.js"
export type { DelegationError, PlanningError, TeamError } from "./errors.js"
