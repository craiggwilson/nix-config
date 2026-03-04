/**
 * ResearchManager - Manages research artifacts and their index
 *
 * Research documents capture findings from investigation tasks, providing
 * a knowledge base for the project. Each research entry includes a summary,
 * key findings, and links to the source issue/session that produced it.
 *
 * The research index provides a table of contents with summaries and links
 * to individual research documents, enabling quick discovery of relevant
 * findings.
 *
 * State is persisted to the research directory:
 * - `research/index.md` - TOC with summaries and links
 * - `research/{slug}.md` - Individual research documents
 *
 * @module research
 */

import * as fs from "node:fs/promises";
import * as path from "node:path";

import type { ArtifactRegistry } from "../artifacts/index.js";
import type { Logger } from "../utils/opencode-sdk/index.js";
import { ok, err, type Result } from "../utils/result/index.js";

/**
 * Represents a tracked research entry with its metadata.
 *
 * Research entries are identified by their artifact ID from the registry.
 * The path can be relative (within projectDir) or absolute (external).
 */
export interface ResearchEntry {
	/** Artifact ID from registry */
	id: string;
	/** Human-readable research title */
	title: string;
	/** Relative path to the research document */
	path: string;
	/** Absolute path for direct file access */
	absolutePath: string;
	/** True if stored outside the project directory */
	external: boolean;
	/** ISO timestamp when the research was created */
	createdAt: string;
	/** Issue ID that produced this research, if any */
	sourceIssue?: string;
	/** Session identifier where this was created */
	sourceSession?: string;
	/** Brief summary of findings */
	summary: string;
	/** Key bullet points from the research */
	keyFindings?: string[];
}

/**
 * Persisted state for the research index.
 *
 * Entries are sorted alphabetically by title for easy discovery.
 */
export interface ResearchIndex {
	/** All research entries, alphabetically sorted by title */
	entries: ResearchEntry[];
}

/**
 * Error types for research operations.
 *
 * Uses discriminated unions for type-safe error handling.
 */
export type ResearchError =
	| { type: "already_exists"; title: string }
	| { type: "not_found"; id: string }
	| { type: "persistence_failed"; message: string };

/**
 * Options for creating a new research entry.
 *
 * The `id` and `createdAt` fields are generated automatically.
 */
export interface CreateResearchOptions {
	/** Human-readable research title */
	title: string;
	/** The research document content (markdown) */
	content: string;
	/** Brief summary of findings */
	summary: string;
	/** Key bullet points from the research */
	keyFindings?: string[];
	/** Issue ID that produced this research */
	sourceIssue?: string;
	/** Session identifier where this was created */
	sourceSession?: string;
	/** Optional custom filename (defaults to slugified title) */
	filename?: string;
}

/**
 * Manages research artifacts for a project.
 *
 * The ResearchManager maintains an index of all research documents produced
 * during project work, enabling discovery by title, source issue, or ID.
 * Research documents are stored as markdown files with the index providing
 * a navigable table of contents.
 *
 * @example
 * ```typescript
 * const manager = new ResearchManager("/path/to/project", artifactRegistry, logger)
 * const index = await manager.load()
 *
 * const result = await manager.createResearch({
 *   title: "Authentication Patterns",
 *   content: "# Authentication Patterns\n\n...",
 *   summary: "Analysis of OAuth2, SAML, and OIDC for enterprise SSO",
 *   keyFindings: [
 *     "OAuth2 with PKCE is best for SPAs",
 *     "SAML still required for enterprise SSO"
 *   ],
 *   sourceIssue: "proj-abc123.1"
 * })
 *
 * if (result.ok) {
 *   console.log("Created research:", result.value.id)
 * }
 * ```
 */
export class ResearchManager {
	/** Path to the project directory */
	private projectDir: string;
	/** Artifact registry for tracking research artifacts */
	private artifactRegistry: ArtifactRegistry;
	/** Logger for tracking research operations */
	private log: Logger;
	/** Optional override for research directory location */
	private researchPath?: string;
	/** In-memory research index, loaded from disk */
	private index: ResearchIndex;

