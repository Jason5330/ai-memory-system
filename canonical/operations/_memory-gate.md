# Memory Decision Gate (shared by /capture, /ingest-sessions, and session-end auto-capture)

> **Purpose.** Let the agent decide *on its own* what is worth remembering — Hermes/GBrain style —
> WITHOUT letting it rewrite its own long-term rules. Borrowed: GBrain's `signal → confidence`
> detector, Harness's *pass-state gating* (the agent may not self-promote a rule), Hermes's safe-write
> shell. Imported by `/capture`, `/ingest-sessions`, and the entry files' "auto-capture" section.
> Roots resolve per `~/.ai-memory/guides/PATHS.md`.

Run this gate for each candidate signal (a preference, decision, fix, reusable fact, persona cue,
broken tool, repeated workflow). It has two questions: **(A) how confident am I?** and **(B) which
category is this?** — because the category decides whether high confidence is even *allowed* to
auto-write.

## A. Confidence → action

| Confidence | What it looks like | Action |
|---|---|---|
| **HIGH** — explicit & stable | User stated it directly and it generalizes: "always reply in 繁中", "stop using tool X here", "this decision is final", a reproduced error+fix, a workflow you watched happen 2+ times. | **Auto-write now** — but only to a *safe category* (see B). No need to ask. |
| **MEDIUM** — probable | You *infer* a preference / reusable fact that wasn't stated outright; "this might be how they like it". | **Write a CANDIDATE only** — `reflection.md` (an observation) or `doctrine_candidates.md` (a possible rule). Never straight into doctrine/skill. |
| **LOW** — one-off / vague | This-session artifact, temp path, chit-chat, a guess, a task that won't recur. | **Skip.** (Same spirit as `/capture` Step 2.0 knowledge gate — when in doubt, don't store.) |

> **Signal-density test (apply to every candidate):** *"if I DROP this, would the AI's **next step** be
> wrong?"* If nothing changes → **skip**. Context is a limited attention budget, not a warehouse —
> low-signal memory *dilutes* the high-signal memory, so over-capturing makes recall worse, not safer.
>
> **Preserve exact identifiers VERBATIM** in anything you do write — file paths, function/variable
> names, error codes, commit SHAs, API params, versions, exact commands (`config/redis.ts`,
> `ECONNREFUSED`, `bun install --ignore-scripts`). **Never paraphrase** ("the config file") — a
> paraphrased identifier forces a future session to re-discover it, defeating the memory.

### 🚫 NEVER capture — hard exclusions (these are LOW no matter how confident)
Over-capturing these is the #1 way memory fills with noise. If a candidate matches ANY row, **skip it**
(or route it elsewhere as noted) — do NOT write it as a memory/knowledge entry:

| Don't store | Why | Do instead |
|---|---|---|
| **The agent's own bookkeeping** — "已寫入 feedback_user_style.md", "已 capture 這條", "更新了索引" | meta about your own action, never a fact about the user/world | nothing — it's already done |
| **This-session / transient status** — "本 session 串接正常", "cheat-debug 漏建兩次", "預測進行中: …", "測試中斷" | true for minutes, useless next week; clutters recall | if it's "where to continue" → **`handoff.md`**, not knowledge |
| **In-progress / next-step state** — "v2 下次繼續用真實 PDF 驗收", "OCR 已實作但…" | that's a handoff pointer, not durable knowledge | **`/handoff`** (one overwriteable note) |
| **Changelog-style self-notes** — "新增了 cheat-go/cheat-debug skills", "升版了 X" | history, not a reusable rule or fact | git/changelog already has it |
| **One-off env / task trivia** — "jq 1.8.1 已安裝", "某.xlsx 已重建", "磁碟上有多份副本" | won't change a future decision | skip (or a broken-tool entry only if a tool truly failed twice) |
| **Cryptic fragments** — "IR 維度爭議：用戶選主 Claude 全套分" | too terse to be actionable later | skip, or rewrite as a real decision with context |
| **Duplicates / near-dupes** of an existing entry | dilutes the canonical one | update the existing entry instead |

