#!/usr/bin/env bash
# nightly.sh — OS-level nightly consolidation (Mac/Linux), hardened.
#   --dry-run : PLAN ONLY — print what it WOULD do and exit. Launches NO agent, takes NO lock,
#               writes NO audit/memory. (Honest dry-run: never starts a memory-modifying agent.)
# Hardening (real runs): single memory.lock (stale >6h auto-clears), run-id, per-phase JSON audit at
# ~/.ai-memory/cron/audit.jsonl. Per-file atomicity is the operations' job, not this wrapper's.
# Never auto-approves doctrines or auto-builds skills.
set -u
DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1
personal="$HOME/.ai-memory"; cron="$personal/cron"; mkdir -p "$cron"
lock="$cron/memory.lock"; audit="$cron/audit.jsonl"; log="$personal/nightly-last-run.md"
run_id="$(date +%Y%m%d-%H%M)-$(printf '%04x' $((RANDOM)))"

detect_cli(){ if command -v claude >/dev/null 2>&1; then echo claude; elif command -v codex >/dev/null 2>&1; then echo codex; fi; }
scopes(){ echo "$HOME"; local pf="$personal/nightly-projects.txt"; [ -f "$pf" ] && while IFS= read -r p; do case "$p" in ''|\#*) continue;; esac; [ -d "$p/.claude/memory" ] && echo "$p"; done < "$pf"; }

# --- DRY RUN: plan only, no agent, no lock, no audit ---
if [ "$DRY" = 1 ]; then
  cli="$(detect_cli)"; [ -z "$cli" ] && cli="NONE (a real run would skip)"
  if [ -f "$lock" ]; then lst="HELD (real run in progress or stale)"; else lst="free"; fi
  { echo "# Nightly PLAN (dry-run) $run_id $(date '+%Y-%m-%d %H:%M')"
    echo "This is a plan only. No agent is launched; nothing is written to memory, audit, or the lock."
    echo ""
    echo "CLI detected:      $cli"
    echo "Lock state:        $lst"
    echo "Would consolidate:"; scopes | sed 's/^/  - /'
    echo "Per scope it WOULD run: /ingest-sessions -> /dream (candidates only) -> /harvest scan (no build)."
    echo "Run without --dry-run to execute."; } | tee "$log"
  exit 0
fi

au(){ printf '{"run_id":"%s","ts":"%s","event":"%s","scope":"%s","status":"%s","detail":"%s"}\n' \
  "$run_id" "$(date -u +%FT%TZ)" "$1" "$2" "$3" "$(printf '%s' "$4" | tr -d '"')" >> "$audit"; }

# single-instance lock (stale >6h auto-clears)
if [ -f "$lock" ]; then
  if [ -z "$(find "$lock" -mmin +360 2>/dev/null)" ]; then
    au skipped - locked "another run holds the lock"; echo "# Nightly $run_id — SKIPPED (locked)" > "$log"; exit 0
  else au lock - stale-cleared ">6h old"; rm -f "$lock"; fi
fi
echo "$run_id pid=$$ $(date -u +%FT%TZ)" > "$lock"; au lock - acquired ""
cleanup(){ rm -f "$lock"; au unlock - released ""; }
trap cleanup EXIT

echo "# Nightly $run_id $(date '+%Y-%m-%d %H:%M')" > "$log"
cli="$(detect_cli)"
if [ -z "$cli" ]; then au abort - no-cli "no claude/codex on PATH"; echo "No claude/codex CLI — skipped." >> "$log"; exit 0; fi
au start - ok "cli=$cli"

prompt="First run /ingest-sessions to sediment any signals missed from recent Claude/Codex sessions (per-source checkpoint, idempotent). Then run a full /dream memory consolidation now, non-interactively (entity sweep, link repair, dedup, reflection, skill-failure writeback, index sync, doctor). Distill doctrine CANDIDATES only — do NOT approve any doctrine and do NOT build any skill. Then run /harvest in SCAN-ONLY mode: produce the candidate list with evidence/confidence but STOP before building. Summarize what you wrote."

run(){ au consolidate "$2" begin "$1"
  ( cd "$1" 2>/dev/null || exit 1
    if [ "$cli" = "claude" ]; then printf '%s' "$prompt" | claude -p 2>&1; else codex exec "$prompt" 2>&1; fi
  ) >> "$log" 2>&1 && au consolidate "$2" ok "" || au consolidate "$2" error "run failed"; }

while IFS= read -r s; do
  [ "$s" = "$HOME" ] && { echo "## personal" >> "$log"; run "$s" personal; } || { echo "## project:$s" >> "$log"; run "$s" "project:$s"; }
done < <(scopes)
au done - ok ""
echo "" >> "$log"; echo "Done $run_id. Review next session: /review-doctrine and /harvest." >> "$log"
