---
name: capture
description: Save the current conversation's valuable signals into the two-layer memory (personal vs project). Use when the user says "capture", "save this", "remember this", or when a notable preference / decision / fix / reusable knowledge / skill failure / broken tool appears. Routes each signal to the correct layer; never stores this-session artifacts as knowledge.
---

# capture — Save Current Conversation (layer-aware)

Scan the conversation and persist important content to the **right layer**. Roots
(`~/.ai-memory/guides/PATHS.md`): `PERSONAL = ~/.ai-memory`, `PROJECT = ./.claude/memory` (if it exists).
Routing table: `~/.ai-memory/guides/_routing.md`. **Decision gate: `~/.ai-memory/guides/_memory-gate.md`**
— for each signal it sets confidence (HIGH→auto-write a safe category · MEDIUM→candidate only ·
LOW→skip) and the hard rule that **doctrine and skills are NEVER auto-written** (they go to candidates
/ `## 🔁 Repeat candidates` for human review). Apply that gate throughout the steps below.

## Step 1: Scan for signals

| Type | Description | Default layer |
|------|-------------|---------------|
| 💡 Insight/Decision | something chosen or understood | PROJECT if about this project, else PERSONAL |
| 📚 Knowledge | how something works, a fix, a gotcha | PROJECT if project-specific, else PERSONAL |
| ❤️ Preference | how the user likes a TASK done | **PERSONAL** (`feedback_user_style.md`) |
| 🎭 Persona | how the AI itself should sound/address you, its role/boundaries | **PERSONAL** (`persona.md`) |
| 🚧 In Progress | unfinished task to continue | layer it belongs to |
| 🐛 Problem Solved | error + fix | PROJECT if this codebase, else PERSONAL |
| 🛠️ Skill Failure | a skill ran but was wrong/missed a case / user said "no" while it drove | log in that layer's conversation file |
| ⚙️ Environment/Tool Failure | a built-in tool is broken here (e.g. WebSearch 400) | **PERSONAL** — highest priority, see Step 2.5 |
| 🧩 Entity mentioned | tool/person/concept/project | PROJECT or PERSONAL per routing |

Skip greetings, simple Q&A, no-content explanations.

> **Short but decisive messages are NOT "routine".** When the user's message is a brief confirmation
> or choice — "OK", "好", "就這樣", "用 A", "同意", "對", "可以", "不要", "先這版" — it usually
> *resolves* something from the previous turns. **Do not skip it.** Look back over the **last 3-5
> turns**, reconstruct WHAT was settled (the option chosen, the stance taken, the rejected alternative
> + why), and capture that **resolved decision** as a 💡 Insight/Decision — store the substance, not
> the bare "OK". Example: user says "好" → capture *"Decided to use PGLite over Postgres for the demo
> (zero-config), per the discussion on 2026-06-01"*, not "好". If the short reply settles nothing
> concrete (pure acknowledgement), then skip it.

> **NOT a skill failure:** a *built-in tool* breaking is an ⚙️ Environment/Tool Failure → Step 2.5
> (hard block), never a skill-failure note. A built-in tool has no SKILL.md, so a fallback note there
> does nothing and the tool keeps getting called.

## Step 2: Entity detection

### 2.0 Knowledge Filter Gate (run BEFORE creating any page) ⚠️
**🚫 Never make a knowledge page for:** artifacts produced this session (a file/function/web page just
created — e.g. `tetris.html`), the one-off task name, temp paths/commands. These are *output*, not
knowledge.
**✅ Genuine-knowledge test (all three "yes"):** (1) useful in a *different future* conversation?
(2) a reusable fact/method/gotcha/setting, not "what I did this time"? (3) carries a fact worth
keeping? Shortcut: *"three months from now, on a different project, would I open this page?"*

### 2.1 Layer + type resolver
For entities that pass the gate, pick the **layer** (per `_routing.md`) then the **type/kind**:

