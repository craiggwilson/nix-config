# Obsidian Knowledge Base

Craig uses two Obsidian vaults:

- **`kb`** at `~/Projects/github.com/craiggwilson/kb` — personal projects and reference.
- **`kb-work`** at `~/Projects/github.com/craiggwilson/kb-work` — MongoDB work context (projects, PRs, briefings, daily plans, codebases, notes, reference).

## Vault Structure

### `kb` (personal)

```
kb/
├── home.md              # Vault index
├── inbox/               # Raw capture
├── projects/<name>/     # One dir per project
│   ├── <name>.md        # Project overview
│   ├── progress.md      # Current state — read this first
│   └── sessions/        # YYYY-MM-DD.md session notes
├── templates/           # Obsidian templates
└── AGENTS.md            # Full conventions
```

### `kb-work` (MongoDB work)

```
kb-work/
├── home.md              # Vault index
├── briefings/           # Morning briefs
├── codebases/<name>/    # Codebase orientation
├── daily/               # Day plans and daily notes
├── docs/                # MongoDB design-doc writing artifacts
├── inbox/               # Raw capture
├── mocs/                # Maps of Content
├── notes/               # Atomic zettelkasten notes
├── people/              # One file per person
├── prs/                 # Durable PR working files
├── projects/<name>/     # One dir per project
├── reference/           # Stable lookup facts
├── templates/           # Obsidian templates
└── AGENTS.md            # Full conventions
```

## Session Workflow

1. Read `projects/<project>/progress.md` to orient
2. Read recent session files if more context needed
3. Do the work
4. Update `progress.md` to reflect current state
5. Create `projects/<project>/sessions/YYYY-MM-DD.md`
6. Commit: `jj describe -m "<description>" && jj new`

## Skills

Load these when working with a vault:

- `obsidian-cli` — Read, create, search, append via the `obsidian` CLI (requires Obsidian open). Use `vault=kb` or `vault=kb-work` as appropriate.
- `obsidian-markdown` — Obsidian Flavored Markdown: wikilinks, callouts, frontmatter, tags.
- `obsidian-bases` — Create/edit `.base` database views over vault notes.
- `kb` — Shared conventions for both the `kb` (personal) and `kb-work` (work) vaults.

## CLI Quick Reference

```bash
obsidian vault=kb read file="projects/bloobiverse/progress"
obsidian vault=kb-work read file="projects/mvcp/progress"
obsidian vault=kb-work search query="search term" limit=10
```

Full conventions:
- `~/Projects/github.com/craiggwilson/kb/AGENTS.md` for the personal vault
- `~/Projects/github.com/craiggwilson/kb-work/AGENTS.md` for the work vault
