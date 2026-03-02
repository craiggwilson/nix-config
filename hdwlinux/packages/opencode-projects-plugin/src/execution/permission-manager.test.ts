/**
 * Tests for PermissionManager
 */

import { describe, test, expect } from "bun:test"

import { PermissionManager } from "./permission-manager.js"
import type { TeamMemberRole } from "./delegation-manager.js"

describe("PermissionManager", () => {
  describe("resolvePermissions", () => {
    describe("primary role", () => {
      test("should allow write tools for primary role", () => {
        const permissions = PermissionManager.resolvePermissions("primary")

        // Primary should NOT have write tools disabled
        expect(permissions["edit"]).toBeUndefined()
        expect(permissions["write"]).toBeUndefined()
      })

      test("should disable delegation and state modification tools", () => {
        const permissions = PermissionManager.resolvePermissions("primary")

        // All roles should have these disabled
        expect(permissions["task"]).toBe(false)
        expect(permissions["delegate"]).toBe(false)
        expect(permissions["todowrite"]).toBe(false)
        expect(permissions["question"]).toBe(false)
        expect(permissions["project-create"]).toBe(false)
        expect(permissions["project-close"]).toBe(false)
        expect(permissions["project-create-issue"]).toBe(false)
        expect(permissions["project-update-issue"]).toBe(false)
        expect(permissions["project-work-on-issue"]).toBe(false)
      })
    })

    describe("secondary role", () => {
      test("should disable write tools for secondary role", () => {
        const permissions = PermissionManager.resolvePermissions("secondary")

        expect(permissions["edit"]).toBe(false)
        expect(permissions["write"]).toBe(false)
      })

      test("should disable delegation and state modification tools", () => {
        const permissions = PermissionManager.resolvePermissions("secondary")

        expect(permissions["task"]).toBe(false)
        expect(permissions["delegate"]).toBe(false)
        expect(permissions["todowrite"]).toBe(false)
        expect(permissions["question"]).toBe(false)
        expect(permissions["project-create"]).toBe(false)
        expect(permissions["project-close"]).toBe(false)
        expect(permissions["project-create-issue"]).toBe(false)
        expect(permissions["project-update-issue"]).toBe(false)
        expect(permissions["project-work-on-issue"]).toBe(false)
      })
    })

    describe("devilsAdvocate role", () => {
      test("should disable write tools for devilsAdvocate role", () => {
        const permissions = PermissionManager.resolvePermissions("devilsAdvocate")

        expect(permissions["edit"]).toBe(false)
        expect(permissions["write"]).toBe(false)
      })

      test("should have same permissions as secondary role", () => {
        const secondaryPermissions = PermissionManager.resolvePermissions("secondary")
        const devilsAdvocatePermissions = PermissionManager.resolvePermissions("devilsAdvocate")

        expect(devilsAdvocatePermissions).toEqual(secondaryPermissions)
      })

      test("should disable delegation and state modification tools", () => {
        const permissions = PermissionManager.resolvePermissions("devilsAdvocate")

        expect(permissions["task"]).toBe(false)
        expect(permissions["delegate"]).toBe(false)
        expect(permissions["todowrite"]).toBe(false)
        expect(permissions["question"]).toBe(false)
        expect(permissions["project-create"]).toBe(false)
        expect(permissions["project-close"]).toBe(false)
        expect(permissions["project-create-issue"]).toBe(false)
        expect(permissions["project-update-issue"]).toBe(false)
        expect(permissions["project-work-on-issue"]).toBe(false)
      })
    })

    describe("all roles", () => {
      const roles: TeamMemberRole[] = ["primary", "secondary", "devilsAdvocate"]

      test("should disable all always-disabled tools for all roles", () => {
        const alwaysDisabled = PermissionManager.getAlwaysDisabledTools()

        for (const role of roles) {
          const permissions = PermissionManager.resolvePermissions(role)

          for (const tool of alwaysDisabled) {
            expect(permissions[tool]).toBe(false)
          }
        }
      })
    })
  })

  describe("getAlwaysDisabledTools", () => {
    test("should return expected tools", () => {
      const tools = PermissionManager.getAlwaysDisabledTools()

      expect(tools).toContain("task")
      expect(tools).toContain("delegate")
      expect(tools).toContain("todowrite")
      expect(tools).toContain("question")
      expect(tools).toContain("project-create")
      expect(tools).toContain("project-close")
      expect(tools).toContain("project-create-issue")
      expect(tools).toContain("project-update-issue")
      expect(tools).toContain("project-work-on-issue")
    })

    test("should return immutable array", () => {
      const tools1 = PermissionManager.getAlwaysDisabledTools()
      const tools2 = PermissionManager.getAlwaysDisabledTools()

      expect(tools1).toEqual(tools2)
    })
  })

  describe("getWriteTools", () => {
    test("should return edit and write tools", () => {
      const tools = PermissionManager.getWriteTools()

      expect(tools).toContain("edit")
      expect(tools).toContain("write")
      expect(tools.length).toBe(2)
    })
  })

  describe("hasWriteAccess", () => {
    test("should return true for primary role", () => {
      expect(PermissionManager.hasWriteAccess("primary")).toBe(true)
    })

    test("should return false for secondary role", () => {
      expect(PermissionManager.hasWriteAccess("secondary")).toBe(false)
    })

    test("should return false for devilsAdvocate role", () => {
      expect(PermissionManager.hasWriteAccess("devilsAdvocate")).toBe(false)
    })
  })
})
