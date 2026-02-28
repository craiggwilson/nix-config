/**
 * Tests for BeadsClient
 */

import { describe, test, expect, beforeEach } from "bun:test"
import { BeadsClient } from "./client.js"
import type { BunShell } from "../../utils/opencode-sdk/index.js"

describe("BeadsClient", () => {
  let client: BeadsClient
  let mockShell: BunShell

  beforeEach(() => {
    client = new BeadsClient()
    mockShell = {
      escape: (str: string) => `'${str}'`,
    } as unknown as BunShell
    client.setShell(mockShell)
  })

  describe("setShell", () => {
    test("sets shell instance", () => {
      const newClient = new BeadsClient()
      expect(() => newClient.setShell(mockShell)).not.toThrow()
    })
  })

  describe("isAvailable", () => {
    test("returns ok(true) when bd is available", async () => {
      const shell = Object.assign(
        (...args: unknown[]) => {
          return {
            nothrow: () => ({
              quiet: async () => ({ exitCode: 0 }),
            }),
          }
        },
        { escape: (str: string) => `'${str}'` }
      ) as unknown as BunShell

      client.setShell(shell)
      const result = await client.isAvailable()

      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(result.value).toBe(true)
      }
    })

    test("returns error when bd is not available", async () => {
      const shell = Object.assign(
        (...args: unknown[]) => {
          return {
            nothrow: () => ({
              quiet: async () => ({ exitCode: 1 }),
            }),
          }
        },
        { escape: (str: string) => `'${str}'` }
      ) as unknown as BunShell

      client.setShell(shell)
      const result = await client.isAvailable()

      expect(result.ok).toBe(false)
      if (!result.ok) {
        expect(result.error.name).toBe("BeadsNotAvailableError")
      }
    })
  })

  describe("execute", () => {
    test("returns error when shell not initialized", async () => {
      const newClient = new BeadsClient()
      const result = await newClient.execute(["list"])
      
      expect(result.ok).toBe(false)
      if (!result.ok) {
        expect(result.error.name).toBe("BeadsNotAvailableError")
        expect(result.error.message).toContain("BeadsClient shell not initialized")
      }
    })
  })
})
