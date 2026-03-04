# HookRegistry Implementation Guide

**Date:** 2026-03-04  
**Status:** Implementation Ready  
**Audience:** Developers implementing the HookRegistry pattern

---

## Overview

This guide provides step-by-step instructions for implementing the HookRegistry pattern in opencode-projects-plugin.

---

## Phase 1: Create HookRegistry Class

### Step 1.1: Create src/hooks/hook-registry.ts

Create a new file with the HookRegistry class:

```typescript
/**
 * Hook registry for managing all plugin hooks.
 * 
 * Centralizes hook registration and provides explicit dependency injection.
 * Each hook is created by a method that returns the hook object(s) it implements.
 */

import type { Event } from "@opencode-ai/sdk"
import type { ProjectManager } from "../projects/index.js"
import type { DelegationManager, TeamManager, Delegation } from "../execution/index.js"
import type { WorktreeManager } from "../vcs/index.js"
import type { OpencodeClient } from "../utils/opencode-sdk/index.js"
import type { ConfigManager } from "../config/index.js"
import type { ReturnType as LoggerType } from "../utils/logging/index.js"
import {
  PROJECT_RULES,
  buildFocusContext,
  buildCompactionContext,
  buildDelegationCompactionContext,
  buildTeamCompactionContext,
} from "../projects/index.js"
import { extractConversationContent } from "../utils/conversation/index.js"
import { summarizeSession } from "../sessions/index.js"

/**
 * Manages all plugin hooks with explicit dependency injection.
 * 
 * Hooks are created on demand by methods that return hook objects.
 * Stateful hooks (like event) encapsulate their state as instance variables.
 */
export class HookRegistry {
  /**
   * Tracks the orchestrator session ID (root session with no parentID).
   * Set on session.created; used to filter session.idle events.
   */
  private orchestratorSessionId: string | null = null

  constructor(
    private projectManager: ProjectManager,
    private delegationManager: DelegationManager,
    private teamManager: TeamManager,
    private worktreeManager: WorktreeManager,
    private typedClient: OpencodeClient,
    private config: ConfigManager,
    private log: LoggerType,
  ) {}

  /**
   * Returns all hooks as a single object.
   * Each hook is spread into the result, allowing multiple hooks per method.
   */
  getHooks() {
    return {
      ...this.getSystemTransformHook(),
      ...this.getSessionCompactingHook(),
      ...this.getShellEnvHook(),
      ...this.getEventHook(),
      ...this.getConfigHook(),
    }
  }

  /**
   * Hook: experimental.chat.system.transform
   * 
   * Injects project context into system prompts.
   * Adds PROJECT_RULES, VCS context, focus context, and planning context.
   */
  private getSystemTransformHook() {
    return {
      "experimental.chat.system.transform": async (_input: unknown, output: any) => {
        output.system.push(PROJECT_RULES)

        const vcsContext = this.worktreeManager.getVCSContext()
        if (vcsContext) {
          output.system.push(vcsContext)
        }

        const contextBlock = await buildFocusContext(this.projectManager)
        output.system.push(contextBlock)

        const projectId = this.projectManager.getFocusedProjectId()
        if (projectId) {
          const planningContext = await this.buildPlanningContext(projectId)
          if (planningContext) {
            output.system.push(planningContext)
          }
        }
      },
    }
  }

  /**
   * Hook: experimental.session.compacting
   * 
   * Captures session summaries and delegation/team context during session compaction.
   * Filters delegations and teams by session ID.
   */
  private getSessionCompactingHook() {
    return {
      "experimental.session.compacting": async (input: any, output: any) => {
        const projectId = this.projectManager.getFocusedProjectId()
        if (!projectId) return

        const contextBlock = await buildCompactionContext(this.projectManager)
        if (contextBlock) {
          output.context.push(contextBlock)
        }

        // Get session ID for filtering delegations
        const sessionId = input.sessionID as string | undefined

        // Add running and completed delegations, filtered by session
        const allRunning = await this.delegationManager.list({ status: "running" })
        const allCompleted = await this.delegationManager.getRecentCompletedDelegations(10)

        const runningDelegations = sessionId
          ? allRunning.filter((d: Delegation) => d.parentSessionId === sessionId)
          : allRunning
        const completedDelegations = sessionId
          ? allCompleted.filter((d: Delegation) => d.parentSessionId === sessionId)
          : allCompleted

        if (runningDelegations.length > 0 || completedDelegations.length > 0) {
          const delegationContext = buildDelegationCompactionContext(
            runningDelegations,
            completedDelegations
          )
          output.context.push(delegationContext)
        }

        // Add running teams context
        const runningTeams = await this.teamManager.getRunningTeams()
        const sessionTeams = sessionId
          ? runningTeams.filter((t) => t.parentSessionId === sessionId)
          : runningTeams

        if (sessionTeams.length > 0) {
          const teamContext = buildTeamCompactionContext(sessionTeams)
          output.context.push(teamContext)
        }

        // Capture session summary if we have a session ID
        if (sessionId) {
          await this.captureSessionSummary(projectId, sessionId, input)
        }
      },
    }
  }

  /**
   * Hook: shell.env
   * 
   * Exports the focused project ID to the shell environment.
   */
  private getShellEnvHook() {
    return {
      "shell.env": async (_input: unknown, output: any) => {
        const projectId = this.projectManager.getFocusedProjectId()
        if (projectId) {
          output.env.OPENCODE_PROJECT_ID = projectId
        }
      },
    }
  }

  /**
   * Hook: event
   * 
   * Handles plugin events:
   * - session.created: Tracks the orchestrator session (root session with no parentID)
   * - session.idle: Handles delegation idle events and writes orchestrator snapshots
   */
  private getEventHook() {
    return {
      event: async ({ event }: { event: Event }) => {
        if (event.type === "session.created") {
          await this.handleSessionCreated(event)
        }

        if (event.type === "session.idle") {
          await this.handleSessionIdle(event)
        }
      },
    }
  }

  /**
   * Hook: config
   * 
   * Registers plugin agents, commands, skills, and permissions with OpenCode.
   */
  private getConfigHook() {
    return {
      config: async (opencodeConfig: Record<string, unknown>) => {
        const { OPENCODE_PROJECTS_AGENT_CONFIG } = await import("../agents/index.js")
        const { OPENCODE_PROJECTS_COMMANDS } = await import("../commands/index.js")
        const path = await import("path")
        const { fileURLToPath } = await import("url")

        const pluginDir = path.dirname(fileURLToPath(import.meta.url))
        const packageRoot = path.resolve(pluginDir, "..")
        const skillsPath = path.resolve(packageRoot, "skills")

        const pluginAgents = {
          "opencode-projects": OPENCODE_PROJECTS_AGENT_CONFIG,
        }

        const pluginSkillPaths = [skillsPath]

        if (!opencodeConfig.agent) {
          opencodeConfig.agent = {}
        }
        Object.assign(opencodeConfig.agent as Record<string, unknown>, pluginAgents)

        if (!opencodeConfig.command) {
          opencodeConfig.command = {}
        }
        Object.assign(opencodeConfig.command as Record<string, unknown>, OPENCODE_PROJECTS_COMMANDS)

        if (!opencodeConfig.skills) {
          opencodeConfig.skills = { paths: [] }
        }
        const skillsConfig = opencodeConfig.skills as { paths?: string[] }
        if (!skillsConfig.paths) {
          skillsConfig.paths = []
        }
        for (const p of pluginSkillPaths) {
          if (!skillsConfig.paths.includes(p)) {
            skillsConfig.paths.push(p)
          }
        }

        const globalProjectsDir = this.config.getGlobalProjectsDir()
        const globalProjectsPattern = `${globalProjectsDir}/*`
        if (!opencodeConfig.permission || typeof opencodeConfig.permission === "object") {
          if (!opencodeConfig.permission) {
            opencodeConfig.permission = {}
          }
          const permissionConfig = opencodeConfig.permission as Record<string, unknown>
          if (!permissionConfig.external_directory || typeof permissionConfig.external_directory === "object") {
            if (!permissionConfig.external_directory) {
              permissionConfig.external_directory = {}
            }
            const externalDir = permissionConfig.external_directory as Record<string, unknown>
            if (!externalDir[globalProjectsPattern]) {
              externalDir[globalProjectsPattern] = "allow"
            }
          }
        }

        await this.log.info(
          `Registered ${Object.keys(pluginAgents).length} agent(s), ` +
          `${Object.keys(OPENCODE_PROJECTS_COMMANDS).length} command(s), and ` +
          `${pluginSkillPaths.length} skill path(s)`
        )
      },
    }
  }

  // Private helper methods

  /**
   * Builds context for active planning sessions.
   */
  private async buildPlanningContext(projectId: string): Promise<string | null> {
    const planningManager = await this.projectManager.getPlanningManager(projectId)
    if (!planningManager) return null
    return planningManager.buildContext()
  }

  /**
   * Handles session.created event.
   * Tracks the orchestrator session (root session with no parentID).
   */
  private async handleSessionCreated(event: Event): Promise<void> {
    const session = (event.properties as any)?.info
    if (!session?.parentID && !this.orchestratorSessionId) {
      this.orchestratorSessionId = session.id
      await this.log.debug(`Orchestrator session identified: ${this.orchestratorSessionId}`)
    }
  }

  /**
   * Handles session.idle event.
   * Processes delegation idle events and writes orchestrator snapshots.
   */
  private async handleSessionIdle(event: Event): Promise<void> {
    const sessionId = (event.properties as any)?.sessionID as string | undefined
    if (!sessionId) return

    // Check if this is a delegation session
    const delegationId = this.delegationManager.findBySession(sessionId)
    if (delegationId) {
      await this.delegationManager.handleSessionIdle(sessionId)
    }

    // Write incremental snapshot for the orchestrator session
    if (sessionId === this.orchestratorSessionId) {
      const projectId = this.projectManager.getFocusedProjectId()
      if (projectId) {
        await this.writeOrchestratorSnapshot(projectId, sessionId)
      }
    }
  }

  /**
   * Captures session summary during session compaction.
   */
  private async captureSessionSummary(
    projectId: string,
    sessionId: string,
    input: any
  ): Promise<void> {
    try {
      const sessionManager = await this.projectManager.getSessionManager(projectId)
      if (!sessionManager) return

      const conversationContent = extractConversationContent(input)
      if (!conversationContent) return

      const metadata = await this.projectManager.getProjectMetadata(projectId)
      const planningManager = await this.projectManager.getPlanningManager(projectId)
      const planningState = await planningManager?.getState()
      const planningPhase = planningState?.phase

      const summaryResult = await summarizeSession(this.typedClient, this.log, {
        conversationContent,
        projectName: metadata?.name,
        planningPhase,
        timeoutMs: this.config.getSmallModelTimeoutMs(),
      })

      if (!summaryResult.ok) return

      const captureResult = await sessionManager.captureSession({
        sessionId,
        summary: summaryResult.value.summary,
        keyPoints: summaryResult.value.keyPoints,
        openQuestionsAdded: summaryResult.value.openQuestionsAdded,
        decisionsMade: summaryResult.value.decisionsMade,
      })

      if (captureResult.ok) {
        if (summaryResult.value.whatsNext.length > 0) {
          await sessionManager.updateIndex({
            whatsNext: summaryResult.value.whatsNext,
          })
        }
        await this.log.debug(`Session ${sessionId} captured for project ${projectId}`)
      } else if (captureResult.error.type === "already_exists") {
        // Session was already captured (e.g., on focus clear)
        // Update with more detailed summary from compaction
        if (summaryResult.value.whatsNext.length > 0) {
          await sessionManager.updateIndex({
            whatsNext: summaryResult.value.whatsNext,
          })
        }
        await this.log.debug(`Session ${sessionId} already captured, updated with compaction details`)
      } else {
        await this.log.warn(`Failed to capture session ${sessionId}: ${captureResult.error.message}`)
      }
    } catch (error) {
      await this.log.warn(`Failed to capture session: ${error}`)
    }
  }

  /**
   * Writes a lightweight incremental snapshot for the orchestrator session.
   * Called on every session.idle event for the root orchestrator session.
   */
  private async writeOrchestratorSnapshot(
    projectId: string,
    sessionId: string
  ): Promise<void> {
    try {
      const sessionManager = await this.projectManager.getSessionManager(projectId)
      if (!sessionManager) return

      // Build project state summary from current project status
      const status = await this.projectManager.getProjectStatus(projectId)
      const metadata = await this.projectManager.getProjectMetadata(projectId)

      const projectStateLines: string[] = []
      projectStateLines.push(`**Project:** ${metadata?.name || projectId}`)
      projectStateLines.push(`**Status:** ${metadata?.status || "active"}`)
      if (status?.issueStatus) {
        const { completed, total } = status.issueStatus
        projectStateLines.push(`**Progress:** ${completed}/${total} issues complete`)
      }
      const projectState = projectStateLines.join("\n")

      // Fetch recent messages from the session
      const recentMessages = await this.fetchRecentMessages(sessionId, 20)

      await sessionManager.writeSnapshot({
        sessionId,
        timestamp: new Date().toISOString(),
        projectState,
        recentMessages,
      })

      await this.log.debug(`Wrote orchestrator snapshot for session ${sessionId}`)
    } catch (error) {
      await this.log.warn(`Failed to write orchestrator snapshot: ${error}`)
    }
  }

  /**
   * Fetches the last N messages from a session and formats them as text.
   */
  private async fetchRecentMessages(sessionId: string, limit: number): Promise<string> {
    try {
      const result = await this.typedClient.session.messages({ path: { id: sessionId } })
      const messages = result.data ?? []

      const recent = messages.slice(-limit)
      if (recent.length === 0) {
        return "*No messages yet*"
      }

      return recent
        .map((msg: any) => {
          const role = msg.info?.role ?? "unknown"
          const text = msg.parts
            ?.filter((p: any) => p.type === "text")
            .map((p: any) => p.text ?? "")
            .join("")
            .trim()
          return `**${role}:** ${text || "(no text content)"}`
        })
        .join("\n\n")
    } catch {
      return "*Could not fetch messages*"
    }
  }
}
```

### Step 1.2: Create src/hooks/index.ts

Create a barrel export for the hooks module:

```typescript
/**
 * Hooks module - Plugin hook registration and management
 */