	/**
	 * Creates a new ResearchManager for a specific project.
	 *
	 * Call `load()` before using other methods to initialize state from disk.
	 *
	 * @param projectDir - Absolute path to the project directory
	 * @param artifactRegistry - Registry for tracking artifacts
	 * @param log - Logger instance for operation tracking
	 * @param researchPath - Optional override for research directory location
	 */
	constructor(
		projectDir: string,
		artifactRegistry: ArtifactRegistry,
		log: Logger,
		researchPath?: string,
	) {
		this.projectDir = projectDir;
		this.artifactRegistry = artifactRegistry;
		this.log = log;
		this.researchPath = researchPath;
		this.index = { entries: [] };
	}

	/**
	 * Gets the effective research directory path.
	 *
	 * Returns the custom researchPath if provided, otherwise defaults to
	 * `projectDir/research/`.
	 */
	getResearchDir(): string {
		return this.researchPath ?? path.join(this.projectDir, "research");
	}

	/**
	 * Resolves the path to the research index file.
	 */
	private getIndexPath(): string {
		return path.join(this.getResearchDir(), "index.md");
	}

	/**
	 * Ensures the research directory exists.
	 */
	private async ensureResearchDir(): Promise<void> {
		const researchDir = this.getResearchDir();
		await fs.mkdir(researchDir, { recursive: true });
	}

	/**
	 * Determines if a path is external to the project directory.
	 */
	private isExternal(absolutePath: string): boolean {
		return !absolutePath.startsWith(this.projectDir);
	}

	/**
	 * Generates a slug from a title for use in filenames.
	 *
	 * @param title - The title to slugify
	 * @returns Lowercase, hyphenated slug
	 */
	private slugify(title: string): string {
		return title
			.toLowerCase()
			.replace(/[^a-z0-9]+/g, "-")
			.replace(/^-|-$/g, "")
			.slice(0, 50);
	}

	/**
	 * Loads the research index from disk.
	 *
	 * Parses the index.md file to reconstruct the ResearchIndex structure.
	 * Creates an empty index if the file doesn't exist.
	 *
	 * @returns The loaded research index
	 */
	async load(): Promise<ResearchIndex> {
		const indexPath = this.getIndexPath();

		try {
			const content = await fs.readFile(indexPath, "utf-8");
			this.index = this.parseIndexFile(content);
			await this.log.debug(
				`Loaded ${this.index.entries.length} research entries from index`,
			);
		} catch (error) {
			if ((error as NodeJS.ErrnoException).code === "ENOENT") {
				this.index = { entries: [] };
				await this.log.debug("No existing research index, starting fresh");
			} else {
				throw error;
			}
		}

		return this.index;
	}

	/**
	 * Persists the research index to disk.
	 *
	 * Writes the index.md file with the current state.
	 *
	 * @param index - The index to persist
	 */
	async save(index: ResearchIndex): Promise<void> {
		await this.ensureResearchDir();
		const indexPath = this.getIndexPath();
		const content = this.formatIndexFile(index);
		await fs.writeFile(indexPath, content);
		this.index = index;
		await this.log.debug(
			`Saved research index with ${index.entries.length} entries`,
		);
	}

	/**
	 * Creates a new research entry.
	 *
	 * Writes the research document to the research directory, registers it
	 * in the artifact registry, and updates the index. Returns an error if
	 * a research entry with the same title already exists.
	 *
	 * @param options - Research creation options
	 * @returns The created research entry, or an error
	 */
	async createResearch(
		options: CreateResearchOptions,
	): Promise<Result<ResearchEntry, ResearchError>> {
		// Check for duplicate title
		const existing = this.index.entries.find(
			(e) => e.title.toLowerCase() === options.title.toLowerCase(),
		);
		if (existing) {
			return err({ type: "already_exists", title: options.title });
		}

		const slug = options.filename ?? this.slugify(options.title);
		const filename = `${slug}.md`;
		const researchDir = this.getResearchDir();
		const absolutePath = path.join(researchDir, filename);
		const relativePath = path.relative(this.projectDir, absolutePath);
		const external = this.isExternal(absolutePath);

		try {
			// Ensure directory exists and write the research document
			await this.ensureResearchDir();
			await fs.writeFile(absolutePath, options.content);

			// Register in artifact registry
			const artifactResult = await this.artifactRegistry.register({
				type: "research",
				title: options.title,
				path: external ? absolutePath : relativePath,
				absolutePath,
				external,
				sourceIssue: options.sourceIssue,
				sourceSession: options.sourceSession,
				summary: options.summary,
			});

			if (!artifactResult.ok) {
				// Clean up the written file on registration failure
				await fs.unlink(absolutePath).catch(() => {});
				return err({
					type: "persistence_failed",
					message: `Failed to register artifact: ${artifactResult.error.type}`,
				});
			}

			const entry: ResearchEntry = {
				id: artifactResult.value.id,
				title: options.title,
				path: external ? absolutePath : relativePath,
				absolutePath,
				external,
				createdAt: artifactResult.value.createdAt,
				sourceIssue: options.sourceIssue,
				sourceSession: options.sourceSession,
				summary: options.summary,
				keyFindings: options.keyFindings,
			};

			// Add to index and sort alphabetically by title
			this.index.entries.push(entry);
			this.index.entries.sort((a, b) => a.title.localeCompare(b.title));

			// Save the updated index
			await this.save(this.index);

			await this.log.info(`Created research: ${entry.id} (${entry.title})`);
			return ok(entry);
		} catch (error) {
			const message = error instanceof Error ? error.message : String(error);
			return err({ type: "persistence_failed", message });
		}
	}

