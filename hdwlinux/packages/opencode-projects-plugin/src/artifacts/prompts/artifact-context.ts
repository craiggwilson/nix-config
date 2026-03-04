/**
 * Artifact context builder for prompt injection
 *
 * Builds context from the artifact registry, grouping artifacts by type
 * for easy reference in agent prompts. This enables agents to discover
 * and reference existing project outputs.
 */

import type { ArtifactRegistry, Artifact } from "../artifact-registry.js";

/**
 * Artifacts grouped by their type for structured access.
 */
export interface ArtifactsByType {
	[type: string]: Artifact[];
}

/**
 * Aggregated artifact context for prompt injection.
 *
 * Contains all artifacts from the registry organized for easy consumption
 * by agents, with grouping by type and summary statistics.
 */
export interface ArtifactContext {
	/** All registered artifacts */
	artifacts: Artifact[];
	/** Artifacts grouped by type */
	byType: ArtifactsByType;
	/** Sorted list of artifact types present */
	types: string[];
	/** Total number of artifacts */
	count: number;
}

/**
 * Builds artifact context for prompt injection.
 *
 * Extracts all artifacts from the registry and organizes them by type,
 * sorting both types and artifacts within each type alphabetically.
 *
 * @param artifactRegistry - The artifact registry to build context from
 * @returns Aggregated artifact context
 */
export function buildArtifactContext(
	artifactRegistry: ArtifactRegistry,
): ArtifactContext {
	const artifacts = artifactRegistry.list();
	const byType: ArtifactsByType = {};

	for (const artifact of artifacts) {
		if (!byType[artifact.type]) {
			byType[artifact.type] = [];
		}
		byType[artifact.type].push(artifact);
	}

	for (const type of Object.keys(byType)) {
		byType[type].sort((a, b) => a.title.localeCompare(b.title));
	}

	const types = Object.keys(byType).sort();

	return {
		artifacts,
		byType,
		count: artifacts.length,
		types,
	};
}

/**
 * Formats artifact context as markdown for prompt injection.
 *
 * Produces a structured listing of all artifacts grouped by type,
 * suitable for inclusion in system prompts.
 *
 * @param context - The artifact context to format
 * @returns Markdown-formatted context string, empty if no artifacts
 */
export function formatArtifactContext(context: ArtifactContext): string {
	if (context.count === 0) {
		return "";
	}

	const lines: string[] = [];
	lines.push("## Available Artifacts");
	lines.push("");

	for (const type of context.types) {
		const artifacts = context.byType[type];
		const typeLabel = type.charAt(0).toUpperCase() + type.slice(1);

		lines.push(`### ${typeLabel}`);
		lines.push("");

		for (const artifact of artifacts) {
			const location = artifact.external ? " (external)" : "";
			const summary = artifact.summary ? ` - ${artifact.summary}` : "";
			lines.push(
				`- **${artifact.title}**${location}: \`${artifact.path}\`${summary}`,
			);
		}

		lines.push("");
	}

	return lines.join("\n").trim();
}

/**
 * Formats a compact artifact summary for limited context.
 *
 * Produces a brief one-line-per-type summary listing artifact titles,
 * useful when full context would be too verbose.
 *
 * @param context - The artifact context to summarize
 * @returns Compact summary string
 */
export function formatArtifactSummary(context: ArtifactContext): string {
	if (context.count === 0) {
		return "No artifacts registered.";
	}

	const typeSummaries: string[] = [];

	for (const type of context.types) {
		const artifacts = context.byType[type];
		const titles = artifacts.map((a) => a.title).join(", ");
		typeSummaries.push(`**${type}:** ${titles}`);
	}

	return typeSummaries.join("\n");
}

/**
 * Checks if there are any artifacts to inject.
 *
 * Returns true if the context contains at least one artifact,
 * allowing callers to skip context injection when empty.
 *
 * @param context - The artifact context to check
 * @returns True if context contains any artifacts
 */
export function hasArtifactContext(context: ArtifactContext): boolean {
	return context.count > 0;
}
