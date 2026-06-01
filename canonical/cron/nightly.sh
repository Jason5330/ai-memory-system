#!/usr/bin/env bash
# nightly.sh — OS-level nightly consolidation (Mac/Linux; platform-neutral)
#
# Replaces Claude's internal CronCreate. Register with cron (install-personal prints
# the crontab line). Runs headless:
#   1) /dream  — consolidate + reflect → doctrine CANDIDATES (human reviews later)
#   2) /harvest (scan only) — candidate list (does NOT build; human gates)
# Never auto-approves doctrines or auto-builds skills.
#
# CLI auto-detect: prefers `claude` (print mode), falls back to `codex exec`.
# Projects: one absolute path per line in ~/.ai-memory/nightly-projects.txt
# (personal layer is always consolidated).

personal="$HOME/.ai-memory"
log="$personal/nightly-last-run.md"
mkdir -p "$personal"
echo "# Nightly run $(date '+%Y-%m-%d %H:%M')" > "$log"

cli=""
if command -v claude >/dev/null 2>&1; then cli="claude"
elif command -v codex >/dev/null 2>&1; then cli="codex"; fi
if [ -z "$cli" ]; then echo "No claude/codex CLI on PATH — skipped." >> "$log"; exit 0; fi
echo "CLI: $cli" >> "$log"

prompt='Run a full /dream memory consolidation now, non-interactively. Follow the dream operation (entity sweep, link repair, dedup, reflection, skill-failure writeback, index sync, lint). Distill doctrine CANDIDATES only — do NOT approve any doctrine and do NOT build any skill (those need human review). Then run /harvest in SCAN-ONLY mode: produce the candidate list of repeatable workflows with evidence/confidence, but STOP before building anything. Summarize what you wrote.'

run_headless() { # $1 = workdir
    ( cd "$1" || return 1
      if [ "$cli" = "claude" ]; then printf '%s' "$prompt" | claude -p 2>&1
      else codex exec "$prompt" 2>&1; fi )
}

echo "## Personal layer" >> "$log"
run_headless "$HOME" >> "$log" 2>&1

projfile="$personal/nightly-projects.txt"
if [ -f "$projfile" ]; then
    while IFS= read -r p; do
        case "$p" in ''|\#*) continue ;; esac
        if [ -d "$p/.claude/memory" ]; then
            echo "## Project: $p" >> "$log"
            run_headless "$p" >> "$log" 2>&1
        fi
    done < "$projfile"
fi

echo "" >> "$log"
echo "Done $(date '+%Y-%m-%d %H:%M'). Review next session: /review-doctrine and /harvest." >> "$log"
