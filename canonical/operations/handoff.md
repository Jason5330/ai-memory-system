---
name: handoff
description: Write or read a single OVERWRITEABLE "hand off to the next session" summary per layer — the seamless-continuation note. Use when the user says "handoff", "交接", "換窗口接續", "做個交接", "上下文太長先存進度", or when a long session is about to end / compact. Writing overwrites the previous handoff for that layer (it never accumulates); reading shows the current one.
---

# handoff — Seamless next-session transfer (one overwriteable note per layer)

Borrowed from Open LeftBrain's `handoff` idea, kept as **plain markdown**. Distinct from `/capture`:
capture **accumulates** signals (logs/knowledge/decisions); handoff is **one short, always-current**
"what the next session needs to pick up" note that **overwrites** the previous one. Roots:
`PERSONAL = ~/.ai-memory`, `PROJECT = ./.claude/memory` (if present).

## Decide: WRITE or READ (default = WRITE)
`/handoff` is **almost always a WRITE** — the user wants to *save* where things are. Pick:
- **WRITE (default)** — whenever this session has ANY real progress / decisions / next steps to hand
  off, OR the user gave summary text, OR said 交接 / 做個交接 / 換窗口 / 先存進度. Distil it from the
  session and overwrite `<layer>/handoff.md`, **then show what you wrote**.
- **READ only** — *only* when there is genuinely nothing to hand off yet (a brand-new session, no work
  done) OR the user explicitly asked to *see* it ("看交接", "show/read handoff"). Then print the
  current handoff. (Session start already auto-reads it, so a manual READ is rare.)

> ⚠️ **Never answer a mid-conversation `/handoff` with just "no handoff exists / nothing written".**
> If there's no file yet, that means you should **WRITE the first one** from this session — not report
> its absence. Reporting "不存在、沒寫入" is the wrong outcome when the user clearly wanted to save progress.

## Which layer
Write to the **project** layer's `handoff.md` when inside an initialized project (it's about *this*
project's progress); otherwise the **personal** `~/.ai-memory/handoff.md`. (You may keep both — a
project handoff for the task, a personal one for cross-project state.)

## Write (overwrite) — the default action
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

## Read — only when there's nothing to save (or the user asked to *see* it)
Print the current `<layer>/handoff.md` (and the personal one if relevant) so the user / next session
sees exactly where to continue. If no file exists AND this session has progress, **WRITE one instead**
(see the rule above) rather than reporting that it's missing.

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
- **Protect the existing handoff — never clobber it with an empty/placeholder write.** If this session
  has no real progress yet (e.g. a brand-new window where the user just said "接續上次/讀交接"), **READ
  the current handoff, do NOT overwrite it.** Only overwrite once there is genuine new progress to save.
  A read must never destroy the note the previous session wrote.
- Short + structured + verbatim identifiers. Not a raw transcript.
- It's a transient *pointer* to continue; the durable facts still go to knowledge/doctrine via `/capture`.
- Reply in the user's language.
