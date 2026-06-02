---
name: ingest-sessions
description: Batch-sediment memory from ACTUAL recent session records (Claude Code / Codex transcripts) instead of relying on in-the-moment self-capture. Use when the user says "ingest sessions", "sweep my recent chats", "補抓最近的對話", or on the nightly schedule. Reads recent transcripts + framework conversation logs, extracts signals, routes them to the right layer, dedups against what's already stored, and advances per-source checkpoints so re-runs only process new material.
---

# ingest-sessions — Sediment from real session records (idempotent, per-source checkpoints)

This closes the gap where "every conversation auto-sediments" otherwise depends on the agent
remembering to capture in the moment. It re-reads what *actually happened* and files what was missed.
Roots: `PERSONAL = ~/.ai-memory`, `PROJECT = ./.claude/memory` (if present). Routing:
`~/.ai-memory/guides/_routing.md`. It behaves like `/capture`, but over a batch of past sessions.

## Step 1: Sources (in priority order)
1. **Claude Code transcripts** — `~/.claude/projects/<encoded-cwd>/*.jsonl` (one folder per project
   path; each `.jsonl` is a session). Read past each source's checkpoint (Step 2).
2. **Codex transcripts** — under `~/.codex/` (e.g. `~/.codex/sessions/*.jsonl` rollout files, or
   `~/.codex/history.jsonl`). Paths vary by version — look in `~/.codex` for session/history files.
3. **Framework conversation logs** — `conversations/*.md` in both layers NOT yet marked
   `[consolidated]` (catch anything `/capture` wrote but `/dream` hasn't processed).
4. **Chronicle / external activity logs (if available)** — **LEADS ONLY.** They point at where
   something happened; **verify the actual detail in the source system** before storing. Never store a
   Chronicle summary as fact.

## Step 2: Per-source checkpoints (idempotent; handles late/rewritten/out-of-order files)
A single global timestamp is too coarse — transcripts can **land late**, get **rewritten/compacted**,
or have **out-of-order mtimes across projects**, so a global watermark can skip real unprocessed
content. Instead keep a **per-source checkpoint** store at
`~/.ai-memory/cron/ingest-checkpoints.json`, keyed by source (the transcript file path), each holding:
`{ session_id, last_event_ts, last_offset, content_hash }` (offset = lines or bytes processed;
content_hash = hash of the processed range / whole file).

Decide **per source** (sources are independent — a late/reordered file never makes another skip):
- **Unseen source** → process from the start (first run only: cap look-back at 7 days to bound cost).
- **content_hash unchanged AND nothing past `last_offset`** → skip (nothing new).
- **Grew past `last_offset`** → process only the **delta** (events after `last_offset`).
- **content_hash changed for an already-processed range** (file rewritten/compacted) → re-scan the
  file and rely on Step 4 dedup to avoid re-storing; then reset that source's checkpoint.

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

## Step 6: Update checkpoints + report
For each source processed, write its updated checkpoint (`session_id`, `last_event_ts`, `last_offset`,
`content_hash`) back to `~/.ai-memory/cron/ingest-checkpoints.json`. Report:
```
🧹 Session ingest complete
  Sources: Claude X sessions · Codex Y sessions · unconsolidated logs Z (A skipped: no change)
  New: B entity pages · C preferences/persona · D tool-failures enforced · E repeat-candidates
  Deduped/merged: F   Checkpoints updated: G sources
```

## Rules
- Idempotent: the per-source checkpoints + dedup mean re-running is safe and cheap; never double-store.
- Same discipline as `/capture`: knowledge gate, layer routing, personal memory never into a project tree.
- Chronicle = leads only; verify in source before storing.
- Read-only on the transcripts themselves (never modify `~/.claude/projects` or `~/.codex`).
- Write in the user's language.