| Entity is… | type | kind | layer |
|---|---|---|---|
| tool / tech / library | reference | tool | PERSONAL if generic, PROJECT if this project's own |
| person / org | reference | person | usually PERSONAL |
| mental model / workflow / concept | reference | concept | PERSONAL |
| something being built in THIS project | project | project | **PROJECT** |

**Fixed-file buckets (NOT entity pages — they live in their own files, all PERSONAL):**
**user** (who you are) → `feedback_user_style.md` · **persona** (the AI's identity/voice/role/
boundaries) → `persona.md` · **feedback** (approved behavior rules) → `doctrine.md` (via
`/review-doctrine`). Route 🎭 persona signals to `persona.md`; ❤️ task preferences to
`feedback_user_style.md` — they're different (persona = how the AI *is*; preference = how a *task* is done).

Then for each entity, in the chosen layer's `knowledge/`:
1. If `<layer>/knowledge/<entity>.md` doesn't exist → create it (format below).
2. If it exists → refresh `## Current State` (overwrite stale facts), append a dated line **with its
   source** to `## Timeline`, bump `last_updated`.

#### Entity page format (compiled-truth + timeline)
```markdown
---
name: <entity-name>
type: reference | project
kind: tool | person | concept | project
layer: personal | project
first_seen: YYYY-MM-DD
last_updated: YYYY-MM-DD
---

# <Entity Name>

> Summary (= the **Why**, REQUIRED): one line — what it is now + why it matters to the user.

## Current State          <!-- overwrite zone: latest truth; read this first -->
## How to Apply           <!-- REQUIRED: when <situation> → <action>. Pure reference? write
                               "Reference only — surfaces when <topic> comes up." Never leave blank. -->
## Known Issues
## Relations
- [[other-entity]]

---

## Timeline               <!-- append-only; newest first; every line ends with (source: ...) -->
- YYYY-MM-DD — created / what changed  (source: conversation YYYY-MM-DD | file | URL)
```

> **Every page carries a Why + a How to Apply** (the two REQUIRED parts above). The Why is the
> Summary line; the How to Apply says what to *do* with it (or, for pure reference, when it becomes
> relevant). `doctor` flags pages missing either. Source goes on every Timeline line; uncertain
> Current-State facts get `(confidence: low)` until confirmed.

### 2.5 Environment/Tool Failure → 3-layer enforcement (PERSONAL) ⚠️
A passive knowledge page will NOT change behavior. By failure kind:

