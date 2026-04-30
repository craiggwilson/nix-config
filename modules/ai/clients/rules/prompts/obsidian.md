# Obsidian Knowledge Base

The personal knowledge base vault is at `~/Projects/kb`. It covers work, personal projects, research, ideas, and everything in between.

## Structure

```
kb/
├── home.md              # Vault index
├── people/              # One file per person
├── projects/<name>/     # One dir per project
│   ├── <name>.md        # Project overview
│   ├── progress.md      # Current state — read this first
│   └── sessions/        # YYYY-MM-DD.md session notes
├── reference/           # Stable lookup facts
├── research/            # Synthesized deep-dive notes
└── AGENTS.md            # Full conventions — read this for detail
```

## Session Workflow

1. Read `projects/<project>/progress.md` to orient
2. Read recent session files if more context needed
3. Do the work
4. Update `progress.md` to reflect current state
5. Create `projects/<project>/sessions/YYYY-MM-DD.md`
6. Commit: `jj describe -m "<description>" && jj new`

## Skills

Load these when working with the vault:

- `obsidian-cli` — Read, create, search, append via the `obsidian` CLI (requires Obsidian open). Use `vault=kb`.
- `obsidian-markdown` — Obsidian Flavored Markdown: wikilinks, callouts, frontmatter, tags.
- `obsidian-bases` — Create/edit `.base` database views over vault notes.
- `kb` — Personal KB conventions: file types, frontmatter schemas, linking patterns.

## CLI Quick Reference

```bash
obsidian vault=kb read file="projects/mvcp/progress"
obsidian vault=kb create name="projects/mvcp/sessions/2026-03-22" content="..."
obsidian vault=kb search query="search term" limit=10
```

Full conventions: `~/Projects/kb/AGENTS.md`
