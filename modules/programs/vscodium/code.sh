#!/usr/bin/env bash
# Launch VSCodium with optional profile support.
#
# With arguments: passes them directly to codium.
# Without arguments: walks up from $PWD looking for a *.code-workspace file.
#   If found, opens it. If not, launches empty.
#
# If VSCODE_PROFILE is set, always passes --profile <name> to codium.

args=()
[[ -n "$VSCODE_PROFILE" ]] && args+=("--profile" "$VSCODE_PROFILE")

if [[ $# -gt 0 ]]; then
  exec codium "${args[@]}" "$@"
fi

dir="$PWD"
while [[ "$dir" != "/" ]]; do
  for ws in "$dir"/*.code-workspace; do
    if [[ -e "$ws" ]]; then
      exec codium "${args[@]}" "$ws"
    fi
  done
  dir="${dir%/*}"
done

# No workspace found — launch empty
exec codium "${args[@]}"
