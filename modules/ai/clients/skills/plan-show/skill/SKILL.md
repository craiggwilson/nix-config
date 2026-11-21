---
name: plan-show
description: Use when presenting a plan, design, or OpenSpec change to the user for review — after a planner/architect drafts one, or when the user asks to see/visualize a plan. Opens the plan as rendered Markdown with Mermaid diagrams in a herdr pane beside the agent.
---

# Show a plan

The user reviews plans visually in a herdr pane next to the agent. Present
plans there instead of pasting long plans into chat.

## Steps

1. Write the plan as one Markdown file.
   - OpenSpec: show the change's `proposal.md` or `design.md` directly.
   - Otherwise write `/tmp/opencode/plans/<short-name>.md` (create the folder).
2. Make it visual where structure matters, with fenced ```` ```mermaid ````
   blocks: `flowchart` for components and data flow, `sequenceDiagram` for
   interactions, `stateDiagram-v2` for lifecycles, `gantt` for phases.
   Keep each diagram small (under ~15 nodes); split big ones.
3. Run `plan-show <file>`. It opens once; the pane re-renders on every save,
   so edit the same file to revise — don't run `plan-show` again.
4. In chat, give a 2–3 line summary and ask for feedback.

## Plan shape

- Title, then a one-paragraph goal.
- A diagram of the target state.
- Changes grouped by area, each with the files it touches.
- Risks and open questions last.

## Limits

- Markdown only: no raw HTML/CSS, no images other than mermaid diagrams.
- A diagram with a syntax error shows mermaid's error in its place; fix and save.
- `plan-show` needs herdr-app running on this machine.
