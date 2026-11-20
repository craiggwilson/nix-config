# Hindsight Memory

You have long-term memory through the Hindsight plugin. The current bank is
chosen automatically from the working directory:

- Coding work in `nix-config`, `nix-private`, `substrate`, or `homelab` → `wilsonfamilyhq`.
- The MongoDB work vault at `~/Projects/github.com/craiggwilson/kb-work` → `mongodb`.
- The personal vault at `~/Projects/github.com/craiggwilson/kb` or the home directory → `craig`.

## At the start of a session

- Recall relevant context before you act. Use `hindsight_reflect` on the user's
goal, or `hindsight_search_pages` if you need the project's seeded pages.
- For the personal `craig` bank, prioritize life context: active projects,
recurring commitments, preferences, and deadlines. Skip code-level detail.

## While working

- Before big decisions, architecture changes, or unfamiliar code, search pages
with `hindsight_search_pages` and read the relevant ones with
`hindsight_read_page`.
- If pages are too shallow, use `hindsight_reflect` for a deeper synthesis.
- Treat recalled memory as a past record, not current truth. Verify any concrete
claim against the code, config, or docs before acting on it.

## Capture durable outcomes

- When you finish a meaningful thread, capture durable decisions or new
initiatives with `hindsight_capture_initiative`.
- Ingest important reference documents with `hindsight_ingest_document`.
- If memory seems missing, stale, or the wrong bank, run
`hindsight_diagnose` (and `hindsight_sync_status` if you need sync details) and
report what you find.

## End of session

- Summarize what changed and any decisions worth remembering. The plugin writes
the session back automatically; the summary ensures the retention focuses on
the durable bits.
