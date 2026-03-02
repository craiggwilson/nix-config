/**
 * Tests for focus-context builder
 */

import { describe, it, expect, beforeEach, afterEach } from "bun:test"
import * as fs from "node:fs/promises"
import * as path from "node:path"
import * as os from "node:os"

import { buildFocusContext } from "./focus-context.js"
import { ProjectManager } from "../project-manager.js"
import { ConfigManager } from "../../config/index.js"
import { FocusManager } from "../focus-manager.js"
import { InMemoryIssueStorage } from "../../issues/inmemory/index.js"
import type { Logger } from "../../utils/opencode-sdk/index.js"

function createMockLogger(): Logger {
  return {
    debug: async () => {},
    info: async () => {},
    warn: async () => {},
    error: async () => {},
  }
}

describe("buildFocusContext", () => {
  let tempDir: string
  let projectManager: ProjectManager
  let originalXdgConfig: string | undefined
  let originalXdgData: string | undefined

  beforeEach(async () => {
    tempDir = await fs.mkdtemp(path.join(os.tmpdir(), "focus-context-test-"))
    originalXdgConfig = process.env.XDG_CONFIG_HOME
    originalXdgData = process.env.XDG_DATA_HOME
    process.env.XDG_CONFIG_HOME = path.join(tempDir, "config")
    process.env.XDG_DATA_HOME = path.join(tempDir, "data")

    const config = await ConfigManager.loadOrThrow()
    const focus = new FocusManager()
    const issueStorage = new InMemoryIssueStorage({ prefix: "test" })
    const logger = createMockLogger()

    projectManager = new ProjectManager(config, issueStorage, focus, logger, tempDir)
  })

  afterEach(async () => {
    if (originalXdgConfig !== undefined) {
      process.env.XDG_CONFIG_HOME = originalXdgConfig
    } else {
      delete process.env.XDG_CONFIG_HOME
    }
    if (originalXdgData !== undefined) {
      process.env.XDG_DATA_HOME = originalXdgData
    } else {
      delete process.env.XDG_DATA_HOME
    }
    await fs.rm(tempDir, { recursive: true, force: true })
  })

  it("returns context with no focused project", async () => {
    const context = await buildFocusContext(projectManager)

    expect(context).toContain("<project-context>")
    expect(context).toContain("</project-context>")
    expect(context).toContain("Focused Project: None")
  })

  it("returns context with focused project", async () => {
    const result = await projectManager.createProject({
      name: "test-project",
      description: "Test description",
      storage: "local",
    })

    projectManager.setFocus(result.projectId)

    const context = await buildFocusContext(projectManager)

    expect(context).toContain("<project-context>")
    expect(context).toContain("</project-context>")
    expect(context).toContain(`Focused Project: ${result.projectId}`)
  })

  it("includes progress information", async () => {
    const result = await projectManager.createProject({
      name: "progress-test",
      description: "Test",
      storage: "local",
    })

    projectManager.setFocus(result.projectId)

    await projectManager.createIssue(result.projectId, "Issue 1")
    await projectManager.createIssue(result.projectId, "Issue 2")

    const context = await buildFocusContext(projectManager)

    expect(context).toContain("Progress:")
    expect(context).toContain("issues complete")
  })

  it("handles project with artifacts", async () => {
    const result = await projectManager.createProject({
      name: "artifact-test",
      description: "Test",
      storage: "local",
    })

    projectManager.setFocus(result.projectId)

    const artifactPath = path.join(tempDir, "test-artifact.md")
    await fs.writeFile(artifactPath, "# Test Artifact")

    const registry = await projectManager.getArtifactRegistry(result.projectId)
    if (registry) {
      await registry.register({
        title: "Test Artifact",
        type: "research",
        path: "test-artifact.md",
        absolutePath: artifactPath,
        external: false,
      })
    }

    const context = await buildFocusContext(projectManager)

    expect(context).toContain("<project-context>")
  })

  it("handles errors gracefully", async () => {
    const result = await projectManager.createProject({
      name: "error-test",
      description: "Test",
      storage: "local",
    })

    projectManager.setFocus(result.projectId)

    const context = await buildFocusContext(projectManager)

    expect(context).toContain("<project-context>")
    expect(context).not.toContain("Error")
  })

  it("includes session continuity context (sessions, open questions, pending decisions, what's next)", async () => {
    const result = await projectManager.createProject({
      name: "session-continuity-test",
      description: "Test session continuity",
      storage: "local",
    })

    projectManager.setFocus(result.projectId)

    // Capture sessions with open questions
    const sessionManager = await projectManager.getSessionManager(result.projectId)
    if (sessionManager) {
      await sessionManager.captureSession({
        sessionId: "ses_continuity_1",
        summary: "First session with important findings.",
        keyPoints: ["Analyzed authentication patterns", "Created initial design"],
        openQuestionsAdded: ["How to handle token refresh?"],
      })

      await sessionManager.captureSession({
        sessionId: "ses_continuity_2",
        summary: "Second session with more progress.",
        keyPoints: ["Implemented OAuth2 flow", "Added tests"],
        openQuestionsAdded: ["What about offline mode?"],
      })

      // Update pending decisions and what's next
      await sessionManager.updateIndex({
        pendingDecisions: ["Choose between Auth0 and Okta"],
        whatsNext: ["Complete token refresh implementation", "Write integration tests"],
      })
    }

    const context = await buildFocusContext(projectManager)

    // Verify session context is included
    expect(context).toContain("Recent Sessions")
    expect(context).toContain("Second session with more progress")

    // Verify open questions are included
    expect(context).toContain("Open Questions")
    expect(context).toContain("How to handle token refresh?")
    expect(context).toContain("What about offline mode?")

    // Verify pending decisions are included
    expect(context).toContain("Pending Decisions")
    expect(context).toContain("Choose between Auth0 and Okta")

    // Verify what's next is included
    expect(context).toContain("What's Next")
    expect(context).toContain("Complete token refresh implementation")
  })

  it("includes decision context with pending and recent decisions", async () => {
    const result = await projectManager.createProject({
      name: "decision-context-test",
      description: "Test decision context",
      storage: "local",
    })

    projectManager.setFocus(result.projectId)

    // Record a decision
    const decisionManager = await projectManager.getDecisionManager(result.projectId)
    if (decisionManager) {
      await decisionManager.recordDecision({
        title: "Use OAuth2 with PKCE",
        decision: "Implement OAuth2 with PKCE for authentication",
        rationale: "Better mobile support and security",
      })

      // Add a pending decision
      await decisionManager.addPendingDecision({
        question: "Which identity provider to use?",
        context: "Need to decide before implementation",
      })
    }

    const context = await buildFocusContext(projectManager)

    // Verify pending decisions are shown
    expect(context).toContain("Pending Decisions")
    expect(context).toContain("Which identity provider to use?")

    // Verify recent decisions are shown
    expect(context).toContain("Recent Decisions")
    expect(context).toContain("Use OAuth2 with PKCE")
  })

  it("includes artifact summary grouped by type", async () => {
    const result = await projectManager.createProject({
      name: "artifact-summary-test",
      description: "Test artifact summary",
      storage: "local",
    })

    projectManager.setFocus(result.projectId)

    const artifactRegistry = await projectManager.getArtifactRegistry(result.projectId)
    if (artifactRegistry) {
      // Register research artifact
      await artifactRegistry.register({
        title: "Authentication Research",
        type: "research",
        path: "research/auth.md",
        absolutePath: path.join(tempDir, "research/auth.md"),
        external: false,
        summary: "Analysis of auth patterns",
      })

      // Register decision artifact
      await artifactRegistry.register({
        title: "OAuth2 Decision",
        type: "decision",
        path: "decisions/oauth2.md",
        absolutePath: path.join(tempDir, "decisions/oauth2.md"),
        external: false,
        summary: "Decision to use OAuth2",
      })
    }

    const context = await buildFocusContext(projectManager)

    // Verify artifacts are shown
    expect(context).toContain("Available Artifacts")
    expect(context).toContain("research")
    expect(context).toContain("Authentication Research")
    expect(context).toContain("decision")
    expect(context).toContain("OAuth2 Decision")
  })
})
