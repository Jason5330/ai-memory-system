---
name: ingest-sessions
description: Batch-sediment memory from ACTUAL recent session records (Claude Code / Codex transcripts) instead of relying on in-the-moment self-capture. Use when the user says "ingest sessions", "sweep my recent chats", "補抓最近的對話", or on the nightly schedule. Reads recent transcripts + framework conversation logs, extracts signals, routes them to the right layer, dedups against what's already stored, and advances a watermark so re-runs only process new material.
---

# ingest-sessions — Sediment from real session records (idempotent, watermarked)

This closes the gap where "every conversation auto-sediments" otherwise depends on the agent
remembering to capture in the moment. It re-reads what *actually happened* and files what was missed.
Roots: `PERSONAL = ~/.ai-memory`, `PROJECT = ./.claude/memory` (if present). Routing:
`~/.ai-memory/guides/_routing.md`. It behaves like `/capture`, but over a batch of past sessions.

## Step 1: Sources (in priority order)
1. **Claude Code transcripts** — `~/.claude/projects/<encoded-cwd>/*.jsonl` (one folder per project
   path; each `.jsonl` is a session). Read sessions newer than the watermark (Step 2).
2. **Codex transcripts** — under `~/.codex/` (e.g. `~/.codex/sessions/*.jsonl` rollout files, or
   `~/.codex/history.jsonl`). Paths vary by version — look in `~/.codex` for session/history files.
3. **Framework conversation logs** — `conversations/*.md` in both layers NOT yet marked
   `[consolidated]` (catch anything `/capture` wrote but `/dream` hasn't processed).
4. **Chronicle / external activity logs (if available)** — **LEADS ONLY.** They point at where
   something happened; **verify the actual detail in the source system** before storing. Never store a
   Chronicle summary as fact.

## Step 2: Watermark (makes re-runs cheap + idempotent)
Read `~/.ai-memory/cron/ingest-watermark.txt` (an ISO timestamp; absent = first run → look back 7 days).
Only process sessions/messages **newer** than the watermark. At the end (Step 6) write the newest
processed timestamp back. This stops re-ingesting the same sessions.

## Step 3: Extract signals (same gate as /capture)
For each session in scope, pull: 💡 decisions (incl. short "OK/好" resolved against its 3-5 surrounding
turns), ❤️ task preferences, 🎭 persona signals, 📚 reusable knowledge, 🐛 problem+fix, 🛠️ skill
failures, ⚙️ tool failures. Apply the **knowledge filter gate** (this-session artifacts are output, not
knowledge) exactly as `/capture` Step 2.0.

## Step 4: Dedup before writing
For each candidate, check whether it's already stored (same fact in `knowledge/`, same decision in a
conversation log, same tool already in `blocked-actions.json`, same preference in
`feedback_user_style.md`). **Update/merge rather than duplicate.** When unsure, prefer not to create a
near-duplicate page.

## Step 5: Route + write (per layer)
Write each kept signal to the correct layer per `_routing.md` — preferences→`feedback_user_style.md`,
persona→`persona.md`, project knowledge→`PROJECT/knowledge/`, generic knowledge→`PERSONAL/knowledge/`,
tool failures→`blocked-actions.json` (+ MEMORY.md Environment Limits + hard-block), repeated workflows
→ flag as `## 🔁 Repeat candidates` for `/harvest`. Entity pages use the compiled-truth + timeline
format (Why + How to Apply required; every Timeline line names its source — here the source is the
session id / file). Update each layer's `MEMORY.md` index.

## Step 6: Advance watermark + report
Write the newest processed timestamp to `~/.ai-memory/cron/ingest-watermark.txt`. Report:
```
🧹 Session ingest complete
  Sources: Claude X sessions · Codex Y sessions · unconsolidated logs Z
  New: A entity pages · B preferences/persona · C tool-failures enforced · D repeat-candidates
  Deduped/merged: E   Watermark → <timestamp>
```

## Rules
- Idempotent: the watermark + dedup mean re-running is safe and cheap; never double-store.
- Same discipline as `/capture`: knowledge gate, layer routing, personal memory never into a project tree.
- Chronicle = leads only; verify in source before storing.
- Read-only on the transcripts themselves (never modify `~/.claude/projects` or `~/.codex`).
- Write in the user's language.
