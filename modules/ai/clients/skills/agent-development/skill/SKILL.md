---
name: agent-development
description: Use this skill when the user asks to create an agent, add a subagent, write a system prompt, define triggering conditions, choose tools or model settings, or adapt an agent format for a different client.
---

# Agent Development

Use this skill to design agents that handle complex, multi-step work with a clear role, prompt, and trigger logic.

## Overview

Agents are autonomous subprocesses for structured work. Commands are for user-initiated actions. A good agent has three parts:

1. A narrow role
2. Clear trigger conditions
3. A system prompt that defines behavior and output

## This repo's format

In this Nix setup, agent definitions are usually split across:

1. `modules/ai/clients/agents/prompts/<agent>.md` for the system prompt
2. `modules/ai/clients/agents/default.nix` for metadata like model, color, temperature, tools, and prompt path

If you are targeting another client, map the same concepts to that client's agent file format.

## Agent structure

### Portable metadata

When a client supports agent frontmatter, the equivalent shape is:

```markdown
---
name: agent-name
description: Use this agent when ... Examples:
color: blue
tools: ["Read", "Write", "Grep"]
---
```

### System prompt

Write the prompt in second person and keep it specific:

```markdown
You are a [role] specializing in [domain].

**Your Core Responsibilities:**
1. ...
2. ...

**Analysis Process:**
1. ...
2. ...

**Output Format:**
...
```

## Frontmatter guidance

### Name

Use a lowercase, hyphenated identifier.

### Description

Use the description to define when the agent should trigger. Include 2 to 4 concrete examples and cover alternate phrasings of the same intent.

### Model

Prefer the smallest capable model for the job. Use the default model when the client supports inheritance.

### Color

Use color as a quick visual hint for the agent's role.

### Tools

Limit tools to the minimum required. Read-only agents should not get write access.

## Prompt design

Include these parts when useful:

1. Responsibilities
2. Analysis process
3. Quality standards
4. Output format
5. Edge cases

Keep the prompt direct, testable, and specific to the agent's job.

## Creating agents

### AI-assisted generation

Use a prompt like this:

```text
Create an agent configuration for: "[request]"

Return:
- identifier
- whenToUse
- systemPrompt
- model
- color
- tools
```

Then adapt the result to the target client's format.

### Manual creation

1. Choose the agent's narrow job
2. Write trigger examples
3. Draft the system prompt
4. Pick model, color, and tools
5. Wire it into the client's agent configuration

## Validation rules

1. The agent name should be unambiguous
2. The description should make triggering obvious
3. The prompt should define output format
4. The tool set should be minimal
5. The agent should fail closed on unclear requests

## Implementation workflow in this repo

1. Add the prompt file under `modules/ai/clients/agents/prompts/`
2. Add or update the agent metadata in `modules/ai/clients/agents/default.nix`
3. Keep the prompt portable so it can be reused by multiple clients
4. Verify the agent trigger wording matches the intended use

Focus on clarity over cleverness. A good agent is specific enough to be useful and narrow enough to be reliable.

## References

- `references/system-prompt-design.md`
- `references/triggering-examples.md`
- `references/agent-creation-system-prompt.md`