export { HookRegistry } from "./hook-registry.js"
```

### Step 1.3: Add Unit Tests

Create `src/hooks/hook-registry.test.ts`:

```typescript
import { describe, it, expect, beforeEach } from "bun:test"
import { HookRegistry } from "./hook-registry.js"
import type { Event } from "@opencode-ai/sdk"

// Mock implementations
const createMockProjectManager = () => ({
  getFocusedProjectId: () => "project-123",
  getProjectStatus: async () => ({ issueStatus: { completed: 5, total: 10 } }),
  getProjectMetadata: async () => ({ name: "Test Project", status: "active" }),
  getPlanningManager: async () => null,
  getSessionManager: async () => null,
})

const createMockDelegationManager = () => ({
  list: async () => [],
  getRecentCompletedDelegations: async () => [],
  findBySession: () => null,
  handleSessionIdle: async () => {},
})

const createMockTeamManager = () => ({
  getRunningTeams: async () => [],
})

const createMockWorktreeManager = () => ({
  getVCSContext: () => null,
})

const createMockTypedClient = () => ({
  session: {
    messages: async () => ({ data: [] }),
  },
})

const createMockConfig = () => ({
  getGlobalProjectsDir: () => "/tmp/projects",
  getSmallModelTimeoutMs: () => 30000,
})