	/**
	 * Updates a research entry's metadata.
	 *
	 * Only summary and keyFindings can be updated. The research document
	 * content itself should be edited directly.
	 *
	 * @param id - Research entry ID to update
	 * @param updates - Partial updates to apply
	 * @returns The updated research entry, or an error
	 */
	async updateResearch(
		id: string,
		updates: Partial<Pick<ResearchEntry, "summary" | "keyFindings">>,
	): Promise<Result<ResearchEntry, ResearchError>> {
		const entryIndex = this.index.entries.findIndex((e) => e.id === id);
		if (entryIndex === -1) {
			return err({ type: "not_found", id });
		}

		const entry = this.index.entries[entryIndex];

		// Apply updates
		if (updates.summary !== undefined) {
			entry.summary = updates.summary;
		}
		if (updates.keyFindings !== undefined) {
			entry.keyFindings = updates.keyFindings;
		}

		try {
			await this.save(this.index);
			await this.log.info(`Updated research: ${entry.id}`);
			return ok(entry);
		} catch (error) {
			const message = error instanceof Error ? error.message : String(error);
			return err({ type: "persistence_failed", message });
		}
	}

	/**
	 * Lists all research entries, alphabetically sorted by title.
	 *
	 * @returns Array of all research entries
	 */
	list(): ResearchEntry[] {
		return this.index.entries;
	}

	/**
	 * Retrieves a research entry by its unique ID.
	 *
	 * @param id - Research entry ID to look up
	 * @returns The research entry if found, or null
	 */
	getById(id: string): ResearchEntry | null {
		return this.index.entries.find((e) => e.id === id) ?? null;
	}

	/**
	 * Retrieves all research entries produced by a specific issue.
	 *
	 * @param issueId - Issue ID to filter by
	 * @returns Array of research entries with matching sourceIssue
	 */
	getByIssue(issueId: string): ResearchEntry[] {
		return this.index.entries.filter((e) => e.sourceIssue === issueId);
	}

	/**
	 * Formats the research index file as markdown.
	 *
	 * The index includes a summary table and detailed sections for each
	 * research entry, sorted alphabetically by title.
	 *
	 * @param index - The research index to format
	 * @returns Markdown content for index.md
	 */
	formatIndexFile(index: ResearchIndex): string {
		const lines: string[] = [];

		lines.push("# Research Index");
		lines.push("");

		if (index.entries.length === 0) {
			lines.push("*No research documents yet.*");
			lines.push("");
			return lines.join("\n");
		}

		// Summary table
		lines.push("## Summary");
		lines.push("");
		lines.push("| Title | Summary | Source |");
		lines.push("|-------|---------|--------|");

		for (const entry of index.entries) {
			const linkPath = entry.external
				? entry.absolutePath
				: `./${path.basename(entry.path)}`;
			const source = entry.sourceIssue ?? "-";
			lines.push(
				`| [${entry.title}](${linkPath}) | ${entry.summary} | ${source} |`,
			);
		}

		lines.push("");
		lines.push("---");
		lines.push("");

		// Detailed sections for each entry
		for (const entry of index.entries) {
			lines.push(`## ${entry.title}`);
			lines.push("");

			lines.push(`**ID:** ${entry.id}`);
			if (entry.sourceIssue) {
				lines.push(`**Source Issue:** ${entry.sourceIssue}`);
			}
			lines.push(`**Created:** ${entry.createdAt.split("T")[0]}`);
			lines.push("");
			lines.push(entry.summary);
			lines.push("");

			if (entry.keyFindings && entry.keyFindings.length > 0) {
				lines.push("**Key Findings:**");
				for (const finding of entry.keyFindings) {
					lines.push(`- ${finding}`);
				}
				lines.push("");
			}

			const linkPath = entry.external
				? entry.absolutePath
				: `./${path.basename(entry.path)}`;
			lines.push(
				`**Full Document:** [${path.basename(entry.path)}](${linkPath})`,
			);
			lines.push("");
			lines.push("---");
			lines.push("");
		}

		return lines.join("\n");
	}

