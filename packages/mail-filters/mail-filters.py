#!/usr/bin/env python3
"""Declarative mail filter management.

One rules file, two backends:
  sync   - apply rules to Gmail via the `gws` CLI (official Gmail API)
  sieve  - render rules as a Sieve script for Fastmail (paste into their UI)

Rules file schema (JSON):
  {
    "labels": ["ops/github"],                  # Gmail labels to ensure exist
    "rules": [
      {
        "name": "github",                      # optional, used in sieve comments
        "match": {                             # fields are ANDed
          "from": "github.com",              # substring match on sender
          "to": "team@example.com",
          "subject": "invoice",
          "query": "list:foo.example.com",   # raw Gmail search syntax (Gmail only)
          "hasAttachment": true              # Gmail only
        },
        "actions": {
          "label": "ops/github",             # label (Gmail) / fileinto (Sieve)
          "archive": true,                   # remove from inbox
          "markRead": true,
          "forward": "addr@example.com",     # forward (Gmail) / redirect (Sieve)
          "discard": false                   # trash (Gmail) / discard (Sieve)
        }
      }
    ]
  }
"""

import argparse
import json
import os
import subprocess
import sys
from typing import NoReturn

MATCH_FIELDS = ("from", "to", "subject", "query", "negatedQuery", "hasAttachment")
GMAIL_ONLY_MATCH = ("query", "negatedQuery", "hasAttachment")


def fail(msg) -> NoReturn:
    print(f"error: {msg}", file=sys.stderr)
    sys.exit(1)


def load_rules(path):
    """Load and minimally validate the rules file."""
    try:
        with open(path) as f:
            data = json.load(f)
    except (OSError, json.JSONDecodeError) as e:
        fail(f"cannot load rules from {path}: {e}")
    for i, rule in enumerate(data.get("rules", [])):
        name = rule.get("name", f"rule[{i}]")
        if not rule.get("match"):
            fail(f"{name}: 'match' is required")
        if not rule.get("actions"):
            fail(f"{name}: 'actions' is required")
        unknown = set(rule["match"]) - set(MATCH_FIELDS)
        if unknown:
            fail(f"{name}: unknown match fields: {', '.join(sorted(unknown))}")
    return data


# --- Gmail backend -----------------------------------------------------------

def gws_json(args, params=None, body=None):
    """Run a gws command and parse its JSON stdout."""
    cmd = ["gws", "gmail", *args]
    if params:
        cmd += ["--params", json.dumps(params)]
    if body is not None:
        cmd += ["--json", json.dumps(body)]
    try:
        result = subprocess.run(cmd, capture_output=True, text=True)
    except FileNotFoundError:
        fail("gws not found on PATH (install gws or run from a profile that has it)")
    if result.returncode != 0:
        fail(f"gws {' '.join(args)} failed:\n{result.stderr.strip() or result.stdout.strip()}")
    try:
        # gws may print banners (e.g. "Using keyring backend: ...") on stdout
        # before the JSON payload; skip to the first JSON value.
        out = result.stdout
        start = min((i for i in (out.find("{"), out.find("[")) if i != -1), default=-1)
        if start == -1:
            raise json.JSONDecodeError("no JSON in output", out, 0)
        return json.loads(out[start:])
    except json.JSONDecodeError:
        fail(f"gws {' '.join(args)} returned non-JSON output:\n{result.stdout[:500]}")


def gmail_filter(rule):
    """Compile a rule to a Gmail Filter resource (criteria + action)."""
    criteria = {k: rule["match"][k] for k in MATCH_FIELDS if k in rule["match"]}
    a = rule["actions"]
    add, remove = [], []
    if a.get("label"):
        add.append(a["label"])
    if a.get("archive"):
        remove.append("INBOX")
    if a.get("markRead"):
        remove.append("UNREAD")
    if a.get("discard"):
        add.append("TRASH")
    action = {}
    if add:
        action["addLabelIds"] = add
    if remove:
        action["removeLabelIds"] = remove
    if a.get("forward"):
        action["forward"] = a["forward"]
    if not action:
        fail(f"{rule.get('name', '?')}: no actions produced")
    return {"criteria": criteria, "action": action}


def filter_key(filt):
    """Canonical key for exact-match comparison. Label id lists are sorted:
    Gmail treats them as sets and its stored ordering (e.g. UNREAD before
    INBOX) need not match ours."""
    body = json.loads(json.dumps(filt))
    for ids in ("addLabelIds", "removeLabelIds"):
        if ids in body["action"]:
            body["action"][ids] = sorted(body["action"][ids])
    return json.dumps(body, sort_keys=True)


