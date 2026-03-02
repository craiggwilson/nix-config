/**
 * Integration tests for artifact, session, decision, and research management
 *
 * Tests the complete flow of creating projects and managing artifacts, sessions,
 * decisions, and research across the project lifecycle.
 *
 * CRITICAL: All tests use local storage in temporary directories to prevent
 * interference with actual projects.
 */

import { describe, test, expect, beforeEach, afterEach, afterAll } from "bun:test"
import * as fs from "node:fs/promises"
import * as path from "node:path"

import {
  createIntegrationFixture,
  cleanupTestDirectories,
  type IntegrationTestFixture,
} from "./integration-test-utils.js"
import { ArtifactRegistry } from "../src/artifacts/index.js"
import { SessionManager } from "../src/sessions/index.js"
import { DecisionManager } from "../src/decisions/index.js"
import { ResearchManager } from "../src/research/index.js"
import { createMockLogger } from "../src/utils/testing/index.js"

describe("Artifact and Session Management Integration", () => {
  let fixture: IntegrationTestFixture
  let artifactRegistry: ArtifactRegistry
  let sessionManager: SessionManager
  let decisionManager: DecisionManager
  let researchManager: ResearchManager
  let projectDir: string
  let projectId: string

  beforeEach(async () => {
    fixture = await createIntegrationFixture()

    // Create a project to work with
    const project = await fixture.projectManager.createProject({
      name: "Artifact Test Project",
      storage: "local",
    })
    projectDir = project.projectDir
    projectId = project.projectId

    // Initialize managers for the project
    const log = createMockLogger()
    artifactRegistry = new ArtifactRegistry(projectDir, log)
    await artifactRegistry.load()

    sessionManager = new SessionManager(projectDir, log)
    await sessionManager.load()

    decisionManager = new DecisionManager(projectDir, artifactRegistry, log)
    await decisionManager.load()

    researchManager = new ResearchManager(projectDir, artifactRegistry, log)
    await researchManager.load()
  })

  afterEach(async () => {
    await fixture.cleanup()
  })

  afterAll(async () => {
    await cleanupTestDirectories("opencode-integration-test-")
  })

  describe("Artifact Management Integration", () => {
    test("create project → register artifacts → verify in registry", async () => {
      // Register a research artifact
      const researchResult = await artifactRegistry.register({
        type: "research",
        title: "Authentication Patterns",
        path: "research/auth-patterns.md",
        absolutePath: path.join(projectDir, "research/auth-patterns.md"),
        external: false,
        summary: "Analysis of OAuth2 vs SAML for enterprise SSO",
      })

      expect(researchResult.ok).toBe(true)
      if (researchResult.ok) {
        expect(researchResult.value.id).toMatch(/^research-authentication-patterns-[a-f0-9]+$/)
        expect(researchResult.value.type).toBe("research")
        expect(researchResult.value.title).toBe("Authentication Patterns")
      }

      // Register a deliverable artifact
      const deliverableResult = await artifactRegistry.register({
        type: "deliverable",
        title: "API Design Document",
        path: "deliverables/api-design.md",
        absolutePath: path.join(projectDir, "deliverables/api-design.md"),
        external: false,
        summary: "REST API design for user authentication endpoints",
      })

      expect(deliverableResult.ok).toBe(true)

      // Verify both artifacts are in the registry
      const allArtifacts = artifactRegistry.list()
      expect(allArtifacts.length).toBe(2)

      // Verify filtering by type
      const researchArtifacts = artifactRegistry.getByType("research")
      expect(researchArtifacts.length).toBe(1)
      expect(researchArtifacts[0].title).toBe("Authentication Patterns")

      const deliverableArtifacts = artifactRegistry.getByType("deliverable")
      expect(deliverableArtifacts.length).toBe(1)
      expect(deliverableArtifacts[0].title).toBe("API Design Document")
    })

    test("artifacts linked to issues", async () => {
      const issueId = `${projectId}.1`

      // Register artifacts linked to an issue
      const artifact1Result = await artifactRegistry.register({
        type: "research",
        title: "Issue Research",
        path: "research/issue-research.md",
        absolutePath: path.join(projectDir, "research/issue-research.md"),
        external: false,
        sourceIssue: issueId,
        summary: "Research for issue 1",
      })

      const artifact2Result = await artifactRegistry.register({
        type: "diagram",
        title: "Architecture Diagram",
        path: "diagrams/architecture.png",
        absolutePath: path.join(projectDir, "diagrams/architecture.png"),
        external: false,
        sourceIssue: issueId,
        summary: "System architecture diagram",
      })

      expect(artifact1Result.ok).toBe(true)
      expect(artifact2Result.ok).toBe(true)

      // Retrieve artifacts by issue
      const issueArtifacts = artifactRegistry.getByIssue(issueId)
      expect(issueArtifacts.length).toBe(2)
      expect(issueArtifacts.map((a) => a.type).sort()).toEqual(["diagram", "research"])
    })

    test("artifacts linked to sessions", async () => {
      const sessionId = "ses_abc123"

      // Register artifacts linked to a session
      await artifactRegistry.register({
        type: "notes",
        title: "Session Notes",
        path: "notes/session-notes.md",
        absolutePath: path.join(projectDir, "notes/session-notes.md"),
        external: false,
        sourceSession: sessionId,
        summary: "Notes from planning session",
      })

      await artifactRegistry.register({
        type: "decision",
        title: "Tech Stack Decision",
        path: "decisions/tech-stack.md",
        absolutePath: path.join(projectDir, "decisions/tech-stack.md"),
        external: false,
        sourceSession: sessionId,
        summary: "Decision on technology stack",
      })

      // Retrieve artifacts by session
      const sessionArtifacts = artifactRegistry.getBySession(sessionId)
      expect(sessionArtifacts.length).toBe(2)
    })

    test("external artifacts (outside project directory)", async () => {
      const externalPath = "/tmp/external-artifact.md"

      const result = await artifactRegistry.register({
        type: "reference",
        title: "External Reference",
        path: externalPath,
        absolutePath: externalPath,
        external: true,
        summary: "Reference document stored externally",
      })

      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(result.value.external).toBe(true)
        expect(result.value.absolutePath).toBe(externalPath)
      }

      // Verify external artifact is retrievable
      const allArtifacts = artifactRegistry.list()
      const externalArtifact = allArtifacts.find((a) => a.external)
      expect(externalArtifact).toBeDefined()
      expect(externalArtifact?.title).toBe("External Reference")
    })

    test("artifact registry persists across reloads", async () => {
      // Register an artifact
      await artifactRegistry.register({
        type: "test",
        title: "Persistence Test",
        path: "test/persistence.md",
        absolutePath: path.join(projectDir, "test/persistence.md"),
        external: false,
        summary: "Testing persistence",
      })

      // Create a new registry instance and load
      const log = createMockLogger()
      const newRegistry = new ArtifactRegistry(projectDir, log)
      await newRegistry.load()

      // Verify artifact persisted
      const artifacts = newRegistry.list()
      expect(artifacts.length).toBe(1)
      expect(artifacts[0].title).toBe("Persistence Test")
    })

    test("duplicate artifact path rejected", async () => {
      const artifactPath = path.join(projectDir, "test/duplicate.md")

      // Register first artifact
      const first = await artifactRegistry.register({
        type: "test",
        title: "First Artifact",
        path: "test/duplicate.md",
        absolutePath: artifactPath,
        external: false,
        summary: "First artifact",
      })
      expect(first.ok).toBe(true)

      // Attempt to register duplicate
      const second = await artifactRegistry.register({
        type: "test",
        title: "Second Artifact",
        path: "test/duplicate.md",
        absolutePath: artifactPath,
        external: false,
        summary: "Second artifact with same path",
      })

      expect(second.ok).toBe(false)
      if (!second.ok) {
        expect(second.error.type).toBe("already_exists")
      }
    })
  })

  describe("Session Management Integration", () => {
    test("create project → capture sessions → verify history", async () => {
      // Capture first session
      const session1Result = await sessionManager.captureSession({
        sessionId: "ses_session1",
        summary: "Initial project setup and planning completed.",
        keyPoints: [
          "Defined project scope and objectives",
          "Identified key stakeholders",
          "Created initial task breakdown",
        ],
      })

      expect(session1Result.ok).toBe(true)
      if (session1Result.ok) {
        expect(session1Result.value.sequence).toBe(1)
        expect(session1Result.value.filename).toMatch(/^001-ses_session1-\d{4}-\d{2}-\d{2}\.md$/)
      }

      // Capture second session
      const session2Result = await sessionManager.captureSession({
        sessionId: "ses_session2",
        summary: "Completed authentication research and made key decisions.",
        keyPoints: [
          "Analyzed OAuth2 vs SAML",
          "Decided on OAuth2 with PKCE",
          "Created architecture diagram",
        ],
        openQuestionsAdded: ["How to handle token refresh in offline mode?"],
        decisionsMade: ["OAuth2 with PKCE for authentication"],
        artifactsCreated: ["research-auth-patterns-abc123"],
      })

      expect(session2Result.ok).toBe(true)
      if (session2Result.ok) {
        expect(session2Result.value.sequence).toBe(2)
      }

      // Verify session history
      const recentSessions = sessionManager.getRecentSessions(10)
      expect(recentSessions.length).toBe(2)
      // Most recent first
      expect(recentSessions[0].id).toBe("ses_session2")
      expect(recentSessions[1].id).toBe("ses_session1")
    })

    test("session index updated correctly (most recent first)", async () => {
      // Capture multiple sessions
      await sessionManager.captureSession({
        sessionId: "ses_first",
        summary: "First session",
        keyPoints: ["Point 1"],
      })

      await sessionManager.captureSession({
        sessionId: "ses_second",
        summary: "Second session",
        keyPoints: ["Point 2"],
      })

      await sessionManager.captureSession({
        sessionId: "ses_third",
        summary: "Third session",
        keyPoints: ["Point 3"],
      })

      // Verify order
      const sessions = sessionManager.getRecentSessions(10)
      expect(sessions.length).toBe(3)
      expect(sessions[0].id).toBe("ses_third")
      expect(sessions[1].id).toBe("ses_second")
      expect(sessions[2].id).toBe("ses_first")

      // Verify sequence numbers
      expect(sessions[0].sequence).toBe(3)
      expect(sessions[1].sequence).toBe(2)
      expect(sessions[2].sequence).toBe(1)
    })

    test("open questions accumulated across sessions", async () => {
      // First session adds questions
      await sessionManager.captureSession({
        sessionId: "ses_q1",
        summary: "Session with questions",
        keyPoints: ["Identified open questions"],
        openQuestionsAdded: ["Question 1?", "Question 2?"],
      })

      // Second session adds more questions
      await sessionManager.captureSession({
        sessionId: "ses_q2",
        summary: "More questions",
        keyPoints: ["More questions identified"],
        openQuestionsAdded: ["Question 3?"],
      })

      // Reload and verify accumulated questions
      const log = createMockLogger()
      const newManager = new SessionManager(projectDir, log)
      const index = await newManager.load()

      expect(index.openQuestions.length).toBe(3)
      expect(index.openQuestions).toContain("Question 1?")
      expect(index.openQuestions).toContain("Question 2?")
      expect(index.openQuestions).toContain("Question 3?")
    })

    test("what's next updated from sessions", async () => {
      // Capture a session
      await sessionManager.captureSession({
        sessionId: "ses_next",
        summary: "Planning session",
        keyPoints: ["Planned next steps"],
      })

      // Update what's next
      await sessionManager.updateIndex({
        whatsNext: ["Implement authentication", "Write tests", "Deploy to staging"],
      })

      // Reload and verify
      const log = createMockLogger()
      const newManager = new SessionManager(projectDir, log)
      const index = await newManager.load()

      expect(index.whatsNext.length).toBe(3)
      expect(index.whatsNext).toContain("Implement authentication")
    })

    test("session files created on disk", async () => {
      await sessionManager.captureSession({
        sessionId: "ses_file_test",
        summary: "Testing file creation",
        keyPoints: ["Verify file exists"],
      })

      // Check that session file exists
      const sessionsDir = path.join(projectDir, "sessions")
      const files = await fs.readdir(sessionsDir)
      const sessionFile = files.find((f) => f.includes("ses_file_test"))
      expect(sessionFile).toBeDefined()

      // Verify file content
      const content = await fs.readFile(path.join(sessionsDir, sessionFile!), "utf-8")
      expect(content).toContain("# Session:")
      expect(content).toContain("Testing file creation")
      expect(content).toContain("Verify file exists")
    })

    test("duplicate session ID rejected", async () => {
      await sessionManager.captureSession({
        sessionId: "ses_duplicate",
        summary: "First capture",
        keyPoints: ["Point 1"],
      })

      const duplicate = await sessionManager.captureSession({
        sessionId: "ses_duplicate",
        summary: "Duplicate capture",
        keyPoints: ["Point 2"],
      })

      expect(duplicate.ok).toBe(false)
      if (!duplicate.ok) {
        expect(duplicate.error.type).toBe("already_exists")
      }
    })
  })

  describe("Decision Management Integration", () => {
    test("create project → record decisions → verify in log", async () => {
      // Record a decision
      const decisionResult = await decisionManager.recordDecision({
        title: "OAuth2 over SAML",
        decision: "Use OAuth2 with PKCE instead of SAML for authentication",
        rationale: "Better mobile support and simpler implementation",
        alternatives: [
          {
            name: "SAML",
            description: "Enterprise SSO standard",
            whyRejected: "Poor mobile support",
          },
        ],
      })

      expect(decisionResult.ok).toBe(true)
      if (decisionResult.ok) {
        expect(decisionResult.value.title).toBe("OAuth2 over SAML")
        expect(decisionResult.value.status).toBe("decided")
        expect(decisionResult.value.filename).toMatch(/^\d{4}-\d{2}-\d{2}-oauth2-over-saml\.md$/)
      }

      // Verify decision is in the list
      const decisions = decisionManager.list()
      expect(decisions.length).toBe(1)
      expect(decisions[0].title).toBe("OAuth2 over SAML")
    })

    test("decision status transitions (proposed → decided → superseded)", async () => {
      // Record a proposed decision
      const proposedResult = await decisionManager.recordDecision({
        title: "Database Choice",
        decision: "Use PostgreSQL for primary data storage",
        rationale: "Strong ACID compliance and JSON support",
        status: "proposed",
      })

      expect(proposedResult.ok).toBe(true)
      const decisionId = proposedResult.ok ? proposedResult.value.id : ""

      // Transition to decided
      const decidedResult = await decisionManager.updateStatus(decisionId, "decided")
      expect(decidedResult.ok).toBe(true)
      if (decidedResult.ok) {
        expect(decidedResult.value.status).toBe("decided")
      }

      // Record a new decision that supersedes this one
      const newDecisionResult = await decisionManager.recordDecision({
        title: "Database Choice v2",
        decision: "Use CockroachDB for distributed data storage",
        rationale: "Need for horizontal scaling",
      })
      expect(newDecisionResult.ok).toBe(true)
      const newDecisionId = newDecisionResult.ok ? newDecisionResult.value.id : ""

      // Supersede the original decision
      const supersededResult = await decisionManager.updateStatus(
        decisionId,
        "superseded",
        newDecisionId
      )
      expect(supersededResult.ok).toBe(true)
      if (supersededResult.ok) {
        expect(supersededResult.value.status).toBe("superseded")
        expect(supersededResult.value.supersededBy).toBe(newDecisionId)
      }

      // Verify lists
      const decided = decisionManager.list({ status: "decided" })
      const superseded = decisionManager.list({ status: "superseded" })
      expect(decided.length).toBe(1)
      expect(superseded.length).toBe(1)
    })

    test("pending decisions tracked", async () => {
      // Add pending decisions
      await decisionManager.addPendingDecision({
        question: "Which cloud provider should we use?",
        context: "Need to decide before infrastructure setup",
        blocking: ["infra-setup-issue"],
      })

      await decisionManager.addPendingDecision({
        question: "Should we use GraphQL or REST?",
        context: "API design decision",
        relatedResearch: ["research-api-patterns-abc123"],
      })

      // Verify pending decisions
      const pending = decisionManager.getPending()
      expect(pending.length).toBe(2)
      expect(pending[0].question).toBe("Which cloud provider should we use?")
      expect(pending[1].question).toBe("Should we use GraphQL or REST?")

      // Remove a pending decision
      await decisionManager.removePendingDecision("Which cloud provider should we use?")
      const remainingPending = decisionManager.getPending()
      expect(remainingPending.length).toBe(1)
    })

    test("decisions linked to research and sessions", async () => {
      const sessionId = "ses_decision_session"
      const researchIds = ["research-auth-abc123", "research-security-def456"]

      const result = await decisionManager.recordDecision({
        title: "Authentication Protocol",
        decision: "Use OAuth2 with PKCE",
        rationale: "Based on research findings",
        sourceSession: sessionId,
        sourceResearch: researchIds,
        relatedIssues: ["proj-123.1", "proj-123.2"],
      })

      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(result.value.sourceSession).toBe(sessionId)
        expect(result.value.sourceResearch).toEqual(researchIds)
        expect(result.value.relatedIssues).toEqual(["proj-123.1", "proj-123.2"])
      }

      // Verify decision file contains sources
      const decisionsDir = path.join(projectDir, "decisions")
      const files = await fs.readdir(decisionsDir)
      const decisionFile = files.find((f) => f.includes("authentication-protocol"))
      expect(decisionFile).toBeDefined()

      const content = await fs.readFile(path.join(decisionsDir, decisionFile!), "utf-8")
      expect(content).toContain("## Sources")
      expect(content).toContain(sessionId)
    })

    test("invalid status transition rejected", async () => {
      // Record a decided decision
      const result = await decisionManager.recordDecision({
        title: "Final Decision",
        decision: "This is final",
        rationale: "No changes needed",
        status: "decided",
      })

      expect(result.ok).toBe(true)
      const decisionId = result.ok ? result.value.id : ""

      // Try invalid transition: decided → proposed (not allowed)
      const invalidResult = await decisionManager.updateStatus(decisionId, "proposed")
      expect(invalidResult.ok).toBe(false)
      if (!invalidResult.ok) {
        expect(invalidResult.error.type).toBe("invalid_transition")
      }
    })

    test("duplicate decision title rejected", async () => {
      await decisionManager.recordDecision({
        title: "Unique Decision",
        decision: "First decision",
        rationale: "First rationale",
      })

      const duplicate = await decisionManager.recordDecision({
        title: "Unique Decision",
        decision: "Duplicate decision",
        rationale: "Duplicate rationale",
      })

      expect(duplicate.ok).toBe(false)
      if (!duplicate.ok) {
        expect(duplicate.error.type).toBe("already_exists")
      }
    })
  })

  describe("Research Management Integration", () => {
    test("create project → create research → verify in index", async () => {
      const result = await researchManager.createResearch({
        title: "Authentication Patterns",
        content: "# Authentication Patterns\n\nResearch on auth patterns...",
        summary: "Analysis of OAuth2, SAML, and OIDC for enterprise SSO",
        keyFindings: [
          "OAuth2 with PKCE is best for SPAs",
          "SAML still required for enterprise SSO",
        ],
      })

      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(result.value.title).toBe("Authentication Patterns")
        expect(result.value.summary).toContain("OAuth2")
        expect(result.value.keyFindings?.length).toBe(2)
      }

      // Verify in index
      const entries = researchManager.list()
      expect(entries.length).toBe(1)
      expect(entries[0].title).toBe("Authentication Patterns")
    })

    test("research linked to issues", async () => {
      const issueId = `${projectId}.research-task`

      await researchManager.createResearch({
        title: "Issue Research",
        content: "# Research for Issue\n\nFindings...",
        summary: "Research findings for the issue",
        sourceIssue: issueId,
      })

      // Retrieve by issue
      const issueResearch = researchManager.getByIssue(issueId)
      expect(issueResearch.length).toBe(1)
      expect(issueResearch[0].sourceIssue).toBe(issueId)
    })

    test("custom research path (external storage)", async () => {
      // Create research manager with custom path
      const externalResearchDir = path.join(fixture.testDir, "external-research")
      await fs.mkdir(externalResearchDir, { recursive: true })

      const log = createMockLogger()
      const externalResearchManager = new ResearchManager(
        projectDir,
        artifactRegistry,
        log,
        externalResearchDir
      )
      await externalResearchManager.load()

      const result = await externalResearchManager.createResearch({
        title: "External Research",
        content: "# External Research\n\nStored externally...",
        summary: "Research stored in external location",
      })

      expect(result.ok).toBe(true)
      if (result.ok) {
        expect(result.value.absolutePath).toContain("external-research")
      }

      // Verify file exists in external location
      const files = await fs.readdir(externalResearchDir)
      expect(files.some((f) => f.includes("external-research"))).toBe(true)
    })

    test("research updates (summary, key findings)", async () => {
      const createResult = await researchManager.createResearch({
        title: "Updatable Research",
        content: "# Research\n\nInitial content...",
        summary: "Initial summary",
        keyFindings: ["Finding 1"],
      })

      expect(createResult.ok).toBe(true)
      const researchId = createResult.ok ? createResult.value.id : ""

      // Update the research
      const updateResult = await researchManager.updateResearch(researchId, {
        summary: "Updated summary with more details",
        keyFindings: ["Finding 1", "Finding 2", "Finding 3"],
      })

      expect(updateResult.ok).toBe(true)
      if (updateResult.ok) {
        expect(updateResult.value.summary).toBe("Updated summary with more details")
        expect(updateResult.value.keyFindings?.length).toBe(3)
      }

      // Verify update persisted
      const entry = researchManager.getById(researchId)
      expect(entry?.summary).toBe("Updated summary with more details")
    })

    test("research file created on disk", async () => {
      await researchManager.createResearch({
        title: "Disk Test Research",
        content: "# Disk Test\n\nContent for disk test...",
        summary: "Testing disk persistence",
      })

      const researchDir = path.join(projectDir, "research")
      const files = await fs.readdir(researchDir)
      const researchFile = files.find((f) => f.includes("disk-test-research"))
      expect(researchFile).toBeDefined()

      const content = await fs.readFile(path.join(researchDir, researchFile!), "utf-8")
      expect(content).toContain("# Disk Test")
      expect(content).toContain("Content for disk test")
    })

    test("duplicate research title rejected", async () => {
      await researchManager.createResearch({
        title: "Unique Research",
        content: "# Research\n\nContent...",
        summary: "First research",
      })

      const duplicate = await researchManager.createResearch({
        title: "Unique Research",
        content: "# Research\n\nDifferent content...",
        summary: "Duplicate research",
      })

      expect(duplicate.ok).toBe(false)
      if (!duplicate.ok) {
        expect(duplicate.error.type).toBe("already_exists")
      }
    })
  })

  describe("Cross-Feature Integration", () => {
    test("complete workflow: research → decision → artifact → session capture", async () => {
      // Step 1: Create research
      const researchResult = await researchManager.createResearch({
        title: "API Design Research",
        content: "# API Design Research\n\nAnalysis of REST vs GraphQL...",
        summary: "Comparison of REST and GraphQL for our API",
        keyFindings: ["REST is simpler", "GraphQL better for complex queries"],
        sourceIssue: `${projectId}.1`,
      })
      expect(researchResult.ok).toBe(true)
      const researchId = researchResult.ok ? researchResult.value.id : ""

      // Step 2: Record decision based on research
      const decisionResult = await decisionManager.recordDecision({
        title: "API Protocol Choice",
        decision: "Use REST for public API, GraphQL for internal",
        rationale: "Balance simplicity for external consumers with flexibility for internal use",
        sourceResearch: [researchId],
        relatedIssues: [`${projectId}.1`],
      })
      expect(decisionResult.ok).toBe(true)

      // Step 3: Register additional artifact (implementation doc)
      const artifactResult = await artifactRegistry.register({
        type: "documentation",
        title: "API Implementation Guide",
        path: "docs/api-implementation.md",
        absolutePath: path.join(projectDir, "docs/api-implementation.md"),
        external: false,
        summary: "Guide for implementing the API based on decisions",
      })
      expect(artifactResult.ok).toBe(true)
      const artifactId = artifactResult.ok ? artifactResult.value.id : ""

      // Step 4: Capture session summarizing the work
      const sessionResult = await sessionManager.captureSession({
        sessionId: "ses_workflow_complete",
        summary: "Completed API design research and made protocol decision.",
        keyPoints: [
          "Researched REST vs GraphQL tradeoffs",
          "Decided on hybrid approach",
          "Created implementation guide",
        ],
        decisionsMade: ["API Protocol Choice"],
        artifactsCreated: [researchId, artifactId],
      })
      expect(sessionResult.ok).toBe(true)

      // Verify all components are linked
      const research = researchManager.getById(researchId)
      expect(research).not.toBeNull()

      const decisions = decisionManager.list()
      expect(decisions.length).toBe(1)
      expect(decisions[0].sourceResearch).toContain(researchId)

      const artifacts = artifactRegistry.list()
      expect(artifacts.length).toBe(3) // research + decision + documentation

      const sessions = sessionManager.getRecentSessions(1)
      expect(sessions[0].artifactsCreated).toContain(researchId)
    })

    test("context injection includes all components", async () => {
      // Create various artifacts
      await researchManager.createResearch({
        title: "Context Test Research",
        content: "# Research\n\nContent...",
        summary: "Research for context test",
      })

      await decisionManager.recordDecision({
        title: "Context Test Decision",
        decision: "Test decision",
        rationale: "Test rationale",
      })

      await decisionManager.addPendingDecision({
        question: "Pending question for context?",
      })

      await sessionManager.captureSession({
        sessionId: "ses_context_test",
        summary: "Session for context test",
        keyPoints: ["Testing context injection"],
      })

      // Verify all data is accessible
      const research = researchManager.list()
      const decisions = decisionManager.list()
      const pending = decisionManager.getPending()
      const sessions = sessionManager.getRecentSessions(10)

      expect(research.length).toBe(1)
      expect(decisions.length).toBe(1)
      expect(pending.length).toBe(1)
      expect(sessions.length).toBe(1)
    })

    test("focus context shows recent sessions, pending decisions, artifacts", async () => {
      // Create multiple sessions
      await sessionManager.captureSession({
        sessionId: "ses_focus_1",
        summary: "First focus session",
        keyPoints: ["Point 1"],
      })

      await sessionManager.captureSession({
        sessionId: "ses_focus_2",
        summary: "Second focus session",
        keyPoints: ["Point 2"],
      })

      await sessionManager.captureSession({
        sessionId: "ses_focus_3",
        summary: "Third focus session",
        keyPoints: ["Point 3"],
      })

      // Add pending decisions
      await decisionManager.addPendingDecision({
        question: "Focus pending 1?",
      })

      await decisionManager.addPendingDecision({
        question: "Focus pending 2?",
      })

      // Create artifacts
      await artifactRegistry.register({
        type: "focus-test",
        title: "Focus Artifact 1",
        path: "focus/artifact1.md",
        absolutePath: path.join(projectDir, "focus/artifact1.md"),
        external: false,
        summary: "First focus artifact",
      })

      await artifactRegistry.register({
        type: "focus-test",
        title: "Focus Artifact 2",
        path: "focus/artifact2.md",
        absolutePath: path.join(projectDir, "focus/artifact2.md"),
        external: false,
        summary: "Second focus artifact",
      })

      // Verify recent sessions (limit to 2)
      const recentSessions = sessionManager.getRecentSessions(2)
      expect(recentSessions.length).toBe(2)
      expect(recentSessions[0].id).toBe("ses_focus_3")
      expect(recentSessions[1].id).toBe("ses_focus_2")

      // Verify pending decisions
      const pending = decisionManager.getPending()
      expect(pending.length).toBe(2)

      // Verify artifacts
      const artifacts = artifactRegistry.getByType("focus-test")
      expect(artifacts.length).toBe(2)
    })

    test("artifacts registered by decision and research managers appear in registry", async () => {
      // Create research (registers artifact internally)
      await researchManager.createResearch({
        title: "Registry Test Research",
        content: "# Research\n\nContent...",
        summary: "Testing artifact registration",
      })

      // Create decision (registers artifact internally)
      await decisionManager.recordDecision({
        title: "Registry Test Decision",
        decision: "Test decision",
        rationale: "Test rationale",
      })

      // Both should appear in the artifact registry
      const allArtifacts = artifactRegistry.list()
      expect(allArtifacts.length).toBe(2)

      const researchArtifacts = artifactRegistry.getByType("research")
      expect(researchArtifacts.length).toBe(1)

      const decisionArtifacts = artifactRegistry.getByType("decision")
      expect(decisionArtifacts.length).toBe(1)
    })

    test("managers persist and reload correctly", async () => {
      // Create data in all managers
      await researchManager.createResearch({
        title: "Persistence Research",
        content: "# Research\n\nContent...",
        summary: "Testing persistence",
        keyFindings: ["Finding 1"],
      })

      await decisionManager.recordDecision({
        title: "Persistence Decision",
        decision: "Test decision",
        rationale: "Test rationale",
      })

      await decisionManager.addPendingDecision({
        question: "Persistence pending?",
      })

      await sessionManager.captureSession({
        sessionId: "ses_persistence",
        summary: "Persistence session",
        keyPoints: ["Testing persistence"],
        openQuestionsAdded: ["Persistence question?"],
      })

      // Create new manager instances and reload
      const log = createMockLogger()

      const newArtifactRegistry = new ArtifactRegistry(projectDir, log)
      await newArtifactRegistry.load()

      const newSessionManager = new SessionManager(projectDir, log)
      const sessionIndex = await newSessionManager.load()

      const newDecisionManager = new DecisionManager(projectDir, newArtifactRegistry, log)
      const decisionIndex = await newDecisionManager.load()

      const newResearchManager = new ResearchManager(projectDir, newArtifactRegistry, log)
      const researchIndex = await newResearchManager.load()

      // Verify all data persisted
      expect(newArtifactRegistry.list().length).toBe(2) // research + decision
      expect(sessionIndex.sessions.length).toBe(1)
      expect(sessionIndex.openQuestions).toContain("Persistence question?")
      expect(decisionIndex.decided.length).toBe(1)
      expect(decisionIndex.pending.length).toBe(1)
      expect(researchIndex.entries.length).toBe(1)
    })
  })
})
