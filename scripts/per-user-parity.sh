#!/usr/bin/env bash
# Compare every file in the live home-manager generation against the
# perUser activation script's link targets. Directory targets match by
# longest prefix. MATCH = migrated & byte-equal, DIFF = content differs,
# TODO = still HM-owned. Accepted diffs documented in MIGRATION.md.
#
# Usage: scripts/per-user-parity.sh [host] [user-key]
set -u
host="${1:-blackflame}"
userkey="${2:-craig@personal}"
user="${userkey%@*}"
repo="$(cd "$(dirname "$0")/.." && pwd)"

hmgen=$(dirname "$(readlink "$HOME/.bashrc")")   # live home-manager-files generation
nix eval --raw ".#nixosConfigurations.$host.config.systemd.user.services.\"hdwlinux-${userkey//@/-}\".script" \
  > /tmp/per-user-activation.txt 2>/dev/null || { echo "eval failed" >&2; exit 1; }

# target<TAB>source map from the activation link script
awk '
  /^target=/{t=substr($0,8); gsub(/^'\''|'\''$/,"",t); next}
  /ln -sfn/{s=$3; gsub(/^'\''|'\''$/,"",s); if (t!="") {print t "\t" s; t=""}}
' /tmp/per-user-activation.txt > /tmp/per-user-targets.tsv

match=0; diffn=0; todo=0; dirn=0
while IFS= read -r rel; do
  [ "$rel" = "$hmgen" ] && continue
  [ -d "$hmgen/$rel" ] && { dirn=$((dirn+1)); continue; }
  p=$(awk -v want="$HOME/$rel" -F'\t' '$1==want{print $2}' /tmp/per-user-targets.tsv | head -1)
  prefix=""
  if [ -z "$p" ]; then
    # longest directory-target prefix
    best=0
    while IFS=$'\t' read -r t s; do
      case "$rel" in
        "${t#"$HOME/"}/"*) [ "${#t}" -gt "$best" ] && { best=${#t}; prefix="$t"; p="$s"; } ;;
      esac
    done < /tmp/per-user-targets.tsv
  fi
  if [ -n "$prefix" ]; then
    rest="${rel#"${prefix#"$HOME/"}"/}"
    f="$p/$rest"
  else
    f="$p"
  fi
  if [ -z "$p" ]; then printf 'TODO %s\n' "$rel"; todo=$((todo+1));
  elif [ ! -e "$f" ] && [[ "$f" == *-source/* ]]; then
    # repo-file source whose flake copy was GC'd; compare against the checkout
    src="${f#*-source/}"
    if diff -q "$repo/$src" "$hmgen/$rel" >/dev/null 2>&1; then
      match=$((match+1))
    else
      printf 'DIFF %s (repo:%s)\n' "$rel" "$src"; diffn=$((diffn+1))
    fi
  elif diff -q "$f" "$hmgen/$rel" >/dev/null 2>&1; then match=$((match+1));
  else printf 'DIFF %s\n' "$rel"; diffn=$((diffn+1)); fi
done < <(cd "$hmgen" && find . -type f -o -type l | sed 's|^\./||')
echo "-- MATCH=$match DIFF=$diffn DIR=$dirn TODO=$todo"
