# Agent Permission Model Research

**Date:** 2026-03-03  
**Status:** Complete  
**Scope:** opencode-projects-plugin agent permission architecture

## Executive Summary

The opencode-projects-plugin currently uses a **prompt-based constraint system** combined with **tool disabling at the API level** to control agent behavior. There is no fine-grained permission model per agent role. The OpenCode SDK supports permission configuration, but the plugin doesn't leverage it. This research identifies the current state, SDK capabilities, and recommends a comprehensive permission model for different agent roles.

---

## 1. Current State of Agent Permissions

### 1.1 How Delegated Agents Are Configured

Delegated agents receive:

1. **System Prompt** - Role-specific instructions injected into the prompt
2. **Disabled Tools List** - Hard-coded list of tools disabled at API level
3. **Read-Only Constraint** (for reviewers) - Text constraint in prompt

#### System Prompt Structure

The plugin uses **role-based prompt templates** that differentiate behavior:

**Primary Agent Prompt:**
```
# Task: {issueId}

You are the PRIMARY agent for this task. Your role: {agent}

## Issue
{issueContext}

## Your Responsibilities
1. Complete the main work for this issue
2. Write code, make changes, implement the solution
3. Commit your changes with clear messages

## Constraints
You are running as a background delegation. The following tools are disabled:
- project-create, project-close, project-create-issue, project-update-issue, project-work-on-issue
- task, delegate (no recursive delegation)

Focus on completing your assigned role.
```

**Reviewer/Devil's Advocate Prompt:**
```
# Review Task: {issueId}

You are a REVIEWER for this task. Your role: {agent}

## Issue
{issueContext}

## Primary Agent's Work
The primary agent ({primaryAgent}) is implementing this. Your job is to:
1. Review their approach and implementation
2. Identify issues, risks, or improvements
3. Provide constructive feedback

## Worktree
The code is in an isolated worktree at: {worktreePath}
You can read files there to review the implementation.
Do NOT modify files - you are read-only.

[Devil's Advocate guidance if applicable]

## Constraints
You are running as a background delegation. The following tools are disabled:
- project-create, project-close, project-create-issue, project-update-issue, project-work-on-issue
- task, delegate (no recursive delegation)

Focus on completing your assigned role.
```

### 1.2 Tools Disabled in Delegations

**Hard-coded disabled tools** (in `delegation-manager.ts` and `discussion-coordinator.ts`):

```typescript
const DISABLED_TOOLS: Record<string, boolean> = {
  // Prevent recursive delegation
  task: false,
  delegate: false,

  // Prevent state modifications
  todowrite: false,
  plan_save: false,
  "project-create": false,
  "project-close": false,
  "project-create-issue": false,
  "project-update-issue": false,
  "project-work-on-issue": false,
}
```

These are passed to the OpenCode SDK's `session.prompt()` API:

```typescript
const result = await this.client!.session.prompt({
  path: { id: sessionId },
  body: {
    agent: delegation.agent,
    parts: [{ type: "text", text: delegation.prompt }],
    tools: DISABLED_TOOLS,  // ← Disables tools at API level
  },
})
```

### 1.3 Current Limitations

1. **No per-role tool permissions** - All delegated agents get the same disabled tools
2. **No per-agent configuration** - Permissions are not agent-specific
3. **Prompt-based constraints only** - Reviewers rely on text saying "do NOT modify files"
4. **No fine-grained control** - Can't allow specific tools for specific roles
5. **No configuration system** - Permissions are hard-coded in source

---

## 2. OpenCode SDK Support for Permissions

### 2.1 SDK Type Definitions

The OpenCode SDK defines permission infrastructure:

```typescript
/**
 * Agent-specific configuration
 */
export interface AgentConfig {
  /** Permission settings for tools */
  permission?: Record<string, PermissionEntry>
}

/**
 * Permission entry for tool access control
 */
export type PermissionEntry = "ask" | "allow" | "deny" | Record<string, "ask" | "allow" | "deny">
```

### 2.2 Permission Levels

OpenCode supports three permission levels:

