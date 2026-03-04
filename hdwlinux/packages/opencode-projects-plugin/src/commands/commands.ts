/**
 * Slash command configurations registered via the plugin's config hook.
 * Each command has a description shown in the UI and a template prompt
 * that is sent to the model when the command is invoked.
 */

/**
 * Command configuration shape expected by OpenCode's config.command field.
 */
export interface CommandConfig {
	/** Short description shown in the command palette. */
	description: string;
	/** Prompt template sent to the model; $ARGUMENTS is replaced with user input. */
	template: string;
}

/**
 * Lists all projects (local and global, active and completed) with their status.
 */
const PROJECTS_LIST_COMMAND: CommandConfig = {
	description: "List all projects and their status",
	template: `Use the project-list tool to show all projects (scope="all", status="all"). Display the results clearly, including project IDs, names, status, and issue counts.`,
};

/**
 * Focuses a specific project by ID or name.
 * $ARGUMENTS receives the project ID or name provided by the user.
 */
const PROJECTS_FOCUS_COMMAND: CommandConfig = {
	description: "Focus a specific project by ID or name",
	template: `Use the project-focus tool to focus on the project specified in the arguments: $ARGUMENTS

If no argument is provided, show the currently focused project using project-focus with no arguments.
If an argument is provided, use it as the projectId parameter to set focus.`,
};

/**
 * Explicitly saves the current project's session state.
 * Useful before ending a work session to ensure continuity.
 */
const PROJECTS_SAVE_SESSION_COMMAND: CommandConfig = {
	description: "Save the current project's session state",
	template: `Use the project-plan tool with action="save" to explicitly save the current project's session state.

If a project is currently focused, save that project's session. If no project is focused, ask the user which project to save.

This ensures session continuity and captures current progress, open questions, and next steps.`,
};

/**
 * All plugin slash commands keyed by their command name.
 * Registered via the plugin's config hook into opencodeConfig.command.
 */
export const OPENCODE_PROJECTS_COMMANDS: Record<string, CommandConfig> = {
	"projects-list": PROJECTS_LIST_COMMAND,
	"projects-focus": PROJECTS_FOCUS_COMMAND,
	"projects-save-session": PROJECTS_SAVE_SESSION_COMMAND,
};
