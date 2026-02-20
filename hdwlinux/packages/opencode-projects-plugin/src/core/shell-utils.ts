/**
 * Shell utilities for executing commands
 *
 * Provides a consistent interface for running shell commands across
 * different parts of the plugin (VCS adapters, issue storage, etc.)
 */

import type { BunShell } from "./types.js"

/**
 * Result of a shell command execution
 */
export interface ShellResult {
  exitCode: number
  stdout: string
  stderr: string
}

/**
 * Run a shell command and return the result.
 *
 * Uses Bun's shell with `nothrow()` to prevent exceptions on non-zero exit codes
 * and `quiet()` to suppress output.
 *
 * @param shell - The Bun shell instance
 * @param cmd - The command string to execute
 * @returns ShellResult with exitCode, stdout, and stderr
 */
export async function runShell(shell: BunShell, cmd: string): Promise<ShellResult> {
  try {
    const result = await shell`${{ raw: cmd }}`.nothrow().quiet()
    return {
      exitCode: result.exitCode,
      stdout: result.stdout.toString(),
      stderr: result.stderr.toString(),
    }
  } catch (error) {
    return {
      exitCode: 1,
      stdout: "",
      stderr: String(error),
    }
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
 * @returns ShellResult with exitCode, stdout, and stderr
 */
export async function runShellInDir(
  shell: BunShell,
  cmd: string,
  directory: string
): Promise<ShellResult> {
  const fullCmd = `cd ${JSON.stringify(directory)} && ${cmd}`
  return runShell(shell, fullCmd)
}
