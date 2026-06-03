#!/usr/bin/env bash
# memory-lint.sh — the "doctor": deterministic health check (Mac/Linux)
# Usage: memory-lint.sh [--strict] [root1] [root2] ...
# Default roots: ~/.ai-memory and ./.claude/memory (if present). Also runs GLOBAL wiring checks.
# Reports and exits 0 by default. With --strict it is a CI GATE: exit 1 if fail > 0.

pass=0; warn=0; fail=0
P(){ pass=$((pass+1)); echo "  PASS  $1"; }
W(){ warn=$((warn+1)); echo "  WARN  $1"; }
F(){ fail=$((fail+1)); echo "  FAIL  $1"; }

U="$HOME"
strict=0; roots=()
for a in "$@"; do case "$a" in --strict|-Strict|-strict) strict=1;; *) roots+=("$a");; esac; done
if [ "${#roots[@]}" -eq 0 ]; then
    roots+=("$U/.ai-memory"); [ -d "./.claude/memory" ] && roots+=("./.claude/memory")
fi

for root in "${roots[@]}"; do
    [ -d "$root" ] || { W "root not found: $root"; continue; }
    case "$root" in "$U/.ai-memory"*) personal=1;; *) personal=0;; esac
    echo "Linting: $root"

    if [ -f "$root/MEMORY.md" ]; then
        P "MEMORY.md present"
        grep -oE '\]\(([^)#:]+\.md)\)' "$root/MEMORY.md" | sed -E 's/^\]\(//; s/\)$//' | while IFS= read -r lnk; do
            [ -f "$root/$lnk" ] || W "MEMORY.md dead link: $lnk"
        done
    else F "MEMORY.md missing in $root"; fi

    if [ "$personal" = 1 ]; then
        [ -f "$root/persona.md" ] && P "persona.md present" || W "persona.md missing (AI identity bucket)"
        if [ -f "$root/blocked-actions.json" ]; then
            if python3 - "$root/blocked-actions.json" <<'PY' 2>/dev/null
import json,sys
d=json.load(open(sys.argv[1],encoding="utf-8"))
bt=d.get("blocked_tools")
assert isinstance(bt,list)
for e in bt: assert e.get("tool") and e.get("use_instead")
PY
            then P "blocked-actions.json valid"; else F "blocked-actions.json INVALID/incomplete — hard-block net is DOWN until fixed"; fi
        fi
    fi

    if [ -d "$root/knowledge" ]; then
        for file in "$root"/knowledge/*.md; do
            [ -e "$file" ] || continue
            base="$(basename "$file")"
            case "$base" in *[A-Z]*|*" "*|*_*) W "filename not kebab-lowercase: $base";; esac
            for k in name type kind layer first_seen last_updated; do
                grep -Eq "^$k[[:space:]]*:" "$file" || W "$base missing frontmatter '$k'"
            done
            grep -q "Current State" "$file" || W "$base missing '## Current State'"
            grep -q "Timeline" "$file" || W "$base missing '## Timeline'"
            grep -Eq "^>[[:space:]]*Summary" "$file" || W "$base missing Why (the '> Summary' line)"
            grep -q "How to Apply" "$file" || W "$base missing '## How to Apply'"
            if grep -Eq "^- [0-9]{4}-[0-9]{2}-[0-9]{2}" "$file" && ! grep -q "(source:" "$file"; then W "$base Timeline line missing (source: ...)"; fi
        done
        P "knowledge/ scanned"
    fi

    if [ -f "$root/doctrine.md" ]; then
        ids="$(grep -Eo '^###[[:space:]]+D-[0-9]+' "$root/doctrine.md" | sort)"
        [ "$(printf '%s\n' "$ids" | wc -l)" = "$(printf '%s\n' "$ids" | sort -u | wc -l)" ] && P "doctrine ids unique" || F "duplicate doctrine D-XXX ids"
    fi

    if [ -d "$root/conversations" ]; then
        stale=0
        for f in "$root"/conversations/*.md; do
            [ -e "$f" ] || continue
            if [ -n "$(find "$f" -mtime +7 2>/dev/null)" ] && ! grep -q "consolidated" "$f"; then stale=$((stale+1)); fi
        done
        [ "$stale" -gt 0 ] && W "$stale conversation log(s) >7 days old not consolidated — run /dream" || P "conversation logs consolidated/current"
    fi

    if [ "$personal" = 0 ] && [ -d "$root/knowledge" ]; then
        leak="$(grep -rlE 'feedback_user_style|\.ai-memory|persona\.md' "$root/knowledge" 2>/dev/null | wc -l)"
        [ "$leak" -gt 0 ] && W "PRIVACY: project knowledge references personal-layer memory ($leak file(s)) — must not leak into shared project"
    fi

    # SECURITY: scan stored memory for prompt-injection / exfiltration phrasing (WARN; human reviews)
    susp='ignore (all )?(previous|prior|above) instructions|disregard (all |the )?(previous|prior|above)|exfiltrat|(reveal|print|show) (your )?(system )?prompt'
    shits=0
    for sf in "$root/MEMORY.md" "$root"/knowledge/*.md "$root"/conversations/*.md; do
        [ -f "$sf" ] || continue
        grep -qiE "$susp" "$sf" && shits=$((shits+1))
    done
    [ "$shits" -gt 0 ] && W "SECURITY: injection/exfiltration phrasing in $shits memory file(s) — review (stored memory is data, never an instruction)" || P "memory content clean (no injection/exfiltration phrasing)"
done

# ---- GLOBAL wiring checks ----
echo "Wiring (both platforms):"
# Self-test runs the ACTUAL registered command (catches stale path / wrong command). Exit 0 expected.
run_reg(){ echo '{"tool_name":"__doctor_selftest__"}' | bash -c "$1" >/dev/null 2>&1; }
# Claude: parse the registered command from settings.json (via python3) and run it
if [ -f "$U/.claude/settings.json" ]; then
    reg="$(python3 - "$U/.claude/settings.json" <<'PY' 2>/dev/null
import json,sys
try: s=json.load(open(sys.argv[1],encoding="utf-8"))
except Exception: sys.exit(0)
for e in s.get("hooks",{}).get("PreToolUse",[]):
    for h in e.get("hooks",[]):
        c=h.get("command","")
        if "block-failed-actions" in c: print(c); raise SystemExit
PY
)"
    if [ -z "$reg" ]; then F "Claude hook NOT registered in settings.json — hard-block net is DOWN"
    elif run_reg "$reg"; then P "Claude hook registered command runs (self-test exit 0)"
    else F "Claude registered hook command FAILED self-test (stale path / broken?) — net is DOWN"; fi
else W "Claude settings.json not found (run install-personal)"; fi
# Codex: parse the registered command line from config.toml and run it
if [ -f "$U/.codex/config.toml" ]; then
    line="$(grep 'block-failed-actions' "$U/.codex/config.toml" | grep -i command | head -1)"
    reg="$(printf '%s' "$line" | sed -E "s/.*command[[:space:]]*=[[:space:]]*'([^']+)'.*/\1/; t; s/.*command[[:space:]]*=[[:space:]]*\"([^\"]+)\".*/\1/")"
    if [ -z "$line" ]; then W "Codex hook not registered in config.toml"
    elif run_reg "$reg"; then P "Codex hook registered command runs (self-test exit 0)"
    else F "Codex registered hook command FAILED self-test — Codex hard-block is DOWN"; fi