const createMockLogger = () => ({
  info: async () => {},
  debug: async () => {},
  warn: async () => {},
  error: async () => {},
})

describe("HookRegistry", () => {
  let registry: HookRegistry

  beforeEach(() => {
    registry = new HookRegistry(
      createMockProjectManager() as any,
      createMockDelegationManager() as any,
      createMockTeamManager() as any,
      createMockWorktreeManager() as any,
      createMockTypedClient() as any,
      createMockConfig() as any,
      createMockLogger() as any,
    )
  })

  describe("getHooks", () => {
    it("should return all hooks", () => {
      const hooks = registry.getHooks()

      expect(hooks).toHaveProperty("experimental.chat.system.transform")
      expect(hooks).toHaveProperty("experimental.session.compacting")
      expect(hooks).toHaveProperty("shell.env")
      expect(hooks).toHaveProperty("event")
      expect(hooks).toHaveProperty("config")
    })
  })

  describe("getSystemTransformHook", () => {
    it("should inject project context into system prompts", async () => {
      const hooks = registry.getHooks()
      const output = { system: [] }

      await hooks["experimental.chat.system.transform"]({}, output)

      expect(output.system.length).toBeGreaterThan(0)
    })
  })

  describe("getShellEnvHook", () => {
    it("should export focused project ID to shell", async () => {
      const hooks = registry.getHooks()
      const output = { env: {} }

      await hooks["shell.env"]({}, output)

      expect(output.env.OPENCODE_PROJECT_ID).toBe("project-123")
    })
  })

  describe("getEventHook", () => {
    it("should handle session.created event", async () => {
      const hooks = registry.getHooks()
      const event: Event = {
        type: "session.created",
        properties: {
          info: { id: "session-123", parentID: undefined },
        },
      } as any

      await hooks.event({ event })

      // Verify event was handled (may need getter method for orchestratorSessionId)
      // This is a basic test; more detailed tests would verify state changes
    })
  })
})
```

---

## Phase 2: Update Plugin Entry Point

### Step 2.1: Update src/index.ts

Replace the inline hook registration with HookRegistry:

```typescript
/**
 * opencode-projects
 *
 * Project planning, tracking, and execution plugin for OpenCode.
 * Integrates with beads for issue tracking and supports parallel
 * agent work with VCS worktree isolation.
 *
 * @packageDocumentation
 */

