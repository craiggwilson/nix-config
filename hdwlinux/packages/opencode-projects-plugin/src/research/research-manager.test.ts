/**
 * Tests for ResearchManager
 */

import { describe, test, expect, beforeEach, afterEach } from "bun:test"
import * as fs from "node:fs/promises"
import * as path from "node:path"
import * as os from "node:os"

import { ResearchManager, type ResearchIndex, type ResearchEntry } from "./research-manager.js"
import { ArtifactRegistry } from "../artifacts/index.js"
import { createMockLogger } from "../utils/testing/index.js"

describe("ResearchManager", () => {
  let testDir: string
  let artifactRegistry: ArtifactRegistry
  let manager: ResearchManager

  beforeEach(async () => {
    testDir = await fs.mkdtemp(path.join(os.tmpdir(), "research-manager-test-"))
    artifactRegistry = new ArtifactRegistry(testDir, createMockLogger())
    await artifactRegistry.load()
    manager = new ResearchManager(testDir, artifactRegistry, createMockLogger())
  })

  afterEach(async () => {
    await fs.rm(testDir, { recursive: true, force: true })
  })

  describe("load", () => {
    test("creates empty index if directory doesn't exist", async () => {
      const index = await manager.load()

      expect(index.entries).toEqual([])
    })

    test("loads existing index from file", async () => {
      const researchDir = path.join(testDir, "research")
      await fs.mkdir(researchDir, { recursive: true })

      const existingIndex = `# Research Index

## Summary

| Title | Summary | Source |
|-------|---------|--------|
| [Authentication Patterns](./authentication-patterns.md) | Analysis of OAuth2 and SAML | proj-123.1 |

---

## Authentication Patterns

**Source Issue:** proj-123.1
**Created:** 2026-03-01

Analysis of OAuth2 and SAML

**Key Findings:**
- OAuth2 with PKCE is best for SPAs
- SAML still required for enterprise SSO

**Full Document:** [authentication-patterns.md](./authentication-patterns.md)

---

`
      await fs.writeFile(path.join(researchDir, "index.md"), existingIndex)

      const index = await manager.load()

      expect(index.entries).toHaveLength(1)
      expect(index.entries[0].title).toBe("Authentication Patterns")
      expect(index.entries[0].summary).toBe("Analysis of OAuth2 and SAML")
      expect(index.entries[0].sourceIssue).toBe("proj-123.1")
      expect(index.entries[0].keyFindings).toEqual([
        "OAuth2 with PKCE is best for SPAs",
        "SAML still required for enterprise SSO",
      ])
    })

    test("creates research directory on first use", async () => {
      await manager.load()

      await manager.createResearch({
        title: "Test Research",
        content: "# Test Research\n\nContent here.",
        summary: "Test summary",
      })

      const researchDir = path.join(testDir, "research")
      const stat = await fs.stat(researchDir)
      expect(stat.isDirectory()).toBe(true)
    })

    test("uses custom researchPath when provided", async () => {
      const customPath = path.join(testDir, "custom-research")
      const customManager = new ResearchManager(
        testDir,
        artifactRegistry,
        createMockLogger(),
        customPath
      )
      await customManager.load()

      await customManager.createResearch({
        title: "Custom Path Research",
        content: "# Custom Path Research\n\nContent here.",
        summary: "Custom path summary",
      })

      const stat = await fs.stat(customPath)
      expect(stat.isDirectory()).toBe(true)

      const files = await fs.readdir(customPath)
      expect(files).toContain("custom-path-research.md")
    })
  })

  describe("createResearch", () => {
    beforeEach(async () => {
      await manager.load()
    })

    test("creates research with all fields", async () => {
      const result = await manager.createResearch({
        title: "Authentication Patterns",
        content: "# Authentication Patterns\n\nDetailed analysis...",
        summary: "Analysis of OAuth2, SAML, and OIDC for enterprise SSO",
        keyFindings: [
          "OAuth2 with PKCE is best for SPAs",
          "SAML still required for enterprise SSO",
        ],
        sourceIssue: "proj-abc123.1",
        sourceSession: "ses_xyz789",
      })

      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(result.value.title).toBe("Authentication Patterns")
        expect(result.value.summary).toBe("Analysis of OAuth2, SAML, and OIDC for enterprise SSO")
        expect(result.value.keyFindings).toEqual([
          "OAuth2 with PKCE is best for SPAs",
          "SAML still required for enterprise SSO",
        ])
        expect(result.value.sourceIssue).toBe("proj-abc123.1")
        expect(result.value.sourceSession).toBe("ses_xyz789")
        expect(result.value.id).toMatch(/^research-/)
        expect(result.value.createdAt).toBeDefined()
      }
    })

    test("generates correct filename from title slug", async () => {
      const result = await manager.createResearch({
        title: "OAuth2 with PKCE",
        content: "# OAuth2 with PKCE\n\nContent here.",
        summary: "OAuth2 analysis",
      })

      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(result.value.path).toContain("oauth2-with-pkce.md")
      }
    })

    test("writes research file with content", async () => {
      const content = "# Test Research\n\nThis is the research content."
      const result = await manager.createResearch({
        title: "Test Research",
        content,
        summary: "Test summary",
      })

      expect(result.ok).toBe(true)
      if (!result.ok) return

      const filePath = result.value.absolutePath
      const fileContent = await fs.readFile(filePath, "utf-8")
      expect(fileContent).toBe(content)
    })

    test("registers artifact in registry", async () => {
      const result = await manager.createResearch({
        title: "Artifact Test Research",
        content: "# Artifact Test\n\nContent here.",
        summary: "Test summary",
      })

      expect(result.ok).toBe(true)
      if (!result.ok) return

      const artifact = artifactRegistry.getById(result.value.id)
      expect(artifact).not.toBeNull()
      expect(artifact?.type).toBe("research")
      expect(artifact?.title).toBe("Artifact Test Research")
    })

    test("updates index with entry", async () => {
      await manager.createResearch({
        title: "Index Test Research",
        content: "# Index Test\n\nContent here.",
        summary: "Index test summary",
      })

      const entries = manager.list()
      expect(entries).toHaveLength(1)
      expect(entries[0].title).toBe("Index Test Research")
    })

    test("handles custom filename", async () => {
      const result = await manager.createResearch({
        title: "Custom Filename Research",
        content: "# Custom Filename\n\nContent here.",
        summary: "Custom filename summary",
        filename: "my-custom-filename",
      })

      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(result.value.path).toContain("my-custom-filename.md")
      }
    })

    test("returns error for duplicate title", async () => {
      await manager.createResearch({
        title: "Duplicate Title",
        content: "# First\n\nContent.",
        summary: "First summary",
      })

      const result = await manager.createResearch({
        title: "Duplicate Title",
        content: "# Second\n\nContent.",
        summary: "Second summary",
      })

      expect(result.ok).toBe(false)
      if (!result.ok && result.error.type === "already_exists") {
        expect(result.error.title).toBe("Duplicate Title")
      }
    })

    test("returns error for duplicate title case-insensitive", async () => {
      await manager.createResearch({
        title: "Case Test",
        content: "# First\n\nContent.",
        summary: "First summary",
      })

      const result = await manager.createResearch({
        title: "CASE TEST",
        content: "# Second\n\nContent.",
        summary: "Second summary",
      })

      expect(result.ok).toBe(false)
      if (!result.ok) {
        expect(result.error.type).toBe("already_exists")
      }
    })

    test("sorts entries alphabetically by title", async () => {
      await manager.createResearch({
        title: "Zebra Research",
        content: "# Zebra\n\nContent.",
        summary: "Z summary",
      })

      await manager.createResearch({
        title: "Alpha Research",
        content: "# Alpha\n\nContent.",
        summary: "A summary",
      })

      await manager.createResearch({
        title: "Middle Research",
        content: "# Middle\n\nContent.",
        summary: "M summary",
      })

      const entries = manager.list()
      expect(entries[0].title).toBe("Alpha Research")
      expect(entries[1].title).toBe("Middle Research")
      expect(entries[2].title).toBe("Zebra Research")
    })
  })

  describe("updateResearch", () => {
    let researchId: string

    beforeEach(async () => {
      await manager.load()
      const result = await manager.createResearch({
        title: "Update Test Research",
        content: "# Update Test\n\nContent here.",
        summary: "Original summary",
        keyFindings: ["Original finding"],
      })
      if (result.ok) {
        researchId = result.value.id
      }
    })

    test("updates summary", async () => {
      const result = await manager.updateResearch(researchId, {
        summary: "Updated summary",
      })

      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(result.value.summary).toBe("Updated summary")
      }
    })

    test("updates key findings", async () => {
      const result = await manager.updateResearch(researchId, {
        keyFindings: ["New finding 1", "New finding 2"],
      })

      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(result.value.keyFindings).toEqual(["New finding 1", "New finding 2"])
      }
    })

    test("returns error for non-existent research", async () => {
      const result = await manager.updateResearch("non-existent-id", {
        summary: "Updated summary",
      })

      expect(result.ok).toBe(false)
      if (!result.ok && result.error.type === "not_found") {
        expect(result.error.id).toBe("non-existent-id")
      }
    })

    test("updates both summary and keyFindings together", async () => {
      const result = await manager.updateResearch(researchId, {
        summary: "Both updated summary",
        keyFindings: ["Both updated finding"],
      })

      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(result.value.summary).toBe("Both updated summary")
        expect(result.value.keyFindings).toEqual(["Both updated finding"])
      }
    })

    test("persists updates across instances", async () => {
      await manager.updateResearch(researchId, {
        summary: "Persisted summary",
      })

      const newArtifactRegistry = new ArtifactRegistry(testDir, createMockLogger())
      await newArtifactRegistry.load()
      const newManager = new ResearchManager(testDir, newArtifactRegistry, createMockLogger())
      await newManager.load()

      const entry = newManager.list().find((e) => e.title === "Update Test Research")
      expect(entry).not.toBeUndefined()
      expect(entry?.summary).toBe("Persisted summary")
    })
  })

  describe("querying", () => {
    beforeEach(async () => {
      await manager.load()

      await manager.createResearch({
        title: "Research One",
        content: "# One\n\nContent.",
        summary: "Summary one",
        sourceIssue: "proj-123.1",
      })

      await manager.createResearch({
        title: "Research Two",
        content: "# Two\n\nContent.",
        summary: "Summary two",
        sourceIssue: "proj-123.1",
      })

      await manager.createResearch({
        title: "Research Three",
        content: "# Three\n\nContent.",
        summary: "Summary three",
        sourceIssue: "proj-456.1",
      })
    })

    test("list() returns all research alphabetically by title", () => {
      const entries = manager.list()
      expect(entries).toHaveLength(3)
      expect(entries[0].title).toBe("Research One")
      expect(entries[1].title).toBe("Research Three")
      expect(entries[2].title).toBe("Research Two")
    })

    test("getById() returns research or null", () => {
      const entries = manager.list()
      const firstEntry = entries[0]

      const found = manager.getById(firstEntry.id)
      expect(found).not.toBeNull()
      expect(found?.id).toBe(firstEntry.id)

      const notFound = manager.getById("non-existent-id")
      expect(notFound).toBeNull()
    })

    test("getByIssue() returns research for an issue", () => {
      const entries = manager.getByIssue("proj-123.1")
      expect(entries).toHaveLength(2)
      expect(entries.every((e) => e.sourceIssue === "proj-123.1")).toBe(true)
    })

    test("getByIssue() returns empty array for unknown issue", () => {
      const entries = manager.getByIssue("unknown-issue")
      expect(entries).toHaveLength(0)
    })
  })

  describe("research path handling", () => {
    test("default path is projectDir/research/", async () => {
      const researchDir = manager.getResearchDir()
      expect(researchDir).toBe(path.join(testDir, "research"))
    })

    test("custom path is used when provided", async () => {
      const customPath = path.join(testDir, "custom-research-dir")
      const customManager = new ResearchManager(
        testDir,
        artifactRegistry,
        createMockLogger(),
        customPath
      )

      expect(customManager.getResearchDir()).toBe(customPath)
    })

    test("external research is marked correctly", async () => {
      const externalPath = path.join(os.tmpdir(), "external-research")
      await fs.mkdir(externalPath, { recursive: true })

      try {
        const externalManager = new ResearchManager(
          testDir,
          artifactRegistry,
          createMockLogger(),
          externalPath
        )
        await externalManager.load()

        const result = await externalManager.createResearch({
          title: "External Research",
          content: "# External\n\nContent.",
          summary: "External summary",
        })

        expect(result.ok).toBe(true)
        if (result.ok) {
          expect(result.value.external).toBe(true)
          expect(result.value.absolutePath.startsWith(externalPath)).toBe(true)
        }
      } finally {
        await fs.rm(externalPath, { recursive: true, force: true })
      }
    })

    test("internal research is marked as not external", async () => {
      await manager.load()

      const result = await manager.createResearch({
        title: "Internal Research",
        content: "# Internal\n\nContent.",
        summary: "Internal summary",
      })

      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(result.value.external).toBe(false)
        expect(result.value.absolutePath.startsWith(testDir)).toBe(true)
      }
    })
  })

  describe("formatIndexFile", () => {
    beforeEach(async () => {
      await manager.load()
    })

    test("produces valid markdown with table and entries", () => {
      const index: ResearchIndex = {
        entries: [
          {
            id: "research-auth-patterns-abc123",
            title: "Authentication Patterns",
            path: "research/authentication-patterns.md",
            absolutePath: path.join(testDir, "research/authentication-patterns.md"),
            external: false,
            createdAt: "2026-03-02T10:30:00.000Z",
            sourceIssue: "proj-123.1",
            summary: "Analysis of OAuth2 and SAML",
            keyFindings: ["OAuth2 is better for SPAs", "SAML for enterprise"],
          },
        ],
      }

      const content = manager.formatIndexFile(index)

      expect(content).toContain("# Research Index")
      expect(content).toContain("## Summary")
      expect(content).toContain("| Title | Summary | Source |")
      expect(content).toContain("|-------|---------|--------|")
      expect(content).toContain("[Authentication Patterns]")
      expect(content).toContain("Analysis of OAuth2 and SAML")
      expect(content).toContain("proj-123.1")
      expect(content).toContain("## Authentication Patterns")
      expect(content).toContain("**Source Issue:** proj-123.1")
      expect(content).toContain("**Created:** 2026-03-02")
      expect(content).toContain("**Key Findings:**")
      expect(content).toContain("- OAuth2 is better for SPAs")
      expect(content).toContain("- SAML for enterprise")
      expect(content).toContain("**Full Document:**")
    })

    test("shows placeholder text for empty index", () => {
      const index: ResearchIndex = { entries: [] }

      const content = manager.formatIndexFile(index)

      expect(content).toContain("# Research Index")
      expect(content).toContain("*No research documents yet.*")
    })

    test("formats multiple entries correctly", () => {
      const index: ResearchIndex = {
        entries: [
          {
            id: "research-alpha-abc123",
            title: "Alpha Research",
            path: "research/alpha-research.md",
            absolutePath: path.join(testDir, "research/alpha-research.md"),
            external: false,
            createdAt: "2026-03-01T10:00:00.000Z",
            summary: "Alpha summary",
          },
          {
            id: "research-beta-def456",
            title: "Beta Research",
            path: "research/beta-research.md",
            absolutePath: path.join(testDir, "research/beta-research.md"),
            external: false,
            createdAt: "2026-03-02T10:00:00.000Z",
            summary: "Beta summary",
            sourceIssue: "proj-456.1",
          },
        ],
      }

      const content = manager.formatIndexFile(index)

      expect(content).toContain("## Alpha Research")
      expect(content).toContain("## Beta Research")
      expect(content).toContain("Alpha summary")
      expect(content).toContain("Beta summary")
    })

    test("handles entries without optional fields", () => {
      const index: ResearchIndex = {
        entries: [
          {
            id: "research-minimal-abc123",
            title: "Minimal Research",
            path: "research/minimal-research.md",
            absolutePath: path.join(testDir, "research/minimal-research.md"),
            external: false,
            createdAt: "2026-03-02T10:00:00.000Z",
            summary: "Minimal summary",
          },
        ],
      }

      const content = manager.formatIndexFile(index)

      expect(content).toContain("## Minimal Research")
      expect(content).toContain("Minimal summary")
      expect(content).not.toContain("**Source Issue:**")
      expect(content).not.toContain("**Key Findings:**")
    })

    test("uses absolute path for external entries", () => {
      const externalPath = "/external/path/research.md"
      const index: ResearchIndex = {
        entries: [
          {
            id: "research-external-abc123",
            title: "External Research",
            path: externalPath,
            absolutePath: externalPath,
            external: true,
            createdAt: "2026-03-02T10:00:00.000Z",
            summary: "External summary",
          },
        ],
      }

      const content = manager.formatIndexFile(index)

      expect(content).toContain(`[External Research](${externalPath})`)
    })
  })

  describe("persistence across instances", () => {
    test("new manager instance loads previously saved research", async () => {
      await manager.load()
      await manager.createResearch({
        title: "Persistent Research",
        content: "# Persistent\n\nContent.",
        summary: "Persistent summary",
      })

      const newArtifactRegistry = new ArtifactRegistry(testDir, createMockLogger())
      await newArtifactRegistry.load()
      const newManager = new ResearchManager(testDir, newArtifactRegistry, createMockLogger())
      const index = await newManager.load()

      expect(index.entries).toHaveLength(1)
      expect(index.entries[0].title).toBe("Persistent Research")
    })

    test("key findings persist across instances", async () => {
      await manager.load()
      await manager.createResearch({
        title: "Findings Research",
        content: "# Findings\n\nContent.",
        summary: "Findings summary",
        keyFindings: ["Finding 1", "Finding 2"],
      })

      const newArtifactRegistry = new ArtifactRegistry(testDir, createMockLogger())
      await newArtifactRegistry.load()
      const newManager = new ResearchManager(testDir, newArtifactRegistry, createMockLogger())
      const index = await newManager.load()

      expect(index.entries[0].keyFindings).toEqual(["Finding 1", "Finding 2"])
    })
  })

  describe("slug generation", () => {
    beforeEach(async () => {
      await manager.load()
    })

    test("generates lowercase hyphenated slug", async () => {
      const result = await manager.createResearch({
        title: "Use OAuth2 With PKCE",
        content: "# Test\n\nContent.",
        summary: "Test summary",
      })

      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(result.value.path).toContain("use-oauth2-with-pkce.md")
      }
    })

    test("removes special characters from slug", async () => {
      const result = await manager.createResearch({
        title: "OAuth2 (with PKCE!) for Auth",
        content: "# Test\n\nContent.",
        summary: "Test summary",
      })

      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(result.value.path).toContain("oauth2-with-pkce-for-auth.md")
      }
    })

    test("truncates long slugs to 50 characters", async () => {
      const result = await manager.createResearch({
        title:
          "This Is A Very Long Research Title That Should Be Truncated To Fifty Characters Maximum",
        content: "# Test\n\nContent.",
        summary: "Test summary",
      })

      expect(result.ok).toBe(true)
      if (result.ok) {
        const filename = path.basename(result.value.path, ".md")
        expect(filename.length).toBeLessThanOrEqual(50)
      }
    })

    test("removes leading and trailing hyphens from slug", async () => {
      const result = await manager.createResearch({
        title: "---Test Research---",
        content: "# Test\n\nContent.",
        summary: "Test summary",
      })

      expect(result.ok).toBe(true)
      if (result.ok) {
        const filename = path.basename(result.value.path, ".md")
        expect(filename).not.toMatch(/^-/)
        expect(filename).not.toMatch(/-$/)
      }
    })
  })
})
