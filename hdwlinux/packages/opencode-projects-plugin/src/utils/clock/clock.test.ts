/**
 * Tests for Clock abstraction
 */

import { describe, test, expect } from "bun:test"
import { SystemClock, MockClock } from "./clock.js"

describe("SystemClock", () => {
  test("now() returns current timestamp", () => {
    const clock = new SystemClock()
    const before = Date.now()
    const result = clock.now()
    const after = Date.now()

    expect(result).toBeGreaterThanOrEqual(before)
    expect(result).toBeLessThanOrEqual(after)
  })

  test("toISOString() returns valid ISO string", () => {
    const clock = new SystemClock()
    const result = clock.toISOString()

    expect(result).toMatch(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}.\d{3}Z$/)
  })

  test("setTimeout schedules callback", async () => {
    const clock = new SystemClock()
    let called = false

    clock.setTimeout(() => {
      called = true
    }, 10)

    await clock.sleep(20)
    expect(called).toBe(true)
  })

  test("clearTimeout cancels callback", async () => {
    const clock = new SystemClock()
    let called = false

    const handle = clock.setTimeout(() => {
      called = true
    }, 10)

    clock.clearTimeout(handle)
    await clock.sleep(20)
    expect(called).toBe(false)
  })

  test("sleep resolves after delay", async () => {
    const clock = new SystemClock()
    const start = Date.now()

    await clock.sleep(50)

    const elapsed = Date.now() - start
    expect(elapsed).toBeGreaterThanOrEqual(45)
  })
})

describe("MockClock", () => {
  describe("now()", () => {
    test("returns initial time", () => {
      const clock = new MockClock(1000)
      expect(clock.now()).toBe(1000)
    })

    test("defaults to 0", () => {
      const clock = new MockClock()
      expect(clock.now()).toBe(0)
    })
  })

  describe("toISOString()", () => {
    test("returns ISO string for current time", () => {
      const clock = new MockClock(1705320000000)
      expect(clock.toISOString()).toBe("2024-01-15T12:00:00.000Z")
    })
  })

  describe("advance()", () => {
    test("advances time", () => {
      const clock = new MockClock(1000)
      clock.advance(500)
      expect(clock.now()).toBe(1500)
    })

    test("executes scheduled callbacks when deadline passes", () => {
      const clock = new MockClock(0)
      let called = false

      clock.setTimeout(() => {
        called = true
      }, 100)

      expect(called).toBe(false)
      clock.advance(50)
      expect(called).toBe(false)
      clock.advance(50)
      expect(called).toBe(true)
    })

    test("executes callbacks in deadline order", () => {
      const clock = new MockClock(0)
      const executed: number[] = []

      clock.setTimeout(() => executed.push(1), 100)
      clock.setTimeout(() => executed.push(2), 50)
      clock.setTimeout(() => executed.push(3), 150)

      clock.advance(200)

      expect(executed).toEqual([2, 1, 3])
    })
  })

  describe("setTime()", () => {
    test("sets time to specific value", () => {
      const clock = new MockClock(1000)
      clock.setTime(5000)
      expect(clock.now()).toBe(5000)
    })

    test("executes callbacks when time passes deadline", () => {
      const clock = new MockClock(0)
      let called = false

      clock.setTimeout(() => {
        called = true
      }, 100)

      clock.setTime(100)
      expect(called).toBe(true)
    })
  })

  describe("clearTimeout()", () => {
    test("cancels scheduled callback", () => {
      const clock = new MockClock(0)
      let called = false

      const handle = clock.setTimeout(() => {
        called = true
      }, 100)

      clock.clearTimeout(handle)
      clock.advance(200)

      expect(called).toBe(false)
    })
  })

  describe("sleep()", () => {
    test("resolves when time advances past deadline", async () => {
      const clock = new MockClock(0)
      let resolved = false

      const promise = clock.sleep(100).then(() => {
        resolved = true
      })

      expect(resolved).toBe(false)
      clock.advance(100)
      await promise
      expect(resolved).toBe(true)
    })
  })

  describe("getPendingCount()", () => {
    test("returns number of pending callbacks", () => {
      const clock = new MockClock(0)

      expect(clock.getPendingCount()).toBe(0)

      clock.setTimeout(() => {}, 100)
      expect(clock.getPendingCount()).toBe(1)

      clock.setTimeout(() => {}, 200)
      expect(clock.getPendingCount()).toBe(2)

      clock.advance(150)
      expect(clock.getPendingCount()).toBe(1)
    })
  })

  describe("reset()", () => {
    test("clears all state", () => {
      const clock = new MockClock(1000)
      clock.setTimeout(() => {}, 100)

      clock.reset(0)

      expect(clock.now()).toBe(0)
      expect(clock.getPendingCount()).toBe(0)
    })
  })
})
