#!/usr/bin/env bash
# install-personal.sh — Personal-layer installer (Mac/Linux) for the dual-platform memory system.
# Sets up ~/.ai-memory and materializes entry/operations/skills/hook/cron to BOTH Claude Code
# (~/.claude) and Codex (~/.codex + ~/.agents/skills). Idempotent.
# Run from the framework folder:  ./install-personal.sh
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)/canonical"
# Personal brain root. Default ~/.ai-memory. Set $AI_MEMORY_HOME to RELOCATE the brain (e.g. a synced
# cloud folder for cross-machine sharing). Claude Code + Codex already share one brain; pointing both
# machines' AI_MEMORY_HOME at the same synced folder = shared memory.
PERSONAL="${AI_MEMORY_HOME:-$HOME/.ai-memory}"; PERSONAL="${PERSONAL/#\~/$HOME}"
CUSTOM_HOME=0; [ "$PERSONAL" != "$HOME/.ai-memory" ] && CUSTOM_HOME=1
GUIDES="$PERSONAL/guides"; HOOKS="$PERSONAL/hooks"; CRON="$PERSONAL/cron"
CLAUDE="$HOME/.claude"; CMDS="$CLAUDE/commands"; CLAUDE_SK="$CLAUDE/skills"
CODEX="$HOME/.codex"; AGENTS_SK="$HOME/.agents/skills"

echo ""; echo "=== AI Memory System — personal install ==="
echo "Personal brain: $PERSONAL"
[ "$CUSTOM_HOME" = 1 ] && echo "  (relocated via AI_MEMORY_HOME — set the SAME value on every machine/shell to share this brain)"

# 1. Directories
mkdir -p "$PERSONAL" "$GUIDES" "$HOOKS" "$CRON" "$PERSONAL/knowledge" "$PERSONAL/knowledge/archive" \
         "$PERSONAL/conversations" "$PERSONAL/conversations/archive" "$CMDS" "$CLAUDE_SK" "$CODEX" "$AGENTS_SK"
echo "[1] directories ready"

# 2. Migrate legacy ~/.claude/memory (copy-if-missing; keep original)
if [ -d "$CLAUDE/memory" ]; then
    (cd "$CLAUDE/memory" && find . -type f | while IFS= read -r rel; do
        dest="$PERSONAL/${rel#./}"; mkdir -p "$(dirname "$dest")"; [ -f "$dest" ] || cp "$rel" "$dest"; done)
    echo "[2] migrated existing ~/.claude/memory (copy-if-missing; original kept)"
else echo "[2] no legacy ~/.claude/memory to migrate"; fi

# 3. Personal templates (copy-if-missing — your data)
TPL="$SRC/templates/personal"
for f in MEMORY.md doctrine.md doctrine_candidates.md feedback_user_style.md persona.md reflection.md; do
    [ -f "$PERSONAL/$f" ] || cp "$TPL/$f" "$PERSONAL/$f"
done
[ -f "$PERSONAL/blocked-actions.json" ] || cp "$SRC/templates/blocked-actions.json" "$PERSONAL/blocked-actions.json"
echo "[3] personal templates in place (existing data preserved)"

# Materialize a framework .md: plain copy by default; when the brain is relocated, rewrite the
# literal ~/.ai-memory runtime references to the real root so the AI reads correct paths.
copy_doc() { # $1 src  $2 dest
    if [ "$CUSTOM_HOME" = 1 ]; then sed "s#~/\.ai-memory#$PERSONAL#g" "$1" > "$2"; else cp "$1" "$2"; fi
}

# 4. Framework-owned files (always overwrite)
copy_doc "$SRC/PATHS.md" "$GUIDES/PATHS.md"
copy_doc "$SRC/operations/_routing.md" "$GUIDES/_routing.md"
copy_doc "$SRC/operations/_materialize-skill.md" "$GUIDES/_materialize-skill.md"
copy_doc "$SRC/operations/_memory-gate.md" "$GUIDES/_memory-gate.md"
cp "$SRC/hooks/block-failed-actions.ps1" "$HOOKS/"; cp "$SRC/hooks/block-failed-actions.sh" "$HOOKS/"; chmod +x "$HOOKS/block-failed-actions.sh"
cp "$SRC/cron/nightly.ps1" "$CRON/"; cp "$SRC/cron/nightly.sh" "$CRON/"; chmod +x "$CRON/nightly.sh"
cp "$SRC/lint/memory-lint.ps1" "$PERSONAL/"; cp "$SRC/lint/memory-lint.sh" "$PERSONAL/"; chmod +x "$PERSONAL/memory-lint.sh"
mkdir -p "$PERSONAL/reset"; cp "$SRC/reset/reset.ps1" "$PERSONAL/reset/"; cp "$SRC/reset/reset.sh" "$PERSONAL/reset/"; chmod +x "$PERSONAL/reset/reset.sh"
mkdir -p "$PERSONAL/lib"; cp "$SRC/lib/memory-write.ps1" "$PERSONAL/lib/"; cp "$SRC/lib/memory-write.sh" "$PERSONAL/lib/"; chmod +x "$PERSONAL/lib/memory-write.sh"
cp "$SRC/lib/detect-repeats.ps1" "$PERSONAL/lib/"; cp "$SRC/lib/detect-repeats.sh" "$PERSONAL/lib/"; chmod +x "$PERSONAL/lib/detect-repeats.sh"
cp "$SRC/lib/tool.ps1" "$PERSONAL/lib/"; cp "$SRC/lib/tool.sh" "$PERSONAL/lib/"; chmod +x "$PERSONAL/lib/tool.sh"
cp "$SRC/lib/recall.py" "$PERSONAL/lib/"
mkdir -p "$PERSONAL/tools"; [ -f "$PERSONAL/tools/tools.json" ] || cp "$SRC/templates/tools.json" "$PERSONAL/tools/tools.json"
# stage project scaffolding so init-project works from any folder without the framework repo
PT="$PERSONAL/project-templates"; mkdir -p "$PT"
copy_doc "$SRC/entry/project-CLAUDE.md" "$PT/project-CLAUDE.md"
copy_doc "$SRC/entry/project-AGENTS.md" "$PT/project-AGENTS.md"
cp "$SRC/templates/project/MEMORY.md" "$PT/MEMORY.md"
echo "[4] guides + hook + cron + lint + reset + safe-writer (lib) + project-templates installed"

