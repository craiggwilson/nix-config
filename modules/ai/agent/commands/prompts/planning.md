# Planning Command

Load the `planning` skill and execute the appropriate planning workflow based on the command arguments.

**Arguments**: $ARGUMENTS

The first argument specifies the planning phase or operation:

- **init** - Initialize a new planning cycle (roadmap/project/task)
- **research** - Conduct focused research on a topic
- **continue** - Resume an in-progress planning cycle

Additional arguments depend on the phase (see skill references for details).

## Process

1. Load the `planning` skill
2. Parse the command arguments to determine the phase
3. Load the appropriate reference guide from the skill
4. Execute the planning workflow for that phase

## Skill Loading

**IMPORTANT**: Always load the `planning` skill at the start of this command:

```
I'm loading the planning skill to guide this workflow...
```

The skill provides:
- Complete planning methodology
- Reference guides for each phase
- Subagent delegation patterns
- Version control integration
- Artifact templates and quality criteria

## Phase Routing

Based on the first argument:

### `/planning init [roadmap|project|task] [focus]`
Load `references/init.md` and execute initialization workflow.

### `/planning research <topic>`
Load `references/research.md` and conduct research.

### `/planning continue [focus]`
Load `references/continue.md` and resume planning.

## Example Usage

```
/planning init project API-redesign
/planning research authentication-patterns
/planning continue risk-assessment
```

**Now load the planning skill and begin the requested workflow.**
