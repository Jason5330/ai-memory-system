---
name: capture
description: Save the current conversation's valuable signals into the two-layer memory (personal vs project). Use when the user says "capture", "save this", "remember this", or when a notable preference / decision / fix / reusable knowledge / skill failure / broken tool appears. Routes each signal to the correct layer; never stores this-session artifacts as knowledge.
---

# capture — Save Current Conversation (layer-aware)

Scan the conversation and persist important content to the **right layer**. Roots
(`~/.ai-memory/guides/PATHS.md`): `PERSONAL = ~/.ai-memory`, `PROJECT = ./.claude/memory` (if it exists).
Routing table: `~/.ai-memory/guides/_routing.md`.

## Step 1: Scan for signals

| Type | Description | Default layer |
|------|-------------|---------------|
| 💡 Insight/Decision | something chosen or understood | PROJECT if about this project, else PERSONAL |
| 📚 Knowledge | how something works, a fix, a gotcha | PROJECT if project-specific, else PERSONAL |
| ❤️ Preference | how the user likes things done | **PERSONAL** (`feedback_user_style.md`) |
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

> Summary: one line — what it is now + why it matters

## Current State          <!-- overwrite zone: latest truth; read this first -->
## How to Apply           <!-- what to DO with this; omit for pure reference -->
## Known Issues
## Relations
- [[other-entity]]

---

## Timeline               <!-- append-only; newest first; every line ends with (source: ...) -->
- YYYY-MM-DD — created / what changed  (source: conversation YYYY-MM-DD | file | URL)
```

### 2.5 Environment/Tool Failure → 3-layer enforcement (PERSONAL) ⚠️
A passive knowledge page will NOT change behavior. By failure kind:

> **Escalate on the 2nd failure — don't keep logging plain memories.** If the same tool/behavior has
> failed before (check prior logs or MEMORY.md's Environment Limits), do the hard-block **now**.
> Capturing the same failure as a normal memory 7-8 times does nothing to stop it; the registry + hook
> is what makes it stop getting called.
- **Layer 1 (always)** — append to the `## ⚠️ Environment Limits & Blocked Tools` section at the TOP
  of `PERSONAL/MEMORY.md`: `- ❌ <tool> broken here (<reason>) → use <alternative>; do not <broken action>.`
- **Layer 2 (a named TOOL)** — add to `PERSONAL/blocked-actions.json` `blocked_tools`:
  `{ "tool": "<Name>", "reason": "...", "use_instead": "<Alt>", "platform": "claude|codex|both", "added": "YYYY-MM-DD" }`
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

## Step 5: Update the active layer's MEMORY.md index
Group entries by type (User / Feedback / Projects / Reference / Skills / Conversations).

## Step 6: Report
```
✅ Capture complete
- Layer(s) written: personal / project
- Signals: X   New/updated entity pages: X (names)
- Tool failures enforced: X   Repeat candidates flagged: X
```

## Rules
- Write in the user's language; be concise (bullets).
- **When in doubt, don't store it** (Step 2.0 gate).
- **Never** make a knowledge page from a this-session artifact.
- Tool failures → directives + hard block, not passive notes (Step 2.5).
- Personal memory NEVER gets written into a project's tree.
- Entity filenames: lowercase kebab-case.
