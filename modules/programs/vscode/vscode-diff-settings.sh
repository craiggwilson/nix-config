#!/usr/bin/env bash
# Compare settings.json against settings.canonical.json for VSCodium profiles.
#
# Lines present in settings.json but absent from canonical are manually-added
# settings that may need to be merged back into the Nix config.
#
# Usage:
#   vscode-diff-settings              # check all profiles
#   vscode-diff-settings default      # check a specific profile
#   vscode-diff-settings nix rust     # check multiple profiles
#   vscode-diff-settings --fix        # overwrite all profiles with canonical
#   vscode-diff-settings --fix nix    # overwrite specific profile with canonical

user_dir="${XDG_CONFIG_HOME:-$HOME/.config}/VSCodium/User"
fix=0

# Parse --fix flag
args=()
for arg in "$@"; do
  if [[ "$arg" == "--fix" ]]; then
    fix=1
  else
    args+=("$arg")
  fi
done

fix_profile() {
  local profile="$1"
  local settings_dir

  if [[ "$profile" == "default" ]]; then
    settings_dir="$user_dir"
  else
    settings_dir="$user_dir/profiles/$profile"
  fi

  local canonical="$settings_dir/settings.canonical.json"
  local target="$settings_dir/settings.json"

  if [[ ! -f "$canonical" ]]; then
    echo "[$profile] no canonical settings found at $canonical" >&2
    return 1
  fi

  cp "$canonical" "$target" && chmod 644 "$target"
  echo "[$profile] reset settings.json to canonical"
}

check_profile() {
  local profile="$1"
  local settings_dir

  if [[ "$profile" == "default" ]]; then
    settings_dir="$user_dir"
  else
    settings_dir="$user_dir/profiles/$profile"
  fi

  local canonical="$settings_dir/settings.canonical.json"
  local target="$settings_dir/settings.json"

  if [[ ! -f "$canonical" ]]; then
    echo "[$profile] no canonical settings found at $canonical" >&2
    return 1
  fi

  if [[ ! -f "$target" ]]; then
    echo "[$profile] no settings.json found at $target" >&2
    return 1
  fi

  local diff
  diff=$(rg -xvFf "$canonical" "$target")

  if [[ -z "$diff" ]]; then
    echo "[$profile] clean — no manually-added settings"
  else
    echo "[$profile] manually-added settings (not in canonical):"
    echo "$diff" | sed 's/^/  /'
  fi
}

run_profile() {
  if [[ "$fix" -eq 1 ]]; then
    fix_profile "$1"
  else
    check_profile "$1"
  fi
}

if [[ ${#args[@]} -gt 0 ]]; then
  for profile in "${args[@]}"; do
    run_profile "$profile"
  done
else
  run_profile "default"
  if [[ -d "$user_dir/profiles" ]]; then
    for dir in "$user_dir/profiles"/*/; do
      run_profile "$(basename "$dir")"
    done
  fi
fi
