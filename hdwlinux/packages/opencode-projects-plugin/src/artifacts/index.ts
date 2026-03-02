/**
 * Artifact Registry module for tracking project outputs
 *
 * Provides centralized tracking of all artifacts (research, decisions,
 * deliverables, etc.) produced during project work.
 */

export type {
  Artifact,
  ArtifactRegistryData,
  ArtifactError,
  ArtifactInput,
  ListOptions,
} from "./artifact-registry.js"

export { ArtifactRegistry } from "./artifact-registry.js"

export {
  buildArtifactContext,
  formatArtifactContext,
  formatArtifactSummary,
  hasArtifactContext,
  type ArtifactContext,
  type ArtifactsByType,
} from "./prompts/artifact-context.js"
