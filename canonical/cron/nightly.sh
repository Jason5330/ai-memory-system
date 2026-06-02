#!/usr/bin/env bash
# nightly.sh — OS-level nightly consolidation (Mac/Linux), hardened.
#   --dry-run : report what WOULD happen, write nothing.
# Hardening: single memory.lock (prevents concurrent dreams; stale >6h auto-clears), a run-id, and a
# per-phase JSON audit at ~/.ai-memory/cron/audit.jsonl. Per-file atomicity is the operations' job,
# not this wrapper's. Never auto-approves doctrines or auto-builds skills.
set -u
DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1
personal="$HOME/.ai-memory"; cron="$personal/cron"; mkdir -p "$cron"
lock="$cron/memory.lock"; audit="$cron/audit.jsonl"; log="$personal/nightly-last-run.md"
run_id="$(date +%Y%m%d-%H%M)-$(printf '%04x' $((RANDOM)))"

au(){ # event scope status detail
  printf '{"run_id":"%s","ts":"%s","event":"%s","scope":"%s","status":"%s","detail":"%s","dry_run":%s}\n' \
    "$run_id" "$(date -u +%FT%TZ)" "$1" "$2" "$3" "$(printf '%s' "$4" | tr -d '"')" "$([ $DRY = 1 ] && echo true || echo false)" >> "$audit"; }

# single-instance lock (stale >6h auto-clears via find -mmin +360)
if [ -f "$lock" ]; then
  if [ -z "$(find "$lock" -mmin +360 2>/dev/null)" ]; then
    au skipped - locked "another run holds the lock"; echo "# Nightly $run_id — SKIPPED (locked)" > "$log"; exit 0
  else au lock - stale-cleared ">6h old"; rm -f "$lock"; fi
fi
echo "$run_id pid=$$ $(date -u +%FT%TZ)" > "$lock"; au lock - acquired ""

cleanup(){ rm -f "$lock"; au unlock - released ""; }
trap cleanup EXIT

echo "# Nightly $run_id $(date '+%Y-%m-%d %H:%M')$([ $DRY = 1 ] && echo ' (DRY RUN)')" > "$log"

cli=""
if command -v claude >/dev/null 2>&1; then cli="claude"
elif command -v codex >/dev/null 2>&1; then cli="codex"; fi
if [ -z "$cli" ]; then au abort - no-cli "no claude/codex on PATH"; echo "No claude/codex CLI — skipped." >> "$log"; exit 0; fi
au start - ok "cli=$cli"

dry_note=""; [ $DRY = 1 ] && dry_note=" THIS IS A DRY RUN: do NOT write or modify ANY file; report what you WOULD consolidate/harvest and stop."
prompt="First run /ingest-sessions to sediment any signals missed from recent Claude/Codex sessions (watermarked, idempotent). Then run a full /dream memory consolidation now, non-interactively (entity sweep, link repair, dedup, reflection, skill-failure writeback, index sync, lint). Distill doctrine CANDIDATES only — do NOT approve any doctrine and do NOT build any skill. Then run /harvest in SCAN-ONLY mode: produce the candidate list with evidence/confidence but STOP before building. Summarize what you wrote.${dry_note}"

run(){ # workdir scope
  au consolidate "$2" begin "$1"
  ( cd "$1" 2>/dev/null || exit 1
    if [ "$cli" = "claude" ]; then printf '%s' "$prompt" | claude -p 2>&1; else codex exec "$prompt" 2>&1; fi
  ) >> "$log" 2>&1 && au consolidate "$2" ok "" || au consolidate "$2" error "run failed"
}

echo "## personal" >> "$log"; run "$HOME" personal
projfile="$personal/nightly-projects.txt"
if [ -f "$projfile" ]; then
  while IFS= read -r p; do
    case "$p" in ''|\#*) continue;; esac
    [ -d "$p/.claude/memory" ] && { echo "## project:$p" >> "$log"; run "$p" "project:$p"; }
  done < "$projfile"
fi
au done - ok ""
echo "" >> "$log"; echo "Done $run_id. Review next session: /review-doctrine and /harvest." >> "$log"
