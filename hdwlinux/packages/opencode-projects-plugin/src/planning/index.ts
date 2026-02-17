/**
 * Planning module - Interview and artifact management
 */

export { InterviewManager } from "./interview-manager.js"
export type {
  InterviewSession,
  InterviewSummary,
  InterviewExchange,
} from "./interview-manager.js"

export { ArtifactManager } from "./artifact-manager.js"
export type {
  ArtifactType,
  ArtifactMetadata,
  RoadmapContent,
  ArchitectureContent,
  RisksContent,
  SuccessCriteriaContent,
  Milestone,
  Risk,
  SuccessCriterion,
  ArchitectureComponent,
} from "./artifact-manager.js"

export { PlanningDelegator } from "./planning-delegator.js"
export type {
  PlanningPhase,
  DelegationRequest,
  DelegationResult,
} from "./planning-delegator.js"

// Re-export AgentInfo from core for backwards compatibility
export type { AgentInfo } from "./planning-delegator.js"
