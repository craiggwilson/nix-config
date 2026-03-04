# Team Composition

## Team Sizes

**3–4 agents is the ideal team size.** Smaller teams should be the exception, not the default.

### Single Agent (use sparingly)
```json
{ "agents": ["<implementation-agent>"] }
```
Only for: Trivial, mechanical tasks with no meaningful risk of error. Avoid unless there is a specific reason — no review means no catch.

### Two Agents (use sparingly)
```json
{ "agents": ["<implementation-agent>", "<review-agent>"] }
```
Only for: Tasks where a single reviewer is clearly sufficient and a larger team would add no value. Prefer three agents unless you have a specific reason to limit to two.

### Three Agents (default sweet spot)
```json
{ "agents": ["<architecture-agent>", "<implementation-agent>", "<review-agent>"] }
```
Best for: Most tasks. Multiple perspectives, meaningful review, manageable overhead. First agent is primary.

### Four Agents (high-stakes or complex)
```json
{ "agents": ["<implementation-agent>", "<review-agent>", "<security-agent>", "<docs-agent>"] }
```
Best for: Large, high-stakes, or cross-cutting changes where thoroughness matters more than speed.

### Auto-Selection (recommended)
```json
// No agents specified — small model selects the best team
```
The auto-selector reads the issue title and description and picks 3–4 appropriate agents.

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
