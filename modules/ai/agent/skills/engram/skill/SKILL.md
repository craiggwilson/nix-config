---
name: engram
description: Semantic memory CLI and OpenCode plugin for storing and retrieving personal knowledge base memories. Use when working with engram tools, managing memories, configuring the memory system, or understanding how memories are stored and retrieved.
---

# Engram

Semantic memory system backed by `all-MiniLM-L6-v2` embeddings and a local SQLite database. Memories are markdown files on disk, indexed and searched by vector similarity. Indexed documents (vault files, code repos) are separate from memories and survive `clear`/`decay`.

## MCP Tools (OpenCode Plugin)

Two tools are registered by the `opencode-engram-plugin`:

### `engram-search`

Search the knowledge base for relevant memories with a targeted query.

```
Parameters:
  query  (string, required)  Natural language search query
  limit  (number, optional)  Max results to return (default: 5)
```

Results are ranked by combined semantic similarity + memory strength. Returns file paths, classification, strength, and content snippets.

> The plugin automatically injects relevant memories into every system prompt — before the first LLM call (based on session title + recent user messages) and after every tool execution (based on the tool name, arguments, and result). Call `engram-search` manually only when you need more targeted recall than the automatic injection provides.

### `engram-add`

Save a new memory to the knowledge base. Use when information is worth preserving across sessions.

```
Parameters:
  content  (string, required)  The memory content to save
  type     (string, required)  Memory classification type (see configured types)
```

The available `type` values are loaded from the running engram config — they are not hardcoded. Common defaults: `episodic`, `fact`, `preference`.

## When to Use Each Tool

| Situation | Tool |
|:----------|:-----|
| Need more targeted recall than auto-injection | `engram-search` |
| User states a preference or constraint | `engram-add` (type: preference) |
| Decision made with long-term impact | `engram-add` (type: fact) |
| Session event worth recalling later | `engram-add` (type: episodic) |

> Auto-classification runs automatically at session end — only call `engram-add` manually for high-value information you want captured immediately.

## CLI Reference

The `engram` binary is available in the shell. Global flags apply to all subcommands:

```bash
engram [--config PATH] [--db PATH] [--memory-path PATH] <subcommand>
```

### Subcommands

```bash
# Search memories semantically
engram search [--limit N] [--json] <query>

# Add a memory manually
engram add --type TYPE <content>

# List all memories
engram list [--type TYPE] [--json]

# Remove memories by ID or path
engram remove <id|path>...

# Show memory statistics
engram stats [--json]

# Show active configuration
engram config [--json]

# List configured memory types
engram types [--json]

# Ingest indexed paths (re-index vault/docs)
engram ingest [--full]

# Apply Ebbinghaus strength decay
engram decay

# Delete memories (not indexed docs)
engram clear [--type TYPE]
```

### Examples

```bash
# Find memories about a specific topic
engram search "authentication decisions"

# Add a preference immediately
engram add --type preference "Prefer explicit error handling over silent failures"

# List all fact memories as JSON
engram list --type fact --json

# Check memory counts by type
engram stats

# Remove a specific memory
engram remove 42
engram remove /home/user/.local/share/engram/memories/2026-01-20-abc123.md
```

## Configuration

Config file: `$XDG_CONFIG_HOME/engram/engram.toml` (default: `~/.config/engram/engram.toml`)

```toml
# SQLite database path
db = "$XDG_DATA_HOME/engram/engram.db"

# Directory where memory markdown files are written
memory_path = "$XDG_DATA_HOME/engram/memories"

# Memory types (name + description + decay_rate)
# These are examples — customize with your own types and decay rates
[[memory_types]]
name = "episodic"
description = "Short-lived observations, session events, and what happened."
decay_rate = 0.1

[[memory_types]]
name = "fact"
description = "Decisions made, things learned, and stable factual knowledge."
decay_rate = 0.0

[[memory_types]]
name = "preference"
description = "Standing user preferences, constraints, and workflow rules."
decay_rate = 0.0

# Indexed paths (documents, not memories — survive clear/decay)
[[indexed_paths]]
path = "~/Documents/notes"
classification = "notes"
strength = 0.8
```

### Plugin Config

OpenCode plugin config: `~/.config/opencode/engram.json`

```json
{
  "config_file": "/path/to/engram.toml",
  "auto_classify": {
    "enabled": true,
    "min_messages": 10,
    "max_memories": 3,
    "temperature": 0.2,
    "search_limit": 8
  }
}
```

`auto_classify.enabled = false` disables automatic end-of-session classification while keeping `engram-add` available for manual use.

## Custom Embedding Models

By default, engram uses a compiled-in `gte-small` model (384 dimensions, BERT architecture). To use a different model, point `model_path` in `engram.toml` at a directory containing `config.json`, `model.safetensors`, and `tokenizer.json`:

```toml
model_path = "~/models/bge-small-en-v1.5"
```

Any BERT-architecture model in safetensors format works (sentence-transformers, BGE, E5, GTE, MiniLM, etc.).

Some models require a prefix prepended to queries or passages to achieve their benchmark performance. Configure these alongside `model_path`:

```toml
# E5 models
query_prefix = "query: "
passage_prefix = "passage: "

# BGE models
query_prefix = "Represent this sentence for searching relevant passages: "
# (no passage_prefix needed for BGE)
```

GTE and MiniLM don't require prefixes — omit both fields or leave them empty.

**Switching models requires re-indexing.** Engram detects dimension mismatches at startup and will refuse to run until you clear and re-ingest:

```bash
engram clear && engram ingest --full
```

## Key Concepts

- **`is_memory` flag** — distinguishes hand-added/classified memories from indexed documents. Only memories are returned by `list`, affected by `clear`, or decayed.
- **Strength** — starts at 1.0, decays over time (for types with `decay_rate > 0`), boosted on access. Higher strength = surfaces first in search.
- **Indexed paths** — files ingested from `indexed_paths` entries are indexed for search context but are never decayed or cleared (`is_memory = false`). Files from `memory_path` are treated as memories (`is_memory = true`) and do decay and clear like any other memory.
- **Decay** — runs at session end via `engram decay`. Uses Ebbinghaus forgetting curve. Memories with `decay_rate = 0` never weaken.