| Level | Behavior | Use Case |
|-------|----------|----------|
| `"allow"` | Tool is available without prompting | Trusted operations |
| `"ask"` | User is prompted before tool use | Sensitive operations |
| `"deny"` | Tool is completely unavailable | Forbidden operations |

### 2.3 Fine-Grained Control

Permissions can be nested for command-level control:

```typescript
// Simple permission
permission: {
  "read": "allow",
  "edit": "deny"
}

// Command-level control
permission: {
  "bash": {
    "git log *": "allow",
    "rm *": "deny",
    "*": "ask"
  }
}
```

### 2.4 Configuration Integration

The OpenCode configuration system supports agent-specific permissions:

```json
{
  "agent": {
    "my-agent": {
      "description": "...",
      "mode": "primary",
      "permission": {
        "read": "allow",
        "edit": "deny",
        "bash": {
          "git *": "deny",
          "*": "allow"
        }
      }
    }
  }
}
```

### 2.5 Current Plugin Integration

The plugin's Nix configuration transforms tool permissions:

```nix
# Transform tools attrset for OpenCode config (boolean values)
# "allow" -> true, "ask"/"deny" -> false
transformTools = tools: lib.mapAttrs (_: perm: perm == "allow") tools;

# Transform agents to OpenCode JSON config format
agentConfig = lib.mapAttrs (
  _: agent:
  {
    description = agent.description;
    mode = agent.mode;
    model = resolveAlias agent.model;
    prompt = "{file:${builtins.unsafeDiscardStringContext (toString agent.prompt)}}";
  }
  // lib.optionalAttrs (agent.tools != { }) { tools = transformTools agent.tools; }
) config.hdwlinux.ai.agent.agents;
```

**Current limitation:** The plugin only transforms boolean tool permissions, not the full `PermissionEntry` type. It doesn't use the SDK's permission system for delegated agents.

---

## 3. Agent Roles and Current Behavior

### 3.1 Role Types

The plugin defines three team member roles:

```typescript
export type TeamMemberRole = "primary" | "secondary" | "devilsAdvocate"
```

**Primary Agent:**
- Implements the solution
- Can write code, make changes, commit
- Gets full implementation instructions
- Receives delegation constraints (no recursive delegation)

**Secondary Agent (Reviewer):**
- Reviews primary's work
- Can read files (including worktree)
- Cannot modify files (prompt constraint only)
- Provides feedback and identifies issues

**Devil's Advocate:**
- Special reviewer role (one per team)
- Challenges assumptions and identifies risks
- Can read files
- Cannot modify files
- Gets additional critical thinking guidance

### 3.2 Current Constraints by Role

| Role | Disabled Tools | Read-Only | Prompt Guidance |
|------|---|---|---|
| Primary | All 7 project/delegation tools | No | Implementation instructions |
| Reviewer | All 7 project/delegation tools | Yes (text only) | Review instructions |
| Devil's Advocate | All 7 project/delegation tools | Yes (text only) | Critical thinking guidance |

---

## 4. How Other OpenCode Plugins Handle Permissions

### 4.1 Research Findings

The plugin ecosystem is limited. Based on available code:

1. **No other plugins implement role-based permissions** - Most plugins don't use delegations
2. **Global permissions are standard** - Permissions are set at the OpenCode config level
3. **Tool disabling is common** - Plugins disable tools via the `session.prompt()` API
4. **Prompt constraints are primary** - Most rely on text instructions rather than API-level enforcement

### 4.2 Best Practices Observed

From the codebase and OpenCode configuration:

1. **Principle of Least Privilege** - Only enable what's needed
2. **Explicit Denials** - Deny dangerous operations (git, sudo, reboot)
3. **Role-Based Guidance** - Different prompts for different roles
4. **Layered Constraints** - Combine API-level disabling with prompt guidance

---

## 5. Recommended Permission Model

### 5.1 Design Principles

1. **Explicit over implicit** - All permissions should be explicitly configured
2. **Role-based** - Permissions tied to agent roles, not individual agents
3. **Layered enforcement** - Combine API-level disabling with prompt constraints
4. **Configurable** - Permissions should be configurable, not hard-coded
5. **Fail-safe** - Default to deny, explicitly allow what's needed