def sync_gmail(rules, dry_run, prune=False):
    """Idempotently apply rules to Gmail: ensure labels, then filters.

    With prune=True, also delete existing filters that no rule matches.
    """
    def run(args, params=None, body=None):
        if dry_run:
            cmd = ["gws", "gmail", *args]
            if params:
                cmd += ["--params", json.dumps(params)]
            if body is not None:
                cmd += ["--json", json.dumps(body)]
            print("+ " + " ".join(cmd))
            return {}
        return gws_json(args, params, body)

    labels = {l["name"]: l["id"] for l in run(["users", "labels", "list"], {"userId": "me"}).get("labels", [])}

    # Ensure user labels exist; system labels (INBOX, TRASH, ...) are their own ids.
    for name in rules.get("labels", []):
        if name not in labels:
            created = run(
                ["users", "labels", "create"],
                {"userId": "me"},
                body={"name": name, "labelListVisibility": "labelShow"},
            )
            labels[name] = created.get("id", name)
            print(f"label created: {name}")

    # Resolve label names to ids up front so keys match what the API returns.
    wanted = []  # (filter body, display name)
    for rule in rules["rules"]:
        filt = gmail_filter(rule)
        for ids in ("addLabelIds", "removeLabelIds"):
            if ids in filt["action"]:
                filt["action"][ids] = [labels.get(l, l) for l in filt["action"][ids]]
        wanted.append((filt, rule.get("name", json.dumps(filt["criteria"]))))

    existing = {
        f["id"]: filter_key({k: f[k] for k in ("criteria", "action")})
        for f in run(["users", "settings", "filters", "list"], {"userId": "me"}).get("filter", [])
    }

    created = skipped = pruned = 0
    for filt, name in wanted:
        if filter_key(filt) in existing.values():
            skipped += 1
            print(f"filter exists, skipping: {name}")
        else:
            run(["users", "settings", "filters", "create"], {"userId": "me"}, filt)
            created += 1
            print(f"filter created: {name}")

    if prune:
        wanted_keys = {filter_key(filt) for filt, _ in wanted}
        for fid, key in existing.items():
            if key not in wanted_keys:
                run(["users", "settings", "filters", "delete"], {"userId": "me", "id": fid})
                pruned += 1
                print(f"filter pruned: {fid}")

    summary = f"done: {created} created, {skipped} skipped" + (f", {pruned} pruned" if prune else "")
    print(summary + (" (dry run)" if dry_run else ""))


# --- Sieve backend -----------------------------------------------------------

