---
name: handoff
description: Write or read a single OVERWRITEABLE "hand off to the next session" summary per layer — the seamless-continuation note. Use when the user says "handoff", "交接", "換窗口接續", "做個交接", "上下文太長先存進度", or when a long session is about to end / compact. Writing overwrites the previous handoff for that layer (it never accumulates); reading shows the current one.
---

# handoff — Seamless next-session transfer (one overwriteable note per layer)

Borrowed from Open LeftBrain's `handoff` idea, kept as **plain markdown**. Distinct from `/capture`:
capture **accumulates** signals (logs/knowledge/decisions); handoff is **one short, always-current**
"what the next session needs to pick up" note that **overwrites** the previous one. Roots:
`PERSONAL = ~/.ai-memory`, `PROJECT = ./.claude/memory` (if present).

## Which layer
Write to the **project** layer's `handoff.md` when inside an initialized project (it's about *this*
project's progress); otherwise the **personal** `~/.ai-memory/handoff.md`. (You may keep both — a
project handoff for the task, a personal one for cross-project state.)

## Write (overwrite) — `/handoff "summary"` or `/handoff` after a long session
Overwrite `<layer>/handoff.md` with a concise, structured note. Populate every section that applies;
**preserve exact identifiers verbatim** (paths, function names, error codes, commands):
```markdown
# Handoff — <layer> — <YYYY-MM-DD HH:MM>
## Current state      <!-- what's true right now -->
## Completed          <!-- what got done this session -->
## Important files/IDs <!-- exact paths, functions, error codes, commands -->
## Decisions          <!-- chosen X over Y because … -->
## Next steps         <!-- the immediate next actions -->
## Open issues / risks
```
Keep it SHORT (it's a pointer, not a transcript) and **always current** — overwrite, don't append.
If the user gave the summary text, use it; otherwise distil it from this session.

## Read — `/handoff` (no new content)
Print the current `<layer>/handoff.md` (and the personal one if relevant) so the user / next session
sees exactly where to continue.

## When to write it (proactive)
- The user says they're switching windows / starting a fresh session.
- A long or token-heavy session (before the harness compacts — pairs with the entry file's
  "capture before the window compacts" rule).
- A phase transition (research → build → verify).

## Loaded at session start
Each layer's `handoff.md` is read at session start **before** the rest (it's the freshest "continue
from here"). See the entry files' "On session start".

## Rules
- **STANDALONE & SEPARATE — never mixed with other memory.** The handoff lives in its OWN file
  `<layer>/handoff.md` only. **Never** write it into `MEMORY.md`, `conversations/`, `knowledge/`, or
  `doctrine`; **never index its content into `MEMORY.md`**; `/capture`, `/dream`, `/ingest-sessions`,
  and `/recall` all **ignore `handoff.md`** (they don't fold it into the accumulating memory). It is
  read directly at session start and nowhere else.
- **Overwrite, never accumulate** — exactly ONE handoff per layer, always replaced by the latest write
  (no history, no appending old summaries).
- Short + structured + verbatim identifiers. Not a raw transcript.
- It's a transient *pointer* to continue; the durable facts still go to knowledge/doctrine via `/capture`.
- Reply in the user's language.
