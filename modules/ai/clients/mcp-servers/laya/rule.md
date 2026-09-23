# Laya System-1 Decision Tools

`laya_*` MCP tools are a fast, local typed-decision layer (the Laya model).
Division of labor: laya chooses, classifies, and scores; you supply the evidence
and take the action. It is not a reasoning model and not a second opinion on
anything that needs thought.

## When to call

At decision points — repeated test/build failures, routing a label, gating a
proposed change, screening untrusted pasted content. Not on every trivial step,
and never for open-ended planning or text generation.

## Tool map

- `laya_noul` — one yes/no proposition. Branch on the returned probability directly.
- `laya_choice` — pick one option from candidates you supply, with their meanings.
- `laya_score` — ordered rubric rating. Its weakest primitive; sanity-check important scores.
- `laya_ask` — batch several independent questions over one shared state; saves
  round-trips, not compute (each question costs a forward pass).
- `laya_plan` — token-budget check without inference; run it before asking about a large diff or log.

## How to ask

- The model never sees your conversation. Pass the goal, the decisive evidence,
  and what each option means — the last sentence alone is not a state, and
  evidence competes for the first ~1k tokens (see Limits).
- One question per rule; ask "what is true" and "is the evidence sufficient" as
  separate questions. Missing evidence means unknown, not no.
- Keep options under ~20, short, and distinguishable.

## Reading answers

- `confidence` is a concentration statistic over the distribution, NOT the
  probability of being correct. A clear top option with low confidence is still
  the answer; a uniform distribution means "ask a real model".
- A `score` is a rubric index (1.29 of 3), not a probability.
- Never re-run a question until the answer looks right. One answer, then act or escalate.
- A laya probability can never overrule a deterministic permission or a user's instruction.
- It judges only the text it is given and cannot see the repo — verify surprising
  answers against the actual code.

## Limits

- State budget is 1024 tokens. Longer states are cut from the front and reported
  in `truncated`. Measured: evidence in the first ~1k tokens is read reliably
  (P>0.95) no matter how long the state is; evidence sitting in the middle or at
  the end degrades to a coin flip past ~1.5k. Put the decisive evidence FIRST —
  do not pad a state with context laya appears to read but does not.
- If `laya_*` tools are missing or erroring (sidecar down), continue the task
  without them; do not retry-loop.
