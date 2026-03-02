/**
 * Tests for artifact context builder
 */

import { describe, test, expect, beforeEach, afterEach } from "bun:test"
import * as fs from "node:fs/promises"
import * as path from "node:path"
import * as os from "node:os"

import { ArtifactRegistry } from "../artifact-registry.js"
import { createMockLogger } from "../../utils/testing/index.js"
import {
  buildArtifactContext,
  formatArtifactContext,
  formatArtifactSummary,
  hasArtifactContext,
  type ArtifactContext,
} from "./artifact-context.js"

describe("artifact-context", () => {
  let testDir: string
  let artifactRegistry: ArtifactRegistry

  beforeEach(async () => {
    testDir = await fs.mkdtemp(path.join(os.tmpdir(), "artifact-context-test-"))
    artifactRegistry = new ArtifactRegistry(testDir, createMockLogger())
    await artifactRegistry.load()
  })

  afterEach(async () => {
    await fs.rm(testDir, { recursive: true, force: true })
  })

  describe("buildArtifactContext", () => {
    test("groups artifacts by type", async () => {
      await artifactRegistry.register({
        type: "research",
        title: "Auth Patterns",
        path: "research/auth.md",
        absolutePath: path.join(testDir, "research/auth.md"),
        external: false,
      })
      await artifactRegistry.register({
        type: "research",
        title: "Caching Strategies",
        path: "research/caching.md",
        absolutePath: path.join(testDir, "research/caching.md"),
        external: false,
      })
      await artifactRegistry.register({
        type: "decision",
        title: "Use OAuth2",
        path: "decisions/oauth2.md",
        absolutePath: path.join(testDir, "decisions/oauth2.md"),
        external: false,
      })

      const context = buildArtifactContext(artifactRegistry)

      expect(context.byType["research"]).toHaveLength(2)
      expect(context.byType["decision"]).toHaveLength(1)
    })

    test("sorts types alphabetically", async () => {
      await artifactRegistry.register({
        type: "research",
        title: "Research Doc",
        path: "research/doc.md",
        absolutePath: path.join(testDir, "research/doc.md"),
        external: false,
      })
      await artifactRegistry.register({
        type: "decision",
        title: "Decision Doc",
        path: "decisions/doc.md",
        absolutePath: path.join(testDir, "decisions/doc.md"),
        external: false,
      })
      await artifactRegistry.register({
        type: "deliverable",
        title: "Deliverable Doc",
        path: "deliverables/doc.md",
        absolutePath: path.join(testDir, "deliverables/doc.md"),
        external: false,
      })

      const context = buildArtifactContext(artifactRegistry)

      expect(context.types).toEqual(["decision", "deliverable", "research"])
    })

    test("sorts artifacts within type alphabetically by title", async () => {
      await artifactRegistry.register({
        type: "research",
        title: "Zebra Analysis",
        path: "research/zebra.md",
        absolutePath: path.join(testDir, "research/zebra.md"),
        external: false,
      })
      await artifactRegistry.register({
        type: "research",
        title: "Alpha Research",
        path: "research/alpha.md",
        absolutePath: path.join(testDir, "research/alpha.md"),
        external: false,
      })
      await artifactRegistry.register({
        type: "research",
        title: "Beta Study",
        path: "research/beta.md",
        absolutePath: path.join(testDir, "research/beta.md"),
        external: false,
      })

      const context = buildArtifactContext(artifactRegistry)

      expect(context.byType["research"][0].title).toBe("Alpha Research")
      expect(context.byType["research"][1].title).toBe("Beta Study")
      expect(context.byType["research"][2].title).toBe("Zebra Analysis")
    })

    test("returns correct count", async () => {
      await artifactRegistry.register({
        type: "research",
        title: "Doc 1",
        path: "doc1.md",
        absolutePath: path.join(testDir, "doc1.md"),
        external: false,
      })
      await artifactRegistry.register({
        type: "decision",
        title: "Doc 2",
        path: "doc2.md",
        absolutePath: path.join(testDir, "doc2.md"),
        external: false,
      })

      const context = buildArtifactContext(artifactRegistry)

      expect(context.count).toBe(2)
      expect(context.artifacts).toHaveLength(2)
    })

    test("returns empty context when no artifacts", () => {
      const context = buildArtifactContext(artifactRegistry)

      expect(context.artifacts).toEqual([])
      expect(context.byType).toEqual({})
      expect(context.types).toEqual([])
      expect(context.count).toBe(0)
    })
  })

  describe("formatArtifactContext", () => {
    test("produces valid markdown", () => {
      const context: ArtifactContext = {
        artifacts: [
          {
            id: "research-auth-abc123",
            type: "research",
            title: "Auth Patterns",
            path: "research/auth.md",
            absolutePath: "/project/research/auth.md",
            external: false,
            createdAt: "2026-03-02T10:00:00.000Z",
            summary: "Analysis of authentication patterns",
          },
        ],
        byType: {
          research: [
            {
              id: "research-auth-abc123",
              type: "research",
              title: "Auth Patterns",
              path: "research/auth.md",
              absolutePath: "/project/research/auth.md",
              external: false,
              createdAt: "2026-03-02T10:00:00.000Z",
              summary: "Analysis of authentication patterns",
            },
          ],
        },
        types: ["research"],
        count: 1,
      }

      const markdown = formatArtifactContext(context)

      expect(markdown).toContain("## Available Artifacts")
      expect(markdown).toContain("### Research")
      expect(markdown).toContain("**Auth Patterns**")
      expect(markdown).toContain("`research/auth.md`")
      expect(markdown).toContain("Analysis of authentication patterns")
    })

    test("marks external artifacts", () => {
      const context: ArtifactContext = {
        artifacts: [
          {
            id: "external-doc-abc123",
            type: "reference",
            title: "External Doc",
            path: "/external/doc.md",
            absolutePath: "/external/doc.md",
            external: true,
            createdAt: "2026-03-02T10:00:00.000Z",
          },
        ],
        byType: {
          reference: [
            {
              id: "external-doc-abc123",
              type: "reference",
              title: "External Doc",
              path: "/external/doc.md",
              absolutePath: "/external/doc.md",
              external: true,
              createdAt: "2026-03-02T10:00:00.000Z",
            },
          ],
        },
        types: ["reference"],
        count: 1,
      }

      const markdown = formatArtifactContext(context)

      expect(markdown).toContain("(external)")
    })

    test("returns empty string when no artifacts", () => {
      const context: ArtifactContext = {
        artifacts: [],
        byType: {},
        types: [],
        count: 0,
      }

      const markdown = formatArtifactContext(context)

      expect(markdown).toBe("")
    })

    test("formats multiple types correctly", () => {
      const context: ArtifactContext = {
        artifacts: [],
        byType: {
          decision: [
            {
              id: "decision-oauth-abc123",
              type: "decision",
              title: "Use OAuth2",
              path: "decisions/oauth.md",
              absolutePath: "/project/decisions/oauth.md",
              external: false,
              createdAt: "2026-03-02T10:00:00.000Z",
            },
          ],
          research: [
            {
              id: "research-auth-abc123",
              type: "research",
              title: "Auth Patterns",
              path: "research/auth.md",
              absolutePath: "/project/research/auth.md",
              external: false,
              createdAt: "2026-03-02T10:00:00.000Z",
            },
          ],
        },
        types: ["decision", "research"],
        count: 2,
      }

      const markdown = formatArtifactContext(context)

      expect(markdown).toContain("### Decision")
      expect(markdown).toContain("### Research")
      const decisionPos = markdown.indexOf("### Decision")
      const researchPos = markdown.indexOf("### Research")
      expect(decisionPos).toBeLessThan(researchPos)
    })
  })

  describe("formatArtifactSummary", () => {
    test("produces compact summary", () => {
      const context: ArtifactContext = {
        artifacts: [],
        byType: {
          research: [
            {
              id: "research-auth-abc123",
              type: "research",
              title: "Auth Patterns",
              path: "research/auth.md",
              absolutePath: "/project/research/auth.md",
              external: false,
              createdAt: "2026-03-02T10:00:00.000Z",
            },
            {
              id: "research-cache-abc123",
              type: "research",
              title: "Caching",
              path: "research/cache.md",
              absolutePath: "/project/research/cache.md",
              external: false,
              createdAt: "2026-03-02T10:00:00.000Z",
            },
          ],
          decision: [
            {
              id: "decision-oauth-abc123",
              type: "decision",
              title: "Use OAuth2",
              path: "decisions/oauth.md",
              absolutePath: "/project/decisions/oauth.md",
              external: false,
              createdAt: "2026-03-02T10:00:00.000Z",
            },
          ],
        },
        types: ["decision", "research"],
        count: 3,
      }

      const summary = formatArtifactSummary(context)

      expect(summary).toContain("**decision:** Use OAuth2")
      expect(summary).toContain("**research:** Auth Patterns, Caching")
    })

    test("returns message when no artifacts", () => {
      const context: ArtifactContext = {
        artifacts: [],
        byType: {},
        types: [],
        count: 0,
      }

      const summary = formatArtifactSummary(context)

      expect(summary).toBe("No artifacts registered.")
    })
  })

  describe("hasArtifactContext", () => {
    test("returns true when artifacts exist", () => {
      const context: ArtifactContext = {
        artifacts: [
          {
            id: "research-auth-abc123",
            type: "research",
            title: "Auth Patterns",
            path: "research/auth.md",
            absolutePath: "/project/research/auth.md",
            external: false,
            createdAt: "2026-03-02T10:00:00.000Z",
          },
        ],
        byType: {},
        types: [],
        count: 1,
      }

      expect(hasArtifactContext(context)).toBe(true)
    })

    test("returns false when empty", () => {
      const context: ArtifactContext = {
        artifacts: [],
        byType: {},
        types: [],
        count: 0,
      }

      expect(hasArtifactContext(context)).toBe(false)
    })
  })
})
