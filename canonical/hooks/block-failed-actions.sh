#!/usr/bin/env bash
# block-failed-actions.sh — PreToolUse enforcement layer (Mac/Linux; Claude Code + Codex)
#
# Reads ~/.ai-memory/blocked-actions.json. If the tool about to run is on the
# blocklist (and applies to this platform), exits 2 with a reason on stderr.
# BOTH Claude Code and Codex honor "exit 2 + stderr" to deny a PreToolUse call.
#
# Usage in registration:
#   Claude (settings.json):  block-failed-actions.sh claude
#   Codex  (config.toml):    block-failed-actions.sh codex
# Platform arg optional (defaults to "claude"). An entry blocks when its
# "platform" field is absent, "both", or equals this platform.
#
# Uses python3 for JSON parsing (reliably present; jq is not).

platform="${1:-claude}"
# personal brain root honors $AI_MEMORY_HOME (shared/relocatable brain), else default.
aimem="${AI_MEMORY_HOME:-$HOME/.ai-memory}"; aimem="${aimem/#\~/$HOME}"
registry="$aimem/blocked-actions.json"
[ -f "$registry" ] || exit 0

payload="$(cat)"

result="$(printf '%s' "$payload" | REG="$registry" PLAT="$platform" python3 -c '
import sys, json, os
try:
    payload = json.load(sys.stdin)
except Exception:
    sys.exit(0)
tool = payload.get("tool_name")
if not tool:
    sys.exit(0)
try:
    with open(os.environ["REG"], encoding="utf-8") as f:
        data = json.load(f)
except Exception:
    sys.exit(0)
plat = os.environ.get("PLAT", "claude").lower()
for b in data.get("blocked_tools", []):
    if b.get("tool") != tool:
        continue
    p = str(b.get("platform", "both")).lower()
    if p != "both" and p != plat:
        continue
    print(f"{b.get(\"reason\",\"\")}|||{b.get(\"use_instead\",\"\")}|||{tool}")
    break
' 2>/dev/null)"

if [ -n "$result" ]; then
    reason="${result%%|||*}"
    rest="${result#*|||}"
    use_instead="${rest%%|||*}"
    tool="${rest##*|||}"
    echo "[memory enforcement] $tool is known-broken in this environment: $reason. Use $use_instead instead; do not call $tool." >&2
    exit 2
fi

exit 0