> Rule of thumb: a memory entry must still be **true and useful a month from now**. "Progress / status /
> what-I-just-did" is **handoff** material (transient, overwriteable), NOT capture material (durable).
> When unsure between *durable fact* and *current state* → it's state → don't capture.

## B. Category gate — what HIGH confidence is ALLOWED to auto-write

**✅ Safe categories — auto-write on HIGH confidence** (these describe the user or the world, not the
agent's governing rules):

| Category | Destination | Writer |
|---|---|---|
| ❤️ Task preference | `PERSONAL/feedback_user_style.md` | safe append |
| 🎭 AI persona/voice | `PERSONAL/persona.md` | safe append |
| 📚🧩 Reusable knowledge / entity | `<layer>/knowledge/<entity>.md` (compiled-truth+timeline) | AI edit (two-step) |
| 💬 Conversation log entry | `<layer>/conversations/YYYY-MM-DD.md` | safe append |
| ⚙️ Broken tool (on the **2nd** failure) | `PERSONAL/blocked-actions.json` + MEMORY.md + hook | safe `block-tool` |

**🚫 Gated categories — NEVER auto-write, regardless of confidence** (this is the *pass-state gate*:
the agent may not self-promote its own governance):

| Category | Even at HIGH confidence → | Promoted only by |
|---|---|---|
| 🧭 **Doctrine** (behavior rule / "don't repeat this mistake") | write to `PERSONAL/doctrine_candidates.md` | `/review-doctrine` (human ✅) |
| 🛠️ **Skill / subagent / automation** | flag `## 🔁 Repeat candidates` in today's log | `/harvest` review gate (human ✅) |

> **Why the asymmetry.** A wrong preference page is cheap to fix; a wrong *doctrine* silently steers
> every future session, and a wrong *skill* runs unattended. Those two layers stay behind a human
> gate by design (Harness pass-state gating). Hermes auto-captures facts/preferences/workflows — we
> match that — but "edit my own long-term rules" is never autonomous here.

## C. Two-step write (crash-safe ordering — Harness)

Always write in this order so a mid-write crash leaves at worst an orphan file, never a corrupt index:

1. **Write the full topic/knowledge file first**, then confirm it exists on disk.
2. **Only then** add/refresh its one-line pointer in that layer's `MEMORY.md`.

Never update `MEMORY.md` for content you haven't already persisted. `MEMORY.md` stays a *bounded
index* (one line per item) — never paste body text into it.

## D. Safe writer (Hermes-style atomic shell) — for the safety-critical writes

For the two writes where corruption is worst (the **hard-block registry** and **append-only files**),
go through the deterministic writer instead of hand-editing — it does empty-check, dedup, file-lock,
read-latest-from-disk, atomic temp+rename, and a drift backup:

```
# Windows
& "$env:USERPROFILE\.ai-memory\lib\memory-write.ps1" -Mode append    -File <path> -Content "<block>"
& "$env:USERPROFILE\.ai-memory\lib\memory-write.ps1" -Mode block-tool -Tool <Name> -Reason "..." -UseInstead "<Alt>" -Platform both
# Mac/Linux
bash ~/.ai-memory/lib/memory-write.sh append    --file <path> --content "<block>"
bash ~/.ai-memory/lib/memory-write.sh block-tool --tool <Name> --reason "..." --use-instead "<Alt>" --platform both
```

Exit: `0` written · `0`(SKIP) duplicate, nothing changed · `2` empty content refused · `3` lock busy.
Knowledge pages (which need semantic merge of Current State + Timeline) stay AI-edited — the writer is
deliberately scoped to append + JSON-registry, not a universal write router.

## E. One external memory provider (forward rule)

Built-in markdown is ALWAYS the primary store. If a future external brain is mounted (GBrain / Mem0 /
qmd), **at most one** may be active at a time — never two backends writing concurrently (avoids schema
drift and conflicting memories). The built-in layer never depends on an external provider being up.
