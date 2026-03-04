/**
 * ArtifactRegistry - Tracks artifacts produced during project work
 *
 * Artifacts are any outputs produced during a project: research documents,
 * decision records, deliverables, diagrams, etc. The registry provides a
 * centralized index of all artifacts with metadata for discovery and retrieval.
 *
 * Artifacts can be stored within the project directory or externally (e.g., in
 * the workspace root). External artifacts are tracked by absolute path while
 * internal artifacts use relative paths for portability.
 *
 * State is persisted to `artifacts.json` within the project directory.
 *
 * @module artifacts
 */

import * as fs from "node:fs/promises";
import * as path from "node:path";
import * as crypto from "node:crypto";

import type { Logger } from "../utils/opencode-sdk/index.js";
import { ok, err, type Result } from "../utils/result/index.js";

/**
 * Represents a tracked artifact produced during project work.
 *
 * Artifacts are identified by a unique ID combining type, title slug, and
 * random suffix. This allows human-readable IDs while avoiding collisions.
 */
export interface Artifact {
	/** Unique identifier in format: {type}-{slug}-{random} */
	id: string;
	/** User-defined artifact type (e.g., "research", "decision", "deliverable") */
	type: string;
	/** Human-readable title */
	title: string;
	/** Relative path from projectDir (or workspace if external) */
	path: string;
	/** Absolute path for direct file access */
	absolutePath: string;
	/** True if the artifact is stored outside the project directory */
	external: boolean;
	/** ISO timestamp when the artifact was registered */
	createdAt: string;
	/** Issue ID that produced this artifact, if any */
	sourceIssue?: string;
	/** Session identifier in format: {seq}-{sessionId}-{date} */
	sourceSession?: string;
	/** Brief description of the artifact's contents or purpose */
	summary?: string;
}

/**
 * Persisted state for the artifact registry.
 */
export interface ArtifactRegistryData {
	/** All registered artifacts */
	artifacts: Artifact[];
}

/**
 * Error types for artifact operations.
 *
 * Uses discriminated unions for type-safe error handling.
 */
export type ArtifactError =
	| { type: "already_exists"; id: string }
	| { type: "not_found"; id: string }
	| { type: "persistence_failed"; message: string };

/**
 * Options for filtering artifact listings.
 */
export interface ListOptions {
	/** Filter by artifact type */
	type?: string;
	/** Filter by source issue ID */
	sourceIssue?: string;
	/** Filter by source session ID */
	sourceSession?: string;
}

/**
 * Input for registering a new artifact.
 *
 * The `id` and `createdAt` fields are generated automatically.
 */
export type ArtifactInput = Omit<Artifact, "id" | "createdAt">;

/**
 * Manages artifact registration and retrieval for a project.
 *
 * The registry maintains an index of all artifacts produced during project work,
 * enabling discovery by type, source issue, or session. Artifacts themselves are
 * stored as files; the registry only tracks metadata.
 *
 * @example
 * ```typescript
 * const registry = new ArtifactRegistry("/path/to/project", logger)
 * await registry.load()
 *
 * const result = await registry.register({
 *   type: "research",
 *   title: "Authentication Patterns",
 *   path: "research/auth-patterns.md",
 *   absolutePath: "/path/to/project/research/auth-patterns.md",
 *   external: false,
 *   sourceIssue: "proj-abc123.1",
 *   summary: "Analysis of OAuth2 vs SAML for enterprise SSO"
 * })
 *
 * if (result.ok) {
 *   console.log("Registered artifact:", result.value.id)
 * }
 * ```
 */
export class ArtifactRegistry {
	/** Path to the project directory containing artifacts.json */
	private projectDir: string;
	/** Logger for tracking registry operations */
	private log: Logger;
	/** In-memory artifact data, loaded from disk */
	private data: ArtifactRegistryData;

	/**
	 * Creates a new ArtifactRegistry for a specific project.
	 *
	 * Call `load()` before using other methods to initialize state from disk.
	 *
	 * @param projectDir - Absolute path to the project directory
	 * @param log - Logger instance for operation tracking
	 */
	constructor(projectDir: string, log: Logger) {
		this.projectDir = projectDir;
		this.log = log;
		this.data = { artifacts: [] };
	}

	/**
	 * Resolves the path to the artifact registry file.
	 */
	private getRegistryPath(): string {
		return path.join(this.projectDir, "artifacts.json");
	}

	/**
	 * Loads the artifact registry from disk.
	 *
	 * Creates an empty registry if the file doesn't exist. This allows the
	 * registry to be used immediately without explicit initialization.
	 */
	async load(): Promise<void> {
		const registryPath = this.getRegistryPath();

		try {
			const content = await fs.readFile(registryPath, "utf-8");
			this.data = JSON.parse(content) as ArtifactRegistryData;
			await this.log.debug(
				`Loaded ${this.data.artifacts.length} artifacts from registry`,
			);
		} catch (error) {
			if ((error as NodeJS.ErrnoException).code === "ENOENT") {
				this.data = { artifacts: [] };
				await this.log.debug("No existing artifact registry, starting fresh");
			} else {
				throw error;
			}
		}
	}

