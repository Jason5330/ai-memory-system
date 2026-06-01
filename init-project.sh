#!/usr/bin/env bash
# init-project.sh — initialize the current folder as a memory-enabled project (Mac/Linux). Idempotent.
# Run INSIDE the project folder:  ./init-project.sh   (or: ./init-project.sh /path/to/proj)
set -euo pipefail

proj="${1:-$(pwd)}"; proj="$(cd "$proj" && pwd)"
name="$(basename "$proj")"
PT="$HOME/.ai-memory/project-templates"
[ -d "$PT" ] || { echo "Run ./install-personal.sh first (missing $PT)."; exit 1; }

echo ""; echo "=== init-project: $name ==="

mkdir -p "$proj/.claude/memory/knowledge/archive" "$proj/.claude/memory/conversations/archive" \
         "$proj/.claude/skills" "$proj/.codex" "$proj/.agents/skills"

mem="$proj/.claude/memory/MEMORY.md"
[ -f "$mem" ] || sed "s/{{PROJECT_NAME}}/$name/g" "$PT/MEMORY.md" > "$mem"

new_entry() { # $1 tpl  $2 dest
    [ -f "$2" ] && return 0
    sed "s/{{PROJECT_NAME}}/$name/g" "$PT/$1" > "$2"
}
new_entry project-CLAUDE.md "$proj/CLAUDE.md"
new_entry project-AGENTS.md "$proj/AGENTS.md"

cfg="$proj/.codex/config.toml"
[ -f "$cfg" ] || cat > "$cfg" <<'EOF'
# Codex project config for this project. Skills live in ./.agents/skills (not here).
# Add project-scoped PreToolUse hooks or [[skills.config]] entries below if needed.
EOF

gi="$proj/.gitignore"
guard=$'\n# ai-memory: project knowledge is shareable; never commit machine-local noise\n.claude/memory/conversations/\n.codex/\n'
if [ -f "$gi" ]; then
    grep -q 'ai-memory: project knowledge' "$gi" || printf '%s' "$guard" >> "$gi"
else printf '%s' "${guard#$'\n'}" > "$gi"; fi

echo "Created: CLAUDE.md, AGENTS.md, .claude/memory, .claude/skills, .codex/config.toml, .agents/skills"
echo "Personal layer (~/.ai-memory) is shared and loaded globally; this only adds the project layer."
