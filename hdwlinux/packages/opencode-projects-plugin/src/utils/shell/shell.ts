/**
 * Shell utilities for executing commands
 *
 * Provides a consistent interface for running shell commands across
 * different parts of the plugin (VCS adapters, issue storage, etc.)
 */

import type { BunShell } from "../opencode-sdk/index.js";
import type { Clock } from "../clock/index.js";
import { systemClock } from "../clock/index.js";

/**
 * Result of a shell command execution
 */
export interface ShellResult {
	exitCode: number;
	stdout: string;
	stderr: string;
	timedOut?: boolean;
}

/**
 * Default timeout for shell commands (30 seconds)
 */
export const DEFAULT_SHELL_TIMEOUT_MS = 30000;

/**
 * Options for running a shell command
 */
export interface RunShellOptions {
	/** Timeout in milliseconds (default: 30000) */
	timeoutMs?: number;
	/** Clock for timing operations (optional, uses system clock) */
	clock?: Clock;
}

/**
 * Run a shell command and return the result.
 *
 * Uses Bun's shell with `nothrow()` to prevent exceptions on non-zero exit codes
 * and `quiet()` to suppress output.
 *
 * @param shell - The Bun shell instance
 * @param cmd - The command string to execute
 * @param options - Optional configuration including timeout and clock
 * @returns ShellResult with exitCode, stdout, stderr, and timedOut flag
 */
export async function runShell(
	shell: BunShell,
	cmd: string,
	options: RunShellOptions = {},
): Promise<ShellResult> {
	const { timeoutMs = DEFAULT_SHELL_TIMEOUT_MS, clock = systemClock } = options;

	try {
		const controller = new AbortController();
		const timeoutId = clock.setTimeout(() => controller.abort(), timeoutMs);

		try {
			const result = await shell`${{ raw: cmd }}`.nothrow().quiet();
			clock.clearTimeout(timeoutId);
			return {
				exitCode: result.exitCode,
				stdout: result.stdout.toString(),
				stderr: result.stderr.toString(),
				timedOut: false,
			};
		} catch (error) {
			clock.clearTimeout(timeoutId);
			if (error instanceof Error && error.name === "AbortError") {
				return {
					exitCode: 124,
					stdout: "",
					stderr: `Command timed out after ${timeoutMs}ms`,
					timedOut: true,
				};
			}
			throw error;
		}
	} catch (error) {
		return {
			exitCode: 1,
			stdout: "",
			stderr: String(error),
			timedOut: false,
		};
	}
}

/**
 * Run a shell command in a specific directory.
 *
 * Wraps the command with `cd <directory> && <command>`.
 *
 * @param shell - The Bun shell instance
 * @param cmd - The command string to execute
 * @param directory - The directory to run the command in
 * @param options - Optional configuration including timeout and clock
 * @returns ShellResult with exitCode, stdout, stderr, and timedOut flag
 */
export async function runShellInDir(
	shell: BunShell,
	cmd: string,
	directory: string,
	options: RunShellOptions = {},
): Promise<ShellResult> {
	const escapedDir = shell.escape(directory);
	const fullCmd = `cd ${escapedDir} && ${cmd}`;
	return runShell(shell, fullCmd, options);
}

/**
 * Build a shell command with properly escaped arguments.
 *
 * Uses Bun's native shell escaping to prevent command injection.
 *
 * @param shell - The Bun shell instance
 * @param command - The base command (e.g., "bd")
 * @param args - Array of arguments to escape and append
 * @returns Safely constructed command string
 */
export function buildCommand(
	shell: BunShell,
	command: string,
	args: string[],
): string {
	const escapedArgs = args.map((arg) => shell.escape(arg));
	return [command, ...escapedArgs].join(" ");
}
