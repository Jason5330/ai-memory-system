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
- skills: count (Claude `.claude/skills` + Codex `.agents/skills`). **EXCLUDE the operation names**
  `capture, dream, harvest, review-doctrine, status, schedule-dream, reset, help, ingest-sessions,
  skill-creator` — they're **Claude slash-commands vs Codex skills BY DESIGN** (always look
  "Codex-only", NOT divergence). For the rest: a `/harvest`-promoted skill is materialized to BOTH
  platforms atomically, so **any skill on only ONE platform is the user's OWN skill** (installed
  independently) — that's **fine, just informational**, NOT a cleanup item. Only the *count* of
  skills present on both matters for "in sync".
- PERSONAL only: approved doctrines, pending candidates, reflection entries, blocked-tools count
- **hard-block health**: is `blocked-actions.json` valid JSON, and is the PreToolUse hook registered
  (Claude `settings.json` / Codex `config.toml`)? If the registry is corrupt or the hook is missing,
  the safety net is DOWN — report it **red**, don't stay silent.
- repeat-workflow candidates: run the deterministic detector
  `~/.ai-memory/lib/detect-repeats.ps1` (`.sh` on Mac/Linux) — it tallies `🔁 repeat:<slug>` tags
  across both layers and lists workflows **seen ≥2× with no skill yet**. Surface those (the ones worth
  a `/harvest` → skill).

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

🔁 Repeat-workflow candidates (seen ≥2×, no skill yet): <slug> ×N, ...  → 要不要 /harvest 生成 skill？
🧰 Saved tools: N  (run `~/.ai-memory/lib/tool.ps1 list` — kept scripts you re-run on demand)
💡 Suggested: <run /dream | /review-doctrine | /harvest | nothing — healthy>
Platform skills: <N> on both · one-platform-only (your own, fine): <list or none>
Status: Healthy / Approaching limit / ⚠️ Needs cleanup
```
> **"Needs cleanup" is ONLY for real problems** — dead links, a corrupt/DOWN hard-block, or a layer
> overflowing. **Skill divergence is NOT a cleanup item**: operations are commands-vs-skills by design,
> and one-platform-only skills are the user's own (independently installed). A fresh install with
> everything at 0 and the hard-block up is **Healthy**. Only list divergent skills as *information*,
> never as a reason to say "needs cleanup".

## Rules
- Never write anything. If something looks wrong (dead links, divergent skills), report it and
  suggest the fixing command — don't fix it here.
- Write in the user's language.
