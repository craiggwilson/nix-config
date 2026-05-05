# Agent creation system prompt

Use this prompt when generating a new agent configuration.

```text
Create an agent configuration based on this request: "[request]"

Requirements:
1. Extract the core intent and responsibilities.
2. Design an expert persona for the domain.
3. Write a system prompt with clear boundaries, process steps, edge cases, and output format.
4. Create a concise identifier using lowercase letters, numbers, and hyphens.
5. Write a description that explains when the agent should be used.
6. Include any model, color, and tool settings needed by the target client.

Return JSON with:
{
  "identifier": "agent-name",
  "whenToUse": "Use this agent when...",
  "systemPrompt": "You are...",
  "model": "inherit",
  "color": "blue",
  "tools": ["Read", "Write", "Grep"]
}
```

## Mapping to this repo

After generating the agent, translate it into the local Nix layout under `modules/ai/clients/agents/`.
