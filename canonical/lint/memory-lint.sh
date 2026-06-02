#!/usr/bin/env bash
# memory-lint.sh — the "doctor": deterministic health check (Mac/Linux)
# Usage: memory-lint.sh [root1] [root2] ...
# Default roots: ~/.ai-memory and ./.claude/memory (if present). Also runs GLOBAL wiring checks.
# Exit 0 always; prints "RESULT: X pass, Y warn, Z fail".

pass=0; warn=0; fail=0
P(){ pass=$((pass+1)); echo "  PASS  $1"; }
W(){ warn=$((warn+1)); echo "  WARN  $1"; }
F(){ fail=$((fail+1)); echo "  FAIL  $1"; }

U="$HOME"
roots=()
if [ "$#" -gt 0 ]; then roots=("$@")
else roots+=("$U/.ai-memory"); [ -d "./.claude/memory" ] && roots+=("./.claude/memory"); fi

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
done

# ---- GLOBAL wiring checks ----
echo "Wiring (both platforms):"
if [ -f "$U/.claude/settings.json" ]; then
    grep -q "block-failed-actions" "$U/.claude/settings.json" && P "Claude PreToolUse hook registered" || F "Claude hook NOT registered — hard-block net is DOWN"
else W "Claude settings.json not found (run install-personal)"; fi
if [ -f "$U/.codex/config.toml" ]; then
    grep -q "block-failed-actions" "$U/.codex/config.toml" && P "Codex PreToolUse hook registered" || W "Codex hook not registered in config.toml"
else W "Codex config.toml not found (Codex hard-block inactive)"; fi
hook="$U/.ai-memory/hooks/block-failed-actions.sh"
if [ -f "$hook" ]; then
    echo '{"tool_name":"__doctor_selftest__"}' | bash "$hook" claude >/dev/null 2>&1
    [ $? -eq 0 ] && P "hook script runs (self-test exit 0 on non-blocked tool)" || F "hook self-test failed — hook is broken"
else F "hook script missing: $hook"; fi
{ [ -f "$U/.claude/skills/skill-creator/SKILL.md" ] && [ -f "$U/.agents/skills/skill-creator/SKILL.md" ]; } && P "skill-creator deployed (both platforms)" || W "skill-creator missing on a platform"
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
