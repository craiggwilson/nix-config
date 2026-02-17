/**
 * Tests for ArtifactManager
 */

import { describe, test, expect, beforeEach, afterAll } from "bun:test"
import * as fs from "node:fs/promises"
import * as path from "node:path"
import * as os from "node:os"

import { ArtifactManager } from "./artifact-manager.js"

describe("ArtifactManager", () => {
  let testDir: string
  let manager: ArtifactManager

  beforeEach(async () => {
    // Create a fresh temporary directory for each test
    testDir = await fs.mkdtemp(path.join(os.tmpdir(), "artifact-test-"))
    manager = new ArtifactManager(testDir)
  })

  afterAll(async () => {
    // Cleanup all test directories
    try {
      const tmpDir = os.tmpdir()
      const entries = await fs.readdir(tmpDir)
      for (const entry of entries) {
        if (entry.startsWith("artifact-test-")) {
          await fs.rm(path.join(tmpDir, entry), { recursive: true, force: true })
        }
      }
    } catch {
      // Ignore cleanup errors
    }
  })

  describe("listArtifacts", () => {
    test("lists all artifact types", async () => {
      const artifacts = await manager.listArtifacts()

      expect(artifacts.length).toBe(5)
      expect(artifacts.map((a) => a.type)).toContain("roadmap")
      expect(artifacts.map((a) => a.type)).toContain("architecture")
      expect(artifacts.map((a) => a.type)).toContain("risks")
      expect(artifacts.map((a) => a.type)).toContain("success-criteria")
      expect(artifacts.map((a) => a.type)).toContain("resources")
    })

    test("shows non-existent artifacts as not existing", async () => {
      const artifacts = await manager.listArtifacts()

      for (const artifact of artifacts) {
        expect(artifact.exists).toBe(false)
      }
    })

    test("shows existing artifacts with metadata", async () => {
      // Create a roadmap
      await manager.writeArtifact("roadmap", "# Test Roadmap")

      const artifacts = await manager.listArtifacts()
      const roadmap = artifacts.find((a) => a.type === "roadmap")

      expect(roadmap?.exists).toBe(true)
      expect(roadmap?.lastModified).toBeDefined()
      expect(roadmap?.size).toBeGreaterThan(0)
    })
  })

  describe("artifactExists", () => {
    test("returns false for non-existent artifact", async () => {
      const exists = await manager.artifactExists("roadmap")
      expect(exists).toBe(false)
    })

    test("returns true for existing artifact", async () => {
      await manager.writeArtifact("roadmap", "# Test")

      const exists = await manager.artifactExists("roadmap")
      expect(exists).toBe(true)
    })
  })

  describe("readArtifact", () => {
    test("returns null for non-existent artifact", async () => {
      const content = await manager.readArtifact("roadmap")
      expect(content).toBeNull()
    })

    test("returns content for existing artifact", async () => {
      await manager.writeArtifact("roadmap", "# Test Roadmap\n\nContent here.")

      const content = await manager.readArtifact("roadmap")
      expect(content).toContain("# Test Roadmap")
      expect(content).toContain("Content here.")
    })
  })

  describe("generateRoadmap", () => {
    test("generates roadmap markdown", async () => {
      const markdown = await manager.generateRoadmap({
        vision: "Build the best project management tool.",
        milestones: [
          {
            name: "MVP",
            description: "Minimum viable product",
            targetDate: "2024-Q1",
            deliverables: ["Core features", "Basic UI"],
            status: "in_progress",
          },
          {
            name: "Beta",
            targetDate: "2024-Q2",
            deliverables: ["Advanced features", "Polish"],
            dependencies: ["MVP"],
            status: "planned",
          },
        ],
        timeline: "6 months total",
        assumptions: ["Team of 3 developers", "No major scope changes"],
        constraints: ["Budget limited to $50k"],
      })

      expect(markdown).toContain("# Roadmap")
      expect(markdown).toContain("## Vision")
      expect(markdown).toContain("Build the best project management tool.")
      expect(markdown).toContain("### 🔄 MVP")
      expect(markdown).toContain("### ⬜ Beta")
      expect(markdown).toContain("**Target Date:** 2024-Q1")
      expect(markdown).toContain("- Core features")
      expect(markdown).toContain("## Assumptions")
      expect(markdown).toContain("## Constraints")

      // Verify file was written
      const exists = await manager.artifactExists("roadmap")
      expect(exists).toBe(true)
    })
  })

  describe("generateArchitecture", () => {
    test("generates architecture markdown", async () => {
      const markdown = await manager.generateArchitecture({
        overview: "A modular architecture with clear separation of concerns.",
        components: [
          {
            name: "API Layer",
            description: "RESTful API endpoints",
            technology: "Node.js + Express",
            responsibilities: ["Handle HTTP requests", "Validate input"],
            dependencies: ["Database Layer"],
          },
          {
            name: "Database Layer",
            description: "Data persistence",
            technology: "PostgreSQL",
            responsibilities: ["Store data", "Handle queries"],
          },
        ],
        decisions: [
          {
            title: "Use TypeScript",
            decision: "All code will be written in TypeScript",
            rationale: "Type safety and better developer experience",
            alternatives: ["JavaScript", "Go"],
          },
        ],
      })

      expect(markdown).toContain("# Architecture")
      expect(markdown).toContain("## Overview")
      expect(markdown).toContain("modular architecture")
      expect(markdown).toContain("### API Layer")
      expect(markdown).toContain("**Technology:** Node.js + Express")
      expect(markdown).toContain("## Architecture Decisions")
      expect(markdown).toContain("### Use TypeScript")

      const exists = await manager.artifactExists("architecture")
      expect(exists).toBe(true)
    })
  })

  describe("generateRisks", () => {
    test("generates risks markdown", async () => {
      const markdown = await manager.generateRisks({
        summary: "Key risks identified during planning.",
        risks: [
          {
            id: "R1",
            title: "Timeline Slip",
            description: "Project may take longer than expected",
            likelihood: "medium",
            impact: "high",
            mitigation: "Build in buffer time and prioritize ruthlessly",
            owner: "PM",
            status: "mitigating",
          },
          {
            id: "R2",
            title: "Technical Complexity",
            description: "Integration may be harder than expected",
            likelihood: "low",
            impact: "medium",
            mitigation: "Spike early on integration points",
          },
        ],
      })

      expect(markdown).toContain("# Risk Assessment")
      expect(markdown).toContain("## Summary")
      expect(markdown).toContain("## Risk Overview")
      expect(markdown).toContain("| High | 1 |")
      expect(markdown).toContain("### 🔴 R1: Timeline Slip")
      expect(markdown).toContain("### 🟡 R2: Technical Complexity")
      expect(markdown).toContain("| Likelihood | medium |")

      const exists = await manager.artifactExists("risks")
      expect(exists).toBe(true)
    })
  })

  describe("generateSuccessCriteria", () => {
    test("generates success criteria markdown", async () => {
      const markdown = await manager.generateSuccessCriteria({
        overview: "How we will measure success.",
        criteria: [
          {
            name: "User Adoption",
            description: "Number of active users",
            metric: "Daily Active Users",
            target: "1000 DAU",
            measurement: "Analytics dashboard",
          },
          {
            name: "Performance",
            description: "System responsiveness",
            metric: "P95 latency",
            target: "< 200ms",
          },
        ],
        acceptanceCriteria: [
          "All tests pass",
          "No critical bugs",
          "Documentation complete",
        ],
      })

      expect(markdown).toContain("# Success Criteria")
      expect(markdown).toContain("## Overview")
      expect(markdown).toContain("## Key Performance Indicators")
      expect(markdown).toContain("### User Adoption")
      expect(markdown).toContain("| Target | 1000 DAU |")
      expect(markdown).toContain("## Acceptance Criteria")
      expect(markdown).toContain("- [ ] All tests pass")

      const exists = await manager.artifactExists("success-criteria")
      expect(exists).toBe(true)
    })
  })
})
