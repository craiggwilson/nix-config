/**
 * Execution Pipelines
 *
 * Concrete pipeline implementations for different work types.
 */

export { ResearchPipeline } from "./research-pipeline.js";
export type {
  ResearchStageResult,
  ParsedQuestion,
  GatheredContext,
  AnalyzedOption,
  SynthesizedRecommendation,
  ResearchPipelineState,
} from "./research-pipeline.js";

export { POCPipeline } from "./poc-pipeline.js";
export type {
  POCStageResult,
  ParsedHypothesis,
  MinimalDesign,
  ImplementationArtifact as POCImplementationArtifact,
  ValidationResult,
  POCRecommendation,
  POCPipelineState,
} from "./poc-pipeline.js";

export { ImplementationPipeline } from "./implementation-pipeline.js";
export type {
  ImplementationStageResult,
  AnalyzedRequirements,
  DesignArtifact,
  ImplementationArtifact,
  TestResult,
  CodeReviewResult,
  SecurityReviewResult,
  ImplementationPipelineState,
  ImplementationPipelineConfig,
} from "./implementation-pipeline.js";

export { ReviewPipeline } from "./review-pipeline.js";
export type {
  ReviewStageResult,
  FetchedTarget,
  AnalysisResult,
  ProducedFindings,
  ReviewPipelineState,
} from "./review-pipeline.js";
