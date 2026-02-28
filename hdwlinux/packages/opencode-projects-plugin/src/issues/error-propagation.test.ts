/**
 * Test error propagation from BeadsError to IssueStorageError
 */

import { describe, test, expect } from "bun:test"
import {
  BeadsNotAvailableError,
  BeadsCommandFailedError,
  BeadsParseError,
  BeadsTimeoutError,
} from "./beads/schemas.js"
import { mapBeadsError } from "./beads/error-mapper.js"
import {
  StorageNotAvailableError,
  StorageOperationError,
  StorageParseError,
  StorageTimeoutError,
} from "./issue-storage.js"

describe("Error Mapping", () => {
  test("maps BeadsNotAvailableError to StorageNotAvailableError", () => {
    const beadsError = new BeadsNotAvailableError("CLI not found")
    const storageError = mapBeadsError(beadsError)

    expect(storageError).toBeInstanceOf(StorageNotAvailableError)
    expect(storageError.message).toBe("CLI not found")
    expect(storageError.code).toBe("STORAGE_NOT_AVAILABLE")
  })

  test("maps BeadsCommandFailedError to StorageOperationError", () => {
    const beadsError = new BeadsCommandFailedError(
      "Command failed",
      "stderr output",
      1,
      "Try again"
    )
    const storageError = mapBeadsError(beadsError)

    expect(storageError).toBeInstanceOf(StorageOperationError)
    expect(storageError.code).toBe("STORAGE_OPERATION_FAILED")
    expect(storageError.recoverable).toBe(true)
  })

  test("distinguishes 'not initialized' from 'CLI not found'", () => {
    const notInitError = new BeadsCommandFailedError(
      "Failed",
      "No .beads directory found",
      1
    )
    const storageError = mapBeadsError(notInitError)

    expect(storageError).toBeInstanceOf(StorageOperationError)
    expect(storageError.message).toContain("not initialized")
    expect(storageError.suggestion).toContain("initialization")
  })

  test("maps BeadsParseError to StorageParseError", () => {
    const beadsError = new BeadsParseError("Invalid JSON")
    const storageError = mapBeadsError(beadsError)

    expect(storageError).toBeInstanceOf(StorageParseError)
    expect(storageError.code).toBe("STORAGE_PARSE_ERROR")
    expect(storageError.recoverable).toBe(false)
  })

  test("maps BeadsTimeoutError to StorageTimeoutError", () => {
    const beadsError = new BeadsTimeoutError("Timeout", 5000)
    const storageError = mapBeadsError(beadsError)

    expect(storageError).toBeInstanceOf(StorageTimeoutError)
    expect(storageError.code).toBe("STORAGE_TIMEOUT")
    expect(storageError.timeoutMs).toBe(5000)
  })

  test("storage errors have no beads references", () => {
    const beadsError = new BeadsCommandFailedError("Test", "stderr", 1)
    const storageError = mapBeadsError(beadsError)

    // Check that the error type name doesn't contain "beads"
    expect(storageError.name.toLowerCase()).not.toContain("beads")
    expect(storageError.code.toLowerCase()).not.toContain("beads")
  })
})
