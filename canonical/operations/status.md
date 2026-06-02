---
name: status
description: Read-only health dashboard for the two-layer memory — personal and project. Shows counts, pending doctrine candidates, repeat-workflow candidates, and suggested next actions. Use when the user says "status", "memory health", or "what should I do next".
---

# status — Read-Only Health (both layers)

Read only; modify nothing. Roots: `PERSONAL = ~/.ai-memory`, `PROJECT = ./.claude/memory` (if present).

## Gather (per layer)
- conversations: count + oldest/newest dates
- **captured-entries tally**: total individual entries across all `conversations/*.md` (the bullet
  items under the signal sections) + the **5 most recent** entries (newest first, with date+layer)
- knowledge: page count
- skills: count (Claude `.claude/skills` + Codex `.agents/skills`; flag if the two diverge)
- PERSONAL only: approved doctrines, pending candidates, reflection entries, blocked-tools count
- **hard-block health**: is `blocked-actions.json` valid JSON, and is the PreToolUse hook registered
  (Claude `settings.json` / Codex `config.toml`)? If the registry is corrupt or the hook is missing,
  the safety net is DOWN — report it **red**, don't stay silent.
- repeat-workflow candidates: scan logs' `## 🔁 Repeat candidates` + recurring topics

## Report
```
📊 Memory Status
Personal (~/.ai-memory):
  conversations: X (oldest → newest)   knowledge: X   skills: X
  doctrine: X approved, Y pending   reflection: Z entries   blocked tools: N
Project (<name>):
  conversations: X   knowledge: X   skills: X (claude/codex in sync? yes/no)

🗒️ 擷取紀錄：累計 N 筆（跨 D 天）。近 5 筆：
  1. [2026-06-02 personal] 💡 Decided to use PGLite for the demo
  2. ...

🔁 Repeat-workflow candidates: N  → run /harvest to evaluate
💡 Suggested: <run /dream | /review-doctrine | /harvest | nothing — healthy>
Platform skills in sync: ✅ / ⚠️ (list divergent skills)
Status: Healthy / Approaching limit / ⚠️ Needs cleanup
```

## Rules
- Never write anything. If something looks wrong (dead links, divergent skills), report it and
  suggest the fixing command — don't fix it here.
- Write in the user's language.
