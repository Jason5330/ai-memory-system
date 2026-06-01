#!/usr/bin/env bash
# memory-lint.sh — deterministic health check for memory layers (Mac/Linux)
# Usage: memory-lint.sh [root1] [root2] ...
# Default roots: ~/.ai-memory and ./.claude/memory (if present).
# Exit 0 always; prints "RESULT: X pass, Y warn, Z fail".

pass=0; warn=0; fail=0
p(){ pass=$((pass+1)); echo "  PASS  $1"; }
w(){ warn=$((warn+1)); echo "  WARN  $1"; }
f(){ fail=$((fail+1)); echo "  FAIL  $1"; }

roots=()
if [ "$#" -gt 0 ]; then roots=("$@")
else
    roots+=("$HOME/.ai-memory")
    [ -d "./.claude/memory" ] && roots+=("./.claude/memory")
fi

for root in "${roots[@]}"; do
    [ -d "$root" ] || { w "root not found: $root"; continue; }
    echo "Linting: $root"

    [ -f "$root/MEMORY.md" ] && p "MEMORY.md present" || f "MEMORY.md missing in $root"

    if [ -f "$root/blocked-actions.json" ]; then
        if python3 -c "import json,sys; json.load(open(sys.argv[1],encoding='utf-8'))" "$root/blocked-actions.json" 2>/dev/null; then
            p "blocked-actions.json valid JSON"; else f "blocked-actions.json invalid JSON"; fi
    fi

    if [ -d "$root/knowledge" ]; then
        for file in "$root"/knowledge/*.md; do
            [ -e "$file" ] || continue
            base="$(basename "$file")"
            case "$base" in *[A-Z]*|*" "*|*_*) w "filename not kebab-lowercase: $base" ;; esac
            for k in name type kind first_seen last_updated; do
                grep -Eq "^$k[[:space:]]*:" "$file" || w "$base missing frontmatter '$k'"
            done
            grep -q "Current State" "$file" || w "$base missing '## Current State'"
            grep -q "Timeline" "$file" || w "$base missing '## Timeline'"
        done
        p "knowledge/ scanned"
    fi

    if [ -f "$root/doctrine.md" ]; then
        ids="$(grep -Eo '^###[[:space:]]+D-[0-9]+' "$root/doctrine.md" | sort)"
        if [ "$(printf '%s\n' "$ids" | wc -l)" != "$(printf '%s\n' "$ids" | sort -u | wc -l)" ]; then
            f "duplicate doctrine D-XXX ids"; else p "doctrine ids unique"; fi
    fi
done

echo ""
echo "RESULT: $pass pass, $warn warn, $fail fail"
