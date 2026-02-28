/**
 * Prompt templates module
 *
 * Exports all prompt templates for agent interactions.
 */

export {
  devilsAdvocateTemplate,
  devilsAdvocateSelectionTemplate,
  type DevilsAdvocateSelectionData,
  DEVILS_ADVOCATE_PROMPT,
  buildDevilsAdvocateSelectionPrompt,
} from "./devil-advocate.js"

export {
  teamMemberTemplate,
  type TeamMemberData,
  type PrimaryMemberData,
  type ReviewerMemberData,
} from "./team-member.js"

export {
  teamCompositionTemplate,
  singleAgentSelectionTemplate,
  type TeamCompositionData,
  type SingleAgentSelectionData,
  type AgentInfo,
} from "./selection.js"

export {
  metadataGenerationTemplate,
  type MetadataGenerationData,
} from "./metadata.js"
