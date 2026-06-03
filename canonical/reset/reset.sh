#!/usr/bin/env bash
# reset.sh — deterministic memory reset (Mac/Linux). The /reset operation gathers the user's choices,
# then calls THIS script so the destructive part is a real, auditable tool.
#
# Usage:
#   reset.sh --layer personal|project|both --categories conversations,reflection,knowledge,doctrine,preferences[,blocked-actions]
#            [--project-path <dir>] [--dry-run] [--yes "yes reset"]
#
# Safety: backup FIRST, VERIFY (count match), only then clear; ROLLBACK from backup if a clear fails.
# Refuses without --yes "yes reset". Exit: 0 ok/dry-run · 2 refused · 3 verify-failed · 4 rolled-back.
set -u
LAYER=personal; CATS="conversations,reflection"; PROJ="$(pwd)"; DRY=0; YES=""
while [ "$#" -gt 0 ]; do case "$1" in
  --layer) LAYER="$2"; shift 2;;
  --categories) CATS="$2"; shift 2;;
  --project-path) PROJ="$2"; shift 2;;
  --dry-run) DRY=1; shift;;
  --yes) YES="$2"; shift 2;;
  *) echo "unknown arg: $1"; exit 2;;
esac; done
run_id="$(date +%Y%m%d-%H%M%S)"
IFS=',' read -ra CATARR <<< "$CATS"

reseed(){ case "$1" in
  reflection.md) printf '# Reflection Log (personal, append-only)\n\n_(empty until first /dream)_\n';;
  doctrine.md) printf '# Doctrine — Approved Behavior Rules\n\n_(none yet)_\n';;
  doctrine_candidates.md) printf '# Doctrine Candidates — Pending Review\n\n_(none yet)_\n';;
  feedback_user_style.md) printf '# User Style & Preferences\n\n_(none yet)_\n';;
  persona.md) printf '# Agent Persona\n\n_(none yet)_\n';;
  blocked-actions.json) printf '{\n  "blocked_tools": []\n}\n';;
  *) printf '';; esac; }

# layers
roots=(); names=(); pers=()
case "$LAYER" in personal|both) roots+=("$HOME/.ai-memory"); names+=("personal"); pers+=(1);; esac
case "$LAYER" in project|both) roots+=("$PROJ/.claude/memory"); names+=("project:$PROJ"); pers+=(0);; esac