### 5.2 Proposed Role-Based Permission Sets

#### Primary Agent Permissions

**Purpose:** Implement solutions with full code modification capabilities

**Allowed Tools:**
- All read tools (read, glob, grep, codebase-retrieval, webfetch)
- All write tools (edit, bash with restrictions)
- VCS tools (bash git/jj commands)
- Testing tools (bash for test runners)

**Denied Tools:**
- project-* tools (prevent state modification)
- task, delegate (prevent recursive delegation)
- todowrite, plan_save (prevent planning state changes)
- Dangerous bash commands (sudo, reboot, shutdown, rm -rf)

**Configuration:**
```json
{
  "agent": {
    "primary-agent-template": {
      "permission": {
        "read": "allow",
        "edit": "allow",
        "glob": "allow",
        "grep": "allow",
        "codebase-retrieval": "allow",
        "webfetch": "allow",
        "bash": {
          "git *": "allow",
          "jj *": "allow",
          "npm *": "allow",
          "cargo *": "allow",
          "python *": "allow",
          "sudo *": "deny",
          "reboot *": "deny",
          "shutdown *": "deny",
          "rm -rf *": "deny",
          "*": "allow"
        },
        "project-create": "deny",
        "project-close": "deny",
        "project-create-issue": "deny",
        "project-update-issue": "deny",
        "project-work-on-issue": "deny",
        "task": "deny",
        "delegate": "deny",
        "todowrite": "deny",
        "plan_save": "deny"
      }
    }
  }
}
```

#### Reviewer/Secondary Agent Permissions

**Purpose:** Review code and provide feedback without modifying

**Allowed Tools:**
- All read tools (read, glob, grep, codebase-retrieval, webfetch)
- No write tools (edit, bash)
- No VCS tools

**Denied Tools:**
- All write tools
- All project-* tools
- task, delegate
- todowrite, plan_save

**Configuration:**
```json
{
  "agent": {
    "reviewer-agent-template": {
      "permission": {
        "read": "allow",
        "edit": "deny",
        "glob": "allow",
        "grep": "allow",
        "codebase-retrieval": "allow",
        "webfetch": "allow",
        "bash": "deny",
        "project-create": "deny",
        "project-close": "deny",
        "project-create-issue": "deny",
        "project-update-issue": "deny",
        "project-work-on-issue": "deny",
        "task": "deny",
        "delegate": "deny",
        "todowrite": "deny",
        "plan_save": "deny"
      }
    }
  }
}
```

#### Devil's Advocate Permissions

**Purpose:** Critical analysis and risk identification (same as reviewer)

**Same as Reviewer** - Devil's advocate is a reviewer with additional prompt guidance, not different permissions.

### 5.3 Implementation Strategy

#### Phase 1: Configuration System

1. Create a permission configuration schema in the plugin
2. Define role-based permission templates
3. Allow per-project overrides
4. Store in `opencode-projects.json`

```typescript
// src/config/permission-schema.ts
export const PermissionTemplateSchema = z.object({
  role: z.enum(["primary", "reviewer", "devilsAdvocate"]),
  permissions: z.record(z.string(), z.union([
    z.enum(["allow", "ask", "deny"]),
    z.record(z.string(), z.enum(["allow", "ask", "deny"]))
  ]))
})

export type PermissionTemplate = z.infer<typeof PermissionTemplateSchema>
```

#### Phase 2: Permission Manager

1. Create a `PermissionManager` to resolve permissions by role
2. Support role-based templates with project overrides
3. Generate OpenCode permission config

```typescript
// src/execution/permission-manager.ts
export class PermissionManager {
  resolvePermissions(role: TeamMemberRole, projectId?: string): Record<string, PermissionEntry> {
    // Get base template for role
    // Apply project overrides if any
    // Return merged permissions
  }
}
```

#### Phase 3: Integration with Delegation

1. Update `DelegationManager` to use `PermissionManager`
2. Pass role-based permissions to `session.prompt()`
3. Remove hard-coded `DISABLED_TOOLS`