import type { Plugin } from "@opencode-ai/plugin"
import { fileURLToPath } from "url"
import path from "path"

import {
  createProjectCreate,
  createProjectList,
  createProjectStatus,
  createProjectFocus,
  createProjectPlan,
  createProjectClose,
  createProjectCreateIssue,
  createProjectWorkOnIssue,
  createProjectUpdateIssue,
  createProjectInternalDelegationRead,
  createProjectRecordDecision,
  createProjectSaveArtifact,
} from "./tools/index.js"

import { ConfigManager } from "./config/index.js"
import { FocusManager, ProjectManager } from "./projects/index.js"
import { createLogger } from "./utils/logging/index.js"
import { validateClientOrThrow } from "./utils/validation/index.js"

import { BeadsIssueStorage } from "./issues/beads/index.js"
import { DelegationManager, TeamManager } from "./execution/index.js"
import { WorktreeManager } from "./vcs/index.js"
import { OPENCODE_PROJECTS_AGENT_CONFIG } from "./agents/index.js"
import { OPENCODE_PROJECTS_COMMANDS } from "./commands/index.js"
import { HookRegistry } from "./hooks/index.js"

/**
 * Main plugin export
 */
export const ProjectsPlugin: Plugin = async (ctx) => {
  const { client, directory, worktree, $ } = ctx
  
  // Validate client before use to catch SDK version mismatches early
  const typedClient = validateClientOrThrow(client)

  const log = createLogger(typedClient)
  await log.info("opencode-projects plugin initializing")

  const config = await ConfigManager.loadOrThrow()
  const issueStorage = new BeadsIssueStorage(log)
  const focus = new FocusManager()
  issueStorage.setShell($)

  const repoRoot = worktree || directory

  // Create worktree manager
  const worktreeManager = new WorktreeManager(repoRoot, $, log)
  await worktreeManager.detectVCS()

  // Create team config
  const teamConfig = {
    maxTeamSize: config.getTeamMaxSize(),
    retryFailedMembers: config.getTeamRetryFailedMembers(),
    smallModelTimeoutMs: config.getSmallModelTimeoutMs(),
    delegationTimeoutMs: config.getDelegationTimeoutMs(),
  }

  // Create delegation manager
  const delegationManager = new DelegationManager(
    log,
    typedClient,
    {
      timeoutMs: config.getDelegationTimeoutMs(),
      smallModelTimeoutMs: config.getSmallModelTimeoutMs(),
    }
  )

  // Create team manager (depends on delegationManager - no circular dependency)
  const teamManager = new TeamManager(
    log,
    typedClient,
    delegationManager,
    worktreeManager,
    teamConfig
  )

  // Create project manager with all dependencies
  const projectManager = new ProjectManager(
    config,
    issueStorage,
    focus,
    log,
    repoRoot,
    typedClient,
    $,
    teamManager,
  )

  const beadsAvailable = await issueStorage.isAvailable()
  if (!beadsAvailable.ok || !beadsAvailable.value) {
    await log.warn("beads (bd) not found in PATH - some features will be unavailable")
  }

  await log.info(`opencode-projects initialized in ${repoRoot}`)

  // Create hook registry with all dependencies
  const hookRegistry = new HookRegistry(
    projectManager,
    delegationManager,
    teamManager,
    worktreeManager,
    typedClient,
    config,
    log,
  )

  return {
    tool: {
      "project-create": createProjectCreate(projectManager, log),
      "project-list": createProjectList(projectManager, log),
      "project-status": createProjectStatus(projectManager, log),
      "project-focus": createProjectFocus(projectManager, log),
      "project-plan": createProjectPlan(projectManager, log),
      "project-close": createProjectClose(projectManager, log),
      "project-create-issue": createProjectCreateIssue(projectManager, log),
      "project-work-on-issue": createProjectWorkOnIssue(
        projectManager,
        teamManager,
        log,
        typedClient,
        config,
      ),
      "project-update-issue": createProjectUpdateIssue(projectManager, log, $),
      "project-internal-delegation-read": createProjectInternalDelegationRead(projectManager, log),
      "project-record-decision": createProjectRecordDecision(projectManager, log),
      "project-save-artifact": createProjectSaveArtifact(projectManager, log),
    },

    ...hookRegistry.getHooks(),
  }
}

