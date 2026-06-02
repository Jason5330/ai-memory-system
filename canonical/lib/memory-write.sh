#!/usr/bin/env bash
# memory-write.sh — deterministic safe writer (Mac/Linux). Hermes-style write shell for the two
# safety-critical memory writes: append-to-file and add-to-block-registry. Does empty-check, dedup,
# file-lock (mkdir), read-latest-from-disk, atomic temp+rename (mv), and a drift backup. NOT a
# universal writer — knowledge pages (semantic merge) stay AI-edited. Called by _memory-gate.md.
#
# Usage:
#   memory-write.sh append     --file <path> --content "<text block>"
#   memory-write.sh block-tool  --tool <Name> --reason "..." --use-instead "<Alt>" [--platform both] [--file <registry.json>]
#
# Exit: 0 written · 0 (prints SKIP) duplicate/no-op · 2 empty content refused · 3 lock busy · 4 write error.
set -euo pipefail
MODE="${1:-append}"; shift || true
FILE=""; CONTENT=""; TOOL=""; REASON=""; USE_INSTEAD=""; PLATFORM="both"
while [ $# -gt 0 ]; do
  case "$1" in
    --file) FILE="$2"; shift 2;;
    --content) CONTENT="$2"; shift 2;;
    --tool) TOOL="$2"; shift 2;;
    --reason) REASON="$2"; shift 2;;
    --use-instead) USE_INSTEAD="$2"; shift 2;;
    --platform) PLATFORM="$2"; shift 2;;
    *) shift;;
  esac
done

acquire_lock() { # $1 target ; lock dir = target.lock ; returns 0 if acquired
  local lock="$1.lock"; local i=0
  while [ $i -lt 30 ]; do
    if mkdir "$lock" 2>/dev/null; then echo "$lock"; return 0; fi
    i=$((i+1)); sleep 0.1
  done
  return 1
}
release_lock() { [ -n "${1:-}" ] && [ -d "$1" ] && rmdir "$1" 2>/dev/null || true; }

atomic_write() { # $1 target  $2 text
  local target="$1"; local text="$2"; local dir; dir="$(dirname "$target")"
  mkdir -p "$dir"
  local tmp="$target.tmp"
  printf '%s' "$text" > "$tmp"
  [ -f "$target" ] && cp "$target" "$target.bak"   # drift snapshot
  mv -f "$tmp" "$target"                            # atomic rename
}

if [ "$MODE" = "append" ]; then
  [ -n "$FILE" ] || { echo "ERROR: --file required for append." >&2; exit 4; }
  # empty / whitespace-only?
  if [ -z "$(printf '%s' "$CONTENT" | tr -d '[:space:]')" ]; then
    echo "REFUSED: empty content (nothing written)."; exit 2
  fi
  LOCK="$(acquire_lock "$FILE")" || { echo "LOCK BUSY: $FILE.lock held — try again." >&2; exit 3; }
  trap 'release_lock "$LOCK"' EXIT
  CUR=""; [ -f "$FILE" ] && CUR="$(cat "$FILE")"   # read LATEST from disk
  if printf '%s' "$CUR" | grep -qF -- "$(printf '%s' "$CONTENT" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"; then
    echo "SKIP: identical content already present in $FILE (no change)."; exit 0
  fi
  SEP=""; [ -n "$CUR" ] && [ "${CUR: -1}" != $'\n' ] && SEP=$'\n'
  atomic_write "$FILE" "$CUR$SEP$CONTENT"$'\n'
  echo "✅ appended to $FILE"; exit 0
fi

if [ "$MODE" = "block-tool" ]; then
  [ -n "$TOOL" ] || { echo "ERROR: --tool required for block-tool." >&2; exit 4; }
  [ -n "$FILE" ] || FILE="$HOME/.ai-memory/blocked-actions.json"
  LOCK="$(acquire_lock "$FILE")" || { echo "LOCK BUSY: $FILE.lock held — try again." >&2; exit 3; }
  trap 'release_lock "$LOCK"' EXIT
  ADDED="$(date +%Y-%m-%d)"
  python3 - "$FILE" "$TOOL" "$REASON" "$USE_INSTEAD" "$PLATFORM" "$ADDED" <<'PY'
import json, sys, os
path, tool, reason, use_instead, platform, added = sys.argv[1:7]
data = {"blocked_tools": []}
if os.path.exists(path):
    try: data = json.load(open(path, encoding="utf-8"))
    except Exception: data = {"blocked_tools": []}
data.setdefault("blocked_tools", [])
for e in data["blocked_tools"]:
    if e.get("tool") == tool and (e.get("platform") in (platform, "both") or platform == "both"):
        print(f"SKIP: '{tool}' already in registry (no change)."); sys.exit(0)
data["blocked_tools"].append({"tool":tool,"reason":reason,"use_instead":use_instead,"platform":platform,"added":added})
tmp = path + ".tmp"
json.dump(data, open(tmp,"w",encoding="utf-8"), indent=2, ensure_ascii=False)
if os.path.exists(path):
    import shutil; shutil.copy(path, path + ".bak")
os.replace(tmp, path)
print(f"OK: blocked '{tool}' (platform={platform}) -> {path}. Restart Claude/Codex to load.")
PY
  exit 0
fi

echo "ERROR: unknown mode '$MODE' (use append | block-tool)." >&2; exit 4
