import { describe, it, expect } from "bun:test"
import { validateClient, validateClientOrThrow, ClientValidationError } from "./client-validator.js"
import type { OpencodeClient } from "../opencode-sdk/index.js"

describe("validateClient", () => {
  const createValidClient = (): OpencodeClient => ({
    app: {
      log: async () => ({}),
      agents: async () => ({ data: [] }),
    },
    session: {
      create: async () => ({ data: { id: "test", title: "Test" } }),
      get: async () => ({ data: { id: "test" } }),
      prompt: async () => ({ data: { id: "msg1", role: "assistant", sessionID: "test", parts: [] } }),
      messages: async () => ({ data: [] }),
      delete: async () => ({}),
    },
    config: {
      get: async () => ({ data: {} }),
    },
  })

  describe("valid client", () => {
    it("should validate a complete client", () => {
      const client = createValidClient()
      const result = validateClient(client)

      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(result.value).toBe(client)
      }
    })

    it("should not throw for valid client with validateClientOrThrow", () => {
      const client = createValidClient()
      expect(() => validateClientOrThrow(client)).not.toThrow()
    })
  })

  describe("invalid client - basic type checks", () => {
    it("should fail for null", () => {
      const result = validateClient(null)

      expect(result.ok).toBe(false)
      if (!result.ok) {
        expect(result.error).toBeInstanceOf(ClientValidationError)
        expect(result.error.message).toContain("must be an object")
      }
    })

    it("should fail for undefined", () => {
      const result = validateClient(undefined)

      expect(result.ok).toBe(false)
      if (!result.ok) {
        expect(result.error).toBeInstanceOf(ClientValidationError)
        expect(result.error.message).toContain("must be an object")
      }
    })

    it("should fail for primitive types", () => {
      const result = validateClient("not an object")

      expect(result.ok).toBe(false)
      if (!result.ok) {
        expect(result.error).toBeInstanceOf(ClientValidationError)
        expect(result.error.message).toContain("must be an object")
      }
    })

    it("should fail for empty object", () => {
      const result = validateClient({})

      expect(result.ok).toBe(false)
      if (!result.ok) {
        expect(result.error).toBeInstanceOf(ClientValidationError)
        expect(result.error.path).toBeDefined()
      }
    })
  })

  describe("invalid client - missing properties", () => {
    it("should fail when app is missing", () => {
      const client = createValidClient()
      // @ts-expect-error - intentionally creating invalid client
      delete client.app

      const result = validateClient(client)

      expect(result.ok).toBe(false)
      if (!result.ok) {
        expect(result.error).toBeInstanceOf(ClientValidationError)
        expect(result.error.message).toContain("app")
      }
    })

    it("should fail when session is missing", () => {
      const client = createValidClient()
      // @ts-expect-error - intentionally creating invalid client
      delete client.session

      const result = validateClient(client)

      expect(result.ok).toBe(false)
      if (!result.ok) {
        expect(result.error).toBeInstanceOf(ClientValidationError)
        expect(result.error.message).toContain("session")
      }
    })

    it("should fail when config is missing", () => {
      const client = createValidClient()
      // @ts-expect-error - intentionally creating invalid client
      delete client.config

      const result = validateClient(client)

      expect(result.ok).toBe(false)
      if (!result.ok) {
        expect(result.error).toBeInstanceOf(ClientValidationError)
        expect(result.error.message).toContain("config")
      }
    })

    it("should fail when app.log is missing", () => {
      const client = createValidClient()
      // @ts-expect-error - intentionally creating invalid client
      delete client.app.log

      const result = validateClient(client)

      expect(result.ok).toBe(false)
      if (!result.ok) {
        expect(result.error).toBeInstanceOf(ClientValidationError)
        expect(result.error.path).toContain("app.log")
      }
    })

    it("should fail when app.agents is missing", () => {
      const client = createValidClient()
      // @ts-expect-error - intentionally creating invalid client
      delete client.app.agents

      const result = validateClient(client)

      expect(result.ok).toBe(false)
      if (!result.ok) {
        expect(result.error).toBeInstanceOf(ClientValidationError)
        expect(result.error.path).toContain("app.agents")
      }
    })

    it("should fail when session.create is missing", () => {
      const client = createValidClient()
      // @ts-expect-error - intentionally creating invalid client
      delete client.session.create

      const result = validateClient(client)

      expect(result.ok).toBe(false)
      if (!result.ok) {
        expect(result.error).toBeInstanceOf(ClientValidationError)
        expect(result.error.path).toContain("session.create")
      }
    })

    it("should fail when session.prompt is missing", () => {
      const client = createValidClient()
      // @ts-expect-error - intentionally creating invalid client
      delete client.session.prompt

      const result = validateClient(client)

      expect(result.ok).toBe(false)
      if (!result.ok) {
        expect(result.error).toBeInstanceOf(ClientValidationError)
        expect(result.error.path).toContain("session.prompt")
      }
    })
  })

  describe("invalid client - wrong types", () => {
    it("should fail when app is not an object", () => {
      const client = createValidClient()
      // @ts-expect-error - intentionally creating invalid client
      client.app = "not an object"

      const result = validateClient(client)

      expect(result.ok).toBe(false)
      if (!result.ok) {
        expect(result.error).toBeInstanceOf(ClientValidationError)
        expect(result.error.path).toContain("app")
      }
    })

    it("should fail when app.log is not a function", () => {
      const client = createValidClient()
      // @ts-expect-error - intentionally creating invalid client
      client.app.log = "not a function"

      const result = validateClient(client)

      expect(result.ok).toBe(false)
      if (!result.ok) {
        expect(result.error).toBeInstanceOf(ClientValidationError)
        expect(result.error.path).toContain("app.log")
      }
    })

    it("should fail when session is not an object", () => {
      const client = createValidClient()
      // @ts-expect-error - intentionally creating invalid client
      client.session = 123

      const result = validateClient(client)

      expect(result.ok).toBe(false)
      if (!result.ok) {
        expect(result.error).toBeInstanceOf(ClientValidationError)
        expect(result.error.path).toContain("session")
      }
    })

    it("should fail when config.get is not a function", () => {
      const client = createValidClient()
      // @ts-expect-error - intentionally creating invalid client
      client.config.get = null

      const result = validateClient(client)

      expect(result.ok).toBe(false)
      if (!result.ok) {
        expect(result.error).toBeInstanceOf(ClientValidationError)
        expect(result.error.path).toContain("config.get")
      }
    })
  })

  describe("validateClientOrThrow", () => {
    it("should throw ClientValidationError for invalid client", () => {
      expect(() => validateClientOrThrow(null)).toThrow(ClientValidationError)
    })

    it("should throw with detailed error message", () => {
      try {
        validateClientOrThrow({})
      } catch (error) {
        expect(error).toBeInstanceOf(ClientValidationError)
        if (error instanceof ClientValidationError) {
          expect(error.message).toContain("validation failed")
          expect(error.path).toBeDefined()
        }
      }
    })

    it("should return validated client for valid input", () => {
      const client = createValidClient()
      const validated = validateClientOrThrow(client)
      expect(validated).toBe(client)
    })
  })

  describe("ClientValidationError", () => {
    it("should include path in error", () => {
      const error = new ClientValidationError("Test error", "app.log", "function")
      expect(error.path).toBe("app.log")
      expect(error.expected).toBe("function")
      expect(error.name).toBe("ClientValidationError")
    })

    it("should work without path and expected", () => {
      const error = new ClientValidationError("Test error")
      expect(error.path).toBeUndefined()
      expect(error.expected).toBeUndefined()
      expect(error.message).toBe("Test error")
    })
  })
})
