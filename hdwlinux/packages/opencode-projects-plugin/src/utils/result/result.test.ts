import { describe, it, expect } from "bun:test"
import {
  ok,
  err,
  isOk,
  isErr,
  map,
  flatMap,
  mapErr,
  unwrap,
  unwrapOr,
  unwrapOrElse,
  match,
  all,
  tryCatch,
  tryCatchAsync,
  toPromise,
  fromPromise,
  tap,
  tapErr,
  orElse,
  firstOk,
  type Result,
  type BaseError,
} from "./result"

interface TestError extends BaseError {
  name: "TestError"
  message: string
  code: string
  recoverable: boolean
}

function createTestError(message: string, code = "TEST_ERROR"): TestError {
  return {
    name: "TestError",
    message,
    code,
    recoverable: true,
  }
}

describe("Result type", () => {
  describe("ok and err constructors", () => {
    it("should create successful result", () => {
      const result = ok(42)
      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(result.value).toBe(42)
      }
    })

    it("should create error result", () => {
      const error = createTestError("test error")
      const result = err(error)
      expect(result.ok).toBe(false)
      if (!result.ok) {
        expect(result.error).toBe(error)
      }
    })
  })

  describe("type guards", () => {
    it("isOk should narrow type to success", () => {
      const result: Result<number, TestError> = ok(42)
      if (isOk(result)) {
        expect(result.value).toBe(42)
      }
    })

    it("isErr should narrow type to error", () => {
      const error = createTestError("test")
      const result: Result<number, TestError> = err(error)
      if (isErr(result)) {
        expect(result.error).toBe(error)
      }
    })
  })

  describe("map", () => {
    it("should transform successful value", () => {
      const result = ok(5)
      const mapped = map(result, (x) => x * 2)
      expect(isOk(mapped)).toBe(true)
      if (isOk(mapped)) {
        expect(mapped.value).toBe(10)
      }
    })

    it("should pass through error", () => {
      const error = createTestError("test")
      const result: Result<number, TestError> = err(error)
      const mapped = map(result, (x) => x * 2)
      expect(isErr(mapped)).toBe(true)
      if (isErr(mapped)) {
        expect(mapped.error).toBe(error)
      }
    })
  })

  describe("flatMap", () => {
    it("should chain successful results", () => {
      const result = ok(5)
      const chained = flatMap(result, (x) => ok(x * 2))
      expect(isOk(chained)).toBe(true)
      if (isOk(chained)) {
        expect(chained.value).toBe(10)
      }
    })

    it("should short-circuit on first error", () => {
      const error = createTestError("first error")
      const result: Result<number, TestError> = err(error)
      const chained = flatMap(result, (x) => ok(x * 2))
      expect(isErr(chained)).toBe(true)
      if (isErr(chained)) {
        expect(chained.error).toBe(error)
      }
    })

    it("should propagate error from mapper", () => {
      const result = ok(5)
      const error = createTestError("mapper error")
      const chained = flatMap(result, () => err(error))
      expect(isErr(chained)).toBe(true)
      if (isErr(chained)) {
        expect(chained.error).toBe(error)
      }
    })
  })

  describe("mapErr", () => {
    it("should transform error", () => {
      const error = createTestError("original")
      const result: Result<number, TestError> = err(error)
      const mapped = mapErr(result, (e) => createTestError(`transformed: ${e.message}`))
      expect(isErr(mapped)).toBe(true)
      if (isErr(mapped)) {
        expect(mapped.error.message).toBe("transformed: original")
      }
    })

    it("should pass through success", () => {
      const result: Result<number, TestError> = ok(42)
      const mapped = mapErr(result, (e) => createTestError(`transformed: ${e.message}`))
      expect(isOk(mapped)).toBe(true)
      if (isOk(mapped)) {
        expect(mapped.value).toBe(42)
      }
    })
  })

  describe("unwrap", () => {
    it("should return value for success", () => {
      const result = ok(42)
      expect(unwrap(result)).toBe(42)
    })

    it("should throw for error", () => {
      const error = createTestError("test error")
      const result: Result<number, TestError> = err(error)
      expect(() => unwrap(result)).toThrow()
    })
  })

  describe("unwrapOr", () => {
    it("should return value for success", () => {
      const result = ok(42)
      expect(unwrapOr(result, 0)).toBe(42)
    })

    it("should return default for error", () => {
      const error = createTestError("test")
      const result: Result<number, TestError> = err(error)
      expect(unwrapOr(result, 0)).toBe(0)
    })
  })

  describe("unwrapOrElse", () => {
    it("should return value for success", () => {
      const result = ok(42)
      expect(unwrapOrElse(result, () => 0)).toBe(42)
    })

    it("should compute default for error", () => {
      const error = createTestError("test")
      const result: Result<number, TestError> = err(error)
      expect(unwrapOrElse(result, (e) => e.message.length)).toBe(4)
    })
  })

  describe("match", () => {
    it("should call ok handler for success", () => {
      const result: Result<number, TestError> = ok(42)
      const output = match(result, {
        ok: (v) => `success: ${v}`,
        err: (e) => `error: ${e.message}`,
      })
      expect(output).toBe("success: 42")
    })

    it("should call err handler for error", () => {
      const error = createTestError("test")
      const result: Result<number, TestError> = err(error)
      const output = match(result, {
        ok: (v) => `success: ${v}`,
        err: (e) => `error: ${e.message}`,
      })
      expect(output).toBe("error: test")
    })
  })

  describe("all", () => {
    it("should combine all successful results", () => {
      const results = [ok(1), ok(2), ok(3)]
      const combined = all(results)
      expect(isOk(combined)).toBe(true)
      if (isOk(combined)) {
        expect(combined.value).toEqual([1, 2, 3])
      }
    })

    it("should return first error", () => {
      const error1 = createTestError("error 1")
      const error2 = createTestError("error 2")
      const results: Result<number, TestError>[] = [ok(1), err(error1), err(error2)]
      const combined = all(results)
      expect(isErr(combined)).toBe(true)
      if (isErr(combined)) {
        expect(combined.error).toBe(error1)
      }
    })

    it("should handle empty array", () => {
      const results: Result<number, TestError>[] = []
      const combined = all(results)
      expect(isOk(combined)).toBe(true)
      if (isOk(combined)) {
        expect(combined.value).toEqual([])
      }
    })
  })

  describe("tryCatch", () => {
    it("should catch successful execution", () => {
      const result = tryCatch(
        () => 42,
        (e) => createTestError(String(e))
      )
      expect(isOk(result)).toBe(true)
      if (isOk(result)) {
        expect(result.value).toBe(42)
      }
    })

    it("should catch thrown errors", () => {
      const result = tryCatch(
        () => {
          throw new Error("boom")
        },
        (e) => createTestError(e instanceof Error ? e.message : String(e))
      )
      expect(isErr(result)).toBe(true)
      if (isErr(result)) {
        expect(result.error.message).toBe("boom")
      }
    })
  })

  describe("tryCatchAsync", () => {
    it("should catch successful async execution", async () => {
      const result = await tryCatchAsync(
        async () => 42,
        (e) => createTestError(String(e))
      )
      expect(isOk(result)).toBe(true)
      if (isOk(result)) {
        expect(result.value).toBe(42)
      }
    })

    it("should catch rejected promises", async () => {
      const result = await tryCatchAsync(
        async () => {
          throw new Error("boom")
        },
        (e) => createTestError(e instanceof Error ? e.message : String(e))
      )
      expect(isErr(result)).toBe(true)
      if (isErr(result)) {
        expect(result.error.message).toBe("boom")
      }
    })
  })

  describe("toPromise", () => {
    it("should resolve for success", async () => {
      const result = ok(42)
      await expect(toPromise(result)).resolves.toBe(42)
    })

    it("should reject for error", async () => {
      const error = createTestError("test")
      const result: Result<number, TestError> = err(error)
      await expect(toPromise(result)).rejects.toThrow("test")
    })
  })

  describe("fromPromise", () => {
    it("should convert resolved promise to ok", async () => {
      const result = await fromPromise(Promise.resolve(42), (e) => createTestError(String(e)))
      expect(isOk(result)).toBe(true)
      if (isOk(result)) {
        expect(result.value).toBe(42)
      }
    })

    it("should convert rejected promise to err", async () => {
      const result = await fromPromise(
        Promise.reject(new Error("boom")),
        (e) => createTestError(e instanceof Error ? e.message : String(e))
      )
      expect(isErr(result)).toBe(true)
      if (isErr(result)) {
        expect(result.error.message).toBe("boom")
      }
    })
  })

  describe("tap", () => {
    it("should execute side effect for success", () => {
      let sideEffect = 0
      const result = ok(42)
      const tapped = tap(result, (v) => {
        sideEffect = v
      })
      expect(sideEffect).toBe(42)
      expect(tapped).toBe(result)
    })

    it("should not execute side effect for error", () => {
      let sideEffect = 0
      const error = createTestError("test")
      const result: Result<number, TestError> = err(error)
      const tapped = tap(result, (v) => {
        sideEffect = v
      })
      expect(sideEffect).toBe(0)
      expect(tapped).toBe(result)
    })
  })

  describe("tapErr", () => {
    it("should execute side effect for error", () => {
      let sideEffect = ""
      const error = createTestError("test")
      const result: Result<number, TestError> = err(error)
      const tapped = tapErr(result, (e) => {
        sideEffect = e.message
      })
      expect(sideEffect).toBe("test")
      expect(tapped).toBe(result)
    })

    it("should not execute side effect for success", () => {
      let sideEffect = ""
      const result: Result<number, TestError> = ok(42)
      const tapped = tapErr(result, (e) => {
        sideEffect = e.message
      })
      expect(sideEffect).toBe("")
      expect(tapped).toBe(result)
    })
  })

  describe("orElse", () => {
    it("should return original for success", () => {
      const result = ok(42)
      const fallback = orElse(result, () => ok(0))
      expect(isOk(fallback)).toBe(true)
      if (isOk(fallback)) {
        expect(fallback.value).toBe(42)
      }
    })

    it("should compute fallback for error", () => {
      const error = createTestError("test")
      const result: Result<number, TestError> = err(error)
      const fallback = orElse(result, () => ok(0))
      expect(isOk(fallback)).toBe(true)
      if (isOk(fallback)) {
        expect(fallback.value).toBe(0)
      }
    })
  })

  describe("firstOk", () => {
    it("should return first success", () => {
      const error1 = createTestError("error 1")
      const error2 = createTestError("error 2")
      const results: Result<number, TestError>[] = [err(error1), ok(42), err(error2)]
      const first = firstOk(results)
      expect(isOk(first)).toBe(true)
      if (isOk(first)) {
        expect(first.value).toBe(42)
      }
    })

    it("should return last error if all fail", () => {
      const error1 = createTestError("error 1")
      const error2 = createTestError("error 2")
      const results: Result<number, TestError>[] = [err(error1), err(error2)]
      const first = firstOk(results)
      expect(isErr(first)).toBe(true)
      if (isErr(first)) {
        expect(first.error).toBe(error2)
      }
    })

    it("should throw for empty array", () => {
      const results: Result<number, TestError>[] = []
      expect(() => firstOk(results)).toThrow("firstOk called with empty array")
    })
  })
})
