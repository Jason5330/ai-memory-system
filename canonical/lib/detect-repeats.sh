#!/usr/bin/env bash
# detect-repeats.sh — deterministic repeat-workflow detector (Mac/Linux). Scans BOTH layers'
# conversation logs for tagged repeat markers ( "- 🔁 [<slug>] <desc>" lines that /capture, /dream and
# /ingest-sessions drop once per occurrence ), tallies recurrences, cross-checks existing skills on
# both platforms, and lists workflows seen >= threshold that have NO skill yet — the ones worth
# proactively offering to turn into a skill via /harvest.
#
# Usage:  detect-repeats.sh [--threshold 2] [--project-path <dir>] [--json]
# Exit: 0 always (read-only reporter).
set -euo pipefail
THRESHOLD=2; PROJECT_PATH="$(pwd)"; JSON=0
while [ $# -gt 0 ]; do
  case "$1" in
    --threshold) THRESHOLD="$2"; shift 2;;
    --project-path) PROJECT_PATH="$2"; shift 2;;
    --json) JSON=1; shift;;
    *) shift;;
  esac
done

ROOTS=()
[ -d "$HOME/.ai-memory" ] && ROOTS+=("$HOME/.ai-memory")
[ -d "$PROJECT_PATH/.claude/memory" ] && ROOTS+=("$PROJECT_PATH/.claude/memory")

# existing skill dir-names (lowercased) across both platforms + project
existing=" "
for sr in "$HOME/.claude/skills" "$HOME/.agents/skills" "$PROJECT_PATH/.claude/skills" "$PROJECT_PATH/.agents/skills"; do
  [ -d "$sr" ] || continue
  for d in "$sr"/*/; do [ -d "$d" ] && existing+="$(basename "$d" | tr '[:upper:]' '[:lower:]') "; done
done

# extract slugs from "🔁 [<slug>]" markers across all conversation logs, one count per occurrence
slugs="$(
  for r in "${ROOTS[@]:-}"; do
    [ -d "$r/conversations" ] || continue
    grep -rhoE 'repeat:[a-z0-9][a-z0-9-]*' "$r/conversations" 2>/dev/null \
      | sed -E 's/repeat://'
  done | sort | uniq -c | sort -rn
)"

candidates=""   # "slug count" lines, threshold met + no skill
while read -r count slug; do
  [ -n "${slug:-}" ] || continue
  [ "$count" -ge "$THRESHOLD" ] || continue
  case "$existing" in *" $slug "*) continue;; esac
  candidates+="$slug $count"$'\n'
done <<< "$slugs"

candidates="$(printf '%s' "$candidates" | sed '/^$/d')"

if [ "$JSON" = "1" ]; then
  printf '['
  first=1
  while read -r slug count; do
    [ -n "${slug:-}" ] || continue
    [ "$first" = "1" ] || printf ','
    printf '{"slug":"%s","count":%s}' "$slug" "$count"; first=0
  done <<< "$candidates"
  printf ']\n'; exit 0
fi

if [ -z "$candidates" ]; then
  echo "REPEATS: none (no workflow seen >= $THRESHOLD without a skill)"; exit 0
fi
n="$(printf '%s\n' "$candidates" | grep -c . || true)"
echo "REPEATS: $n workflow(s) seen >= $THRESHOLD with no skill yet —"
while read -r slug count; do
  [ -n "${slug:-}" ] && echo "  🔁 $slug — seen ${count}×"
done <<< "$candidates"
echo "→ 主動提醒：機械程式 → 存成 Saved Tool（lib/tool add）；判斷型工作流 → /harvest 生成 skill"
exit 0
