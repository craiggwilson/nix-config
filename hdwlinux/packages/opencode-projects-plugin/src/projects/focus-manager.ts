/**
 * Focus management for opencode-projects plugin
 *
 * Tracks the currently focused project for context injection.
 * Issue context is provided directly when needed (e.g., in delegation prompts).
 */

/**
 * Focus state - tracks only project focus
 */
export interface FocusState {
	projectId: string;
}

/**
 * Focus manager - tracks current project context
 *
 * Note: This is in-memory state that persists for the plugin lifetime.
 * For cross-session persistence, we rely on session compaction hooks
 * to inject focus state into the continuation prompt.
 */
export class FocusManager {
	private current: FocusState | null = null;

	/**
	 * Get current focus state
	 */
	getCurrent(): FocusState | null {
		return this.current;
	}

	/**
	 * Set focus to a project
	 */
	setFocus(projectId: string): void {
		this.current = { projectId };
	}

	/**
	 * Clear all focus
	 */
	clear(): void {
		this.current = null;
	}

	/**
	 * Check if focused on a specific project
	 */
	isFocusedOn(projectId: string): boolean {
		return this.current?.projectId === projectId;
	}

	/**
	 * Get focused project ID
	 */
	getProjectId(): string | null {
		return this.current?.projectId || null;
	}

	/**
	 * Serialize focus state for persistence
	 */
	serialize(): string | null {
		if (!this.current) return null;
		return JSON.stringify(this.current);
	}

	/**
	 * Restore focus state from serialized form
	 */
	restore(serialized: string): boolean {
		try {
			const state = JSON.parse(serialized) as FocusState;
			if (state.projectId) {
				this.current = { projectId: state.projectId };
				return true;
			}
			return false;
		} catch {
			return false;
		}
	}
}
