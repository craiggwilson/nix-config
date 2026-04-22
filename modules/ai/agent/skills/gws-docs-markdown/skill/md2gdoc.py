#!/usr/bin/env python3
"""md2gdoc — Convert Markdown files to Google Docs with tab support.

Uses the gws CLI to call the Google Docs REST API. Each file becomes one tab.

Usage:
    md2gdoc create --title "My Doc" file1.md [file2.md ...]
    md2gdoc add-tab --document DOC_ID [--title "Tab Title"] file.md
    md2gdoc extract-tab --document DOC_ID --tab TITLE_OR_ID

Outputs the document ID (create) or tab ID (add-tab) to stdout.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

import yaml
from markdown_it import MarkdownIt
from markdown_it.tree import SyntaxTreeNode
from mdit_py_plugins.front_matter import front_matter_plugin
from mdit_py_plugins.tasklists import tasklists_plugin


# ---------------------------------------------------------------------------
# Types
# ---------------------------------------------------------------------------


Request = dict[str, Any]


@dataclass
class BuildState:
    """Mutable state threaded through the request builder."""

    tab_id: str
    doc_id: str = ""
    # Map of filename stem → tab_id for resolving intra-doc links.
    tab_map: dict[str, str] = field(default_factory=dict)
    # Running byte offset into the tab body. Starts at 1 (index 0 is the
    # structural newline Google Docs inserts at the start of every segment).
    index: int = 1
    requests: list[Request] = field(default_factory=list)
    # Links that could not be resolved at write time (fragment/relative hrefs).
    # Each entry: (start_index, end_index, original_href).
    deferred_links: list[tuple[int, int, str]] = field(default_factory=list)


@dataclass
class Region:
    """A leaf editable region extracted from a live Google Doc tab."""

    kind: str
    tab_id: str
    start_api: int
    end_api: int
    text: str
    row: int = 0
    col: int = 0
    table_start_api: int = 0
    # 1-6 for headings, 0 for all other regions.
    heading_level: int = 0
    # Raw API paragraph dict — populated by extract_tab_regions for rendering.
    raw_para: dict = field(default_factory=dict)
    # True when this cell is in the header row of a table.
    is_table_header: bool = False
    raw_markdown: str = ""

# ---------------------------------------------------------------------------
# Markdown parser
# ---------------------------------------------------------------------------


def build_parser() -> MarkdownIt:
    """Return a configured MarkdownIt instance."""
    md = (
        MarkdownIt("commonmark")
        .use(front_matter_plugin)
        .use(tasklists_plugin)
        .enable("table")
        .enable("strikethrough")
    )
    return md


def parse(text: str) -> tuple[dict, SyntaxTreeNode]:
    """Parse *text* and return (frontmatter_dict, syntax_tree_root)."""
    md = build_parser()
    tokens = md.parse(text)
    root = SyntaxTreeNode(tokens)

    meta: dict = {}
    # Front-matter node is always the first child if present.
    if root.children and root.children[0].type == "front_matter":
        raw = root.children[0].token.content  # type: ignore[union-attr]
        try:
            meta = yaml.safe_load(raw) or {}
        except yaml.YAMLError:
            meta = {}

    return meta, root


def patch_frontmatter(path: Path, updates: dict) -> None:
    """Update or insert YAML frontmatter fields in *path* in-place.

    Preserves all existing frontmatter fields and body content.
    If no frontmatter block exists, prepends one.
    """
    text = path.read_text(encoding="utf-8")
    fm_pattern = re.compile(r"^---\n(.*?)\n---\n", re.DOTALL)
    match = fm_pattern.match(text)
    if match:
        existing: dict = yaml.safe_load(match.group(1)) or {}
        existing.update(updates)
        new_fm = "---\n" + yaml.dump(existing, default_flow_style=False, allow_unicode=True) + "---\n"
        new_text = new_fm + text[match.end():]
    else:
        new_fm = "---\n" + yaml.dump(updates, default_flow_style=False, allow_unicode=True) + "---\n"
        new_text = new_fm + text
    path.write_text(new_text, encoding="utf-8")


def load_tab_slug_map_from_files(files: list[Path]) -> dict[str, str]:
    """Build a tabId → filename-stem-slug map from local markdown frontmatter.

    Reads each file's frontmatter for 'gdoc_tab_id'. When found, maps that
    tab ID to the file's stem slugified (e.g. '00-README' → '00-readme',
    '04-scope-process' → '04-scope-process').

    This gives the exact mapping needed to render internal tab links as
    Obsidian wikilinks that match the local filenames.
    """
    result: dict[str, str] = {}
    fm_pattern = re.compile(r"^---\n(.*?)\n---\n", re.DOTALL)
    for path in files:
        try:
            text = path.read_text(encoding="utf-8")
        except OSError:
            continue
        match = fm_pattern.match(text)
        if not match:
            continue
        fm: dict = yaml.safe_load(match.group(1)) or {}
        tab_id = fm.get("gdoc_tab_id", "")
        if tab_id:
            result[tab_id] = _slugify(path.stem)
    return result
# ---------------------------------------------------------------------------
# Text extraction helpers (inline spans)
# ---------------------------------------------------------------------------


def plain_text(node: SyntaxTreeNode) -> str:
    """Extract plain text from an inline node tree (strips all markup)."""
    if node.type == "text":
        return node.token.content  # type: ignore[union-attr]
    if node.type == "softbreak" or node.type == "hardbreak":
        return " "
    if node.type == "code_inline":
        return node.token.content  # type: ignore[union-attr]
    if node.type in ("html_inline", "html_block"):
        return re.sub(r"<[^>]+>", "", node.token.content or "")  # type: ignore[union-attr]
    parts = []
    for child in node.children:
        parts.append(plain_text(child))
    return "".join(parts)



def _to_utf16_units(text: str) -> list[str]:
    """Return a list of UTF-16 code units for *text*.

    Characters outside the BMP (codepoint > 0xFFFF) become two entries.
    """
    units = []
    for ch in text:
        cp = ord(ch)
        if cp > 0xFFFF:
            units.append(ch)
            units.append(ch)
        else:
            units.append(ch)
    return units


@dataclass
class Span:
    """A run of text with optional style flags."""

    text: str
    bold: bool = False
    italic: bool = False
    code: bool = False
    strikethrough: bool = False
    link_url: str = ""
    # When True, emit an explicit style-reset span after this one.
    # Set automatically by _emit_spans for any span that has active styles.
    _has_style: bool = field(default=False, repr=False)


# ---------------------------------------------------------------------------
# Link resolution
# ---------------------------------------------------------------------------


_FRAGMENT_ONLY_RE = re.compile(r"^#")
_RELATIVE_MD_RE = re.compile(r"^\.{0,2}/[^:]*\.md(#.*)?$|^[^/:][^:]*\.md(#.*)?$")

# Sentinel prefix stored in Span.link_url for links that need a second pass.
_DEFERRED = "__DEFERRED__:"


def _slug(text: str) -> str:
    """Normalize heading text to a URL fragment slug.

    Matches GitHub's algorithm: lowercase, strip non-alphanumeric/space/hyphen,
    collapse spaces to single hyphens.
    """
    text = text.lower()
    text = re.sub(r"[^\w\s-]", "", text)  # strip punctuation
    text = re.sub(r"\s+", "-", text.strip())
    return text


def resolve_link(href: str, tab_map: dict[str, str]) -> str:
    """Return the resolved link string, or a deferred sentinel, or ''.

    - External URLs (http/https) → pass through unchanged.
    - Fragment-only (#slug) → deferred sentinel (needs post-write heading map).
    - Relative .md links (./file.md or ./file.md#slug) → deferred sentinel
      so the second pass can resolve to tabId ± headingId.
    - Anything else → skip (return '').
    """
    if not href:
        return ""
    # Already a deferred sentinel (e.g. from wikilink expansion) — pass through.
    if href.startswith(_DEFERRED):
        return href
    if href.startswith("http://") or href.startswith("https://"):
        return href
    if _FRAGMENT_ONLY_RE.match(href) or _RELATIVE_MD_RE.match(href):
        # Defer: second pass will resolve once headingIds are known.
        return _DEFERRED + href
    return ""


# ---------------------------------------------------------------------------
# Span collection
# ---------------------------------------------------------------------------


_WIKILINK_RE = re.compile(r"\[\[([^\]|]+?)(?:\|([^\]]+?))?\]\]")


def collect_spans(node: SyntaxTreeNode, bold=False, italic=False, code=False,
                  strike=False, link_url="") -> list[Span]:
    """Recursively collect Span objects from an inline subtree."""
    t = node.type

    if t == "text":
        raw = node.token.content  # type: ignore[union-attr]
        return _expand_wikilinks(raw, bold, italic, code, strike, link_url)

    if t == "softbreak" or t == "hardbreak":
        return [Span(" ", bold, italic, code, strike, link_url)]

    if t == "code_inline":
        return [Span(node.token.content, bold, italic, True, strike, link_url)]  # type: ignore[union-attr]

    if t == "strong":
        return _collect_children(node, bold=True, italic=italic, code=code,
                                 strike=strike, link_url=link_url)

    if t == "em":
        return _collect_children(node, bold=bold, italic=True, code=code,
                                 strike=strike, link_url=link_url)

    if t == "s":
        return _collect_children(node, bold=bold, italic=italic, code=code,
                                 strike=True, link_url=link_url)

    if t == "link":
        href = (node.attrs or {}).get("href", "") or ""
        return _collect_children(node, bold=bold, italic=italic, code=code,
                                 strike=strike, link_url=href)

    if t in ("html_inline",):
        raw = node.token.content or ""  # type: ignore[union-attr]
        stripped = re.sub(r"<[^>]+>", "", raw)
        if stripped:
            return [Span(stripped, bold, italic, code, strike, link_url)]
        return []

    return _collect_children(node, bold=bold, italic=italic, code=code,
                             strike=strike, link_url=link_url)


def _collect_children(node: SyntaxTreeNode, **kwargs) -> list[Span]:
    spans: list[Span] = []
    for child in node.children:
        spans.extend(collect_spans(child, **kwargs))
    return spans


_WIKILINK_RE = re.compile(
    r"\[\["
    r"([^\]|#]+?)"          # target path (before | or # or ]])
    r"(?:#([^\]|]*))?"      # optional #heading fragment
    r"(?:[|\\|]([^\]]+))?" # optional |display or \|display
    r"\]\]"
)


def _expand_wikilinks(text: str, bold, italic, code, strike, link_url) -> list[Span]:
    """Split *text* on Obsidian wikilinks, returning Spans.

    Wikilinks whose target stem matches a file in the upload set are emitted
    with a deferred-sentinel link_url so the second pass resolves them to real
    tab/heading links.  All others render as plain display text.
    """
    spans: list[Span] = []
    last = 0
    for m in _WIKILINK_RE.finditer(text):
        before = text[last:m.start()]
        if before:
            spans.append(Span(before, bold, italic, code, strike, link_url))

        target = m.group(1).strip()   # e.g. "path/to/note" or "note-stem"
        fragment = (m.group(2) or "").strip()  # heading after #
        display = (m.group(3) or "").strip()   # text after | or \|
        if not display:
            # Use the last path component (stem) as display text.
            display = Path(target.rstrip("/")).stem.replace("-", " ").replace("_", " ").title()

        # Build a synthetic relative href so resolve_link / second-pass can
        # handle this identically to a regular markdown relative link.
        stem = Path(target.rstrip("/")).stem
        if fragment:
            synthetic_href = f"./{stem}.md#{fragment}"
        else:
            synthetic_href = f"./{stem}.md"

        # Always use deferred sentinel — resolve_link will check tab_map at
        # second-pass time and fall back to plain text if the stem is unknown.
        wikilink_url = _DEFERRED + synthetic_href
        spans.append(Span(display, bold, italic, code, strike, wikilink_url))
        last = m.end()
    tail = text[last:]
    if tail:
        spans.append(Span(tail, bold, italic, code, strike, link_url))
    return spans


def inline_spans(node: SyntaxTreeNode) -> list[Span]:
    """Extract spans from an 'inline' node (child of heading/paragraph etc.)."""
    spans: list[Span] = []
    for child in node.children:
        spans.extend(collect_spans(child))
    return spans


# ---------------------------------------------------------------------------
# Request builders — low-level primitives
# ---------------------------------------------------------------------------


def _insert_text(state: BuildState, text: str) -> None:
    """Append an insertText request and advance the index."""
    if not text:
        return
    state.requests.append({
        "insertText": {
            "text": text,
            "endOfSegmentLocation": {
                "segmentId": "",
                "tabId": state.tab_id,
            },
        }
    })
    state.index += len(text)


def _insert_text_at(state: BuildState, text: str, index: int) -> None:
    """Insert text at an explicit document index (for table cell content)."""
    if not text:
        return
    state.requests.append({
        "insertText": {
            "text": text,
            "location": {
                "index": index,
                "segmentId": "",
                "tabId": state.tab_id,
            },
        }
    })
    # Do not advance state.index — callers manage offsets for index-based writes.


def _paragraph_style(state: BuildState, start: int, end: int,
                     named_style: str) -> None:
    state.requests.append({
        "updateParagraphStyle": {
            "range": {
                "startIndex": start,
                "endIndex": end,
                "segmentId": "",
                "tabId": state.tab_id,
            },
            "paragraphStyle": {"namedStyleType": named_style},
            "fields": "namedStyleType",
        }
    })


def _text_style(state: BuildState, start: int, end: int,
                style: dict, fields: str) -> None:
    state.requests.append({
        "updateTextStyle": {
            "range": {
                "startIndex": start,
                "endIndex": end,
                "segmentId": "",
                "tabId": state.tab_id,
            },
            "textStyle": style,
            "fields": fields,
        }
    })


def _text_style_at(requests: list[Request], tab_id: str,
                   start: int, end: int, style: dict, fields: str) -> None:
    """Append a text style request to an arbitrary request list (for table cells)."""
    requests.append({
        "updateTextStyle": {
            "range": {
                "startIndex": start,
                "endIndex": end,
                "segmentId": "",
                "tabId": tab_id,
            },
            "textStyle": style,
            "fields": fields,
        }
    })


def _bullet_preset(state: BuildState, start: int, end: int,
                   preset: str) -> None:
    state.requests.append({
        "createParagraphBullets": {
            "range": {
                "startIndex": start,
                "endIndex": end,
                "segmentId": "",
                "tabId": state.tab_id,
            },
            "bulletPreset": preset,
        }
    })


# ---------------------------------------------------------------------------
# Style emission helpers
# ---------------------------------------------------------------------------


def _emit_spans(state: BuildState, spans: list[Span],
                tab_map: dict[str, str] | None = None) -> tuple[int, int]:
    """Insert all spans with explicit per-span text styles.

    Every span gets a full updateTextStyle that sets each field explicitly,
    so Google Docs' style inheritance cannot bleed from one span to the next.

    Returns (para_start, para_end).
    """
    if tab_map is None:
        tab_map = state.tab_map

    para_start = state.index

    for span in spans:
        if not span.text:
            continue

        span_start = state.index
        _insert_text(state, span.text)
        span_end = state.index

        # Always emit bold/italic/strikethrough explicitly so that a styled
        # span cannot bleed into an adjacent plain span. Skip
        # backgroundColor/weightedFontFamily for plain text — those are only
        # set for code spans, avoiding the black-background bug.
        style: dict = {
            "bold": bool(span.bold),
            "italic": bool(span.italic),
            "strikethrough": bool(span.strikethrough),
        }
        fields: list[str] = ["bold", "italic", "strikethrough"]

        if span.code:
            style["weightedFontFamily"] = {"fontFamily": "Courier New", "weight": 400}
            style["backgroundColor"] = {
                "color": {"rgbColor": {"red": 0.94, "green": 0.94, "blue": 0.94}}
            }
            fields += ["weightedFontFamily", "backgroundColor"]

        if span.link_url:
            resolved = resolve_link(span.link_url, tab_map)
            if resolved.startswith(_DEFERRED):
                # Record for second-pass resolution; no link style applied now.
                original_href = resolved[len(_DEFERRED):]
                state.deferred_links.append((span_start, span_end, original_href))
            elif resolved:
                style["link"] = {"url": resolved}
                fields.append("link")

        _text_style(state, span_start, span_end, style, ",".join(fields))

    para_end = state.index
    return para_start, para_end


# ---------------------------------------------------------------------------
# Request builders — block nodes
# ---------------------------------------------------------------------------


HEADING_STYLES = {
    1: "HEADING_1",
    2: "HEADING_2",
    3: "HEADING_3",
    4: "HEADING_4",
    5: "HEADING_5",
    6: "HEADING_6",
}

CALLOUT_RE = re.compile(r"^\[!(NOTE|TIP|WARNING|CAUTION|IMPORTANT)\]\s*", re.I)


def handle_heading(state: BuildState, node: SyntaxTreeNode) -> None:
    level = int(node.tag[1])  # "h2" → 2
    inline = node.children[0] if node.children else None
    spans = inline_spans(inline) if inline else []

    para_start = state.index
    _emit_spans(state, spans)
    _insert_text(state, "\n")
    para_end = state.index

    _paragraph_style(state, para_start, para_end,
                     HEADING_STYLES.get(level, "HEADING_6"))


def handle_paragraph(state: BuildState, node: SyntaxTreeNode) -> None:
    inline = node.children[0] if node.children else None
    if inline is None:
        _insert_text(state, "\n")
        return

    # Detect Obsidian callouts: first child text starts with [!TYPE]
    if inline.children:
        first = inline.children[0]
        raw_text = ""
        if first.type == "text" and first.token:
            raw_text = first.token.content or ""
        if CALLOUT_RE.match(raw_text):
            handle_callout(state, inline)
            return

    spans = inline_spans(inline)
    para_start = state.index
    _emit_spans(state, spans)
    _insert_text(state, "\n")
    para_end = state.index
    _paragraph_style(state, para_start, para_end, "NORMAL_TEXT")
    # Emit an extra blank line to match the blank line markdown uses to
    # separate paragraphs. The parser consumes it without producing an AST node.
    _insert_text(state, "\n")


def handle_callout(state: BuildState, inline: SyntaxTreeNode) -> None:
    """Render an Obsidian callout as a blockquote-styled paragraph."""
    spans = inline_spans(inline)
    # Strip the [!TYPE] prefix from the first span.
    if spans:
        first = spans[0]
        stripped_text = CALLOUT_RE.sub("", first.text)
        spans[0] = Span(stripped_text, first.bold, first.italic,
                        first.code, first.strikethrough, first.link_url)

    para_start = state.index
    _emit_spans(state, spans)
    _insert_text(state, "\n")
    para_end = state.index
    _paragraph_style(state, para_start, para_end, "NORMAL_TEXT")
    _insert_text(state, "\n")
    state.requests.append({
        "updateParagraphStyle": {
            "range": {
                "startIndex": para_start,
                "endIndex": para_end,
                "segmentId": "",
                "tabId": state.tab_id,
            },
            "paragraphStyle": {
                "borderLeft": {
                    "color": {
                        "color": {
                            "rgbColor": {"red": 0.4, "green": 0.6, "blue": 1.0}
                        }
                    },
                    "dashStyle": "SOLID",
                    "padding": {"magnitude": 6, "unit": "PT"},
                    "width": {"magnitude": 3, "unit": "PT"},
                },
                "indentStart": {"magnitude": 18, "unit": "PT"},
            },
            "fields": "borderLeft,indentStart",
        }
    })


def handle_blockquote(state: BuildState, node: SyntaxTreeNode) -> None:
    """Render a blockquote with a left border."""
    for child in node.children:
        para_start = state.index
        _process_node(state, child)
        para_end = state.index
        if para_end > para_start:
            state.requests.append({
                "updateParagraphStyle": {
                    "range": {
                        "startIndex": para_start,
                        "endIndex": para_end,
                        "segmentId": "",
                        "tabId": state.tab_id,
                    },
                    "paragraphStyle": {
                        "borderLeft": {
                            "color": {
                                "color": {
                                    "rgbColor": {
                                        "red": 0.6, "green": 0.6, "blue": 0.6
                                    }
                                }
                            },
                            "dashStyle": "SOLID",
                            "padding": {"magnitude": 6, "unit": "PT"},
                            "width": {"magnitude": 3, "unit": "PT"},
                        },
                        "indentStart": {"magnitude": 18, "unit": "PT"},
                    },
                    "fields": "borderLeft,indentStart",
                }
            })


def handle_fence(state: BuildState, node: SyntaxTreeNode) -> None:
    """Render a fenced code block as a 1x1 table with grey background.

    The Docs REST API has no CODE_BLOCK named style. A single-cell table
    with a grey cell background + Courier New text is the closest visual
    equivalent to the Docs UI 'Building blocks > Code block'.
    """
    if not state.doc_id:
        # No doc_id: fall back to monospace paragraphs.
        _fence_fallback(state, node)
        return

    token = node.token  # type: ignore[union-attr]
    content = token.content if token else ""
    lines = content.split("\n")
    if lines and lines[-1] == "":
        lines = lines[:-1]
    if not lines:
        return

    # 1. Capture pre-insert index, append insertTable, flush.
    pre_insert_index = state.index
    state.requests.append({
        "insertTable": {
            "rows": 1,
            "columns": 1,
            "endOfSegmentLocation": {
                "segmentId": "",
                "tabId": state.tab_id,
            },
        }
    })
    _flush_requests(state)

    # 2. GET the doc to find the table startIndex and cell para startIndex.
    doc = _gws("docs", "documents", "get",
               "--params", json.dumps({
                   "documentId": state.doc_id,
                   "includeTabsContent": "true",
               }))
    table_si, para_si = _find_last_table_indices(doc, state.tab_id,
                                                 min_index=pre_insert_index)
    if para_si is None:
        _fence_fallback(state, node)
        return

    # 3. Build content requests: insert lines in reverse order (last first)
    #    so that index-based inserts don't shift earlier positions.
    cell_requests: list[Request] = []
    # Each line is inserted separately so paragraph styles apply per-line.
    # We insert all at the same para_si in reverse so they stack correctly.
    for line in reversed(lines):
        text = line + "\n"
        cell_requests.append({
            "insertText": {
                "text": text,
                "location": {
                    "index": para_si,
                    "segmentId": "",
                    "tabId": state.tab_id,
                },
            }
        })

    # 4. Style all the inserted text as monospace (range covers all lines).
    total_len = sum(len(l) + 1 for l in lines)
    cell_requests.append({
        "updateTextStyle": {
            "range": {
                "startIndex": para_si,
                "endIndex": para_si + total_len,
                "segmentId": "",
                "tabId": state.tab_id,
            },
            "textStyle": {
                "weightedFontFamily": {"fontFamily": "Courier New", "weight": 400},
            },
            "fields": "weightedFontFamily",
        }
    })

    # 5. Grey cell background via updateTableCellStyle.
    cell_requests.append({
        "updateTableCellStyle": {
            "tableRange": {
                "tableCellLocation": {
                    "tableStartLocation": {
                        "index": table_si,
                        "segmentId": "",
                        "tabId": state.tab_id,
                    },
                    "rowIndex": 0,
                    "columnIndex": 0,
                },
                "rowSpan": 1,
                "columnSpan": 1,
            },
            "tableCellStyle": {
                "backgroundColor": {
                    "color": {
                        "rgbColor": {"red": 0.94, "green": 0.94, "blue": 0.94}
                    }
                }
            },
            "fields": "backgroundColor",
        }
    })

    _gws("docs", "documents", "batchUpdate",
         "--params", json.dumps({"documentId": state.doc_id}),
         "--json", json.dumps({"requests": cell_requests}))

    # 6. Advance state.index past the table.
    doc2 = _gws("docs", "documents", "get",
                "--params", json.dumps({
                    "documentId": state.doc_id,
                    "includeTabsContent": "true",
                }))
    state.index = _find_end_index_after_table(
        doc2, state.tab_id, min_index=pre_insert_index) or state.index
    _flush_requests(state)


def _fence_fallback(state: BuildState, node: SyntaxTreeNode) -> None:
    """Monospace-paragraph fallback when no doc_id is available."""
    token = node.token  # type: ignore[union-attr]
    content = token.content if token else ""
    lines = content.split("\n")
    if lines and lines[-1] == "":
        lines = lines[:-1]
    code_style = {
        "weightedFontFamily": {"fontFamily": "Courier New", "weight": 400},
        "backgroundColor": {
            "color": {"rgbColor": {"red": 0.94, "green": 0.94, "blue": 0.94}}
        },
    }
    for line in lines:
        para_start = state.index
        _insert_text(state, line + "\n")
        para_end = state.index
        _paragraph_style(state, para_start, para_end, "NORMAL_TEXT")
        _text_style(state, para_start, para_end, code_style,
                    "weightedFontFamily,backgroundColor")


def _find_last_table_indices(doc: dict, tab_id: str,
                             min_index: int = 0) -> tuple[int | None, int | None]:
    """Return (table_startIndex, cell_para_startIndex) for the first table
    at or after *min_index* in the tab."""
    for tab in doc.get("tabs", []):
        if tab.get("tabProperties", {}).get("tabId") != tab_id:
            continue
        body = tab.get("documentTab", {}).get("body", {})
        for el in body.get("content", []):
            tbl = el.get("table")
            if not tbl:
                continue
            if el.get("startIndex", 0) < min_index:
                continue
            table_si = el.get("startIndex")
            rows = tbl.get("tableRows", [])
            if rows:
                cells = rows[0].get("tableCells", [])
                if cells:
                    content = cells[0].get("content", [])
                    if content:
                        para_si = content[0].get("startIndex")
                        return table_si, para_si
    return None, None

def handle_hr(state: BuildState, _node: SyntaxTreeNode) -> None:
    """Render a thematic break as a paragraph with a bottom border."""
    para_start = state.index
    _insert_text(state, "\n")
    para_end = state.index
    state.requests.append({
        "updateParagraphStyle": {
            "range": {
                "startIndex": para_start,
                "endIndex": para_end,
                "segmentId": "",
                "tabId": state.tab_id,
            },
            "paragraphStyle": {
                "borderBottom": {
                    "color": {
                        "color": {
                            "rgbColor": {"red": 0.7, "green": 0.7, "blue": 0.7}
                        }
                    },
                    "dashStyle": "SOLID",
                    "padding": {"magnitude": 1, "unit": "PT"},
                    "width": {"magnitude": 1, "unit": "PT"},
                }
            },
            "fields": "borderBottom",
        }
    })


def handle_list(state: BuildState, node: SyntaxTreeNode,
                depth: int = 0) -> None:
    """Render bullet or ordered lists, with task-list support."""
    ordered = node.type == "ordered_list"
    preset = ("NUMBERED_DECIMAL_ALPHA_ROMAN" if ordered
              else "BULLET_DISC_CIRCLE_SQUARE")

    list_start = state.index
    for item in node.children:
        _handle_list_item(state, item, ordered, depth)
    list_end = state.index

    # Only apply bullets to the range we just wrote — never include
    # surrounding paragraphs or headings.
    if list_end > list_start:
        _bullet_preset(state, list_start, list_end, preset)
        _insert_text(state, "\n")


def _handle_list_item(state: BuildState, item: SyntaxTreeNode,
                      ordered: bool, depth: int) -> None:
    """Render a single list item (possibly with nested lists)."""
    for child in item.children:
        if child.type in ("bullet_list", "ordered_list"):
            # Nested list — recurse with increased depth but no surrounding
            # bullet preset (the outer handle_list applies it).
            handle_list(state, child, depth + 1)
        elif child.type == "paragraph":
            _handle_list_paragraph(state, child)
        else:
            # Inline content at the item level (tight lists produce this).
            _handle_list_inline(state, child)


def _handle_list_paragraph(state: BuildState, para: SyntaxTreeNode) -> None:
    """Render the paragraph child of a list item."""
    inline = para.children[0] if para.children else None
    if inline is None:
        _insert_text(state, "\n")
        return

    is_task, checked = _detect_task(inline)
    spans = inline_spans(inline)

    if is_task:
        prefix = "☑ " if checked else "☐ "
        spans = [Span(prefix)] + spans

    para_start = state.index
    _emit_spans(state, spans)
    _insert_text(state, "\n")

    if is_task and checked:
        _text_style(state, para_start, state.index,
                    {"strikethrough": True}, "strikethrough")


def _handle_list_inline(state: BuildState, node: SyntaxTreeNode) -> None:
    """Render a direct inline child of a list_item (tight list)."""
    if node.type == "inline":
        spans = inline_spans(node)
        _emit_spans(state, spans)
        _insert_text(state, "\n")
    else:
        _process_node(state, node)


def _detect_task(inline: SyntaxTreeNode) -> tuple[bool, bool]:
    """Return (is_task, is_checked) from an inline node."""
    for child in inline.children:
        if child.type == "html_inline" and child.token:
            html = child.token.content or ""
            if 'type="checkbox"' in html:
                checked = "checked" in html
                return True, checked
    return False, False


def handle_table(state: BuildState, node: SyntaxTreeNode) -> None:
    """Render a GFM table by inserting the table structure then filling cells.

    Strategy:
    1. Collect all rows and cell text/spans from the AST.
    2. Emit an insertTable request (appended to state.requests).
    3. Flush the current batch to the API so the table exists in the doc.
    4. GET the document to discover the actual paragraph startIndex of each cell.
    5. Build insertText + style requests in reverse cell order (so earlier
       inserts don't shift later indices) and flush them.
    """
    thead = next((c for c in node.children if c.type == "thead"), None)
    tbody_nodes = [c for c in node.children if c.type == "tbody"]

    if thead is None:
        return

    header_rows = thead.children
    body_rows: list[SyntaxTreeNode] = []
    for tb in tbody_nodes:
        body_rows.extend(tb.children)

    all_rows = header_rows + body_rows
    if not all_rows:
        return

    num_cols = len(all_rows[0].children)
    num_rows = len(all_rows)

    # Collect cell content as (spans, is_header) pairs, row-major order.
    cells: list[tuple[list[Span], bool]] = []
    for ri, row in enumerate(all_rows):
        is_header = ri < len(header_rows)
        for cell in row.children:
            inline = cell.children[0] if cell.children else None
            spans = inline_spans(inline) if inline else []
            cells.append((spans, is_header))

    # Emit the insertTable request and flush everything so far.
    # Capture state.index now so we can find THIS table after the flush
    # (not an earlier one with the same dimensions).
    pre_insert_index = state.index
    state.requests.append({
        "insertTable": {
            "rows": num_rows,
            "columns": num_cols,
            "endOfSegmentLocation": {
                "segmentId": "",
                "tabId": state.tab_id,
            },
        }
    })

    if not state.doc_id:
        # No doc_id — fall back to plain-text representation.
        _table_fallback(state, all_rows)
        return

    # Flush current requests to the API.
    _flush_requests(state)

    # GET the document to find cell paragraph indices.
    doc = _gws("docs", "documents", "get",
               "--params", json.dumps({
                   "documentId": state.doc_id,
                   "includeTabsContent": "true",
               }))

    cell_indices = _extract_cell_indices(doc, state.tab_id, num_rows, num_cols)
    if not cell_indices:
        # Couldn't find cells — skip content (table structure is still there).
        return

    # Build cell content requests in reverse order (last cell first) so that
    # index-based inserts don't shift earlier cell positions.
    cell_requests: list[Request] = []
    for flat_idx in reversed(range(len(cells))):
        if flat_idx >= len(cell_indices):
            continue
        para_start = cell_indices[flat_idx]
        spans, is_header = cells[flat_idx]
        if not spans:
            continue

        # Accumulate text and style requests for this cell.
        cell_text = ""
        pending_styles: list[tuple[int, int, dict, str]] = []
        offset = para_start

        prev_had_style = False
        for span in spans:
            if not span.text:
                continue
            span_start = offset
            cell_text_piece = span.text
            span_end = offset + len(cell_text_piece)

            # Always emit bold/italic/strikethrough explicitly (even False)
            # so styled spans cannot bleed into adjacent plain spans.
            style: dict = {
                "bold": bool(span.bold or is_header),
                "italic": bool(span.italic),
                "strikethrough": bool(span.strikethrough),
            }
            field_parts = ["bold", "italic", "strikethrough"]
            if span.code:
                style["weightedFontFamily"] = {
                    "fontFamily": "Courier New", "weight": 400}
                field_parts.append("weightedFontFamily")
            pending_styles.append((span_start, span_end, style,
                                   ",".join(field_parts)))

            cell_text += cell_text_piece
            offset = span_end

        if not cell_text:
            continue

        # Insert the text, then apply styles (all at the same absolute indices
        # since we haven't submitted yet — these will be in the next batch).
        cell_requests.append({
            "insertText": {
                "text": cell_text,
                "location": {
                    "index": para_start,
                    "segmentId": "",
                    "tabId": state.tab_id,
                },
            }
        })
        for s_start, s_end, sty, flds in pending_styles:
            cell_requests.append({
                "updateTextStyle": {
                    "range": {
                        "startIndex": s_start,
                        "endIndex": s_end,
                        "segmentId": "",
                        "tabId": state.tab_id,
                    },
                    "textStyle": sty,
                    "fields": flds,
                }
            })

    if cell_requests:
        body = {"requests": cell_requests}
        _gws("docs", "documents", "batchUpdate",
             "--params", json.dumps({"documentId": state.doc_id}),
             "--json", json.dumps(body))

    # Advance state.index past the table. GET the updated doc to find
    # the paragraph that follows the table.
    doc2 = _gws("docs", "documents", "get",
                "--params", json.dumps({
                    "documentId": state.doc_id,
                    "includeTabsContent": "true",
                }))
    after_index = _find_end_index_after_table(doc2, state.tab_id,
                                             min_index=pre_insert_index) or state.index
    state.index = after_index
    # Insert a blank line after the table. It lands at after_index (before the
    # segment trailing newline), shifting the trailing newline to after_index+1.
    # _insert_text increments state.index to after_index+1, which is exactly
    # where the next endOfSegmentLocation insert will land. Correct.
    _insert_text(state, "\n")   # state.index → after_index+1
    _flush_requests(state)


def _extract_cell_indices(doc: dict, tab_id: str,
                          num_rows: int, num_cols: int,
                          min_index: int = 0) -> list[int]:
    """Return the paragraph startIndex of each cell, row-major order.

    *min_index* selects the first table whose startIndex >= that value,
    so we always find the table we just inserted rather than any prior one.
    """
    for tab in doc.get("tabs", []):
        if tab.get("tabProperties", {}).get("tabId") != tab_id:
            continue
        body = tab.get("documentTab", {}).get("body", {})
        for el in body.get("content", []):
            tbl = el.get("table")
            if tbl is None:
                continue
            if el.get("startIndex", 0) < min_index:
                continue
            rows = tbl.get("tableRows", [])
            if len(rows) != num_rows:
                continue
            indices: list[int] = []
            for row in rows:
                for cell in row.get("tableCells", []):
                    content = cell.get("content", [])
                    if content:
                        para_si = content[0].get("startIndex")
                        if para_si is not None:
                            indices.append(para_si)
            if len(indices) == num_rows * num_cols:
                return indices
    return []


def _find_end_index_after_table(doc: dict, tab_id: str,
                                min_index: int = 0) -> int | None:
    """Return the startIndex of the paragraph that follows the first table
    at or after *min_index*.
    """
    for tab in doc.get("tabs", []):
        if tab.get("tabProperties", {}).get("tabId") != tab_id:
            continue
        body = tab.get("documentTab", {}).get("body", {})
        content = body.get("content", [])
        for i, el in enumerate(content):
            if "table" not in el:
                continue
            if el.get("startIndex", 0) < min_index:
                continue
            # Found the right table — return the start of the next element.
            if i + 1 < len(content):
                return content[i + 1].get("startIndex")
    return None


def _table_fallback(state: BuildState, all_rows: list[SyntaxTreeNode]) -> None:
    """Write a plain TSV representation when no doc_id is available."""
    _insert_text(state, "\n")
    for row in all_rows:
        cells = row.children
        cell_texts = [plain_text(c.children[0]) if c.children else ""
                      for c in cells]
        para_start = state.index
        _insert_text(state, "\t".join(cell_texts) + "\n")
        _paragraph_style(state, para_start, state.index, "NORMAL_TEXT")


def _flush_requests(state: BuildState) -> None:
    """Submit all pending requests to the API and clear the list.

    Ordering guarantee: text must exist before styles can be applied to it.
    Within a single batch the Docs API processes requests sequentially, so if
    an updateTextStyle runs before the insertText that places text at that
    range, the style is a no-op.  We also need updateParagraphStyle (named
    style) to run BEFORE updateTextStyle so that the named style's cascaded
    defaults don’t overwrite the explicit text styles we set afterward.

    Send order:
      1. All insertText / insertTable  — text must exist first
      2. All updateParagraphStyle      — named style defaults cascade
      3. All updateTextStyle           — explicit styles win over cascade
      4. Everything else (bullets, table cell styles, etc.)
    """
    if not state.requests or not state.doc_id:
        return

    inserts  = [r for r in state.requests if "insertText"  in r or "insertTable" in r]
    para_sty = [r for r in state.requests if "updateParagraphStyle" in r]
    text_sty = [r for r in state.requests if "updateTextStyle" in r]
    rest     = [r for r in state.requests
                if not any(k in r for k in (
                    "insertText", "insertTable",
                    "updateParagraphStyle", "updateTextStyle"))]

    ordered = inserts + para_sty + text_sty + rest

    batch_size = 500
    for i in range(0, len(ordered), batch_size):
        _gws("docs", "documents", "batchUpdate",
             "--params", json.dumps({"documentId": state.doc_id}),
             "--json", json.dumps({"requests": ordered[i:i + batch_size]}))
    state.requests.clear()


# ---------------------------------------------------------------------------
# Node dispatcher
# ---------------------------------------------------------------------------


def _process_node(state: BuildState, node: SyntaxTreeNode) -> None:
    t = node.type

    if t in ("front_matter", "html_block"):
        return

    if t == "heading":
        handle_heading(state, node)
    elif t == "paragraph":
        handle_paragraph(state, node)
    elif t == "fence":
        handle_fence(state, node)
    elif t == "code_block":
        handle_fence(state, node)
    elif t == "hr":
        handle_hr(state, node)
    elif t in ("bullet_list", "ordered_list"):
        handle_list(state, node)
    elif t == "blockquote":
        handle_blockquote(state, node)
    elif t == "table":
        handle_table(state, node)
    elif t == "root":
        for child in node.children:
            _process_node(state, child)
    else:
        for child in node.children:
            _process_node(state, child)


# ---------------------------------------------------------------------------
# Top-level: build requests for one file
# ---------------------------------------------------------------------------


def build_requests(path: Path, state: BuildState) -> list[Request]:
    """Parse *path* and populate *state* with batchUpdate requests."""
    text = path.read_text(encoding="utf-8")
    _meta, root = parse(text)
    _process_node(state, root)
    return state.requests


def extract_tab_regions(doc: dict, tab_id: str) -> list[Region]:
    """Extract editable leaf regions from *tab_id* in *doc*.

    Each Region carries *raw_para* — the full API paragraph dict — so that
    render_tab_as_markdown() can reconstruct inline styles and structure.
    """
    regions: list[Region] = []
    tab = _find_tab(doc.get("tabs", []), tab_id)
    if tab is None:
        return []

    body = tab.get("documentTab", {}).get("body", {})
    for el in body.get("content", []):
        para = el.get("paragraph")
        if para is not None:
            text = _paragraph_text_from_api(para)
            named_style = para.get("paragraphStyle", {}).get("namedStyleType", "")
            hlevel = _NAMED_STYLE_TO_HEADING.get(named_style, 0)
            regions.append(Region(
                kind="paragraph",
                tab_id=tab_id,
                start_api=el.get("startIndex", 0),
                end_api=el.get("endIndex", 0),
                text=text,
                heading_level=hlevel,
                raw_para=para,
            ))
            continue

        table = el.get("table")
        if table is not None:
            table_start = el.get("startIndex", 0)
            num_header_rows = table.get("tableStyle", {}).get("tableColumnProperties", [])
            # Detect header rows: the first row of a table is treated as the
            # header when all its cells have bold text or when the table has a
            # headerRowCount. Fall back to row_idx == 0 as a safe heuristic.
            header_row_count = 1  # GDocs tables always treat row 0 as header for MD purposes
            for row_idx, row in enumerate(table.get("tableRows", [])):
                is_header = row_idx < header_row_count
                for col_idx, cell in enumerate(row.get("tableCells", [])):
                    content = cell.get("content", [])
                    if not content:
                        continue
                    for cell_el in content:
                        cell_para = cell_el.get("paragraph")
                        if cell_para is None:
                            continue
                        cell_text = _paragraph_text_from_api(cell_para)
                        regions.append(Region(
                            kind="table_cell",
                            tab_id=tab_id,
                            start_api=cell_el.get("startIndex", 0),
                            end_api=cell_el.get("endIndex", 0),
                            text=cell_text,
                            row=row_idx,
                            col=col_idx,
                            table_start_api=table_start,
                            raw_para=cell_para,
                            is_table_header=is_header,
                        ))
            continue

    return regions




    """Convert text hunks to Docs API batchUpdate requests."""
    requests: list[Request] = []
    for hunk in sorted(hunks, key=lambda h: h.start_api, reverse=True):
        if hunk.end_api > hunk.start_api:
            requests.append({
                "deleteContentRange": {
                    "range": {
                        "startIndex": hunk.start_api,
                        "endIndex": hunk.end_api,
                        "segmentId": "",
                        "tabId": hunk.tab_id,
                    }
                }
            })
        if hunk.new_text:
            requests.append({
                "insertText": {
                    "location": {
                        "index": hunk.start_api,
                        "segmentId": "",
                        "tabId": hunk.tab_id,
                    },
                    "text": hunk.new_text,
                }
            })
    return requests


def find_tab_by_title_or_id(doc: dict, title_or_id: str) -> tuple[str, str]:
    """Return (tab_id, tab_title) for *title_or_id* from *doc*."""
    wanted_title = title_or_id.casefold()
    title_match = _find_tab_by_title(doc.get("tabs", []), wanted_title)
    if title_match is not None:
        props = title_match.get("tabProperties", {})
        return props.get("tabId", ""), props.get("title", "")

    id_match = _find_tab(doc.get("tabs", []), title_or_id)
    if id_match is not None:
        props = id_match.get("tabProperties", {})
        return props.get("tabId", ""), props.get("title", "")

    known = ", ".join(_tab_labels(doc.get("tabs", [])))
    print(f"Tab not found: {title_or_id}. Available tabs: {known}", file=sys.stderr)
    sys.exit(1)


def _find_tab(tabs: list[dict], tab_id: str) -> dict | None:
    for tab in tabs:
        props = tab.get("tabProperties", {})
        if props.get("tabId") == tab_id:
            return tab
        child_match = _find_tab(tab.get("childTabs", []), tab_id)
        if child_match is not None:
            return child_match
    return None


def _find_tab_by_title(tabs: list[dict], wanted_title: str) -> dict | None:
    for tab in tabs:
        props = tab.get("tabProperties", {})
        if str(props.get("title", "")).casefold() == wanted_title:
            return tab
        child_match = _find_tab_by_title(tab.get("childTabs", []), wanted_title)
        if child_match is not None:
            return child_match
    return None


def _tab_labels(tabs: list[dict]) -> list[str]:
    labels: list[str] = []
    for tab in tabs:
        props = tab.get("tabProperties", {})
        title = props.get("title", "")
        tab_id = props.get("tabId", "")
        if title and tab_id:
            labels.append(f"{title} ({tab_id})")
        labels.extend(_tab_labels(tab.get("childTabs", [])))
    return labels



def _paragraph_text_from_api(paragraph: dict) -> str:
    parts: list[str] = []
    for el in paragraph.get("elements", []):
        run = el.get("textRun")
        if run is None:
            continue
        parts.append(run.get("content", ""))
    text = "".join(parts)
    if text.endswith("\n"):
        text = text[:-1]
    return text


# ---------------------------------------------------------------------------
# gws CLI helpers
# ---------------------------------------------------------------------------


def _gws(*args: str, _retries: int = 5, _backoff: float = 10.0) -> dict:
    """Call the gws CLI and return parsed JSON output.

    Retries on HTTP 429 (quota exceeded) with exponential backoff.
    """
    cmd = ["gws"] + list(args) + ["--format", "json"]
    for attempt in range(_retries):
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode == 0:
            return json.loads(result.stdout) if result.stdout.strip() else {}
        if "429" in result.stderr or "quota" in result.stderr.lower() or "rate" in result.stderr.lower():
            wait = _backoff * (2 ** attempt)
            print(f"Rate limit hit, retrying in {wait:.0f}s…", file=sys.stderr)
            time.sleep(wait)
            continue
        print(f"gws error:\n{result.stderr}", file=sys.stderr)
        sys.exit(1)
    print(f"gws: exceeded retry limit", file=sys.stderr)
    sys.exit(1)

def create_document(title: str) -> tuple[str, str]:
    """Create a new Google Doc and return (doc_id, first_tab_id)."""
    resp = _gws("docs", "documents", "create",
                "--json", json.dumps({"title": title}))
    doc_id = resp["documentId"]
    # First tab always has tabId "t.0".
    first_tab_id = resp["tabs"][0]["tabProperties"]["tabId"]
    return doc_id, first_tab_id


def add_tab(doc_id: str, title: str) -> str:
    """Add a new tab to *doc_id* and return its tabId."""
    body = {
        "requests": [
            {
                "addDocumentTab": {
                    "tabProperties": {"title": title},
                }
            }
        ]
    }
    resp = _gws("docs", "documents", "batchUpdate",
                "--params", json.dumps({"documentId": doc_id}),
                "--json", json.dumps(body))
    return resp["replies"][0]["addDocumentTab"]["tabProperties"]["tabId"]


def rename_tab(doc_id: str, tab_id: str, title: str) -> None:
    """Rename *tab_id* in *doc_id*."""
    body = {
        "requests": [
            {
                "updateDocumentTabProperties": {
                    "tabProperties": {"tabId": tab_id, "title": title},
                    "fields": "title",
                }
            }
        ]
    }
    _gws("docs", "documents", "batchUpdate",
         "--params", json.dumps({"documentId": doc_id}),
         "--json", json.dumps(body))


def write_tab(doc_id: str, requests: list[Request]) -> None:
    """Submit *requests* to the API in batches of 500."""
    batch_size = 500
    for i in range(0, len(requests), batch_size):
        batch = requests[i:i + batch_size]
        _gws("docs", "documents", "batchUpdate",
             "--params", json.dumps({"documentId": doc_id}),
             "--json", json.dumps({"requests": batch}))


# ---------------------------------------------------------------------------
# Tab title derivation
# ---------------------------------------------------------------------------


def derive_tab_title(path: Path) -> str:
    """Return a tab title: first H1 if present, else the stem of the filename."""
    text = path.read_text(encoding="utf-8")
    for line in text.splitlines():
        line = line.strip()
        if line.startswith("# "):
            title = line[2:].strip()
            if title:
                return title[:100]
    return path.stem.replace("-", " ").replace("_", " ").title()


# ---------------------------------------------------------------------------
# Second-pass link resolution
# ---------------------------------------------------------------------------


def _build_heading_map(doc: dict) -> dict[str, dict[str, str]]:
    """Walk all tabs in *doc* and return {tab_id: {slug: headingId}}.

    The slug is derived from heading text using _slug(). Both the raw text
    slug and the tab title stem are indexed for matching fragment and
    relative-file hrefs.
    """
    result: dict[str, dict[str, str]] = {}
    for tab in doc.get("tabs", []):
        tab_id = tab["tabProperties"]["tabId"]
        slug_map: dict[str, str] = {}
        body = tab.get("documentTab", {}).get("body", {})
        for el in body.get("content", []):
            para = el.get("paragraph")
            if not para:
                continue
            ps = para.get("paragraphStyle", {})
            heading_id = ps.get("headingId", "")
            if not heading_id:
                continue
            # Collect the heading's plain text.
            text = "".join(
                pe.get("textRun", {}).get("content", "")
                for pe in para.get("elements", [])
            ).strip()
            if text:
                slug_map[_slug(text)] = heading_id
        result[tab_id] = slug_map
    return result


def resolve_deferred_links(
    doc_id: str,
    tab_id_list: list[str],
    tab_map: dict[str, str],
    deferred_per_tab: dict[str, list[tuple[int, int, str]]],
) -> None:
    """Second pass: resolve deferred links and patch the doc.

    For each tab that has deferred links:
    - Fragment links (#slug) → headingId within the same tab.
    - Relative .md links (./file.md) → tabId link.
    - Relative .md#slug links (./file.md#slug) → tabId link (headingId is
      tab-scoped only, so cross-tab heading links resolve to the tab).

    Skips any link whose target cannot be resolved.
    """
    # Flatten check: any deferred links at all?
    total = sum(len(v) for v in deferred_per_tab.values())
    if total == 0:
        return

    print(f"Resolving {total} deferred link(s)\u2026", file=sys.stderr)

    # GET the full doc to build heading maps.
    doc = _gws("docs", "documents", "get",
               "--params", json.dumps({
                   "documentId": doc_id,
                   "includeTabsContent": "true",
               }))

    heading_map = _build_heading_map(doc)  # {tab_id: {slug: headingId}}

    # Reverse tab_map: tab_id → stem (for looking up target tab from stem).
    stem_to_tab: dict[str, str] = {stem: tid for stem, tid in tab_map.items()}

    for tab_id, deferred in deferred_per_tab.items():
        if not deferred:
            continue

        same_tab_headings = heading_map.get(tab_id, {})
        patch_requests: list[Request] = []

        for start, end, href in deferred:
            link_style: dict | None = None

            if href.startswith("#"):
                # Same-tab fragment link.
                slug = _slug(href[1:])
                heading_id = same_tab_headings.get(slug)
                if heading_id:
                    link_style = {"headingId": heading_id}
                else:
                    print(f"  warn: no headingId for slug {slug!r} in tab {tab_id}",
                          file=sys.stderr)

            elif _RELATIVE_MD_RE.match(href):
                path_part, _, fragment = href.partition("#")
                stem = Path(path_part).stem
                target_tab_id = stem_to_tab.get(stem)
                if target_tab_id:
                    if fragment:
                        # Try to resolve to a specific heading in the target tab.
                        # Cross-tab headingId is not supported by the API, so we
                        # fall back to a tab-level link.
                        target_headings = heading_map.get(target_tab_id, {})
                        slug = _slug(fragment)
                        # tabId link is the best we can do cross-tab.
                        link_style = {"tabId": target_tab_id}
                        if slug not in target_headings:
                            print(
                                f"  info: cross-tab heading #{fragment!r} in", 
                                f"{stem!r} not resolvable to headingId; linking to tab",
                                file=sys.stderr,
                            )
                    else:
                        link_style = {"tabId": target_tab_id}
                else:
                    print(f"  warn: no tab found for stem {stem!r}", file=sys.stderr)

            if link_style is None:
                # Unresolvable link — mark text red so it's visible for manual fix.
                patch_requests.append({
                    "updateTextStyle": {
                        "range": {
                            "startIndex": start,
                            "endIndex": end,
                            "segmentId": "",
                            "tabId": tab_id,
                        },
                        "textStyle": {
                            "foregroundColor": {
                                "color": {
                                    "rgbColor": {"red": 0.85, "green": 0.1, "blue": 0.1}
                                }
                            }
                        },
                        "fields": "foregroundColor",
                    }
                })
                continue

            patch_requests.append({
                "updateTextStyle": {
                    "range": {
                        "startIndex": start,
                        "endIndex": end,
                        "segmentId": "",
                        "tabId": tab_id,
                    },
                    "textStyle": {"link": link_style},
                    "fields": "link",
                }
            })

        if patch_requests:
            print(f"  patching {len(patch_requests)} link(s) in tab {tab_id}",
                  file=sys.stderr)
            batch_size = 500
            for i in range(0, len(patch_requests), batch_size):
                _gws("docs", "documents", "batchUpdate",
                     "--params", json.dumps({"documentId": doc_id}),
                     "--json", json.dumps({"requests": patch_requests[i:i+batch_size]}))


# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------


def cmd_create(args: argparse.Namespace) -> None:
    files = [Path(f) for f in args.files]
    for f in files:
        if not f.exists():
            print(f"File not found: {f}", file=sys.stderr)
            sys.exit(1)

    title = args.title or derive_tab_title(files[0])
    print(f"Creating document: {title!r}", file=sys.stderr)

    doc_id, first_tab_id = create_document(title)
    print(f"Document ID: {doc_id}", file=sys.stderr)

    # Build tab_map: filename stem → tab_id (for intra-doc link resolution).
    tab_map: dict[str, str] = {}
    tab_id_list: list[str] = [first_tab_id]

    # Pre-create all additional tabs so we have their IDs for tab_map before
    # writing content (links in tab 0 might reference tab 3, for example).
    for idx, path in enumerate(files[1:], start=1):
        tab_title = derive_tab_title(path)
        tab_id = add_tab(doc_id, tab_title)
        tab_id_list.append(tab_id)
        print(f"Created tab {idx}: {tab_title!r} ({tab_id})", file=sys.stderr)

    for path, tab_id in zip(files, tab_id_list):
        tab_map[path.stem] = tab_id

    # First tab: rename then write.
    first_title = derive_tab_title(files[0])
    rename_tab(doc_id, first_tab_id, first_title)
    print(f"Writing tab: {first_title!r} ({first_tab_id})\u2026", file=sys.stderr)
    state = BuildState(tab_id=first_tab_id, doc_id=doc_id, tab_map=tab_map)
    build_requests(files[0], state)
    _flush_requests(state)
    deferred_per_tab: dict[str, list[tuple[int, int, str]]] = {}
    deferred_per_tab[first_tab_id] = state.deferred_links

    # Remaining tabs.
    for path, tab_id in zip(files[1:], tab_id_list[1:]):
        tab_title = derive_tab_title(path)
        print(f"Writing tab: {tab_title!r} ({tab_id})\u2026", file=sys.stderr)
        state = BuildState(tab_id=tab_id, doc_id=doc_id, tab_map=tab_map)
        build_requests(path, state)
        _flush_requests(state)
        deferred_per_tab[tab_id] = state.deferred_links

    # Second pass: resolve deferred fragment and relative-file links.
    resolve_deferred_links(doc_id, tab_id_list, tab_map, deferred_per_tab)

    # Write back gdoc_url and gdoc_tab_id into each source file's frontmatter.
    doc_url = f"https://docs.google.com/document/d/{doc_id}/edit"
    for path, tab_id in zip(files, tab_id_list):
        patch_frontmatter(path, {
            "gdoc_url": doc_url,
            "gdoc_tab_id": tab_id,
        })
        print(f"Updated frontmatter: {path.name}", file=sys.stderr)

    print(doc_id)

def cmd_add_tab(args: argparse.Namespace) -> None:
    path = Path(args.file)
    if not path.exists():
        print(f"File not found: {path}", file=sys.stderr)
        sys.exit(1)

    doc_id = args.document
    tab_title = args.title or derive_tab_title(path)

    print(f"Adding tab {tab_title!r} to document {doc_id}…", file=sys.stderr)
    tab_id = add_tab(doc_id, tab_title)

    # Build a minimal tab_map from the existing doc's tabs.
    doc = _gws("docs", "documents", "get",
               "--params", json.dumps({"documentId": doc_id}))
    tab_map: dict[str, str] = {}
    for tab in doc.get("tabs", []):
        props = tab.get("tabProperties", {})
        existing_title = props.get("title", "")
        existing_id = props.get("tabId", "")
        if existing_title and existing_id:
            tab_map[existing_title] = existing_id

    state = BuildState(tab_id=tab_id, doc_id=doc_id, tab_map=tab_map)
    build_requests(path, state)
    _flush_requests(state)

    # Second pass: resolve deferred links.
    deferred_per_tab = {tab_id: state.deferred_links}
    resolve_deferred_links(doc_id, [tab_id], tab_map, deferred_per_tab)

    # Write back gdoc_url and gdoc_tab_id into the source file's frontmatter.
    doc_url = f"https://docs.google.com/document/d/{doc_id}/edit"
    patch_frontmatter(path, {
        "gdoc_url": doc_url,
        "gdoc_tab_id": tab_id,
    })
    print(f"Updated frontmatter: {path.name}", file=sys.stderr)

    print(tab_id)

# ---------------------------------------------------------------------------
# Markdown rendering from live API content
# ---------------------------------------------------------------------------


_NAMED_STYLE_TO_HEADING: dict[str, int] = {
    "HEADING_1": 1,
    "HEADING_2": 2,
    "HEADING_3": 3,
    "HEADING_4": 4,
    "HEADING_5": 5,
    "HEADING_6": 6,
}


def _slugify(title: str) -> str:
    """Convert a tab title to a lowercase-hyphenated slug.

    'Proposal process' -> 'proposal-process'
    'Senior Staff+ Design Consultation' -> 'senior-staff-design-consultation'
    """
    import re
    slug = title.lower()
    slug = re.sub(r"[^a-z0-9]+", "-", slug)
    return slug.strip("-")


def _build_tab_slug_map(doc: dict) -> dict[str, str]:
    """Return a mapping of tabId → slug derived from tab titles.

    Used to render internal tab links as Obsidian wikilinks.
    """
    result: dict[str, str] = {}

    def _walk(tabs: list) -> None:
        for tab in tabs:
            props = tab.get("tabProperties", {})
            tab_id = props.get("tabId", "")
            title = props.get("title", "")
            if tab_id and title:
                result[tab_id] = _slugify(title)
            _walk(tab.get("childTabs", []))

    _walk(doc.get("tabs", []))
    return result


def _build_heading_slug_map(doc: dict, tab_id: str) -> dict[str, str]:
    """Return a mapping of headingId → slug for all headings in *tab_id*.

    Used to render internal heading links as Obsidian wikilinks.
    A link to heading id 'h.vppnh7y8ykem' whose text is
    '01 Decision Chart — Process selection' renders as
    '[[01-decision-chart---process-selection|display]]'.
    """
    result: dict[str, str] = {}
    tab = _find_tab(doc.get("tabs", []), tab_id)
    if tab is None:
        return result
    body = tab.get("documentTab", {}).get("body", {})
    for el in body.get("content", []):
        para = el.get("paragraph")
        if not para:
            continue
        ps = para.get("paragraphStyle", {})
        heading_id = ps.get("headingId", "")
        if not heading_id:
            continue
        text = "".join(
            pe.get("textRun", {}).get("content", "")
            for pe in para.get("elements", [])
        ).strip()
        if text:
            result[heading_id] = _slugify(text)
    return result


def _render_text_run(
    run: dict,
    tab_slug_map: dict[str, str] | None = None,
    heading_slug_map: dict[str, str] | None = None,
    strip_bold: bool = False,
) -> str:
    """Render a single textRun dict as inline markdown.

    Applies bold, italic, strikethrough, code (monospace font), and links.
    Internal tab links are rendered as Obsidian wikilinks using *tab_slug_map*.
    Set *strip_bold* to suppress bold markers (used for table header cells).
    """
    content = run.get("content", "")
    if not content or content == "\n":
        return ""
    content = content.replace("\n", "")
    if not content:
        return ""
    style = run.get("textStyle", {})

    is_code = bool(
        style.get("weightedFontFamily", {}).get("fontFamily", "") == "Courier New"
    )
    is_bold = bool(style.get("bold")) and not strip_bold
    is_italic = bool(style.get("italic"))
    is_strike = bool(style.get("strikethrough"))
    link = style.get("link", {})
    link_url = link.get("url", "") or ""

    text = content

    if is_code:
        escaped = text.replace("`", "\\`")
        text = f"`{escaped}`"
    else:
        if is_strike:
            text = f"~~{text}~~"
        if is_bold and is_italic:
            text = f"***{text}***"
        elif is_bold:
            text = f"**{text}**"
        elif is_italic:
            text = f"*{text}*"

    if link_url:
        text = f"[{text}]({link_url})"
    elif "tabId" in link:
        tab_id = link["tabId"]
        slug = (tab_slug_map or {}).get(tab_id, tab_id)
        # Render as Obsidian wikilink: [[slug|display]] or [[slug]] if display == slug
        display = content  # use unstyled content as display text
        text = f"[[{slug}|{display}]]"
    elif "headingId" in link:
        # Internal heading anchor — render as [[#headingId|display]]
        heading_id = link["headingId"]
        slug = (heading_slug_map or {}).get(heading_id, "")
        display = content
        if slug:
            text = f"[[{slug}|{display}]]" if display != slug else f"[[{slug}]]"
        else:
            text = f"[[#{heading_id}|{display}]]"

    return text


def _render_paragraph_as_markdown(
    para: dict,
    bullet_counters: dict,
    tab_slug_map: dict[str, str] | None = None,
    heading_slug_map: dict[str, str] | None = None,
    strip_bold: bool = False,
) -> str:
    """Render a single API paragraph dict as a markdown string (no trailing newline).

    *bullet_counters* is a mutable dict used to track ordered-list counters
    keyed by (listId, nestingLevel).
    *tab_slug_map* is used to resolve internal tab links to wikilinks.
    *strip_bold* suppresses bold markers (used for table header cells).
    """
    ps = para.get("paragraphStyle", {})
    named_style = ps.get("namedStyleType", "NORMAL_TEXT")
    bullet = para.get("bullet")

    # Thematic break: empty paragraph with a bottom border.
    if ps.get("borderBottom") and not any(
        pe.get("textRun", {}).get("content", "").strip()
        for pe in para.get("elements", [])
    ):
        return "---"

    # Build inline content from text runs.
    inline = ""
    for pel in para.get("elements", []):
        run = pel.get("textRun")
        if run is not None:
            inline += _render_text_run(run, tab_slug_map=tab_slug_map, heading_slug_map=heading_slug_map, strip_bold=strip_bold)

    # Task list checkboxes: \u2610 (unchecked) or \u2611 (checked) prefix.
    # These were written by md2gdoc from '- [ ]' / '- [x]' syntax.
    if inline.startswith("\u2610  "):
        return "- [ ] " + inline[3:]
    if inline.startswith("\u2611  "):
        return "- [x] " + inline[3:]

    # Heading.
    heading_level = _NAMED_STYLE_TO_HEADING.get(named_style, 0)
    if heading_level:
        prefix = "#" * heading_level
        return f"{prefix} {inline}"

    # List item.
    if bullet is not None:
        nesting = bullet.get("nestingLevel", 0)
        indent = "  " * nesting
        list_props = bullet.get("listProperties", {})
        nesting_levels = list_props.get("nestingLevels", [])
        glyph_type = ""
        if nesting_levels and nesting < len(nesting_levels):
            glyph_type = nesting_levels[nesting].get("glyphType", "")
        if glyph_type in ("DECIMAL", "ALPHA", "ROMAN",
                          "UPPER_ALPHA", "UPPER_ROMAN",
                          "LOWER_ALPHA", "LOWER_ROMAN"):
            key = (bullet.get("listId", ""), nesting)
            bullet_counters[key] = bullet_counters.get(key, 0) + 1
            return f"{indent}{bullet_counters[key]}. {inline}"
        return f"{indent}- {inline}"

    # Normal paragraph.
    return inline


def _collect_table_regions(regions: list[Region]) -> list[list[list[Region]]]:
    """Group consecutive table_cell regions into a 2-D grid.

    Returns a list of tables; each table is a list of rows; each row is a list
    of cell Regions. Assumes regions are in document order.
    """
    tables: list[list[list[Region]]] = []
    i = 0
    while i < len(regions):
        if regions[i].kind != "table_cell":
            i += 1
            continue
        # Collect all consecutive table_cell regions from the same table.
        table_start_api = regions[i].table_start_api
        cells: list[Region] = []
        while i < len(regions) and regions[i].kind == "table_cell" and regions[i].table_start_api == table_start_api:
            cells.append(regions[i])
            i += 1
        if not cells:
            continue
        # Determine grid dimensions.
        max_row = max(c.row for c in cells)
        max_col = max(c.col for c in cells)
        grid: list[list[Region | None]] = [
            [None] * (max_col + 1) for _ in range(max_row + 1)
        ]
        for c in cells:
            grid[c.row][c.col] = c
        tables.append(grid)  # type: ignore[arg-type]
    return tables


def render_tab_as_markdown(
    regions: list[Region],
    tab_slug_map: dict[str, str] | None = None,
    heading_slug_map: dict[str, str] | None = None,
) -> str:
    """Render a list of Regions extracted from a live tab as a markdown string.

    Paragraph regions are rendered using their *raw_para* dict to recover inline
    styles (bold, italic, code, links). Table cell regions are grouped into
    GFM tables. Internal tab links are rendered as Obsidian wikilinks when
    *tab_slug_map* is provided.
    """
    lines: list[str] = []
    bullet_counters: dict = {}
    i = 0
    while i < len(regions):
        region = regions[i]

        if region.kind == "paragraph":
            if not region.raw_para.get("bullet"):
                bullet_counters = {}
            md = _render_paragraph_as_markdown(
                region.raw_para, bullet_counters,
                tab_slug_map=tab_slug_map, heading_slug_map=heading_slug_map,
            )
            if md.strip():
                lines.append(md)
            i += 1
            continue

        if region.kind == "table_cell":
            table_start_api = region.table_start_api
            cells: list[Region] = []
            j = i
            while j < len(regions) and regions[j].kind == "table_cell" and regions[j].table_start_api == table_start_api:
                cells.append(regions[j])
                j += 1

            if cells:
                max_row = max(c.row for c in cells)
                max_col = max(c.col for c in cells)
                grid: list[list[str]] = [[""] * (max_col + 1) for _ in range(max_row + 1)]
                for c in cells:
                    cell_md = _render_paragraph_as_markdown(
                        c.raw_para, {},
                        tab_slug_map=tab_slug_map, heading_slug_map=heading_slug_map,
                        strip_bold=c.is_table_header,
                    ) if c.raw_para else c.text
                    grid[c.row][c.col] = cell_md

                if grid:
                    header = "| " + " | ".join(grid[0]) + " |"
                    separator = "| " + " | ".join(":---" for _ in grid[0]) + " |"
                    lines.append(header)
                    lines.append(separator)
                    for row in grid[1:]:
                        lines.append("| " + " | ".join(row) + " |")
                    lines.append("")

            i = j
            continue

        i += 1

    return "\n".join(lines)



def cmd_extract_tab(args: argparse.Namespace) -> None:
    doc_id = args.document
    doc = _gws("docs", "documents", "get",
               "--params", json.dumps({
                   "documentId": doc_id,
                   "includeTabsContent": "true",
               }))

    tab_id, _tab_title = find_tab_by_title_or_id(doc, args.tab)
    tab_slug_map = (
        load_tab_slug_map_from_files(sorted(Path(args.files_dir).glob("*.md")))
        if getattr(args, "files_dir", None)
        else _build_tab_slug_map(doc)
    )
    heading_slug_map = _build_heading_slug_map(doc, tab_id)
    regions = extract_tab_regions(doc, tab_id)
    print(render_tab_as_markdown(regions, tab_slug_map=tab_slug_map, heading_slug_map=heading_slug_map))



# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Convert Markdown to Google Docs with tab support.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    sub = parser.add_subparsers(dest="command", required=True)

    p_create = sub.add_parser(
        "create",
        help="Create a new Google Doc from one or more Markdown files.",
    )
    p_create.add_argument(
        "--title",
        metavar="TITLE",
        help="Document title (defaults to the first H1 of the first file).",
    )
    p_create.add_argument(
        "files",
        nargs="+",
        metavar="FILE",
        help="Markdown files to include as tabs (one tab per file).",
    )

    p_add = sub.add_parser(
        "add-tab",
        help="Add a new tab to an existing Google Doc.",
    )
    p_add.add_argument(
        "--document",
        required=True,
        metavar="DOC_ID",
        help="Target document ID.",
    )
    p_add.add_argument(
        "--title",
        metavar="TITLE",
        help="Tab title (defaults to the first H1 or filename stem).",
    )
    p_add.add_argument(
        "file",
        metavar="FILE",
        help="Markdown file to write into the new tab.",
    )

    p_extract = sub.add_parser(
        "extract-tab",
        help="Extract plain text from an existing Google Doc tab.",
    )
    p_extract.add_argument(
        "--document",
        required=True,
        metavar="DOC_ID",
        help="Target document ID.",
    )
    p_extract.add_argument(
        "--tab",
        required=True,
        metavar="TITLE_OR_ID",
        help="Tab title (case-insensitive) or exact tab ID.",
    )
    p_extract.add_argument(
        "--files-dir",
        metavar="DIR",
        default=None,
        help="Directory of local markdown files with gdoc_tab_id frontmatter for exact wikilink slug resolution.",
    )


    args = parser.parse_args()

    if args.command == "create":
        cmd_create(args)
    elif args.command == "add-tab":
        cmd_add_tab(args)
    elif args.command == "extract-tab":
        cmd_extract_tab(args)


if __name__ == "__main__":
    main()
