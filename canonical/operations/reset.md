---
name: reset
description: Reset (clear) memory and start fresh, interactively. Use when the user says "reset memory", "重置記憶", "wipe my memory", "清空記憶重來", or has over-captured unwanted memories. ALWAYS backs up to an archive first and requires explicit confirmation; the user chooses which layer and which categories to clear at run time. Never hard-deletes the only copy.
---

# reset — Interactive Memory Reset (archive-first, layer-aware)

The user decides **what** to clear, at run time. You never decide for them, never skip the backup,
and never clear without an explicit "yes". Roots: `PERSONAL = ~/.ai-memory`,
`PROJECT = ./.claude/memory` (if it exists).

## Step 1: Show what exists (read-only)
Report current counts per layer so the user knows what they're about to clear:
```
Personal (~/.ai-memory):  conversations X · reflection (Y entries) · knowledge Z ·
                          doctrine A approved/B pending · preferences (present?)
Project (<name>):         conversations X · knowledge Z   (only if a project layer exists)
```

## Step 2: Ask WHICH LAYER (let the user choose)
- If only the personal layer exists → default to personal (still confirm).
- If a project layer also exists → ask:
  ```
  Reset which layer?
   1. This project only  (<proj>/.claude/memory)
   2. Personal only      (~/.ai-memory — affects ALL projects)
   3. Both
  ```

## Step 3: Ask WHICH CATEGORIES (let the user choose)
```
Clear what? (everything chosen is BACKED UP first, then cleared)
 1. Conversations + reflection      (the noisy logs — keeps doctrine, preferences, knowledge)
 2. + Knowledge pages too           (also clears knowledge/, keeps doctrine + preferences)
 3. Everything incl. doctrine + preferences   (full from-scratch)
 4. Let me pick item by item        (conversations / reflection / knowledge / doctrine / preferences)
```
**`blocked-actions.json` (broken-tool registry) is preserved by default** — it's hard-won machine
truth, not memory clutter. Only clear it if the user explicitly asks.

## Step 4: Back up FIRST (mandatory, never skip)
For each chosen layer, copy everything that will be cleared into a timestamped backup:
`<layer>/archive/reset-YYYYMMDD-HHMMSS/` (preserve subfolder structure). Confirm the backup exists
before clearing anything.

## Step 5: Confirm explicitly (show the exact plan)
```
About to reset:
  Layer(s): <...>
  Clearing: <categories>
  Backup → <layer>/archive/reset-YYYYMMDD-HHMMSS/
  Preserved: <doctrine/preferences/blocked-actions as applicable>
Type "yes reset" to proceed, anything else cancels.
```
Proceed only on an explicit "yes". Otherwise stop and change nothing.

## Step 6: Clear (after backup + confirmation)
- **Conversations** → move `conversations/*.md` into the backup; leave `conversations/` empty.
- **Reflection** → archive `reflection.md`, re-seed it to the empty template.
- **Knowledge** → move `knowledge/*.md` into the backup; leave `knowledge/` empty.
- **Doctrine** → archive `doctrine.md` + `doctrine_candidates.md`, re-seed to templates.
- **Preferences** → archive `feedback_user_style.md`, re-seed to template.
- **MEMORY.md** → re-seed to the layer's template so the index reflects the cleared state (PERSONAL
  keeps its `## ⚠️ Environment Limits & Blocked Tools` section intact unless blocked-actions was also
  cleared).
Never delete the only copy of anything — everything cleared exists in the backup.

## Step 7: Report + how to undo
```
✅ Reset complete
  Cleared: <categories> in <layer(s)>
  Backup:  <layer>/archive/reset-YYYYMMDD-HHMMSS/   (restore = copy files back)
  Preserved: <...>
Restart Claude Code / Codex so the fresh index loads.
```

## Rules
- Interactive every time — the user picks layer + categories; never assume.
- Backup before clear is non-negotiable; show the backup path.
- Require an explicit "yes reset"; any other answer cancels with zero changes.
- Personal vs project stays separate; resetting one never touches the other.
- `blocked-actions.json` preserved unless explicitly requested.
- Write in the user's language.
