---
name: dream
description: Multi-phase memory consolidation across both layers — entity sweep, bidirectional link repair, dedup/contradiction cleanup, reflection→doctrine candidates, skill-failure writeback, index sync, and a deterministic lint. Use when the user says "dream", "consolidate memory", "process my conversations", or on the nightly schedule.
---

# dream — Multi-Phase Consolidation (layer-aware)

Roots: `PERSONAL = ~/.ai-memory`, `PROJECT = ./.claude/memory` (if it exists). Run phases against
**both** layers where noted. Reflection + doctrine are PERSONAL-only.

> Follows the **Memory Decision Gate** (`~/.ai-memory/guides/_memory-gate.md`): dream may create/refresh
> safe categories (entities, preferences, logs) and may **propose** doctrine/skill *candidates*, but it
> **never auto-promotes** a doctrine or builds a skill — those stay behind `/review-doctrine` and
> `/harvest` (human gate). Two-step write throughout: persist the topic file first, then index it.

## Phase 1: Entity Sweep (both layers)
For each layer, read `conversations/*.md`, scan `## 🧩 Entities Mentioned` + names in text, compare to
`knowledge/`. For each entity without a page → create `knowledge/<entity>.md` (compiled-truth +
timeline format from capture). Project entities → PROJECT; generic/personal → PERSONAL.
Report: "Found X, created Y, Z existed (per layer)".

## Phase 2: Fix Broken Links (both layers)
Read each layer's `knowledge/*.md`, check `## Relations` `[[wikilinks]]`; if A→B but not B→A (and it's
meaningful), add the reverse link. Cross-layer links are allowed but never auto-create a PERSONAL page
from a PROJECT mention without it passing the knowledge gate.

## Phase 3: Consolidate & Deduplicate
### 3a (both layers)
- Preferences → `PERSONAL/feedback_user_style.md` (update if new).
- Knowledge → matching `knowledge/*.md`: refresh `## Current State`, append dated `## Timeline` line
  with source, bump `last_updated`.
- In-progress tasks → mark completed if resolved in a later log.
### 3b Contradiction detection (both layers)
Same topic with conflicting info across logs → keep newest, mark `[updated]`. Resolved task → `[✅ completed]`.
### 3c Repeat-candidate roll-up (count occurrences, not days)
Collect `## 🔁 Repeat candidates` and recurring workflows across logs — counting **occurrences**
(twice in one day already qualifies; you do NOT need 3 separate days). Surface a short list and
**offer to act**: "N repeatable workflows detected (≥2× each) — want me to run /harvest now?"
Building still goes through `/harvest`'s review gate. **A repeatedly-failing built-in tool is NOT a
skill** — it belongs in the hard-block (blocked-actions.json), not /harvest.
### 3d Memory Overflow Guard (per layer)
- `conversations/` > 30 files → archive oldest 10 to `conversations/archive/YYYY-MM/` (extract
  knowledge first).
- any `knowledge/*.md` > 200 lines → keep `## Current State`, move OLDEST `## Timeline` to
  `knowledge/archive/<entity>.md`, keep ~20 newest lines.
- `MEMORY.md` > 150 lines → merge older index entries.
- `PERSONAL/doctrine.md` > 80 entries → merge semantic dups; move >6-month-untriggered to
  `doctrine_archive.md` `[verify if still needed]`; notify user → /review-doctrine.
- any entry file (`CLAUDE.md`/`AGENTS.md`) > 80 lines → warn: entry files should not grow.

## Phase 3.5: Reflection (Self-Evolution) — PERSONAL
Read every `conversations/*.md` (both layers) NOT marked `[consolidated]`; find:
✅ what went right · ❌ where it got stuck (situation/problem/root cause) · 🔄 what to change next
time · 💬 communication patterns. Append (never overwrite) to `PERSONAL/reflection.md`:
```markdown
## Reflection YYYY-MM-DD (auto by /dream)
### ✅ What went right
### ❌ Where it got stuck
- Situation / Problem / Root cause
### 🔄 What to change next time
- If "..." → do "..." first
### 💬 Observed communication patterns
```
Then read the WHOLE `reflection.md`; patterns recurring across **2+** reflections → append to
`PERSONAL/doctrine_candidates.md`:
```markdown
## Candidates YYYY-MM-DD
### Candidate #N
- Source: reflection #X (date range)
- Observed pattern:
- Proposed doctrine: (concrete, paste-ready behavior rule)
- Why it helps:
- Status: ⏳ pending review
```
Mark each processed conversation log `[consolidated YYYY-MM-DD]` at its top.

## Phase 3.6: Skill Failure Writeback
Gather every `## 🛠️ Skill Failures` (both layers) not yet consolidated, group by skill. For each skill,
locate its **canonical** file (project skill → `./.claude/skills/<n>/SKILL.md`; personal →
`~/.claude/skills/<n>/SKILL.md`), ensure a `## Known Limitations & Fallbacks` section, append (dedup):
```markdown
- **Fails when**: <situation>
  **Do instead**: <fallback / what the user wanted>
  **Severity**: blocker | error | confused | nit
  **Learned**: YYYY-MM-DD
```
Then **re-materialize** the updated SKILL.md to its Codex twin (`.agents/skills/<n>/` or
`~/.agents/skills/<n>/`) so both platforms see the fallback. If the skill doesn't exist yet, leave the
failure in the log for `/harvest` to handle.

## Phase 4: Sync Index (per layer) — keep it a BOUNDED INDEX
Rewrite each layer's `MEMORY.md` as a **bounded index only**: one line per item (a title/hook + link),
**never body text** — the substance lives in the topic files, MEMORY.md just points at them. Group by
type with **bilingual headers** (keep the form the template uses: `## User 用戶`,
`## Feedback / Self-Evolution 反饋／自我進化`, `## Reference 參考`, `## Skills 技能`,
`## Conversations 對話紀錄`). Verify every link resolves; drop dead links; newest conversations first.
If an entry has grown into a paragraph, move the prose into its topic file and leave only the one-line
pointer here (Phase 3d also trims MEMORY.md past 150 lines). PERSONAL MEMORY.md keeps the `## ⚠️ Environment Limits & Blocked Tools 環境限制／壞工具`
section at the top.

## Phase 5: Dream Report
Show per-phase counts, memory health (both layers), and doctrine-candidate preview → prompt
`/review-doctrine`. If none: "Doctrine Candidates: none new this run."

## Phase 6: Lint (deterministic)
Run `memory-lint` against both layers (the installer puts it at `~/.ai-memory/memory-lint.{ps1,sh}`).
Append `RESULT: X pass, Y warn, Z fail`. Fix any FAIL before next cycle.

## Rules
- Never delete the only copy of unique info; tag uncertain info `[verify]`.
- Personal vs project separation is strict — never move personal memory into a project tree.
- Write in the user's language.
