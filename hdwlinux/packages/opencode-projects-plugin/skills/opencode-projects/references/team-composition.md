# Team Composition

## Team Sizes

### Single Agent (no discussion)
```json
{ "agents": ["<implementation-agent>"] }
```
Best for: Simple, well-defined tasks. Fast. No review overhead.

### Two Agents (primary + devil's advocate)
```json
{ "agents": ["<implementation-agent>", "<review-agent>"] }
```
Best for: Code changes that benefit from review. The second agent acts as devil's advocate.

### Three Agents
```json
{ "agents": ["<architecture-agent>", "<implementation-agent>", "<review-agent>"] }
```
Best for: Complex features requiring multiple perspectives. First agent is primary.

### Four+ Agents
```json
{ "agents": ["<implementation-agent>", "<review-agent>", "<security-agent>", "<docs-agent>"] }
```
Best for: Large, high-stakes changes. More discussion rounds, slower but thorough.

### Auto-Selection (recommended)
```json
{ "isolate": true }
// No agents specified — small model selects the best team
```
The auto-selector reads the issue title and description and picks 2-4 appropriate agents.

## Team Roles

### Primary (first agent listed)
- Does the main work
- Defends their approach when challenged
- Only yields to true blockers, not stylistic preferences

### Devil's Advocate (second agent in 2+ teams)
- Adversarial by design — assumes something is wrong and looks hard
- Signals CONVERGED when they've exhausted objections (not when they agree)
- Signals STUCK to veto convergence when a blocker is unresolved
- Does NOT rubber-stamp

### Reviewer (non-primary, non-devil's advocate)
- Finds blocking issues and non-blocking concerns separately
- Uses structured output: Blockers / Concerns / Verdict
- APPROVE unless true blockers exist

## Discussion Strategies

| Strategy | Rounds | Best For |
|----------|--------|----------|
| `fixedRound` | Fixed (default: 2) | Predictable, structured review |
| `dynamicRound` | 2–10 (adaptive) | Complex decisions, needs convergence |
| `realtime` | Concurrent | Live back-and-forth, primary needs feedback during work |

See [configuration reference](./configuration.md) for per-strategy settings.
