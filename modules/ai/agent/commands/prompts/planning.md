# Planning Command

Load the `planning` skill to establish state management framework for planning sessions.

**Arguments**: $ARGUMENTS (optional)

This command loads the planning skill, which provides a framework for:
- Loading current planning state at session start
- Tracking decisions and progress during work
- Persisting state at session end
- Investigating planning history

## What This Command Does

1. **Loads the planning skill** - Establishes state management framework
2. **Assesses current state** - Reads CONTEXT.md, PROGRESS.md, recent sessions
3. **Executes planning work** - Based on PROGRESS.md "Next Steps" or provided arguments
4. **Persists state** - Updates PROGRESS.md, creates session note, commits changes

## Skill Loading

**IMPORTANT**: Always load the `planning` skill at the start:

```
Loading planning skill for state management...
```

The skill provides:
- State loading patterns (how to read current state)
- State persistence patterns (how to save progress)
- History investigation patterns (how to trace decisions)
- Consistency patterns (how to maintain continuity)

## Usage Patterns

### Start a Planning Session
```
/planning
```
Loads skill, reads current state from PROGRESS.md, begins work on "Next Steps"

### Start with Specific Focus
```
/planning [focus-area]
```
Loads skill, reads current state, focuses on specific area (e.g., "risk assessment", "dependency mapping")

### Continue Previous Work
```
/planning continue
```
Explicit signal to resume from PROGRESS.md "Next Steps"

## What to Expect

The agent will:
1. Load the planning skill
2. Read CONTEXT.md and PROGRESS.md
3. Review recent session notes
4. State understanding of current phase and next steps
5. Execute planning work
6. Create session note documenting decisions
7. Update PROGRESS.md with new state
8. Commit with structured message
9. State what next session should do

## State Management Focus

This command emphasizes **consistency across sessions**:
- Always loads state before beginning work
- Always persists state before ending
- Tracks all decisions with rationale
- Maintains clear "Next Steps" for continuity

**Now load the planning skill and establish state management for this session.**
