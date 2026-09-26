#!/usr/bin/env python3
"""Static guard for perUser migrations.

Finds `perUser` blocks that still contain home-manager machinery the
perUser schema does not provide (freeformType would silently swallow it).
Run after each migration wave:  python3 scripts/per-user-audit.py

Exit code 1 = findings.
"""
import re
import sys
import pathlib

REPO = pathlib.Path(__file__).resolve().parent.parent

PERUSER_RE = re.compile(r"^(\s*)perUser\s*=")
CLASS_RE = re.compile(r"^(\s*)(homeManager|nixos|generic|tags|perUser)\s*=")

# perUser schema provides: packages, files, env, services, homeDirectory (+
# module-local options/hdwlinux declarations via freeform). Everything
# home-manager-specific inside a perUser block is a silent-loss bug.
FORBIDDEN = [
    (re.compile(r"^\s*(programs|xdg|wayland|fonts|qt|gtk|targets|manual|news|nix)\.", re.M), "hm option namespace"),
    (re.compile(r"^\s*home\.(?!packages)", re.M), "home.* (not packages)"),
    (re.compile(r"imports\s*=\s*[^\n]*homeManagerModules|inputs\.[\w-]+\.homeModules", re.M), "hm module pull via imports"),
    (re.compile(r"inputs\.home-manager|\blib\.hm\.|hm\.dag|homeManager"), "hm references"),
    (re.compile(r"config\.(home|xdg|programs|services|wayland)\b"), "read of hm-only option"),
]
# services.<name> at block root is our schema option IF it uses our serviceType
# keys only; hm services.X use enable+settings/package -- flag those shapes.
SERVICES_SHAPE = re.compile(
    r"^\s*services\.[\w-]+\s*=\s*\{[^}]*?\b(enable|settings|package|arguments|extraOptions)\b",
    re.M | re.S,
)


def per_user_bodies(text):
    lines = text.split("\n")
    for i, ln in enumerate(lines):
        m = PERUSER_RE.match(ln)
        if not m:
            continue
        indent = len(m.group(1))
        body = []
        for j in range(i + 1, len(lines)):
            m2 = CLASS_RE.match(lines[j])
            if m2 and len(m2.group(1)) <= indent:
                break
            body.append(lines[j])
        yield "\n".join(body)


def main():
    findings = 0
    for f in sorted((REPO / "modules").rglob("*.nix")):
        text = f.read_text()
        if "perUser" not in text:
            continue
        for body in per_user_bodies(text):
            for rx, why in FORBIDDEN:
                for m in rx.finditer(body):
                    print(f"{f}: {why}: {m.group(0)[:60]!r}")
                    findings += 1
            for m in SERVICES_SHAPE.finditer(body):
                print(f"{f}: hm-shaped services.*: {m.group(0)[:60]!r}")
                findings += 1
    if findings:
        print(f"FAIL: {findings} finding(s)")
        return 1
    print("OK: perUser blocks clean")
    return 0


if __name__ == "__main__":
    sys.exit(main())
