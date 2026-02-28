/**
 * Maps beads-specific errors to storage-agnostic errors
 */

import type { Result } from "../../utils/result/index.js"
import { mapErr } from "../../utils/result/index.js"
import type {
  IssueStorageError,
} from "../issue-storage.js"
import {
  StorageNotAvailableError,
  StorageOperationError,
  StorageParseError,
  StorageTimeoutError,
} from "../issue-storage.js"
import type { BeadsError } from "./schemas.js"
import {
  BeadsNotAvailableError,
  BeadsCommandFailedError,
  BeadsParseError,
  BeadsTimeoutError,
} from "./schemas.js"

/**
 * Map a BeadsError to a storage-agnostic IssueStorageError
 */
export function mapBeadsError(error: BeadsError): IssueStorageError {
  if (error instanceof BeadsNotAvailableError) {
    return new StorageNotAvailableError(
      error.message,
      error.suggestion,
      error
    )
  }

  if (error instanceof BeadsCommandFailedError) {
    const message = error.stderr.trim() || error.message
    
    // Distinguish between "shell not initialized" and "CLI not found"
    let enhancedMessage = message
    let suggestion = error.suggestion
    
    if (message.includes("not initialized") || message.includes("No .beads directory")) {
      enhancedMessage = "Issue storage not initialized in this directory"
      suggestion = "Run initialization first or check the project directory"
    } else if (message.includes("command not found") || message.includes("not found in PATH")) {
      enhancedMessage = "Issue tracking CLI not found in PATH"
      suggestion = "Install the issue tracking CLI"
    }
    
    return new StorageOperationError(
      enhancedMessage,
      suggestion,
      error
    )
  }

  if (error instanceof BeadsParseError) {
    return new StorageParseError(
      error.message,
      error
    )
  }

  if (error instanceof BeadsTimeoutError) {
    return new StorageTimeoutError(
      error.message,
      error.timeoutMs,
      error
    )
  }

  // Fallback for unknown error types
  return new StorageOperationError(
    error.message,
    error.suggestion,
    error
  )
}

/**
 * Map a Result<T, BeadsError> to Result<T, IssueStorageError>
 */
export function mapBeadsResult<T>(result: Result<T, BeadsError>): Result<T, IssueStorageError> {
  return mapErr(result, mapBeadsError)
}