def sieve_str(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def sieve_test(match, name):
    """Compile match fields to a Sieve test expression. Fields are ANDed."""
    for field in GMAIL_ONLY_MATCH:
        if field in match:
            fail(f"{name}: match.{field} has no Sieve equivalent; use from/to/subject for the Fastmail render")
    tests = []
    if "from" in match:
        tests.append(f"address :contains \"from\" {sieve_str(match['from'])}")
    if "to" in match:
        tests.append(f"address :contains \"to\" {sieve_str(match['to'])}")
    if "subject" in match:
        tests.append(f"header :contains \"subject\" {sieve_str(match['subject'])}")
    if not tests:
        fail(f"{name}: rule would match every message")
    if len(tests) == 1:
        return tests[0]
    return "allof (\n    " + ",\n    ".join(tests) + "\n  )"


def render_sieve(rules):
    """Render rules as a Sieve script. First matching rule wins (stop)."""
    lines = ["# Generated by mail-filters -- edit rules.json, not this file",
             'require ["fileinto", "imap4flags"];', ""]
    for rule in rules["rules"]:
        name = rule.get("name", "unnamed")
        a = rule["actions"]
        body = []
        if a.get("label"):
            # Fastmail uses "." as the folder hierarchy separator.
            body.append(f"fileinto {sieve_str(a['label'].replace('/', '.'))};")
        if a.get("markRead"):
            body.append('addflag "\\\\Seen";')
        if a.get("forward"):
            body.append(f"redirect {sieve_str(a['forward'])};")
        if a.get("discard"):
            body.append("discard;")
        if not body:
            fail(f"{name}: no actions produced")
        body.append("stop;")
        lines.append(f"# rule: {name}")
        lines.append(f"if {sieve_test(rule['match'], name)} {{")
        lines.extend(f"  {b}" for b in body)
        lines.append("}")
        lines.append("")
    return "\n".join(lines)


# --- Gmail XML import format --------------------------------------------------

def render_gmail_xml(rules):
    """Render rules as Gmail's filter import XML (Settings → Filters → Import).

    Note Gmail's XML property names differ from the API's: query/negatedQuery
    are hasTheWord/doesNotHaveTheWord here.
    """
    from xml.sax.saxutils import quoteattr

    match_props = {
        "from": "from",
        "to": "to",
        "subject": "subject",
        "query": "hasTheWord",
        "negatedQuery": "doesNotHaveTheWord",
    }
    action_props = {"archive": "shouldArchive", "markRead": "shouldMarkAsRead", "discard": "shouldTrash"}
    entries = []
    for rule in rules["rules"]:
        props = []
        for field, prop in match_props.items():
            if field in rule["match"]:
                props.append((prop, rule["match"][field]))
        if rule["match"].get("hasAttachment"):
            props.append(("hasAttachment", "true"))
        a = rule["actions"]
        if a.get("label"):
            props.append(("label", a["label"]))
        for field, prop in action_props.items():
            if a.get(field):
                props.append((prop, "true"))
        if a.get("forward"):
            props.append(("forwardTo", a["forward"]))
        body = "\n".join(f"    <apps:property name={quoteattr(k)} value={quoteattr(v)} />" for k, v in props)
        entries.append(
            '  <entry>\n    <category term="filter" />\n    <title>Mail Filter</title>\n'
            + body
            + "\n  </entry>"
        )
    return (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<feed xmlns:apps="http://schemas.google.com/apps/2006" xmlns="http://www.w3.org/2005/Atom">\n'
        + "\n".join(entries)
        + "\n</feed>\n"
    )


# --- selftest ----------------------------------------------------------------

def selftest():
    """Minimal checks for the compilers and the sync/prune logic."""
    import contextlib
    import io

    rule = {
        "name": "t",
        "match": {"from": "github.com", "subject": "ci"},
        "actions": {"label": "ops/github", "archive": True, "markRead": True},
    }
    g = gmail_filter(rule)
    assert g == {
        "criteria": {"from": "github.com", "subject": "ci"},
        "action": {"addLabelIds": ["ops/github"], "removeLabelIds": ["INBOX", "UNREAD"]},
    }, g
    s = render_sieve({"rules": [rule]})
    assert 'fileinto "ops.github";' in s, s
    assert 'addflag "\\\\Seen";' in s, s
    assert "stop;" in s and s.index("if ") < s.index("stop;"), s
    x = render_gmail_xml({"rules": [rule, {"name": "q", "match": {"query": "cc:me"}, "actions": {"label": "cc"}}]})
    assert 'name="hasTheWord" value="cc:me"' in x, x
    assert 'name="shouldArchive"' in x and 'name="label" value="ops/github"' in x, x

    # sync: identical filter is skipped, stale filter is pruned (gws stubbed).
    def stub(args, params=None, body=None):
        if args == ["users", "labels", "list"]:
            return {"labels": [{"name": "INBOX", "id": "INBOX"}, {"name": "ops/github", "id": "L1"}]}
        if args == ["users", "settings", "filters", "list"]:
            return {"filter": [
                {"id": "F1", "criteria": {"from": "stale.example.com"}, "action": {"addLabelIds": ["L1"]}},
                {"id": "F2", "criteria": {"from": "github.com", "subject": "ci"},
                 # Gmail's own label ordering (UNREAD first) must still match.
                 "action": {"addLabelIds": ["L1"], "removeLabelIds": ["UNREAD", "INBOX"]}},
            ]}
        return {"id": "NEW"}

    global gws_json
    orig = gws_json
    gws_json = stub
    try:
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            sync_gmail({"labels": [], "rules": [rule]}, dry_run=False, prune=True)
        text = out.getvalue()
    finally:
        gws_json = orig
    assert "filter exists, skipping: t" in text, text
    assert "filter pruned: F1" in text, text
    assert "done: 0 created, 1 skipped, 1 pruned" in text, text
    print("selftest ok")


# --- entry point -------------------------------------------------------------

def default_rules_path():
    env = os.environ.get("MAIL_FILTERS_RULES")
    if env:
        return env
    beside_script = os.path.join(os.path.dirname(os.path.abspath(__file__)), "rules.json")
    if os.path.exists(beside_script):
        return beside_script
    fail("no rules file: pass --rules, set MAIL_FILTERS_RULES, or place rules.json next to the script")


def main():
    p = argparse.ArgumentParser(description="Declarative mail filter management (Gmail sync / Fastmail Sieve render)")
    p.add_argument("--rules", help="path to rules file (default: $MAIL_FILTERS_RULES)")
    # Same flag accepted after the subcommand; SUPPRESS default keeps the
    # top-level value intact when it is not repeated.
    common = argparse.ArgumentParser(add_help=False)
    common.add_argument("--rules", default=argparse.SUPPRESS, help=argparse.SUPPRESS)
    sub = p.add_subparsers(dest="command", required=True)
    sync = sub.add_parser("sync", parents=[common], help="apply rules to Gmail via gws")
    sync.add_argument("--dry-run", action="store_true", help="print gws commands instead of running them")
    sync.add_argument("--prune", action="store_true", help="delete Gmail filters that no rule in the rules file matches")
    sub.add_parser("sieve", parents=[common], help="render rules as a Sieve script (Fastmail)")
    sub.add_parser("export", parents=[common], help="render rules as Gmail filter import XML")
    sub.add_parser("check", parents=[common], help="validate the rules file")
    sub.add_parser("selftest", help="run compiler self-checks")
    args = p.parse_args()

    if args.command == "selftest":
        selftest()
        return

    rules = load_rules(args.rules or default_rules_path())
    if args.command == "sync":
        sync_gmail(rules, args.dry_run)
    elif args.command == "sieve":
        print(render_sieve(rules))
    elif args.command == "export":
        print(render_gmail_xml(rules), end="")
    elif args.command == "check":
        print(f"ok: {len(rules.get('labels', []))} labels, {len(rules['rules'])} rules")


if __name__ == "__main__":
    main()