```typescript
// In delegation-manager.ts
const permissions = this.permissionManager.resolvePermissions(delegation.role)
const result = await this.client!.session.prompt({
  path: { id: sessionId },
  body: {
    agent: delegation.agent,
    parts: [{ type: "text", text: delegation.prompt }],
    tools: permissions,  // ← Role-based permissions
  },
})
```

#### Phase 4: Nix Configuration

1. Add permission templates to `hdwlinux.ai.agent` module
2. Allow per-agent permission overrides
3. Generate plugin configuration

```nix
# In hdwlinux/modules/ai/agent/default.nix
permissions = lib.mkOption {
  description = "Permission templates for agent roles";
  type = lib.types.attrsOf permissionTemplateType;
  default = {
    primary = { /* ... */ };
    reviewer = { /* ... */ };
    devilsAdvocate = { /* ... */ };
  };
};
```

### 5.4 Rationale for Recommendations

**Why role-based instead of per-agent?**
- Simpler to manage and reason about
- Agents can be swapped without permission changes
- Aligns with team composition logic

**Why keep prompt constraints?**
- Defense in depth - multiple layers of enforcement
- Helps agents understand their role
- Catches mistakes before API enforcement

**Why allow bash for primary but not reviewers?**
- Primary needs to run tests, build, commit
- Reviewers only need to read and analyze
- Reduces risk of accidental modifications

**Why deny project-* tools?**
- Prevents delegated agents from creating new work
- Prevents state modification during delegation
- Maintains clear separation of concerns

---

## 6. Technical Constraints and Tradeoffs

### 6.1 Constraints

1. **OpenCode SDK Limitations**
   - Permission system is global + per-agent, not per-session
   - Can't change permissions mid-delegation
   - No dynamic permission evaluation

2. **Plugin Architecture**
   - Delegations are fire-and-forget (no real-time control)
   - Can't revoke permissions after delegation starts
   - Limited visibility into agent tool usage

3. **Prompt-Based Constraints**
   - Agents can ignore text constraints
   - No enforcement mechanism
   - Relies on agent compliance

### 6.2 Tradeoffs

| Aspect | Over-Restriction | Under-Restriction |
|--------|---|---|
| **Risk** | Agent can't do its job | Agent modifies things it shouldn't |
| **Example** | Deny bash → can't run tests | Allow bash → could delete files |
| **Mitigation** | Test with real agents | Careful command patterns + prompt guidance |
| **Recommendation** | **Prefer this** | Avoid this |

**Decision:** Err on the side of restriction. It's better to discover missing permissions during testing than to discover security issues in production.

### 6.3 Risks of Over-Restriction

1. **Primary agent can't run tests** - If bash is too restricted
2. **Reviewer can't read files** - If read is denied
3. **Agent fails silently** - If tool is denied but agent expects it

**Mitigation:**
- Test with real agents before deployment
- Provide clear error messages when tools are denied
- Document required permissions per agent type

### 6.4 Risks of Under-Restriction

1. **Reviewer modifies code** - If edit is allowed
2. **Agent creates new issues** - If project-create is allowed
3. **Agent deletes files** - If bash rm is allowed

**Mitigation:**
- Explicit deny for dangerous operations
- Prompt constraints as secondary layer
- Regular audits of permission usage

---

## 7. Open Questions and Tradeoffs to Resolve

### 7.1 Before Implementation

1. **Should permissions be configurable per-project?**
   - Pro: Different projects have different needs
   - Con: Adds complexity, harder to reason about
   - **Recommendation:** Start with global role templates, add per-project overrides later

2. **Should we support "ask" permission level?**
   - Pro: Allows user confirmation for sensitive operations
   - Con: Breaks fire-and-forget delegation model
   - **Recommendation:** Not for delegations (no user interaction), but useful for interactive sessions

3. **Should devil's advocate have different permissions than reviewer?**
   - Pro: Could allow more aggressive analysis tools
   - Con: Same read-only constraint applies
   - **Recommendation:** Same permissions, different prompt guidance

