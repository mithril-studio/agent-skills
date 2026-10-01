#!/usr/bin/env bash
# Install skills into an agent's skills directory.
#
#   ./install.sh                       every skill -> ~/.claude/skills
#   ./install.sh code-review-and-quality  just one
#   ./install.sh engineering-skills    a whole category
#   ./install.sh --dest /path          somewhere else
#   ./install.sh --list                show what is available
#
# Skills live in category folders (engineering-skills/code-review-and-quality/SKILL.md) but
# install flat, because that is the layout agents read: ~/.claude/skills/code-review-and-quality.
#
# Idempotent: re-running overwrites, so it doubles as an update. A full install also
# removes skills this installer put there earlier that have since left the repo, so a
# deleted skill disappears from the agent too. Skills from other sources are untouched.

set -euo pipefail

SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
LIST_ONLY=0
WANTED=()

while [ $# -gt 0 ]; do
  case "$1" in
    --dest)
      [ $# -ge 2 ] || { echo "--dest needs a path" >&2; exit 2; }
      DEST="$2"; shift 2 ;;
    --dest=*) DEST="${1#*=}"; shift ;;
    --list) LIST_ONLY=1; shift ;;
    -h|--help) sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "unknown option: $1" >&2; exit 2 ;;
    *) WANTED+=("$1"); shift ;;
  esac
done

# Every directory holding a SKILL.md is a skill, whether it sits at the top level
# or inside a category folder. Names are parallel arrays: bash 3.2 has no maps.
names=()
paths=()
categories=()
for dir in "$SOURCE"/*/; do
  if [ -f "$dir/SKILL.md" ]; then
    names+=("$(basename "$dir")")
    paths+=("${dir%/}")
    continue
  fi
  found_in_category=0
  for sub in "$dir"*/; do
    [ -f "$sub/SKILL.md" ] || continue
    names+=("$(basename "$sub")")
    paths+=("${sub%/}")
    found_in_category=1
  done
  if [ $found_in_category -eq 1 ]; then categories+=("$(basename "$dir")"); fi
done

if [ ${#names[@]} -eq 0 ]; then
  echo "no skills found in $SOURCE" >&2
  exit 1
fi

if [ $LIST_ONLY -eq 1 ]; then
  for i in $(seq 0 $(( ${#names[@]} - 1 ))); do
    echo "${names[$i]}  (${paths[$i]#$SOURCE/})"
  done
  exit 0
fi

# Resolve each argument to one or more skill indices. An argument is either a
# skill name or a category name; a category expands to everything inside it.
selected=()
if [ ${#WANTED[@]} -eq 0 ]; then
  for i in $(seq 0 $(( ${#names[@]} - 1 ))); do selected+=("$i"); done
else
  for arg in "${WANTED[@]}"; do
    hits=0
    for i in $(seq 0 $(( ${#names[@]} - 1 ))); do
      rel="${paths[$i]#$SOURCE/}"
      category="${rel%/*}"
      [ "$category" = "$rel" ] && category=""
      if [ "$arg" = "${names[$i]}" ] || [ "$arg" = "$category" ]; then
        selected+=("$i"); hits=$(( hits + 1 ))
      fi
    done
    if [ $hits -eq 0 ]; then
      echo "no such skill or category: $arg" >&2
      echo "skills: ${names[*]}" >&2
      if [ ${#categories[@]} -gt 0 ]; then echo "categories: ${categories[*]}" >&2; fi
      exit 1
    fi
  done
fi

# The manifest records which skills this installer placed in $DEST, so a later run
# can tell "deleted from the repo" apart from "installed from somewhere else".
MANIFEST="$DEST/.agent-skills-manifest"
previous=()
if [ -f "$MANIFEST" ]; then
  while IFS= read -r line; do
    [ -n "$line" ] && previous+=("$line")
  done < "$MANIFEST"
fi

mkdir -p "$DEST"
installed=()
for i in "${selected[@]}"; do
  name="${names[$i]}"
  rm -rf "${DEST:?}/$name"
  cp -R "${paths[$i]}" "$DEST/$name"
  installed+=("$name")
  echo "installed $name -> $DEST/$name"
done

# A full install prunes: anything we installed before that no longer exists here.
removed=0
if [ ${#WANTED[@]} -eq 0 ]; then
  for old in ${previous[@]+"${previous[@]}"}; do
    still_here=0
    for name in "${names[@]}"; do
      [ "$old" = "$name" ] && { still_here=1; break; }
    done
    if [ $still_here -eq 0 ] && [ -e "$DEST/$old" ]; then
      rm -rf "${DEST:?}/$old"
      removed=$(( removed + 1 ))
      echo "removed $old (no longer in the repo)"
    fi
  done
  printf '%s\n' "${names[@]}" > "$MANIFEST"
else
  # Partial install: remember the union, prune nothing.
  printf '%s\n' ${previous[@]+"${previous[@]}"} "${installed[@]}" | sort -u > "$MANIFEST"
fi

# Some skills link to ../../references/*.md. From an installed skill at
# $DEST/<name>/ that resolves to $DEST/../references, so the shared folder has to
# land one level above the skills directory to keep those links working.
if [ -d "$SOURCE/references" ]; then
  REF_DEST="$(dirname "$DEST")/references"
  REF_MANIFEST="$REF_DEST/.agent-skills-manifest"
  mkdir -p "$REF_DEST"
  # Same pruning as above, for reference files that left the repo.
  if [ ${#WANTED[@]} -eq 0 ] && [ -f "$REF_MANIFEST" ]; then
    while IFS= read -r old; do
      [ -n "$old" ] || continue
      if [ ! -e "$SOURCE/references/$old" ] && [ -e "$REF_DEST/$old" ]; then
        rm -f "$REF_DEST/$old"
        removed=$(( removed + 1 ))
        echo "removed references/$old (no longer in the repo)"
      fi
    done < "$REF_MANIFEST"
  fi
  cp -R "$SOURCE/references/." "$REF_DEST/"
  (cd "$SOURCE/references" && find . -type f | sed 's|^\./||' | sort) > "$REF_MANIFEST"
  echo "installed references -> $REF_DEST"
fi

echo "done: ${#selected[@]} skill(s) in $DEST, $removed removed"
