/**
 * Metadata generation prompt templates
 *
 * Templates for generating titles and descriptions for delegation results.
 */

import type { PromptTemplate } from "../prompt.js";

/**
 * Data for metadata generation
 */
export interface MetadataGenerationData {
	/** The delegation result to summarize */
	result: string;
	/** Maximum length for the result excerpt (default: 2000) */
	maxResultLength?: number;
}

/**
 * Template for generating title and description metadata.
 *
 * Used by the small model to create concise summaries of delegation results.
 */
export const metadataGenerationTemplate: PromptTemplate<MetadataGenerationData> =
	{
		name: "metadata-generation",
		description:
			"Small model prompt to generate title and description for delegation results",

		render: (data) => {
			const maxLen = data.maxResultLength ?? 2000;
			const resultExcerpt = data.result.slice(0, maxLen);

			return `Generate a title and description for this delegation result.

RULES:
- Title: 2-5 words, max 30 characters, summarize the outcome
- Description: 2-3 sentences, max 200 characters, describe what was accomplished

RESULT:
${resultExcerpt}

Respond with ONLY valid JSON:
{"title": "Your Title", "description": "Your description."}`;
		},
	};
