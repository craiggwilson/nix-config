/**
 * Shell utilities for executing commands
 *
 * Provides a consistent interface for running shell commands across
 * different parts of the plugin (VCS adapters, issue storage, etc.)
 */

import type { BunShell } from "../opencode-sdk/index.js"

/**
 * Result of a shell command execution
 */
export interface ShellResult {
  exitCode: number
  stdout: string
  stderr: string
  timedOut?: boolean
}

/**
 * Default timeout for shell commands (30 seconds)
 */
export const DEFAULT_SHELL_TIMEOUT_MS = 30000

/**
 * Run a shell command and return the result.
 *
 * Uses Bun's shell with `nothrow()` to prevent exceptions on non-zero exit codes
 * and `quiet()` to suppress output.
 *
 * @param shell - The Bun shell instance
 * @param cmd - The command string to execute
 * @param timeoutMs - Optional timeout in milliseconds (default: 30000)
 * @returns ShellResult with exitCode, stdout, stderr, and timedOut flag
 */
export async function runShell(
  shell: BunShell,
  cmd: string,
  timeoutMs: number = DEFAULT_SHELL_TIMEOUT_MS
): Promise<ShellResult> {
  try {
    const controller = new AbortController()
    const timeoutId = setTimeout(() => controller.abort(), timeoutMs)

    try {
      const result = await shell`${{ raw: cmd }}`.nothrow().quiet()
      clearTimeout(timeoutId)
      return {
        exitCode: result.exitCode,
        stdout: result.stdout.toString(),
        stderr: result.stderr.toString(),
        timedOut: false,
      }
    } catch (error) {
      clearTimeout(timeoutId)
      if (error instanceof Error && error.name === "AbortError") {
        return {
          exitCode: 124,
          stdout: "",
          stderr: `Command timed out after ${timeoutMs}ms`,
          timedOut: true,
        }
      }
      throw error
    }
  } catch (error) {
    return {
      exitCode: 1,
      stdout: "",
      stderr: String(error),
      timedOut: false,
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
 * @param timeoutMs - Optional timeout in milliseconds (default: 30000)
 * @returns ShellResult with exitCode, stdout, stderr, and timedOut flag
 */
export async function runShellInDir(
  shell: BunShell,
  cmd: string,
  directory: string,
  timeoutMs: number = DEFAULT_SHELL_TIMEOUT_MS
): Promise<ShellResult> {
  const escapedDir = shell.escape(directory)
  const fullCmd = `cd ${escapedDir} && ${cmd}`
  return runShell(shell, fullCmd, timeoutMs)
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
export function buildCommand(shell: BunShell, command: string, args: string[]): string {
  const escapedArgs = args.map((arg) => shell.escape(arg))
  return [command, ...escapedArgs].join(" ")
}
