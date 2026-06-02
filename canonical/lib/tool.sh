#!/usr/bin/env bash
# tool.sh - saved-tools runner (Mac/Linux). A "saved tool" is a working script the AI wrote once and
# KEPT, so the SAME request next time just RUNS it instead of re-writing code. Distinct from a skill
# (a playbook the AI follows): a tool is a single executable, run verbatim.
#
# Registry: ~/.ai-memory/tools/tools.json  ;  scripts live next to it as <slug>.sh / <slug>.ps1
# Usage:
#   tool.sh list
#   tool.sh run <slug> [args...]
#   tool.sh add <slug> --desc "..." --triggers "a;b;c" --script <path-to-working-script>
#   tool.sh path <slug>
# Exit: 0 ok / 2 not found / 3 bad usage / 4 run error.
set -euo pipefail
DIR="$HOME/.ai-memory/tools"; REG="$DIR/tools.json"; mkdir -p "$DIR"
[ -f "$REG" ] || echo '{ "tools": [] }' > "$REG"
CMD="${1:-list}"; SLUG="${2:-}"; shift || true; [ $# -gt 0 ] && shift || true
DESC=""; TRIGGERS=""; SCRIPT=""; ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --desc) DESC="$2"; shift 2;;
    --triggers) TRIGGERS="$2"; shift 2;;
    --script) SCRIPT="$2"; shift 2;;
    *) ARGS+=("$1"); shift;;
  esac
done

case "$CMD" in
  list)
    python3 - "$REG" <<'PY'
import json,sys
d=json.load(open(sys.argv[1],encoding="utf-8")); t=d.get("tools",[])
if not t: print("TOOLS: none saved yet."); sys.exit(0)
print(f"TOOLS: {len(t)} saved -")
for x in t: print("  - %s  : %s   [triggers: %s]" % (x.get("slug"), x.get("desc",""), ", ".join(x.get("triggers",[]))))
PY
    ;;
  path)
    [ -n "$SLUG" ] || { echo "usage: tool.sh path <slug>"; exit 3; }
    if [ -f "$DIR/$SLUG.sh" ]; then echo "$DIR/$SLUG.sh"; else echo "NOT FOUND: $SLUG.sh"; exit 2; fi
    ;;
  run)
    [ -n "$SLUG" ] || { echo "usage: tool.sh run <slug> [args...]"; exit 3; }
    p="$DIR/$SLUG.sh"
    [ -f "$p" ] || { echo "NOT FOUND: no saved tool '$SLUG' for this platform ($SLUG.sh)"; exit 2; }
    bash "$p" "${ARGS[@]:-}" || { echo "RUN ERROR"; exit 4; }
    ;;
  add)
    { [ -n "$SLUG" ] && [ -n "$SCRIPT" ]; } || { echo "usage: tool.sh add <slug> --desc '...' --triggers 'a;b' --script <path>"; exit 3; }
    [ -f "$SCRIPT" ] || { echo "NOT FOUND: script '$SCRIPT'"; exit 2; }
    ext=".${SCRIPT##*.}"; [ "$ext" = ".$SCRIPT" ] && ext=".sh"
    cp "$SCRIPT" "$DIR/$SLUG$ext"
    ADDED="$(date +%Y-%m-%d)"
    python3 - "$REG" "$SLUG" "$DESC" "$TRIGGERS" "$ADDED" <<'PY'
import json,sys
reg,slug,desc,triggers,added=sys.argv[1:6]
d=json.load(open(reg,encoding="utf-8")); d.setdefault("tools",[])
d["tools"]=[t for t in d["tools"] if t.get("slug")!=slug]
trg=[s.strip() for s in triggers.split(";") if s.strip()]
d["tools"].append({"slug":slug,"desc":desc,"triggers":trg,"added":added})
tmp=reg+".tmp"; json.dump(d,open(tmp,"w",encoding="utf-8"),indent=2,ensure_ascii=False)
import os; os.replace(tmp,reg)
print(f"SAVED tool '{slug}'. Next time a matching request comes, run: tool.sh run {slug}")
PY
    ;;
  *) echo "usage: tool.sh list | run <slug> [args] | add <slug> --desc --triggers --script | path <slug>"; exit 3;;
esac