4. **How should we handle permission errors?**
   - Pro: Clear error messages help debugging
   - Con: Agents might retry or work around
   - **Recommendation:** Log permission denials, include in delegation result

5. **Should we audit tool usage?**
   - Pro: Helps identify permission issues
   - Con: Adds logging overhead
   - **Recommendation:** Log denied tools, optional detailed audit trail

### 7.2 Future Enhancements

1. **Dynamic permissions based on issue context**
   - Allow different permissions for different issue types
   - Example: Security issues get more restrictive permissions

2. **Permission inheritance and composition**
   - Define base permissions, compose with role-specific overrides
   - Reduce duplication

3. **Capability-based permissions**
   - Instead of tool names, define capabilities (e.g., "can_modify_code")
   - Map capabilities to tools

4. **Audit and compliance**
   - Track which tools were used by which agents
   - Generate compliance reports

---

## 8. Recommended Next Steps

### 8.1 Immediate (Sprint 1)

1. **Create permission configuration schema**
   - Define `PermissionTemplate` type
   - Create default templates for each role
   - Add to `config-schema.ts`

2. **Implement `PermissionManager`**
   - Resolve permissions by role
   - Support project overrides
   - Generate OpenCode permission config

3. **Update `DelegationManager`**
   - Use `PermissionManager` instead of hard-coded `DISABLED_TOOLS`
   - Pass role-based permissions to `session.prompt()`

4. **Write tests**
   - Test permission resolution
   - Test delegation with different roles
   - Test permission enforcement

### 8.2 Short-term (Sprint 2)

1. **Add Nix configuration**
   - Define permission templates in `hdwlinux.ai.agent`
   - Allow per-agent overrides
   - Generate plugin configuration

2. **Documentation**
   - Document permission model
   - Provide examples for each role
   - Document how to customize permissions

3. **Testing with real agents**
   - Test primary agent with various tasks
   - Test reviewer with code review tasks
   - Verify permissions work as expected

### 8.3 Long-term (Future)

1. **Per-project permission overrides**
2. **Audit and compliance tracking**
3. **Dynamic permissions based on issue context**
4. **Capability-based permission system**

---

## 9. Summary

### Current State
- **Prompt-based constraints** with hard-coded tool disabling
- **No per-role configuration** - all delegated agents get same disabled tools
- **No leverage of OpenCode SDK** permission system
- **Relies on agent compliance** with text constraints

### OpenCode SDK Capabilities
- **Supports role-based permissions** via `AgentConfig.permission`
- **Supports fine-grained control** with command patterns
- **Three permission levels:** allow, ask, deny
- **Not currently used** by the plugin for delegations

### Recommended Model
- **Role-based permission templates** (primary, reviewer, devilsAdvocate)
- **Explicit deny for dangerous operations** (sudo, reboot, rm -rf)
- **Allow read tools for all roles**, write tools only for primary
- **Configurable via plugin config**, with Nix integration
- **Layered enforcement:** API-level + prompt constraints

### Key Tradeoffs
- **Prefer over-restriction** (agent can't do job) over under-restriction (agent modifies things it shouldn't)
- **Start simple** (global role templates) and add complexity later (per-project overrides)
- **Combine API enforcement with prompt guidance** for defense in depth

### Implementation Path
1. Create permission configuration schema
2. Implement `PermissionManager`
3. Update `DelegationManager` to use role-based permissions
4. Add Nix configuration
5. Test with real agents
6. Document and iterate

---

## Appendix: Code References

### Key Files
- `src/execution/delegation-manager.ts` - Where tools are disabled
- `src/execution/team-manager.ts` - Where roles are assigned
- `src/utils/prompts/templates/team-member.ts` - Role-specific prompts
- `src/utils/opencode-sdk/index.ts` - SDK type definitions
- `hdwlinux/modules/programs/opencode/default.nix` - OpenCode configuration
- `hdwlinux/modules/ai/agent/default.nix` - Agent configuration

### Related Issues
- Permission model design
- Configuration system implementation
- Nix integration
- Testing and validation