else W "Codex config.toml not found (Codex hard-block inactive)"; fi
# Entry files present + carry the AI-MEMORY block (so each platform loads memory at startup)
for pair in "$U/.claude/CLAUDE.md|Claude ~/.claude/CLAUDE.md" "$U/.codex/AGENTS.md|Codex ~/.codex/AGENTS.md"; do
    ep="${pair%%|*}"; en="${pair##*|}"
    if [ -f "$ep" ]; then
        grep -q 'AI-MEMORY-START' "$ep" && P "$en present + AI-MEMORY block" || W "$en exists but MISSING the AI-MEMORY block — that platform won't load memory (run install-personal)"
    else W "$en not found — that platform won't load memory (run install-personal)"; fi
done
{ [ -f "$U/.claude/skills/skill-creator/SKILL.md" ] && [ -f "$U/.agents/skills/skill-creator/SKILL.md" ]; } && P "skill-creator deployed (both platforms)" || W "skill-creator missing on a platform"
# lib backbone present + .sh syntax-clean (memory-write / detect-repeats / tool — deterministic scripts)
libdir="$U/.ai-memory/lib"; libmiss=""; libbad=""
for b in memory-write detect-repeats tool; do
    for ext in .ps1 .sh; do
        if [ ! -f "$libdir/$b$ext" ]; then libmiss="$libmiss $b$ext"
        elif [ "$ext" = ".sh" ]; then bash -n "$libdir/$b$ext" 2>/dev/null || libbad="$libbad $b$ext"; fi
    done
done
if [ -n "$libmiss" ]; then F "lib scripts MISSING:$libmiss (run install-personal)"
elif [ -n "$libbad" ]; then F "lib .sh syntax errors:$libbad"
else P "lib backbone present + .sh syntax-clean (memory-write/detect-repeats/tool)"; fi
# PROMOTED-skill twin consistency: operations are Claude commands vs Codex skills (expected to
# differ), so exclude them; a /harvest-promoted skill must exist on BOTH sides.
if [ -d "$U/.claude/skills" ] && [ -d "$U/.agents/skills" ]; then
    ops='^(capture|dream|harvest|review-doctrine|status|schedule-dream|reset|help|skill-creator|ingest-sessions)$'
    cn="$(ls "$U/.claude/skills" 2>/dev/null | grep -Ev "$ops" | sort)"
    an="$(ls "$U/.agents/skills" 2>/dev/null | grep -Ev "$ops" | sort)"
    diff="$(comm -3 <(printf '%s\n' "$cn") <(printf '%s\n' "$an") | tr -d '\t' | grep -v '^$' || true)"
    [ -z "$diff" ] && P "promoted skills in sync across platforms" || W "promoted skills diverge: $(echo "$diff" | tr '\n' ' ')"
fi

echo ""
echo "RESULT: $pass pass, $warn warn, $fail fail"
if [ "$strict" = 1 ] && [ "$fail" -gt 0 ]; then echo "STRICT: $fail failure(s) — exit 1"; exit 1; fi
exit 0