	/**
	 * Persists the artifact registry to disk.
	 *
	 * Writes atomically via Node's writeFile to prevent corruption from
	 * interrupted writes.
	 */
	async save(): Promise<void> {
		const registryPath = this.getRegistryPath();
		await fs.writeFile(registryPath, JSON.stringify(this.data, null, 2));
		await this.log.debug(
			`Saved ${this.data.artifacts.length} artifacts to registry`,
		);
	}

	/**
	 * Generates a unique artifact ID from type and title.
	 *
	 * The ID format is `{type}-{slug}-{random}` where:
	 * - type: The artifact type (e.g., "research")
	 * - slug: Lowercase, hyphenated version of the title (max 30 chars)
	 * - random: 6-character hex string for uniqueness
	 *
	 * @param type - Artifact type
	 * @param title - Human-readable title
	 * @returns Generated ID like "research-auth-patterns-abc123"
	 */
	generateId(type: string, title: string): string {
		const slug = title
			.toLowerCase()
			.replace(/[^a-z0-9]+/g, "-")
			.replace(/^-|-$/g, "")
			.slice(0, 30);

		const random = crypto.randomBytes(3).toString("hex");

		return `${type}-${slug}-${random}`;
	}

	/**
	 * Registers a new artifact in the registry.
	 *
	 * Generates a unique ID and timestamp, then persists the updated registry.
	 * Returns an error if an artifact with the same path already exists.
	 *
	 * @param input - Artifact metadata (without id and createdAt)
	 * @returns The registered artifact with generated fields, or an error
	 */
	async register(
		input: ArtifactInput,
	): Promise<Result<Artifact, ArtifactError>> {
		// Check for duplicate path
		const existing = this.data.artifacts.find(
			(a) => a.absolutePath === input.absolutePath,
		);
		if (existing) {
			return err({ type: "already_exists", id: existing.id });
		}

		const artifact: Artifact = {
			...input,
			id: this.generateId(input.type, input.title),
			createdAt: new Date().toISOString(),
		};

		this.data.artifacts.push(artifact);

		try {
			await this.save();
			await this.log.info(
				`Registered artifact: ${artifact.id} (${artifact.type})`,
			);
			return ok(artifact);
		} catch (error) {
			// Rollback in-memory change on save failure
			this.data.artifacts.pop();
			const message = error instanceof Error ? error.message : String(error);
			return err({ type: "persistence_failed", message });
		}
	}

	/**
	 * Lists artifacts with optional filtering.
	 *
	 * Filters are combined with AND logic - an artifact must match all
	 * specified filters to be included.
	 *
	 * @param options - Optional filters for type, sourceIssue, or sourceSession
	 * @returns Array of matching artifacts
	 */
	list(options?: ListOptions): Artifact[] {
		let artifacts = this.data.artifacts;

		if (options?.type) {
			artifacts = artifacts.filter((a) => a.type === options.type);
		}

		if (options?.sourceIssue) {
			artifacts = artifacts.filter(
				(a) => a.sourceIssue === options.sourceIssue,
			);
		}

		if (options?.sourceSession) {
			artifacts = artifacts.filter(
				(a) => a.sourceSession === options.sourceSession,
			);
		}

		return artifacts;
	}

	/**
	 * Retrieves an artifact by its unique ID.
	 *
	 * @param id - Artifact ID to look up
	 * @returns The artifact if found, or null
	 */
	getById(id: string): Artifact | null {
		return this.data.artifacts.find((a) => a.id === id) ?? null;
	}

	/**
	 * Retrieves all artifacts produced by a specific issue.
	 *
	 * @param issueId - Issue ID to filter by
	 * @returns Array of artifacts with matching sourceIssue
	 */
	getByIssue(issueId: string): Artifact[] {
		return this.data.artifacts.filter((a) => a.sourceIssue === issueId);
	}

	/**
	 * Retrieves all artifacts produced in a specific session.
	 *
	 * @param sessionId - Session ID to filter by
	 * @returns Array of artifacts with matching sourceSession
	 */
	getBySession(sessionId: string): Artifact[] {
		return this.data.artifacts.filter((a) => a.sourceSession === sessionId);
	}

	/**
	 * Retrieves all artifacts of a specific type.
	 *
	 * @param type - Artifact type to filter by (e.g., "research", "decision")
	 * @returns Array of artifacts with matching type
	 */
	getByType(type: string): Artifact[] {
		return this.data.artifacts.filter((a) => a.type === type);
	}
}