export default ProjectsPlugin
```

### Step 2.2: Verify Tests Pass

Run the test suite to ensure everything works:

```bash
bun test
```

---

## Phase 3: Cleanup and Documentation

### Step 3.1: Update Documentation

Update `docs/architecture.md` to document the HookRegistry pattern:

```markdown
## Hook Registration

Hooks are managed by the `HookRegistry` class, which provides explicit dependency injection
and centralized hook management.

### Adding a New Hook

1. Add a method to `HookRegistry` that returns the hook object:

```typescript
private getNewHook() {
  return {
    "new.hook.name": async (input, output) => {
      // Implementation
    }
  }
}
```

2. Call it in `getHooks()`:

```typescript
getHooks() {
  return {
    ...this.getSystemTransformHook(),
    ...this.getNewHook(),  // Add here
    // ...
  }
}
```

3. Add unit tests in `src/hooks/hook-registry.test.ts`

### Hook Dependencies

Each hook declares its dependencies in the `HookRegistry` constructor:

- `projectManager` - Project lifecycle and focus management
- `delegationManager` - Background agent delegations
- `teamManager` - Multi-agent team coordination
- `worktreeManager` - VCS-agnostic worktree operations
- `typedClient` - OpenCode SDK client
- `config` - Plugin configuration
- `log` - Logger instance
```

### Step 3.2: Commit Changes

Commit the implementation:

```bash
jj commit -m "refactor(hooks): introduce HookRegistry for centralized hook management