# 5. Entry files — marker-delimited framework block REPLACED on every install (upgrades refresh the
#    entry); any of YOUR own content outside the markers is preserved.
install_entry() { # $1 src  $2 dest
    local content; content="$(sed "s#{{PERSONAL_MEMORY}}#$PERSONAL#g" "$1")"
    [ "$CUSTOM_HOME" = 1 ] && content="$(printf '%s' "$content" | sed "s#~/\.ai-memory#$PERSONAL#g")"
    mkdir -p "$(dirname "$2")"
    SRC_CONTENT="$content" DEST="$2" python3 - <<'PY'
import os
S='<!-- AI-MEMORY-START (auto-managed by install-personal; do not edit between markers) -->'
E='<!-- AI-MEMORY-END -->'
block=S+'\n'+os.environ['SRC_CONTENT']+'\n'+E
dest=os.environ['DEST']
if os.path.exists(dest):
    cur=open(dest,encoding='utf-8').read()
    si=cur.find('<!-- AI-MEMORY-START'); ei=cur.find(E)
    if si>=0 and ei>=si: new=cur[:si]+block+cur[ei+len(E):]
    elif '# AI Memory System' in cur: new=block
    else: new=cur.rstrip()+'\n\n'+block
else: new=block
open(dest,'w',encoding='utf-8').write(new)
PY
}
install_entry "$SRC/entry/CLAUDE.md" "$CLAUDE/CLAUDE.md"
install_entry "$SRC/entry/AGENTS.md" "$CODEX/AGENTS.md"
echo "[5] entry files: ~/.claude/CLAUDE.md + ~/.codex/AGENTS.md"

# 6. Operations → Claude commands + Codex skills
mkdir -p "$CODEX/prompts"
for op in capture handoff recall dream harvest review-doctrine status schedule-dream reset help ingest-sessions; do
    copy_doc "$SRC/operations/$op.md" "$CMDS/$op.md"                        # Claude slash-command
    mkdir -p "$AGENTS_SK/$op"; copy_doc "$SRC/operations/$op.md" "$AGENTS_SK/$op/SKILL.md"   # Codex skill (intent)
    copy_doc "$SRC/operations/$op.md" "$CODEX/prompts/$op.md"              # Codex slash-command (/capture etc.)
done
echo "[6] operations materialized: Claude commands + Codex skills + Codex /slash prompts"

# 6b. Deploy the official Anthropic skill-creator to BOTH platforms (all skill creation goes through it).
SC_SRC="$(dirname "$SRC")/skills/skill-creator"
if [ -f "$SC_SRC/SKILL.md" ]; then
    for scdest in "$CLAUDE_SK/skill-creator" "$AGENTS_SK/skill-creator"; do
        if [ ! -f "$scdest/SKILL.md" ]; then
            mkdir -p "$scdest"; cp -R "$SC_SRC/." "$scdest/"
        fi
    done
    echo "[6b] skill-creator deployed to ~/.claude/skills + ~/.agents/skills"
else echo "[6b] skill-creator source not found (skipped)"; fi

# 7a. Claude settings.json hook (catch-all matcher; python3 merge)
SETTINGS="$CLAUDE/settings.json"
HOOK_SH="$HOOKS/block-failed-actions.sh"
SETTINGS="$SETTINGS" HOOK_SH="$HOOK_SH" python3 - <<'PY'
import json, os
p = os.environ["SETTINGS"]; hook = os.environ["HOOK_SH"]
try:
    s = json.load(open(p, encoding="utf-8"))
except Exception:
    s = {}
s.setdefault("hooks", {}).setdefault("PreToolUse", [])
present = any("block-failed-actions" in (h.get("command","")) for e in s["hooks"]["PreToolUse"] for h in e.get("hooks", []))
if not present:
    s["hooks"]["PreToolUse"].append({"matcher":"*","hooks":[{"type":"command","command":f'bash "{hook}" claude'}]})
    json.dump(s, open(p,"w",encoding="utf-8"), indent=2, ensure_ascii=False)
    print("[7a] Claude PreToolUse hook registered (matcher: *)")
else:
    print("[7a] Claude hook already registered")
PY

# 7b. Codex config.toml hook (append-if-marker-absent)
CFG="$CODEX/config.toml"
if [ -f "$CFG" ] && grep -q 'block-failed-actions' "$CFG"; then
    echo "[7b] Codex hook already present"
else
cat >> "$CFG" <<EOF

# --- ai-memory enforcement hook (block-failed-actions) ---
[[hooks.PreToolUse]]
matcher = ".*"

[[hooks.PreToolUse.hooks]]
type = "command"
command = 'bash "$HOOK_SH" codex'
statusMessage = "ai-memory: checking blocked tools"
EOF
    echo "[7b] Codex PreToolUse hook appended to config.toml"
fi

echo ""; echo "=== Personal install complete ==="
echo "Brain: $PERSONAL   |   Restart Claude Code / Codex to load."
echo "Per-project: run  ./init-project.sh  inside each project folder."
echo "Nightly: run /schedule-dream (or see ~/.ai-memory/cron/)."
