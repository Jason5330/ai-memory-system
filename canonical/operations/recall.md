---
name: recall
description: Fuzzy/semantic-ish search of memory — find the knowledge pages most related to a query even with synonyms or paraphrase (not just exact keywords). Use when the user says "recall", "找一下記憶", "之前有沒有記過…", "搜記憶", "find in memory", or before a risky/又做過的任務 to pull prior lessons. Read-only.
---

# recall — Fuzzy memory search (Python-optional, markdown-native)

Finds the knowledge pages most relevant to a query by **fuzzy + token-overlap** matching (so synonyms
and paraphrase hit, not only exact keywords). Searches the **plain-markdown** store across both layers
(`~/.ai-memory/knowledge` + `./.claude/memory/knowledge`). Borrowed from Open LeftBrain's search, kept
true to this framework (no DB, no vectors).

## How to run (prefer the Python helper; fall back if no Python)
**If Python is available** (best — semantic-ish, ranked):
```
python "$env:USERPROFILE\.ai-memory\lib\recall.py" "<query>"        # Windows
python3 ~/.ai-memory/lib/recall.py "<query>"                        # Mac/Linux
```
It prints the top matches as `[score] (layer) <name> — <summary>` + path; add `--json` for machine
output, `--limit N` to widen. It's **read-only** and **pure Python stdlib** (zero deps) — Python is the
*only* thing it needs, and only for this command.

**If Python is NOT installed** (graceful fallback): scan each layer's `MEMORY.md` index and
`knowledge/*.md` titles for the query terms by keyword yourself, and list the closest pages. Tell the
user once: *"（沒裝 Python，改用關鍵字搜；裝了 Python 的話 /recall 會做模糊/同義搜尋更準。）"*

## After finding pages
Open the top 1–3 matching `knowledge/<name>.md`, read each page's `## Current State` first (the latest
truth), and answer from them — cite which page. Don't dump whole pages; summarize what's relevant.

## When to use
- The user asks "did we record … / 之前怎麼處理過 X".
- **Before a risky or repeated task** (deploy / schema change / a bug you may have hit) — recall prior
  `lesson` / `bugfix` / decisions first, then act.
- Exact-keyword `MEMORY.md` lookup missed something you suspect is stored under a different wording.

## Rules
- Read-only — never writes. (To store, use `/capture`; to hand off, `/handoff`.)
- Markdown stays the source of truth; recall is just a smarter index over it.
- Reply in the user's language.