	/**
	 * Parses the index.md file to reconstruct the ResearchIndex.
	 *
	 * This is a best-effort parser that extracts structured data from
	 * the markdown format. It handles missing sections gracefully.
	 *
	 * @param content - The raw markdown content
	 * @returns Parsed research index
	 */
	private parseIndexFile(content: string): ResearchIndex {
		const index: ResearchIndex = { entries: [] };
		const lines = content.split("\n");

		let currentEntry: Partial<ResearchEntry> | null = null;
		let inKeyFindings = false;

		for (let i = 0; i < lines.length; i++) {
			const line = lines[i];

			// Detect entry header (## Title)
			if (line.startsWith("## ") && !line.startsWith("## Summary")) {
				// Save previous entry if exists
				if (currentEntry?.title && currentEntry.id) {
					index.entries.push(currentEntry as ResearchEntry);
				}

				const title = line.slice(3).trim();
				currentEntry = {
					title,
					keyFindings: [],
				};
				inKeyFindings = false;
				continue;
			}

			if (!currentEntry) continue;

			// Parse metadata fields
			if (line.startsWith("**ID:**")) {
				currentEntry.id = line.replace("**ID:**", "").trim();
			} else if (line.startsWith("**Source Issue:**")) {
				currentEntry.sourceIssue = line.replace("**Source Issue:**", "").trim();
			} else if (line.startsWith("**Created:**")) {
				const dateStr = line.replace("**Created:**", "").trim();
				currentEntry.createdAt = `${dateStr}T00:00:00.000Z`;
			} else if (line.startsWith("**Key Findings:**")) {
				inKeyFindings = true;
			} else if (line.startsWith("**Full Document:**")) {
				inKeyFindings = false;
				// Extract path from markdown link
				const match = line.match(/\[([^\]]+)\]\(([^)]+)\)/);
				if (match) {
					const linkPath = match[2];
					if (path.isAbsolute(linkPath)) {
						currentEntry.absolutePath = linkPath;
						currentEntry.path = linkPath;
						currentEntry.external = true;
					} else {
						const researchDir = this.getResearchDir();
						currentEntry.absolutePath = path.join(
							researchDir,
							path.basename(linkPath),
						);
						currentEntry.path = path.relative(
							this.projectDir,
							currentEntry.absolutePath,
						);
						currentEntry.external = false;
					}
				}
			} else if (inKeyFindings && line.startsWith("- ")) {
				currentEntry.keyFindings = currentEntry.keyFindings ?? [];
				currentEntry.keyFindings.push(line.slice(2).trim());
			} else if (line.startsWith("---")) {
				// End of entry section
				inKeyFindings = false;
			} else if (
				line.trim() &&
				!line.startsWith("**") &&
				!line.startsWith("-") &&
				!line.startsWith("|") &&
				!line.startsWith("#") &&
				currentEntry.title &&
				!currentEntry.summary
			) {
				// First non-metadata line after title is the summary
				currentEntry.summary = line.trim();
			}
		}

		// Save last entry
		if (currentEntry?.title && currentEntry.id) {
			if (currentEntry.summary && currentEntry.path) {
				index.entries.push(currentEntry as ResearchEntry);
			}
		}

		// Sort alphabetically by title
		index.entries.sort((a, b) => a.title.localeCompare(b.title));

		return index;
	}
}