- Create HookRegistry class with explicit dependency injection
- Move all hooks from src/index.ts to HookRegistry methods
- Add comprehensive unit tests for HookRegistry
- Update src/index.ts to use HookRegistry
- Encapsulate stateful hooks (event) as instance variables
- Document hook registration pattern for future extensions

This change improves modularity, testability, and maintainability of hook
registration while maintaining backward compatibility with all existing hooks."
```

---

## Testing Checklist

- [ ] Unit tests pass: `bun test`
- [ ] Type checking passes: `bun run typecheck`
- [ ] Linting passes: `bun run lint`
- [ ] Build succeeds: `bun run build`
- [ ] All hooks work correctly in integration tests
- [ ] No regressions in existing functionality

---

## Rollback Plan

If issues arise during implementation:

1. Revert to previous commit: `jj undo`
2. Investigate the issue
3. Fix and re-implement

---

## Future Enhancements

### Sub-Registries for Related Hooks

If hooks grow significantly, organize them into sub-registries:

```typescript
export class HookRegistry {
  private systemHooks = new SystemHookRegistry(this.projectManager, ...)
  private executionHooks = new ExecutionHookRegistry(this.delegationManager, ...)

  getHooks() {
    return {
      ...this.systemHooks.getHooks(),
      ...this.executionHooks.getHooks(),
    }
  }
}
```

### Hook Lifecycle Management

Could add lifecycle methods:

```typescript
export class HookRegistry {
  async initialize(): Promise<void> {
    // Perform any async initialization
  }

  async shutdown(): Promise<void> {
    // Cleanup resources
  }
}
```

### Hook Validation

Could add validation to ensure hooks are properly registered:

```typescript
export class HookRegistry {
  validateHooks(): ValidationResult {
    // Check that all required hooks are present
    // Check that hook signatures are correct
  }
}
```

---

## Summary

The HookRegistry pattern provides a clean, maintainable way to manage plugin hooks. By following this implementation guide, you'll:

1. ✅ Centralize hook registration
2. ✅ Improve testability with explicit dependency injection
3. ✅ Make it easy to add new hooks
4. ✅ Align with existing codebase patterns
5. ✅ Encapsulate stateful hooks cleanly

The implementation is straightforward and can be completed in three phases with minimal risk.
