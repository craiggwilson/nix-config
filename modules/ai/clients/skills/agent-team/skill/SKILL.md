---
name: agent-team
description: Use when orchestrating work across several agents that need to talk to each other — implement-and-review loops, design debates, parallel lanes that must agree, or any task where specialists should push back or review one another. Runs specialists as real opencode agents in herdr terminals and coordinates them with hc.
---

# Agent team

Specialists run as their own opencode agents in herdr terminals (visible in
the user's sidebar under you; the user can jump in) and talk through `hc`.
Load the `herdr-core` skill for the full `hc` manual.

Use a team when agents must converse: review, pushback, negotiation. For a
one-shot lookup or a small mechanical edit, an in-process subagent is cheaper.

## Roles

`hc templates` lists them: one per opencode agent (coder, code-reviewer,
architect, debugger, planner, researcher, …). Each template already tells the
agent to report to its parent, push back, answer teammates, and put long
output in `/tmp/opencode/team/`.

## Start

```sh
mkdir -p /tmp/opencode/team
hc run --bg --name coder --cwd "$PWD" coder "<exact scope and done-criteria>"
hc run --bg --name reviewer --cwd "$PWD" code-reviewer "Wait for coder to ask for review. Review only what it changed."
```

- One name per role in a task (`coder`, `reviewer`, or `coder-api` and
  `coder-ui` for parallel lanes); names are how teammates find each other.
- Give each a scope that doesn't overlap another writer's files.
- Check `first_message.sent` in each launch result (see herdr-core skill).

## Wire the conversation

Say who talks to whom in the task itself:

- Implementer: "When done, ask `reviewer` for review with
  `hc send reviewer`. Address or rebut each finding. Report to me when the
  reviewer approves, or after 2 rounds with the open disagreements."
- Reviewer: "Send findings to `coder`, not to me. Approve explicitly when
  satisfied."
- Debate: start two agents (e.g. two `architect`s) with opposing briefs, have
  them exchange positions, and each report its final position to you.

## Wait and decide

```sh
hc wait --children any     # next report, or a message to you
hc read --lines 80 coder   # look at an agent's screen when its report is unclear
```

- A message arrives as your next input; handle it, then wait again.
- `reason: timeout` is a check-in, not a failure.
- When agents disagree after their rounds, you decide, or ask the user with
  both positions side by side.
- Never sleep or poll; never resend a task without reading first.

## Finish

Verify the result yourself (read the diff, run the checks), then
`hc kill <name>` and `hc rm <name>` for each teammate.