> **Escalate on the 2nd failure — don't keep logging plain memories.** If the same tool/behavior has
> failed before (check prior logs or MEMORY.md's Environment Limits), do the hard-block **now**.
> Capturing the same failure as a normal memory 7-8 times does nothing to stop it; the registry + hook
> is what makes it stop getting called.
- **Layer 1 (always)** — append to the `## ⚠️ Environment Limits & Blocked Tools` section at the TOP
  of `PERSONAL/MEMORY.md`: `- ❌ <tool> broken here (<reason>) → use <alternative>; do not <broken action>.`
- **Layer 2 (a named TOOL)** — add to `PERSONAL/blocked-actions.json` `blocked_tools`. Use the
  **deterministic safe writer** (atomic + dedup + lock + drift backup) rather than hand-editing this
  registry — it is the hard-block safety net, so a malformed edit is the worst case:
  ```
  & "$env:USERPROFILE\.ai-memory\lib\memory-write.ps1" -Mode block-tool -Tool <Name> -Reason "..." -UseInstead "<Alt>" -Platform both   # Windows
  bash ~/.ai-memory/lib/memory-write.sh block-tool --tool <Name> --reason "..." --use-instead "<Alt>" --platform both                    # Mac/Linux
  ```
  (Resulting entry: `{ "tool", "reason", "use_instead", "platform": "claude|codex|both", "added" }`.)
  The PreToolUse hook is registered with a **catch-all matcher** on both platforms and gates by this
  registry, so you do NOT need to edit any matcher — adding the entry is enough. Use the canonical
  tool name as each platform reports it (`platform: both` if unsure; a name that doesn't exist on a
  platform simply never matches there). Takes effect after the next Claude Code / Codex restart.
- **Layer 3 (a behavior PATTERN, no single tool)** — write to `PERSONAL/doctrine_candidates.md` for
  `/review-doctrine`.

## Step 3: Write today's log (to the active layer)
Append to `<layer>/conversations/YYYY-MM-DD.md` (PROJECT if in a project, else PERSONAL):
```markdown
# Conversation Log YYYY-MM-DD   (layer: project|personal)

## 💡 Insights & Decisions
## 📚 Knowledge
## ❤️ Preferences          <!-- these mirror to PERSONAL/feedback_user_style.md -->
## 🚧 In Progress
## 🐛 Problems Solved
## 🛠️ Skill Failures       <!-- omit if none; Fails when / Do instead / Severity -->
## 🧩 Entities Mentioned
```
Preferences (❤️) and behavior rules always also update PERSONAL files even when logged inside a project.

## Step 4: Workflow-harvest hint (count occurrences, not days)
Count **occurrences**, not days — a workflow repeated twice in ONE day already qualifies (you do NOT
need 3 separate days). If a repeatable workflow has now occurred **2+ times**, add a one-line note to
today's log under `## 🔁 Repeat candidates`, then **proactively offer to act now**:
*"This looks repeatable (seen N×) — want me to run /harvest to turn it into a skill?"* Don't silently
wait; the user shouldn't have to remember `/harvest` exists. (Building still goes through /harvest's
review gate; you're just offering to start it.)

> ⚠️ **A repeatedly-FAILING built-in tool is NOT a skill candidate.** If the same tool/behavior failed
> 2+ times, that's an ⚙️ Environment/Tool Failure → it belongs in the **hard-block** (Step 2.5), not a
> skill. A "how to search" skill cannot fix a broken search tool.

## Step 5: Update the active layer's MEMORY.md index (two-step write — topic file FIRST)
**Order matters (crash-safe):** finish writing the actual topic/knowledge/log file and confirm it
exists, **then** add its one-line pointer here. Never index content you haven't persisted — a crash
then leaves at worst an orphan file, never a corrupt index. Group entries by type, keeping the
template's **bilingual headers** (`## User 用戶`, `## Feedback / Self-Evolution 反饋／自我進化`,
`## Reference 參考`, `## Skills 技能`, `## Conversations 對話紀錄`). Keep it a bounded index (one line
per item) — never paste body text into MEMORY.md.

## Step 6: Report (always show recent + totals)
After saving, show what just got captured AND a recent recap, so the user can see their running
record without a separate command:
```
✅ Capture complete
- Layer(s) written: personal / project
- This run → signals: X · new/updated entity pages: X (names) · tool-failures enforced: X · repeat candidates: X

🗒️ 近 5 筆擷取紀錄 (most recent 5)
  1. [2026-06-02 personal] 💡 Decided to use PGLite for the demo
  2. [2026-06-02 project:acme] 📚 Bun on Windows needs --ignore-scripts
  3. ...
   （從各層 conversations/*.md 的條目，依日期由新到舊取前 5）

📊 累計 N 筆擷取（跨 D 天）。看完整紀錄打 /status。
```
To build this: scan the active layer(s)' `conversations/*.md`, take the newest 5 individual entries
(across the signal sections), and count the total entries for the running tally.

## Rules
- Write in the user's language; be concise (bullets).
- **When in doubt, don't store it** (Step 2.0 gate).
- **Never** make a knowledge page from a this-session artifact.
- Tool failures → directives + hard block, not passive notes (Step 2.5).
- Personal memory NEVER gets written into a project's tree.
- Entity filenames: lowercase kebab-case.
