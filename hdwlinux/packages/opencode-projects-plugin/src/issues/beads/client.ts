/**
 * BeadsClient - Low-level beads CLI command execution
 *
 * SECURITY: All shell commands MUST use buildCommand() to escape arguments.
 * Never use string concatenation or manual quote escaping - this leaves the
 * code vulnerable to command injection via backticks, $(), and other shell
 * metacharacters. The buildCommand() function uses Bun's native shell.escape()
 * which properly handles all dangerous characters.
 */

import type { BunShell } from "../../utils/opencode-sdk/index.js";
import type { Result } from "../../utils/result/index.js";
import { ok, err } from "../../utils/result/index.js";
import type { ShellResult } from "../../utils/shell/index.js";
import {
	runShell,
	runShellInDir,
	buildCommand,
	DEFAULT_SHELL_TIMEOUT_MS,
} from "../../utils/shell/index.js";
import {
	type BeadsError,
	BeadsNotAvailableError,
	BeadsCommandFailedError,
	BeadsTimeoutError,
} from "./schemas.js";

/**
 * BeadsClient handles low-level beads CLI command execution
 */
export class BeadsClient {
	private $: BunShell | null = null;

	/**
	 * Set the shell to use for commands
	 */
	setShell($: BunShell): void {
		this.$ = $;
	}

	/**
	 * Get shell or throw if not set
	 */
	private getShell(): BunShell {
		if (!this.$) {
			throw new Error(
				"BeadsClient shell not initialized. Call setShell() first.",
			);
		}
		return this.$;
	}

	/**
	 * Check if beads CLI is available
	 */
	async isAvailable(): Promise<Result<boolean, BeadsError>> {
		try {
			const $ = this.getShell();
			const result = await $`which bd`.nothrow().quiet();
			if (result.exitCode === 0) {
				return ok(true);
			}
			return err(new BeadsNotAvailableError());
		} catch (error) {
			return err(
				new BeadsNotAvailableError("beads (bd) CLI not found in PATH", error),
			);
		}
	}

	/**
	 * Execute a beads command
	 */
	async execute(
		args: string[],
		repoPath?: string,
		timeoutMs: number = DEFAULT_SHELL_TIMEOUT_MS,
	): Promise<Result<ShellResult, BeadsError>> {
		try {
			const $ = this.getShell();

			// Use buildCommand to properly escape all arguments and prevent command injection
			const bdCmd = buildCommand(
				$,
				"bd",
				["--no-daemon", ...args].filter(Boolean) as string[],
			);

			const result = repoPath
				? await runShellInDir($, bdCmd, repoPath, { timeoutMs })
				: await runShell($, bdCmd, { timeoutMs });

			if (result.timedOut) {
				return err(
					new BeadsTimeoutError(
						`Command timed out after ${timeoutMs}ms: ${bdCmd}`,
						timeoutMs,
					),
				);
			}

			if (result.exitCode !== 0) {
				return err(
					new BeadsCommandFailedError(
						`Command failed with exit code ${result.exitCode}: ${bdCmd}`,
						result.stderr,
						result.exitCode,
					),
				);
			}

			return ok(result);
		} catch (error) {
			return err(
				new BeadsNotAvailableError(
					"BeadsClient shell not initialized. Call setShell() first.",
					error,
				),
			);
		}
	}
}
