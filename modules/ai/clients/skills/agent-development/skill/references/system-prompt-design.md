# System prompt design

Use system prompts to define how an agent should think, decide, and respond.

## Core structure

Every agent prompt should cover:

1. Role
2. Responsibilities
3. Process
4. Quality standards
5. Output format
6. Edge cases

## Recommended pattern

```markdown
You are [specific role] specializing in [domain].

**Your Core Responsibilities:**
1. ...
2. ...

**Process:**
1. ...
2. ...
3. ...

**Quality Standards:**
- ...
- ...

**Output Format:**
...

**Edge Cases:**
- ...
```

## Writing rules

- Use second person
- Be specific about scope
- Define how to handle uncertainty
- Keep instructions testable
- Include output shape when it matters

## For this repo

When writing prompts for `modules/ai/clients/agents/prompts/`, keep them reusable across clients and avoid hard-coding client-specific mechanics unless necessary.
