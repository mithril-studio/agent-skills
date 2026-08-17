#!/usr/bin/env bash
# Show how the vendored skills have drifted from their upstreams.
#
#   ./upstream-diff.sh                  summary for everything in upstream.tsv
#   ./upstream-diff.sh code-simplification    just entries matching a name
#   ./upstream-diff.sh --diff           print the full diffs, not just the summary
#   ./upstream-diff.sh --check          exit 1 if anything drifted (for CI)
#   ./upstream-diff.sh --refresh        re-fetch the upstreams before comparing
#
# Drift is not a failure — a vendored copy we edited on purpose should differ.
# The point is that the difference is visible and deliberate rather than a
# surprise six months from now.

set -euo pipefail

SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="$SOURCE/upstream.tsv"
CACHE="${UPSTREAM_CACHE:-$SOURCE/.upstream-cache}"
SHOW_DIFF=0
CHECK=0
REFRESH=0
FILTER=""

while [ $# -gt 0 ]; do
  case "$1" in
    --diff) SHOW_DIFF=1; shift ;;
    --check) CHECK=1; shift ;;
    --refresh) REFRESH=1; shift ;;
    -h|--help) sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "unknown option: $1" >&2; exit 2 ;;
    *) FILTER="$1"; shift ;;
  esac
done

[ -f "$MANIFEST" ] || { echo "no manifest at $MANIFEST" >&2; exit 1; }

# A repo URL has to become a directory name. Keep it readable rather than hashed,
# so a stale cache is obvious to anyone who looks in .upstream-cache.
slug() { echo "$1" | sed 's|^https\{0,1\}://||; s|[^A-Za-z0-9._-]|-|g'; }

# Fetch each distinct upstream once, at whatever its default branch currently is.
mkdir -p "$CACHE"
repos="$(awk -F'\t' '!/^#/ && NF>=3 {print $2}' "$MANIFEST" | sort -u)"
for repo in $repos; do
  dir="$CACHE/$(slug "$repo")"
  if [ ! -d "$dir/.git" ]; then
    echo "fetching $repo"
    git clone -q --depth 1 "$repo" "$dir"
  elif [ $REFRESH -eq 1 ]; then
    echo "refreshing $repo"
    git -C "$dir" fetch -q --depth 1 origin HEAD
    git -C "$dir" reset -q --hard FETCH_HEAD
  fi
  printf 'upstream %s @ %s\n' "$repo" "$(git -C "$dir" rev-parse --short HEAD)"
done
echo

same=0
drifted=0
gone=0

# Read the manifest on fd 3: the loop body runs git and diff, and those would
# otherwise eat the manifest off stdin.
while IFS=$'\t' read -r local repo path <&3 || [ -n "${local:-}" ]; do
  case "$local" in ''|'#'*) continue ;; esac
  [ -n "${path:-}" ] || continue
  if [ -n "$FILTER" ]; then
    case "$local" in *"$FILTER"*) ;; *) continue ;; esac
  fi

  ours="$SOURCE/$local"
  theirs="$CACHE/$(slug "$repo")/$path"

  if [ ! -e "$theirs" ]; then
    printf 'GONE     %-46s (upstream no longer has %s)\n' "$local" "$path"
    gone=$(( gone + 1 ))
    continue
  fi
  if [ ! -e "$ours" ]; then
    printf 'MISSING  %-46s (listed in the manifest but not in this repo)\n' "$local"
    gone=$(( gone + 1 ))
    continue
  fi

  # diff exits 1 when files differ, which set -e would treat as fatal.
  out="$(diff -ru "$ours" "$theirs" 2>/dev/null || true)"
  if [ -z "$out" ]; then
    printf 'same     %s\n' "$local"
    same=$(( same + 1 ))
  else
    added=$(printf '%s\n' "$out" | grep -c '^+[^+]' || true)
    removed=$(printf '%s\n' "$out" | grep -c '^-[^-]' || true)
    printf 'DRIFT    %-46s %s line(s) only upstream, %s only ours\n' "$local" "$added" "$removed"
    drifted=$(( drifted + 1 ))
    if [ $SHOW_DIFF -eq 1 ]; then
      printf '%s\n\n' "$out"
    fi
  fi
done 3< "$MANIFEST"

echo
echo "$same same, $drifted drifted, $gone gone"
if [ $SHOW_DIFF -eq 0 ] && [ $drifted -gt 0 ]; then
  echo "run with --diff to see what changed"
fi

if [ $CHECK -eq 1 ] && [ $(( drifted + gone )) -gt 0 ]; then
  exit 1
fi
exit 0
