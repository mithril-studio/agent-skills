#!/usr/bin/env bash
# Install skills into an agent's skills directory.
#
#   ./install.sh                    every skill -> ~/.claude/skills
#   ./install.sh memory             just one
#   ./install.sh --dest /path       somewhere else
#
# Idempotent: re-running overwrites, so it doubles as an update.

set -euo pipefail

SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
WANTED=()

while [ $# -gt 0 ]; do
  case "$1" in
    --dest)
      [ $# -ge 2 ] || { echo "--dest needs a path" >&2; exit 2; }
      DEST="$2"; shift 2 ;;
    --dest=*) DEST="${1#*=}"; shift ;;
    -h|--help) sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "unknown option: $1" >&2; exit 2 ;;
    *) WANTED+=("$1"); shift ;;
  esac
done

# Every directory holding a SKILL.md is a skill.
available=()
for dir in "$SOURCE"/*/; do
  [ -f "$dir/SKILL.md" ] && available+=("$(basename "$dir")")
done

if [ ${#available[@]} -eq 0 ]; then
  echo "no skills found in $SOURCE" >&2
  exit 1
fi

if [ ${#WANTED[@]} -eq 0 ]; then
  WANTED=("${available[@]}")
else
  for name in "${WANTED[@]}"; do
    found=0
    for have in "${available[@]}"; do [ "$name" = "$have" ] && found=1; done
    if [ $found -eq 0 ]; then
      echo "no such skill: $name" >&2
      echo "available: ${available[*]}" >&2
      exit 1
    fi
  done
fi

mkdir -p "$DEST"
for name in "${WANTED[@]}"; do
  rm -rf "${DEST:?}/$name"
  cp -R "$SOURCE/$name" "$DEST/$name"
  echo "installed $name -> $DEST/$name"
done

echo "done: ${#WANTED[@]} skill(s) in $DEST"
