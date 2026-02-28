/**
 * Prompt utilities module
 *
 * Provides a template-based system for building agent prompts.
 * Templates are typed objects that render prompts from structured data,
 * while sections are reusable prompt fragments.
 *
 * @example
 * ```typescript
 * import { teamMemberTemplate, xmlWrap, lines } from "./utils/prompts/index.js"
 *
 * // Use a template
 * const prompt = teamMemberTemplate.render({
 *   role: "primary",
 *   agent: "typescript-expert",
 *   issueId: "proj-123",
 *   issueContext: "Implement feature X",
 *   hasReviewers: true
 * })
 *
 * // Use utilities directly
 * const wrapped = xmlWrap("context", lines("Line 1", "Line 2"))
 * ```
 */

export type { PromptData, PromptSection, PromptTemplate } from "./prompt.js"

export { xmlWrap, lines, section, bulletList, numberedList } from "./xml-wrapper.js"
export type { XmlWrapOptions } from "./xml-wrapper.js"

export {
  delegationConstraints,
  readOnlyConstraints,
  disabledToolsList,
} from "./sections/index.js"

export {
  devilsAdvocateTemplate,
  devilsAdvocateSelectionTemplate,
  type DevilsAdvocateSelectionData,
  teamMemberTemplate,
  type TeamMemberData,
  type PrimaryMemberData,
  type ReviewerMemberData,
  teamCompositionTemplate,
  singleAgentSelectionTemplate,
  type TeamCompositionData,
  type SingleAgentSelectionData,
  type AgentInfo,
  metadataGenerationTemplate,
  type MetadataGenerationData,
} from "./templates/index.js"