# build plan: arrays of root|type|src
PLAN_ROOT=(); PLAN_TYPE=(); PLAN_SRC=(); PLAN_BAK=()
for i in "${!roots[@]}"; do
  root="${roots[$i]}"; isp="${pers[$i]}"
  [ -d "$root" ] || { echo "skip (no memory): ${names[$i]}"; continue; }
  bak="$root/archive/reset-$run_id"
  for c in "${CATARR[@]}"; do c="$(echo "$c" | tr -d ' ' | tr 'A-Z' 'a-z')"
    dirs=(); files=()
    case "$c" in
      conversations) dirs=("$root/conversations");;
      knowledge) dirs=("$root/knowledge");;
      reflection) [ "$isp" = 1 ] && files=("$root/reflection.md");;
      doctrine) [ "$isp" = 1 ] && files=("$root/doctrine.md" "$root/doctrine_candidates.md");;
      preferences) [ "$isp" = 1 ] && files=("$root/feedback_user_style.md" "$root/persona.md");;
      blocked-actions) [ "$isp" = 1 ] && files=("$root/blocked-actions.json");;
    esac
    for d in "${dirs[@]:-}"; do [ -d "$d" ] || continue; for f in "$d"/*.md; do [ -e "$f" ] && { PLAN_ROOT+=("$root"); PLAN_TYPE+=(dir); PLAN_SRC+=("$f"); PLAN_BAK+=("$bak"); }; done; done
    for f in "${files[@]:-}"; do [ -n "$f" ] && [ -f "$f" ] && { PLAN_ROOT+=("$root"); PLAN_TYPE+=(file); PLAN_SRC+=("$f"); PLAN_BAK+=("$bak"); }; done
  done
done

echo "reset $run_id — layer=$LAYER categories=$CATS"
echo "Would affect ${#PLAN_SRC[@]} file(s):"; for s in "${PLAN_SRC[@]:-}"; do echo "  - $s"; done

[ "$DRY" = 1 ] && { echo; echo "DRY RUN — nothing written."; exit 0; }
[ "$YES" = "yes reset" ] || { echo; echo "REFUSED: pass  --yes \"yes reset\"  to actually clear (nothing changed)."; exit 2; }
[ "${#PLAN_SRC[@]}" -eq 0 ] && { echo "Nothing to clear."; exit 0; }

# backup
for i in "${!PLAN_SRC[@]}"; do
  src="${PLAN_SRC[$i]}"; root="${PLAN_ROOT[$i]}"; bak="${PLAN_BAK[$i]}"
  rel="${src#$root/}"; dst="$bak/$rel"; mkdir -p "$(dirname "$dst")"; cp "$src" "$dst"
done
# verify
ubaks=$(printf '%s\n' "${PLAN_BAK[@]}" | sort -u); cnt=0
while IFS= read -r b; do cnt=$((cnt + $(find "$b" -type f 2>/dev/null | wc -l))); done <<< "$ubaks"
if [ "$cnt" -ne "${#PLAN_SRC[@]}" ]; then echo "BACKUP VERIFY FAILED ($cnt/${#PLAN_SRC[@]}) — aborting, nothing cleared."; exit 3; fi
echo "backup verified: $cnt file(s)"

# clear with rollback
DONE_SRC=(); DONE_BAK=(); DONE_ROOT=()
rollback(){ echo "ERROR during clear — ROLLING BACK..."; for j in "${!DONE_SRC[@]}"; do rel="${DONE_SRC[$j]#${DONE_ROOT[$j]}/}"; cp "${DONE_BAK[$j]}/$rel" "${DONE_SRC[$j]}" 2>/dev/null; done; echo "Rolled back ${#DONE_SRC[@]} file(s)."; exit 4; }
trap rollback ERR
for i in "${!PLAN_SRC[@]}"; do
  src="${PLAN_SRC[$i]}"
  if [ "${PLAN_TYPE[$i]}" = dir ]; then rm -f "$src"; else reseed "$(basename "$src")" > "$src"; fi
  DONE_SRC+=("$src"); DONE_BAK+=("${PLAN_BAK[$i]}"); DONE_ROOT+=("${PLAN_ROOT[$i]}")
done
trap - ERR

# prune each affected layer's MEMORY.md: drop lines whose linked .md no longer exists (the cleared
# logs/knowledge), keep headers and links to surviving files — so the visible index reflects the reset.
prune_index(){ local root="$1"; local mem="$root/MEMORY.md"; [ -f "$mem" ] || return
  local tmp="$mem.tmp"; : > "$tmp"
  while IFS= read -r ln || [ -n "$ln" ]; do
    local tgt; tgt="$(printf '%s' "$ln" | grep -oE '\]\([^)#:]+\.md\)' | head -1 | sed -E 's/^\]\(//; s/\)$//')"
    if [ -n "$tgt" ] && [ ! -f "$root/$tgt" ]; then continue; fi   # dead link → drop
    printf '%s\n' "$ln" >> "$tmp"
  done < "$mem"
  mv -f "$tmp" "$mem"
}
while IFS= read -r r; do [ -n "$r" ] && prune_index "$r"; done <<< "$(printf '%s\n' "${PLAN_ROOT[@]}" | sort -u)"

echo; echo "✅ reset complete — cleared ${#PLAN_SRC[@]} file(s) + pruned MEMORY.md index. Backup: $(printf '%s\n' "${PLAN_BAK[@]}" | sort -u | tr '\n' ' ')"
echo "Restore = copy files back from the backup. Run /dream to fully rebuild the index if needed."
exit 0
